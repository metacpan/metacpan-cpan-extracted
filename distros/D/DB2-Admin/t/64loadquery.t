#
# Test the load query functions (V8.2 only)
#
# $Id: 64loadquery.t,v 165.3 2009/04/22 13:46:20 biersma Exp $
#

#
# Get the database/schema/table names from the CONFIG file
#
our %myconfig;
require "util/parse_config";
my $db_name = $myconfig{DBNAME};
my $schema_name = $myconfig{SCHEMA};
my $table_name = $myconfig{TARGET_TABLE};
my $export_dir = $myconfig{EXPORT_DIRECTORY};

use strict;
use Data::Dumper;
use File::Spec;
use Test::More tests => 5;
BEGIN { use_ok('DB2::Admin'); }

die "Environment variable DB2_VERSION not set"
  unless (defined $ENV{DB2_VERSION});

DB2::Admin->SetOptions('RaiseError' => 1);
ok(1, "SetOptions");

my $rc = DB2::Admin->Connect('Database' => $db_name);
ok($rc, "Connect - $db_name");

my $logfile = File::Spec->catfile($export_dir, 'loadquery-test.log');
unlink($logfile);
my $results = DB2::Admin->LoadQuery('Schema'   => $schema_name,
				    'Table'    => $table_name,
				    'LogFile'  => $logfile,
				    'Messages' => 'All',
				   );
ok(defined $results, "LoadQuery succeeded");
#print STDERR Dumper($results);

$rc = DB2::Admin->Disconnect('Database' => $db_name);
ok($rc, "Disconnect - $db_name");
