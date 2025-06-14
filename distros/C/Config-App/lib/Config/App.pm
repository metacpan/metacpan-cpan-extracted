package Config::App;
# ABSTRACT: Cascading merged application configuration

use 5.010;
use strict;
use warnings;

use Carp qw( croak carp );
use Cwd 'getcwd';
use FindBin ();
use JSON::XS ();
use LWP::UserAgent ();
use POSIX ();
use URI ();
use YAML::XS ();

our $VERSION = '1.19'; # VERSION

$Carp::Internal{ (__PACKAGE__) }++;

sub _locate_root_config {
    my ($config_location) = @_;
    if ($config_location) {
        return undef, $config_location if ( URI->new($config_location)->scheme );
        return ( -f $config_location ) ? ( '/', $config_location ) : ( undef, undef )
            if ( substr( $config_location, 0, 1 ) eq '/' );
    }

    my $locate = sub {
        my ( $abs_paths, $rel_config_locations ) = @_;

        for my $abs_paths (@$abs_paths) {
            for my $test_location (@$rel_config_locations) {
                my @search_path = split( '/', $abs_paths );
                while (@search_path) {
                    my $test_path = join( '/', @search_path );
                    return $test_path || '/', $test_location if ( -f $test_path . '/' . $test_location );
                    pop @search_path;
                }
            }
        }
    };

    my ( $root_dir, $config_file ) = $locate->(
        [ $FindBin::Bin, getcwd() ],
        [ ($config_location) ? $config_location : (
            ( $ENV{CONFIGAPPINIT} ) ? $ENV{CONFIGAPPINIT} : (),
            qw(
                config/app.yaml
                etc/config.yaml
                etc/conf.yaml
                etc/app.yaml
                config.yaml
                conf.yaml
                app.yaml
            )
        ) ],
    );

    return ( length $root_dir and length $config_file ) ? ( $root_dir, $config_file ) : undef;
}

sub _add_to_inc {
    my ( $root_dir, @libs ) = @_;

    for my $lib ( map { $root_dir . '/' . $_ } @libs ) {
        unshift( @INC, $lib ) unless ( grep { $_ eq $lib } @INC );
    }

    return;
}

sub import {
    my $self = shift;

    my ( $root_dir, $config_file, @libs );
    for ( @_, undef ) {
        my @locate_root_config = _locate_root_config($_);

        unless ( $locate_root_config[0] ) {
            push( @libs, $_ );
        }
        elsif ( not $root_dir ) {
            ( $root_dir, $config_file ) = @locate_root_config;
        }
    }

    die "Config::App unable to locate configuration file\n" unless ($config_file);

    _add_to_inc( $root_dir, ( @libs || 'lib' ) ) if $root_dir;

    my $error = do {
        local $@;
        eval { $self->new($config_file) };
        $@;
    };
    chomp($error);
    die $error . "\n" if $error;

    return;
}

{
    my $singleton;

    sub new {
        my ( $self, $location, $no_singleton ) = @_;
        return $singleton if ( not $no_singleton and $singleton );

        ( my $box = ( POSIX::uname )[1] ) =~ s/\..*$//;
        my $conf  = {};

        _process_location({
            box      => $box,
            user     => getpwuid($>) || POSIX::cuserid,
            env      => $ENV{CONFIGAPPENV},
            conf     => $conf,
            optional => 0,
            location => $location,
        });

        $self      = bless( { _conf => $conf }, $self );
        $singleton = $self unless $no_singleton;

        if ( my $libs = $self->get('libs') ) {
           _add_to_inc(
                $self->root_dir,
                ( ref $libs eq 'ARRAY' ) ? @$libs : $libs,
            );
        }

        return $self;
    }

    sub deimport {
        my $self = shift;

        delete $self->{_conf} if ( __PACKAGE__ eq ref $self );
        $singleton = undef;

        {
            no strict 'refs';
            @{ __PACKAGE__ . '::ISA' } = ();
            my $symbol_table = __PACKAGE__ . '::';
            for my $symbol ( keys %$symbol_table ) {
                next if ( $symbol =~ /\A[^:]+::\z/ );
                delete $symbol_table->{$symbol};
            }
        }

        delete $INC{ join( '/', split /(?:'|::)/, __PACKAGE__ ) . '.pm' };

        return;
    }
}

sub find {
    my $class = shift;

    my $self;
    local $@;
    eval {
        $self = $class->new(@_);
    };
    if ($@) {
        return;
    }

    return $self;
}

sub root_dir {
    my ($self) = @_;
    return $self->get( qw( config_app root_dir ) );
}

sub includes {
    my ($self) = @_;
    return $self->get( qw( config_app includes ) );
}

sub get {
    my $self = shift;
    my $data = $self->{_conf};

    $data = $data->{$_} for (@_);
    return _clone($data);
}

sub put {
    my $self      = shift;
    my $new_value = pop;
    my $path      = [@_];
    my $node      = pop @{$path};
    my $error     = do {
        local $@;
        eval {
            my $data = $self->{_conf};
            $data = $data->{$_} for ( @{$path} );
            $data->{$node} = $new_value;
        };
        $@;
    };

    return ($error) ? 0 : 1;
}

sub conf {
    my $self = shift;
    _merge_settings( $self->{_conf}, $_ ) for (@_);
    return _clone( $self->{_conf} );
}

sub _process_location {
    my ($input) = @_;
    my ( $root_dir, $config_file ) = _locate_root_config( $input->{location} );

    my $include = join( '/', grep { defined and $_ ne '/' } $root_dir, $config_file );
    my $sources = [ grep { defined } @{ $input->{sources} || [] }, $input->{location} ];

    my $raw_config = _get_raw_config({
        include  => $include,
        location => $input->{location},
        optional => $input->{optional},
        sources  => $sources,
    });
    return unless $raw_config;

    $input->{conf}->{config_app}{root_dir} = $root_dir
        if ( defined $root_dir and not exists $input->{conf}->{config_app}{root_dir} );

    unless ( grep { $_ eq $include } @{ $input->{conf}->{config_app}{includes} } ) {
        push( @{ $input->{conf}->{config_app}{includes} }, $include );
    }
    else {
        carp "Configuration include recursion encountered when trying to include: $include";
        return;
    }

    my $set = _parse_config({
        raw_config => $raw_config,
        include    => $include,
        sources    => $sources,
    });

    my $sub_process_location = sub { _process_location({
        box      => $input->{box},
        user     => $input->{user},
        env      => $input->{env},
        conf     => $input->{conf},
        location => $_[0],
        optional => $_[1],
        sources  => $sources,
    }) };

    my $fetch_block = sub {
        my ($include_type) = @_;
        my $optional = 'optional_' . $include_type;

        $sub_process_location->( $set->{$include_type}, 0 ) if ( $set->{$include_type} );
        $sub_process_location->( delete( $input->{conf}->{$include_type} ), 0 )
            if ( $input->{conf}->{$include_type} );
        $sub_process_location->( $set->{$optional}, 1 ) if ( $set->{$optional} );
        $sub_process_location->( delete( $input->{conf}->{$optional} ), 1 )
            if ( $input->{conf}->{$optional} );
    };

    $fetch_block->('preinclude');

    my ( $box, $user, $env ) = @$input{ qw( box user env ) };
    _merge_settings( $input->{conf}, $_ ) for (
        grep { defined } (
            map {
                $set->{ join( '|', ( grep { defined } @$_ ) ) }
            } (
                [ 'default'         ],
                [ '+',  '+',   '+'  ], [ '+',  '+'   ],  [ '+'  ],
                [ $box, '+',   '+'  ], [ $box, '+'   ],  [ $box ],
                [ '+',  $user, '+'  ], [ '+',  $user ],
                [ $box, $user, '+'  ], [ $box, $user ],
                [ '+',  '+',   $env ],
                [ '+',  $user, $env ],
                [ $box, '+',   $env ],
                [ $box, $user, $env ],
            )
        )
    );

    $fetch_block->('include');

    return;
}

{
    my $ua;

    sub _get_raw_config {
        my ($input) = @_;

        if ( URI->new( $input->{include} )->scheme ) {
            $ua ||= LWP::UserAgent->new(
                agent      => 'Config-App',
                cookie_jar => {},
                env_proxy  => 1,
            );

            my $res = $ua->get( $input->{include} );

            if ( $res->is_success ) {
                return $res->decoded_content;
            }
            else {
                croak 'Failed to get '
                    . join( ' -> ', map { "\"$_\"" } @{ $input->{sources} } )
                    . '; '
                    . $res->status_line
                    unless $input->{optional};
                return;
            }
        }
        else {
            unless ( $input->{include} ) {
                croak 'Failed to find ' .
                    join( ' -> ', map { "\"$_\"" } @{ $input->{sources} } )
                    unless $input->{optional};
                return;
            }
            else {
                open( my $include_fh, '<', $input->{include} )
                    or croak "Failed to read $input->{include}; $!";
                return join( '', <$include_fh> );
            }
        }
    }
}

{
    my $json_xs;

    sub _parse_config {
        my ($input) = @_;

        my @types = qw( yaml json );
        if ( $input->{include} =~ /\.yaml$/i or $input->{include} =~ /\.yml$/i ) {
            @types = ( 'yaml', grep { $_ ne 'yaml' } @types );
        }
        elsif ( $input->{include} =~ /\.json$/i or $input->{include} =~ /\.js$/i ) {
            @types = ( 'json', grep { $_ ne 'json' } @types );
        }

        my ( $config, @errors );
        for my $type (@types) {
            my $error = do {
                local $@;
                eval {
                    if ( $type eq 'json' ) {
                        $json_xs ||= JSON::XS->new
                            ->utf8
                            ->relaxed
                            ->allow_nonref
                            ->allow_unknown
                            ->allow_blessed
                            ->allow_tags;

                        $config = $json_xs->decode( $input->{raw_config} );
                    }
                    else {
                        $config = YAML::XS::Load( $input->{raw_config} );
                    }
                };
                $@;
            };

            if ($error) {
                my $message =
                    'Failed to parse ' .
                    join( ' -> ', map { "\"$_\"" } @{ $input->{sources} } ) . '; ' .
                    $error;
                croak($message) if ( not $config );
                carp($message);
            }

            last if $config;
        }

        return $config;
    }
}

sub _merge_settings {
    my ( $merge, $source, $is_deep_call ) = @_;
    return unless $source;

    if ( not $is_deep_call and ref $merge eq 'HASH' and ref $source eq 'HASH' ) {
        if ( my $libs = delete $source->{libs} ) {
            if ( not exists $merge->{libs} ) {
                $merge->{libs} = $libs;
            }
            elsif ( ref $merge->{libs} eq 'ARRAY' ) {
                my %libs = map { $_ => 1 } @{ $merge->{libs} }, ( ref $libs eq 'ARRAY' ) ? @$libs : $libs;
                $merge->{libs} = [ sort keys %libs ];
            }
            else {
                my %libs = map { $_ => 1 } $merge->{libs}, ( ref $libs eq 'ARRAY' ) ? @$libs : $libs;
                $merge->{libs} = [ sort keys %libs ];
            }
        }
    }

    if ( ref $merge eq 'HASH' ) {
        for my $key ( keys %{$source} ) {
            if ( exists $merge->{$key} and ref $merge->{$key} eq 'HASH' and ref $source->{$key} eq 'HASH' ) {
                _merge_settings( $merge->{$key}, $source->{$key}, 1 );
            }
            else {
                $merge->{$key} = _clone( $source->{$key} );
            }
        }
    }
    elsif ( ref $merge eq 'ARRAY' ) {
        push( @$source, @$merge );
    }

    return;
}

sub _clone {
    return YAML::XS::Load( YAML::XS::Dump(@_) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::App - Cascading merged application configuration

=head1 VERSION

version 1.19

=for markdown [![test](https://github.com/gryphonshafer/Config-App/workflows/test/badge.svg)](https://github.com/gryphonshafer/Config-App/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Config-App/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Config-App)

=head1 SYNOPSIS

    use Config::App;
    use Config::App 'lib';
    use Config::App ();

    # seeks initial conf file "config/app.yaml" (then others)
    my $conf = Config::App->new;

    # seeks initial conf file "conf/settings.yaml"
    $ENV{CONFIGAPPINIT} = 'conf/settings.yaml';
    my $conf2 = Config::App->new;

    # seeks initial conf file "settings/conf.yaml"
    my $conf3 = Config::App->new('settings/conf.yaml');

    # pulls initial conf file from URL
    my $conf4 = Config::App->new('https://example.com/config/app.yaml');

    # optional enviornment variable that can alter how cascading works
    $ENV{CONFIGAPPENV} = 'production';

    my $username = $conf->get( qw( database primary username ) );
    $conf->put( qw( database primary username new_username_value ) );

    my $full_conf_as_data_structure = $conf->conf;

    my $new_full_conf_as_data_structure = $conf->conf({
        change => { some => { conf => 1138 } }
    });

    # same as new() except will silently return undef on failure
    my $conf5 = Config::App->find;

=head1 DESCRIPTION

The intent of this module is to provide for projects (within a directory tree)
configuration fetcher and merger functionality that supports configuration files
that may include other files and "cascade" or merge bits of these files into an
"active" configuration based on server name, user account name the process is
running under, and/or enviornment variable flag. The goal being that a single
unified configuration can be built from a set of files (real files or URLs) and
slices of that configuration can be used as the active configuration in any
enviornment.

You can write configuration files in YAML or JSON. These files can be local
or served through some sort of URL.

=head2 Cascading Configurations

A configuration file can include a "default" section and any number of override
sections. Each overrides section begins with a pipe-delimited selector in the
form of: server name, user name (running the process), and value of the
CONFIGAPPENV enviornment variable. A "+" character means any and all values,
as does a missing value.

As a concrete example, assume the following YAML configuration file:

    default:
        database:
            username: prime
            password: insecure
    alderaan:
        database:
            username: primary
    titanic|gryphon:
        database:
            username: gryphon
    +|gryphon:
        database:
            password: gryphon
    +|gryphon|other:
        database:
            password: other

In this fairly silly and simple example, the "default" settings are at the top
and define a database username and password. Below that are overrides to the
default. On the server with a hostname of "alderaan", the database username is
"primary"; however, the password remains "insecure" (since it was defined
in the "default" section and left unchanged).

The "+|gryphon" selector means any hostname where the process is running under
the "gryphon" user account. The "+|gryphon|other" means the same but only if
CONFIGAPPENV enviornment variable is set to "other".

=head2 Configuration File Including

Any configuration file can "include" other files by including an "include"
keyword as a direct sub-key from a selector. For example:

    +|gryphon|other:
        database:
            password: other
        include: gryphon_settings.yaml

This will result in the file "gryphon_settings.yaml" being read in and merged
if and only if the "+|gryphon|other" selector is active. Any settings in this
included file with selectors that are active will be added even if they are
not the "+|gryphon|other" selector. However, since the file will only be
included if the "+|gryphon|other" selector is active, the selectors of the
sub-file are irrelevant if the "+|gryphon|other" selector is inactive.

Alternatively, you can opt to put "include" in the root namespace, which will
mean the sub-file is always included.

    +|gryphon|other:
        database:
            password: other
    include: gryphon_settings.yaml

=head3 Optional Configuration File Including

Normally, if you "include" a location that doesn't exist, you'll get an error.
However, if you replace the "include" key word with "optional_include", then
the location will be included if it exists and silently bypassed if it doesn't
exist.

=head3 Pre-Including Configuration Files

When you "include" or "optional_include" configuration files, the included file
or files are included after reading of the current or source configuration file.
Thus, any data in included files will overwrite data in the current or source
configuration file. If you want this reversed, with data in the current or
source configuration file  overwriting data in any included files, use
"preinclude" and "optional_preinclude" respectively.

=head2 Configuration File Finding

When a file is included, it's searched for starting at the current directory
of the program or application, as determined by L<FindBin> initially; and if
that failes, the current working directory. If the file is not found, it will be
looked for one directory level above, and so on and so on, until it's either
found or we get to the top directory level. This means that in a given
application with several nested directories of varying depth and programs within
each, you can use a single configuration file and not have to hard-code paths
into each program.

At any point, either in the C<new()> constructor or as values to "include"
keys, you can stipulate URLs. If any of the configuration returned from
a URL includes an "include" key with a non-URL value, it will be assumed to be
a filename of a local file.

Any file can be either local or URL, and either YAML or JSON. The C<new()>
constructor will believe anything that has a URL schema (i.e. "https://") is
a URL, and it will look at the file extension to determine if the file is
YAML or JSON. (As in: .yaml, .yml, .js, .json)

=head2 Root Directory

The very first local file found (whether as the inital configuration file or as
the first local file found following a URL-based configuration) will determine
the "root_dir" setting that falls under the "config_app" auto-generated
configuration. What this means in practice is that if your application needs to
know its own root directory, set your first local configuration file include
to reference itself from the root directory of the application.

For example, let's say you have a directory structure like this:

    home
        gryphon
            app
                conf
                    settings.yaml
                lib
                    Module.pm
                bin
                    program.pl

Let's say then that the "program.pl" program includes this:

    my $conf = Config::App->new('conf/settings.yaml');

The result of this is that the configuration file "settings.yaml" will get found
and "root_dir" will be set to "/home/gryphon/app", which can be access like so:

    $conf->get( 'config_app', 'root_dir' );

=head2 Included Files

All included files, including the initial file, are listed in an arrayref,
which can be accessed like so:

    $conf->get( 'config_app', 'includes' );

This is mostly for debugging purposes, to know from where your configuration
was derived.

=head1 METHODS

The following are the supported methods of this module:

=head2 new

The constructor will return an object that can be used to query and alter the
derived cascaded configuration.

    # seeks initial conf file "config/app.yaml" (then others)
    my $conf = Config::App->new;

By default, with no parameters passed, the constructor assumes the initial
configuration file is, in order, one of the following:

=over 4

=item *

C<config/app.yaml>

=item *

C<etc/config.yaml>

=item *

C<etc/conf.yaml>

=item *

C<etc/app.yaml>

=item *

C<config.yaml>

=item *

C<conf.yaml>

=item *

C<app.yaml>

=back

You can stipulate an initial configuration file to the constructor:

    # seeks initial conf file "settings/conf.json"
    my $conf = Config::App->new('settings/conf.json');

You can also alternatively set an enviornment variable that will identify the
initial configuration file:

    # seeks initial conf file "conf/settings.yaml"
    $ENV{CONFIGAPPINIT} = 'conf/settings.yaml';
    my $conf = Config::App->new;

=head3 Singleton

The C<new()> constructor assumes that you'll want to have the configuration
object be a singleton, because within a single application, I assumed that it'd
be silly to compile the settings more than once. However, if you really want
a not-singleton behavior, pass any positive value as a second parameter to
the constructor.

    my $conf_0 = Config::App->new( 'file_0.yaml', 1 );
    my $conf_1 = Config::App->new( 'file_1.yaml', 1 );

=head2 find

This is the same thing as C<new()> except if unable to find a configuration
file, it will silently return C<undef>.

=head2 get

This returns a configuration setting or block of settings from the merged/active
application settings. To retrieve a setting of block, pass to get a list where
each node of the list is the node of a configuration tree address. Given the
following example YAML:

    default:
        database:
            dbname: answer
            number: 42

To retrieve this setting, you would:

    $conf->get( 'database', 'answer' );

If instead you made this call:

    my $db = $conf->get('database');

You would expect C<$db> to be:

    {
        dbname => 'answer',
        number => 42,
    }

=head2 put

This method allows you to alter the application configuration at runtime. It
expects that you provide a path to a node and the value that will replace that
node's current value.

    $conf->put( qw( database dbname new_db_name ) );

=head2 conf

This method will return the entire derived cascaded configuration data set.
But more interesting is that you can pass in data structures to alter the
configuration.

    my $full_conf_as_data_structure = $conf->conf;

    my $new_full_conf_as_data_structure = $conf->conf({
        change => { some => { conf => 1138 } }
    });

=head2 root_dir

This is a shortcut to:

    $conf->get( qw( config_app root_dir ) );

=head2 includes

This is a shortcut to:

    $conf->get( qw( config_app includes ) );

=head2 deimport

If for whatever reason you need to completely remove Config::App and its data,
perhaps for a use case where you need to C<use> it a second time as if it was
the first time, this method attempts to set that option up.

=head1 LIBRARY DIRECTORY INJECTION

By default, the call to use the library will result in the "lib" subdirectory
from the found root directory being unshifted to @INC. You can also stipulate
a directory alternative from "lib" in the use line.

    use Config::App;        # add "root_dir/lib"  to @INC
    use Config::App 'lib2'; # add "root_dir/lib2" to @INC

You can also supply multiple library directories and a specific configuration
file location relative to your project's root directory. If you specify a
relative configuration file location, it must be either the first or last value
provided.

    use Config::App qw( lib lib2 config.yaml );

To skip all this behavior, do this:

    use Config::App ();

=head2 Injection via configuration file setting

You can also inject a relative library path or set of paths by using the "libs"
keyword in the configuration file. The "libs" keyword should have either an
arrayref of relative paths or a string of a single relative path, relative to
the project's root directory.

=head1 DIRECT DEPENDENCIES

L<URI>, L<LWP::UserAgent>, L<Carp>, L<FindBin>, L<JSON::XS>, L<YAML::XS>, L<POSIX>.

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Config-App>

=item *

L<MetaCPAN|https://metacpan.org/pod/Config::App>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Config-App/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Config-App>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Config-App>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/G/Config-App.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
