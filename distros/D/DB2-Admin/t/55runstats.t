#
# Test the 'runstats' function
#
# $Id: 55runstats.t,v 165.2 2009/04/22 13:46:28 biersma Exp $
#

#
# Get the database name, table nme and schema name from the CONFIG file
#
our %myconfig;
require "util/parse_config";
my $db_name = $myconfig{DBNAME};
my $schema_name = $myconfig{SCHEMA};
my $table_name = $myconfig{SOURCE_TABLE};

use strict;
use Test::More tests => 6;
BEGIN { use_ok('DB2::Admin'); }

die "Environment variable DB2_VERSION not set"
  unless (defined $ENV{DB2_VERSION});

$| = 1;

my $rc = DB2::Admin->SetOptions('RaiseError' => 1);
ok ($rc, "SetOptions");

$rc = DB2::Admin->Connect('Database' => $db_name);
ok($rc, "Connect - $db_name");

#
# Most basic
#
$rc = DB2::Admin::->Runstats('Database' => $db_name,
                             'Schema'   => $schema_name,
                             'Table'    => $table_name,
                            );
ok($rc, "Runstats - basic");

#
# Options
#
$rc = DB2::Admin::->Runstats('Database' => $db_name,
                             'Schema'   => $schema_name,
                             'Table'    => $table_name,
                             #'Columns'  => { 'SALES_person' => 1,
                        #                    'SALES_DATE'   => 1,
                        #                    'BoGus'        => 0,
                        #                    'REGION'       => { 'LikeStatistics' => 1 },
                        #                  },
                             'Options'  => { 'AllColumns'      => 1,
                                             'AllIndexes'      => 1,
                                             'DetailedIndexes' => 1,
                                             'ReadAccess'      => 1,
                                             'SetProfile'      => 1,
                                           },
                            );
ok($rc, "Runstats - with options");

$rc = DB2::Admin->Disconnect('Database' => $db_name);
ok($rc, "Disconnect - $db_name");
