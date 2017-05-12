package Astro::Catalog::IO::ASSM;

=head1 NAME

Astro::Catalog::IO::ASSM - AJP ASSM format

=head1 SYNOPSIS

  $catalog = Astro::Catalog::IO::ASSM->_read_catalog( \@lines );

=head1 DESCRIPTION

Performs simple IO, reading or writing "id_string hh mm ss.s +dd mm ss.s"
formated strings for each Astro::Catalog::Item object in the catalog.

=cut


# L O A D   M O D U L E S --------------------------------------------------

use 5.006;
use strict;
use warnings;
use warnings::register;
use vars qw/ $VERSION /;
use Carp;

use Astro::Catalog;
use Astro::Catalog::Item;
use Astro::Coords;
use Astro::Flux;
use Astro::Fluxes;

use base qw/ Astro::Catalog::IO::ASCII /;

use vars qw/ $VERSION $DEBUG /;

$VERSION = '4.31';
$DEBUG = 0;


=head1 METHODS

=head2 Private methods

These methods are for internal use only and are called from the
Astro::Catalog module. It is not expected that anyone would want to
call them from outside that module.

=over 4

=item B<_read_catalog>

Parses a reference to an array containing a simply formatted catalogue

  $catalog = Astro::Catalog::IO::ASSM->_read_catalog( \@lines );

=cut

sub _read_catalog {
  my $class = shift;
  my $arg = shift;
  my @lines = @{$arg};

  # create an Astro::Catalog object;
  my $catalog = new Astro::Catalog();

  # loop through lines
  my $starnum = 1;
  my $hdrnotprocessed = 1;
  my @allfilters;

  foreach my $i ( 0 .. $#lines ) {

    # Skip commented and blank lines
    next if ($lines[$i] =~ /^\s*[\#*%]/);
    next if ($lines[$i] =~ /^\s*$/);

    print $lines[$i]."\n" if $DEBUG;

    # We need the last line of the header as it has the fieldnames, including
    # the filters
    if ( $hdrnotprocessed ) {
      print "Header processing\n" if $DEBUG;

      # Extract last line of header, strip off the hash and any starting
      # whitespace and then split into fields
      my $colhdr = $lines[$i-1];
      $colhdr =~s/^\s*#//g;
      my @hdrfields = split(/\s+/, $colhdr);

      # Determine which columns are filters...
      my $idx = 0;
      my $first_filter_idx =0;
      my $last_filter_idx =0;
      foreach my $colname ( @hdrfields ) {
        if ( $colname eq 'DECdeg' ) {
          # We've found the leftmost edge of the filter columns
          $first_filter_idx = $idx + 1;
        } elsif ( $colname eq 'sptyp' ) {
          # We've found the rightmost edge of the filter columns
          $last_filter_idx = $idx - 1;
        }
        $idx++;
      }

      @allfilters = @hdrfields[$first_filter_idx .. $last_filter_idx];
      print "Found " . @allfilters . " Filters\n" if $DEBUG;
      for my $f ( @allfilters ) {
        print "filter was: $f\n" if $DEBUG;
      }
      $hdrnotprocessed = 0;
    }
    my @fields = split(/\s+/, $lines[$i]);
    my $ra_value = $fields[0];
    my $dec_value = $fields[1];

    # Skip if the 3rd entry is 'NoStars' or there aren't the right number of fields
    next if $fields[2] eq 'NoStars' or @fields != @allfilters + 4;

    my $star = new Astro::Catalog::Item();
    # Set up the Astro::Coords object, assuming our RA and Dec are in units
    # of degrees.

    my $coords;
    if ( defined( $ra_value ) && defined( $dec_value ) ) {
      $coords = new Astro::Coords( ra => $ra_value,
                                   dec => $dec_value,
                                   units => 'degrees',
                                   type => 'J2000',
                                 );
    }

    croak "Error creating coordinate object from $ra_value / $dec_value "
      unless defined $coords;

    # and push it into the Astro::Catalog::Item object
    $star->coords( $coords );

    # Go through the passbands and create the Astro::Flux object for
    # this magnitude.
    my $waveband;
    my $filtnum = 2;
    my @mags;
    foreach my $filter ( @allfilters ) {
      print "Filter=$filter, " if $DEBUG;
      $waveband = new Astro::WaveBand( Filter => $filter );
      # Create the Astro::Flux object for this magnitude.
      my $flux = new Astro::Flux( new Number::Uncertainty( Value => $fields[$filtnum] ),
                                  'MAG_CATALOG',
                                  $waveband );
      push @mags, $flux;
      $filtnum++;
    }
    print "\n" if $DEBUG;
    my $fluxes = new Astro::Fluxes( @mags );
    # and push the fluxes into the catalog
    $star->fluxes( $fluxes );
    $star->preferred_magnitude_type( 'MAG_CATALOG' );

    # get the sptype, strip out underscores
    my $spectype = $fields[5];
    $spectype =~ s/_//g;
    print "Spectype=$spectype\n" if $DEBUG;
    # and push into object
    $star->spectype( $spectype );

    # push the source column into the Comment field
    $star->comment( $fields[6] );

    # push id number
    $star->id( $starnum );
    # push it onto the stack
    $catalog->pushstar( $star );

    $starnum++;
  }

  $catalog->origin( 'IO::ASSM' );
  return $catalog;

}

=back

=head1 REVISION

 $Id: ASSM.pm 5702 2012-05-19 00:45:23Z tlister $

=head1 SEE ALSO

L<Astro::Catalog>, L<Astro::Catalog::IO::Simple>


=head1 FORMAT

The ASSM format is defined as follows: Any line that looks like

RAdeg Decdeg filter1mag filter2mag filter3mag sp. type source

=head1 COPYRIGHT

Copyright (C) 2012 Las Cumbres Observatory Global Telescope Network.
All Rights Reserved.

This module is free software;
you can redistribute it and/or modify it under the terms of the GNU
Public License.

=head1 AUTHORS

Tim Lister E<lt>tlister@lcogt.netE<gt>

=cut

1;
