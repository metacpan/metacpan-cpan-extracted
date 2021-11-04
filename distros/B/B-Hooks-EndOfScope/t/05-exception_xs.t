use strict;
use warnings;
use Test::More 0.88;
use lib 't/lib';

use B::Hooks::EndOfScope;
BEGIN {
  plan skip_all => 'Skiping XS test in PP mode'
    unless $INC{'B/Hooks/EndOfScope/XS.pm'};
}

my $beg_err;
BEGIN {
  on_scope_end {
    eval { require ExploderLoader };
    $beg_err = $@;
  }
}

like( $beg_err, qr/^crap/ );

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
