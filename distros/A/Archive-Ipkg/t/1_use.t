# Test 1: use

use Test::More tests => 1;

BEGIN { use_ok('Archive::Ipkg') };

diag("Testing Archive::Ipkg $Archive::Ipkg::VERSION");
