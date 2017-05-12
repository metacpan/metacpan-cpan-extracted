package Mocked::WebService::Solr;

use Moose;

extends 'WebService::Solr';

use WebService::Solr::Response;
use HTTP::Response;
use HTTP::Headers;

sub search {
    my $header = HTTP::Headers->new( content_type => 'text/plain;charset=UTF-8' );
    my $content = qq~{
        "responseHeader":{
        "status":0,
        "QTime":4,
        "params":{
            "q":"Software",
            "qt":"standard",
            "wt":"json",
            "rows":"1"}},
        "response":{"numFound":1,"start":0,"docs":[
            {
            "id": 1,
            "name":"fishie",
            "mongo_ids":[1, 3, 6, 9]}]
        }}~;

    WebService::Solr::Response->new(
        HTTP::Response->new( 200, '', $header, $content)
    );
}

package main;

use Test::More;

use Data::SearchEngine::Solr;
use Data::SearchEngine::Query;

my $solr = Data::SearchEngine::Solr->new(
    url => 'http://this_is_fake.com',
    _solr => Mocked::WebService::Solr->new
);

{
    my $query = Data::SearchEngine::Query->new(query => 'anything, because we faked it');
    my $results = $solr->search($query);

    cmp_ok($results->query->query, 'eq', 'anything, because we faked it', 'query');

    cmp_ok($results->pager->total_entries, '==', 1, 'pager total_entries');

    cmp_ok(ref($results->items->[0]->get_value('mongo_ids')), 'eq', 'ARRAY', 'Array instead of last value');
}

done_testing();
