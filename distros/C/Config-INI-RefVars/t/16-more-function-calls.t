use strict;
use warnings;

use Test::More;
use File::Spec::Functions qw(catdir catfile);

use Config::INI::RefVars;


subtest 'ignore and concat' => sub {
  my $ini = <<'INI';
[sec]
x := $(=& ignore, a, b, c)
y := $(=& concat, foo, bar, baz)
z := $(=& concat, left-, $(=& ignore, a, b), -right)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{sec}{x}, "", 'ignore returns empty string');
  is($vars->{sec}{y}, "foobarbaz", 'concat joins all args');
  is($vars->{sec}{z}, "left--right", 'concat works with nested ignore');
};


subtest 'ignore and concat (=)' => sub {
  my $ini = <<'INI';
[sec]
x = $(=& ignore, a, b, c)
y = $(=& concat, foo, bar, baz)
z = $(=& concat, left-, $(=& ignore, a, b), -right)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{sec}{x}, "", 'ignore returns empty string');
  is($vars->{sec}{y}, "foobarbaz", 'concat joins all args');
  is($vars->{sec}{z}, "left--right", 'concat works with nested ignore');
};


subtest 'join' => sub {
  my $ini = <<'INI';
[sec]
comma = ,
x := $(=& join, $(comma), a, b, c)
y := $(=& join, -, foo, bar, baz)
z := $(=& join, , foo, bar)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{sec}{x}, "a,b,c", 'join uses first arg as separator');
  is($vars->{sec}{y}, "foo-bar-baz", 'join with dash separator works');
  is($vars->{sec}{z}, "foobar", 'join with empty separator works');
};


subtest 'join (=)' => sub {
  my $ini = <<'INI';
[sec]
comma = ,
x = $(=& join, $(comma), a, b, c)
y = $(=& join, -, foo, bar, baz)
z = $(=& join, , foo, bar)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{sec}{x}, "a,b,c", 'join uses first arg as separator');
  is($vars->{sec}{y}, "foo-bar-baz", 'join with dash separator works');
  is($vars->{sec}{z}, "foobar", 'join with empty separator works');
};


subtest 'substr' => sub {
  my $ini = <<'INI';
[sec]
x := $(=& substr, abcdef, 2)
y := $(=& substr, abcdef, 2, 3)
z := $(=& substr, prefix-abcdef-suffix, 7, 6)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{sec}{x}, "cdef", 'substr(string, offset) works');
  is($vars->{sec}{y}, "cde", 'substr(string, offset, length) works');
  is($vars->{sec}{z}, "abcdef", 'substr extracts middle part');
};


subtest 'x function' => sub {
  my $ini = <<'INI';
[sec]
x = $(=& x,, 3)
y = $(=& x, abc, 0)
z = $(=& x, abc, 4)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{sec}{x}, "", 'x("", 3) works');
  is($vars->{sec}{y}, "", 'x(string, 0) works');
  is($vars->{sec}{z}, "abcabcabcabc", 'x(string, n), n>0, works');
};


#==================================================================================================
done_testing();
