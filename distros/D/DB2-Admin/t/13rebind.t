#
# Test the rebind function
#
# $Id: 13rebind.t,v 150.1 2007/12/12 19:29:01 biersma Exp $
#

use strict;
use Test::More tests => 11;
BEGIN { use_ok('DB2::Admin'); }

#
# Get the database/schema/package names from the CONFIG file
#
our %myconfig;
require "util/parse_config";
my $db_name = $myconfig{DBNAME};
my $schema = $myconfig{REBIND_SCHEMA};
my $package = $myconfig{REBIND_PACKAGE};

DB2::Admin->SetOptions('PrintError' => 1);
ok(1, "SetOptions");

my $retval = DB2::Admin->Connect('Database' => $db_name);
ok($retval, "Connect - $db_name");

$retval = DB2::Admin->Rebind('Database' => $db_name,
			     'Schema'   => $schema,
			     'Package'  => $package,
			    );
ok($retval, "Rebind - $schema.$package - no options");

foreach my $resolve (qw(Any Conservative)) {
    foreach my $reopt (qw(None Once Always)) {
	$retval = DB2::Admin->Rebind('Database' => $db_name,
				     'Schema'   => $schema,
				     'Package'  => $package,
				     'Options'  => { Resolve => $resolve,
						     ReOpt   => $reopt,
						   },
				    );
	ok($retval, "Rebind - $schema.$package - resolve $resolve, reopt $reopt");
    }
}

$retval = DB2::Admin->Disconnect('Database' => $db_name);
ok($retval, "Disconnect - $db_name");
