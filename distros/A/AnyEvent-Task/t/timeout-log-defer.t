use common::sense;

use List::Util;

use Callback::Frame;
use Log::Defer;
use Data::Dumper;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 3;


## The point of this test is to verify that if a timeout error is thrown
## from a checkout with a log_defer_object then a reference to the Log::Defer
## object is not kept alive by the cmd_handler closure of the checkout. This was
## a bug in AE::T 0.802.


AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  interface => sub {
                     select undef, undef, undef, 0.4;
                     die "shouldn't get here";
                   },
);


my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
             );


my $error_thrown = 0;

my $cv = AE::cv;

{
  my $ld = Log::Defer->new(sub {
    ok($error_thrown, 'log defer obj destroyed after error handler ran');
    $cv->send;
  });

  frame_try {
    $client->checkout( timeout => 0.2, log_defer_object => $ld )->(sub {
      $ld->warn("keep alive 1");
      die "checkout was serviced?";
    });
  } frame_catch {
    $ld->warn("keep alive 2");
    my $err = $@;
    ok(1, "timeout hit");
    ok($err =~ /timed out after/, 'correct err msg');
    $error_thrown = 1;
  };
}

my $timer = AE::timer 1, 0, sub {
  fail("log defer object destroyed");
  $cv->send;
};

$cv->recv;
