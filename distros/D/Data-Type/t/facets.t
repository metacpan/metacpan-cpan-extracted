use Test;
BEGIN { plan tests => 1; $| = 0 }

use strict; use warnings;

use Data::Type qw(:all);
use Error qw(:try);
use IO::Extended qw(:all);

	try
	{
		ok(1);
	}
	catch Type::Exception with
	{
		ok(0);
		
		use Data::Dumper;
		
		print Dumper shift;
	};
