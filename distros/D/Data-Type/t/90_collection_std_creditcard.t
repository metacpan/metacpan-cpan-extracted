use Test;
BEGIN { plan tests => 3; $| = 0 }

use strict; use warnings;

use Data::Type qw(:all);
use IO::Extended qw(:all);

	try
	{
		valid( '5276 4400 6542 1319', STD::CREDITCARD( 'MASTERCARD' ) );

		valid( '5276 4400 6542 1319', STD::CREDITCARD( 'MASTERCARD', 'VISA' ) );

		ok(1);
	}
	catch Data::Type::Exception with
	{
		ok(0);
		
		use Data::Dumper;
		
		print Dumper shift;
	};

	try
	{
		valid( '5276 4400 6542 1319', STD::CREDITCARD( 'VISA', 'AMEX' ) );

		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

	try
	{
		valid( '5276 4400 6542 1319', STD::CREDITCARD( 'VISA' ) );

		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

