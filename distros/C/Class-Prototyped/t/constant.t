use strict;
$^W++;
use Class::Prototyped qw(:NEW_MAIN);
use Data::Dumper;
use Test;

BEGIN {
	$|++;
	plan tests => 32;
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

my $p1 = new( a => 2, [qw(b constant)] => 2);
my $p2 = $p1->clone();

ok( $p1->a, 2 );
ok( $p1->{a}, 2 );

ok( $p1->a(3), 3 );
ok( $p1->{a}, 3 );
ok( $p1->a, 3 );

ok( $p1->{a} = 4, 4 );
ok( $p1->a, 4 );
ok( $p1->{a}, 4 );

ok( $p1->b, 2 );
ok( $p1->{b}, 2 );

ok( $p1->b(3), 2 );
ok( $p1->{b}, 2 );
ok( $p1->b, 2 );

ok( $p1->{b} = 4, 4 );
ok( $p1->b, 4 );
ok( $p1->{b}, 4 );

ok( $p2->a, 2 );
ok( $p2->{a}, 2 );

ok( $p2->a(3), 3 );
ok( $p2->{a}, 3 );
ok( $p2->a, 3 );

ok( $p2->{a} = 4, 4 );
ok( $p2->a, 4 );
ok( $p2->{a}, 4 );

ok( $p2->b, 2 );
ok( $p2->{b}, 2 );

ok( $p2->b(3), 2 );
ok( $p2->{b}, 2 );
ok( $p2->b, 2 );

ok( $p2->{b} = 4, 4 );
ok( $p2->b, 4 );
ok( $p2->{b}, 4 );
