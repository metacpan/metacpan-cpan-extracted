#!perl
use warnings;
use Test::Most;
use Test::Fatal;
use Data::Printer;
use HTTP::Request::Common;
use lib 't/lib';
use Catalyst::Test 'Test2';

my $foo_one = Test2->component('Test2::Foo::One');

subtest 'correct message' => sub {
    my $res = request POST "/base_url/my_action",
        'Request-id' => 356,
        'Content-type' => 'text/plain',
        'Content-length' => 6,
        Content => 'a body';

    ok($res->is_success, 'the request works')
        or note p $res;

    cmp_deeply($foo_one->calls,
               [
                   [
                       all(isa('HTTP::Headers'),
                           methods([header => 'Request-id'] => 356),
                       ),
                       'a body',
                   ],
               ],
               'request received and action run')
        or note p $foo_one->calls;
};

subtest 'wrong type' => sub {
    my $res = request POST "/base_url/bad_action",
        'Content-type' => 'text/plain',
        'Content-length' => 6,
        Content => 'a body';

    ok(not($res->is_success), 'the request fails')
        or note p $res;
    is($res->code,404,'with 404');
};

done_testing();
