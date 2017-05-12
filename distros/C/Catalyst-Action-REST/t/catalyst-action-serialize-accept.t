use strict;
use warnings;
use Test::More;
use FindBin;
use Test::Requires qw(YAML::Syck);

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/../lib", "$FindBin::Bin/broken");
use Test::Rest;
use Catalyst::Action::Serialize::YAML;

# Should use Data::Dumper, via YAML
my $t = Test::Rest->new('content_type' => 'text/x-yaml');

use_ok 'Catalyst::Test', 'Test::Catalyst::Action::REST';

# to avoid whatever serialization bugs YAML::Syck has,
# e.g. http://rt.cpan.org/Public/Bug/Display.html?id=46983,
# we won't hardcode the expected output
my $output_YAML = Catalyst::Action::Serialize::YAML->serialize({lou => 'is my cat'});

{
    my $req = $t->get(url => '/serialize/test');
    $req->remove_header('Content-Type');
    $req->header('Accept', 'text/x-yaml');
    my $res = request($req);
    SKIP: {
        skip "can't test text/x-yaml without YAML support",
        3 if (
                not $res->is_success and
                $res->content =~ m#Content-Type text/x-yaml is not supported#
             );
        ok( $res->is_success, 'GET the serialized request succeeded' );
        is( $res->content, $output_YAML, "Request returned proper data");
        is( $res->content_type, 'text/x-yaml', '... with expected content-type')

    };
}

SKIP: {
    eval 'use JSON 2.12;';
    skip "can't test application/json without JSON support", 3 if $@;
    my $json = JSON->new;
    my $at = Test::Rest->new('content_type' => 'text/doesnt-exist');
    my $req = $at->get(url => '/serialize/test');
    $req->header('Accept', 'application/json');
    my $res = request($req);
    ok( $res->is_success, 'GET the serialized request succeeded' );
    my $ret = $json->decode($res->content);
    is( $ret->{lou}, 'is my cat', "Request returned proper data");
    is( $res->content_type, 'application/json', 'Accept header used if content-type mapping not found')
};

# Make sure we don't get a bogus content-type when using the default
# serializer (https://rt.cpan.org/Ticket/Display.html?id=27949)
{
    my $req = $t->get(url => '/serialize/test');
    $req->remove_header('Content-Type');
    $req->header('Accept', '*/*');
    my $res = request($req);
    ok( $res->is_success, 'GET the serialized request succeeded' );
    is( $res->content, $output_YAML, "Request returned proper data");
    is( $res->content_type, 'text/x-yaml', '... with expected content-type')
}

# Make sure that when using content_type_stash_key, an invalid value in the stash gets ignored
{
    my $req = $t->get(url => '/serialize/test_second?serialize_content_type=nonesuch');
    $req->remove_header('Content-Type');
    $req->header('Accept', '*/*');
    my $res = request($req);
    ok( $res->is_success, 'GET the serialized request succeeded' );
    is( $res->content, $output_YAML, "Request returned proper data");
    is( $res->content_type, 'text/x-yaml', '... with expected content-type')
}

# Make sure that the default content type you specify really gets used.
{
    my $req = $t->get(url => '/override/test');
    $req->remove_header('Content-Type');
    my $res = request($req);
    ok( $res->is_success, 'GET the serialized request succeeded' );
    is( $res->content, "--- \nlou: is my cat\n", "Request returned proper data");
}

done_testing;

