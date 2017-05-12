use common::sense;

use List::Util;
use Callback::Frame;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 7;


## This test verifies that the dont_refork_after_error client stops the
## worker process from being killed off after a checkout is released
## where the worker threw an error in its lifetime.

## Note that a checkout's methods can still be called after an error
## is thrown but before the checkout is released, perhaps to access
## error states or to rollback a transaction.



AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  interface => {
    get_pid => sub { return $$ },
    throw => sub { my ($err) = @_; die $err; },
  },
);



my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
               max_workers => 1,
               dont_refork_after_error => 1,
             );


my $cv = AE::cv;

my $pid;
{
  my $checkout = $client->checkout();

  $checkout->get_pid(sub {
    my ($checkout, $ret) = @_;
    $pid = $ret;

    like($pid, qr/^\d+$/, "got PID");

    $checkout->get_pid(sub {
      my ($checkout, $ret) = @_;
      is($pid, $ret, "PID didn't change in same checkout");

      $checkout->throw("BLAH", frame(code => sub {
        die "throw method didn't return error";
      }, catch => sub {
        my $err = $@;
        like($err, qr/BLAH/, "caught BLAH error");

        $checkout->get_pid(sub {
          my ($checkout, $ret) = @_;
          is($pid, $ret, "PID didn't change even after error");

          $checkout->throw("OUCH", frame(code => sub {
            die "throw method didn't return error 2";
          }, catch => sub {
            my $err = $@;
            like($err, qr/OUCH/, "caught OUCH error");
 
            $checkout->get_pid(sub {
              my ($checkout, $ret) = @_;
              is($pid, $ret, "PID didn't change even after second error");
            });
          }));
        });
      }));
    });
  });
}


{
  my $checkout = $client->checkout();

  $checkout->get_pid(sub {
    my ($checkout, $ret) = @_;
    is($ret, $pid, "new worker was not created since previous checkout had an error and we set dont_refork_after_error");

    $cv->send;
  });
}


$cv->recv;
