use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok('Algorithm::IRCSRP2');
    use_ok('Algorithm::IRCSRP2::Alice');
    use_ok('Algorithm::IRCSRP2::Exchange');
    use_ok('Algorithm::IRCSRP2::Utils');
}
