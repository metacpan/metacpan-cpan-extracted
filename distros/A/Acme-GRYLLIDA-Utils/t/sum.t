use Test::More;
BEGIN { use_ok( 'Acme::GRYLLIDA::Utils' ) }
ok(defined &sum, 'sum() is exported' );

is(sum( 1, 2, 3 ), 6, '1+2+3 is six' );
is(sum( qw(1 2 3) ), 6, '1+2+3 as strings is six' );
is(sum( 4, -9, 37, 6 ), 38, '4−9+37+6 is six' );
is(sum( 3.14, 2.2 ), 5.34, '3.14 + 2.2 is 5.34' );
is(sum(), undef, 'No arguments returns undef' );
is(sum( qw(a b) ), undef, 'All bad args gives undef' );
is(sum( qw(a b 4 5) ), 9, 'Some good args works' );

done_testing();
