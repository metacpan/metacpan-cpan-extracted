use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;

use_ok('App::War');

my @items = qw{ apple banana ceviche durian };

my $war = App::War->new();
$war->items(@items);
is_deeply([sort $war->items], \@items);

# verify that the graph vivifies
is($war->{graph},undef);
my $g = $war->graph;
isnt($war->{graph},undef);

$war->init;

