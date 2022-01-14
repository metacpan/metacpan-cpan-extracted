use strict;
use warnings;

use lib 't/lib';

# eval { use Module::Exists::Unexpected; return Module::Exists::Unexpected->new(); }; # will be ignored
my $dummy
    ; # eval { use Module::Exists::Unexpected; return Module::Exists::Unexpected->new(); }; # will be ignored
$dummy = eval "use Module::Exists::Unexpected; return Module::Exists::Unexpected->new();";

# will be ignored

require Acme::BadExample;    # does not exist anywhere
