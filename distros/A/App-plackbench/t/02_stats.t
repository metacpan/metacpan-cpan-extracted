use strict;
use warnings;

use Test::More;
use Test::Deep;

use App::plackbench::Stats;

subtest 'new'                => \&test_new;
subtest 'insert'             => \&test_insert;
subtest 'count'              => \&test_count;
subtest 'mean'               => \&test_mean;
subtest 'median'             => \&test_median;
subtest 'min'                => \&test_min;
subtest 'max'                => \&test_max;
subtest 'standard deviation' => \&test_standard_deviation;
subtest 'percentile'         => \&test_percentile;
subtest 'elapsed'            => \&test_elapsed;
subtest 'rate'               => \&test_rate;

done_testing();

sub test_new {
    my $stats = App::plackbench::Stats->new( 2, 1 );
    ok( $stats->isa('App::plackbench::Stats'),
        'new() should return an instance of App::plackbench::Stats' );
    cmp_deeply(
        $stats,
        noclass( [ 1, 2 ] ),
        'arguments should be copied, sorted and blessed'
    );
    return;
}

sub test_insert {
    my $stats = App::plackbench::Stats->new(10);

    $stats->insert(9);
    cmp_deeply($stats, noclass([9, 10]), 'should insert the new number in the list');

    $stats->insert(12);
    cmp_deeply($stats, noclass([9, 10, 12]), 'should insert the new number in the list in the right order');

    $stats->insert(11);
    cmp_deeply($stats, noclass([9, 10, 11, 12]), 'should insert the new number in the list in the right order');

    return;
}

sub test_count {
    my $stats = App::plackbench::Stats->new( 1, 2, 3, 4, 5 );
    is( $stats->count(), 5,
        'count() should return the number of items in the object' );

    $stats = App::plackbench::Stats->new();
    is( $stats->count(), 0, 'count() should be 0 for empty lists' );

    return;
}

sub test_mean {
    my $stats = App::plackbench::Stats->new( 1, 2, 3, 4, 5 );
    is( $stats->mean(), 3, 'mean() should return the average' );

    $stats = App::plackbench::Stats->new();
    is( $stats->mean(), undef, 'mean() should return undef for an empty list' );

    return;
}

sub test_min {
    my $stats = App::plackbench::Stats->new( 5, 3, 0, 1, 4 );
    is( $stats->min(), 0, 'min() should return the smallest number' );

    $stats = App::plackbench::Stats->new();
    is( $stats->min(), undef, 'min() should return undef for an empty list' );
    return;
}

sub test_max {
    my $stats = App::plackbench::Stats->new( 3, 0, 5, 1, 4 );
    is( $stats->max(), 5, 'max() should return the largest number' );

    $stats = App::plackbench::Stats->new();
    is( $stats->max(), undef, 'max() should return undef for an empty list' );

    return;
}

sub test_median {
    my $stats = App::plackbench::Stats->new( 3, 0, 5, 1, 4 );
    is( $stats->median(), 3, 'median() should return the median' );

    $stats = App::plackbench::Stats->new( 0, 1, 3, 4 );
    is( $stats->median(), 2, 'median() should return the average between the two medians for an odd number of items' );

    $stats = App::plackbench::Stats->new();
    is( $stats->median(), undef, 'median() should return undef for an empty list' );

    return;
}

sub test_standard_deviation {
    my $stats = App::plackbench::Stats->new(2, 4, 4, 4, 5, 5, 7, 9);
    is( $stats->standard_deviation(), 2, 'standard_deviation() should return the standard_deviation' );

    $stats = App::plackbench::Stats->new();
    is( $stats->standard_deviation(), 0, 'standard_deviation() should return 0 for an empty list' );

    return;
}

sub test_percentile {
    my $stats = App::plackbench::Stats->new( 9, 8, 7, 6, 5, 4, 3, 2, 1 );
    is( $stats->percentile(100),
        $stats->max(), '100th percentile should return the largest number' );
    is( $stats->percentile(50),
        $stats->median(), '50th percentile should return median' );
    is( $stats->percentile(0),
        $stats->min(), '0th percentile should return the smallest number' );

    $stats = App::plackbench::Stats->new();
    is( $stats->percentile(50), undef, 'percentile() should return undef for an empty list' );

    return;
}

sub test_elapsed {
    my $stats = App::plackbench::Stats->new(2, 4, 4, 4, 5, 5, 7, 9);
    is( $stats->elapsed(), 40, 'elapsed() should return the total time' );

    $stats = App::plackbench::Stats->new();
    is( $stats->elapsed(), 0, 'elapsed() should return 0 for an empty list' );

    return;
}

sub test_rate {
    my $stats = App::plackbench::Stats->new(0.1, 0.2, 0.3, 0.1, 0.2, 0.1);
    is( $stats->rate(), 6, 'rate() should return the number of requests per second' );

    $stats = App::plackbench::Stats->new();
    is( $stats->rate(), 0, 'rate() should return 0 for an empty list' );

    return;
}

1;

