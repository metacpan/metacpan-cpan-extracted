#
# Test the 'List History' functions
#
# $Id: 63history.t,v 145.1 2007/10/17 14:42:27 biersma Exp $
#

use strict;
use Data::Dumper;
use Test::More tests => 4;
BEGIN { use_ok('DB2::Admin'); }

#
# Get the database name from the CONFIG file
#
our %myconfig;
require "util/parse_config";
my $db_name = $myconfig{DBNAME};

our @history;

DB2::Admin->SetOptions('RaiseError' => 1);
ok(1, "SetOptions");

@history = DB2::Admin->ListHistory('Database' => $db_name,
			       #'ObjectName' => 'BIERSMA.VIEW1',
			       'Action'   => 'Load',
			      );
ok(1, "ListHistory - Load");

@history = DB2::Admin->ListHistory('Database' => $db_name,
			       #'StartTime' => '200502',
			       'Action'   => 'Backup',
			      );
ok(1, "ListHistory - Backup");
