package Test::Attean::Store::SPARQL::Role::CreateStore;
use strict;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.012';

use RDF::Trine::Model;
use RDF::Trine qw(statement iri blank literal);
use RDF::Endpoint;
use Test::LWP::UserAgent;
use HTTP::Message::PSGI;
use Moo::Role;

sub create_store {
	my $self = shift;
	my %args = @_;
	my $triples = $args{triples} // [];
	my $model = RDF::Trine::Model->temporary_model; # For creating endpoint
	foreach my $atteantriple (@{$triples}) {
		my $s = iri($atteantriple->subject->value);
		if ($atteantriple->subject->is_blank) {
			$s = blank($atteantriple->subject->value);
		}
		my $p = iri($atteantriple->predicate->value);
		my $o = iri($atteantriple->object->value);
		if ($atteantriple->object->is_literal) {
			# difference with RDF 1.0 vs RDF 1.1 datatype semantics
			if ($atteantriple->object->datatype->value eq 'http://www.w3.org/2001/XMLSchema#string') {
				$o = literal($atteantriple->object->value, $atteantriple->object->language);
			} else {
				$o = literal($atteantriple->object->value, $atteantriple->object->language, $atteantriple->object->datatype->value);
			}
		} elsif ($atteantriple->object->is_blank) {
			$o = blank($atteantriple->object->value);
		}
		$model->add_statement(statement($s, $p, $o));
	}
	my $end = RDF::Endpoint->new($model);
	my $app = sub {
		my $env = shift;
		my $req = Plack::Request->new($env);
		my $resp = $end->run( $req );
		return $resp->finalize;
	};
	my $useragent = Test::LWP::UserAgent->new;
	$useragent->register_psgi('localhost', $app);
	# Now, we should just have had a URL of the endpoint
	my $url = 'http://localhost:5000/sparql';
	my $store = Attean->get_store('SPARQL')->new(endpoint_url => $url,
                                                ua => $useragent
                                               );
	return $store;
}

1;

=pod 

=head1 NAME

Test::Attean::Store::SPARQL::Role::CreateStore - Create a SPARQL store for tests

=head1 SYNOPSIS

Either:

  use Test::More;
  use Test::Roo;
  with 'Test::Attean::TripleStore', 'Test::Attean::Store::SPARQL::Role::CreateStore';
  run_me;
  done_testing;

or:

  package TestCreateStore {
   	use Moo;
   	with 'Test::Attean::Store::SPARQL::Role::CreateStore';
  };
  my $triples = [
  				   triple(iri('http://example.org/bar'), iri('http://example.org/c'), iri('http://example.org/foo')),
               # [...]
				  ];

  my $test = TestCreateStore->new;
  my $store = $test->create_store(triples => $triples);


=head1 DESCRIPTION


There are two ways of using this. The original idea is to use it to
test a triple/quad that uses L<Test::Attean::TripleStore>, like in the
first example in the synopsis.

It is also possible to utilize this role like in the second example to
create a store for testing other parts of the code too. In that
example, first wrap a class around the role, then create an arrayref
of triples, which should be used to populate the store. Then,
instantiate an object of the class, and call it's C<create_store>
method with the triples. Now, you have a proper store that can be used
in tests.

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015, 2016 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
