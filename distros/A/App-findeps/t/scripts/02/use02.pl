use strict;
use warnings;

use lib 't/lib';

# use Module::Exists::Unexpected qw(Acme::BadExample); # exists but will be ignored
my $dummys = 1;  # use Module::Exists::Unexpected qw(Acme::BadExample); # exists but will be ignored

use Module::Exists qw(dummy is_dummy);        # exists in t/lib
use Acme::BadExample qw(Acme::BadExample);    # does not exist anywhere

