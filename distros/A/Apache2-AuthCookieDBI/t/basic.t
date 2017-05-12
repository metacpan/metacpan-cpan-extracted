# $Id: basic.t,v 1.1 2007/02/03 21:57:48 matisse Exp $
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/mock_libs";

use Test::More tests => 1;
use_ok('Apache2::AuthCookieDBI');