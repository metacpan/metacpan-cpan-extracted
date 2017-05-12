#!perl
use warnings;
use Test::Most;
use Test::Fatal;
use Data::Printer;
use HTTP::Request::Common;
use lib 't/lib';
use Catalyst::Test 'Test1';

my $foo_one = Test1->component('Test1::Foo::One');

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

# in the following two tests, we check that errors are *not* caught
# specially. Error handling is provided by a role that
# Test1::Base::Foo does not consume (see t/test2/run.t)

# silence the expected error messages if the user does not want to see
# them
Test1->log->disable('error') unless $ENV{TEST_VERBOSE};

subtest 'wrong url' => sub {
    my $res = request POST "/bad/url",
        'Content-type' => 'text/plain',
        'Content-length' => 6,
        Content => 'a body';

    ok(not($res->is_success), 'the request fails')
        or note p $res;
    is($res->code,500,'with 500');
};

done_testing();
