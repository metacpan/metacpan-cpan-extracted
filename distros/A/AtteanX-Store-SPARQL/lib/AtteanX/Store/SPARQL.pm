package AtteanX::Store::SPARQL;

use v5.14;
use strict;
use warnings;


our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.010';

use Moo;
use Type::Tiny::Role;
use Types::URI -all;
use Types::Standard qw(InstanceOf);
use Attean;
use Attean::RDF;
use AtteanX::Plan::SPARQLBGP;
use LWP::UserAgent;

use Data::Dumper;
use Carp;

with 'Attean::API::TripleStore';
with 'MooX::Log::Any';

has 'endpoint_url' => (is => 'ro', isa => Uri, coerce => 1);
has 'ua' => (is => 'rw', isa => InstanceOf['LWP::UserAgent'], builder => '_build_ua');

sub _build_ua {
	my $self = shift;
	my $ua = LWP::UserAgent->new;
	$ua->default_headers->push_header( 'Accept' => 'application/sparql-results+json' ); #Attean->acceptable_parsers(handles => q[Attean::API::Result]));
	return $ua;
}

sub get_triples {
	my $self = shift;
	my $pattern = Attean::TriplePattern->new(@_);
	my $ua = $self->ua->clone;
	$ua->default_headers->header( 'Accept' => Attean->acceptable_parsers);
	return $self->get_sparql("CONSTRUCT WHERE {\n\t".$pattern->tuples_string."\n}");
}

sub count_triples {
	my $self = shift;
	my $pattern = Attean::TriplePattern->new(@_);
	my $iter = $self->get_sparql("SELECT (count(*) AS ?count) WHERE {\n\t".$pattern->tuples_string."\n}");
	return $iter->next->value('count')->value;
}

sub get_sparql {
	my $self = shift;
	my $sparql = shift;
	my $ua = shift || $self->ua;
	my $url = $self->endpoint_url->clone;
	my %query = $url->query_form;
	$query{'query'} = $sparql;
	$url->query_form(%query);
	$self->log->debug('Sending GET request for URL: ' . $url);
	my $response = $ua->get( $url );
	if ($response->is_success) {
		my $parsertype = Attean->get_parser( media_type => $response->content_type);
		croak 'Could not parse response from '. $self->endpoint_url->as_string . ' which returned ' . $response->content_type unless defined($parsertype);
		my $p = $parsertype->new;
		return $p->parse_iter_from_bytes($response->content);
	} else {
		$self->log->trace('Got an error, dumping the response: ' . Dumper($response));
		croak 'Error making remote SPARQL call to endpoint ' . $self->endpoint_url->as_string . ' (' .$response->status_line. ')';
	}
}

sub plans_for_algebra {
	my $self = shift;
	my $algebra = shift;
	my $model = shift;
	my $active_graphs = shift;
	my $default_graphs = shift;

	if ($algebra->isa('Attean::Algebra::BGP') && scalar $algebra->elements > 1) {
		my @quads;
		foreach my $triple (@{$algebra->triples}) {
			push(@quads, Attean::Plan::Quad->new(subject => $triple->subject,
															 predicate => $triple->predicate,
															 object => $triple->object,
															 graph => $active_graphs,
															 distinct => 0));
			  }
		return AtteanX::Plan::SPARQLBGP->new(children => \@quads,
																	 distinct => 0); # TODO: Fix
	}
	return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AtteanX::Store::SPARQL - Attean SPARQL store

=head1 SYNOPSIS

  my $store = Attean->get_store('SPARQL')->new(endpoint_url => $url);

=head1 DESCRIPTION

This implements a simple immutable triple store, which simply allows
programmers to use L<Attean> facilities to query remote SPARQL
endpoints.

This distribution also brings a corresponding
L<AtteanX::Model::SPARQL>, which allows query plans to be made, and a
L<AtteanX::Plan::SPARQLBGP> plan class, which contains a
rudimentary cost estimate that attempts to avoid sending Cartesian
joins to remote endpoints if possible.

=head2 Attributes and methods

=over

=item C<< endpoint_url >>

The URL of a remote SPARQL endpoint. Will be coerced into a L<URI>
object, so it may be set as a string or whatever. Required attribute.

=item C<< ua >>

An L<LWP::UserAgent> object to use for remote queries. Will be set to
a reasonable default if not supplied.

=item C<< get_triples >>

Method to query the remote endpoint, as required by L<Attean::API::TripleStore>.

=item C<< count_triples >>

Reimplemented using an aggregate query for greater efficiency.

=item C<< get_sparql($sparql, [ $ua ]) >>

Will submit the given C<$sparql> query to the above C<endpoint_url>
attribute. Optionally, you may pass an L<LWP::UserAgent>, if not it
will use the user agent set using the C<ua> method. Will return an
iterator with the results if the request is successful.



=back



=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-atteanx-store-sparql/issues>.

=head1 ACKNOWLEDGEMENTS

This module is heavily influenced by L<RDF::Trine::Store::SPARQL>.

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015, 2016 by Kjetil Kjernsmo and Gregory
Todd Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

