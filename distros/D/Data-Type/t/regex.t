use Test;
BEGIN { plan tests => 2 }

use Data::Type qw(:all);
use Error qw(:try);

		# Regexp::Common
		
	try
	{
			# QUOTED

		verify( '"me"' , QUOTED );

			# URI

		verify( 'http://www.perl.org' , URI );

		verify( 'http://www.cpan.org' , URI('http') );

		verify( 'https://www.cpan.org' , URI('https') );

		verify( 'ftp://www.cpan.org' , URI('ftp') );

		verify( 'axkit://www.axkit.org' , URI('axkit') );

		verify( '62.01.01.20' , IP( 'V4' ) );

		ok(1);
	}
	catch Type::Exception with
	{
		ok(0);
	};


		# Custom own Regex types

	try
	{
		verify( '80', PORT() );

		verify( 'www.cpan.org', DOMAIN() );

		ok(1);
	}
	catch Type::Exception with
	{
		ok(0);
	};
