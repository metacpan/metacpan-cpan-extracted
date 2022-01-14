use strict;
use warnings;

use lib 't/lib';

# eval { require Module::Exists::Unexpected }; # will be ignored
my $dummys = 1;    # eval { require Module::Exists::Unexpected }; # will be ignored

eval { require Module::Exists } or die $@;    # exists in t/lib

require Acme::BadExample;                     # does not exist anywhere

0;
