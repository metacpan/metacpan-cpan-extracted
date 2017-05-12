use Test;
BEGIN { plan tests => 5};

require DBI;
ok(1);

import DBI;
ok(1);

$switch = DBI->internal;
ok(ref $switch eq 'DBI::dr');

$drh = DBI->install_driver('mysqlPP');
ok(ref $drh eq 'DBI::dr');

ok($drh->{Version});
