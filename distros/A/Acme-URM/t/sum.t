# f(x,y) = x + y
use Test;
BEGIN { plan tests => 6 }
use Acme::URM;

my $rm	= Acme::URM->new();
$rm->program(
			 'J(2,1,4)',
			 'S(0)',
			 'S(2)',
			 'J(0,0,0)',
			 );

$rm->clear_registers();	$rm->register( 0, 1, 1 );
ok( $rm->run() == 2 );
$rm->clear_registers();	$rm->register( 0, 1, 1 );
ok( $rm->run() == 2 );
$rm->clear_registers();	$rm->register( 0, 2, 1 );
ok( $rm->run() == 3 );
$rm->clear_registers();	$rm->register( 0, 26, 0 );
ok( $rm->run() == 26 );
$rm->clear_registers();	$rm->register( 0, 0, 12 );
ok( $rm->run() == 12 );
$rm->clear_registers();	$rm->register( 0, 4, 13 );
ok( $rm->run() != 16 );
