use warnings;
use strict;

use Test::More;

plan tests => 7;

use Alias::Any;

alias my $x = 1;
is $x, 1 => 'alias works';

{
    alias my $z = 9;
    is $z, 9 => 'nested alias works';
    ok !eval { $z++ } => 'really aliased to constant';

    no Alias::Any;

    no warnings 'redefine';
    sub alias {
        is shift, 2 => 'Non-keyword alias sub';
        pass '...works as expected'; }

    eval {
        alias my $y = 2;
        ok eval { $y++ } => 'not aliased to constant';
        1;
    }
    or do {
        like $@, qr/\AUndefined subroutine &Data::Alias::alias called/
                       => 'Right error message';
        ok $^V < 5.022 => '...fails as expected';
        pass              '...so works as expected';
    }
}

use Alias::Any;

alias my $q = 42;
is $q, 42 => 'alias works again';

done_testing();

