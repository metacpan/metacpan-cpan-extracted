=pod

=encoding utf-8

=head1 PURPOSE

Test around the post-execution analysis.

=head1 SYNOPSIS

It may come in handy to enable logging for debugging purposes, e.g.:

  LOG_ADAPTER=Screen DEBUG=1 prove -lv t/analysis.t

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
#use Carp::Always;
use Redis;
use Test::RedisServer;
use Attean;
use Attean::RDF;
use AtteanX::Query::Cache::Analyzer;
use Data::Dumper;
use AtteanX::Model::SPARQLCache;
use Log::Any::Adapter;
Log::Any::Adapter->set($ENV{LOG_ADAPTER} ) if ($ENV{LOG_ADAPTER});

my $cache = CHI->new( driver => 'Memory', global => 1 );

my $redis_server = Test::RedisServer->new;

my $redis2 = Redis->new( $redis_server->connect_info );

is $redis2->ping, 'PONG', 'Redis store ping pong ok';

package TestLDFCreateStore {
        use Moo;
        with 'Test::Attean::Store::LDF::Role::CreateStore';
};

my $test = TestLDFCreateStore->new;
my $ldfstore	= $test->create_store(triples => [
																 triple(iri('http://example.org/foo'), iri('http://example.org/m/r'), literal('1')),
																 triple(iri('http://example.org/foo'), iri('http://example.org/m/p'), iri('http://example.org/bar')),
																 triple(iri('http://example.org/m/a'), iri('http://example.org/m/p'), iri('http://example.org/bar')),
																 triple(iri('http://example.org/bar'), iri('http://example.org/m/p'), literal('2')),
																 triple(iri('http://example.org/bar'), iri('http://example.org/m/p'), literal('o')),
																 triple(iri('http://example.org/bar'), iri('http://example.org/m/p'), literal('dahut')),
																 triple(iri('http://example.com/foo'), iri('http://example.org/m/p'), literal('dahut')),
																 triple(iri('http://example.com/foo'), iri('http://example.org/m/p'), iri('http://example.org/baz')),
																 triple(iri('http://example.com/foo'), iri('http://example.org/m/p'), iri('http://example.org/foobar')),
																 triple(iri('http://example.com/bar'), iri('http://example.org/m/p'), literal('dahut')),
																 triple(iri('http://example.org/dahut'), iri('http://example.org/m/dahut'), literal('1')),
																 triple(iri('http://example.org/dahut'), iri('http://example.org/m/dahut'), literal('Foobar')),
																 triple(iri('http://example.org/foo'), iri('http://example.org/m/q'), literal('xyz')),
																 triple(iri('http://example.com/foo'), iri('http://example.org/m/b'), iri('http://example.org/m/c')),
																 triple(iri('http://example.com/dahut'), iri('http://example.org/m/b'), literal('2')),
																 triple(iri('http://example.org/m/a'), iri('http://example.org/m/q'), iri('http://example.org/baz')),
																 triple(iri('http://example.org/m/a'), iri('http://example.org/m/q'), iri('http://example.org/foobar')),
																 triple(iri('http://example.org/m/a'), iri('http://example.org/m/c'), iri('http://example.org/foo')),
																 triple(iri('http://example.org/m/a'), iri('http://example.org/m/p'), iri('http://example.org/m/o')),
																]);



my $store = Attean->get_store('SPARQL')->new('endpoint_url' => iri('http://test.invalid/'));
my $model = AtteanX::Query::Cache::Analyzer::Model->new(store => $store, cache => $cache, ldf_store => $ldfstore);

subtest '3-triple BGP where cache breaks the join to cartesian' => sub {

	my $query = <<'END';
SELECT * WHERE {
  ?a <http://example.org/m/c> ?s . 
  ?s <http://example.org/m/p> ?o . 
  ?o <http://example.org/m/b> "2" .
}
END
	
	$model->cache->set('?v002 <http://example.org/m/p> ?v001 .', {'<http://example.org/foo>' => ['<http://example.org/bar>'],
														  '<http://example.com/foo>' => ['<http://example.org/m/b>', '<http://example.org/foobar>']});
	my $analyzer = AtteanX::Query::Cache::Analyzer->new(model => $model, query => $query, store => $redis2);
	my @patterns = $analyzer->best_cost_improvement;
	is(scalar @patterns, 2, '2 patterns to submit');
	foreach my $pattern (@patterns) {
		isa_ok($pattern, 'Attean::TriplePattern');
		ok($pattern->predicate->compare(iri('http://example.org/m/p')), 'Predicate is not <http://example.org/m/p>'); # cached, compare returns 0 when it is the same
	}
};

note 'This test is CPU intensive';
subtest '4-triple BGP where one pattern makes little impact' => sub {

my $query = <<'END';
SELECT * WHERE {
	?s <http://example.org/m/r> "1" .
   ?s <http://example.org/m/p> ?o .
	?s <http://example.org/m/q> "xyz" . 
	?o <http://example.org/m/b> <http://example.org/m/c> . 
}
END

	my $analyzer = AtteanX::Query::Cache::Analyzer->new(model => $model, query => $query, store => $redis2);
	my @patterns = $analyzer->best_cost_improvement;
	is(scalar @patterns, 2, '2 patterns to submit');
	foreach my $pattern (@patterns) {
		isa_ok($pattern, 'Attean::TriplePattern');
		ok($pattern->predicate->compare(iri('http://example.org/m/p')), 'Predicate is not <http://example.org/m/p>');  # cached, compare returns 0 when it is the same
	}
   ok(! $patterns[0]->predicate->compare(iri('http://example.org/m/b')), 'Predicate in first pattern is <http://example.org/m/b>');
   ok($patterns[1]->predicate->compare(iri('http://example.org/m/b')), 'Predicate in second pattern is not <http://example.org/m/b>');
};

done_testing();
