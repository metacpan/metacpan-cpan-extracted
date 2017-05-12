use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Index;
use lib "t";
use testlib::SampleObject;

note("immutable=1 AND allow_blessed=1");

{
    my $target = testlib::SampleObject->new;
    $target->set(hoge => "fuga");
    my $lens = Data::Focus::Lens::HashArray::Index->new(index => "foo", immutable => 1, allow_blessed => 1);
    my $result = focus($target)->set($lens, "bar");
    is_deeply $result, {hoge => "fuga", foo => "bar"}, "result data OK";
    is ref($result), "HASH", "result is a plain hash-ref";
    is $target->get("foo"), undef, "target is not modified";
}

done_testing;
