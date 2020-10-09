use strict;
use warnings;

use lib 't/lib';

require If::AfterRequire unless 0;    # ignored
require If::AfterRequire unless 1;    # ignored by parser

require Dummy;                        # does not exist anywhere

exit;
