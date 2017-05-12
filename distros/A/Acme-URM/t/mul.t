# *(x,y) = x*y
use Test;
BEGIN { plan tests => 8 }
use Acme::URM;

my $rm	= Acme::URM->new();
$rm->program(
			 'J(0,3,'.Acme::URM::LAST.')',	# if 0 == x
			 'T(0,2)',						# copy/preserve first argument
			 'J(1,3,11)',					# if 0 == y
			 'S(3)',						# set up counter to 1, since we have one copy of x already
			 'J(1,3,'.Acme::URM::LAST.')',	# loop for number of adding copies
			 'Z(4)',
			 'S(3)',						# increment counter
			 'J(2,4,4)',					# loop for adding another copy of x to result
			 'S(0)',
			 'S(4)',
			 'J(0,0,7)',
			 'Z(0)',
			 );

$rm->clear_registers();	$rm->register( 0, 0, 0 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 0, 1 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 1, 0 );
ok( $rm->run() == 0 );
$rm->clear_registers();	$rm->register( 0, 1, 7 );
ok( $rm->run() == 7 );
$rm->clear_registers();	$rm->register( 0, 12, 1 );
ok( $rm->run() == 12 );
$rm->clear_registers();	$rm->register( 0, 12, 13 );
ok( $rm->run() == 156 );
$rm->clear_registers();	$rm->register( 0, 9, 7 );
ok( $rm->run() == 63 );
$rm->clear_registers();	$rm->register( 0, 9, 7 );
ok( $rm->run() != 62 );
