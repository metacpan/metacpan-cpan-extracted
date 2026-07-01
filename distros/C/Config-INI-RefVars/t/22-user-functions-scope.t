use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;

subtest 'function body expands in caller section scope' => sub {
  my $ini = <<'INI';
fmt #= $(1):$(var)
var = GLOBAL

[sec]
var = LOCAL
x = $(=# fmt,test)
INI

  my $obj = Config::INI::RefVars->new();
  is($obj->parse_ini(src => $ini)->variables()->{sec}{x}, 'test:LOCAL',
     'local variable is visible in function body');
};


subtest 'qualified variable reference can force tocopy value' => sub {
  my $ini = <<'INI';
fmt #= $(1):$([__TOCOPY__]var)
var = GLOBAL

[sec]
var = LOCAL
x = $(=# fmt,test)
INI

  my $obj = Config::INI::RefVars->new();
  is($obj->parse_ini(src => $ini)->variables()->{sec}{x}, 'test:GLOBAL',
     'qualified variable reference forces tocopy value');
};


subtest 'function parameters shadow numeric variables temporarily' => sub {
  my $ini = <<'INI';
fmt #= $(1):$(2):$(3)

[sec]
1 = original-1
2 = original-2
x = $(=# fmt,a,b)
y = $(1):$(2)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{sec}{x}, 'a:b:', 'missing parameter expands to empty string');
  is($vars->{sec}{y}, 'original-1:original-2',
     'numeric variables are restored after function call');
};


subtest 'local user function overrides tocopy user function' => sub {
  my $ini = <<'INI';
fmt #= GLOBAL:$(1)

[sec]
fmt #= LOCAL:$(1)
x = $(=# fmt,value)
INI

  my $obj = Config::INI::RefVars->new();
  is($obj->parse_ini(src => $ini)->variables()->{sec}{x}, 'LOCAL:value',
     'local function overrides tocopy function');
};


subtest 'qualified function call bypasses local override' => sub {
  my $ini = <<'INI';
fmt #= GLOBAL:$(1)

[sec]
fmt #= LOCAL:$(1)
x = $(=# [__TOCOPY__]fmt,value)
INI

  my $obj = Config::INI::RefVars->new();
  is($obj->parse_ini(src => $ini)->variables()->{sec}{x}, 'GLOBAL:value',
     'qualified call bypasses local function');
};


subtest 'user function overrides builtin fallback' => sub {
  my $ini = <<'INI';
concat #= user:$(1):$(2)

[sec]
x = $(=# concat,a,b)
y = $(=& concat,a,b)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{sec}{x}, 'user:a:b', 'user function overrides builtin for $(=# ...)');
  is($vars->{sec}{y}, 'ab', 'builtin dispatch still available through $(=& ...)');
};


subtest 'section-local user function can override builtin only locally' => sub {
  my $ini = <<'INI';
[sec1]
concat #= sec1:$(1):$(2)
x = $(=# concat,a,b)

[sec2]
x = $(=# concat,a,b)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{sec1}{x}, 'sec1:a:b', 'local user function used in defining section');
  is($vars->{sec2}{x}, 'ab', 'builtin fallback used in other section');
};


#==================================================================================================
done_testing();

