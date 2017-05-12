#
# Test the get/set monitor switches functions
#
# $Id: 20monitor_switches.t,v 150.1 2007/12/12 19:29:50 biersma Exp $
#

use strict;
use Test::More tests => 5;
BEGIN { use_ok('DB2::Admin'); }

DB2::Admin->SetOptions('RaiseError' => 1);
ok(1, "SetOptions");

my $retval = DB2::Admin->Attach();
ok($retval, "Attach");

$retval = DB2::Admin->GetMonitorSwitches();
ok($retval, "GetMonitorSwitches");

$retval = DB2::Admin->SetMonitorSwitches(Switches => {'Table' => 0,
						      'Sort'  => 0,
						     },
					);
ok($retval, "SetMonitorSwitches");
