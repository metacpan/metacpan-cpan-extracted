use strict;
use warnings;

use Test::More;
use Test::Exception;

use Config::INI::RefVars::Builtins ();

my $dispatch = Config::INI::RefVars::Builtins::default_dispatch_table();


subtest 'substr' => sub {
  is($dispatch->{substr}->('abcdef', 2), 'cdef', 'substr with offset');
  is($dispatch->{substr}->('abcdef', 2, 3), 'cde', 'substr with offset and length');

  throws_ok {
    $dispatch->{substr}->('abcdef');
  }
    qr/^substr: expected 2 or 3 arguments/,
    'substr rejects too few args';

  throws_ok {
    $dispatch->{substr}->('abcdef', 1, 2, 3);
  }
    qr/^substr: expected 2 or 3 arguments/,
    'substr rejects too many args';

  throws_ok {
    $dispatch->{substr}->('abcdef', 'x');
  }
    qr/^substr: Argument "x" isn't numeric in substr/,
    'substr converts numeric warning to exception';
};


subtest 'x' => sub {
  is($dispatch->{x}->('ab', 3), 'ababab', 'x repeats string');
  is($dispatch->{x}->('ab', 0), '', 'x with zero count');

  throws_ok {
    $dispatch->{x}->('ab');
  }
    qr/^x: expected 2 arguments/,
    'x rejects too few args';

  throws_ok {
    $dispatch->{x}->('ab', 1, 2);
  }
    qr/^x: expected 2 arguments/,
    'x rejects too many args';

  throws_ok {
    $dispatch->{x}->('ab', -1);
  }
    qr/^x: second argument must be a non-negative integer/,
    'x rejects negative count';

  throws_ok {
    $dispatch->{x}->('ab', 'x');
  }
    qr/^x: second argument must be a non-negative integer/,
    'x rejects non-numeric count';
};


#==================================================================================================
done_testing();
