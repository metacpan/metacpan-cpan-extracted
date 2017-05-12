# f(x) = sg(x)
use Test;
BEGIN { plan tests => 5 }
use Acme::URM;

my $rm	= Acme::URM->new();
$rm->program(
			 'J(0,1,3)',
			 'Z(0)',
			 'S(0)',
			 );

$rm->clear_registers();	$rm->register( 0, 0 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 1 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 12 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 144 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 145 );
ok( $rm->run() != 0 );
