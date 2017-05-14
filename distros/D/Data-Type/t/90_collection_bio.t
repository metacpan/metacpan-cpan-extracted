use Test;
BEGIN { plan tests => 4; $| = 0 }

use strict; use warnings;

use Data::Type qw(:all +Bio);
use IO::Extended qw(:all);

	try
	{
		print "#DNA testing..\n";

			valid 'ATGCAAAT', BIO::DNA();
				
		print "#RNA testing..\n";

			valid 'AUGGGAAAU', BIO::RNA();
		
		print "#CODON testing..\n";

			valid 'ATG', BIO::CODON();
		
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
		print "#DNA testing..\n";

			valid 'ZZZZZATGCAAAT', BIO::DNA();
		
		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

	try
	{
		print "#RNA testing..\n";

			valid 'ZZZZZZAUGGGAAAU', BIO::RNA();
		
		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

	try
	{
		print "#CODON testing..\n";

			valid 'ZZZATG', BIO::CODON();
		
		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

