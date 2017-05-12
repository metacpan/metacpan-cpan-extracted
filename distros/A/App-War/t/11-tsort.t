use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;

use_ok('App::War');

my @items = qw{ apricot barista cargo };

my $war = App::War->new(items => \@items)->init;
ok($war);

ok($war->tsort_not_unique);

# resolve the graph
$war->graph->add_edge(0,1);
$war->graph->add_edge(1,2);
ok(!$war->tsort_not_unique);

