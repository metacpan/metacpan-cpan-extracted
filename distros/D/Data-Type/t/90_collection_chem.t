use Test;
BEGIN { plan tests => 2; $| = 0 }

use strict; use warnings;

use Data::Type qw(:all +Chem);
use IO::Extended qw(:all);

	try
	{
		print "#Atom testing..\n";

			valid 'He', CHEM::ATOM();
				
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
		print "#Atom testing..\n";

			valid 'XX', CHEM::ATOM();
		
		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};
