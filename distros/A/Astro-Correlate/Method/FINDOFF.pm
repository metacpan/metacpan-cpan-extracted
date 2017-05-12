package Astro::Correlate::Method::FINDOFF;

=head1 NAME

Astro::Correlate::Method::FINDOFF - Correlation using Starlink FINDOFF.

=head1 SYNOPSIS

  ( $corrcat1, $corrcat2 ) = Astro::Correlate::Method::FINDOFF->correlate( catalog1 => $cat1, catalog2 => $cat2 );

=head1 DESCRIPTION

This class implements catalogue cross-correlation using Starlink's FINDOFF
application.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;
use File::Temp qw/ tempfile /;
use Storable qw/ dclone /;

use Starlink::ADAM;
use Starlink::AMS::Init;
use Starlink::AMS::Task;
use Starlink::Config qw/ :override /;
use Starlink::EMS qw/ :sai get_facility_error /;

our $VERSION = '0.01';
our $DEBUG = 0;

# Cache the task.
our $TASK;

=head1 METHODS

=head2 General Methods

=over 4

=item B<correlate>

Cross-correlates two catalogues.

  ( $corrcat1, $corrcat2 ) = Astro::Correlate::Method::FINDOFF->correlate( catalog1 => $cat1,
                                                                           catalog2 => $cat2 );

This method takes two mandatory arguments, both C<Astro::Catalog> objects.
It returns two C<Astro::Catalog> objects containing C<Astro::Catalog::Star>
objects that matched spatially between the two input catalogues. The
first returned catalogue contains matched objects from the first input
catalogue, and ditto for the second. The C<Astro::Catalog::Star> objects
in the returned catalogues are not in the original order, nor do they have
the same IDs as in the input catalogues. A matched object has the same ID
in the two returned catalogues, allowing for further comparisons between
matched objects.

This method takes the following optional named arguments:

=item keeptemps - If this argument is set to true (1), then this
method will keep temporary files used in processing. Defaults to
false.

=item messages - If set to true (1), then this method will print
messages from the FINDOFF task during processing. Defaults to false.

=item temp - Set the directory to hold temporary files. If not set,
then a new temporary directory will be created using File::Temp.

=item timeout - Set the time in seconds to wait for the CCDPACK
monolith to time out. Defaults to 60 seconds.

=item verbose - If this argument is set to true (1), then this method will
print progress statements. Defaults to false.

This method uses the Starlink FINDOFF task, which is part of
CCDPACK. In order for this method to work it must be able to find
FINDOFF. It first looks in the directory pointed to by the CCDPACK_DIR
environment variable, then it looks in the Starlink binary files
directory pointed to by the Starlink::Config module, with C</ccdpack>
appended. If either of these fail, then this method will croak. See
the C<Starlink::Config> module for information on overriding the base
Starlink directory for non-standard installations.

=cut

sub correlate {
  my $class = shift;

# Grab the arguments, and make sure they're defined and are
# Astro::Catalog objects (the catalogues, at least).
  my %args = @_;
  my $inputcat1 = dclone( $args{'catalog1'} );
  my $inputcat2 = dclone( $args{'catalog2'} );

  if( ! defined( $inputcat1 ) ||
      ! UNIVERSAL::isa( $inputcat1, "Astro::Catalog" ) ) {
    croak "catalog1 parameter to correlate method must be defined and must be an Astro::Catalog object";
  }
  if( ! defined( $inputcat2 ) ||
      ! UNIVERSAL::isa( $inputcat2, "Astro::Catalog" ) ) {
    croak "catalog2 parameter to correlate method must be defined and must be an Astro::Catalog object";
  }

  # Make deep clones of the two input catalogues so we can modify IDs
  # and not trample those input catalogues.
  my $cat1 = dclone( $inputcat1 );
  my $cat2 = dclone( $inputcat2 );

  my $keeptemps = defined( $args{'keeptemps'} ) ? $args{'keeptemps'} : 0;
  my $temp;
  if( exists( $args{'temp'} ) && defined( $args{'temp'} ) ) {
    $temp = $args{'temp'};
  } else {
    $temp = tempdir( UNLINK => ! $keeptemps );
  }
  my $verbose = defined( $args{'verbose'} ) ? $args{'verbose'} : 0;
  my $messages = defined( $args{'messages'} ) ? $args{'messages'} : 0;
  my $timeout = defined( $args{'timeout'} ) ? $args{'timeout'} : 60;

# Try to find the FINDOFF binary. First, try the CCDPACK_DIR
# environment variable. If that doesn't find it, use
# Starlink::Config. If that doesn't work, croak.
  my $findoff_bin;
  if( defined( $ENV{'CCDPACK_DIR'} ) &&
      -d $ENV{'CCDPACK_DIR'} &&
      -e File::Spec->catfile( $ENV{'CCDPACK_DIR'}, "findoff" ) ) {
    $findoff_bin = File::Spec->catfile( $ENV{'CCDPACK_DIR'}, "findoff" );
  } elsif( -d File::Spec->catfile( $StarConfig{Star_Bin}, "ccdpack" ) &&
           -e File::Spec->catfile( $StarConfig{Star_Bin}, "ccdpack", "findoff" ) ) {
    $findoff_bin = File::Spec->catfile( $StarConfig{Star_Bin}, "ccdpack", "findoff" );
  } else {
    croak "Could not find FINDOFF binary.\n";
  }
  print "FINDOFF binary is in $findoff_bin\n" if $DEBUG;

# Get two temporary file names for catalog files.
  ( undef, my $catfile1 ) = tempfile( DIR => $temp );
  ( undef, my $catfile2 ) = tempfile( DIR => $temp );

# Create two hash lookup tables. Key will be an integer incrementing
# from 1, value will be the original ID. We have to renumber because
# some modern catalogues have star IDs where the integer part exceeds
# a 32-bit integer (as used by FINDOFF)
  my %lookup_cat1;
  my %lookup_cat2;

  my $cat1stars = $cat1->stars;
  my $newid = 1;
  foreach my $cat1star ( @$cat1stars ) {
    $lookup_cat1{$newid} = $cat1star->id;
    print "Catalogue 1 star with original ID of " . $cat1star->id . " has FINDOFF-ed ID of $newid\n" if $DEBUG;
    $cat1star->id( $newid );
    $newid++;
  }

  my $cat2stars = $cat2->stars;
  $newid = 1;
  foreach my $cat2star ( @$cat2stars ) {
    $lookup_cat2{$newid} = $cat2star->id;
    print "Catalogue 2 star with original ID of " . $cat2star->id . " has FINDOFF-ed ID of $newid\n" if $DEBUG;
    $cat2star->id( $newid );
    $newid++;
  }

# We need to write two input files for FINDOFF, one for each catalogue.
# Do so using Astro::Catalog.
  $cat1->write_catalog( Format => 'FINDOFF', File => $catfile1 );
  $cat2->write_catalog( Format => 'FINDOFF', File => $catfile2 );
  print "Input catalog 1 written to $catfile1.\n" if $DEBUG;
  print "Input catalog 2 written to $catfile2.\n" if $DEBUG;

# We need to write an input file for FINDOFF that lists the above two
# input files.
  ( my $findoff_fh, my $findoff_input ) = tempfile( DIR => $temp, UNLINK => 1 );
  print $findoff_fh "$catfile1\n$catfile2\n";
  close $findoff_fh;

# Set up the parameter list for FINDOFF.
  my $param = "ndfnames=false error=5 maxdisp=! minsep=5 fast=yes failsafe=yes";
  $param .= " logto=terminal namelist=! complete=0.15";
  $param .= " inlist=^$findoff_input outlist='*.off'";

# Do the correlation.
  local $ENV{'ADAM_DIR'} = ( defined( $ENV{'ADAM_DIR'} ) ?
                             $ENV{'ADAM_DIR'} . "/corr" :
                             $ENV{'HOME'} . "/adam/corr" );

  my @findoffargs = ( "ndfnames=false",
                      "error=2",
                      "maxdisp=!",
                      "minsep=5",
                      "fast=yes",
                      "failsafe=yes",
                      "logto=neither",
                      "namelist=!",
                      "complete=0.05",
                      "inlist=^$findoff_input",
                      "outlist='*.off'" );

  my $ams = new Starlink::AMS::Init(1);
  $ams->timeout( $timeout );
  my $set_messages = $ams->messages;
  if( ! defined( $set_messages ) ) {
    $ams->messages( $messages );
  }
  if( ! defined( $TASK ) ) {
    $TASK = new Starlink::AMS::Task( "findoff", "$findoff_bin" );
  }
  my $STATUS = $TASK->contactw;
  if( ! $STATUS ) {
    croak "Could not contact FINDOFF monolith";
  }
  $STATUS = $TASK->obeyw("findoff", join( " ", @findoffargs ) );
  if( $STATUS != SAI__OK && $STATUS != &Starlink::ADAM::DTASK__ACTCOMPLETE ) {
    ( my $facility, my $ident, my $text ) = get_facility_error( $STATUS );
    croak "Error in running FINDOFF: $STATUS - $text";
  }

# Read in the first output catalog. If it doesn't exist, croak because
# FINDOFF has failed to find a correlation.
  my $outfile1 = $catfile1 . ".off";
  if( ! -e $outfile1 ) {
    croak "FINDOFF failed to find a correlation between the two input catalogues";
  }
  my $tempcat = new Astro::Catalog( Format => 'FINDOFF',
                                    File => $outfile1 );
# Loop through the stars, making a new catalogue with new stars using
# a combination of the new ID and the old information.
  my $corrcat1 = new Astro::Catalog();
  my @stars = $tempcat->stars;
  foreach my $star ( @stars ) {

# The old ID is found in the first column of the star's comment.
# However, this old ID has been "FINDOFF-ed", i.e. all non-numeric
# characters have been stripped from it. Use the lookup table we
# generated earlier to find the proper old ID.
    $star->comment =~ /^(\w+)/;
    my $oldfindoffid = $1;
    my $oldid = $lookup_cat1{$oldfindoffid};

# Get the star's information.
    my $oldstar = $inputcat1->popstarbyid( $oldid );
    $oldstar = $oldstar->[0];
    next if ! defined( $oldstar );

# Set the ID to the new star's ID.
    $oldstar->id( $star->id );

# Set the comment denoting the old ID.
    $oldstar->comment( "Old ID: " . $oldid );

# And push this star onto the output catalogue.
    $corrcat1->pushstar( $oldstar );
  }

# Do the same for the second catalogue.
  my $outfile2 = $catfile2 . ".off";
  if( ! -e $outfile2 ) {
    croak "FINDOFF failed to find a correlation between the two input catalogues";
  }
  $tempcat = new Astro::Catalog( Format => 'FINDOFF',
                                 File => $outfile2 );

# Loop through the stars, making a new catalogue with new stars using
# a combination of the new ID and the old information.
  my $corrcat2 = new Astro::Catalog();
  @stars = $tempcat->stars;

  foreach my $star ( @stars ) {

# The old ID is found in the first column of the star's comment.
# However, this old ID has been "FINDOFF-ed", i.e. all non-numeric
# characters have been stripped from it. Use the lookup table we
# generated earlier to find the proper old ID.
    $star->comment =~ /^(\w+)/;
    my $oldfindoffid = $1;
    my $oldid = $lookup_cat2{$oldfindoffid};

# Get the star's information.
    my $oldstar = $inputcat2->popstarbyid( $oldid );
    $oldstar = $oldstar->[0];
    next if ! defined( $oldstar );

# Set the ID to the new star's ID.
    $oldstar->id( $star->id );

# Set the comment denoting the old ID.
    $oldstar->comment( "Old ID: " . $oldid );

# And push this star onto the output catalogue.
    $corrcat2->pushstar( $oldstar );
  }

# Delete the temporary catalogues.
  unlink $catfile1 unless ( $DEBUG || $keeptemps );
  unlink $catfile2 unless ( $DEBUG || $keeptemps );
  unlink $outfile1 unless ( $DEBUG || $keeptemps );
  unlink $outfile2 unless ( $DEBUG || $keeptemps );

  unlink $findoff_input unless ( $DEBUG || $keeptemps );

  return ( $corrcat1, $corrcat2 );

}

=back

=head1 SEE ALSO

C<Astro::Correlate>, C<Starlink::Config>

Starlink User Note 139.

=head1 REVISION

$Id$

=head1 AUTHORS

Brad Cavanagh <brad.cavanagh@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2005 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut

1;
