=pod

=encoding utf-8

=head1 PURPOSE

Test that we can fetch and cache

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
use Redis;
use Test::RedisServer;

use Log::Any::Adapter;
Log::Any::Adapter->set($ENV{LOG_ADAPTER} ) if ($ENV{LOG_ADAPTER});

package TestCreateStore {
	use Moo;
	with 'Test::Attean::Store::SPARQL::Role::CreateStore';
};

package TestLDFCreateStore {
        use Moo;
        with 'Test::Attean::Store::LDF::Role::CreateStore';
};

my $redis_server = Test::RedisServer->new;

my $triples = [
				   triple(iri('http://example.org/bar'), iri('http://example.org/c'), iri('http://example.org/foo')),
				   triple(iri('http://example.org/foo'), iri('http://example.org/p'), iri('http://example.org/baz')),
				   triple(iri('http://example.org/baz'), iri('http://example.org/b'), literal('2')),
				   triple(iri('http://example.com/foo'), iri('http://example.org/p'), literal('dahut')),
				   triple(iri('http://example.org/dahut'), iri('http://example.org/dahut'), literal('1')),
				  ];


my $test = TestCreateStore->new;
my $store = $test->create_store(triples => $triples);
my $testldf = TestLDFCreateStore->new;
my $ldfstore = $testldf->create_store(triples => $triples);

my $model = AtteanX::Query::Cache::Analyzer::Model->new(store => $store,
																		  ldf_store => $ldfstore,
																		  cache => CHI->new( driver => 'Memory', 
																									global => 1 ));


my $redis2 = Redis->new( $redis_server->connect_info );

is $redis2->ping, 'PONG', 'Redis store ping pong ok';


note '3-triple BGP where cache breaks the join to cartesian';

my $query = <<'END';
SELECT * WHERE {
  ?a <http://example.org/c> ?s . 
  ?s <http://example.org/p> ?o . 
  ?o <http://example.org/b> "2" .
}
END

can_ok($model, 'cache');

$model->cache->set('?v002 <p> ?v001 .', {'<http://example.org/foo>' => ['<http://example.org/bar>'],
													  '<http://example.com/foo>' => ['<http://example.org/baz>', '<http://example.org/foobar>']});
my $analyzer = AtteanX::Query::Cache::Analyzer->new(model => $model, query => $query, store => $redis2);
my $count = $analyzer->analyze_and_cache('best_cost_improvement');
is($count, 2, 'Two triple patterns has match');


done_testing;
