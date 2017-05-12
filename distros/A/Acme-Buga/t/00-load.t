use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use_ok 'Acme::Buga';
    require_ok 'Acme::Buga';
}

done_testing;
