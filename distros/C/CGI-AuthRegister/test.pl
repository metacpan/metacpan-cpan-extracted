# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#########################

use Test;
BEGIN { plan tests => 1 };
use CGI::AuthRegister;
ok(1);				# made this far
