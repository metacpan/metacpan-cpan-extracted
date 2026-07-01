use strict;
use warnings;

use Test::More;
use File::Spec::Functions qw(catdir catfile);

use Config::INI::RefVars;

subtest 'nested user function calls' => sub {
  my $ini = <<'INI';
wrap #= [$(1)]
pair #= $(1):$(2)
wrapped_pair #= $(=# wrap,$(=# pair,$(1),$(2)))

[sec]
x = $(=# wrapped_pair,a,b)
INI

  my $obj = Config::INI::RefVars->new();
  is($obj->parse_ini(src => $ini)->variables()->{sec}{x}, '[a:b]',
     'nested user function call works');
};


subtest 'user function calls builtin dispatch function' => sub {
  my $ini = <<'INI';
path #= $(=& catdir,$(1),$(2),$(3))

[sec]
x = $(=# path,foo,bar,baz)
INI

  my $obj = Config::INI::RefVars->new();
  is($obj->parse_ini(src => $ini)->variables()->{sec}{x}, catdir('foo', 'bar', 'baz'),
     'user function can call builtin');
};


subtest 'builtin arguments may contain user function calls' => sub {
  my $ini = <<'INI';
name #= $(1).txt

[sec]
x = $(=& catfile,foo,$(=# name,bar))
INI

  my $obj = Config::INI::RefVars->new();
  is($obj->parse_ini(src => $ini)->variables()->{sec}{x}, catfile('foo', 'bar.txt'),
     'builtin argument can contain user function call');
};


subtest 'expanded commas from nested user functions stay inside arguments' => sub {
  my $ini = <<'INI';
comma = ,
with_comma #= $(1)$(comma)$(2)
path #= $(=& catdir,$(1),$(2))

[sec]
x = $(=# path,foo,$(=# with_comma,bar,baz))
INI

  my $obj = Config::INI::RefVars->new();
  is($obj->parse_ini(src => $ini)->variables()->{sec}{x}, catdir('foo', 'bar,baz'),
     'comma from nested user function stays in argument');
};


subtest 'nested qualified user function calls' => sub {
  my $ini = <<'INI';
fmt #= GLOBAL:$(1)

[a]
fmt #= A:$(1)

[b]
wrap #= [$(=# [a]fmt,$(1))]
x = $(=# wrap,test)
INI

  my $obj = Config::INI::RefVars->new();
  is($obj->parse_ini(src => $ini)->variables()->{b}{x}, '[A:test]',
     'nested qualified user function call works');
};


#==================================================================================================
done_testing();

