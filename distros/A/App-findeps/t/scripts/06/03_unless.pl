use strict;
use warnings;

use lib 't/lib';

unless (0) { require Module::Exists }                # ignored by parser
unless (1) { require Module::Exists::Unexpected }    # ignored

require Acme::BadExample;                            # does not exist anywhere

