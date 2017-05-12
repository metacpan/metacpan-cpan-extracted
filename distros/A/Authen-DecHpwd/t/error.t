use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok "Authen::DecHpwd", qw(lgi_hpwd UAI_C_PURDY); }

eval { lgi_hpwd("foo\x{100}bar", "foobar", UAI_C_PURDY, 123); };
like $@, qr/\Ainput must contain only octets\b/;

eval { lgi_hpwd("foobar", "foo\x{100}bar", UAI_C_PURDY, 123); };
like $@, qr/\Ainput must contain only octets\b/;

1;
