# f(x) = 5
use Test;
BEGIN { plan tests => 4 }
use Acme::URM;

my $rm	= Acme::URM->new();
$rm->program(
			 'Z(0)',
			 'S(0)',
			 'S(0)',
			 'S(0)',
			 'S(0)',
			 'S(0)',
			 );

$rm->clear_registers();	$rm->register( 0, 0 );
ok( $rm->run() == 5 );
$rm->clear_registers();	$rm->register( 0, 1 );
ok( $rm->run() == 5 );
$rm->clear_registers();	$rm->register( 0, 12 );
ok( $rm->run() == 5 );
$rm->clear_registers();	$rm->register( 0, 144 );
ok( $rm->run() == 5 );
