use strict;
use warnings;
use lib 't/lib';

# use Module::Exists::Unexpected; # exists but will be ignored
my $dummys = 1;    # use Module::Exists::Unexpected; # exists but will be ignored

use Module::Exists;      # exists in t/lib
use Acme::BadExample;    # does not exist anywhere

