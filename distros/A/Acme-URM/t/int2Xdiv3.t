# f(x) = [2x / 3]
use Test;
BEGIN { plan tests => 8 }
use Acme::URM;

my $rm	= Acme::URM->new();
$rm->program(
			# *2
			 'T(0,1)',
			 'J(1,2,5)',
			 'S(0)',
			 'S(2)',
			 'J(0,0,1)',
			# int div
			 'Z(1)',
			 'Z(2)',
			 'S(3)',
			 'S(4)',
			 'S(4)',
			 'J(0,2,25)',
			 'J(0,3,25)',
			 'J(0,4,25)',
			 'J(0,1,26)',
			 'S(1)',
			 'S(2)',
			 'S(2)',
			 'S(2)',
			 'S(3)',
			 'S(3)',
			 'S(3)',
			 'S(4)',
			 'S(4)',
			 'S(4)',
			 'J(0,0,10)',
			 'T(1,0)',
			 'J(0,0,'.Acme::URM::LAST.')',
			 'J(0,0,'.Acme::URM::THIS.')',
			 );

$rm->max_steps( 0xFF );
$rm->clear_registers();	$rm->register( 0, 0 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 1 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 2 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 3 );
ok( $rm->run() == 2 );
$rm->clear_registers();	$rm->register( 0, 4 );
ok( $rm->run() == 2 );
$rm->clear_registers();	$rm->register( 0, 5 );
ok( $rm->run() == 3 );
$rm->clear_registers();	$rm->register( 0, 12 );
ok( $rm->run() == 8 );
$rm->clear_registers();	$rm->register( 0, 23 );
ok( $rm->run() != 14 );
