use Test;
BEGIN { plan tests => 3 }

use Data::Type qw(:all);

		# Regexp::Common
		
	try
	{
			# QUOTED

		valid( '"me"' , STD::QUOTED );

			# URI

		valid( 'http://www.perl.org' , STD::URI );

		valid( 'http://www.cpan.org' , STD::URI('http') );

		valid( 'https://www.cpan.org' , STD::URI('https') );

		valid( 'ftp://www.cpan.org' , STD::URI('ftp') );

		valid( 'axkit://www.axkit.org' , STD::URI('axkit') );

		valid( '62.01.01.20' , STD::IP( 'V4' ) );

		valid( '12345', STD::ZIP );

		ok(1);
	}
	catch Data::Type::Exception with
	{
		ok(0);
	};

	try
	{
		valid( 'nozipcode', STD::ZIP );

		ok(0);
	}
	catch Error with
	{
		ok(1);
	};


		# Custom own Regex types

	try
	{
		valid( '80', STD::PORT() );

		valid( 'www.cpan.org', STD::DOMAIN() );

		ok(1);
	}
	catch Data::Type::Exception with
	{
		ok(0);
	};
