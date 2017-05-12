#!perl

use strict;
use lib qw(lib);
use My::Util qw(mod_perl_version);
use Test::More tests => 1;

if (mod_perl_version() == 2) {
    use_ok('Apache2::AuthTicket');
}
else {
    use_ok('Apache::AuthTicket');
}
