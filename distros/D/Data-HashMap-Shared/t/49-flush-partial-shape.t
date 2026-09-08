use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use File::Temp qw(tempdir);

# flush_expired_partial returns ($flushed, $done), and the XSUB is written ten
# times over.  Drive every variant through a full expiry cycle and pin each
# value to what only IT can be: the first sums to the expired count, the
# second is 0 or 1 and true exactly once.

my @variants = qw(II IS SI SS I16 I16S I32 I32S SI16 SI32);
my $dir = tempdir(CLEANUP => 1);
my %map;
for my $v (@variants) {
    my $cls = "Data::HashMap::Shared::$v";
    eval "require $cls; 1" or die $@;
    my $m = $cls->new("$dir/fep-$v.shm", 64, 0, 60);   # count under a long TTL first
    $m->put($_, $_) for 1 .. 30;
    is $m->size, 30, "$v: 30 live entries before expiry";
    $m->set_ttl($_, 1) for 1 .. 30;
    $map{$v} = $m;
}
Time::HiRes::sleep(1.2);                                               # everything expires, once

for my $v (@variants) {
    my $m = $map{$v};
    my ($sum_first, $sum_second, $calls, $shape_bad, $range_bad) = (0, 0, 0, 0, 0);
    while (1) {
        my @r = $m->flush_expired_partial(8);
        $calls++;
        $shape_bad++ unless @r == 2;
        my ($n, $d) = @r;
        $range_bad++ unless defined $n && defined $d && $n =~ /^\d+$/ && $n <= 8 && ($d eq '0' || $d eq '1');
        $sum_first  += $n // 0;
        $sum_second += $d // 0;
        last if $d || $calls > 1000;
    }
    is $shape_bad,  0,  "$v: every call returned exactly two values ($calls calls)";
    is $range_bad,  0,  "$v: first value in 0..limit, second value exactly 0 or 1";
    is $sum_first,  30, "$v: the first value sums to the 30 expired entries";
    is $sum_second, 1,  "$v: the second value was true once, on the final call";
    is $m->size,    0,  "$v: table empty afterwards";
}
done_testing;
