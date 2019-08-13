#!perl

use 5.010;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;
use Test::Needs;

use Data::Clean::ForJSON qw(clean_json_in_place clone_and_clean_json);
use DateTime;
use JSON::PP;
use Scalar::Util qw(blessed);

my $c = Data::Clean::ForJSON->get_cleanser;
my $data;
my $cdata;

$cdata = $c->clean_in_place({
    code   => sub{} ,
    date   => DateTime->from_epoch(epoch=>1001),
    scalar => \1,
    version => version->parse('1.2'),
    obj    => bless({},"Foo"),
});
is_deeply($cdata, {
    code    => "CODE",
    date    => 1001,
    scalar  => 1 ,
    version => '1.2',
    obj     => {},
}, "cleaning up");

{
    my $ref = [];
    $data  = {a=>$ref, b=>$ref};
    $cdata = $c->clone_and_clean($data);
    #use Data::Dump; dd $data; dd $cdata;
    is_deeply($cdata, {a=>[], b=>[]}, "circular")
        or diag explain $cdata;
}

subtest "unbless does not modify original object when using clone_and_clean()" => sub {
    my $data = bless({},"Foo");
    my $cdata = $c->clone_and_clean($data);
    is_deeply($cdata, {}, "cleaned data");
    is_deeply($data , bless({},"Foo"), "original data");
    # is_deeply doesn't differentiate blessed and unblessed, so we test it here
    ok(blessed($data), "original data blessed");
};

subtest "unbless modifies original object when using clean_in_place()" => sub {
    my $data = [bless({},"Foo")];
    $c->clean_in_place($data);
    is_deeply($data , [{}], "original data modified");
    # is_deeply doesn't differentiate blessed and unblessed, so we test it here
    ok(!blessed($data), "original data not blessed");
};

# XXX test: re

subtest "non-oo functions" => sub {
    my $data = [sub {}];

    # Sereal::Dclone doesn't like this
    #my $cleaned = clone_and_clean_json($data);
    #is_deeply($cleaned, ["CODE"]);

    clean_json_in_place($data);
    is_deeply($data, ["CODE"]);
};

subtest "Clone::PP" => sub {
    my $c = Data::Clean::ForJSON->new(
        '!clone_func' => 'Clone::PP::clone',
    );
    my $json = JSON::PP::decode_json('[true, false]');
    is_deeply($c->clone_and_clean($json), [1,0]);
    is_deeply($c->clean_in_place($json), [1,0]);
};

subtest "Clone" => sub {
    test_needs "Clone";

    my $c = Data::Clean::ForJSON->new(
        '!clone_func' => 'Clone::clone',
    );
    my $json = JSON::PP::decode_json('[true, false]');
    is_deeply($c->clone_and_clean($json), [1,0]);
    is_deeply($c->clean_in_place($json), [1,0]);
};

subtest "Data::Clone" => sub {
    plan skip_all => "Data::Clone currently cannot clone JSON::PP::Boolean objects";
    test_needs "Data::Clone";

    my $c = Data::Clean::ForJSON->new(
        '!clone_func' => 'Data::Clone::clone',
    );
    my $json = JSON::PP::decode_json('[true, false]');
    is_deeply($c->clone_and_clean($json), [1,0]);
    is_deeply($c->clean_in_place($json), [1,0]);
};

subtest "Sereal::Dclone" => sub {
    test_needs "Sereal::Dclone";

    my $c = Data::Clean::ForJSON->new(
        '!clone_func' => 'Sereal::Dclone::dclone',
    );
    my $json = JSON::PP::decode_json('[true, false]');
    is_deeply($c->clone_and_clean($json), [1,0]);
    is_deeply($c->clean_in_place($json), [1,0]);
};

DONE_TESTING:
done_testing;
