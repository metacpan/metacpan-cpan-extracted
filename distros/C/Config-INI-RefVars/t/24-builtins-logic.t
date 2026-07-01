use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;

subtest 'and' => sub {
  my $ini = <<'INI';
[sec]
a = $(=& and,a,b,c)
b = $(=& and,a,,c)
c = $(=& and)
d = $(=& and,yes)
e = $(=& and,yes,$(=& ignore,no),later)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables()->{sec};

  is($vars->{a}, 'c', 'and returns last non-empty argument');
  is($vars->{b}, '', 'and returns empty if one argument is empty');
  is($vars->{c}, '', 'and without arguments returns empty');
  is($vars->{d}, 'yes', 'and with one argument returns that argument');
  is($vars->{e}, '', 'and treats expanded empty argument as false');
};


subtest 'or' => sub {
  my $ini = <<'INI';
[sec]
a = $(=& or,,b,c)
b = $(=& or,,,)
c = $(=& or)
d = $(=& or,yes,no)
e = $(=& or,$(=& ignore,no),fallback)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables()->{sec};

  is($vars->{a}, 'b', 'or returns first non-empty argument');
  is($vars->{b}, '', 'or returns empty if all arguments are empty');
  is($vars->{c}, '', 'or without arguments returns empty');
  is($vars->{d}, 'yes', 'or returns first argument if non-empty');
  is($vars->{e}, 'fallback', 'or treats expanded empty argument as false');
};


subtest 'if' => sub {
  my $ini = <<'INI';
[sec]
a = $(=& if,yes,then,else)
b = $(=& if,,then,else)
c = $(=& if,yes,then)
d = $(=& if,,then)
e = $(=& if,$(=& ignore,no),then,else)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables()->{sec};

  is($vars->{a}, 'then', 'if returns then branch for non-empty condition');
  is($vars->{b}, 'else', 'if returns else branch for empty condition');
  is($vars->{c}, 'then', 'if with two args returns then branch if true');
  is($vars->{d}, '', 'if with two args returns empty if false');
  is($vars->{e}, 'else', 'if treats expanded empty condition as false');
};


#==================================================================================================
done_testing();
