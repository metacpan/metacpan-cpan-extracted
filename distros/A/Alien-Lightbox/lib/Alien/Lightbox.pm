package Alien::Lightbox;

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
use File::Basename qw(basename dirname);
use Alien::scriptaculous;

###############################################################################
# Version number
###############################################################################
our $LIGHTBOX_VERSION = '2.03.3';
our $VERSION = '2.03.3.4';

###############################################################################
# Subroutine:   version()
###############################################################################
# Returns the Lightbox version number.
#
# Not to be confused with the 'Alien::Lightbox' version number (which is the
# version number of the Perl wrapper).
###############################################################################
sub version {
    return $LIGHTBOX_VERSION;
}

###############################################################################
# Subroutine:   path()
###############################################################################
# Returns the path to the available copy of Lightbox.
###############################################################################
sub path {
    my $base = $INC{'Alien/Lightbox.pm'};
    $base =~ s{\.pm$}{};
    return $base;
}

###############################################################################
# Subroutine:   to_blib()
###############################################################################
# Returns a hash containing paths to the source files to be copied, and their
# relative destinations.
###############################################################################
sub to_blib {
    my $class = shift;
    my $path  = $class->path();
    my %blib;

    # JS/CSS files
    my @files = qw(js/lightbox.js css/lightbox.css);
    foreach my $file (@files) {
        my $src = File::Spec->catfile( $path, $file );
        $blib{$src} = basename($file);
    }

    # images
    my $imagedir = File::Spec->catdir( $path, 'images' );
    File::Find::find(
        sub {
            -f $_ && do {
                my $dstdir = $File::Find::dir;
                $dstdir =~ s{^$imagedir/?}{};
                $blib{$File::Find::name} = File::Spec->catfile('lightbox', $dstdir, $_);
            }
        },
        $imagedir
        );

    # return list of files to install
    return %blib;
}

###############################################################################
# Subroutine:   files()
###############################################################################
# Returns the list of files that are installed by Alien::Lightbox.
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
# Installs the Lightbox into the given '$destdir'.  Throws a fatal exception on
# errors.
###############################################################################
sub install {
    my ($class, $destdir) = @_;

    # install scriptaculous
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

Alien::Lightbox - (DEPRECATED) installing and finding Lightbox JS

=head1 SYNOPSIS

  use Alien::Lightbox;
  ...
  $version = Alien::Lightbox->version();
  $path    = Alien::Lightbox->path();
  ...
  Alien::Lightbox->install( $my_destination_directory );

=head1 DESCRIPTION

B<DEPRECATED> - DO NOT USE.

Please see L<Alien> for the manifesto of the Alien namespace.

=head1 METHODS

=over

=item version()

Returns the Lightbox version number. 

Not to be confused with the C<Alien::Lightbox> version number (which is the
version number of the Perl wrapper). 

=item path()

Returns the path to the available copy of Lightbox. 

=item to_blib()

Returns a hash containing paths to the source files to be copied, and their
relative destinations. 

=item files()

Returns the list of files that are installed by Alien::Lightbox. 

=item install($destdir)

Installs the Lightbox into the given C<$destdir>. Throws a fatal exception
on errors. 

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 LICENSE

Copyright (C) 2007, Graham TerMarsch.  All rights reserved.

This is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.huddletogether.com/projects/lightbox2/,
L<Alien::scriptaculous>,
L<Alien>.

=cut
