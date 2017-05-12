# f(x,y) = min(x,y)
use Test;
BEGIN { plan tests => 6 }
use Acme::URM;

my $rm	= Acme::URM->new();
$rm->program(
			 'T(0,2)',
			 'T(1,3)',
			 'J(3,4,6)',
			 'S(2)',
			 'S(4)',
			 'J(0,0,2)',
			 'T(0,3)',
			 'J(3,1,'.Acme::URM::LAST.')',
			 'J(3,2,11)',
			 'S(3)',
			 'J(0,0,7)',
			 'T(1,0)',
			 );

$rm->clear_registers();	$rm->register( 0, 0, 0 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 0, 1 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 1, 0 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 1, 7 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 12, 12 );
ok( $rm->run() == 12 );
$rm->clear_registers();	$rm->register( 0, 9, 7 );
ok( $rm->run() != 8 );
