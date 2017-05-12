use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Fatal;
use Data::Focus qw(focus);
use Data::Focus::Lens::Accessor;
use lib "t";
use testlib::AccessorSample;
use testlib::Identity qw(identical);

sub lens {
    my ($name) = @_;
    return Data::Focus::Lens::Accessor->new(method => $name);
}

{
    my $target = testlib::AccessorSample->new;
    is focus($target)->get(lens("foo")), undef;
    my $ret = focus($target)->set(lens("foo"), "FOO");
    isa_ok $ret, "testlib::AccessorSample";
    identical $ret, $target, "set() returns the identical target";
    is $target->foo, "FOO";
    is focus($target)->get(lens("foo")), "FOO";
}

{
    my $target = testlib::AccessorSample->new;
    is_deeply [$target->list], [], "at first, 'list' field returns an empty list";
    $target->list(1,2,3);
    is_deeply [$target->list], [1,2,3], "list returning method ok";
    is focus($target)->get(lens("list")), 1, "get(): accessor method is accessed in scalar context";
    is_deeply [focus($target)->list(lens("list"))], [1], "list(): accessor method is accessed in scalar context as well";
    
    my $ret = focus($target)->over(lens("list"), sub { $_[0] * 100 });
    identical $ret, $target, "over() returns the identical target";
    is_deeply [focus($target)->list(lens("list"))], [100], "list(): still accessed in scalar context";
    is_deeply [$target->list], [100], "list field is actually crushed into a single value by over()";
}

{
    my $target = testlib::AccessorSample->new;
    like exception { focus($target)->get(lens("bomb")) }, qr{boom}, "exception from the accessor method propagates.";
}

done_testing;
