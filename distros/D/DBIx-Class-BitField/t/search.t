use Test::More tests => 13;

use lib qw(t/lib);

use Schema;
my $rs = Schema->connect->resultset('Item');

foreach my $i (1..10) {
  my $status = $i < 5 ? 1 : $i < 8 ? 2 : 6;
  ok($rs->create({id => $i, bitfield => $status}));
}

is($rs->search({ bitfield => [1,2,4] })->count, 7);

is($rs->search_bitfield([ status2 => 1, status3 => 1 ])->count, 6);

is($rs->search_bitfield({ status2 => 1, status3 => 0 })->count, 3);

