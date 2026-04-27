use strict;
use warnings;
use Test::More;

use Data::PubSub::Shared;

my $ps = Data::PubSub::Shared::Str->new(undef, 16, 512);
my $sub = $ps->subscribe;

# Full byte range
my $bin = join '', map chr, 0..255;
$ps->publish($bin);
my ($m) = $sub->poll;
is $m, $bin, 'full-byte message';

# NUL-containing
$ps->publish("x\x00y\x00z");
($m) = $sub->poll;
is $m, "x\x00y\x00z", 'NUL-containing';

# Empty
$ps->publish("");
($m) = $sub->poll;
is $m, "", 'empty message';

# Repeated varying sizes for arena wrap
for my $i (1..30) {
    my $msg = chr(ord('a') + $i % 26) x ($i * 5);
    $ps->publish($msg);
    my ($got) = $sub->poll;
    is $got, $msg, "iter $i (len " . length($msg) . ")";
}

done_testing;
