use strict;
use warnings;

use lib 't/lib';

require If::AfterRequire if 0;    # ignored
require If::AfterRequire if 1;    # ignored by parser

require Dummy;                    # does not exist anywhere

exit;
