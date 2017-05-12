# change 'tests => 1' to 'tests => last_test_to_print';

BEGIN
{
	$| = 1;
	
	use Test::More qw(no_plan);

	#plan tests => 2 + 1; 

	use_ok( 'Class::MVC' );
}

ok( 1 );
