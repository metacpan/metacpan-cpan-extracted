#!perl -T

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Data::Dump::Color qw(dump dd ddx);

local $Data::Dump::Color::COLOR = 0;
local $Data::Dump::Color::COLOR_THEME = "Default16";
subtest dump => sub {
    is_deeply(dump([1, 2, 3]), "[1, 2, 3]");
    my $var = [0,1,[],3]; $var->[1] = $var->[2];
    is_deeply(dump($var), q(do {
  my $var = [0, [], '$var->[1]', 3];
  $var->[2] = $var->[1];
  $var;
}));
};

DONE_TESTING:
done_testing;

__END__
# disabled for now
is(dd([1, 2, 3]), "[1, 2, 3]\n", "[1, 2, 3]");
