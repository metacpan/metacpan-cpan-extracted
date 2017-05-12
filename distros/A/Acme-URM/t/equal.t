# f(x,y) = 0 if x == y 
#          1 else
use Test;
BEGIN { plan tests => 6 }
use Acme::URM;

my $rm	= Acme::URM->new();
$rm->program(
			 'J(0,1,4)',
			 'Z(0)',
			 'S(0)',
			 'J(0,0,'.Acme::URM::LAST.')',
			 'Z(0)',
			 );

$rm->clear_registers();	$rm->register( 0, 0, 0 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 0, 1 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 1, 0 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 12, 12 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 12, 23 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 223, 23 );
ok( $rm->run() != 0 );
