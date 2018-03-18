use warnings;
use strict;

use Test::More;

plan tests => 6;

use Data::BLNS;

local $@;
ok !defined eval{ scalar get_naughty_strings(); }
    => 'Correctly died in scalar context';

like $@, qr/^Useless use of get_naughty_strings\(\) in a non-list context/
    => '...with correct error message';

local $@;
ok !defined eval{ ; get_naughty_strings(); }
    => 'Correctly died in void context';

like $@, qr/^Useless use of get_naughty_strings\(\) in a non-list context/
    => '...with correct error message';

local $@;
ok defined eval{ ()= get_naughty_strings(); }
    => 'Correctly returned in list context';

ok ! $@
    => '...with correct lcak of error message';


done_testing();

