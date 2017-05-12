#!perl
use warnings;
use Test::Most;
use Test::Fatal;
use Data::Printer;
use HTTP::Request::Common;
use lib 't/lib';

BEGIN { $ENV{CATALYST_CONFIG} = 't/lib/test1.conf' }
use Catalyst::Test 'Test1';

# let's get all URLs from the controllers, to make sure they got
# created properly, 2 controllers for a single Foo, because of the
# configuration
my @destinations =
    map { '/'.$_ }
    map { Test1->controller($_)->action_namespace }
    Test1->controllers;

my $foo_one = Test1->component('Test1::Foo::One');
my $foo_two = Test1->component('Test1::Foo::Two');

sub run_test {
    my ($foo,$url,$action) = @_;

    $foo->calls([]);

    my $res = request POST "$url/$action",
        'My-Header' => 'my value',
        'Content-type' => 'text/plain',
        'Content-length' => 6,
        Content => 'a body';

    ok($res->is_success, 'the request works')
        or note p $res;

    cmp_deeply($foo->calls,
               [
                   [
                       all(isa('HTTP::Headers'),
                           methods([header => 'My-Header'] => 'my value'),
                       ),
                       'a body',
                   ],
               ],
               'request received and action run')
        or note p $foo->calls;
}

subtest 'request on a configured destination' => sub {
    run_test($foo_one,'/url/1','my_action');
};

subtest 'request on the other configured destination' => sub {
    run_test($foo_one,'/url/2','my_action');
};

subtest 'requests on configured destination & actions' => sub {
    run_test($foo_two,'/url2/1','action1');
    run_test($foo_two,'/url2/1','action2');
    run_test($foo_two,'/url2/2','action3');
    run_test($foo_two,'/url2/2','action4');
};

done_testing();
