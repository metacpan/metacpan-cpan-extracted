# vim: ft=perl
use Test::More tests => 3;
# $Id: dbd-multi.t,v 1.2 2006/02/10 18:47:47 wright Exp $
use strict;
$^W = 1;

use_ok 'DBD::Multi';
can_ok 'DBD::Multi', 'driver';
isa_ok DBD::Multi->driver, 'DBI::dr';
