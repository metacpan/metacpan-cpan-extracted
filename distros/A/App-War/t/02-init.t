use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

use_ok('App::War');

my @items = qw{ apple banana ceviche durian };

my $war = App::War->new();
$war->items(@items);
is_deeply([sort $war->items], \@items);

$war->init;
my $g = $war->graph;

is(scalar($g->vertices), scalar(@items)) or
    diag("vertices: @{[$g->vertices]}");

