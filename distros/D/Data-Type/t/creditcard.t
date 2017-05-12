use Test;
BEGIN { plan tests => 3; $| = 0 }

use strict; use warnings;

use Data::Type qw(:all);
use Error qw(:try);
use IO::Extended qw(:all);

	try
	{
		verify( '5276 4400 6542 1319', CREDITCARD( 'MASTERCARD' ) );

		verify( '5276 4400 6542 1319', CREDITCARD( 'MASTERCARD', 'VISA' ) );

		ok(1);
	}
	catch Type::Exception with
	{
		ok(0);
		
		use Data::Dumper;
		
		print Dumper shift;
	};

	try
	{
		verify( '5276 4400 6542 1319', CREDITCARD( 'VISA', 'AMEX' ) );

		ok(0);
	}
	catch Type::Exception with
	{
		ok(1);
	};

	try
	{
		verify( '5276 4400 6542 1319', CREDITCARD( 'VISA' ) );

		ok(0);
	}
	catch Type::Exception with
	{
		ok(1);
	};

