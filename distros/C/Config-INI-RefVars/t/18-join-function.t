use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;

subtest 'join with simple separators' => sub {
  my $ini = <<'INI';
[sec]
comma = ,
dash  = -
x := $(=& join, $(comma), a, b, c)
y := $(=& join, $(dash), foo, bar, baz)
z := $(=& join, , foo, bar)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{sec}{x}, 'a,b,c', 'join with comma separator');
  is($vars->{sec}{y}, 'foo-bar-baz', 'join with dash separator');
  is($vars->{sec}{z}, 'foobar', 'join with empty separator');
};


subtest 'join with nested and expanded arguments' => sub {
  my $ini = <<'INI';
[sec]
comma = ,
a = left
b = right
x := $(=& join, $(comma), pre-$(a), mid-$(b), post)
y := $(=& join, /, $(=& concat, foo, bar), baz)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{sec}{x}, 'pre-left,mid-right,post', 'join expands arguments first');
  is($vars->{sec}{y}, 'foobar/baz', 'join works with nested function call');
};


subtest 'join edge cases' => sub {
  my $ini = <<'INI';
[sec]
x := $(=& join, , )
y := $(=& join, :)
z := $(=& join, :, one)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{sec}{x}, '', 'join with empty separator and one empty item');
  is($vars->{sec}{y}, '', 'join with separator only and no items');
  is($vars->{sec}{z}, 'one', 'join with one item returns the item unchanged');
};


#==================================================================================================
done_testing();
