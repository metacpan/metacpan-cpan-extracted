#! /usr/bin/env perl

use strict;
use warnings;
use Test::TAPv13 ":all";
use Test::More tests => 3;
use Data::DPath 'dpath';
use Data::Dumper;
use Benchmark ':all', ':hireswallclock';
use Devel::Size 'total_size';
use TAP::DOM;

BEGIN {
        use_ok( 'Data::DPath' );
}

my $tap;
{
        local $/;
        open (TAP, "< xt/regexp-common.tap") or die "Cannot read xt/regexp-common.tap";
        $tap = <TAP>;
        close TAP;
}

local $Data::DPath::USE_SAFE;

my $path          = '//is_has[ value & $TAP::DOM::HAS_TODO & $TAP::DOM::IS_ACTUAL_OK ]/..';
#my $path          = '//is_has[ print(((value & $TAP::DOM::IS_ACTUAL_OK) ? "1" : "0")."\n") ; value & $TAP::DOM::HAS_TODO & $TAP::DOM::IS_ACTUAL_OK ]/..';
#my $path          = qq|//is_has[ print(((value & $IS_ACTUAL_OK) ? "1" : "0")."\n") ; value & $HAS_TODO & $IS_ACTUAL_OK ]/..|;
#my $path          = '//is_has[ print value."\n" ]/..';
#my $expected      = "2";

foreach my $usebitsets (0..1) {
        my $huge_data = TAP::DOM->new( tap => $tap, usebitsets => $usebitsets );

        my $resultlist;

        diag "Running benchmark. Can take some time ...";
        my $count = 1;
        my $t = timeit ($count, sub { $resultlist = [ dpath($path)->match($huge_data) ] });
        my $n = $t->[5];
        my $throughput = $n / $t->[0];
        diag Dumper($resultlist);
        ok(1, "benchmark -- usebitsets = $usebitsets");
        tap13_yaml({ benchmark => {
                                   timestr    => timestr($t),
                                   wallclock  => $t->[0],
                                   usr        => $t->[1],
                                   sys        => $t->[2],
                                   throughput => $throughput,
                                  }
                   });
}

done_testing;
