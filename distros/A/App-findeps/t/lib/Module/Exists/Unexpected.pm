package Module::Exists::Unexpected;

use strict;
use warnings;

use parent qw(Module::Exists);
use Acme::BadExample;    # must fail if this module was required or used

1;
