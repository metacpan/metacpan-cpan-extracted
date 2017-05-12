package Alien::IE7;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;
use Carp;
use File::Spec;
use File::Find qw(find);
use File::Copy qw(copy);
use File::Path qw(mkpath);
use File::Basename qw(basename dirname);

###############################################################################
# Version numbering
###############################################################################
our $IE7_VERSION = '0.9';
our $VERSION     = '0.9.3';

###############################################################################
# Subroutine:   version()
###############################################################################
# Returns the IE7 version number.
#
# Not to be confused with the 'Alien::IE7' version number (which is the version
# number of the Perl wrapper).
###############################################################################
sub version {
    return $IE7_VERSION;
}

###############################################################################
# Subroutine:   path()
###############################################################################
# Returns the path to the available copy of IE7.
###############################################################################
sub path {
    my $base = $INC{'Alien/IE7.pm'};
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
    File::Find::find(
        sub {
            -f && do {
                my $dstdir = $File::Find::dir;
                $dstdir =~ s{^$path/?}{};
                $blib{$File::Find::name} = join('', $dstdir, $_);
            }
        },
        $path
        );
    return %blib;
}

###############################################################################
# Subroutine:   files()
###############################################################################
# Returns the list of files that are installed by Alien::IE7.
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
# Installs the IE7 compatibility library into the given '$destdir'.  Throws a
# fatal exception on errors.
###############################################################################
sub install {
    my ($class, $destdir) = @_;

    # install our files
    my %blib = $class->to_blib();
    while (my ($srcfile, $dest) = each %blib) {
        # Get full path to destination file
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

Alien::IE7 - installing and finding IE7 JS compatibility library

=head1 SYNOPSIS

  use Alien::IE7;
  ...
  $version = Alien::IE7->version();
  $path    = Alien::IE7->path();
  ...
  Alien::IE7->install( $my_destination_directory );

=head1 DESCRIPTION

Please see L<Alien> for the manifesto of the Alien namespace.

=head1 METHODS

=over

=item version()

Returns the IE7 version number. 

Not to be confused with the C<Alien::IE7> version number (which is the
version number of the Perl wrapper). 

=item path()

Returns the path to the available copy of IE7. 

=item to_blib()

Returns a hash containing paths to the source files to be copied, and their
relative destinations. 

=item files()

Returns the list of files that are installed by Alien::IE7. 

=item install($destdir)

Installs the IE7 compatibility library into the given C<$destdir>. Throws a
fatal exception on errors. 

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 LICENSE

Copyright (C) 2007, Graham TerMarsch.  All rights reserved.

This is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://dean.edwards.name/ie7/
L<Alien>.

=cut
