use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::All;
use lib "t";
use testlib::Identity qw(identical);

sub create_target {
    return +{
        foo => [
            20, 30,
            {hoge => "HOGE"},
        ],
        bar => "buzz",
    };
}

{
    my $lens = Data::Focus->coerce_to_lens("bar");
    isa_ok $lens, "Data::Focus::Lens";
    isa_ok $lens, "Data::Focus::Lens::Dynamic";
    is focus(create_target())->get($lens), "buzz", "coerce_to_lens() creates a valid lens";
}

{
    my $all_lens = Data::Focus::Lens::HashArray::All->new;
    my $got = Data::Focus->coerce_to_lens($all_lens);
    identical $got, $all_lens, "coerce_to_lens(\$lens) returns \$lens itself if it's already a Lens";
}

is focus(create_target(), "foo", 2, "hoge")->get, "HOGE", "focus() lens coerce";
is(
    Data::Focus->new(target => create_target(), lens => "bar")->get,
    "buzz",
    "new() single lens coerce"
);
is focus(create_target)->into("foo", 1)->get, 30, "into() lens coerce";
is focus(create_target)->get("foo", 2, "hoge"), "HOGE", "get() lens coerce";
is_deeply [focus(create_target)->list("foo", [0,1])], [20, 30], "list() lens coerce";

is_deeply(
    focus(create_target)->set("foo", 0 => "quux"),
    +{ foo => ["quux", 30, {hoge => "HOGE"}], bar => "buzz" },
    "set() lens coerce"
);

is_deeply(
    focus(create_target)->over("foo", [0,1] => sub { 3 * $_[0] }),
    +{ foo => [60, 90, {hoge => "HOGE"}], bar => "buzz" },
    "over() lens coerce"
);

done_testing;
