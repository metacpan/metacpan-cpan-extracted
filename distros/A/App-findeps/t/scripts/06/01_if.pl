use strict;
use warnings;

use lib 't/lib';

require Module::Exists::Unexpected if 0;    # ignored
require Module::Exists             if 1;    # ignored by parser
require Acme::BadExample;                   # does not exist anywhere

