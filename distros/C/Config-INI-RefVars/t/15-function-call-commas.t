# t/16-function-call-commas.t
use strict;
use warnings;

use Test::More;
use File::Spec::Functions qw(catdir catfile);

use Config::INI::RefVars;

subtest 'comma from variable stays inside one function argument' => sub {
  my $ini = <<'INI';
[paths]
komma = ,
dir   := $(=& catdir, foo, bar$(komma)baz)
file  := $(=& catfile, pre$(komma)fix, tail)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{paths}{dir}, catdir('foo', 'bar,baz'),
     'expanded comma inside catdir argument does not split argument');

  is($vars->{paths}{file}, catfile('pre,fix', 'tail'),
     'expanded comma inside catfile argument does not split argument');
};


subtest 'comma from variable also works in nested function calls' => sub {
  my $ini = <<'INI';
[paths]
komma  = ,
nested := $(=& catfile, $(=& catdir, foo$(komma)bar, baz), out.txt)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{paths}{nested}, catfile(catdir('foo,bar', 'baz'), 'out.txt'),
     'expanded comma inside nested function argument does not split argument');
};


subtest 'multiple expanded commas remain within their original arguments' => sub {
  my $ini = <<'INI';
[paths]
komma = ,
x     = left
y     = right
dir   := $(=& catdir, $(x)$(komma)$(y), a$(komma)b, plain)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{paths}{dir}, catdir('left,right', 'a,b', 'plain'),
     'multiple expanded commas stay in their respective arguments');
};


#==================================================================================================
done_testing();
