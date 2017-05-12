package Astro::Catalog::Query::GSC;

=head1 NAME

Astro::Catalog::Query::GSC - A query request to the GSC Catalog

=head1 SYNOPSIS

  $gsc = new Astro::Catalog::Query::GSC( RA        => $ra,
					 Dec       => $dec,
					 Radius    => $radius,
					 Bright    => $magbright,
					 Faint     => $magfaint,
					 Sort      => $sort_type,
					 Nout      => $number_out );

  my $catalog = $gsc->querydb();

=head1 DESCRIPTION

The module is an object orientated interface to the online Guide Star
catalogue at the ESO/ST-ECF archive site.

Stores information about an prospective GSC query and allows the query to
be made, returning an Astro::Catalog::GSC::Catalog object.

The object will by default pick up the proxy information from the HTTP_PROXY
and NO_PROXY environment variables, see the LWP::UserAgent documentation for
details.

See L<Astro::Catalog::BaseQuery> for the catalog-independent methods.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use 5.006;
use strict;
use warnings;
use base qw/ Astro::Catalog::Transport::REST /;
use vars qw/ $VERSION /;

use File::Spec;
use Carp;

# generic catalog objects
use Astro::Catalog;
use Astro::Catalog::Star;
use Astro::Flux;
use Astro::Fluxes;
use Number::Uncertainty;

$VERSION = "4.31";

=head1 REVISION

$Id: GSC.pm,v 1.5 2005/06/16 01:57:35 aa Exp $

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
  return "gsc/gsc?";
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
	  catalogue => 'catalogue',
	  epoch => 'epoch',
	  chart => 'chart',
	  multi => 'multi',
	 );
}

=item B<_get_default_options>

Get the default query state.

=cut

sub _get_default_options {
  return  (
	   # Hidden
	   catalogue => 'gsc',
	   epoch => '2000.0',
	   chart => 1,

	   # Target information
	   ra => undef,
	   dec => undef,
	   object => undef,

	   # Limits
	   radmax => 5,
	   magbright => 0,
	   magfaint => 100,
	   format => 1,
	   sort => 'RA',
	   nout => 20000,
	   multi => 1,
	  );
}

=item B<_parse_query>

Private function used to parse the results returned in an GSC query.
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
  my %field; # field centre

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
     $catalog->fieldcentre( %field );

     # Parse list of objects
     # ---------------------

     if( lc($buffer[$line]) =~ "<pre>" ) {

        # reached the catalog block, loop through until </pre> reached
        $counter = $line+2;
        until ( lc($buffer[$counter+1]) =~ "</pre>" ) {

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
              my $id = $separated[2];
              $star->id( $id );

              # debugging
              #my $num = $counter - $line -2;
              #print "# ID $id star $num\n";

              # RA
              my $objra = "$separated[3] $separated[4] $separated[5]";

              # Dec
              my $objdec = "$separated[6] $separated[7] $separated[8]";

	      $star->coords( new Astro::Coords(ra => $objra,
					       dec => $objdec,
					       units => 'sex',
					       type => 'J2000',
					       name => $id,
					       ),
			     );

              # B Magnitude
              #my %b_mag = ( B => $separated[10] );
              #$star->magnitudes( \%b_mag );

	      $star->fluxes( new Astro::Fluxes( new Astro::Flux(
	               new Number::Uncertainty( Value => $separated[10],
		                                Error => $separated[11] ),
			'mag', "B" )));

              # B mag error
              #my %mag_errors = ( B => $separated[11] );
              #$star->magerr( \%mag_errors );

              # Quality
              my $quality = $separated[13];
              $quality = 1 if $quality == 3; # 3 == non-stellar
              $star->quality( $quality );

              # Field
              my $field = $separated[12];
              $star->field( $field );

              # GSC, obvious!
              $star->gsc( "TRUE" );

              # Distance
              my $distance = $separated[16];
              $star->distance( $distance );

              # Position Angle
              my $pos_angle = $separated[17];
              $star->posangle( $pos_angle );

           }

           # Push the star into the catalog
           # ------------------------------
           $catalog->pushstar( $star );

           # increment counter
           # -----------------
           $counter = $counter + 1;
        }

        # reset $line to correct place
        $line = $counter;
     }

  }
  # Set the field centre
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

The base class only includes one to one mappings.

=item B<_translate_one_to_one>

Return a list of internal options (as defined in C<_get_allowed_options>)
that are known to support a one-to-one mapping of the internal value
to the external value.

  %one = $q->_translate_one_to_one();

Returns a hash with keys and no values (this makes it easy to
check for the option).

This method also returns, the values from the parent class.

=cut

sub _translate_one_to_one {
  my $self = shift;
  # convert to a hash-list
  return ($self->SUPER::_translate_one_to_one,
	  map { $_, undef }(qw/
			    chart epoch catalogue
			    /)
	 );
}


sub _from_multi {
  my $self = shift;
  my $key = "multi";
  my $value = $self->query_options($key);

  # convert boolean to "yes" or "no"
  if (!$value || $value =~ /^no%/i) {
    # boolean false is always false
    # as is "no"
    $value = 'no';
  } else {
    # must be true
    $value = 'yes';
  }

  my %allow = $self->_get_allowed_options();
  return ($allow{$key}, $value);
}

=end __PRIVATE_METHODS__

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
