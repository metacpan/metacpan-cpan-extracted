use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/mock_libs";

use Test::More tests => 2;
BEGIN { use_ok('Apache2::AuthCookieDBI'); }
BEGIN { use_ok('Apache2_4::AuthCookieDBI'); }
