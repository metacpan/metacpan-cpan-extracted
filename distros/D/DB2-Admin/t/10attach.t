#
# Test the attach / detach functions
#
# $Id: 10attach.t,v 150.1 2007/12/12 19:30:25 biersma Exp $
#

use strict;
use Test::More tests => 5;
BEGIN { use_ok('DB2::Admin'); }

DB2::Admin->SetOptions('RaiseError' => 1);
ok(1, "SetOptions");

my $retval = DB2::Admin->Attach();
ok($retval, "Attach");

$retval = DB2::Admin->InquireAttach();
ok($retval, "InquireAttach");

$retval = DB2::Admin->Detach();
ok($retval, "Detach");
