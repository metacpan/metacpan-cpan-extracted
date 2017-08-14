use utf8;
use lib 't/lib';
use Test2::Plugin::EV;
use Test2::Plugin::AnyEvent::Timeout;
use Test2::V0 -no_srand => 1;
use Test2::Tools::WebSocket::Connection qw( create_connection_pair create_connection_and_handle );
use AnyEvent::WebSocket::Connection;

subtest 'send' => sub {

  my($a,$b) = create_connection_pair;

  my $round_trip = sub {
  
    my($message) = @_;
    
    my $done = AnyEvent->condvar;
    
    $b->on(next_message => sub {
      my(undef, $message) = @_;
      $done->send($message);
    });
    
    $a->send($message);
    
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

    $a->send(
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
  
    $b->on(finish => sub {
      $done->send;
    });
  
    $a->send(
      AnyEvent::WebSocket::Message->new(
        opcode => 8,
        body   => pack('naa', 1005, 'b','b'),
      ),
    );
    
    $done->recv;
    
    is(
      $b,
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
      my ($a_conn, $b_handle) = create_connection_and_handle({masked => $masked});
      my $cv_finish = AnyEvent->condvar;
      $b_handle->on_read(sub {
        my ($handle) = @_;
        return if length($handle->{rbuf}) < 2;
        is substr($handle->{rbuf}, 0, 2), pack("C*", 0x81, ($masked ? 0x85 : 0x05)), "frame header OK";
        $cv_finish->send;
      });
      $a_conn->send("Hello");
      $cv_finish->recv;
    };
  
  }

};

subtest 'Connection should respond to a ping frame with a pong frame' => sub {

  my ($a_conn, $b_handle) = create_connection_and_handle;

  my $parser = Protocol::WebSocket::Frame->new;
  my $cv_finish = AnyEvent->condvar;
  $b_handle->on_read(sub {
    my ($handle) = @_;
    $parser->append($handle->{rbuf});
    my $payload = $parser->next_bytes;
    return if !defined($payload);
    is $parser->opcode, 10, "pong frame received";
    is $payload, "foobar", "... payload is identical to what b_handle has sent.";
    $cv_finish->send;
  });
  $b_handle->push_write(Protocol::WebSocket::Frame->new(type => "ping", buffer => "foobar")->to_bytes);

  $cv_finish->recv;
};

subtest 'connection close data' => sub {

  subtest 'ascii' => sub {

    my($a, $b) = create_connection_pair;

    my $cv = AnyEvent->condvar;
    my $reason;
    my $code;

    $b->on(finish => sub {
      my($con) = @_;
      $code   = $con->close_code;
      $reason = $con->close_reason;
      $cv->send;
    });

    $a->close(1009 => 'anything');

    $cv->recv;

    is $code,   1009,       'code is available in finish callback';
    is $reason, 'anything', 'reason is available in finish callback';

    is(
      $b,
      object {
        call close_code   => 1009;
        call close_reason => 'anything';
      },
      'connection has finish code and reason',
    );
  };

  subtest 'unicode' => sub {

    my($a, $b) = create_connection_pair;

    my $cv = AnyEvent->condvar;
    my $reason;
    my $code;

    $b->on(finish => sub {
      my($con) = @_;
      $code   = $con->close_code;
      $reason = $con->close_reason;
      $cv->send;
    });

    $a->close(1009 => 'ＵＴＦ８ ＷＩＤＥ ＣＨＡＲＡＣＴＥＲＳ');

    $cv->recv;

    is $code,   1009,                                     'code is available in finish callback';
    is $reason, 'ＵＴＦ８ ＷＩＤＥ ＣＨＡＲＡＣＴＥＲＳ', 'reason is available in finish callback';

    is(
      $b,
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
    my ($a_conn, $b_handle) = create_connection_and_handle;

    my $b_received;
    my $cv_finish = AnyEvent->condvar;
    $cv_finish->begin;
    $cv_finish->begin;
    $b_handle->on_read(sub { });
    $b_handle->on_error(sub {
      $b_received = $_[0]->{rbuf};
      $_[0]->{rbuf} = "";
      $cv_finish->end;
    });
    $a_conn->on(finish => sub {
      $cv_finish->end;
    });
    $a_conn->close();
    $a_conn->send("hoge");
    $cv_finish->recv;

    my $parser = Protocol::WebSocket::Frame->new();
    $parser->append($b_received);
    ok defined($parser->next_bytes), "received a complete frame";
    ok $parser->is_close, "... and it's a close frame";
    ok !defined($parser->next_bytes), "no more frame";
  };

  my $make_frame = sub {
    Protocol::WebSocket::Frame->new(@_)->to_bytes;
  };

  subtest "it should not receive after receiving close frame", sub {
    my ($a_conn, $b_handle) = create_connection_and_handle;

    my @received_messages = ();
    my $cv_finish = AnyEvent->condvar;
    $a_conn->on(each_message => sub { push(@received_messages, $_[1]) });
    $a_conn->on(finish => sub { $cv_finish->send });
    $b_handle->push_write($make_frame->(type => "close"));
    $b_handle->push_write($make_frame->(buffer => "hoge"));
    $b_handle->push_shutdown;
    $cv_finish->recv;
    is scalar(@received_messages), 0, "the message 'hoge' should be discarded"
        or diag($received_messages[0]->body);
  };

};

subtest 'Connection should respond with close frame to close frame' => sub {

  my ($a_conn, $b_handle) = create_connection_and_handle;

  my $cv_b_recv = AnyEvent->condvar;
  $b_handle->on_error(sub {
    my $h = shift;
    $cv_b_recv->send($h->{rbuf});
    $h->{rbuf} = "";
  });
  $b_handle->on_read(sub {});
  $b_handle->push_write(Protocol::WebSocket::Frame->new(buffer => "", type => "close")->to_bytes);

  my $b_recv = $cv_b_recv->recv;
  my $parser = Protocol::WebSocket::Frame->new;
  $parser->append($b_recv);
  ok defined($parser->next_bytes), "received a complete frame";
  ok $parser->is_close, "... and it's a close frame";

};

subtest 'Connection should refuse extremely huge messages' => sub {

  subtest "Connection should refuse huge frames", sub {

    my ($a_conn, $b_handle) = create_connection_and_handle();
    my $cv_finish = AnyEvent->condvar;
    $cv_finish->begin;
    $cv_finish->begin;
    my @received_messages = ();
    $a_conn->on(finish => sub {
      $cv_finish->end;
    });
    $a_conn->on(each_message => sub {
      push(@received_messages, $_[1]);
    });
    $b_handle->on_error(sub {
      my $handle = shift;
      $handle->push_shutdown;
      $cv_finish->end;
    });
    $b_handle->on_read(sub { });

    my $frame_header = pack("H*", "827f00000000ffffffff"); # frame payload size = 2**32 - 1 bytes
    my $MAX_SEND_PAYLOAD = 1024; # for safety
    my $count_send_payload = 0;
    $b_handle->push_write($frame_header);
    $b_handle->on_drain(sub {
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
      # $a_conn chance to receive data.
      my $w; $w = AnyEvent->idle(cb => sub {
        undef $w;
        $handle->push_write("A" x 256);
      });
    });
    $cv_finish->recv;

    is scalar(@received_messages), 0, "the frame is too huge to receive.";
  };


  subtest "Connection should refuse messages with too many fragments", sub {
    my ($a_conn, $b_handle) = create_connection_and_handle;
    my $cv_finish = AnyEvent->condvar;
    $cv_finish->begin;
    $cv_finish->begin;
    my @received_messages = ();
    $a_conn->on(finish => sub {
      $cv_finish->end;
    });
    $a_conn->on(each_message => sub {
      push(@received_messages, $_[1])
    });
    $b_handle->on_error(sub {
      my $handle = shift;
      $handle->push_shutdown;
      $cv_finish->end; 
    });
    $b_handle->on_read(sub {});

    my $MAX_SEND_FRAMES = 10000;
    my $count_send_frame = 0;
    $b_handle->push_write(Protocol::WebSocket::Frame->new(fin => 0, opcode => 1, buffer => "A")->to_bytes);
    $b_handle->on_drain(sub {
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

  my($a,$b) = create_connection_pair;

  my $round_trip = sub {
  
    my($message) = @_;
    
    my $done = AnyEvent->condvar;
    
    $b->on(next_message => sub {
      my(undef, $message) = @_;
      $done->send($message);
    });
    
    $a->send($message);
    
    $done->recv;
  
  };

  my $closed = 0;

  my $quit_cv = AnyEvent->condvar;
  $b->on(finish => sub {
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
  
  $a->close;
  
  $quit_cv->recv;
  
  is $closed, 1, "closed";

};

subtest 'close codes' => sub {

  my @test_data = (
    [ [],                 [1005, ''],         'empty list defaults to 1005'     ],
    [ [undef, undef],     [1005, ''] ,        'both undef'                      ],
    [ [undef, 'error'],   [1005, 'error'] ,   'undef code with explicit reason' ],
    [ [1003, undef],      [1003, ''] ,        'other code with undef reason'    ],
    [ [1000],             [1000, ''],         'normal close code'               ],
    [ [1000, 'a reason'], [1000, 'a reason'], 'normal close code with reason'   ],
  );
  
  foreach my $test_data (@test_data)
  {
    my($args, $expected, $label) = @$test_data;
    subtest $label => sub {
    
      my($a,$b) = create_connection_pair;
      
      my $done = AnyEvent->condvar;
      
      $b->on(finish => sub { $done->send });
      
      $a->close(@$args);
      
      $done->recv;
      
      is(
        $b,
        object {
          call close_code   => $expected->[0];
          call close_reason => $expected->[1];
        },
      );
    
    };
  }

};

done_testing;
