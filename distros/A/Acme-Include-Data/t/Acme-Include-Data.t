# This is a test for module Acme::Include::Data.

use warnings;
use strict;
use Test::More;
use Acme::Include::Data 'yes_it_works';

is (yes_it_works (), "This is a data file.\n");

done_testing ();
# Local variables:
# mode: perl
# End:
