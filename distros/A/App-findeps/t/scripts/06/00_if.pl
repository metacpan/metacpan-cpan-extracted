use strict;
use warnings;

use lib 't/lib';

if (0) { require Module::Exists::Unexpected }    # they can't be ignored so parsed
if (1) { require Module::Exists }                # must be warned by this module

delete $INC{'Module/Exists/Unexpected.pm'};
delete $INC{'Module/Exists.pm'};

unless (1) { require Module::Exists::Unexpected }
unless (0) { require Module::Exists }

require Acme::BadExample;                        # does not exist anywhere

