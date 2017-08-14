use lib 't/lib';
use Test2::Plugin::EV;
use Test2::Plugin::AnyEvent::Timeout;
use Test2::V0 -no_srand => 1;
use Test2::Tools::WebSocket::Connection qw( create_connection_pair );
use AnyEvent::WebSocket::Connection;
use Scalar::Util qw(weaken);

note("It should be safe (exception-free) to destroy the Connection object in callbacks.");

sub test_case
{
  my ($label, $a_conn_code, $b_conn_code) = @_;
  subtest $label, sub {
    my $b_conn;
    my $a_conn_weak;
    my $cv_finish = AnyEvent->condvar;
    $cv_finish->begin;
    $cv_finish->begin;
    {
      my $a_conn;
      ($a_conn, $b_conn) = create_connection_pair;
      $a_conn_weak = $a_conn;
      weaken($a_conn_weak);
      
      $a_conn_code->($a_conn, $cv_finish);
    }
    ok(defined($a_conn_weak), "a_conn is alive due to the cyclic ref in callback");
    $b_conn->on(finish => sub {
      $cv_finish->end;
    });
    
    $b_conn_code->($b_conn, $cv_finish);
    
    $cv_finish->recv;
    ok(!defined($a_conn_weak), "a_conn is now destroyed");
  };
}

test_case "destroy in 'finish' callback", sub {
  my ($a_conn, $cv_finish) = @_;
  $a_conn->on(finish => sub {
    undef $a_conn; # cyclic ref that breaks when executed.
  });
  $a_conn->on(finish => sub {
    my ($conn) = @_;
    ok defined($conn), "conn is still alive in finish callback";
    $cv_finish->end;
  });
},
sub {
  my ($b_conn) = @_;
  $b_conn->close;
};


test_case "destroy in 'next_message' callback", sub {
  my ($a_conn, $cv_finish) = @_;
  $a_conn->on(next_message => sub {
    my ($conn, $msg) = @_;
    undef $a_conn;  # cyclic ref that breaks when executed.
    is $msg->body, "foobar", "message OK (first callback)";
  });
  $a_conn->on(next_message => sub {
    my ($conn, $msg) = @_;
    is $msg->body, "foobar", "message OK (second callback)";
    ok defined($conn), "conn is still alive in second next_message callback";
    $cv_finish->end;
  });
},
sub {
  my ($b_conn) = @_;
  $b_conn->send("foobar");
};


test_case "destroy in 'each_message' callback", sub {
  my ($a_conn, $cv_finish) = @_;
  $a_conn->on(each_message => sub {
    my ($conn, $msg) = @_;
    undef $a_conn;  # cyclic ref that breaks when executed.
    is $msg->body, "FOOBAR", "message OK (first callback)";
  });
  $a_conn->on(each_message => sub {
    my ($conn, $msg) = @_;
    is $msg->body, "FOOBAR", "message OK (second callback)";
    ok defined($conn), "conn is still alive in second next_message callback";
    $cv_finish->end;
  });
},
sub {
  my ($b_conn) = @_;
  $b_conn->send("FOOBAR");
};


done_testing;
