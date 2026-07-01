use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;


subtest 'm builtin' => sub {
  my $ini = <<'INI';
[sec]
a = $(=& m,abc123,\d+)
b = $(=& m,abcdef,\d+)
c = $(=& if,$(=& m,foo\.cpp,\.cpp$),yes,no)

regex=(?:a|b)b 
d = $(=& m, bb, ^$(regex)$)
e = $(=& m, ba, ^$(regex)$)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables()->{sec};

  is($vars->{a}, '1', 'm: first match');
  is($vars->{b}, '', 'm: second match');
  is($vars->{c}, 'yes', 'm: use with if-func');

  is($vars->{d}, 1,  "with non-capturing group (1)");
  is($vars->{e}, '', "with non-capturing group (2)");
};


#==================================================================================================
done_testing();

