#
# Tests of the low-level raw API
#
# $Id: 01lowlevel.t,v 165.2 2009/04/22 13:46:35 biersma Exp $
#

use strict;
use Test::More tests => 28;
#use Test::Differences;
use Data::Dumper;
BEGIN { use_ok('DB2::Admin'); }
BEGIN { use_ok('DB2::Admin::Constants') };

die "Environment variable DB2_VERSION not set" 
  unless (defined $ENV{DB2_VERSION});

#
# Get the database name and whether to update the dbm cfg from the
# CONFIG file
#
our %myconfig;
require "util/parse_config";
my $db_name = $myconfig{DBNAME};
my $update_dbm_cfg = $myconfig{UPDATE_DBM_CONFIG};

$| = 1;

#
# Lookup two constants
#
my $version = DB2::Admin::Constants::->GetValue('SQLM_CURRENT_VERSION');
ok($version, "constant for current_version ($version)");
my $node = DB2::Admin::Constants::->GetValue('SQLM_CURRENT_NODE');
ok($node, "constant for current_node ($node)");

#
# Attach
#
my $data = DB2::Admin::sqleatin($ENV{DB2INSTANCE}, '', '');
ok($data, "sqletain - attach");

#
# InquireAttach
#
$data = DB2::Admin::sqleatin('', '', '');
ok($data, "sqleatin - inquire");

#
# Get Monitor Switches
#
DB2::Admin::db2MonitorSwitches({}, $version, $node) || 
  do {
      diag("Error with sqlcode ", DB2::Admin::sqlcode() .
           " and error message ", DB2::Admin::sqlaintp(), "\n");
      fail("db2MonitorSwitches");
      exit(1);
  };
pass("db2MonitorSwitches - inquire");

#
# Set Monitor Switches
#
my $rc = DB2::Admin::db2MonitorSwitches({ Table => 1 }, $version, $node);
ok($rc, "db2MonitorSwitches - set");

#
# Reset Monitor
#
$rc = DB2::Admin::db2ResetMonitor(1, '', $version, $node);
ok($rc, "db2ResetMonitor");

my $list_apps = DB2::Admin::Constants::->GetValue('SQLMA_APPLINFO_ALL');
ok($list_apps, "constant for list_applinfo_all");

#
# We don't lookup SQLM_CLASS_DEFAULT, as it is new with DB2 V8
#
#my $class_dft = DB2::Admin::Constants::->GetValue('SQLM_CLASS_DEFAULT');
my $class_dft = 0 ; 
$rc = DB2::Admin::db2GetSnapshotSize([ $list_apps ], $version, $node, $class_dft);
ok($rc, "db2GetSnapshotSize");

#
# Get Snapshot
#
$data = DB2::Admin::db2GetSnapshot([ $list_apps ], $version, $node, $class_dft,
                               16384, 16384, 0);
if (defined $data) {
    pass("db2GetSnapshot");
} else {
    diag ("Error with sqlcode ", DB2::Admin::sqlcode(),
          " and error message ", DB2::Admin::sqlaintp(), "\n");
    fail("db2GetSnapshot");
}

#
# Get database manager configuration
#
SKIP: {
    my $version = substr($ENV{DB2_VERSION}, 1); # Vx.y -> x.y
    my $retval = DB2::Admin::db2CfgGet( [ { Token => 311, Size => 255 } ],
                                    { Manager => 1, Immediate => 1 }, 
                                    '', 
                                    $version);
    ok($retval, "db2CfgGet");

    #
    # Changing the DBM cfg is conditional on a CONFIG parameter
    #
    skip ("Do not set DBM config", 1) unless ($update_dbm_cfg);

    my $cur_value = $retval->[0]{Value};
    $rc = DB2::Admin::db2CfgSet( [ { Token => 311, Value => $cur_value } ],
                             { Manager => 1, Delayed => 1 },
                             '', $version);
    ok($rc, "db2CfgSet");
}


#
# List database directory
#
my $db_dir = DB2::Admin::db2DatabaseDirectory('');
ok($db_dir, "db2DatabaseDirectory");

#
# List node directory
# SQL code -1027: node directory empty
#
my $node_dir = DB2::Admin::db2NodeDirectory();
ok((DB2::Admin::sqlcode() == 0 || DB2::Admin::sqlcode() == -1027), "db2NodeDirectory");

#
# List DCS directory
# SQL code 1312: DCS directory empty
#
my $dcs_dir = DB2::Admin::db2DCSDirectory();
ok((DB2::Admin::sqlcode() == 0 || DB2::Admin::sqlcode() == 1312 ), "db2DCSDirectory");

#
# Detach
#
$rc = DB2::Admin::sqledtin();
ok($rc, "sqledtin - detach");

#
# Connect to database
#
$rc = DB2::Admin::db_connect($db_name, '', '', {});
ok($rc, "db_connect - $db_name");

#
# Get client information
#
$rc = DB2::Admin::db2ClientInfo($db_name, {});
ok($rc, "db2ClientInfo - get - $db_name");
#print Dumper($rc);

#
# Set client information
#
my $cinfo = { ClientUserid     => 'User Name',
              Workstation      => 'Desktop',
              Application      => 'Test Suite',
              AccountingString => 'Text used for accounting',
            };
$rc = DB2::Admin::db2ClientInfo($db_name, $cinfo);
ok($rc, "db2ClientInfo - set - $db_name");
#print Dumper($rc);
ok(eq_hash($rc, $cinfo), "db2ClientInfo - return value matches input");

#
# Disconnect from database
#
$rc = DB2::Admin::db_disconnect($db_name);
ok($rc, "db_disconnect - $db_name");

#
# Cleanup connections (a no-op)
#
DB2::Admin::cleanup_connections();
ok(1, "cleanup_connections");

#
# We're not doing import/export/load tests in this low-level suite
#

#
# The 'list history' command.  This is slow, so limit to 'backup'.
#
$rc = DB2::Admin::db2ListHistory($db_name, 'Load', '', '');
ok(defined $rc, "db2ListHistory - $db_name Load");

#
# Extract SQL code
#
DB2::Admin::sqlcode();
pass("sqlcode");

#
# Format error message
#
my $err_msg = DB2::Admin::sqlaintp();
pass("sqlaintp (format error message)");

#
# Format SQL state message
#
my $state_msg = DB2::Admin::sqlogstt();
pass("sqlogstt (format SQL state message)");
