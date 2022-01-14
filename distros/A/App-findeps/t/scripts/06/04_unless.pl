use strict;
use warnings;

use lib 't/lib';

require Module::Exists::Unexpected unless 0;    # ignored by parser
require Module::Exists             unless 1;    # ignored

require Acme::BadExample;                       # does not exist anywhere

