#!perl

use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More;
use Test::Requires {'PPI::XS' => 0.902};
ok($PPI::XS::VERSION == 0.902, 'PPI::XS is loaded');


done_testing();

__END__
