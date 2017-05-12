use Test;
BEGIN { plan tests => 2 }

use Data::Type qw(:all);
use Error qw(:try);

	try
	{
		verify( 'muenalan@cpan.org' , EMAIL );
		
		ok(1);
	}
	catch Type::Exception with
	{
		ok(0);
	};

	try
	{
		verify( 'muenalan<at>cpan.org' , EMAIL );
		
		ok(0);
	}
	catch Type::Exception with
	{
		ok(1);
	};

