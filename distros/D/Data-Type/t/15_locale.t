use Test;
BEGIN { plan tests => 2; $| = 0 }

use strict; use warnings;

use Data::Type qw(:all);
use IO::Extended qw(:all);

	try
	{
		   print "#LANGCODE testing..\n";

		valid 'DE', STD::LANGCODE();

		   print "#LANGNAME testing..\n";

		valid 'German', STD::LANGNAME();

		   print "#COUNTRYNAME testing..\n";

      valid 'United Kingdom', STD::COUNTRYNAME();

		   print "#COUNTRCODE testing..\n";

      valid 'GB', STD::COUNTRYCODE();

		   print "#REGIONNAME testing..\n";

      valid 'New South Wales', STD::REGIONNAME( 'Australia' );

		   print "#REGIONCODE testing..\n";

      valid 'NSW', STD::REGIONCODE( 'Australia' );

         print "#All passed successfull\n";

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
		valid( 'bla' , STD::REF );

		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

