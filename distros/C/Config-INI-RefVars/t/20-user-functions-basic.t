use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;

subtest 'simple user functions' => sub {
  my $ini = <<'INI';
pair #= $(1):$(2)
hello #= Hello $(1)

[sec]
2 = two
x = $(=# pair,a,b)
y = $(=# hello,World)
z = $(=# pair,XYZ)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{sec}{2}, 'two',         'no conflict with digit named variable');
  is($vars->{sec}{x}, 'a:b',         'pair function works');
  is($vars->{sec}{y}, 'Hello World', 'hello function works');
  is($vars->{sec}{z}, 'XYZ:',        'parameter vars are local');
};


subtest 'section local functions override tocopy functions' => sub {
  my $ini = <<'INI';
fmt #= global:$(1)

[sec]
fmt #= local:$(1)
x = $(=# fmt,test)
INI

  my $obj = Config::INI::RefVars->new();

  is($obj->parse_ini(src => $ini)->variables()->{sec}{x}, 'local:test', 'local function wins');
};


subtest 'qualified function call' => sub {
  my $ini = <<'INI';
fmt #= global:$(1)

[sec]
fmt #= local:$(1)
x = $(=# [__TOCOPY__]fmt,test)
INI

  my $obj = Config::INI::RefVars->new();
  is($obj->parse_ini(src => $ini)->variables()->{sec}{x}, 'global:test',
     'qualified function call works');
};


subtest 'local variables are visible inside function body' => sub {
  my $ini = <<'INI';
fmt #= $(1):$(var)
var = GLOBAL

[sec]
var = LOCAL
x = $(=# fmt,test)
INI

  my $obj = Config::INI::RefVars->new();
  is($obj->parse_ini(src => $ini)->variables()->{sec}{x}, 'test:LOCAL',
     'function expands in caller scope');
};


subtest 'builtins are fallback for user-function calls' => sub {
  my $ini = <<'INI';
[sec]
x = $(=# concat,a,b,c)
INI

  my $obj = Config::INI::RefVars->new();
  is($obj->parse_ini(src => $ini)->variables()->{sec}{x}, 'abc', 'builtin fallback works');
};


#==================================================================================================
done_testing();
