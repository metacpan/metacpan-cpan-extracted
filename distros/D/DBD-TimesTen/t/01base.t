#!perl -w
# $Id: 01base.t 508 2006-11-22 17:06:19Z wagnerch $

use Test::More tests => 5;

require DBI;
require_ok('DBI');

import DBI;
pass("import DBI");

$switch = DBI->internal;
is(ref $switch, 'DBI::dr', "DBI->internal is DBI::dr");

$drh = DBI->install_driver('TimesTen');
is(ref $drh, 'DBI::dr', "Install TimesTen driver OK");

ok($drh->{Version}, "Version is not empty");

exit 0;
