use strict;
use warnings;

use Test::More;
use Test::Exception;

use Config::INI::RefVars::Builtins ();

my $dispatch = Config::INI::RefVars::Builtins::default_dispatch_table();

subtest 's' => sub {
  is($dispatch->{s}->('foo bar foo', 'foo', 'baz'), 'baz bar foo', 's replaces first match');
  is($dispatch->{s}->('foo bar foo', 'foo', 'baz', 'g'), 'baz bar baz', 's with g');
  is($dispatch->{s}->('Foo', 'foo', 'bar', 'i'), 'bar', 's with i');
  is($dispatch->{s}->('abc123', '[a-z]+[0-9]+', 'X'), 'X', 's regex pattern');
  is($dispatch->{s}->('a b c', '[ ]+', '_', 'g'), 'a_b_c', 's whitespace class');

  throws_ok(
            sub { $dispatch->{s}->('abc', 'a') },
            qr/^s: expected 3 or 4 arguments/,
            's rejects too few args',
           );

  throws_ok(
            sub { $dispatch->{s}->('abc', 'a', 'b', 'e') },
            qr/^s: unsupported modifier 'e'/,
            's rejects e modifier',
           );

  throws_ok(
            sub { $dispatch->{s}->('abc', '(?{})', 'x') },
            qr/^s: regex code blocks are not allowed/,
            's rejects (?{})',
           );

  throws_ok(
            sub { $dispatch->{s}->('abc', '(??{})', 'x') },
            qr/^s: regex code blocks are not allowed/,
            's rejects (??{})',
           );
};


subtest 'tr' => sub {
  is($dispatch->{tr}->('abcabc', 'a', 'x'), 'xbcxbc', 'tr replaces chars');
  is($dispatch->{tr}->('abcabc', 'abc', 'ABC'), 'ABCABC', 'tr maps chars');
  is($dispatch->{tr}->('aaabbbccc', 'abc', 'x', 's'), 'x', 'tr with s');
  is($dispatch->{tr}->('abc123', '0-9', '#', 'c'), '###123', 'tr with c');
  is($dispatch->{tr}->('abc123', '0-9', '', 'd'), 'abc', 'tr with d');

  throws_ok(
            sub { $dispatch->{tr}->('abc', 'a') },
            qr/^tr: expected 3 or 4 arguments/,
            'tr rejects too few args',
           );

  throws_ok(
            sub { $dispatch->{tr}->('abc', 'a', 'b', 'g') },
            qr/^tr: unsupported modifier 'g'/,
            'tr rejects unsupported modifier',
           );
};


#==================================================================================================
done_testing();
