use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;
use TestApp2;

plan tests => 1;

my $test = Plack::Test->create( TestApp2->to_app );
my $res;

subtest 'Check core keywords without ResultSetNames plugin' => sub {
    plan tests => 4;

    $res = $test->request( GET '/test_rs' );
    is_deeply( decode_json( $res->content ), [qw(id name)], 'rs' );

    $res = $test->request( GET '/test_rset' );
    is_deeply( decode_json( $res->content ), [qw(id name)], 'rset' );

    $res = $test->request( GET '/test_resultset' );
    is_deeply( decode_json( $res->content ), [qw(id name)], 'resultset' );

    $res = $test->request( GET '/test_schema' );
    is_deeply( decode_json( $res->content ), [qw(id name)], 'schema' );
};
