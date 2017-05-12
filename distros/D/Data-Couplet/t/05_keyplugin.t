
use strict;
use warnings;

use Test::More;
use Test::Moose;

use Data::Couplet;

my $dc = Data::Couplet->new(
  qw(
    a b
    c d
    e f
    g h
    )
);

my $t = 0;

++$t;
does_ok( $dc, 'Data::Couplet::Plugin::KeyCount' );

++$t;
can_ok( $dc, qw( last_index indices count ) );

++$t;
is( $dc->count, 4, 'Count works' );

++$t;
is( $dc->last_index, 3, 'Index works' );

++$t;

is_deeply( [ $dc->indices ], [ 0, 1, 2, 3 ], "Indices work" ) || diag explain [$dc];

done_testing($t);

