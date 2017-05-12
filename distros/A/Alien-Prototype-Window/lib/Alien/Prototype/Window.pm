package Alien::Prototype::Window;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;
use Carp;
use File::Spec;
use File::Copy qw(copy);
use File::Path qw(mkpath);
use File::Find qw(find);
use File::Basename qw(dirname);
use Alien::scriptaculous;

###############################################################################
# Version number
###############################################################################
our $PWC_VERSION = '1.3';
our $VERSION = '1.3.3';

###############################################################################
# Subroutine:   version()
###############################################################################
# Return the Prototype Window Class version number.
#
# Not to be confused with the 'Alien::Prototype::Window' version number (which
# is the version number of the Perl wrapper).
###############################################################################
sub version {
    return $PWC_VERSION;
}

###############################################################################
# Subroutine:   path()
###############################################################################
# Returns the path to the available copy of Prototype Window Class.
###############################################################################
sub path {
    my $base = $INC{'Alien/Prototype/Window.pm'};
    $base =~ s{\.pm$}{};
    return $base;
}

###############################################################################
# Subroutine:   to_blib()
###############################################################################
# Returns a hash containing paths to the soure files to be copied, and their
# relative destinations.
###############################################################################
sub to_blib {
    my $class = shift;
    my $path  = $class->path();
    my %blib;

    # JS files
    my @js = qw( window window_ext window_effects tooltip debug extended_debug );
    foreach my $file (@js) {
        $file .= '.js';
        my $src = File::Spec->catfile( $path, 'javascripts', $file );
        $blib{$src} = $file;
    }

    # themes
    my $themedir = File::Spec->catdir( $path, 'themes' );
    File::Find::find (
        sub {
            -f $_ && do {
                my $dstdir = $File::Find::dir;
                $dstdir =~ s{^$themedir/?}{};
                $blib{$File::Find::name} = File::Spec->catfile('window', $dstdir, $_);
            }
        },
        $themedir
        );

    # return list of files to install
    return %blib;
}

###############################################################################
# Subroutine:   files()
###############################################################################
# Returns the lsit of files that are installed by Alien::Prototype::Window.
###############################################################################
sub files {
    my $class = shift;
    my %blib  = $class->to_blib();
    return sort values %blib;
}

###############################################################################
# Subroutine:   install($destdir)
# Parameters:   $destdir    - Destination directory
###############################################################################
# Installs the Prototype Window Class into the given '$destdir'.  Throws a
# fatal exception on errors.
###############################################################################
sub install {
    my ($class, $destdir) = @_;

    # install script.aculo.us
    Alien::scriptaculous->install( $destdir );

    # install our files
    my %blib = $class->to_blib();
    while (my ($srcfile, $dest) = each %blib) {
        # get full path to destination file
        my $destfile = File::Spec->catfile( $destdir, $dest );
        # create any required install directories
        my $instdir = dirname( $destfile );
        if (!-d $instdir) {
            mkpath( $instdir ) || croak "can't create '$instdir'; $!";
        }
        # install the file
        copy( $srcfile, $destfile ) || croak "can't copy '$srcfile' to '$instdir'; $!";
    }
}

1;

=head1 NAME

Alien::Prototype::Window - installing and finding Prototype Window Class

=head1 SYNOPSIS

  use Alien::Prototype::Window;
  ...
  $version = Alien::Prototype::Window->version();
  $path    = Alien::Prototype::Window->path();
  ...
  Alien::Prototype::Window->install( $my_destination_directory );

=head1 DESCRIPTION

Please see L<Alien> for the manifesto of the Alien namespace.

=head1 METHODS

=over

=item version()

Return the Prototype Window Class version number. 

Not to be confused with the C<Alien::Prototype::Window> version number
(which is the version number of the Perl wrapper). 

=item path()

Returns the path to the available copy of Prototype Window Class. 

=item to_blib()

Returns a hash containing paths to the soure files to be copied, and their
relative destinations. 

=item files()

Returns the lsit of files that are installed by Alien::Prototype::Window. 

=item install($destdir)

Installs the Prototype Window Class into the given C<$destdir>. Throws a
fatal exception on errors. 

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 LICENSE

Copyright (C) 2007, Graham TerMarsch.  All rights reserved.

This is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://prototype-window.xilinus.com/,
L<Alien::scriptaculous>,
L<Alien>.

=cut
