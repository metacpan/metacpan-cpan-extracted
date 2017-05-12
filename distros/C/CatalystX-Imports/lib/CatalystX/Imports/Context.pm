package CatalystX::Imports::Context;

=head1 NAME

CatalystX::Imports::Context - Exports Context Helper Functions

=cut

use warnings;
use strict;

=head1 BASE CLASSES

L<CatalystX::Imports>

=cut

use base 'CatalystX::Imports';
use vars qw( $EXPORT_MAP_NAME $DEFAULT_LIBRARY );

use Class::MOP;
use List::MoreUtils qw( part apply uniq );
use Scalar::Util    qw( set_prototype );
use Carp::Clan      qw{ ^CatalystX::Imports(?:::|$) };
use Filter::EOF;
use Sub::Name 'subname';

$EXPORT_MAP_NAME  = 'CATALYSTX_IMPORTS_EXPORT_MAP';
$DEFAULT_LIBRARY  = __PACKAGE__ . '::Default';

=head1 SYNOPSIS

  package MyApp::Controller::Foo;
  use base 'Catalyst::Controller';

  # Export everything minus the 'captures' function. Also load
  # the additional 'Foo' library and a config value
  use CatalystX::Imports
      Context => {
          Default => [qw( :all -captures +Foo )],
          Config  => [qw( model_name )],
      };

  sub list: Local {
      stash( rs => model(model_name)->search_rs );
  }

  sub edit: Local {
      stash(
          foo      => model(model_name)->find(args[0]),
          list_uri => uri_for(action('list')),
      );
  }

  1;

=head1 DESCRIPTION

This package represents the base class and export manager for all
libraries. The default library can be found under the package name
L<CatalystX::Imports::Context::Default>.

The exports will be removed after compiletime. By then, the calls
to them in your controller will already be bound to the right code
slots by perl. This keeps these functions from being available as
methods on your controller object.

=head1 IMPORT SYNTAX

You can specify what library parts you want to import into your
controller on the C<use> line to L<CatalystX::Imports>:

  use CatalystX::Imports Context => [qw(:all -captures +Foo)];

This would import all functions from the default library
L<CatalystX::Imports::Context::Default>, except the C<captures> function.
See L<CatalystX::Imports::Context::Default/Tags> for all available tags
in the default library.

Additionally, it will search and load the C<Foo> library, which would be
C<CatalystX::Imports::Context::Foo>. This notation doesn't accept any
arguments, so the library specific default symbols will be exported.

If you just want some specific functions imported, you can also specify
them explicitly:

  use CatalystX::Imports
      Context => [qw(action uri_for model config stash)];

At last, to be specific about more than one library, you can pass a
hash reference:

  use CatalystX::Imports
      Context => { Default => ':all', Config => [qw(model_name)] };

See the libraries documentation for further syntax information.

=head1 ALIASES

If documented, you can also import a function with one of it's aliases.
If you import a function via a tag, it will only be exported under its
real name, not its aliased names. Therefor, to use an aliase you have
to specify aliases explicitly at any time to use them:

  # load aliases for short forms of 'request' and 'response'
  use CatalystX::Imports Context => [qw( req res )];

=head1 INCLUDED LIBRARIES

=over

=item L<CatalystX::Imports::Context::Default>

Contains default shortcuts and inline accessors.

=item L<CatalystX::Imports::Context::Config>

Allows you to import local controller (instance) configuration accessors
as inline functions into your namespace.

=back

=cut

=head1 METHODS

=cut

=head2 register_export

This method registers a new export in the library it's called upon. You
will mostly only need this function for creating your own libraries:

  package CatalystX::Imports::Context::MyOwnLibrary;
  use base 'CatalystX::Imports::Context';

  __PACKAGE__->register_export(
      name      => 'double',
      alias     => 'times_two',
      prototype => '$',
      tags      => [qw( math )],
      code      => sub {
          my ($library, $ctrl, $ctx, $action_args, @args) = @_;
          return $args[0] * 2;
      },
  );

The C<code> and C<name> parameters are mandatory. If you specify an
alias, it can be imported explicitly, but will not be included in the
C<:all> tag.

The prototype is the usual prototpe you could stuff on perl subroutines.
If you specify tags as an array reference, the export will be included
in those tag sets by it's name and aliases. It will be included in the
C<:all> tag in any case, but only under it's name, not it's aliases.

The specified code reference will get the library class name, the
controller and context objects (like a L<Catalyst> action), and an array
reference of the arguments passed to the last action and then it's
own actual arguments passed in. You could call the above with

  double(23); # 46

=cut

sub register_export {
    my ($class, @args) = @_;

    # we expect pairs of option keys and values as arguments
    croak 'register_export expects key/value pairs as arguments'
        if @args % 2;
    my %options = @args;

    # check if every required option is there
    for my $required (qw( code name )) {
        croak "register_export: Missing required parameter: '$required'"
            unless exists $options{ $required }
              and defined $options{ $required };
    }

    # optionals
    my @tags    = @{ $options{tags}  || [] };
    my @aliases = @{ $options{alias} || [] };

    # get the export map, we'll need it
    my $export_map = $class->_export_map;

    # walk the names we want to register this under
    for my $name ($options{name}, @aliases) {

        # register in tags, only name goes into :all by default
        for my $t (uniq @tags, ($options{name} eq $name ? 'all' : ())) {
            push @{ $export_map->{tag}{ $t } ||= [] }, $name;
        }

        # save export information
        $export_map->{export}{ $name } = {
            name => $name,
            code => $options{code},
            ( exists $options{prototype}
              ? ( prototype => $options{prototype} )
              : () ),
        };
    }

    return 1;
}

=head2 _export_map

Returns the libraries export map as a hash reference. This will be stored
in your library class (if you build your own, otherwise you don't have to
care) in the C<%CATALYSTX_IMPORTS_EXPORT_MAP> package variable.

=cut

sub _export_map {
    my ($class) = @_;
    my $map_name = "${class}::${EXPORT_MAP_NAME}";
    {   no strict 'refs';
        no warnings 'once';
        return \%{ $map_name };
    }
}

=head2 get_export

Expects the name of an export in the library and will return the
information it stored with it. An export will be stored under its actual
name as well as its aliases.

=cut

sub get_export { $_[0]->_export_map->{export}{ $_[1] } }

=head2 export_into

Called by L<CatalystX::Imports>' C<import> method. Takes a target and a
set of commands specified in L</IMPORT SYNTAX>. This will forward the
commands to the actual libraries and the L</context_export_into> method
in them.

=cut

sub export_into {
    my ($class, $target, @args) = @_;
    my %args;

    # we accept lists and array refs for default, and explicit
    # hash refs for more control
    if (@args == 1 and ref $args[0] eq 'ARRAY') {
        %args = (Default => $args[0]);
    }
    elsif (@args == 1 and ref $args[0] eq 'HASH') {
        %args = %{ $args[0] };
        ref($args{ $_ }) eq 'ARRAY' or $args{ $_ } = [ $args{ $_ } ]
            for keys %args;
    }
    else {
        %args = (Default => \@args);
    }

    # filter out additional libraries in Default arguments
    my @default_args = @{ delete($args{Default}) || [] };
    my %load_default;
    for my $arg (@default_args) {
        if ($arg =~ /^[+](.+)$/) {
            next unless exists $args{ $1 };
            $args{ $1 } ||= [];
            $load_default{ $1 } = 1;
            next;
        }
        push @{ $args{Default} ||= [] }, $arg;
    }

    # load libraries and export symbols
    for my $lib (keys %args) {
        my $lib_class = __PACKAGE__ . '::' . $lib;
        Class::MOP::load_class($lib_class);
        my @symbols = @{ $args{ $lib } };
        push @symbols, $lib_class->default_exports
            if $load_default{ $lib };
        $lib_class->context_export_into($target, @{ $args{ $lib } });
    }

    return 1;
}

=head2 context_export_into

Takes a target and an actual command set for a library (no C<+Foo> stuff)
and cleans that (flattens out tags, removes C<-substractions>). It will
utilise L</context_install_export_into> to actually export the final set
of functions.

=cut

sub context_export_into {
    my ($class, $target, @exports) = @_;

    # part and clean different type of import arguments
    my ($export_list, $tags, $substract) = map { [] } 1..3;
    for my $export (@exports) {
        push @$substract, $export and next
            if $export =~ s/^-//;
        push @$tags, $export and next
            if $export =~ s/^://;
        push @$export_list, $export;
    }

    # fetch the export map, we're going to use it a bit
    my $export_map = $class->_export_map;

    # resolve tags
    for my $tag (@$tags) {
        my $tag_exports = $export_map->{tag}{ $tag }
            or croak "Unknown Context tag: ':$tag'";
        push @$export_list, @$tag_exports;
    }

    # remove doubles and substractions
    my %substract_map = map { ($_ => 1) } @{ $substract || [] };
    @$export_list
      = grep { not exists $substract_map{ $_ } }
        uniq @$export_list;

    # install the exports
    for my $export (@$export_list) {
        $class->context_install_export_into($target, $export);
    }

    # register the exports to be removed after compile time
    Filter::EOF->on_eof_call(sub {
        for my $export (@$export_list) {
            no strict 'refs';
            delete ${ $target . '::' }{ $export };
        }
    });

    return 1;
}

=head2 context_install_export_into

Takes a target class and the name of an export to install the function
in the specified class.

=cut

sub context_install_export_into {
    my ($class, $target, $export) = @_;

    # find the export information
    my $export_info = $class->get_export($export)
        or croak "Unknown Context export: '$export'";
    my ($code, $prototype) = @{ $export_info }{qw( code prototype )};

    # the wrapper fetches the current objects
    my $export_code = sub {
        my ($controller, $context, $arguments) = do {
            no strict 'refs';
            map { ${ "${target}::" . ${ "CatalystX::Imports::$_" } } }
                qw( STORE_CONTROLLER STORE_CONTEXT STORE_ARGUMENTS );
        };
        return $class->$code($controller, $context, $arguments, @_);
    };

    # install the export, include prototype if specified
    {   no strict 'refs';
        my $name = join('::',$target, $export_info->{name});
        *$name = subname $name, (
          defined $prototype
            ? set_prototype sub { $export_code->(@_) }, $prototype
            : $export_code
          );
    }

    return 1;
}

=head2 default_exports

Should be overridden by subclasses if they want to export something
by default. This will be used if the library is specified without any
arguments at all. E.g. this:

  use CatalystX::Imports Context => [qw( +Foo )];

will export C<Foo>'s defaults, but

  use CatalystX::Imports Context => { Foo => [] };

will not. Without an overriding method, the default is set to export
nothing at all.

=cut

sub default_exports { }

=head1 DIAGNOSTICS

=head2 register_export expects key/value pairs as arguments

You passed an odd number of values into the C<register_export> method
call, but it expects key and value pairs of named options. See
L>/register_export> for available options and calling syntax.

=head2 register_export: Missing required parameter: 'foo'

The L</register_export> method expects a few parameters that can't be
omitted, including C<foo>. Pass in the parameter as specified in the
section about the L</register_export> method.

=head2 Unknown Context tag: ':foo'

You specified to import the functions in the tag C<:foo> on your C<use>
line, but no tag with the name C<:foo> was registered in the library.

=head2 Unknown Context export: 'foo'

You asked for export of the function C<foo>, but no function under this
name was registered in the library. Please consult your library
documentation for a list of available exports. The default library can
be found under L<CatalystX::Imports::Context::Default>.

=head1 SEE ALSO

L<Catalyst>,
L<Filter::EOF>,
L<CatalystX::Imports::Context::Default>,
L<CatalystX::Imports::Context::Config>,
L<CatalystX::Imports::Vars>,
L<CatalystX::Imports>

=head1 AUTHOR AND COPYRIGHT

Robert 'phaylon' Sedlacek C<E<lt>rs@474.atE<gt>>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
