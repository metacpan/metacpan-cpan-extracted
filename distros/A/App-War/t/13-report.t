use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

use_ok('App::War');

my @items = qw{ ant bear civet donkey };

# construct the war object with known item order
my $war = App::War->new();
$war->{items} = \@items;
$war->init;

# resolve the graph
$war->graph->add_edge($_, $_ + 1) for 0 .. 2;

# check the output
like($war->report, qr/graph: 0-1,1-2,2-3/);
like($war->report, qr/sort: ant bear civet donkey/);

