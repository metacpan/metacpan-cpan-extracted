use strict;
use warnings;
use AnyEvent::Loop; # Ensure the pure perl loop is loaded for testing
use Test::More;
use Sub::Override;
use Argon::Simple;
use Argon::Message;
use Argon qw(:commands);

SKIP: {
    skip 'does not run under MSWin32' if $^O eq 'MSWin32';

    our @overrides = (
        Sub::Override->new('Argon::Client::connect', sub {}),
        Sub::Override->new('Argon::Client::collect', sub { 42 }),
        Sub::Override->new('Argon::Client::send',    sub { Argon::Message->new(cmd => $CMD_ACK, id => 'abcdefg') }),
    );

    ok(my $client1 = connect('somehost:1234'),  'connect (1 arg)');
    ok(my $client2 = connect('somehost', 1234), 'connect (2 arg)');
    ok(my $client3 = connect('somehost', 4567), 'connect (2 arg, changed port)');
    is("$client1", "$client2", 'identical connect args understood between 1 and 2 arg forms');
    isnt("$client1", "$client3", 'change in connection args creates new client');

    # Scalar context
    {
        my $deferred = process { shift } 1, 2, 3; # noop sub - collect will return 42 via mock
        is($deferred->(), 42, 'process + deferred');
    }

    # List context
    {
        my $status = { 'abcdefg' => 1 };
        my $override = Sub::Override->new('Argon::Client::server_status', sub {{pending => {someworker => $status}}});

        my ($deferred, $is_finished) = process { shift } 1, 2, 3;

        is($is_finished->(), 0, 'not finished');

        $status = {};
        is($is_finished->(), 1, 'finished');
        is($deferred->(), 42, 'process + deferred');
    }

    # Task class
    {
        my $deferred = task 't::TestTask', 1, 2, 3;
        is($deferred->(), 42, 'task + deferred');
    }
};

done_testing;
