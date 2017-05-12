package Config::Layered;
use warnings;
use strict;
use Data::Dumper;
use Storable qw( dclone );

our $VERSION = '0.000003'; # 0.0.3
$VERSION = eval $VERSION;

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    for ( qw( sources default merge ) ) {
        $self->can($_) || $self->_build_accessor($_);
    }

    for my $arg ( keys %args ) {
        $self->_build_accessor( $arg ) unless $self->can($arg);

        if ( $arg eq 'sources' ) {
            $self->$arg( $self->_normalize_sources($args{$arg}) );
        } else {
            $self->$arg( $args{$arg} );
        }
    }

    $self->default( {} ) 
        unless $self->default;

    $self->sources([ 
            [ 'ConfigAny'       => {} ], 
            [ 'ENV'             => {} ], 
            [ 'Getopt'          => {} ],
    ]) unless $self->sources;

    return $self;

}

sub load_config {
    my ( $self, @args ) = @_;

    # Allow to skip calling ->new()->load_config
    return $self->new( @args )->load_config unless ref $self eq __PACKAGE__;

    my $config = $self->default;

    for my $source ( @{ $self->sources } ) {
        my $pkg = $self->_load_source( $source->[0] )
            ->new( $self, $source->[1] );

        $config = $self->_merge( $config, dclone($pkg->get_config) );
    }

    return $config;
}

sub _normalize_sources {
    my ( $self, $sources ) = @_;

    my @new_sources;
    while ( my $source = shift @{$sources} ) {
        if ( ref @{$self->{sources}}[0] eq 'HASH' ) {
            push @new_sources, [ $source, shift @{$self->{sources}} ];
        } else {
            push @new_sources, [ $source, {} ];
        }
    }
    $self->{sources} = [@new_sources];
}

sub _build_accessor {
    my ( $self, $method ) = @_;
    
    my $accessor = sub {
        my $self = shift;
        $self->{$method} = shift if @_;
        return $self->{$method};
    };
    {
        no strict 'refs';
        *$method = $accessor;
    }
    return ();
}

sub _load_source {
    my ( $self, $source ) = @_;
    
    my $class = "Config::Layered::Source::$source";

    eval "require $class";
    if ( $@ ) {
        eval "require $source";
        if ( $@ ) {
            die "Couldn't find $source or $class";
        } else {
            $class = $source;
        }
    }

    return $class;
}

sub _merge {
    my ( $self, $content, $data ) = @_;

    # Allow this method to be replaced by a coderef.
    return $self->merge->( $content, $data ) if ref $self->merge eq 'CODE';

    if ( ref $content eq 'HASH' ) {
        for my $key ( keys %$content ) {
            if ( ref $content->{$key} eq 'HASH' ) {
                $content->{$key} = $self->_merge($content->{$key}, $data->{$key});
                delete $data->{$key};
            } else {
                $content->{$key} = delete $data->{$key} if exists $data->{$key};
            }
        }
        # Unhandled keys (simply do injection on uneven rhs structure)
        for my $key ( keys %$data ) {
            $content->{$key} = delete $data->{$key};
        }
    }

    return $content;
}

1;

=head1 NAME

Config::Layered - Layered config from files, command line, and other sources.

=head1 DESCRIPTION

Config::Layered aims to make it easy for programmers, operations teams and those
who run the programs to have the configuration methods they prefer with one simple
interface.

By default options will be taken from the program source code itself, then
-- if provided -- a configuration file, and finally command-line options.

=head1 SYNOPSIS

By default options will be taken from the program source code itself, then
merged -- if provided -- with a configuration file, then environment variables
in the form of C<CONFIG_$OPTIONNAME> and finally command-line options.

    my $config = Config::Layered->load_config(
        file         => "/etc/myapp",
        default => {
            verbose => 0,
            run             => 1,
            input           => "/tmp/to_process",
            output          => "/tmp/done_processing",
            plugins         => [ qw( process ) ] 
        },
    );

Given the above, the data structure would look like:

    
    {
        verbose => 0,
        run             => 1,
        input           => "/tmp/to_process",
        output          => "/tmp/done_processing",
        plugins         => [ qw( process ) ] 
    }

Provided a file, C</etc/myapp.yml> with the line C<input: /tmp/pending_process> 
the data structure would look like:

    {
        verbose => 0,
        run             => 1,
        input           => "/tmp/pending_process",
        output          => "/tmp/done_processing",
        plugins         => [ qw( process ) ] 
    }

Provided the command line arguments C<--norun --verbose --output /tmp/completed_process>
-- in addition to the configuration file above -- the data structure would look like:

    {
        verbose         => 1,
        run             => 0,
        input           => "/tmp/pending_process",
        output          => "/tmp/completed_process",
        plugins         => [ qw( process ) ] 
    }

Provided the environment variable C<CONFIG_INPUT="/tmp/awaiting_process>
-- in addition to the configuration file above -- the data structure would look like:

    {
        verbose         => 1,
        run             => 0,
        input           => "/tmp/awaiting_process",
        output          => "/tmp/completed_process",
        plugins         => [ qw( process ) ] 
    }

=head1 METHODS

=head2 load_config

=over 4

=item * file

By default the file given here will be loaded by Config::Any and the data
structure provided will be merged ontop of the default data structure.

Example:

    file => "/etc/myapp",

This will atempt to load C</etc/myapp> as a stem in L<Config::Any>, meanig
files like C</etc/myapp.yml>, C</etc/myapp.conf>, C</etc/myapp.ini> and such
will be checked for existence.

=item * default

This is the default data structure that L<Config::Layered> will load.

Example:

    default => {
        verbose => 1,
        run     => 0,
    },

The above data structure will have C<$config-E<gt>{verbose}> set to 1, and
C<$config-E<gt>{run}> set to 0 if there are no configuration files, and no
command line options used.

=item * sources

A source returns an instance of configuration to merge with previously loaded
sources.  Following a source a specific configuration may be sent the to source.

Example

    sources => [ 'ConfigAny', { file => "/etc/myapp }, 'Getopts' ]

In the above example, L<Config::Layered::Sources::ConfigAny> will be loaded,
and the following hashref will be sent to the source.  This allows source-specific
configuration to be used.  For more information on creating a soure, see
L</CREATING A SOURCE>.

=item * merge

You may provide a method as a coderef that will be used to merge the data
structures returned from a source together.  By default the method used favors
the newer sources that are loaded.

Example:

    merge => sub {
        my ( $lhs, $rhs ) = @_;

        ... Do something with the data structures ...

        return $merged_data_structure;
    }

=back

=head1 INCLUDED SOURCES

Each source provides its own documentation for source-specific options,
please see the POD pages for the source you're interested in learning more
about

=over4 

=item * L<Config::Layered::Source::ConfigAny> is used for configuration files

=item * L<Config::Layered::Source::ENV> is used for environment variables

=item * L<Config::Layered::Sources::Getopt> is used for command-line options

=back

=head1 CREATING A SOURCE

If you would like to create your own source to provide a configuration method,
the following documents the creation of a source.  You can also check
L<Config::Layered::Source::ConfigAny> for a source that is used by default.

=head2 WRITING THE SOURCE CLASS

A source requires at least two methods, C<new> and C<get_config>.

=over 4

=item * new

The C<new> method should take the following arguments and return an instance of itself:

C<$layered> is the instance of L<Config::Layered> which called it.  You may look at all
arguments given at construction of the instance.

C<$arguments> is the source-specific configuration information.  You should B<NOT> parse
C<$config-E<gt>sources> yourself, instead look at C<$arguments>, and optionally fall-back
to using information in C<$layered> to make decisions.

    sub new {
        my ( $class, $layered, $args ) = @_;
        my $self = bless { layered => $layered, args => $args }, $class;
        return $self;
    }

=item * get_config

The C<get_config> method is given no arguments, and expected to return a hashref that
is merged with previous sources, and will be merged over by future sources.

Example:

    sub get_config {
        my ( $self ) = @_;
        
        # Load a specific file with Config::Any
        if ( exists $self->{args}->{file} ) {
            return Config::Any->load_file( { file => $self->{args}->{file} );
        # Otherwise, load the global file with Config::Any
        } elsif ( exists $config->{layered}->{file} ) 
            return Config::Any->load_file( { file => $self->{layered}->{file} );
        }
        # No configuration file, our source is being ignored.
        return {};
    }

=back

=head2 GLOBAL OR SOURCE ARGUMENTS?

Config::Layered will accept any constructor arguments and a source may
look at C<$layered> to check them.  However, source instance specific arguments
are also available.  Both should be supported under the following reasoning:

Suppose that I would like to load a global file, but I would also like to merge arguments
from a configuration file in my home directory.  With only global arguments this isn't 
possible.  With source-specific arguments, this is easily enabled:

    my $config = Config::Layered->get_config( 
        sources => [ 
            'ConfigAny', { file => "/etc/myapp" },
            'ConfigAny', { file => $ENV{"HOME"} . "/.myapp",
        ] ,
    );

Global arguments are useful in the context that writing out the data structure for the
default use-cases and single-use sources can be tedious.

=head1 AUTHOR

=over 4

=item * Kaitlyn Parkhurst (SymKat) I<E<lt>symkat@symkat.comE<gt>> (L<http://symkat.com/>)

=back

=head1 CONTRIBUTORS

=head1 COPYRIGHT

Copyright (c) 2012 the Config::Layered L</AUTHOR> and L</CONTRIBUTORS> as listed
above.

=head1 LICENSE

This library is free software and may be distributed under the same terms as 
perl itself.

=head1 AVAILABILITY

The latest version of this software is available at 
L<https://github.com/symkat/Config-Layered>

