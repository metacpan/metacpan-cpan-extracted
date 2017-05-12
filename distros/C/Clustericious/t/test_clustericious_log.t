use Test2::Bundle::Extended;
use Test::Clustericious::Log import => ':all';
use Clustericious::Log -init_logging => "Froodle";
use YAML::XS qw( Load );

subtest exports => sub {

  imported_ok $_ for qw(
    log_context
    log_events
    log_like
    log_unlike
  );
  
};

subtest log_context => sub {

  ERROR "this should not appear";
  my @e = log_context {
    log_events;
  };
  
  is \@e, [], 'this should not appear does not appear';
  
  @e = log_context {
    ERROR "this should";
    log_events;
  };
  
  is $e[0]->{message}, 'this should', 'this should does appear';

};

subtest log_events => sub {

  my @e = log_context {
    TRACE "main trace";
    DEBUG "main debug";
    INFO  "main info";
    WARN  "main warn";
    ERROR "main error";
    FATAL "main fatal";
    log_events;
  };

  my $expected = Load(<<EOF);
---
- level: 0
  log4p_category: main
  log4p_level: TRACE
  message: main trace
  name: TestX
- level: 0
  log4p_category: main
  log4p_level: DEBUG
  message: main debug
  name: TestX
- level: 1
  log4p_category: main
  log4p_level: INFO
  message: main info
  name: TestX
- level: 3
  log4p_category: main
  log4p_level: WARN
  message: main warn
  name: TestX
- level: 4
  log4p_category: main
  log4p_level: ERROR
  message: main error
  name: TestX
- level: 7
  log4p_category: main
  log4p_level: FATAL
  message: main fatal
  name: TestX
EOF

  is(\@e, $expected, 'log_events (list context)');

  my $e = log_context {
    TRACE "main trace";
    DEBUG "main debug";
    INFO  "main info";
    WARN  "main warn";
    ERROR "main error";
    FATAL "main fatal";
    log_events;
  };

  is $e, 6, 'log_events (scalar context)';

};

subtest log_like => sub {

  log_context {
  
    ERROR "message1";
    ERROR "message2";
    
    is(
      intercept { log_like 'message1' },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'log matches pattern';
        };
        end;
      },
      'log_like message1',
    );

    is(
      intercept { log_like qr{age1} },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'log matches pattern';
        };
        end;
      },
      'log_like qr{age1}',
    );

    is(
      intercept { log_like 'message3' },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'log matches pattern';
        };
        event Diag => sub {};
        event Diag => sub {};
        event Diag => sub {
          call message => 'None of the events matched the pattern:';
        };
        event Diag => sub {
          call message => match qr{^---};
        };
        end;
      },
      'log_like message3',
    );
    
    is(
      intercept { log_unlike 'message3' },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'log does not match pattern';
        };
        end;
      },
      'log_unlike message3',
    );
  
    is(
      intercept { log_unlike 'message1' },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'log does not match pattern';
        };
        event Diag => sub {};
        event Diag => sub {};
        event Diag => sub {
          call message => 'This event matched, but should not have:';
        };
        event Diag => sub {
          call message => match qr{^---};
        };
        end;
      },
      'log_unlike message1',
    );

    is(
      intercept { log_unlike qr{message} },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'log does not match pattern';
        };
        event Diag => sub {};
        event Diag => sub {};
        event Diag => sub {
          call message => 'This event matched, but should not have:';
        };
        event Diag => sub {
          call message => match qr{^---};
        };
        event Diag => sub {
          call message => 'This event matched, but should not have:';
        };
        event Diag => sub {
          call message => match qr{^---};
        };
        end;
      },
      'log_unlike qr{message}',
    );
    
    # TODO: also test matching of other fields

  };

};

subtest 'local context is also in global' => sub {

  ERROR "PLATYPUS-42";
  log_context {
    ERROR "PLATYPUS-47";
    log_unlike qr{PLATYPUS-42};
    log_like qr{PLATYPUS-47};
  };

  log_like qr{PLATYPUS-42};
  log_like qr{PLATYPUS-47};

};

done_testing;
