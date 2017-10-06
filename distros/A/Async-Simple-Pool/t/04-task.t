#!perl -T

use Modern::Perl;
use POSIX;
use Test::Spec;
use Test::Exception;
use Time::HiRes qw/ sleep /;

plan tests => 6;

# use lib '.';

use Async::Simple::Task;

describe 'init' => sub {

    my $task;

    it 'default initi' => sub {
        # Create a fork process, which will wait for data and execute &$sub if data will be passed
        ok $task = Async::Simple::Task->new( ), 'all params are optional';

        isa_ok( $task, 'Async::Simple::Task', 'successful init' );
        ok( !$task->has_answer, 'has no result after init' );
        $task->answer(1);
        ok( $task->has_answer, 'has result after set' );

        $task = Async::Simple::Task->new(
            id => '12345',
            timeout => 0.1,
        );

        is( $task->id, 12345, 'id found' );
        is( $task->timeout, 0.1, 'timeout setted ok' );
    };
};

runtests unless caller;
