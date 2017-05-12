package test_04_recompute;

use strict;
use Test::More;

use parent 'Exporter';
use Time::HiRes	qw(time);

our @EXPORT = qw(test_cascade);

my $recomputed;

sub test_cascade {
    my $cascade = shift;

    plan tests => 12;

    $cascade->rule(
	target		=> 'big_array',
	code		=> sub {
	    select( undef, undef, undef, 1.0 );
	    return [ 1 .. 1000 ];
	},
	recomputed	=> sub { $recomputed++ }
    );

    $cascade->rule(
	target		=> qr/^one_page_(\d+)$/,
	depends		=> 'big_array',
	code		=> sub {
	    my ($rule) = @_;

	    my ($page) = $rule->target =~ /^one_page_(\d+)$/;

	    my $ret = [ @{$rule->dep_values->{big_array}}[ ($page * 10) .. (( $page + 1 ) * 10 - 1) ] ];
	    $ret;
	},
	recomputed	=> sub { $recomputed++ }
    );

    my ( $state );

    my $time1 = time;
    ok( ! defined $cascade->run( 'one_page_0',
	defer => 1,
	state => \$state )
    );
    my $time2 = time;

    ok( $cascade->{stats}{recompute} == 0 );
    cmp_ok( $time2 - $time1, '<', 0.5 );
    ok( CHI::Cascade::Value->state_as_str($state) eq "CASCADE_DEFERRED | CASCADE_NO_CACHE" );

    my $res;

    $time1 = time;
    ok( defined( $res = $cascade->run( 'one_page_0', state => \$state ) ) );
    $time2 = time;
    ok( $time2 - $time1 > 0.8 && $time2 - $time1 < 1.2 );
    is_deeply( $res, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] );
    ok( CHI::Cascade::Value->state_as_str($state) eq "CASCADE_ACTUAL_VALUE | CASCADE_RECOMPUTED" );

    $time1 = time;
    ok( defined $cascade->run( 'one_page_0',
	defer => 1,
	state => \$state )
    );
    $time2 = time;
    ok( $time2 - $time1 < 0.1 );
    is_deeply( $res, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] );
    ok( CHI::Cascade::Value->state_as_str($state) eq "CASCADE_ACTUAL_VALUE | CASCADE_FROM_CACHE" );
}

1;
