use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Index;

note("--- deep autovivification");

my @lenses = map { Data::Focus::Lens::HashArray::Index->new(index => $_) }
    "hoge", [1,2,4], ["a", "b", "c"], "foo";

is focus(undef)->get(@lenses), undef, "get()";
is_deeply [focus(undef)->list(@lenses)], [(undef) x 9], "list(). It creates focal points.";
is_deeply(
    focus(undef)->set(@lenses, "x"),
    +{
        hoge => [
            undef,
            {a => {foo => "x"}, b => {foo => "x"}, c => {foo => "x"}},
            {a => {foo => "x"}, b => {foo => "x"}, c => {foo => "x"}},
            undef,
            {a => {foo => "x"}, b => {foo => "x"}, c => {foo => "x"}},
        ]
    },
    "set()"
);

done_testing;
