use strict;
use warnings;
use Test::More 0.88;

use B::Hooks::EndOfScope;

plan skip_all => 'Skiping XS test in PP mode'
  unless $INC{'B/Hooks/EndOfScope/XS.pm'};

eval q[
    sub foo {
        BEGIN {
            on_scope_end { die 'bar' };
        }
    }
];

like($@, qr/^bar/);

pass('no segfault');

done_testing;
