package Alien::Prototype;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;
use Carp;
use File::Spec;
use File::Copy qw(copy);
use File::Path qw(mkpath);
use File::Basename qw(dirname);

###############################################################################
# Version number.
###############################################################################
our $PROTOTYPE_VERSION = '1.6.0';
our $VERSION = '1.6.0.2';

###############################################################################
# Subroutine:   version()
###############################################################################
# Return the Prototype version number.
#
# Not to be confused with the 'Alien::Prototype' version number (which is the
# version number of the Perl wrapper).
###############################################################################
sub version {
    return $PROTOTYPE_VERSION;
}

###############################################################################
# Subroutine:   path()
###############################################################################
# Returns the path to the available copy of the Prototype JS library.
###############################################################################
sub path {
    my $base = $INC{'Alien/Prototype.pm'};
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
    my @files = (qw( prototype.js ));
    my %blib  = map { (File::Spec->catfile($path,$_) => $_) } @files;
    return %blib;
}

###############################################################################
# Subroutine:   files()
###############################################################################
# Returns the list of files that are installed by Alien::Prototype.
###############################################################################
sub files {
    my $class = shift;
    my %blib  = $class->to_blib();
    return sort values %blib;
}

###############################################################################
# Subroutine:   install($destdir)
# Parameters:   $destdir        - Destination directory
###############################################################################
# Installs the Prototype JS library into the given '$destdir'.  Throws a fatal
# exception on errors.
###############################################################################
sub install {
    my ($class, $destdir) = @_;

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

Alien::Prototype - installing and finding Prototype JS library

=head1 SYNOPSIS

  use Alien::Prototype;
  ...
  $version = Alien::Prototype->version();
  $path    = Alien::Prototype->path();
  ...
  Alien::Prototype->install( $my_destination_directory );

=head1 DESCRIPTION

Please see L<Alien> for the manifesto of the Alien namespace.

=head1 METHODS

=over

=item version()

Return the Prototype version number. 

Not to be confused with the C<Alien::Prototype> version number (which is
the version number of the Perl wrapper). 

=item path()

Returns the path to the available copy of the Prototype JS library. 

=item to_blib()

Returns a hash containing paths to the source files to be copied, and their
relative destinations. 

=item files()

Returns the list of files that are installed by Alien::Prototype. 

=item install($destdir)

Installs the Prototype JS library into the given C<$destdir>. Throws a
fatal exception on errors. 

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 LICENSE

Copyright (C) 2007, Graham TerMarsch.  All rights reserved.

This is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.prototypejs.org/,
L<Alien>.

=cut
