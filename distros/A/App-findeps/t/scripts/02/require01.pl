use strict;
use warnings;

use lib 't/lib';

require Module::Exists;    # exists in t/lib

# require Module::Exists::Unexpected; # exists but the comennted will be ignored

require Acme::BadExample;    # does not exist anywhere

