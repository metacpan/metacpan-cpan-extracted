package test_08_actual_term_expires;

use strict;
use Test::More;
use CHI::Cascade::Value ':state';

use parent 'Exporter';

our @EXPORT = qw(test_cascade);

my $recomputed;

sub test_cascade {
    my $cascade = shift;

    isa_ok( $cascade, 'CHI::Cascade');

    $cascade->rule(
	target		=> 'big_array',
	code		=> sub {
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

    $cascade->rule(
	target		=> 'actual_test',
	actual_term	=> 2.0,
	value_expires	=> '3s',
	depends		=> 'one_page_0',
	code		=> sub {
	    $_[2]->{one_page_0}
	}
    );

    ok( $cascade->{stats}{recompute} == 0, 'recompute stats - 1');

    is_deeply( $cascade->run('one_page_0'), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], '0th page from cache');
    ok( $cascade->{stats}{recompute} == 2 && $recomputed == 2, 'recompute stats - 2');

    is_deeply( $cascade->run('one_page_1'), [ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 ], '1th page from cache');
    cmp_ok( $cascade->{stats}{recompute}, '==', 3, 'recompute stats - 3');

    is_deeply( $cascade->run('one_page_0'), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], '0th page from cache');
    cmp_ok( $cascade->{stats}{recompute}, '==', 3, 'recompute stats - 4');

    select( undef, undef, undef, 1.0 );

    # To force recalculate dependencied
    $cascade->touch('big_array');

    is_deeply( $cascade->run('one_page_0'), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], '0th page from cache after touching');
    cmp_ok( $cascade->{stats}{recompute}, '==', 4, 'recompute stats - 5');

    is_deeply( $cascade->run('one_page_1'), [ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 ], '1th page from cache after touching');
    cmp_ok( $cascade->{stats}{recompute}, '==', 5, 'recompute stats - 6');

    is_deeply( $cascade->run('one_page_0'), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], '0th page from cache');
    cmp_ok( $cascade->{stats}{recompute}, '==', 5, 'recompute stats - 7');

    ok( $cascade->{stats}{recompute} == $recomputed, 'recompute stats - 8');

    # To checking of actual_term option
    my $state = 0;

    is_deeply( $cascade->run( 'actual_test', state => \$state ), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], 'actual_test');
    ok( $cascade->{stats}{recompute} == 6 );

    my $dependencies_lookup = $cascade->{stats}{dependencies_lookup};

    is_deeply( $cascade->run( 'one_page_0', state => \$state, actual_term => 2.0 ), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], '0th page from cache after touching');
    ok( $state & CASCADE_ACTUAL_TERM );

    select( undef, undef, undef, 2.1 );

    is_deeply( $cascade->run( 'actual_test', state => \$state ), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], 'actual_test');
    ok( not $state & CASCADE_ACTUAL_TERM );

    is_deeply( $cascade->run('one_page_1', state => \$state, actual_term => 2.0), [ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 ] );
    ok( $cascade->{stats}{recompute} == 6 );
    ok( not $state & CASCADE_ACTUAL_TERM );

    ok( $cascade->{stats}{dependencies_lookup} > $dependencies_lookup );

    select( undef, undef, undef, 1.0 );

    # Here the 'value_expires' happened
    # Before there was bug - the expires has been updated by actual_cash checking
    is_deeply( $cascade->run( 'actual_test', state => \$state ), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], 'actual_test');
    ok( $cascade->{stats}{dependencies_lookup} > $dependencies_lookup );
    ok( $cascade->{stats}{recompute} == 7 );	# Here were recomputed 'actual_test' & 'one_page_0'

    # Here target's value has expired before the actual term finished
    ok( not $state & CASCADE_ACTUAL_TERM );
    ok( ( $state & ( CASCADE_RECOMPUTED | CASCADE_ACTUAL_VALUE ) ) == ( CASCADE_RECOMPUTED | CASCADE_ACTUAL_VALUE ) );

    select( undef, undef, undef, 1.0 );

    is_deeply( $cascade->run( 'actual_test', state => \$state ), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], 'actual_test');
    ok( $state & CASCADE_ACTUAL_TERM );
    ok( $cascade->{stats}{recompute} == 7 );

    done_testing;
}

1;
