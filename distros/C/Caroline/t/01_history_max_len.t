use strict;
use warnings;
use utf8;
use Test::More;
use Caroline;

my $c = Caroline->new(history_max_len => 5);
for (1..10) {
    $c->history_add($_);
}
is(0+@{$c->history}, 5);
is_deeply($c->history, [6,7,8,9,10]);

done_testing;

