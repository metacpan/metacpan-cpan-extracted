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


my $basequery =<<'EOQ';
PREFIX dbo: <http://dbpedia.org/ontology/> 
CONSTRUCT {
  ?place a dbo:PopulatedPlace .
  ?place dbo:populationTotal ?pop .
} WHERE {
  ?place a dbo:PopulatedPlace .
  ?place dbo:populationTotal ?pop .
  FILTER (?pop < 50)
}
EOQ

package TestLDFCreateStore {
        use Moo;
        with 'Test::Attean::Store::LDF::Role::CreateStore';
};

my $test = TestLDFCreateStore->new;
my $ldfstore	= $test->create_store(triples => [triple(iri('http://example.org/foo'), iri('http://example.org/m/r'), literal('1'))]);

my $store = Attean->get_store('SPARQL')->new('endpoint_url' => iri('http://test.invalid/'));
my $model = AtteanX::Query::Cache::Analyzer::Model->new(store => $store, ldf_store => $ldfstore, cache => $cache);
my $analyzer1 = AtteanX::Query::Cache::Analyzer->new(model => $model, query => $basequery, store => $redis2);
note 'Testing counts without actual caching';

my @patterns1 = $analyzer1->count_patterns;
is(scalar @patterns1, 0, 'Nothing now');


$basequery =~ s/< 50/> 5000000/;

my $analyzer2 = AtteanX::Query::Cache::Analyzer->new(model => $model, query => $basequery, store => $redis2);

my @patterns2 = $analyzer2->count_patterns;
is(scalar @patterns2, 0, 'Still nothing');

$basequery =~ s/a dbo:PopulatedPlace/dbo:abstract ?abs/g;


my $analyzer3 = AtteanX::Query::Cache::Analyzer->new(model => $model, query => $basequery, store => $redis2);


my @patterns3 = $analyzer3->count_patterns;
is(scalar @patterns3, 1, 'One pattern');

my $pattern = shift @patterns3;
isa_ok($pattern, 'Attean::TriplePattern');
ok($pattern->subject->is_variable, 'Subject is variable');
ok($pattern->predicate->is_resource, 'Predicate is bound');
ok($pattern->object->is_variable, 'Object is variable');
is($pattern->predicate->compare(iri('http://dbpedia.org/ontology/populationTotal')), 0, 'The correct predicate IRI');

$basequery =~ s/FILTER \(\?pop > 5000000\)/?place a dbo:Region ./;
my $analyzer4 = AtteanX::Query::Cache::Analyzer->new(model => $model, query => $basequery, store => $redis2);


my @patterns4 = $analyzer4->count_patterns;
is(scalar @patterns4, 2, 'Two patterns');

$pattern = shift @patterns4;
is($pattern->predicate->compare(iri('http://dbpedia.org/ontology/populationTotal')), 0, 'The correct predicate IRI');
$pattern = shift @patterns4;
is($pattern->predicate->compare(iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')), 0, 'The correct predicate IRI');
done_testing();
