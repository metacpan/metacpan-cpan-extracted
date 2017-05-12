package Astro::Catalog::Query::2MASS;

=head1 NAME

Astro::Catalog::Query::2MASS - A query request to the 2MASS Catalog

=head1 SYNOPSIS

  $gsc = new Astro::Catalog::Query::2MASS( RA        => $ra,
					 Dec       => $dec,
					 Radius    => $radius,
					 Nout      => $number_out );

  my $catalog = $gsc->querydb();

=head1 WARNING

This code should be superceeded by the generic Vizier query class.

=head1 DESCRIPTION

The module is an object orientated interface to the online
2MASS.

Stores information about an prospective query and allows the query to
be made, returning an Astro::Catalog::Query::2MASS object.

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

$VERSION = "4.31";

=head1 REVISION

$Id: 2MASS.pm,v 1.10 2005/02/04 02:47:53 cavanagh Exp $

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<_default_remote_host>

=cut

sub _default_remote_host {
  return "vizier.u-strasbg.fr";
}

=item B<_default_url_path>

=cut

sub _default_url_path {
  return "viz-bin/asu-acl?";
}

=item B<_get_allowed_options>

Returns a hash with keys, being the internal options supported
by this subclass, and values being the key name actually required
by the remote system (and to be included in the query).

=cut

sub _get_allowed_options {
  my $self = shift;
  return (
	  ra => '-c.ra',
	  dec => '-c.dec',
	  radmax => '-c.rm',
	  nout => '-out.max',
          catalog => '-source',
	 );
}


=item B<_get_default_options>

Get the default query state.

=cut

sub _get_default_options {
  return (
	  # Internal
	  catalog => '2MASS',

	  # Target information
	  ra => undef,
	  dec => undef,

	  # Limits
	  radmax => 5,
	  nout => 20000,
	 );
}

=item B<_parse_query>

Private function used to parse the results returned in an 2MASS query.
Should not be called directly. Instead use the querydb() assessor method to
make and parse the results.

=cut

sub _parse_query {
  my $self = shift;

  #print $self->{BUFFER};
  my $query = new Astro::Catalog( Format  => 'TST',
                                  Data => $self->{BUFFER},
			          Origin  => '2MASS Catalogue',
			          ReadOpt => { ra_col => 1, dec_col => 2, id_col => 0 } );

  # Grab each star in the catalog and add some value to it
  my $catalog = new Astro::Catalog( );
  $catalog->origin( $query->origin() );
  $catalog->set_coords( $query->get_coords() ) if defined $query->get_coords();

  my ( @oldstars, @newstars );
  @oldstars = $query->allstars();
  foreach my $i ( 0 ... $query->sizeof() ) {

    my $star = $oldstars[$i];

    # Ungodly hack warning...
    # -----------------------
    # We have J, H and K magnitudes, we probably also want some
    # colours, so lets generate some here and push it into the
    # star object. This is 2MASS specific so goes here, but in
    # reality we probably want something general in Star.pm which
    # dynamically generates colours and errors depending on the
    # stored magnitudes.

    # generate the colours
    my $j_minus_h = $star->get_magnitude( 'J' ) -
                    $star->get_magnitude( 'H' ) if defined $star;

    my $j_minus_k = $star->get_magnitude( 'J' ) -
                    $star->get_magnitude( 'K' ) if defined $star;

    my $h_minus_k = $star->get_magnitude( 'H' ) -
                    $star->get_magnitude( 'K' ) if defined $star;

    # generate the deltas
    my $delta_j = $star->get_errors( 'J' ) if defined $star;
    my $delta_h = $star->get_errors( 'H' ) if defined $star;
    my $delta_k = $star->get_errors( 'K' ) if defined $star;

    # quick kludge, stars without errors will get flagged bad anyway
    $delta_j = 0.000 unless defined $delta_j;
    $delta_h = 0.000 unless defined $delta_h;
    $delta_k = 0.000 unless defined $delta_k;

    my $delta_jmh = ( ( $delta_j ** 2.0 ) + ( $delta_h ** 2.0 ) ) ** (1.0/2.0);
    my $delta_jmk = ( ( $delta_j ** 2.0 ) + ( $delta_k ** 2.0 ) ) ** (1.0/2.0);
    my $delta_hmk = ( ( $delta_h ** 2.0 ) + ( $delta_k ** 2.0 ) ) ** (1.0/2.0);

    # fudge accuracy for readable catalogues
    $j_minus_h = sprintf("%.4f", $j_minus_h ) if defined $star;
    $j_minus_k = sprintf("%.4f", $j_minus_k ) if defined $star;
    $h_minus_k = sprintf("%.4f", $h_minus_k ) if defined $star;
    $delta_jmh = sprintf("%.4f", $delta_jmh ) if defined $star;
    $delta_jmk = sprintf("%.4f", $delta_jmk ) if defined $star;
    $delta_hmk = sprintf("%.4f", $delta_hmk ) if defined $star;

    # generate the hashes
    my %colours = ( 'J-H' => $j_minus_h,
                    'J-K' => $j_minus_k,
                    'H-K' => $h_minus_k ) if defined $star;

    my %col_errors = ( 'J-H' => $delta_jmh,
                       'J-K' => $delta_jmk,
                       'H-K' => $delta_hmk ) if defined $star;

    # append to star object
    $star->colours( \%colours ) if defined $star;
    $star->colerr( \%col_errors ) if defined $star;

    $newstars[$i] = $star if defined $star;

  }
  $catalog->pushstar( @newstars );

  # return the modified catalogue
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

This method also returns, the values from the parent class.

=cut

sub _translate_one_to_one {
  my $self = shift;
  # convert to a hash-list
  return ($self->SUPER::_translate_one_to_one,
	  map { $_, undef }(qw/
			    catalog
			    /)
	 );
}

=back

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
