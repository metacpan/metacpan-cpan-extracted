use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;

use lib 't';

use Local::Test::RefVars qw(ini_exception);


subtest 's builtin' => sub {
  my $ini = <<'INI';
[sec]
a = $(=& s,foo bar foo,foo,baz)
b = $(=& s,foo bar foo,foo,baz,g)
c = $(=& s,Foo,foo,bar,i)
d = $(=& s,abc123,[a-z]+[0-9]+,X)
e = $(=& s,a b c,[ ]+,_,g)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables()->{sec};

  is($vars->{a}, 'baz bar foo', 's replaces first match');
  is($vars->{b}, 'baz bar baz', 's with g replaces all matches');
  is($vars->{c}, 'bar', 's supports i modifier');
  is($vars->{d}, 'X', 's supports regex patterns');
  is($vars->{e}, 'a_b_c', 's supports regex whitespace class');
};


subtest 'tr builtin' => sub {
  my $ini = <<'INI';
[sec]
a = $(=& tr,abcabc,a,x)
b = $(=& tr,abcabc,abc,ABC)
c = $(=& tr,aaabbbccc,abc,x,s)
d = $(=& tr,abc123,0-9,#,c)
e = $(=& tr,abc123,0-9,,d)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables()->{sec};

  is($vars->{a}, 'xbcxbc', 'tr replaces characters');
  is($vars->{b}, 'ABCABC', 'tr maps character lists');
  is($vars->{c}, 'x', 'tr supports s modifier');
  is($vars->{d}, '###123', 'tr supports c modifier');
  is($vars->{e}, 'abc', 'tr supports d modifier');
};


subtest 's rejects unsafe regex code blocks' => sub {
  like(ini_exception(<<'INI'),
[sec]
bad = (?{})
x = $(=& s,abc,$(bad),x)
INI
       qr/^s: regex code blocks are not allowed/,
       's rejects (?{ ... })');

  like(ini_exception(<<'INI'),
[sec]
bad = (??{})
x = $(=& s,abc,$(bad),x)
INI
       qr/^s: regex code blocks are not allowed/,
       's rejects (??{ ... })');
};


subtest 's rejects unsupported modifiers' => sub {
  like(ini_exception(<<'INI'),
[sec]
x = $(=& s,abc,a,b,e)
INI
       qr/^s: unsupported modifier 'e'/,
       's rejects e modifier');

  like(ini_exception(<<'INI'),
[sec]
x = $(=& s,abc,a,b,ge)
INI
    qr/^s: unsupported modifier 'ge'/,
    's rejects mixed unsupported modifier');
};


subtest 'tr rejects unsupported modifiers' => sub {
  like(ini_exception(<<'INI'),
[sec]
x = $(=& tr,abc,a,b,g)
INI

       qr/^tr: unsupported modifier 'g'/,
       'tr rejects g modifier');

  like(ini_exception(<<'INI'),
[sec]
x = $(=& tr,abc,a,b,e)
INI
    qr/^tr: unsupported modifier 'e'/,
    'tr rejects e modifier');
};


subtest 'argument count errors' => sub {
  like(ini_exception(<<'INI'),
[sec]
x = $(=& s,abc,a)
INI
       qr/^s: expected 3 or 4 arguments/,
       's rejects too few arguments');

  like(ini_exception(<<'INI'),
[sec]
x = $(=& tr,abc,a)
INI
       qr/^tr: expected 3 or 4 arguments/,
       'tr rejects too few arguments');
};


#==================================================================================================
done_testing();
