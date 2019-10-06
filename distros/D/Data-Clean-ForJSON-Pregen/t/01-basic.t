#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Data::Clean::ForJSON::Pregen qw(clean_for_json_in_place clone_and_clean_for_json);
use Scalar::Util qw(blessed);

unless (defined &Data::Clean::ForJSON::Pregen::clean_for_json_in_place) {
    plan skip_all => 'clean_for_json_in_place() not yet generated';
}

my $data;
my $cdata;

$cdata = clean_for_json_in_place({
    code   => sub{} ,
    #date   => DateTime->from_epoch(epoch=>1001),
    scalar => \1,
    version => version->parse('1.2'),
    obj    => bless({},"Foo"),
});
is_deeply($cdata, {
    code    => "CODE",
    #date    => 1001,
    scalar  => 1 ,
    version => '1.2',
    obj     => {},
}, "cleaning up");

{
    my $ref = [];
    $data  = {a=>$ref, b=>$ref};
    $cdata = clone_and_clean_for_json($data);
    #use Data::Dump; dd $data; dd $cdata;
    is_deeply($cdata, {a=>[], b=>[]}, "circular")
        or diag explain $cdata;
}

subtest "unbless does not modify original object when using clone_and_clean()" => sub {
    my $data = bless({},"Foo");
    my $cdata = clone_and_clean_for_json($data);
    is_deeply($cdata, {}, "cleaned data");
    is_deeply($data , bless({},"Foo"), "original data");
    # is_deeply doesn't differentiate blessed and unblessed, so we test it here
    ok(blessed($data), "original data blessed");
};

subtest "unbless modifies original object when using clean_in_place()" => sub {
    my $data = [bless({},"Foo")];
    clean_for_json_in_place($data);
    is_deeply($data , [{}], "original data modified");
    # is_deeply doesn't differentiate blessed and unblessed, so we test it here
    ok(!blessed($data), "original data not blessed");
};

done_testing;
