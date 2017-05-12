use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Index;

{
    note("--- synopsis");

    my $target = [
        "hoge",
        {
            foo => "bar",
            quux => ["x", "y", "z"]
        }
    ];

    my $z = focus($target)->get(1, "quux", 2);
    my @xyz = focus($target)->list(1, "quux", [0,1,2]);
    is $z, "z";
    is_deeply \@xyz, [qw(x y z)];

    focus($target)->set(1, "foo",  10);
    focus($target)->set(1, "quux", 11);
    is_deeply $target, ["hoge", {foo => 10, quux => 11}];

    focus($target)->over(1, ["foo", "quux"], sub { $_[0] * $_[0] });
    is_deeply $target, ["hoge", {foo => 100, quux => 121}];
}

{
    note("--- example without lens");
    my $target = ["hoge", { foo => "bar" }];
    my $part = $target->[1]{foo};
    $target->[1]{foo} = "buzz";

    is $part, "bar";
    is_deeply $target, ["hoge", {foo => "buzz"}];
}

{
    note("--- example with lens");
    my $target = ["hoge", { foo => "bar" }];
    my $lens_1   = Data::Focus::Lens::HashArray::Index->new(index => 1);
    my $lens_foo = Data::Focus::Lens::HashArray::Index->new(index => "foo");
    my $part = focus($target)->get($lens_1, $lens_foo);
    focus($target)->set($lens_1, $lens_foo, "buzz");

    is $part, "bar";
    is_deeply $target, ["hoge", {foo => "buzz"}];
}

{
    note("--- example with coerced lens");
    
    my $target = ["hoge", { foo => "bar" }];
    my $part = focus($target)->get(1, "foo");
    focus($target)->set(1, foo => "buzz");

    is $part, "bar";
    is_deeply $target, ["hoge", {foo => "buzz"}];
}

{
    note("--- example slices");
    my $target = ["a", "b", "c"];
    my @abc = focus($target)->list([0, 1, 2]);

    is_deeply \@abc, ["a", "b", "c"];
}

{
    note("--- composite example");
    my $target = ["hoge", { foo => "bar" }];
    my $lens_1   = Data::Focus::Lens::HashArray::Index->new(index => 1);
    my $lens_foo = Data::Focus::Lens::HashArray::Index->new(index => "foo");

    my $composite = $lens_1 . $lens_foo;

    my $part = focus($target)->get($composite);
    focus($target)->set($composite, "buzz");

    is $part, "bar";
    is_deeply $target, ["hoge", {foo => "buzz"}];
}

{
    note("--- into()");
    my $focused = focus({foo => {bar => "buzz"}});
    
    my $result1 = $focused->into("foo", "bar")->get();
    my $result2 = $focused->into("foo")->get("bar");
    my $result3 = $focused->get("foo", "bar");

    is $result1, "buzz";
    is $result2, "buzz";
    is $result3, "buzz";
}

done_testing;
