# t/14-function-call-errors.t
use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;

use lib 't';
use Local::Test::RefVars qw(throws_ini_like);


subtest 'empty function call dies' => sub {
  throws_ini_like('parse_ini dies for empty function call',
                  <<'INI',
[paths]
bad := $(=&)
INI
                  qr/empty function call/
                 );
};

subtest 'blank function call dies' => sub {
  throws_ini_like('parse_ini dies for blank function call',
                  <<'INI',
[paths]
bad := $(=&   )
INI
                  qr/empty function call/
                 );
};


subtest 'unterminated function call dies' => sub {
  throws_ini_like('parse_ini dies for unterminated function call',
                  <<'INI',
[paths]
bad := $(=& catdir, foo, bar
INI
                  qr/unterminated variable reference/
                 );
};


subtest 'unterminated nested function call dies' => sub {
  throws_ini_like('parse_ini dies for unterminated nested function call',
                  <<'INI',
[paths]
bad := $(=& catfile, $(=& catdir, foo, bar), $(=& catdir, x, y)
INI
                  qr/unterminated variable reference/
                 );
};


#==================================================================================================
done_testing();
