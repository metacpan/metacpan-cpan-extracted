use strict;
use Test::More 0.98 tests => 2;

use lib 'lib';

use_ok qw(Business::Tax::Withholding::JP);
my $tax = new_ok('Business::Tax::Withholding::JP', [ price => 10000 ]);

done_testing;
