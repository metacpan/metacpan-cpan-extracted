use strict;
use warnings;

use lib 't/lib';

# use autouse 'Module::Exists::Unexpected' => qw(dummy isdummy); # exists but will be ignored
my $dummys
    = 1
    ;  # use autouse 'Module::Exists::Unexpected' => qw(dummy isdummy); # exists but will be ignored

use autouse 'Module::Exists'   => qw(dummy is_dummy);   # exists in t/lib
use autouse 'Acme::BadExample' => qw(dummy is_dummy);   # 'Acme::BadExample' does not exist anywhere

require Acme::BadExample;

