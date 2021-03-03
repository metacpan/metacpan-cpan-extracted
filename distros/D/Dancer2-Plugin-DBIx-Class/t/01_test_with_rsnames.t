use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;
use TestApp;

plan tests => 2;

my $test = Plack::Test->create( TestApp->to_app );
my $res;

subtest 'Check core keywords' => sub {
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

subtest 'Check ResultSetNames' => sub {
    plan tests => 2;

    $res = $test->request( GET '/test_humans' );
    is_deeply(
        decode_json( $res->content ),
        [qw(id name)], 'Plural term returns resultset'
    );

    $res = $test->request( GET '/test_human' );
    is_deeply(
        decode_json( $res->content ),
        { id => 1, name => 'Ruth Holloway' }, 'Singular term does a find()'
    );
};
