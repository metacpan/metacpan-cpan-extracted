#
# Test the get/set client information functions
#
# $Id: 17client_info.t,v 150.1 2007/12/12 19:30:07 biersma Exp $
#

use strict;
use Test::More tests => 9;
#use Test::Differences;

#
# Get the database name from the CONFIG file
#
our %myconfig;
require "util/parse_config";
my $db_name = $myconfig{DBNAME};

$| = 1;

BEGIN { use_ok('DB2::Admin'); }

DB2::Admin->SetOptions('RaiseError' => 1);
ok(1, "SetOptions");

my $retval = DB2::Admin->Connect('Database' => $db_name);
ok($retval, "Connect - $db_name");

#
# Get client information (expect nothing)
#
my %rc = DB2::Admin->ClientInfo('Database' => $db_name);
ok(1, "ClientInfo - get 1 - $db_name");
#print Dumper($rc);

#
# Set client information
#
my %cinfo = ( ClientUserid     => 'User Name',
	      Workstation      => 'Desktop',
	      Application      => 'Test Suite',
	      AccountingString => 'Text used for accounting',
	    );
%rc = DB2::Admin->ClientInfo('Database' => $db_name, %cinfo);
ok((keys %rc), "ClientInfo - set - $db_name");
#print Dumper($rc);
ok(eq_hash(\%rc, \%cinfo), "ClientInfo - return value matches input");

#
# Get client information (expect data_
#
%rc = DB2::Admin->ClientInfo('Database' => $db_name);
ok((keys %rc), "ClientInfo - get 2 - $db_name");
ok(eq_hash(\%rc, \%cinfo), "ClientInfo - return value matches input");

$retval = DB2::Admin->Disconnect('Database' => $db_name);
ok($retval, "Disconnect - $db_name");
