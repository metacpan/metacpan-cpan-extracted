package Data::Context;

# Created on: 2012-03-18 16:54:56
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use namespace::autoclean;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Path::Tiny;

use Data::Context::Instance;
use Data::Context::Finder::File;

our $VERSION = version->new('0.2');

has fallback => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
has fallback_depth => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);
has actions => (
    is   => 'rw',
    isa  => 'HashRef[CodeRef]',
);
has action_class => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Data::Context::Actions',
);
has action_method => (
    is      => 'rw',
    isa     => 'Str',
    default => 'get_data',
);
has log => (
    is         => 'rw',
    isa        => 'Object',
    builder    => '_log',
    lazy_build => 1,
);
has debug => (
    is         => 'rw',
    isa        => 'Int',
    builder    => '_debug',
    trigger    => \&_debug_set,
    lazy_build => 1,
);
has instance_class => (
    is       => 'rw',
    isa      => 'Str',
    default  => 'Data::Context::Instance',
);
has instance_cache => (
    is       => 'rw',
    isa      => 'HashRef[Data::Context::Instance]',
    default  => sub {{}},
    init_arg => undef,
);
has finder => (
    is       => 'rw',
    isa      => ' Data::Context::Finder',
    required => 1,
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args
        = !@args     ? {}
        : @args == 1 ? $args[0]
        :              {@args};

    if ( !$args->{finder} ) {
        $args->{finder} = Data::Context::Finder::File->new(
            map { $_ => $args->{$_} }
            grep { $_ eq 'path' || /^file_/xms }
            keys %{ $args }
        );
    }

    return $class->$orig($args);
};

sub get {
    my ( $self, $path, $vars ) = @_;

    my $dci = $self->get_instance($path);

    return $dci->get_data($vars);
}

sub get_instance {
    my ( $self, $path ) = @_;

    # TODO add some cache controls here or in ::Instance::init();
    return $self->instance_cache->{$path} if $self->instance_cache->{$path};

    my @path  = split m{/+}xms, $path;
    shift @path         if !defined $path[0] || $path[0] eq '';
    push @path, 'index' if $path =~ m{/$}xms;

    my $count = 1;
    my $loader;

    # find the most appropriate file
    PATH:
    while ( @path ) {
        $loader = $self->finder->find(@path);

        last if $loader;
        last if !$self->fallback || ( $self->fallback_depth && $count++ >= $self->fallback_depth );

        pop @path;
    }

    confess "Could not find a data context config file for '$path'\n" if ! $loader;

    my $instance_class = $self->instance_class;
    return $self->instance_cache->{$path} = $instance_class->new(
        path   => $path,
        loader => $loader,
        dc     => $self,
    );
}

sub _log {
    my $self = shift;
    require Data::Context::Log;
    return Data::Context::Log->new( level => $self->debug );
}
sub _debug { return 3 }
sub _debug_set {
    my ($self, $new_debug ) = @_;
    if ( ref $self->log eq 'Data::Context::Log' ) {
        $self->log->level( $new_debug );
    }
    return $new_debug;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Context - Configuration data with context

=head1 VERSION

This documentation refers to Data::Context version 0.2.

=head1 SYNOPSIS

   use Data::Context;

   # create a new Data::Context variable
   my $dc = Data::Context->new(
        path => [qw{ /path/to/configs /alt/path }],
   );

   # read a config
   my $data = $dc->get(
        'some/config',
        {
            context => 'values',
        }
   );

=head1 DESCRIPTION

    /path/to/file.dc.js:
    {
        "PARENT" : "/path/to/default.dc.js:,
        "replace_me" : "#replaced.from.input.variables.0#"
        "structure" : {
            "MODULE": "My::Module",
            "METHOD": "do_stuff",
            ....
        },
        ...
    }

Get object
Build -> parse file
    -> if "PARENT" build parent
    -> merge self and raw parent
    -> construct instance
        -> iterate to all values
            -> if the value is a string of the form "#...#" make sub reference to add to call list
            -> if the value is a HASHREF & "MODULE" or "METHOD" keys exist add to call list
    -> cache result

Use object
    -> clone raw data
    -> call each method call list
        -> if return is a CODEREF assume it's an event handler
        -> else replace data with returned value
   -> if any event handlers are returned run event loop
   -> return data

MODULE HASHES
{
    "MODULE" : "My::Module",
    "METHOD" : "get_data",
    "NEW"    : "new",
    ...
}
or
{
    "METHOD" : "do_something",
    "ORDER"  : 1,
    ....
}

1st : calls My::Module->new->get_data (if NEW wasn't present would just call My::Module->get_data)
2nd : calls Data::Context::Actions->do_something

the parameters passed in both cases are
    $value = the hashref containing the method call
    $dc    = The whole data context raw data
    $path  = A path of how to get to this data
    $vars  = The variables that the  get was called with

Data::Context Configuration
    path      string or list of strings containing directory names to be searched config files
    fallback bool if true if a config isn't found the parent config will be searched for etc
    fallback_depth
              If set to a non zero value the fall back will limited to this number of times
    actions   hashref of coderefs, allows simple adding of extra methods to Data::Context::Actions
    action_class
              Allows the using of an action class other than Data::Context::Actions. Although it is suggested that the alt class should inherit from Data::Context::Actions
    file_suffixes HASHREF
             json => '.dc.json' : JSON
             js   => '.dc.js'   : JSON->relaxed
             yaml => '.dc.yml'  : YAML or YAML::XS
             xml  => '.dc.xml'  : XML::Simple
    log      logging object, creates own object that just writes to STDERR if not specified
    debug    set the debugging level default is WARN (DEBUG, INFO, WARN, ERROR or FATAL)
    cache ...

=head1 SUBROUTINES/METHODS

=head2 C<new (...)>

Parameters to new:

=over 4

=item path

The directory path (or a list of paths) where the configuration files can be found

=item fallback

A bool if set to true will allow the falling back along the path of the
config specified.

 eg config path = my/config/file

if fallback is false the default search performed (for each directory in $dc->path) is

 my/config/file.dc.js
 my/config/file.dc.json
 my/config/file.dc.yml
 my/config/file.dc.xml
 my/config/_default.dc.js
 my/config/_default.dc.json
 my/config/_default.dc.yml
 my/config/_default.dc.xml

if fallback is true the search is (just for the .dc.js)

 my/config/file.dc.js
 my/config/_default.dc.js
 my/config.dc.js
 my/_default.dc.js
 my.dc.js
 _default.dc.js

=item fallback_depth

f fallback is true this if set to a non zero +ve int will limit the number
of time a fallback will occur. eg from the above example

fallback_depth = 0 or 2

 my/config/file.dc.js
 my/config/_default.dc.js
 my/config.dc.js
 my/_default.dc.js
 my.dc.js
 _default.dc.js

fallback_depth = 1

 my/config/file.dc.js
 my/config/_default.dc.js
 my/config.dc.js
 my/_default.dc.js

=item actions

A hash ref of code refs to allow the simple adding of default actions. The
key can be used in templates METHOD parameter and the code will be called
when found.

=item action_class

If you want to use your own default class for actions (ie you don't want
to specify C<actions> and don't want to have to always specify MODULE).
Your class should inherit from L<Data::Context::Action> to be safe.

=item action_method

The default action_method is get_data, through this parameter you may choose
a different method name.

=item file_suffixes

This allows the setting of what file suffixes will be used for loading the
various config types. Default:

 {
   js   => '.dc.js',
   json => '.dc.json',
   yaml => '.dc.yml',
   xml  => '.dc.xml',
 }

=item file_suffix_order

Specify the order to search for various file types. If you will only use
one config type you can specify just that type to speed up the searching.
Default: [ js, json, yaml, xml ]

=item file_default

Sets the name of the default config file name (_default by default). If you
unset this value, falling back to a default will be disabled

=item log

A log object should be compatible with a L<Catalyst::Log>, L<Log::Log4perl>,
etc logger object. The default value just writes to STDERR.

=item debug

When using the default logger for C<log>. This sets the level of logging.
1 = most information, 5 = almost none, default is 3 warnings and higher
messages

=back

=head2 C<get ($path, $vars)>

Reads the config represented by C<$path> and apply the context variable
C<$vars> as dictated by the found config.

=head2 C<get_instance ($path)>

Creates (or retrieves from cache) an instance of the config C<$paht>.

=head1 DIAGNOSTICS

By default C<Data::Context> writes messages to STDERR (via it's simple log
object). More detailed messages can be had by upping the debug level (by
lowering the value of debug, 1 out puts all messages, 2 - info and above,
3 - warnings and above, 4 - errors and above, 5 - fatal errors)

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

L<Moose>, L<Moose::Util::TypeConstraints>

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
