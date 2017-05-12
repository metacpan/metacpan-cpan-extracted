package Alien::scriptaculous;

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
use Alien::Prototype;

###############################################################################
# Version number
###############################################################################
our $SCRIPTACULOUS_VERSION = '1.8.0';
our $VERSION = '1.8.0.2';

###############################################################################
# Subroutine:   version()
###############################################################################
# Returns the script.aculo.us version number.
#
# Not to be confused with the 'Alien::scriptaculous' version number (which is
# the version number of the Perl wrapper).
###############################################################################
sub version {
    return $SCRIPTACULOUS_VERSION;
}

###############################################################################
# Subroutine:   path()
###############################################################################
# Returns the path to the available copy of script.aculo.us.
###############################################################################
sub path {
    my $base = $INC{'Alien/scriptaculous.pm'};
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
    my @files = map { "$_.js" }
                qw( builder controls dragdrop effects scriptaculous slider
                    sound
                );
    my %blib  = map { (File::Spec->catfile($path,'src',$_) => $_) } @files;
    return %blib;
}

###############################################################################
# Subroutine:   files()
###############################################################################
# Returns the list of files that are installed by Alien::scriptaculous.
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
# Installs the script.aculo.us Javascript libraries into the given '$destdir'.
# Throws a fatal exception on errors.
###############################################################################
sub install {
    my ($class, $destdir) = @_;

    # install Prototype
    Alien::Prototype->install( $destdir );

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

Alien::scriptaculous - installing and finding script.aculo.us

=head1 SYNOPSIS

  use Alien::scriptaculous;
  ...
  $version = Alien::scriptaculous->version();
  $path    = Alien::scriptaculous->path();
  ...
  Alien::scriptaculous->install( $my_destination_directory );

=head1 DESCRIPTION

Please see L<Alien> for the manifesto of the Alien namespace.

=head1 METHODS

=over

=item version()

Returns the script.aculo.us version number. 

Not to be confused with the C<Alien::scriptaculous> version number (which
is the version number of the Perl wrapper). 

=item path()

Returns the path to the available copy of script.aculo.us. 

=item to_blib()

Returns a hash containing paths to the source files to be copied, and their
relative destinations. 

=item files()

Returns the list of files that are installed by Alien::scriptaculous. 

=item install($destdir)

Installs the script.aculo.us Javascript libraries into the given
C<$destdir>. Throws a fatal exception on errors. 

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 LICENSE

Copyright (C) 2006, Graham TerMarsch.  All rights reserved.

This is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://script.aculo.us/,
L<Alien::Prototype>,
L<Alien>.

=cut
