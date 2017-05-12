# f(x,y,z) = x + y + z
use Test;
BEGIN { plan tests => 9 }
use Acme::URM;

my $rm	= Acme::URM->new();
$rm->program(
			 'J(4,1,4)',
			 'S(0)',
			 'S(4)',
			 'J(0,0,0)',
			 'Z(4)',
			 'J(4,2,'.Acme::URM::LAST.')',
			 'S(0)',
			 'S(4)',
			 'J(0,0,5)',
			 );

$rm->clear_registers();	$rm->register( 0, 0, 0, 0 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 0, 0, 1 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 0, 1, 0 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 1, 0, 0 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 1, 0, 1 );
ok( $rm->run() == 2 );
$rm->clear_registers();	$rm->register( 0, 1, 1, 0 );
ok( $rm->run() == 2 );
$rm->clear_registers();	$rm->register( 0, 0, 1, 1 );
ok( $rm->run() == 2 );
$rm->clear_registers();	$rm->register( 0, 12, 23, 37 );
ok( $rm->run() == 72 );
$rm->clear_registers();	$rm->register( 0, 12, 23, 37 );
ok( $rm->run() != 22 );
