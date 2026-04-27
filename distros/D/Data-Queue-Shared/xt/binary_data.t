use strict;
use warnings;
use Test::More;

use Data::Queue::Shared;

my $q = Data::Queue::Shared::Str->new(undef, 16, 4096);

# All bytes 0..255
my $bin = join '', map chr, 0..255;
$q->push($bin);
is $q->pop, $bin, 'full-byte-range roundtrip';

# NUL-containing
my $with_nul = "a\x00b\x00c";
$q->push($with_nul);
is $q->pop, $with_nul, 'NUL-containing message';

# Empty string
$q->push("");
is $q->pop, "", 'empty string message';

# Large message at msg_size boundary (arena-cap bound)
my $big = "x" x 1024;
$q->push($big);
is $q->pop, $big, '1KB message';

# Rapid small/large mix for arena wrap
for my $i (1..20) {
    my $m = chr(ord('a') + $i % 26) x ($i * 10);
    $q->push($m);
    is $q->pop, $m, "mix iter $i";
}

done_testing;
