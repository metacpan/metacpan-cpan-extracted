#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Complete::Util qw(modify_answer);

is_deeply(
    modify_answer(answer=>[qw/a b ce DE/], prefix=>"<", suffix=>">"),
    [qw/<a> <b> <ce> <DE>/],
);

is_deeply(
    modify_answer(answer=>{foo=>1, words=>[qw/a b ce DE/]}, prefix=>"<", suffix=>">"),
    {foo=>1, words=>[qw/<a> <b> <ce> <DE>/]},
);

is_deeply(
    modify_answer(answer=>[{word=>"a",summary=>"foo"}], prefix=>"<", suffix=>">"),
    [{word=>"<a>",summary=>"foo"}],
);

done_testing;
