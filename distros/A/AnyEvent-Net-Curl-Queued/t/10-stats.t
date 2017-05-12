#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use_ok('AnyEvent::Net::Curl::Queued::Stats');

my $obj = {
    appconnect_time     => 0,
    connect_time        => 0.000518,
    header_size         => 285,
    namelookup_time     => 0.000427,
    num_connects        => 1,
    pretransfer_time    => 0.000527,
    redirect_count      => 0,
    redirect_time       => 0,
    request_size        => 189,
    size_download       => 5079,
    size_upload         => 0,
    starttransfer_time  => 0.001488,
    total_time          => 0.001751,
};

my $stats = AnyEvent::Net::Curl::Queued::Stats->new(stats => { %{$obj} });

isa_ok($stats, 'AnyEvent::Net::Curl::Queued::Stats');
can_ok($stats, qw(stamp stats sum));

my $n = 10;
ok($stats->sum($stats), "increment stats $_") for 1 .. $n;

for (sort keys %{$obj}) {
    my $x = $obj->{$_} * (2 ** $n);
    my $y = $stats->stats->{$_};

    ok($x == $y, "$_: $x == $y");
}

done_testing(3 + $n + scalar keys %{$obj});
