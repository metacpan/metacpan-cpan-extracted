package Astro::Catalog::Query::MPC;

=head1 NAME

Astro::Catalog::Query::MPC - A query request to the Minor Planet Center's
Minor Planet Checker.

=head1 SYNOPSIS

  $mpc = new Astro::Catalog::Query::MPC( RA => $ra,
                                         Dec => $dec,
                                         Year => $year,
                                         Month => $month,
                                         Day => $day,
                                         Radmax => $radius,
                                         Limit => $limit,
                                         ObsCode => $obscode,
                                        );

  my $catalog = $mpc->querydb();

=head1 DESCRIPTION

This module provides an object-oriented interface to the Minor Planet
Center's Minor Planet Checker webform available at
http://scully.harvard.edu/~cgi/CheckMP. It stores information about
asteroids found in a search radius at a specific epoch in an
C<Astro::Catalog> object.

The object will by default pick up the proxy information from the HTTP_PROXY
and NO_PROXY environment variables. See the LWP::UserAgent documentation
for details.

See L<Astro::Catalog::BaseQuery> for the catalog-independent methods.

=cut

use 5.006;
use strict;
use warnings;
use base qw/ Astro::Catalog::Transport::REST /;
use vars qw/ $VERSION /;

use File::Spec;
use Time::Piece ':override';
use Carp;

use Astro::Catalog;
use Astro::Catalog::Star;

use Astro::Flux;
use Astro::Fluxes;
use Number::Uncertainty;

$VERSION = "4.31";

=head1 REVISION

$Id: MPC.pm,v 1.2 2005/06/16 01:57:35 aa Exp $

=begin __PRIVATE_METHODS__

=head2 Private Methods

These methods are for internal use only.

=over 4

=item B<_default_remote_host>

Defines the default remote host to be scully.harvard.edu.

=cut

sub _default_remote_host {
  return "scully.harvard.edu";
}

=item B<_default_url_path>

Defines the default URL path to be ~cgi/MPCheck.COM?.

=cut

sub _default_url_path {
  return "~cgi/MPCheck.COM?";
}

=item B<_get_allowed_options>

Returns a hash with key being the internal options supported
by this subclass, and values being the key name actually requred
by the remote system (and to be included in the query).

=cut

sub _get_allowed_options {
  my $self = shift;
  return (
          ra => 'ra',
          dec => 'decl',
          year => 'year',
          month => 'month',
          day => 'day',
          limit => 'limit',
          obscode => 'oc',
          which => 'which',
          mpcsort => 'sort',
          mot => 'mot',
          tmot => 'tmot',
          needed => 'needed',
          ps => 'ps',
          type => 'type',
          radmax => 'radius',
          textarea => 'TextArea',
         );
}

=item B<_get_default_options>

Get the default query state.

=cut

sub _get_default_options {
  my $time = gmtime;

  my $day = sprintf( "%.2f",$time->mday + ( $time->hour / 24 ) + ( $time->min / 1440 ) + ( $time->sec / 86400 ) );

  return (
          # Hidden and constant options
          which => 'pos',
          mpcsort => 'd',
          mot => 'h',
          tmot => 's',
          needed => 'f',
          ps => 'n',
          type => 'p',
          textarea => '',

          # Target information
          ra => undef,
          dec => undef,
          year => $time->year,
          month => $time->mon,
          day => $day,
          obscode => 500,

          # Limits
          radmax => 15,
          limit => 20.0,

         );
}

=item B<_parse_query>

Private function used to parse the results returned in an MPC query.
Should not be called directly. Instead, use the querydb() accessor
method to make and parse the results.

=cut

sub _parse_query {
  my $self = shift;

  # Get a local copy of the current BUFFER.
  my @buffer = split( /\n/, $self->{BUFFER} );
  chomp @buffer;

  # Create an Astro::Catalog object to hold the search results.
  my $catalog = new Astro::Catalog();

  # Create a temporary object to hold stars.
  my $star;

  my ( $line, $counter );
  my ( $epoch );

  # Loop around the returned buffer and stuff the contents into
  # star objects.
  foreach $line ( 0 ... $#buffer ) {

    # Get the limiting magnitude, field center, radius, and epoch.
    if( $buffer[$line] =~ /^The following objects/ ) {
      $buffer[$line] =~ /\<i\>V\<\/i\> = ([0-9\.]+), were found in the ([0-9\.]+)-arcminute region around R.A. = ([0-9\. ]+), Decl. = ([\-+0-9\. ]+) \(J2000.0\) on (\d{4}) (\d{2}) ([0-9\.]+)/;
      my $limit = $1;
      my $radius = $2;
      my $ra = $3;
      my $dec = $4;
      my $year = $5;
      my $month = $6;
      my $day = $7;

      my $hour = int ( ( $day - int( $day ) ) * 24 );
      my $minute = int( ( ( ( $day - int( $day ) ) * 24 ) - $hour ) * 60 );
      my $second = int( ( ( ( ( ( $day - int( $day ) ) * 24 ) - $hour ) * 60 ) - $minute ) * 60 );
      $day = int($day);

      my $t = Time::Piece->strptime( "$year $month $day $hour $minute $second",
                                     "%Y %m %d %H %M %S" );
      $epoch = $t->year + ( $t->yday / 365.24 );
    }

    if( $buffer[$line] =~ "<pre>" ) {

      # We're now in the list of asteroids. Loop through until we
      # hit </pre>.
      $counter = $line + 4;
      until( $buffer[$counter] =~ "</pre>" ) {

        my( $name, $ra, $dec, $vmag, $raoff, $decoff, $pm_ra, $pm_dec, $orbit, $comment ) = unpack("A24A11A10A6A7A7A7A7A6A*", $buffer[$counter]);

        if( defined( $ra ) ) {

          $star = new Astro::Catalog::Star();

          $name =~ s/^\s+//;
          $star->id( $name );

          $vmag =~ s/^\s+//;
          #my %vmag = ( V => $vmag );
          #$star->magnitudes( \%vmag );

	  $star->fluxes( new Astro::Fluxes( new Astro::Flux(
	                 new Number::Uncertainty( Value => $vmag ),
			 'mag', "V" )));

          $comment =~ s/^\s+//;
          $star->comment( $comment );

          # Deal with the coordinates. RA and Dec are almost in the
          # right format (need to replace separating spaces with colons).
          $ra =~ s/^\s+//;
          $ra =~ s/ /:/g;
          $dec =~ s/^\s+//;
          $dec =~ s/ /:/g;

          my $coords = new Astro::Coords( name => $name,
                                          ra => $ra,
                                          dec => $dec,
                                          type => 'J2000',
                                          epoch => $epoch,
                                        );

          $star->coords( $coords );

          # Push the star onto the catalog.
          $catalog->pushstar( $star );

        }
        $counter++;
      }
      $line = $counter
    }
  }

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

The base class only includes one to one mappings.

=over 4

=item B<_translate_one_to_one>

Return a list of internal options (as defined in C<_get_allowed_options>)
that are known to support a one-to-one mapping of the internal value
to the external value.

  %one = $q->_translate_one_to_one();

Returns a hash with keys and no values (this makes it easy to
check for the option).

This method also returns the values from the parent class.

=cut

sub _translate_one_to_one {
  my $self = shift;
  # convert to a hash-list
  return ($self->SUPER::_translate_one_to_one,
          map { $_, undef }(qw/ year month day obscode
                                ra dec radius limit
                                which mot tmot mpcsort
                                needed ps type textarea
                               /)
         );
}

=back

=end __PRIVATE_METHODS__

=head1 COPYRIGHT

Copyright (C) 2004 Particle Physics and Astronomy Research
Council. All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Public License.

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut

1;
