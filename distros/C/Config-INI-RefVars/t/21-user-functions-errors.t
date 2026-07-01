use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 't';

use Local::Test::RefVars qw(throws_ini_like);

use Config::INI::RefVars;

subtest 'unknown user functions' => sub {
  throws_ini_like('unknown unqualified function',
                  <<'INI',
[sec]
x = $(=# does_not_exist)
INI
                  qr/unknown function 'does_not_exist'/);

  throws_ini_like('unknown qualified function in existing section',
                  <<'INI',
[other]
known #= ok

[sec]
x = $(=# [other]does_not_exist)
INI
                  qr/unknown function '\[other\]does_not_exist'/);

  throws_ini_like('unknown qualified function in missing section',
                  <<'INI',
[sec]
x = $(=# [missing]does_not_exist)
INI
                  qr/unknown function '\[missing\]does_not_exist'/);
};


subtest 'qualified user function calls' => sub {
  my $ini = <<'INI';
fmt #= GLOBAL:$(1)

[a]
fmt #= A:$(1)

[b]
fmt #= B:$(1)
x = $(=# fmt,x)
y = $(=# [a]fmt,y)
z = $(=# [__TOCOPY__]fmt,z)
INI

  my $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini)->variables();

  is($vars->{b}{x}, 'B:x', 'unqualified call uses local function');
  is($vars->{b}{y}, 'A:y', 'qualified call uses function from explicit section');
  is($vars->{b}{z}, 'GLOBAL:z', 'qualified call can use function from __TOCOPY__');
};


subtest 'qualified call does not fall back to builtin' => sub {

  throws_ini_like('qualified builtin fallback is not allowed',
                  <<'INI',
[sec]
x = $(=# [sec]concat,a,b)
INI
                  qr/unknown function '\[sec\]concat'/);
};


subtest 'malformed and empty calls' => sub {

  throws_ini_like('empty user function call',
                  <<'INI',
[sec]
x = $(=#)
INI
                  qr/empty function call/);

  throws_ini_like('blank user function call',
                  <<'INI',
[sec]
x = $(=#    )
INI
                  qr/empty function call/);

  throws_ini_like('empty qualified function basename',
                  <<'INI',
[sec]
x = $(=# [sec])
INI
                  qr/unknown function '\[sec\]'/);
};


subtest 'recursive user functions die cleanly' => sub {
  throws_ini_like('direct recursive function',
                  <<'INI',
rec #= $(=# rec)

[sec]
x = $(=# rec)
INI
                  qr/recursive function '\[__TOCOPY__\]#=rec' calls itself/);

  throws_ini_like('indirect recursive function',
                  <<'INI',
a #= $(=# b)
b #= $(=# a)

[sec]
x = $(=# a)
INI
                  qr/recursive function '\[__TOCOPY__\]#=a' calls itself/);

  throws_ini_like('section-local recursive function',
                  <<'INI',
[sec]
rec #= $(=# rec)
x = $(=# rec)
INI
                  qr/recursive function '\[sec\]#=rec' calls itself/);
};


subtest 'recursive user functions restore temporary parameters' => sub {
  my $ini = <<'INI';
rec #= $(1)$(=# rec,$(1))
ok  #= $(1):$(2)

[sec]
1 = original-1
2 = original-2
bad = $(=# rec,x)
good = $(=# ok,a,b)
INI

  my $obj = Config::INI::RefVars->new();

  throws_ok(
    sub { $obj->parse_ini(src => $ini); },
    qr/recursive function '\[__TOCOPY__\]#=rec' calls itself/,
    'recursive function dies',
  );

  my $ini_after = <<'INI';
ok #= $(1):$(2)

[sec]
1 = original-1
2 = original-2
good = $(=# ok,a,b)
check = $(1) and $(2)
INI

  $obj = Config::INI::RefVars->new();
  my $vars = $obj->parse_ini(src => $ini_after)->variables();

  is($vars->{sec}{good}, 'a:b',
     'function still works after recursion error in new object');

  is($vars->{sec}{check}, 'original-1 and original-2',
     'numeric variables are not left polluted');
};


subtest 'function name in variable causes error' => sub {
  throws_ini_like('function name in variables: unknown function',
                  <<'INI',
[sec]
myfunc #= myfunc:$(1)
fn = myfunc
result = $(=# $(fn), foo)
INI
                  qr/unknown function '\$\(fn\)'/
                 );

  throws_ini_like('function name in variables: unknown function',
                  <<'INI',
[sec]
myfunc #= myfunc:$(1)
fn1 = my
fn2 = func
result = $(=# $(fn1)$(fn2), foo)
INI
                  qr/unknown function '\$\(fn1\)\$\(fn2\)'/
                 );
};


#==================================================================================================
done_testing();
