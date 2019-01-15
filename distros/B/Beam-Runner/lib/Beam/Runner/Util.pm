package Beam::Runner::Util;
our $VERSION = '0.015';
# ABSTRACT: Utilities for Beam::Runner command classes

#pod =head1 SYNOPSIS
#pod
#pod     use Beam::Runner::Util qw( find_container_path );
#pod
#pod     my $path = find_container_path( $container_name );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module has some shared utility functions for creating
#pod L<Beam::Runner::Command> classes.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Runner>, L<beam>, L<Exporter>
#pod
#pod =cut

use strict;
use warnings;
use Exporter 'import';
use Path::Tiny qw( path );

our @EXPORT_OK = qw( find_container_path find_containers );

# File extensions to try to find, starting with no extension (which is
# to say the extension is given by the user's input)
our @EXTS = ( "", qw( .yml .yaml .json .xml .pl ) );
# A regex to use to remove the container's name
my $EXT_RE = qr/(?:@{[ join '|', @EXTS ]})$/;

# The "BEAM_PATH" separator value. Windows uses ';' to separate
# PATH-like variables, everything else uses ':'
our $PATHS_SEP = $^O eq 'MSWin32' ? ';' : ':';

#pod =sub find_containers
#pod
#pod     my %container = find_containers();
#pod
#pod Returns a list of C<name> and C<path> pairs pointing to all the containers
#pod in the C<BEAM_PATH> paths.
#pod
#pod =cut

sub find_containers {
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
    return %containers;
}

#pod =sub find_container_path
#pod
#pod     my $path = find_container_path( $container_name );
#pod
#pod Find the path to the given container. If the given container is already
#pod an absolute path, it is simply returned. Otherwise, the container is
#pod searched for in the directories defined by the C<BEAM_PATH> environment
#pod variable.
#pod
#pod If the container cannot be found, throws an exception with a user-friendly
#pod error message.
#pod
#pod =cut

sub find_container_path {
    my ( $container ) = @_;
    my $path;
    if ( path( $container )->is_file ) {
        return path( $container );
    }

    my @dirs = ( "." );
    if ( $ENV{BEAM_PATH} ) {
        push @dirs, split /$PATHS_SEP/, $ENV{BEAM_PATH};
    }

    DIR: for my $dir ( @dirs ) {
        my $d = path( $dir );
        for my $ext ( @EXTS ) {
            my $f = $d->child( $container . $ext );
            if ( $f->exists ) {
                $path = $f;
                last DIR;
            }
        }
    }

    die sprintf qq{Could not find container "%s" in directories: %s\n},
        $container, join( $PATHS_SEP, @dirs )
        unless $path;

    return $path;
}

1;

__END__

=pod

=head1 NAME

Beam::Runner::Util - Utilities for Beam::Runner command classes

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use Beam::Runner::Util qw( find_container_path );

    my $path = find_container_path( $container_name );

=head1 DESCRIPTION

This module has some shared utility functions for creating
L<Beam::Runner::Command> classes.

=head1 SUBROUTINES

=head2 find_containers

    my %container = find_containers();

Returns a list of C<name> and C<path> pairs pointing to all the containers
in the C<BEAM_PATH> paths.

=head2 find_container_path

    my $path = find_container_path( $container_name );

Find the path to the given container. If the given container is already
an absolute path, it is simply returned. Otherwise, the container is
searched for in the directories defined by the C<BEAM_PATH> environment
variable.

If the container cannot be found, throws an exception with a user-friendly
error message.

=head1 SEE ALSO

L<Beam::Runner>, L<beam>, L<Exporter>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
