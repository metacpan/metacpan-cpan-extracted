#!perl -w

use strict;
use Test::More;

use Acme::Hidek;
use Time::Piece;

my $hidek = Acme::Hidek->new();

cmp_ok $hidek->age,  '>=', 39;
cmp_ok $hidek->agef, '>',  39;

is $hidek->birthdate->year,  1970;
is $hidek->birthdate->mon,      9;
is $hidek->birthdate->mday,     2;

eval { $hidek->is_birthday };
ok(!$@);

{
    close STDOUT;
    open STDOUT, '>', \my $buff;
    $hidek->we_love_hidek();
    close STDOUT;

    is $buff, "We love hidek!\n" x ($hidek->age * 100);
}

done_testing;
