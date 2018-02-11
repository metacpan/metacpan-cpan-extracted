package Astro::Catalog::Query::USNOA2;

=head1 NAME

Astro::Catalog::Query::USNOA2 - A query request to the USNO-A2.0 Catalog

=head1 SYNOPSIS

  $usno = new Astro::Catalog::Query::USNOA2( Coords    => new Astro::Coords(),
                                             Radius    => $radius,
                                             Bright    => $magbright,
                                             Faint     => $magfaint,
                                             Sort      => $sort_type,
                                             Number    => $number_out );

  my $catalog = $usno->querydb();

=head1 DESCRIPTION

The module is an object orientated interface to the online USNO-A2.0
catalogue at the ESO/ST-ECF archive site.

Stores information about an prospective USNO-A2.0 query and allows the query to
be made, returning an Astro::Catalog::USNOA2::Catalog object.

The object will by default pick up the proxy information from the HTTP_PROXY
and NO_PROXY environment variables, see the LWP::UserAgent documentation for
details.

See L<Astro::Catalog::BaseQuery> for the catalog-independent methods.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use warnings;
use base qw/ Astro::Catalog::Transport::REST /;
use vars qw/ $VERSION /;

use File::Spec;
use Carp;

# generic catalog objects
use Astro::Coords;
use Astro::Catalog;
use Astro::Catalog::Star;

use Astro::Flux;
use Astro::Fluxes;
use Astro::FluxColor;
use Number::Uncertainty;

$VERSION = "4.33";

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<_default_remote_host>

=cut

sub _default_remote_host {
  return "archive.eso.org";
}

=item B<_default_url_path>

=cut

sub _default_url_path {
  return "skycat/servers/usnoa_res?";
}

=item B<_get_allowed_options>

Returns a hash with keys, being the internal options supported
by this subclass, and values being the key name actually required
by the remote system (and to be included in the query).

=cut

sub _get_allowed_options {
  my $self = shift;
  return (
          ra => 'ra',
          dec => 'dec',
          object => 'object',
          radmax => 'radmax',
          magbright => 'magbright',
          magfaint => 'magfaint',
          sort => 'sort',
          nout => 'nout',
          format => 'format',
         );
}


=item B<_get_default_options>

Get the default query state.

=cut

sub _get_default_options {
  return (
          ra => undef,
          dec => undef,
          object => undef,

          radmax => 5,
          magbright => 0,
          magfaint => 100,
          format => 1,
          sort => 'RA',
          nout => 2000,
         );
}

=item B<_parse_query>

Private function used to parse the results returned in an USNO-A2.0 query.
Should not be called directly. Instead use the querydb() assessor method to
make and parse the results.

=cut

sub _parse_query {
  my $self = shift;

  # get a local copy of the current BUFFER
  my @buffer = split( /\n/,$self->{BUFFER});
  chomp @buffer;

  # create an Astro::Catalog object to hold the search results
  my $catalog = new Astro::Catalog();

  # create a temporary object to hold stars
  my $star;

  my ( $line, $counter );

  # Read field centre a line at a time and store it outside the loop
  my %field;

  # loop round the returned buffer and stuff the contents into star objects
  foreach $line ( 0 ... $#buffer ) {

     # Parse field centre
     # ------------------

     # RA
     if( lc($buffer[$line]) =~ "<td>ra:" ) {
        $_ = lc($buffer[$line]);
        my ( $ra ) = /^\s*<td>ra:\s+(.*)<\/td>/;
        $field{RA} = $ra;
     }

     # Dec
     if( lc($buffer[$line]) =~ "<td>dec:" ) {
        $_ = lc($buffer[$line]);
        my ( $dec ) = /^\s+<td>dec:\s+(.*)<\/td>/;
        $field{Dec} = $dec;
      }

     # Radius
     if( lc($buffer[$line]) =~ "search radius:" ) {
        $_ = lc($buffer[$line+1]);
        my ( $radius ) = />\s+(.*)\s\w/;
        $field{Radius} = $radius;
     }

     # Parse list of objects
     # ---------------------

     if( lc($buffer[$line]) =~ "<pre>" ) {

        # reached the catalog block, loop through until </pre> reached
        $counter = $line+2;
        until ( lc($buffer[$counter+1]) =~ "</pre>" ) {

           # hack for first line, remove </b>
           if ( lc($buffer[$counter]) =~ "</b>" ) {
              $buffer[$counter] = substr( $buffer[$counter], 5);
           }

           # remove leading spaces
           $buffer[$counter] =~ s/^\s+//;

           # split each line
           my @separated = split( /\s+/, $buffer[$counter] );

           # debugging (leave in)
           #foreach my $thing ( 0 .. $#separated ) {
           #   print "   $thing # $separated[$thing] #\n";
           #}

           # check that there is something on the line
           if ( defined $separated[0] ) {

              # create a temporary place holder object
              $star = new Astro::Catalog::Star();

              # ID
              my $id = $separated[1];
              #my $num = $counter - $line -2;
              #print "# ID $id star $num\n";
              $star->id( $id );

              # RA
              my $objra = "$separated[2] $separated[3] $separated[4]";

              # Dec
              my $objdec = "$separated[5] $separated[6] $separated[7]";

              # only generate coordinates if the seconds field of the
              # dec isn't 60.0, if it is, lets just dump this star as
              # currently the Astro::Coords object gives totally bogus
              # answers due to the bogus answers its getting from SLALIB.
              unless ( $separated[7] == 60 || $separated[4] == 60 ) {
                  $star->coords( new Astro::Coords(  ra => $objra,
                                                     dec => $objdec,
                                                     units => 'sex',
                                                     type => 'J2000',
                                                     name => $star->id(),
                                                  ) );
              }

              # R Magnitude
              #my %r_mag = ( R => $separated[8] );
              #$star->magnitudes( \%r_mag );

              # B Magnitude
              #my %b_mag = ( B => $separated[9] );
              #$star->magnitudes( \%b_mag );

              # Quality
              my $quality = $separated[10];
              $star->quality( $quality );

              # Field
              my $field = $separated[11];
              $star->field( $field );

              # GSC
              my $gsc = $separated[12];
              if ( $gsc eq "+" ) {
                 $star->gsc( "TRUE" );
              } else {
                 $star->gsc( "FALSE" );
              }

              # Distance
              my $distance = $separated[13];
              $star->distance( $distance );

              # Position Angle
              my $pos_angle = $separated[14];
              $star->posangle( $pos_angle );

           }



           # Calculate error
           # ---------------

           # Error are calculated as follows
           #
           #   Delta.R = 0.15*sqrt( 1 + 10**(0.8*(R-19)) )
           #   Delta.B = 0.15*sqrt( 1 + 10**(0.8*(B-19)) )
           #

           my ( $power, $delta_r, $delta_b );

           # delta.R
           $power = 0.8*( $separated[8] - 19.0 );
           $delta_r = 0.15* (( 1.0 + ( 10.0 ** $power ) ) ** (1.0/2.0));

           # delta.B
           $power = 0.8*( $separated[9] - 19.0 );
           $delta_b = 0.15* (( 1.0 + ( 10.0 ** $power ) ) ** (1.0/2.0));

           # mag errors
           #my %mag_errors = ( B => $delta_b,  R => $delta_r );
           #$star->magerr( \%mag_errors );

           # calcuate B-R colour and error
           # -----------------------------

           # Error is calculated as follows
           #
           #   Delta.(B-R) = sqrt( Delta.R**2 + Delta.B**2 )
           #

           my $b_minus_r = $separated[9] - $separated[8];

           #my %colours = ( 'B-R' => $b_minus_r );
           #$star->colours( \%colours );

           # delta.(B-R)
           my $delta_bmr = ( ( $delta_r ** 2.0 ) + ( $delta_b ** 2.0 ) ) ** (1.0/2.0);

           # col errors
           #my %col_errors = ( 'B-R' => $delta_bmr );
           #$star->colerr( \%col_errors );

          $star->fluxes( new Astro::Fluxes(
            new Astro::Flux(
               new Number::Uncertainty( Value => $separated[8],
                                        Error => $delta_r ),'mag', "R" ),
            new Astro::Flux(
               new Number::Uncertainty( Value => $separated[9],
                                        Error => $delta_b),'mag', "B" ),
            new Astro::FluxColor( lower => "R", upper => "B",
                                  quantity => new Number::Uncertainty(
                                        Value => $b_minus_r,
                                        Error => $delta_bmr) ),
                        ));

           # Push the star into the catalog
           # ------------------------------

           # only push the star if the Astro::Coords object is
           # correctly defined. The Dec might be bogus since the
           # USNO-A2 catalogue has its seconds field out of
           # normal range (0-59.9) in some cases.
           if( $star->coords() ) {
              $catalog->pushstar( $star );
           }

           # increment counter
           # -----------------
           $counter = $counter + 1;
        }

        # reset $line to correct place
        $line = $counter;
     }

  }

  # set the field centre
  $catalog->fieldcentre( %field );

  return $catalog;
}

=back

=head2 Translation Methods

The query options stored internally in the object are not necessarily
the form required for a query to a remote server. Methods for converting
from the internal representation to the external query format are
provided in the form of _from_$opt. ie:

  ($outkey, $outvalue) = $q->_from_ra();
  ($outkey, $outvalue) = $q->_from_object();

Currently translations are a bit thin on the ground...

=cut

# None special for subclass

=end __PRIVATE_METHODS__

=head1 SEE ALSO

L<Astro::Catalog::Query>, L<Astro::Catalog::GSC::Query>

=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.
Some modifications copyright (C) 2003 Particle Physics and Astronomy
Research Council. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;
