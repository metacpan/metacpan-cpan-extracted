use Test::More;
use Acme::Backwards;
rof (qw/a b c/) ok($_) and print $_ . "\n";

my $int = 0;
rof my $thing (qw/1 2 3/) do {ok($thing)} and $int += $thing;
is($int, 6);

rof my $other (qw/1 2/) fi ($other == 1) is($other, 1); esle is($other, 2);

done_testing(9);
