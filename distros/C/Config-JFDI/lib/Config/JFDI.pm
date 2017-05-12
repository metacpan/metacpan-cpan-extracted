package Config::JFDI;
BEGIN {
  $Config::JFDI::VERSION = '0.065';
}
# ABSTRACT: Just * Do it: A Catalyst::Plugin::ConfigLoader-style layer over Config::Any

use warnings;
use strict;


use Any::Moose;

use Config::JFDI::Source::Loader;
use Config::JFDI::Carp;

use Path::Class;
use Config::Any;
use Hash::Merge::Simple;
use Sub::Install;
use Data::Visitor::Callback;
use Clone qw//;

has package => qw/ is ro isa Str /;

has source => qw/ is ro /, handles => [qw/ driver local_suffix no_env env_lookup path found /];

has load_once => qw/ is ro required 1 /, default => 1;

has loaded => qw/ is ro required 1 /, default => 0;

has substitution => qw/ reader _substitution lazy_build 1 isa HashRef /;
sub _build_substitution {
    return {};
}

has default => qw/ is ro lazy_build 1 isa HashRef /;
sub _build_default {
    return {};
}

has path_to => qw/ reader _path_to lazy_build 1 isa Str /;
sub _build_path_to {
    my $self = shift;
    return $self->config->{home} if $self->config->{home};
    return $self->source->path unless $self->source->path_is_file;
    return '.';
}

has _config => qw/ is rw isa HashRef /;


sub BUILD {
    my $self = shift;
    my $given = shift;

    $self->{package} = $given->{name} if defined $given->{name} && ! defined $self->{package} && ! ref $given->{name};

    my ($source, %source);
    if ($given->{file}) {

        if ( 0 ) { # Deprecate the deprecation warning
            carp "The behavior of the 'file' option has changed, pass in 'quiet_deprecation' or 'no_06_warning' to disable this warning"
                unless $given->{quiet_deprecation} || $given->{no_06_warning};
            carp "Warning, overriding path setting with file (\"$given->{file}\" instead of \"$given->{path}\")" if $given->{path};
        }
        $given->{path} = $given->{file};
        $source{path_is_file} = 1;
    }

    {
        for (qw/
            name
            path
            driver

            no_local
            local_suffix

            no_env
            env_lookup

        /) {
            $source{$_} = $given->{$_} if exists $given->{$_};
        }

        carp "Warning, 'local_suffix' will be ignored if 'file' is given, use 'path' instead" if
            exists $source{local_suffix} && exists $given->{file};

        $source{local_suffix} = $given->{config_local_suffix} if $given->{config_local_suffix};

        $source = Config::JFDI::Source::Loader->new( %source );
    }

    $self->{source} = $source;

    for (qw/substitute substitutes substitutions substitution/) {
        if ($given->{$_}) {
            $self->{substitution} = $given->{$_};
            last;
        }
    }

    if (my $package = $given->{install_accessor}) {
        $package = $self->package if $package eq 1;
        Sub::Install::install_sub({
            code => sub {
                return $self->config;
            },
            into => $package,
            as => "config"
        });

    }
}


sub open {
    if ( ! ref $_[0] ) {
        my $class = shift;
        return $class->new( no_06_warning => 1, 1 == @_ ? (file => $_[0]) : @_ )->open;
    }
    my $self = shift;
    carp "You called ->open on an instantiated object with arguments" if @_;
    return unless $self->found;
    return wantarray ? ($self->get, $self) : $self->get;
}

sub get {
    my $self = shift;

    my $config = $self->config;
    return $config;
    # TODO Expand to allow dotted key access (?)
}

sub config {
    my $self = shift;

    return $self->_config if $self->loaded;
    return $self->load;
}

sub load {
    my $self = shift;

    if ($self->loaded && $self->load_once) {
        return $self->get;
    }

    $self->_config($self->default);

    {
        my @read = $self->source->read;

        $self->_load($_) for @read;
    }

    $self->{loaded} = 1;

    {
        my $visitor = Data::Visitor::Callback->new(
            plain_value => sub {
                return unless defined $_;
                $self->substitute($_);
            }
        );
        $visitor->visit( $self->config );

    }

    return $self->config;
}


sub clone {
    my $self = shift;
    return Clone::clone($self->config);
}


sub reload {
    my $self = shift;
    $self->{loaded} = 0;
    return $self->load;
}


sub substitute {
    my $self = shift;

    my $substitution = $self->_substitution;
    $substitution->{ HOME }    ||= sub { shift->path_to( '' ); };
    $substitution->{ path_to } ||= sub { shift->path_to( @_ ); };
    $substitution->{ literal } ||= sub { return $_[ 1 ]; };
    my $matcher = join( '|', keys %$substitution );

    for ( @_ ) {
        s{__($matcher)(?:\((.+?)\))?__}{ $substitution->{ $1 }->( $self, $2 ? split( /,/, $2 ) : () ) }eg;
    }
}

sub path_to {
    my $self = shift;
    my @path = @_;

    my $path_to = $self->_path_to;

    my $path = Path::Class::Dir->new( $path_to, @path );
    if ( -d $path ) {
        return $path;
    }
    else {
        return Path::Class::File->new( $path_to, @path );
    }
}

sub _load {
    my $self = shift;
    my $cfg = shift;

    my ($file, $hash) = %$cfg;

    $self->{_config} = Hash::Merge::Simple->merge($self->_config, $hash);
}


1;

__END__
=pod

=head1 NAME

Config::JFDI - Just * Do it: A Catalyst::Plugin::ConfigLoader-style layer over Config::Any

=head1 VERSION

version 0.065

=head1 DESCRIPTION

Config::JFDI is an implementation of L<Catalyst::Plugin::ConfigLoader> that exists outside of L<Catalyst>.

Essentially, Config::JFDI will scan a directory for files matching a certain name. If such a file is found which also matches an extension
that Config::Any can read, then the configuration from that file will be loaded.

Config::JFDI will also look for special files that end with a "_local" suffix. Files with this special suffix will take
precedence over any other existing configuration file, if any. The precedence takes place by merging the local configuration with the
"standard" configuration via L<Hash::Merge::Simple>.

Finally, you can override/modify the path search from outside your application, by setting the <NAME>_CONFIG variable outside your application (where <NAME>
is the uppercase version of what you passed to Config::JFDI->new).

=head1 SYNPOSIS 

    use Config::JFDI;

    my $config = Config::JFDI->new(name => "my_application", path => "path/to/my/application");
    my $config_hash = $config->get;

This will look for something like (depending on what Config::Any will find):

    path/to/my/application/my_application_local.{yml,yaml,cnf,conf,jsn,json,...} AND

    path/to/my/application/my_application.{yml,yaml,cnf,conf,jsn,json,...}

... and load the found configuration information appropiately, with _local taking precedence.

You can also specify a file directly:

    my $config = Config::JFDI->new(file => "/path/to/my/application/my_application.cnf");

To later reload your configuration, fresh from disk:

    $config->reload;

=head1 Config::Loader

We are currently kicking around ideas for a next-generation configuration loader. The goals are:

    * A universal platform for configuration slurping and post-processing
    * Use Config::Any to do configuration loading
    * A sane API so that developers can roll their own loader according to the needs of their application
    * A friendly interface so that users can have it just DWIM
    * Host/application/instance specific configuration via _local and %ENV

Find more information and contribute at:

Roadmap: L<http://sites.google.com/site/configloader/>

Mailing list: L<http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/config-loader>

=head1 Behavior change of the 'file' parameter in 0.06

In previous versions, Config::JFDI would treat the file parameter as a path parameter, stripping off the extension (ignoring it) and globbing what remained against all the extensions that Config::Any could provide. That is, it would do this:

    Config::JFDI->new( file => 'xyzzy.cnf' );
    # Transform 'xyzzy.cnf' into 'xyzzy.pl', 'xyzzy.yaml', 'xyzzy_local.pl', ... (depending on what Config::Any could parse)

This is probably not what people intended. Config::JFDI will now squeak a warning if you pass 'file' through, but you can suppress the warning with 'no_06_warning' or 'quiet_deprecation'

    Config::JFDI->new( file => 'xyzzy.cnf', no_06_warning => 1 );
    Config::JFDI->new( file => 'xyzzy.cnf', quiet_deprecation => 1 ); # More general

If you *do* want the original behavior, simply pass in the file parameter as the path parameter instead:

    Config::JFDI->new( path => 'xyzzy.cnf' ); # Will work as before

=head1 METHODS

=head2 $config = Config::JFDI->new(...)

You can configure the $config object by passing the following to new:

    name                The name specifying the prefix of the configuration file to look for and 
                        the ENV variable to read. This can be a package name. In any case,
                        :: will be substituted with _ in <name> and the result will be lowercased.

                        To prevent modification of <name>, pass it in as a scalar reference.

    path                The directory to search in

    file                Directly read the configuration from this file. Config::Any must recognize
                        the extension. Setting this will override path

    no_local            Disable lookup of a local configuration. The 'local_suffix' option will be ignored. Off by default

    local_suffix        The suffix to match when looking for a local configuration. "local" By default
                        ("config_local_suffix" will also work so as to be drop-in compatible with C::P::CL)

    no_env              Set this to 1 to disregard anything in the ENV. The 'env_lookup' option will be ignored. Off by default

    env_lookup          Additional ENV to check if $ENV{<NAME>...} is not found

    driver              A hash consisting of Config:: driver information. This is passed directly through
                        to Config::Any

    install_accessor    Set this to 1 to install a Catalyst-style accessor as <name>::config
                        You can also specify the package name directly by setting install_accessor to it 
                        (e.g. install_accessor => "My::Application")

    substitute          A hash consisting of subroutines called during the substitution phase of configuration
                        preparation. ("substitutions" will also work so as to be drop-in compatible with C::P::CL)
                        A substitution subroutine has the following signature: ($config, [ $argument1, $argument2, ... ])

    path_to             The path to dir to use for the __path_to(...)__ substitution. If nothing is given, then the 'home'
                        config value will be used ($config->get->{home}). Failing that, the current directory will be used.

    default             A hash filled with default keys/values

Returns a new Config::JFDI object

=head2 $config_hash = Config::JFDI->open( ... )

As an alternative way to load a config, ->open will pass given arguments to ->new( ... ), then attempt to do ->load

Unlike ->get or ->load, if no configuration files are found, ->open will return undef (or the empty list)

This is so you can do something like:

    my $config_hash = Config::JFDI->open( "/path/to/application.cnf" ) or croak "Couldn't find config file!"

In scalar context, ->open will return the config hash, NOT the config object. If you want the config object, call ->open in list context:

    my ($config_hash, $config) = Config::JFDI->open( ... )

You can pass any arguments to ->open that you would to ->new

=head2 $config->get

=head2 $config->config

=head2 $config->load

Load a config as specified by ->new( ... ) and ENV and return a hash

These will only load the configuration once, so it's safe to call them multiple times without incurring any loading-time penalty

=head2 $config->found

Returns a list of files found

If the list is empty, then no files were loaded/read

=head2 $config->clone

Return a clone of the configuration hash using L<Clone>

This will load the configuration first, if it hasn't already

=head2 $config->reload

Reload the configuration, examining ENV and scanning the path anew

Returns a hash of the configuration

=head2 $config->substitute( <value>, <value>, ... )

For each given <value>, if <value> looks like a substitution specification, then run
the substitution macro on <value> and store the result.

There are three default substitutions (the same as L<Catalyst::Plugin::ConfigLoader>)

=over 4

=item * C<__HOME__> - replaced with C<$c-E<gt>path_to('')>

=item * C<__path_to(foo/bar)__> - replaced with C<$c-E<gt>path_to('foo/bar')>

=item * C<__literal(__FOO__)__> - leaves __FOO__ alone (allows you to use
C<__DATA__> as a config value, for example)

=back

The parameter list is split on comma (C<,>).

You can define your own substitutions by supplying the substitute option to ->new

=head1 SEE ALSO

L<Catalyst::Plugin::ConfigLoader>

L<Config::Any>

L<Catalyst>

L<Config::Merge>

L<Config::General>

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

