package Astro::Catalog::Query::Vizier;

=head1 NAME

Astro::Catalog::Query::Vizier - A query request to the Vizier catalogs

=head1 SYNOPSIS

    $gsc = new Astro::Catalog::Query::2MASS(
            Catalog => '2MASS',
            RA        => $ra,
            Dec       => $dec,
            Radius    => $radius,
            Nout      => $number_out,
            Target    => $object,
        );

    my $catalog = $gsc->querydb();

=head1 DESCRIPTION

The module is an object orientated interface to the online
Vizier catalogs. Multiple catalogues can be specified using a
comma-separated list.

Stores information about an prospective query and allows the query to
be made, returning an Astro::Catalog::Query::Vizier object.

The object will by default pick up the proxy information from the HTTP_PROXY
and NO_PROXY environment variables, see the LWP::UserAgent documentation for
details.

See L<Astro::Catalog::Query> for the catalog-independent methods.

=cut

use strict;
use warnings;
use base qw/Astro::Catalog::Transport::REST/;

use File::Spec;
use Carp;

use Astro::Catalog;
use Astro::Catalog::Item;

our $VERSION = '4.36';
our $DEBUG = 0;

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<_default_remote_host>

Need to allow the host to be specified.

=cut

sub _default_remote_host {
    return "vizier.u-strasbg.fr";
}

=item B<_default_url_path>

asu-acl will generate TST format catalogues. asu-xml will generate
AstroRes format XML. We assume TST for the moment.

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
    # Need to add magfaint and magbright
    return (
        ra => '-c.ra',
        dec => '-c.dec',
        radmax => '-c.rm',
        radmin => '-c.rm.min',  # _from_radmin combines this into c.rm: no c.rm.min parameter
        nout => '-out.max',
        # sort => '-sort',
        object => '-c.obj',

        catalog => '-source',
        # outcols => '-out.all',
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
        object => undef,

        # Limits
        radmin => 0,
        radmax => 5,
        nout => 20000,
        # sort => 'RA', # do not know the allowed options

        # outcols => '', # need to check
    );
}

# Combine radmax and radmin into c.rm parameter.

sub _from_radmax {
    my $self = shift;
    my $radmax = $self->query_options('radmax');
    my $radmin = $self->query_options('radmin');
    my %allow = $self->_get_allowed_options();

    my $param = $radmin ? (join '+', $radmin, $radmax) : $radmax;

    return ($allow{'radmax'}, $param);
}

# (Note: this just sets radmax again...)

sub _from_radmin {
    my $self = shift;
    return $self->_from_radmax;
}

=item B<_parse_query>

Private function used to parse the results returned in an GSC query.
Should not be called directly. Instead use the querydb() assessor method to
make and parse the results.

=cut

sub _parse_query {
    my $self = shift;

    print $self->{BUFFER} if $DEBUG;
    return new Astro::Catalog(
            Format => 'TST',
            Data => $self->{BUFFER},
            Origin => 'Vizier',
            ReadOpt => {
                id_col => 0,
                ra_col => 1,
                dec_col => 2,
        });
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
                outcols
                /)
           );
}

1;

__END__

=back

=end __PRIVATE_METHODS__

=head1 NOTES

See http://vizier.u-strasbg.fr/doc/asu.html for all the options
supported by Vizier (although they will be the translated form
rather than the abstracted arguments used by C<Astro::Catalog>.

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
