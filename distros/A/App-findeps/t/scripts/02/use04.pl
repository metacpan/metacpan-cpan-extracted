use strict;
use warnings;

use lib 't/lib';

# use parent 'Module::Exists::Unexpected'; # exists but will be ignored
my $dummys = 1;    # use parent 'Module::Exists::Unexpected'; # exists but will be ignored

use parent 'Module::Exists';      # exists in t/lib
use parent 'Acme::BadExample';    # does not exist anywhere

