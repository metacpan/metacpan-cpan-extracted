#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::Exception;
use Data::Dumper;

BEGIN {
    use_ok( 'App::ProcTrends::RRD' ) || print "Bail out!\n";
}

diag( "Testing App::ProcTrends::RRD $App::ProcTrends::RRD::VERSION, Perl $], $^X" );

my $obj;
lives_ok { $obj = App::ProcTrends::RRD->new(); } "constructor test";

my $ref = {
    rrd_dir => "$Bin/test_data/rrd",
};

$obj = App::ProcTrends::RRD->new( $ref );

my $test_data = [
    { metric => 'cpu', process => 'firefox' },
    { metric => 'rss', process => 'firefox' },
];

my @next_test_data;

for my $test ( @{ $test_data } ) {
    my $metric = $test->{ metric };
    my $process = $test->{ process };

    my $data = $obj->gen_image( $metric, $process );
    isnt( $data, undef, 'checking data has something for $metric $process' );
}

done_testing();