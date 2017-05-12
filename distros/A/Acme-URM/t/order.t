# f(x,y) = 0 if x <= y 
#          1 else
use Test;
BEGIN { plan tests => 9 }
use Acme::URM;

my $rm	= Acme::URM->new();
$rm->program(
			# adding arguments, summ in 0
			 'T(0,2)',	# prevent first argument while adding
			 'J(1,3,5)',
			 'S(0)',
			 'S(3)',
			 'J(0,0,1)',
			# grow one of elements while it achieve second or summ
			 'J(2,1,9)',
			 'J(2,0,11)',
			 'S(2)',
			 'J(0,0,5)',
			 'Z(0)',
			 'J(0,0,'.Acme::URM::LAST.')',
			 'Z(0)',
			 'S(0)',
			 'J(0,0,'.Acme::URM::LAST.')',
			 );

$rm->clear_registers();	$rm->register( 0, 0, 0 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 0, 1 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 1, 2 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 12, 23 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 1, 0 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 12, 0 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 23, 12 );
ok( $rm->run() == 1 );
$rm->clear_registers();	$rm->register( 0, 23, 12 );
ok( $rm->run() != 0 );
$rm->clear_registers();	$rm->register( 0, 23, 24 );
ok( $rm->run() != 1 );
