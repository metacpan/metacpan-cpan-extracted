use strict;
use Test::More;

use lib 't/lib';

use Data::SearchEngine;
use Data::SearchEngine::Query;
use SearchEngineWee;

my @data = (
    {
        id => '1',
        name => 'One Fish',
        description => 'A fish numbered one'
    },
    {
        id => '2',
        name => 'Two Fish',
        description => 'A fish numbered two'
    },
    {
        id => '3',
        name => 'Red Fish',
        description => 'A fish colored red '
    },
    {
        id => '4',
        name => 'Blue Fish',
        description => 'A fish colored blue'
    },
);

my $searcher = SearchEngineWee->new;
foreach my $prod (@data) {
    $searcher->add($prod);
}

{
    my $query = Data::SearchEngine::Query->new(query => 'Fish');
    my $results = $searcher->search($query);
    my $ser = $results->freeze({ format => 'JSON' });
    my $results2 = SEWeeResults->thaw($ser, { format => 'JSON' });
    cmp_ok($results->query->query, 'eq', 'Fish', 'query');
    cmp_ok($results2->pager->total_entries, '==', 4, 'pager total_entries');
}

done_testing;