use strict;
use warnings;

use Test::More;
use Test::Exception;

use Config::INI::RefVars::Builtins ();

my $dispatch = Config::INI::RefVars::Builtins::default_dispatch_table();


subtest "m: good cases" => sub {
  is($dispatch->{m}->('abc123', '\d+'), '1');
  is($dispatch->{m}->('abcdef', '\d+'), '');
  is($dispatch->{m}->('ABC', 'abc', 'i'), '1');
};


subtest "m: error cases" => sub {
  throws_ok(
            sub { $dispatch->{m}->('abc') },
            qr/^m: expected 2 or 3 arguments/,
            'm rejects too few args',
           );

  throws_ok(
            sub { $dispatch->{m}->('abc', '(?{})') },
            qr/^m: regex code blocks are not allowed/,
            'm rejects code blocks',
           );
};


done_testing();


