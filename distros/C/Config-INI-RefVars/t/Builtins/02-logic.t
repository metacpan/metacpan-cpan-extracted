use strict;
use warnings;

use Test::More;

use Config::INI::RefVars::Builtins ();

my $dispatch = Config::INI::RefVars::Builtins::default_dispatch_table();

subtest 'and' => sub {
  is($dispatch->{'and'}->('a', 'b', 'c'), 'c', 'returns last argument');
  is($dispatch->{'and'}->('a', '', 'c'), '', 'empty argument is false');
  is($dispatch->{'and'}->(), '', 'no args returns empty');
  is($dispatch->{'and'}->('x'), 'x', 'one arg returns that arg');
};

subtest 'or' => sub {
  is($dispatch->{'or'}->('', 'b', 'c'), 'b', 'returns first non-empty argument');
  is($dispatch->{'or'}->('', '', ''), '', 'all empty returns empty');
  is($dispatch->{'or'}->(), '', 'no args returns empty');
  is($dispatch->{'or'}->('x', 'y'), 'x', 'first arg wins');
};

subtest 'if' => sub {
  is($dispatch->{'if'}->('yes', 'then', 'else'), 'then', 'true condition');
  is($dispatch->{'if'}->('', 'then', 'else'), 'else', 'false condition');
  is($dispatch->{'if'}->('yes', 'then'), 'then', 'true without else');
  is($dispatch->{'if'}->('', 'then'), '', 'false without else');
};


#==================================================================================================
done_testing();
