use strict;
use warnings;

use lib 't/lib';

# use parent qw(Acme::BadExample Module::Exists::Unexpected); # exists but will be ignored
my $dummys
    = 1;  # use parent qw(Acme::BadExample Module::Exists::Unexpected); # exists but will be ignored

use parent qw(Acme::BadExample Module::Exists);    # 'Acme::BadExample' does not exist anywhere

