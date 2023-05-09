use utf8;
use lib 't/lib';
use Test2::Plugin::EV;
use Test2::Plugin::AnyEvent::Timeout;
use Test2::V0 -no_srand => 1;
use Test2::Tools::WebSocket::Connection qw( create_connection_pair create_connection_and_handle );
use AnyEvent::WebSocket::Connection;

subtest 'send' => sub {

  my($x,$y) = create_connection_pair;

  my $round_trip = sub {

    my($message) = @_;

    my $done = AnyEvent->condvar;

    $y->on(next_message => sub {
      my(undef, $message) = @_;
      $done->send($message);
    });

    $x->send($message);

    $done->recv;

  };

  subtest 'string' => sub {

    is(
      $round_trip->('hello world'),
      object {
        call body => 'hello world';
      },
    );
  };

  require AnyEvent::WebSocket::Message;

  subtest 'message object' => sub {

    is(
      $round_trip->(AnyEvent::WebSocket::Message->new(
        body => 'And another one',
      )),
      object {
        call body => 'And another one';
      },
    );

  };

  subtest 'is_text' => sub {

    is(
      $round_trip->(AnyEvent::WebSocket::Message->new(
        opcode => 1,
        body   => 'xx',
      )),
      object {
        call body => 'xx';
        call is_text => T();
        call is_binary => F();
      },
    );

  };


  subtest 'is_binary' => sub {

    is(
      $round_trip->(AnyEvent::WebSocket::Message->new(
        opcode => 2,
        body   => 'yy',
      )),
      object {
        call body => 'yy';
        call is_text => F();
        call is_binary => T();
      },
    );

  };

  subtest 'ping' => sub {

    skip_all 'no pong callback... yet';

    $x->send(
      AnyEvent::WebSocket::Message->new(
        opcode => 9,
        body   => 'zz',
      )
    );

  };

  {
    my @test_data = (
      {label => "single character", data => "a"},
      {label => "5k bytes", data => "a" x 5000},
      {label => "empty", data => ""},
      {label => "0", data => 0},
      {label => "utf8 charaters", data => 'ＵＴＦ８ ＷＩＤＥ ＣＨＡＲＡＣＴＥＲＳ'},
    );

    foreach my $case (@test_data)
    {
      subtest $case->{label} => sub {
        is(
          $round_trip->($case->{data}),
          object {
            call decoded_body => $case->{data};
          },
          'string'
        );
        is(
          $round_trip->(AnyEvent::WebSocket::Message->new(body => $case->{data})),
          object {
            call decoded_body => $case->{data};
          },
          'object'
        );
      };
    }
  }

  subtest 'close' => sub {

    my $done = AnyEvent->condvar;

    $y->on(finish => sub {
      $done->send;
    });

    $x->send(
      AnyEvent::WebSocket::Message->new(
        opcode => 8,
        body   => pack('naa', 1005, 'b','b'),
      ),
    );

    $done->recv;

    is(
      $y,
      object {
        call close_code   => 1005;
        call close_reason => 'bb';
      },
    );
  };

};

subtest 'masked attribute should control whether the frames sent by the Connection are masked or not' => sub {

  foreach my $masked (0,1)
  {

    subtest "masked = $masked" => sub {
      my ($x_conn, $y_handle) = create_connection_and_handle({masked => $masked});
      my $cv_finish = AnyEvent->condvar;
      $y_handle->on_read(sub {
        my ($handle) = @_;
        return if length($handle->{rbuf}) < 2;
        is substr($handle->{rbuf}, 0, 2), pack("C*", 0x81, ($masked ? 0x85 : 0x05)), "frame header OK";
        $cv_finish->send;
      });
      $x_conn->send("Hello");
      $cv_finish->recv;
    };

  }

};

subtest 'Connection should respond to a ping frame with a pong frame' => sub {

  my ($x_conn, $y_handle) = create_connection_and_handle;

  my $parser = Protocol::WebSocket::Frame->new;
  my $cv_finish = AnyEvent->condvar;
  $y_handle->on_read(sub {
    my ($handle) = @_;
    $parser->append($handle->{rbuf});
    my $payload = $parser->next_bytes;
    return if !defined($payload);
    is $parser->opcode, 10, "pong frame received";
    is $payload, "foobar", "... payload is identical to what b_handle has sent.";
    $cv_finish->send;
  });
  $y_handle->push_write(Protocol::WebSocket::Frame->new(type => "ping", buffer => "foobar")->to_bytes);

  $cv_finish->recv;
};

subtest 'connection close data' => sub {

  subtest 'ascii' => sub {

    my($x, $y) = create_connection_pair;

    my $cv = AnyEvent->condvar;
    my $reason;
    my $code;

    $y->on(finish => sub {
      my($con) = @_;
      $code   = $con->close_code;
      $reason = $con->close_reason;
      $cv->send;
    });

    $x->close(1009 => 'anything');

    $cv->recv;

    is $code,   1009,       'code is available in finish callback';
    is $reason, 'anything', 'reason is available in finish callback';

    is(
      $y,
      object {
        call close_code   => 1009;
        call close_reason => 'anything';
      },
      'connection has finish code and reason',
    );
  };

  subtest 'unicode' => sub {

    my($x, $y) = create_connection_pair;

    my $cv = AnyEvent->condvar;
    my $reason;
    my $code;

    $y->on(finish => sub {
      my($con) = @_;
      $code   = $con->close_code;
      $reason = $con->close_reason;
      $cv->send;
    });

    $x->close(1009 => 'ＵＴＦ８ ＷＩＤＥ ＣＨＡＲＡＣＴＥＲＳ');

    $cv->recv;

    is $code,   1009,                                     'code is available in finish callback';
    is $reason, 'ＵＴＦ８ ＷＩＤＥ ＣＨＡＲＡＣＴＥＲＳ', 'reason is available in finish callback';

    is(
      $y,
      object {
        call close_code   => 1009;
        call close_reason => 'ＵＴＦ８ ＷＩＤＥ ＣＨＡＲＡＣＴＥＲＳ';
      },
      'connection has finish code and reason',
    );

  };
};

subtest 'Connection should not send after sending close frame, should not receive after receiving close frame' => sub {

  subtest "it should not send after sending close frame", sub {
    my ($x_conn, $y_handle) = create_connection_and_handle;

    my $y_received;
    my $cv_finish = AnyEvent->condvar;
    $cv_finish->begin;
    $cv_finish->begin;
    $y_handle->on_read(sub { });
    $y_handle->on_error(sub {
      $y_received = $_[0]->{rbuf};
      $_[0]->{rbuf} = "";
      $cv_finish->end;
    });
    $x_conn->on(finish => sub {
      $cv_finish->end;
    });
    $x_conn->close();
    $x_conn->send("hoge");
    $cv_finish->recv;

    my $parser = Protocol::WebSocket::Frame->new();
    $parser->append($y_received);
    ok defined($parser->next_bytes), "received a complete frame";
    ok $parser->is_close, "... and it's a close frame";
    ok !defined($parser->next_bytes), "no more frame";
  };

  my $make_frame = sub {
    Protocol::WebSocket::Frame->new(@_)->to_bytes;
  };

  subtest "it should not receive after receiving close frame", sub {
    my ($x_conn, $y_handle) = create_connection_and_handle;

    my @received_messages = ();
    my $cv_finish = AnyEvent->condvar;
    $x_conn->on(each_message => sub { push(@received_messages, $_[1]) });
    $x_conn->on(finish => sub { $cv_finish->send });
    $y_handle->push_write($make_frame->(type => "close"));
    $y_handle->push_write($make_frame->(buffer => "hoge"));
    $y_handle->push_shutdown;
    $cv_finish->recv;
    is scalar(@received_messages), 0, "the message 'hoge' should be discarded"
        or diag($received_messages[0]->body);
  };

};

subtest 'Connection should respond with close frame to close frame' => sub {

  my ($x_conn, $y_handle) = create_connection_and_handle;

  my $cv_b_recv = AnyEvent->condvar;
  $y_handle->on_error(sub {
    my $h = shift;
    $cv_b_recv->send($h->{rbuf});
    $h->{rbuf} = "";
  });
  $y_handle->on_read(sub {});
  $y_handle->push_write(Protocol::WebSocket::Frame->new(buffer => "", type => "close")->to_bytes);

  my $y_recv = $cv_b_recv->recv;
  my $parser = Protocol::WebSocket::Frame->new;
  $parser->append($y_recv);
  ok defined($parser->next_bytes), "received a complete frame";
  ok $parser->is_close, "... and it's a close frame";

};

subtest 'Connection should refuse extremely huge messages' => sub {

  subtest "Connection should refuse huge frames", sub {

    my ($x_conn, $y_handle) = create_connection_and_handle();
    my $cv_finish = AnyEvent->condvar;
    $cv_finish->begin;
    $cv_finish->begin;
    my @received_messages = ();
    $x_conn->on(finish => sub {
      $cv_finish->end;
    });
    $x_conn->on(each_message => sub {
      push(@received_messages, $_[1]);
    });
    $y_handle->on_error(sub {
      my $handle = shift;
      $handle->push_shutdown;
      $cv_finish->end;
    });
    $y_handle->on_read(sub { });

    my $frame_header = pack("H*", "827f00000000ffffffff"); # frame payload size = 2**32 - 1 bytes
    my $MAX_SEND_PAYLOAD = 1024; # for safety
    my $count_send_payload = 0;
    $y_handle->push_write($frame_header);
    $y_handle->on_drain(sub {
      my $handle = shift;
      $count_send_payload++;
      if($count_send_payload >= $MAX_SEND_PAYLOAD)
      {
        fail("Connection should be aborted by now.");
        $handle->on_drain(undef);
        $handle->push_shutdown;
        $cv_finish->send;
        return;
      }

      # push_write is delayed to prevent deep-recursion and to give
      # $x_conn chance to receive data.
      my $w; $w = AnyEvent->idle(cb => sub {
        undef $w;
        $handle->push_write("A" x 256);
      });
    });
    $cv_finish->recv;

    is scalar(@received_messages), 0, "the frame is too huge to receive.";
  };


  subtest "Connection should refuse messages with too many fragments", sub {
    my ($x_conn, $y_handle) = create_connection_and_handle;
    my $cv_finish = AnyEvent->condvar;
    $cv_finish->begin;
    $cv_finish->begin;
    my @received_messages = ();
    $x_conn->on(finish => sub {
      $cv_finish->end;
    });
    $x_conn->on(each_message => sub {
      push(@received_messages, $_[1])
    });
    $y_handle->on_error(sub {
      my $handle = shift;
      $handle->push_shutdown;
      $cv_finish->end;
    });
    $y_handle->on_read(sub {});

    my $MAX_SEND_FRAMES = 10000;
    my $count_send_frame = 0;
    $y_handle->push_write(Protocol::WebSocket::Frame->new(fin => 0, opcode => 1, buffer => "A")->to_bytes);
    $y_handle->on_drain(sub {
      my $handle = shift;
      $count_send_frame++;
      if($count_send_frame >= $MAX_SEND_FRAMES)
      {
        fail("Connection should be aborted by now.");
        $handle->on_drain(undef);
        $handle->push_shutdown;
        $cv_finish->send;
        return;
      }
      my $w; $w = AnyEvent->idle(cb => sub {
        undef $w;
        $handle->push_write(Protocol::WebSocket::Frame->new(fin => 0, opcode => 0, buffer => "A")->to_bytes);
      });
    });
    $cv_finish->recv;

    is scalar(@received_messages), 0, "the message consists of too many fragments to receive.";
  };
};

subtest 'other end is closed' => sub {

  my($x,$y) = create_connection_pair;

  my $round_trip = sub {

    my($message) = @_;

    my $done = AnyEvent->condvar;

    $y->on(next_message => sub {
      my(undef, $message) = @_;
      $done->send($message);
    });

    $x->send($message);

    $done->recv;

  };

  my $closed = 0;

  my $quit_cv = AnyEvent->condvar;
  $y->on(finish => sub {
    $closed = 1;
    $quit_cv->send("finished");
  });

  is(
    $round_trip->('a'),
    object {
      call decoded_body => 'a';
    },
    'single character',
  );

  is(
    $round_trip->('quit'),
    object {
      call decoded_body => 'quit';
    },
    'quit',
  );

  $x->close;

  $quit_cv->recv;

  is $closed, 1, "closed";

};

subtest 'close codes' => sub {

  my @test_data = (
    [ [],                 [1000, ''],         'empty list defaults to 1005'     ],
    [ [undef, undef],     [1000, ''] ,        'both undef'                      ],
    [ [undef, 'error'],   [1000, 'error'] ,   'undef code with explicit reason' ],
    [ [1003, undef],      [1003, ''] ,        'other code with undef reason'    ],
    [ [1001],             [1001, ''],         'normal close code'               ],
    [ [1001, 'a reason'], [1001, 'a reason'], 'normal close code with reason'   ],
  );

  foreach my $test_data (@test_data)
  {
    my($xrgs, $expected, $label) = @$test_data;
    subtest $label => sub {

      my($x,$y) = create_connection_pair;

      my $done = AnyEvent->condvar;

      $y->on(finish => sub { $done->send });

      $x->close(@$xrgs);

      $done->recv;

      is(
        $y,
        object {
          call close_code   => $expected->[0];
          call close_reason => $expected->[1];
        },
      );

    };
  }

};

subtest 'next_message callback can be set from within a next_message callback' => sub {
  my($x,$y) = create_connection_pair;
  my($first_msg, $second_msg);

  my $round_trip = sub {
    my $done = AnyEvent->condvar;

    $y->on(next_message => sub {
      my(undef, $message) = @_;
      $first_msg = $message;
      $x->send('second');
      $y->on(next_message => sub {
        my(undef, $message) = @_;
        $second_msg = $message;
        $done->send;
      });
    });

    $x->send('first');
    $done->recv;
  };

  my $quit_cv = AnyEvent->condvar;
  $y->on(finish => sub { $quit_cv->send; });
  $round_trip->();

  is(
    $first_msg,
    object {
      call decoded_body => 'first';
    },
    'first message',
  );

  is(
    $second_msg,
    object {
      call decoded_body => 'second';
    },
    'second message',
  );

  $x->close;

  $quit_cv->recv;
};

done_testing;
