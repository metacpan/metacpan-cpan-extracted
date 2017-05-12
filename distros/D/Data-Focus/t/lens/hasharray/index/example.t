use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Index;


sub lens { Data::Focus::Lens::HashArray::Index->new(index => $_[0]) }

my $target = {
    foo => "bar",
    hoge => [ "a", "b", "c" ]
};

is_deeply focus($target)->get(lens("foo")), "bar";
is_deeply focus($target)->get(lens("hoge")), ["a", "b", "c"];
is_deeply focus($target)->get(lens("hoge"), lens(1)), "b";

is_deeply [focus($target)->list(lens("hoge"), lens([0, 2]))], ["a", "c"];

done_testing;
