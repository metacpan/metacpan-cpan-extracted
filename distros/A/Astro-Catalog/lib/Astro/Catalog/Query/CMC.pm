package Astro::Catalog::Query::CMC;

=head1 NAME

Astro::Catalog::Query::CMC - A query request to the Carlsberg Meridian Catalog

=head1 SYNOPSIS

  $gsc = new Astro::Catalog::Query::CMC( RA        => $ra,
                                         Dec       => $dec,
                                         Radius    => $radius,
                                         Nout      => $number_out );

  my $catalog = $gsc->querydb();

=head1 WARNING

This code should be superceeded by the generic Vizier query class.

=head1 DESCRIPTION

The module is an object orientated interface to the online
Carlsberg Meridian Catalogues (CMC11)

Stores information about an prospective query and allows the query to
be made, returning an Astro::Catalog::Query::CMC object.

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
use vars qw/ $VERSION $DEBUG /;

use File::Spec;
use Carp;

# generic catalog objects
use Astro::Catalog;
use Astro::Catalog::Star;

$VERSION = "4.35";
$DEBUG = 0;

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
          catalog => 'I/282/cmc12',

          # Target information
          ra => undef,
          dec => undef,

          # Limits
          radmax => 5,
          nout => 20000,
         );
}

=item B<_parse_query>

Private function used to parse the results returned in an GSC query.
Should not be called directly. Instead use the querydb() assessor method to
make and parse the results.

=cut

sub _parse_query {
  my $self = shift;

  print $self->{BUFFER} if $DEBUG;
  return new Astro::Catalog( Format => 'TST', Data => $self->{BUFFER},
                             Origin => 'Carlsberg Meridian Catalogue (CMC/11)',
                             ReadOpt => { ra_col => 2, dec_col => 4, }
                           );
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
