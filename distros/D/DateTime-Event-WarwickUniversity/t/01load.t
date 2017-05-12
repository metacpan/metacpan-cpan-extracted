#
# Check the module loads
#

use Test::More tests => 1;
use blib;
BEGIN { use_ok('DateTime::Event::WarwickUniversity') };

