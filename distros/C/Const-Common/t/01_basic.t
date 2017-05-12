use strict;
use warnings;
use utf8;
use Test::More 0.98;
use t::Const;

is( t::Const->FIRST,  1);
is SECOND, 2;
is MONTH->{JAN}, 1;
is( t::Const->const('FIRST'), 1 );
is_deeply [t::Const->constant_names], [qw/FIRST MONTH SECOND THIRD/];

eval {
    MONTH->{JAN} = 10;
};
like $@, qr/Modification of a read-only value attempted/;

done_testing;
