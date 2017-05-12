use Test::More;
plan tests => 2;

use_ok(qq(Acme::Test::Weather));

diag("\nDo you really want me to install this package only if it's not raining?");

ok(1);

# $Id: use.t,v 1.2 2003/02/20 23:42:37 asc Exp $
