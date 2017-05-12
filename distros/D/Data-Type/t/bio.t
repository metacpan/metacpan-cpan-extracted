use Test;
BEGIN { plan tests => 4; $| = 0 }

use strict; use warnings;

use Data::Type qw(:all);
use Error qw(:try);
use IO::Extended qw(:all);

	try
	{
		print "#DNA testing..\n";

			verify 'ATGCAAAT', BIO::DNA();
				
		print "#RNA testing..\n";

			verify 'AUGGGAAAU', BIO::RNA();
		
		print "#CODON testing..\n";

			verify 'ATG', BIO::CODON();
		
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
		print "#DNA testing..\n";

			verify 'ZZZZZATGCAAAT', BIO::DNA();
		
		ok(0);
	}
	catch Type::Exception with
	{
		ok(1);
	};

	try
	{
		print "#RNA testing..\n";

			verify 'ZZZZZZAUGGGAAAU', BIO::RNA();
		
		ok(0);
	}
	catch Type::Exception with
	{
		ok(1);
	};

	try
	{
		print "#CODON testing..\n";

			verify 'ZZZATG', BIO::CODON();
		
		ok(0);
	}
	catch Type::Exception with
	{
		ok(1);
	};

