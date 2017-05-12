use Test2::Bundle::Extended;
use Types::Standard -types;
use Type::Utils -all;
use Auto::Mata;

subtest 'utils' => sub {
  is Auto::Mata::explain(['foo', 42, {bar => "baz"}]), "['foo',42,{'bar' => 'baz'}]", 'explain';
  ok no_warnings { local $Auto::Mata::DEBUG = 0; Auto::Mata::debug('foo') }, 'debug w/o DEBUG_AUTOMATA';
  is warnings { local $Auto::Mata::DEBUG = 1; Auto::Mata::debug('test is %s', 'bar') }, ["# DEBUG> test is bar\n"], 'debug w/ DEBUG_AUTOMATA';
};

subtest 'basics' => sub {
  my $PosInt      = declare 'PosInt',      as Int, where { $_ > 0 };
  my $PosIntArray = declare 'PosIntArray', as ArrayRef[$PosInt];
  my $Remaining   = declare 'Remaining',   as $PosIntArray, where { @$_ > 1 };
  my $Reduced     = declare 'Reduced',     as $PosIntArray, where { @$_ == 1 };

  my $add_reduce = sub {
    my ($x, $y, @rem) = @{$_[0]};
    return [$x + $y, @rem];
  };

  my $fsm = machine {
    ready      'READY';
    terminal   'TERM';
    transition 'READY',  to 'REDUCE', on $Remaining;
    transition 'REDUCE', to 'REDUCE', on $Remaining, with { $add_reduce->($_) };
    transition 'REDUCE', to 'TERM',   on $Reduced,   with { $_->[0] };
    transition 'REDUCE', to 'TERM',   on Undef;

    like dies { transition 'REDUCE', to 'TERM', on $Reduced },
      qr/transition conflict in REDUCE to TERM: Reduced already matched by REDUCE_to_TERM_on_Reduced/,
      'expected error on transition conflict with identical transitions';

    like dies { transition 'REDUCE', to 'FOO', on $Reduced },
      qr/transition conflict in REDUCE to FOO: Reduced already matched by REDUCE_to_TERM_on_Reduced/,
      'expected error on transition conflict with equivalent constraints';
  };

  ok $fsm, 'machine';

  subtest 'interactive' => sub {
    ok my $adder = $fsm->(1), 'instance';

    my $arr = [1, 2, 3];
    my @states;
    my @results;

    while (my ($state, $data) = $adder->($arr)) {
      is $data, $arr, 'returns reference to input';
      push @states, $state;

      if (ref $data) {
        push @results, [@$data];
      } else {
        push @results, $data;
      }

      die "backstop reached" if @states > 10;
    }

    is \@states, [qw(REDUCE REDUCE REDUCE TERM)], 'expected state progression';
    is \@results, [[1, 2, 3], [3, 3], [6], 6], 'expected result progression';
    is $arr, 6, 'accumulator contains expected result';

    like dies { $fsm->()->([1, 2, -5]) }, qr/no transitions match/, 'expected error on invalid input type';
  };

  subtest 'non-interactive' => sub {
    ok my $adder = $fsm->(), 'instance';
    is $adder->([1, 2, 3, 4]), 10, 'result';
  };
};

subtest 'invalid state after transition' => sub {
  my $fsm = machine {
    ready      'READY';
    term       'TERM';
    transition 'READY', to 'FOO',  on Undef, with { ['foo'] };
    transition 'FOO',   to 'BAR',  on Tuple[Enum['foo']];
    transition 'BAR',   to 'TERM', on Tuple[Enum['bar']];
  };

  my $fails = $fsm->(1);
  $fails->(my $state);

  like dies { $fails->($state) }, qr/produced an invalid state/, 'expected error';
};

subtest 'sanity checks' => sub {
  like dies { transition 'READY' },
    qr/cannot be called outside a state machine definition block/,
    'transition outside the machine';

  like dies { ready 'READY' },
    qr/cannot be called outside a state machine definition block/,
    'ready outside the machine';

  like dies { terminal 'TERM' },
    qr/cannot be called outside a state machine definition block/,
    'terminal outside the machine';

  like dies { machine { } },
    qr/no ready state defined/,
    'missing ready state';

  like dies { machine { ready 'READY' } },
    qr/no terminal state defined/,
    'missing terminal state';

  like dies { machine { ready 'READY'; terminal 'READY' } },
    qr/terminal state and ready state are identical/,
    'terminal eq ready state';

  like dies { machine { ready 'READY'; terminal 'TERM' } },
    qr/no transitions defined/,
    'missing transitions';

  like dies {
      machine {
        ready 'READY'; terminal 'TERM';
        transition 'FOO', to 'TERM', on Any;
      };
    },
    qr/no transition defined for ready state/,
    'no ready transition';

  like dies {
      machine {
        ready 'READY'; terminal 'TERM';
        transition 'READY', to 'FOO', on Any;
        transition 'FOO', to 'READY', on Any;
      };
    },
    qr/no transition defined to terminal state/,
    'no terminal transition';

  like dies {
      machine {
        ready 'READY'; terminal 'TERM';
        transition 'READY', to 'FOO', on Any;
      };
    },
    qr/no subsequent states are reachable from FOO/,
    'incomplete (dangling state)';

  like dies {
      machine {
        ready 'READY'; terminal 'TERM';
        transition 'READY', to 'FOO', on Any;
        transition 'FOO', to 'TERM', on Any;
        transition 'TERM', to 'READY', on Any;
      };
    },
    qr/invalid transition from terminal state detected/,
    'invalid terminal state transition';

  like dies { machine { local $_ = 'foo'; ready 'READY' } },
    qr/invalid machine definition/,
    '$_ is shadowed';

  like dies {
      machine {
        ready 'READY'; terminal 'TERM';
        transition 'READY', to 'TERM';
        $_->{foo} = 'bar';
      };
    },
    qr/invalid machine definition/,
    'type validation failure';
};

done_testing;
