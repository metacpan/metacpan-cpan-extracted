#
# Test 'list utilities' function (which uses the snapshot API)
#
# $Id: 31listutil.t,v 160.1 2008/05/29 19:12:31 biersma Exp $
#

use strict;
use Test::More tests => 5;
BEGIN { use_ok('DB2::Admin'); }

DB2::Admin->SetOptions('RaiseError' => 1);
ok(1, "SetOptions");

my $retval = DB2::Admin->Attach();
ok($retval, "Attach");

my @utils = DB2::Admin->ListUtilities();
ok(1, "List Utilities");

$retval = DB2::Admin->Detach();
ok($retval, "Detach");
