use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 't';

use Local::Test::RefVars qw(throws_ini_like ini_exception);

subtest 'substr needs 2 or 3 arguments' => sub {
  throws_ini_like('substr with 0 args dies',
                  <<'INI',
[sec]
x := $(=& substr)
INI
                  qr/\bsubstr: expected 2 or 3 arguments\b/);

  throws_ini_like('substr with 1 arg dies',
                  <<'INI',
[sec]
x := $(=& substr, abcdef)
INI
                  qr/\bsubstr: expected 2 or 3 arguments\b/);

  throws_ini_like('substr with 4 args dies',
                  <<'INI',
[sec]
x := $(=& substr, abcdef, 1, 2, 3)
INI
                  qr/\bsubstr: expected 2 or 3 arguments\b/);
};


subtest 'substr numeric warnings are converted to clean errors' => sub {
  my $err = ini_exception(<<'INI');
[sec]
x := $(=& substr, abcdef, a)
INI

  like($err, qr/^substr: .*isn't numeric in substr/,
       'offset warning converted to substr error');

  unlike($err, qr/\sat\s+\S+\s+line\s+\d+/, 'offset error has no file/line tail');

  $err = ini_exception(<<'INI');
[sec]
x := $(=& substr, abcdef, 1, b)
INI

  like($err, qr/^substr: .*isn't numeric in substr/, 'length warning converted to substr error');
  unlike($err, qr/\sat\s+\S+\s+line\s+\d+/, 'length error has no file/line tail');
};


#==================================================================================================
done_testing();
