use Test;
BEGIN { plan tests => 2 }

use Data::Type qw(:all);

	try
	{
		valid( 'muenalan@cpan.org' , STD::EMAIL );
		
		ok(1);
	}
	catch Data::Type::Exception with
	{
		ok(0);
	};

	try
	{
		valid( 'muenalan<at>cpan.org' , STD::EMAIL );
		
		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

