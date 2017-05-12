use common::sense;

use List::Util;

use Callback::Frame;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 16;


## The point of this test is to verify that arguments, errors, and
## return values are passed correctly between client and server.



AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  interface => sub {
                     die "ERR: $_[1]" if $_[0] eq 'error';
                     return \@_;
                   },
);



my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
               max_workers => 1,
               name => 'MY CLIENT NAME',
             );


my $cv = AE::cv;


{
  $client->checkout->(1, [2], { three => 3, λ => '𝇚' }, sub {
    my ($checkout, $ret) = @_;

    ok(!$@, 'no error set');
    is(@$ret, 3);
    is($ret->[0], 1);
    is($ret->[1]->[0], 2);
    is(ref($ret->[2]), 'HASH');
    is($ret->[2]->{three}, 3);
    is(ord($ret->[2]->{λ}), 0x1D1DA, 'unicode character round-tripped ok');
  });

  $client->checkout->some_method(1, sub {
    my ($checkout, $ret) = @_;

    ok(!$@, 'no error set 2');
    ok(@$ret == 2);
    ok($ret->[0] eq 'some_method');
    ok($ret->[1] == 1);
  });

  $client->checkout->error('die please', frame(code => sub {
    die "should never get here";
  }, catch => sub {
    ok($@, 'no error set 3');
    ok($@ =~ /ERR: die please/);
    ok($@ !~ /setup exception/i);
  }));

  frame(code => sub {
    $client->checkout->error('again, plz die', sub {
      die "should never get here 2";
    });
  }, catch => sub {
    my $trace = shift;
    ok($@ =~ /ERR: again, plz die/, '$@ has the exception');
    ok($trace =~ /MY CLIENT NAME -> error/, 'argument to callback has stack trace');

    $cv->send;
  })->();

}


$cv->recv;
