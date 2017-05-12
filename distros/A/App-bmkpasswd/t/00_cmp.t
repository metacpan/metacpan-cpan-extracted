use Test::More;
use strict; use warnings;

use App::bmkpasswd ();

my $cmp = \&App::bmkpasswd::_eq;
ok  $cmp->('foo', 'foo'),   'foo eq foo';
ok  $cmp->('ooo', 'ooo'),   'ooo eq ooo';
ok  $cmp->('123', '123'),   '123 eq 123';
ok  $cmp->('', ''),         'empty string eq empty string';
ok !$cmp->('abc', '123'),   'abc ne 123';
ok !$cmp->('o', 'oo'),      'o ne oo';
ok !$cmp->('oo', 'o'),      'oo ne o';
ok !$cmp->('oo', 'ooo'),    'oo ne ooo';
ok !$cmp->('ooo', 'oo'),    'ooo ne oo';
ok !$cmp->('foo', 'Foo'),   'foo ne Foo';
ok !$cmp->('Foo', 'foo'),   'Foo ne foo';
ok !$cmp->('foo', 'fooo'),  'foo ne fooo';
ok !$cmp->('fooo', 'foo'),  'fooo ne foo';
ok !$cmp->('aaa', 'aaaa'),  'aaa ne aaaa';
ok !$cmp->('aaaa', 'aaa'),  'aaaa ne aaa';
ok !$cmp->('abcd', 'abc'),  'abcd ne abc';
ok !$cmp->('abc', 'abcd'),  'abc ne abcd';
ok !$cmp->('abcd', 'abce'), 'abcd ne abce';
ok !$cmp->('abce', 'abcd'), 'abce ne abcd';
ok !$cmp->('abc1', 'abc2'), 'abc1 ne abc2';
ok !$cmp->('abc2', 'abc1'), 'abc2 ne abc2';
ok !$cmp->('abcef', 'abce'), 'abcef ne abce';
ok !$cmp->('abce', 'abcef'), 'abce ne abcef';
ok !$cmp->('dcba', 'ecba'), 'dcba ne ecba';
ok !$cmp->('ecba', 'dcba'), 'ecba ne dcba';
ok !$cmp->('ebba', 'edda'), 'ebba ne edda';
ok !$cmp->('eeza', 'eeba'), 'eeza ne eeba';
ok !$cmp->('', 'abc'),      'empty string ne abc';
ok !$cmp->('abc', ''),      'abc ne empty string';
ok !$cmp->('', 'a'),        'empty string ne a';
ok !$cmp->('a', ''),        'a ne empty string';
ok !$cmp->('foo bar', 'foo bar baz'), 'foo bar ne foo bar baz';
ok !$cmp->('foo bar baz', 'foo bar'), 'foo bar baz ne foo bar';

done_testing
