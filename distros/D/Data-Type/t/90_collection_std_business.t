use Test;
BEGIN { plan tests => 1; $| = 0 }

use strict; use warnings;

use Data::Type qw(:all);
use IO::Extended qw(:all);

=head1

  CINS               - a CUSIP International Numbering System Number
  DE::BANKACCOUNT    - a german bank account number
  ISSN               - an International Standard Serial Number
  UPC                - standard (type-A) Universal Product Code

=cut

	try
	{
		print "#CINS testing..\n";

			valid 'A35231AH1', STD::CINS();

		print "#ISSN testing..\n";

			valid '14565935', STD::ISSN();

		print "#UPC testing..\n";

			valid '012345678905', STD::UPC();

		#print "#DE::BANKACCOUNT testing..\n";

		#	valid { BLZ => '12345678', KONTO => '1234567890' }, STD::DE::BANKACCOUNT();

		ok(1);
	}
	catch Data::Type::Exception with
	{
		ok(0);

		use Data::Dumper;

		print Dumper shift;
	};


