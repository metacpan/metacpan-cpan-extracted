# f(x) = x / 3
use Test;
BEGIN { plan tests => 7 }
use Acme::URM;

my $rm	= Acme::URM->new();
$rm->program(
			 'J(0,2,7)',
			 'J(0,1,9)',
			 'S(1)',
			 'S(2)',
			 'S(2)',
			 'S(2)',
			 'J(0,0,0)',
			 'T(1,0)',
			 'J(0,0,'.Acme::URM::LAST.')',
			 'J(0,0,'.Acme::URM::THIS.')',
			 );

$rm->max_steps( 0xFF );
$rm->clear_registers();	$rm->register( 0, 0 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 1 );
ok( $rm->run() == Acme::URM::MAX_STEPS );
$rm->clear_registers();	$rm->register( 0, 2 );
ok( $rm->run() == Acme::URM::MAX_STEPS );
$rm->clear_registers();	$rm->register( 0, 3 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 4 );
ok( $rm->run() == Acme::URM::MAX_STEPS );
$rm->clear_registers();	$rm->register( 0, 5 );
ok( $rm->run() == Acme::URM::MAX_STEPS );
$rm->clear_registers();	$rm->register( 0, 36 );
ok( $rm->run() == 12 );
