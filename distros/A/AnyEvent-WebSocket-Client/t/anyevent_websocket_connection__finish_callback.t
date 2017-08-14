use lib 't/lib';
use Test2::Plugin::EV;
use Test2::Plugin::AnyEvent::Timeout;
use Test2::V0 -no_srand => 1;
use Test2::Tools::WebSocket::Connection qw( create_connection_pair );
use AnyEvent::WebSocket::Connection;

note("finish callback should be called only once");

sub test_case
{
  my ($label, $code) = @_;
  subtest $label, sub {
    my @conns = create_connection_pair;
    my $finish_count = 0;
    my $cv_finish = AnyEvent->condvar;
    $conns[0]->on(finish => sub { $finish_count++; $cv_finish->send });
    
    $code->(\@conns);
    
    $cv_finish->recv;
    $conns[0]->send("hoge");
    $conns[0]->send("foo");
    $conns[0]->send("bar");
    is $finish_count, 1;
  };
}

test_case "delete conn 1", sub {
  my $conns = shift;
  undef $conns->[1];
};

test_case "close conn 1", sub {
  my $conns = shift;
  $conns->[1]->close();
};

test_case "close conn 0", sub {
  my $conns = shift;
  $conns->[0]->close();
};

test_case "recursively fire on_error event (in AE::Handle sense) while in on_eof handler", sub {
  my $conns = shift;
  $conns->[0]->on(finish => sub {
    # It is very rude and unusual to use the handle directly. We don't
    # have to support it, but it may happen.
    $conns->[0]->handle->push_shutdown;
    $conns->[0]->send("FOO"); # sending via a shutdown socket fires on_error ("Broken Pipe")
  });
  undef $conns->[1];
};

done_testing;
