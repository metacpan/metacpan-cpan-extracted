package Beam::Make;
our $VERSION = '0.003';
# ABSTRACT: Recipes to declare and resolve dependencies between things

#pod =head1 SYNOPSIS
#pod
#pod     ### container.yml
#pod     # This Beam::Wire container stores shared objects for our recipes
#pod     dbh:
#pod         $class: DBI
#pod         $method: connect
#pod         $args:
#pod             - dbi:SQLite:RECENT.db
#pod
#pod     ### Beamfile
#pod     # This file contains our recipes
#pod     # Download a list of recent changes to CPAN
#pod     RECENT-6h.json:
#pod         commands:
#pod             - curl -O https://www.cpan.org/RECENT-6h.json
#pod
#pod     # Parse that JSON file into a CSV using an external program
#pod     RECENT-6h.csv:
#pod         requires:
#pod             - RECENT-6h.json
#pod         commands:
#pod             - yfrom json RECENT-6h.json | yq '.recent.[]' | yto csv > RECENT-6h.csv
#pod
#pod     # Build a SQLite database to hold the recent data
#pod     RECENT.db:
#pod         $class: Beam::Make::DBI::Schema
#pod         dbh: { $ref: 'container.yml:dbh' }
#pod         schema:
#pod             - table: recent
#pod               columns:
#pod                 - path: VARCHAR(255)
#pod                 - epoch: DOUBLE
#pod                 - type: VARCHAR(10)
#pod
#pod     # Load the recent data CSV into the SQLite database
#pod     cpan-recent:
#pod         $class: Beam::Make::DBI::CSV
#pod         requires:
#pod             - RECENT.db
#pod             - RECENT-6h.csv
#pod         dbh: { $ref: 'container.yml:dbh' }
#pod         table: recent
#pod         file: RECENT-6h.csv
#pod
#pod     ### Load the recent data into our database
#pod     $ beam make cpan-recent
#pod
#pod =head1 DESCRIPTION
#pod
#pod C<Beam::Make> allows an author to describe how to build some thing (a
#pod file, some data in a database, an image, a container, etc...) and the
#pod relationships between things. This is similar to the classic C<make>
#pod program used to build some software packages.
#pod
#pod Each thing is a C<recipe> and can depend on other recipes. A user runs
#pod the C<beam make> command to build the recipes they want, and
#pod C<Beam::Make> ensures that the recipe's dependencies are satisfied
#pod before building the recipe.
#pod
#pod This class is a L<Beam::Runnable> object and can be embedded in other
#pod L<Beam::Wire> containers.
#pod
#pod =head2 Recipe Classes
#pod
#pod Unlike C<make>, C<Beam::Make> recipes can do more than just execute
#pod a series of shell scripts. Each recipe is a Perl class that describes
#pod how to build the desired thing and how to determine if that thing needs
#pod to be rebuilt.
#pod
#pod These recipe classes come with C<Beam::Make>:
#pod
#pod =over
#pod
#pod =item * L<File|Beam::Make::File> - The default recipe class that creates
#pod a file using one or more shell commands (a la C<make>)
#pod
#pod =item * L<DBI|Beam::Make::DBI> - Write data to a database
#pod
#pod =item * L<DBI::Schema|Beam::Make::DBI::Schema> - Create a database
#pod schema
#pod
#pod =item * L<DBI::CSV|Beam::Make::DBI::CSV> - Load data from a CSV into
#pod a database table
#pod
#pod =item * L<Docker::Image|Beam::Make::Docker::Image> - Build or pull a Docker image
#pod
#pod =item * L<Docker::Container|Beam::Make::Docker::Container> - Build a Docker container
#pod
#pod =back
#pod
#pod Future recipe class ideas are:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod B<Template rendering>: Files could be generated from a configuration
#pod file or database and a template.
#pod
#pod =item *
#pod
#pod B<Docker compose>: An entire docker-compose network could be rebuilt.
#pod
#pod =item *
#pod
#pod B<System services (init daemon, systemd service, etc...)>: Services
#pod could depend on their configuration files (built with a template) and be
#pod restarted when their configuration file is updated.
#pod
#pod =back
#pod
#pod =head2 Beamfile
#pod
#pod The C<Beamfile> defines the recipes. To avoid the pitfalls of C<Makefile>, this is
#pod a YAML file containing a mapping of recipe names to recipe configuration. Each
#pod recipe configuration is a mapping containing the attributes for the recipe class.
#pod The C<$class> special configuration key declares the recipe class to use. If no
#pod C<$class> is specified, the default L<Beam::Wire::File> recipe class is used.
#pod All recipe classes inherit from L<Beam::Class::Recipe> and have the L<name|Beam::Class::Recipe/name>
#pod and L<requires|Beam::Class::Recipe/requires> attributes.
#pod
#pod For examples, see the L<Beam::Wire examples directory on
#pod Github|https://github.com/preaction/Beam-Make/tree/master/eg>.
#pod
#pod =head2 Object Containers
#pod
#pod For additional configuration, create a L<Beam::Wire> container and
#pod reference the objects inside using C<< $ref: "<container>:<service>" >>
#pod as the value for a recipe attribute.
#pod
#pod =head1 TODO
#pod
#pod =over
#pod
#pod =item Target names in C<Beamfile> should be regular expressions
#pod
#pod This would work like Make's wildcard recipes, but with Perl regexp. The
#pod recipe object's name is the real name, but the recipe chosen is the one
#pod the matches the regexp.
#pod
#pod =item Environment variables should interpolate into all attributes
#pod
#pod Right now, the C<< NAME=VALUE >> arguments to C<beam make> only work in
#pod recipes that use shell scripts (like L<Beam::Make::File>). It would be
#pod nice if they were also interpolated into other recipe attributes.
#pod
#pod =item Recipes should be able to require wildcards and directories
#pod
#pod Recipe requirements should be able to depend on patterns, like all
#pod C<*.conf> files in a directory. It should also be able to depend on
#pod a directory, which would be the same as depending on every file,
#pod recursively, in that directory.
#pod
#pod This would allow rebuilding a ZIP file when something changes, or
#pod rebuilding a Docker image when needed.
#pod
#pod =item Beam::Wire should support the <container>:<service> syntax
#pod for references
#pod
#pod The L<Beam::Wire> class should handle the C<BEAM_PATH> environment
#pod variable directly and be able to resolve services from other files
#pod without building another C<Beam::Wire> object in the container.
#pod
#pod =item Beam::Wire should support resolving objects in arbitrary data
#pod structures
#pod
#pod L<Beam::Wire> should have a class method that one can pass in a hash and
#pod get back a hash with any C<Beam::Wire> object references resolved,
#pod including C<$ref> or C<$class> object.
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Wire>
#pod
#pod =cut

use v5.20;
use warnings;
use Log::Any qw( $LOG );
use Moo;
use experimental qw( signatures postderef );
use Time::Piece;
use YAML ();
use Beam::Wire;
use Scalar::Util qw( blessed );
use List::Util qw( max );
use Beam::Make::Cache;
use File::stat;
with 'Beam::Runnable';

has conf => ( is => 'ro', default => sub { YAML::LoadFile( 'Beamfile' ) } );
# Beam::Wire container objects
has _wire => ( is => 'ro', default => sub { {} } );

sub run( $self, @argv ) {
    my ( @targets, %vars );

    for my $arg ( @argv ) {
        if ( $arg =~ /^([^=]+)=([^=]+)$/ ) {
            $vars{ $1 } = $2;
        }
        else {
            push @targets, $arg;
        }
    }

    local @ENV{ keys %vars } = values %vars;
    my $conf = $self->conf;
    my $cache = Beam::Make::Cache->new;

    # Targets must be built in order
    # Prereqs satisfied by original target remain satisfied
    my %recipes; # Built recipes
    my @target_stack;
    # Build a target (if necessary) and return its last modified date.
    # Each dependent will be checked against their depencencies' last
    # modified date to see if they need to be updated
    my $build = sub( $target ) {
        $LOG->debug( "Want to build: $target" );
        if ( grep { $_ eq $target } @target_stack ) {
            die "Recursion at @target_stack";
        }
        # If we already have the recipe, it must already have been run
        if ( $recipes{ $target } ) {
            $LOG->debug( "Nothing to do: $target already built" );
            return $recipes{ $target }->last_modified;
        }

        # If there is no recipe for the target, it must be a source
        # file. Source files cannot be built, but we do want to know
        # when they were last modified
        if ( !$conf->{ $target } ) {
            $LOG->debug(
                "$target has no recipe and "
                . ( -e $target ? 'exists as a file' : 'does not exist as a file' )
            );
            return stat( $target )->mtime if -e $target;
            die $LOG->errorf( q{No recipe for target "%s" and file does not exist}."\n", $target );
        }

        # Resolve any references in the recipe object via Beam::Wire
        # containers.
        my $target_conf = $self->_resolve_ref( $conf->{ $target } );
        my $class = delete( $target_conf->{ '$class' } ) || 'Beam::Make::File';
        $LOG->debug( "Building recipe object $target ($class)" );
        eval "require $class";
        if ( $@ ) {
            die "Could not load $class: $@";
        }
        my $recipe = $recipes{ $target } = $class->new(
            $target_conf->%*,
            name => $target,
            cache => $cache,
        );

        my $requires_modified = 0;
        if ( my @requires = $recipe->requires->@* ) {
            $LOG->debug( "Checking requirements for $target: @requires" );
            push @target_stack, $target;
            for my $require ( @requires ) {
                $requires_modified = max $requires_modified, __SUB__->( $require );
            }
            pop @target_stack;
        }

        # Do we need to build this recipe?
        my $result;
        if ( $requires_modified > ( $recipe->last_modified || -1 ) ) {
            $LOG->debug( "Building $target" );
            $recipe->make( %vars );
            $result = $LOG->info( "$target updated (modified: " . $recipe->last_modified . ")" );
        }
        else {
            $result = $LOG->info( "$target up-to-date (modified: " . $recipe->last_modified . ")" );
        }
        if ( !@target_stack && !$LOG->is_info ) {
            # We were directly asked to build this, so let the user
            # know about it
            say $result;
        }
        return $recipe->last_modified;
    };
    $build->( $_ ) for @targets;
}

# Resolve any references via Beam::Wire container lookups
sub _resolve_ref( $self, $conf ) {
    return $conf if !ref $conf || blessed $conf;
    if ( ref $conf eq 'HASH' ) {
        if ( grep { $_ !~ /^\$/ } keys %$conf ) {
            my %resolved;
            for my $key ( keys %$conf ) {
                $resolved{ $key } = $self->_resolve_ref( $conf->{ $key } );
            }
            return \%resolved;
        }
        else {
            # All keys begin with '$', so this must be a reference
            # XXX: We should add the 'file:path' syntax to
            # Beam::Wire directly. We could even call it as a class
            # method! We should also move BEAM_PATH resolution to
            # Beam::Wire directly...
            # A single Beam::Wire->resolve( $conf ) should recursively
            # resolve the refs in a hash (like this entire subroutine
            # does), but also allow defining inline objects (with
            # $class)
            my ( $file, $service ) = split /:/, $conf->{ '$ref' }, 2;
            my $wire = $self->_wire->{ $file };
            if ( !$wire ) {
                for my $path ( split /:/, $ENV{BEAM_PATH} ) {
                    next unless -e join '/', $path, $file;
                    $wire = $self->_wire->{ $file } = Beam::Wire->new( file => join '/', $path, $file );
                }
            }
            return $wire->get( $service );
        }
    }
    elsif ( ref $conf eq 'ARRAY' ) {
        my @resolved;
        for my $i ( 0..$#$conf ) {
            $resolved[$i] = $self->_resolve_ref( $conf->[$i] );
        }
        return \@resolved;
    }
}

1;

__END__

=pod

=head1 NAME

Beam::Make - Recipes to declare and resolve dependencies between things

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    ### container.yml
    # This Beam::Wire container stores shared objects for our recipes
    dbh:
        $class: DBI
        $method: connect
        $args:
            - dbi:SQLite:RECENT.db

    ### Beamfile
    # This file contains our recipes
    # Download a list of recent changes to CPAN
    RECENT-6h.json:
        commands:
            - curl -O https://www.cpan.org/RECENT-6h.json

    # Parse that JSON file into a CSV using an external program
    RECENT-6h.csv:
        requires:
            - RECENT-6h.json
        commands:
            - yfrom json RECENT-6h.json | yq '.recent.[]' | yto csv > RECENT-6h.csv

    # Build a SQLite database to hold the recent data
    RECENT.db:
        $class: Beam::Make::DBI::Schema
        dbh: { $ref: 'container.yml:dbh' }
        schema:
            - table: recent
              columns:
                - path: VARCHAR(255)
                - epoch: DOUBLE
                - type: VARCHAR(10)

    # Load the recent data CSV into the SQLite database
    cpan-recent:
        $class: Beam::Make::DBI::CSV
        requires:
            - RECENT.db
            - RECENT-6h.csv
        dbh: { $ref: 'container.yml:dbh' }
        table: recent
        file: RECENT-6h.csv

    ### Load the recent data into our database
    $ beam make cpan-recent

=head1 DESCRIPTION

C<Beam::Make> allows an author to describe how to build some thing (a
file, some data in a database, an image, a container, etc...) and the
relationships between things. This is similar to the classic C<make>
program used to build some software packages.

Each thing is a C<recipe> and can depend on other recipes. A user runs
the C<beam make> command to build the recipes they want, and
C<Beam::Make> ensures that the recipe's dependencies are satisfied
before building the recipe.

This class is a L<Beam::Runnable> object and can be embedded in other
L<Beam::Wire> containers.

=head2 Recipe Classes

Unlike C<make>, C<Beam::Make> recipes can do more than just execute
a series of shell scripts. Each recipe is a Perl class that describes
how to build the desired thing and how to determine if that thing needs
to be rebuilt.

These recipe classes come with C<Beam::Make>:

=over

=item * L<File|Beam::Make::File> - The default recipe class that creates
a file using one or more shell commands (a la C<make>)

=item * L<DBI|Beam::Make::DBI> - Write data to a database

=item * L<DBI::Schema|Beam::Make::DBI::Schema> - Create a database
schema

=item * L<DBI::CSV|Beam::Make::DBI::CSV> - Load data from a CSV into
a database table

=item * L<Docker::Image|Beam::Make::Docker::Image> - Build or pull a Docker image

=item * L<Docker::Container|Beam::Make::Docker::Container> - Build a Docker container

=back

Future recipe class ideas are:

=over

=item *

B<Template rendering>: Files could be generated from a configuration
file or database and a template.

=item *

B<Docker compose>: An entire docker-compose network could be rebuilt.

=item *

B<System services (init daemon, systemd service, etc...)>: Services
could depend on their configuration files (built with a template) and be
restarted when their configuration file is updated.

=back

=head2 Beamfile

The C<Beamfile> defines the recipes. To avoid the pitfalls of C<Makefile>, this is
a YAML file containing a mapping of recipe names to recipe configuration. Each
recipe configuration is a mapping containing the attributes for the recipe class.
The C<$class> special configuration key declares the recipe class to use. If no
C<$class> is specified, the default L<Beam::Wire::File> recipe class is used.
All recipe classes inherit from L<Beam::Class::Recipe> and have the L<name|Beam::Class::Recipe/name>
and L<requires|Beam::Class::Recipe/requires> attributes.

For examples, see the L<Beam::Wire examples directory on
Github|https://github.com/preaction/Beam-Make/tree/master/eg>.

=head2 Object Containers

For additional configuration, create a L<Beam::Wire> container and
reference the objects inside using C<< $ref: "<container>:<service>" >>
as the value for a recipe attribute.

=head1 TODO

=over

=item Target names in C<Beamfile> should be regular expressions

This would work like Make's wildcard recipes, but with Perl regexp. The
recipe object's name is the real name, but the recipe chosen is the one
the matches the regexp.

=item Environment variables should interpolate into all attributes

Right now, the C<< NAME=VALUE >> arguments to C<beam make> only work in
recipes that use shell scripts (like L<Beam::Make::File>). It would be
nice if they were also interpolated into other recipe attributes.

=item Recipes should be able to require wildcards and directories

Recipe requirements should be able to depend on patterns, like all
C<*.conf> files in a directory. It should also be able to depend on
a directory, which would be the same as depending on every file,
recursively, in that directory.

This would allow rebuilding a ZIP file when something changes, or
rebuilding a Docker image when needed.

=item Beam::Wire should support the <container>:<service> syntax
for references

The L<Beam::Wire> class should handle the C<BEAM_PATH> environment
variable directly and be able to resolve services from other files
without building another C<Beam::Wire> object in the container.

=item Beam::Wire should support resolving objects in arbitrary data
structures

L<Beam::Wire> should have a class method that one can pass in a hash and
get back a hash with any C<Beam::Wire> object references resolved,
including C<$ref> or C<$class> object.

=back

=head1 SEE ALSO

L<Beam::Wire>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
