package test_02_touch;

use strict;
use Test::More;

use parent 'Exporter';

our @EXPORT = qw(test_cascade);

sub test_cascade {
    my $cascade = shift;

    isa_ok( $cascade, 'CHI::Cascade');

    $cascade->rule(
	target		=> 'big_array',
	code		=> sub {
	    return [ 1 .. 1000 ];
	}
    );

    $cascade->rule(
	target		=> qr/^one_page_(\d+)$/,
	depends		=> sub { isa_ok( $_[0], 'CHI::Cascade::Rule' ); ok( $_[1] =~ /^\d+$/o); [ 'big_array' ] },
	code		=> sub {
	    my ($rule) = @_;

	    my ($page) = $rule->target =~ /^one_page_(\d+)$/;

	    my $ret = [ @{$rule->dep_values->{big_array}}[ ($page * 10) .. (( $page + 1 ) * 10 - 1) ] ];
	    $ret;
	}
    );

    $cascade->rule(
	target		=> 'one_page_1',
	depends		=> [ sub { isa_ok( $_[0], 'CHI::Cascade::Rule' ); 'big_array' } ],
	code		=> sub {
	    my ($rule) = @_;

	    my $page = 1;

	    my $ret = [ @{$rule->dep_values->{big_array}}[ ($page * 10) .. (( $page + 1 ) * 10 - 1) ] ];
	    $ret;
	}
    );

    ok( $cascade->{stats}{recompute} == 0, 'recompute stats - 1');

    is_deeply( $cascade->run('one_page_0'), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], '0th page from cache');
    cmp_ok( $cascade->{stats}{recompute}, '==', 2 );

    is_deeply( $cascade->run('one_page_1'), [ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 ], '1th page from cache');
    cmp_ok( $cascade->{stats}{recompute}, '==', 3 );

    is_deeply( $cascade->run('one_page_2'), [ 21, 22, 23, 24, 25, 26, 27, 28, 29, 30 ], '2th page from cache');
    cmp_ok( $cascade->{stats}{recompute}, '==', 4 );

    sleep 1;

    # To force recalculate dependencied
    $cascade->touch('big_array');

    is_deeply( $cascade->run('one_page_0'), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], '0th page from cache after touching');
    cmp_ok( $cascade->{stats}{recompute}, '==', 5 );

    is_deeply( $cascade->run('one_page_1'), [ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 ], '1th page from cache after touching');
    cmp_ok( $cascade->{stats}{recompute}, '==', 6 );

    is_deeply( $cascade->run('one_page_0'), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], '0th page from cache');
    cmp_ok( $cascade->{stats}{recompute}, '==', 6 );
}

1;
