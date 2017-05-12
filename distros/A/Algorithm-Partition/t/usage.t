use Test::More tests => 7;

use Algorithm::Partition qw(partition);

my ($one, $two);

($one, $two) = partition();
is($one, undef, "Can't partition an empty set");
ok($two =~ /\bempty\b/i, "Error contains word 'empty'");

($one, $two) = partition(1);
is($one, undef, "Can't partition an odd-sum set");
ok($two =~ /\bodd\b/i, "Error contains word 'odd'");

($one, $two) = partition(1, 2);
is($one, undef);

($one, $two) = partition(1, 2, 3, 4);
is(ref($one), 'ARRAY');
is(ref($two), 'ARRAY');
