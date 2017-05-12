package AtteanX::Query::Cache::Retriever;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.002';

use Moo;
use Carp qw(croak);
use Attean::RDF;
use Types::Standard qw(InstanceOf);

has model => (is => 'ro',
				  isa => InstanceOf['AtteanX::Model::SPARQLCache'],
				  required => 1);

with 'MooX::Log::Any';


sub fetch {
	my ($self, $triple) = @_;
	$triple = $triple->canonicalize;
	my $key = $triple->tuples_string;
	my @vars	= $triple->values_consuming_role('Attean::API::Variable');
	my $use_hash = (scalar @vars) - 1;
	if ($use_hash < 0) {
		croak "No variables in triple pattern $key";
	} elsif ($use_hash > 1) {
		croak "Only triple patterns with one or two variables are supported, got $key";
	}

	if ($self->model->isa('AtteanX::Model::SPARQLCache::LDF')) {
		my @terms = $triple->values;
		my @termswithvars;
		my %tmp = $triple->mapping;
		while (my ($pos, $term) = each (%tmp)) {
			if ($term->does('Attean::API::Variable')) {
				push(@termswithvars, $pos);
			}
		}
		my $iter = $self->model->ldf_store->get_triples(@terms);
		if ($use_hash) { # Now, decide if we insert an array or a hash into the cache.
			@termswithvars = reverse sort @termswithvars; # Will ensure s, p, o order
			my $data;
			while (my $res = $iter->next) {
				push(@{$data->{$res->value($termswithvars[0])->ntriples_string}}, $res->value($termswithvars[1])->ntriples_string);
			}
			return $data;
		} else {
			my @data;
			while (my $res = $iter->next) {
				push(@data, $res->value($termswithvars[0])->ntriples_string);
			}
			return \@data;
		}
	} else {
		my $sparql = 'SELECT ' . join(' ', map { $_->ntriples_string } @vars) .
		  " WHERE {\n\t" . $triple->as_sparql . '. }';
		$self->log->debug("Running SPARQL query\n$sparql");
		my $iter = $self->model->get_sparql($sparql);
		if ($use_hash) { # Now, decide if we insert an array or a hash into the cache.
			my $data;
			while (my $res = $iter->next) {
				push(@{$data->{$res->value($vars[0]->value)->ntriples_string}}, $res->value($vars[1]->value)->ntriples_string);
			}
			return $data;
		} else {
			my @data;
			while (my $res = $iter->next) {
				my ($value) = $res->values;
				push(@data, $value->ntriples_string);
			}
			return \@data;
		}
	}
}



1;
