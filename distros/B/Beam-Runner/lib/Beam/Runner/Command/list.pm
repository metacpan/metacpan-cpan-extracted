package Beam::Runner::Command::list;
our $VERSION = '0.010';
# ABSTRACT: List the available containers and services

#pod =head1 SYNOPSIS
#pod
#pod     beam list
#pod     beam list <container>
#pod
#pod =head1 DESCRIPTION
#pod
#pod List the available containers found in the directories defined in
#pod C<BEAM_PATH>, and list the runnable services found in them. Also show
#pod the C<$summary> from the container file, and the abstract from every
#pod service.
#pod
#pod When listing services, this command must load every single class
#pod referenced in the container, but it will not instanciate any object.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<beam>, L<Beam::Runner::Command>, L<Beam::Runner>
#pod
#pod =cut

use strict;
use warnings;
use List::Util qw( any max );
use Path::Tiny qw( path );
use Module::Runtime qw( use_module );
use Beam::Wire;
use Beam::Runner::Util qw( find_container_path );
use Pod::Find qw( pod_where );
use Pod::Simple::SimpleTree;
use Term::ANSIColor qw( color );

# The extensions to remove to show the container's name
my @EXTS = grep { $_ } @Beam::Runner::Util::EXTS;
# A regex to use to remove the container's name
my $EXT_RE = qr/(?:@{[ join '|', @EXTS ]})$/;

#pod =method run
#pod
#pod     my $exit = $class->run;
#pod     my $exit = $class->run( $container );
#pod
#pod Print the list of containers to C<STDOUT>, or, if C<$container> is given,
#pod print the list of runnable services. A runnable service is an object
#pod that consumes the L<Beam::Runnable> role.
#pod
#pod =cut

sub run {
    my ( $class, $container ) = @_;

    if ( !$container ) {
        return $class->_list_containers;
    }

    if ( !$class->_list_services( $container ) ) {
        warn qq{No runnable services in container "$container"\n};
        return 1;
    }

    return 0;
}

#=sub _list_containers
#
#   my $exit = $class->_list_containers
#
# Print all the containers found in the BEAM_PATH to STDOUT
#
#=cut

sub _list_containers {
    my ( $class ) = @_;
    die "Cannot list containers: BEAM_PATH environment variable not set\n"
        unless $ENV{BEAM_PATH};

    my %containers;
    for my $dir ( split /:/, $ENV{BEAM_PATH} ) {
        my $p = path( $dir );
        my $i = $p->iterator( { recurse => 1, follow_symlinks => 1 } );
        while ( my $file = $i->() ) {
            next unless $file->is_file;
            next unless $file =~ $EXT_RE;
            my $name = $file->relative( $p );
            $name =~ s/$EXT_RE//;
            $containers{ $name } ||= $file;
        }
    }

    my @container_names = sort keys %containers;
    my $printed = 0;
    for my $i ( 0..$#container_names ) {
        if ( $printed ) {
            print "\n";
            $printed = 0;
        }
        $printed += $class->_list_services( $containers{ $container_names[ $i ] } );
    }

    return 0;
}

#=sub _list_services
#
#   my $exit = $class->_list_services( $container );
#
# Print all the runnable services found in the container to STDOUT
#
#=cut

sub _list_services {
    my ( $class, $container ) = @_;
    my $path = find_container_path( $container );
    my $cname = $path->basename( @EXTS );
    my $wire = Beam::Wire->new(
        file => $path,
    );

    my $config = $wire->config;
    my %services;
    for my $name ( keys %$config ) {
        my ( $name, $abstract ) = _list_service( $wire, $name, $config->{$name} );
        next unless $name;
        $services{ $name } = $abstract;
    }
    return 0 unless keys %services;

    my ( $bold, $reset ) = ( color( 'bold' ), color( 'reset' ) );
    print "$bold$cname$reset" . ( eval { " -- " . $wire->get( '$summary' ) } || '' ) . "\n";

    my $size = max map { length } keys %services;
    print join( "\n", map { sprintf "- $bold%-${size}s$reset -- %s", $_, $services{ $_ } } sort keys %services ), "\n";
    return 1;
}

#=sub _list_service
#
#   my $service_info = _list_service( $wire, $name, $config );
#
# If the given service is a runnable service, return the information
# about it ready to be printed to STDOUT. $wire is a Beam::Wire object,
# $name is the name of the service, $config is the service's
# configuration hash
#
#=cut

sub _list_service {
    my ( $wire, $name, $svc ) = @_;

    # If it doesn't look like a service, we don't care
    return unless $wire->is_meta( $svc, 1 );

    # Services that are just references to other services should still
    # be available under their referenced name
    my %svc = %{ $wire->normalize_config( $svc ) };
    if ( $svc{ ref } ) {
        my $ref_svc = $wire->get_config( $svc{ ref } );
        return _list_service( $wire, $name, $ref_svc );
    }

    # Services that extend other services must be resolved to find their
    # class and roles
    my %merged = $wire->merge_config( %svc );
    #; use Data::Dumper;
    #; print "$name merged: " . Dumper \%merged;
    my $class = $merged{ class };
    my @roles = @{ $merged{ with } || [] };

    # Can we determine this object is runnable without loading anything?
    if ( grep { $_ eq 'Beam::Runnable' } @roles ) {
        return _get_service_info( $name, $class, \%merged );
    }

    if ( eval { any {; use_module( $_ )->DOES( 'Beam::Runnable' ) } $class, @roles } ) {
        return _get_service_info( $name, $class, \%merged );
    }

    return;
}

#=sub _get_service_info( $name, $class )
#
#   my ( $name, $abstract ) = _get_service_info( $name, $class, $config );
#
# Get the information about the given service. Opens the C<$class>
# documentation to find the class's abstract (the C<=head1 NAME>
# section). If C<$config> contains a C<summary> in its C<args> hashref,
# will use that in place of the POD documentation.
#
#=cut

sub _get_service_info {
    my ( $name, $class, $config ) = @_;
    if ( $config->{args}{summary} ) {
        # XXX: This does not allow good defaults from the object
        # itself... There's no way to get that without instantiating the
        # object, which means potentially doing a lot of work like
        # connecting to a database. If we had some way of making things
        # extra lazy, we could create the object without doing much
        # work...
        return $name, $config->{args}{summary};
    }
    my $pod_path = pod_where( { -inc => 1 }, $class );
    return $name, $class unless $pod_path;

    my $pod_root = Pod::Simple::SimpleTree->new->parse_file( $pod_path )->root;
    #; use Data::Dumper;
    #; print Dumper $pod_root;
    my @nodes = @{$pod_root}[2..$#$pod_root];
    #; print Dumper \@nodes;
    my ( $name_i ) = grep { $nodes[$_][0] eq 'head1' && $nodes[$_][2] eq 'NAME' } 0..$#nodes;
    return $name, $class unless defined $name_i;

    my $abstract = $nodes[ $name_i + 1 ][2];
    return $name, $abstract;
}

1;

__END__

=pod

=head1 NAME

Beam::Runner::Command::list - List the available containers and services

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    beam list
    beam list <container>

=head1 DESCRIPTION

List the available containers found in the directories defined in
C<BEAM_PATH>, and list the runnable services found in them. Also show
the C<$summary> from the container file, and the abstract from every
service.

When listing services, this command must load every single class
referenced in the container, but it will not instanciate any object.

=head1 METHODS

=head2 run

    my $exit = $class->run;
    my $exit = $class->run( $container );

Print the list of containers to C<STDOUT>, or, if C<$container> is given,
print the list of runnable services. A runnable service is an object
that consumes the L<Beam::Runnable> role.

=head1 SEE ALSO

L<beam>, L<Beam::Runner::Command>, L<Beam::Runner>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
