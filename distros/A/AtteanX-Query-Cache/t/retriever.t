=pod

=encoding utf-8

=head1 PURPOSE

Test that prefetching from the net works

=head1 SYNOPSIS

It may come in handy to enable logging for debugging purposes, e.g.:

  LOG_ADAPTER=Screen DEBUG=1 prove -lv t/retriever.t

This requires that L<Log::Any::Adapter::Screen> is installed.

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015, 2016 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use v5.14;
use autodie;
use utf8;
use Test::Modern;

use CHI;
use Attean::RDF qw(triple triplepattern variable iri literal);

use AtteanX::Query::Cache::Retriever;
use AtteanX::Model::SPARQLCache;
use AtteanX::Model::SPARQLCache::LDF;
#use Carp::Always;
use Log::Any::Adapter;
Log::Any::Adapter->set($ENV{LOG_ADAPTER} ) if ($ENV{LOG_ADAPTER});


package TestCreateStore {
	use Moo;
	with 'Test::Attean::Store::SPARQL::Role::CreateStore';
};

my $triples = [
				   triple(iri('http://example.org/foo'), iri('http://example.org/p'), literal('1')),
				   triple(iri('http://example.org/bar'), iri('http://example.org/p'), literal('1')),
				   triple(iri('http://example.com/foo'), iri('http://example.org/p'), literal('dahut')),
				   triple(iri('http://example.org/bar'), iri('http://example.org/p'), iri('http://example.org/dahutten')),
				   triple(iri('http://example.org/dahut'), iri('http://example.org/dahut'), literal('1')),
				  ];


my $test = TestCreateStore->new;
my $store = $test->create_store(triples => $triples);
my $cache = CHI->new( driver => 'Memory', global => 1);

{
	note "Test SPARQL Retriever";
	my $model = AtteanX::Model::SPARQLCache->new(store => $store, 
																cache => $cache);
	
	my $retriever = AtteanX::Query::Cache::Retriever->new(model => $model);
	run_tests($retriever);
}

{
	note "Test LDF Retriever";
	package TestLDFCreateStore {
		use Moo;
		with 'Test::Attean::Store::LDF::Role::CreateStore';
	};

	my $testldf = TestLDFCreateStore->new;
	my $ldfstore	= $testldf->create_store(triples => $triples);

	my $model = AtteanX::Model::SPARQLCache::LDF->new(store => $store, 
																	  cache => $cache,
																	  ldf_store => $ldfstore);
	
	my $retriever = AtteanX::Query::Cache::Retriever->new(model => $model);
	run_tests($retriever);
}


sub run_tests {
	my $retriever = shift;
	subtest 'Simple single-variable triple' => sub {
		my $t = triplepattern(variable('s'), iri('http://example.org/p'), literal('1'));
		my $data = $retriever->fetch($t);
		is(ref($data), 'ARRAY', 'We have arrayref');
		is_deeply([sort @{$data}], ['<http://example.org/bar>','<http://example.org/foo>'], 'expected arrayref');
	};
	
	subtest 'Simple dual-variable triple' => sub {
		my $t = triplepattern(variable('s'), iri('http://example.org/p'), variable('o'));
		my $data = $retriever->fetch($t);
		is(ref($data), 'HASH', 'We have hashref');
		is(scalar keys %{$data}, 3, 'Three keys');
		foreach my $key (keys %{$data}) {
			like($key, qr/example/, 'All keys have example in them');
			is(ref($data->{$key}), 'ARRAY', 'All entries have arrayrefs');
		}
		is(scalar @{$data->{'<http://example.org/bar>'}}, 2, 'One of them has two elements');
	};
}



done_testing;
