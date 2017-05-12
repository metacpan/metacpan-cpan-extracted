#
# Test the export functions
#
# $Id: 60export.t,v 165.1 2009/02/24 14:47:14 biersma Exp $
#

#
# Get the database/schema/table names from the CONFIG file
#
our %myconfig;
require "util/parse_config";
my $db_name = $myconfig{DBNAME};
my $schema_name = $myconfig{SCHEMA};
my $table_name = $myconfig{SOURCE_TABLE};
my $export_dir = $myconfig{EXPORT_DIRECTORY};

my $columns = undef;

use strict;
use File::Spec;
use Test::More tests => 11;
BEGIN { use_ok('DB2::Admin'); }

die "Environment variable DB2_VERSION not set"
  unless (defined $ENV{DB2_VERSION});

DB2::Admin->SetOptions('RaiseError' => 1);
ok(1, "SetOptions");

my $rc = DB2::Admin->Connect('Database' => $db_name);
ok($rc, "Connect - $db_name");

#
# Create the export, LOB and XML directories
#
mkdir($myconfig{EXPORT_DIRECTORY}, 0755);
mkdir($myconfig{LOB_DIRECTORY}, 0755);
mkdir($myconfig{XML_DIRECTORY}, 0755);

#
# Test export w/o LOBs for DEL and IXF.  We need DEL to load
# into a DPF instance.
#
foreach my $type (qw(DEL IXF)) {
    my $out_file = File::Spec->catfile($export_dir, "export-test.\L$type");
    my $log_file = File::Spec->catfile($export_dir, "export-test.\L$type\E.log");
    $rc = DB2::Admin->Export('Database'     => $db_name,
                             'Schema'       => $schema_name,
                             'Table'        => $table_name,
                             #'FinalClauses' => 'ORDER BY region',
                             'Columns'      => $columns,
                             'OutputFile'   => $out_file,
                             'LogFile'      => $log_file,
                             'FileType'     => $type,
                            );
    ok($rc > 0, "Export of $type w/o LOBs - exported $rc rows");
}

#
# Export with LOBs using a DEL file
#
{
    $table_name = $myconfig{SOURCE_LOB_TABLE};
    my $out_file = File::Spec->catfile($export_dir, "export-test-lob.del");
    my $log_file = File::Spec->catfile($export_dir, "export-test-del-lob.log");
    $rc = DB2::Admin->Export('Database'    => $db_name,
                             'Schema'      => $schema_name,
                             'Table'       => $table_name,
                             'Columns'     => $columns,
                             'OutputFile'  => $out_file,
                             'LogFile'     => $log_file,
                             'FileType'    => 'DEL',
                             'FileOptions' => { 'LobsInFile' => 1, },
                             'LobPath'     => $myconfig{LOB_DIRECTORY},
                             'LobFile'     => 'prefix',
                            );
    ok($rc > 0, "Export of DEL w LOBs - exported $rc rows");
}

#
# Export with XML using an IXF file
#
SKIP: {
    my $version = substr($ENV{DB2_VERSION}, 1); # Vx.y -> x.y
    skip("XML not available in DB2 version < 9.1", 4) if ($version < 9.1);

    $table_name = $myconfig{SOURCE_XML_TABLE};
    foreach my $save (0, 1) {
        foreach my $sep (0, 1) {
            my $out_file = File::Spec->catfile($export_dir, "export-test-xml-$save-$sep.ixf");
            my $log_file = File::Spec->catfile($export_dir, "export-test-ixf-xml-$save-$sep.log");
            $rc = DB2::Admin->
              Export('Database'      => $db_name,
                     'Schema'        => $schema_name,
                     'Table'         => $table_name,
                     'Columns'       => $columns,
                     'OutputFile'    => $out_file,
                     'LogFile'       => $log_file,
                     'FileType'      => 'IXF',
                     'FileOptions'   => { 'XmlInSepFiles' => $sep, },
                     'ExportOptions' => { 'XmlSaveSchema' => $save, },
                     'XmlPath'       => $myconfig{XML_DIRECTORY},
                     'XmlFile'       => "prefix-save=$save-sep=$sep",
                );
            ok($rc > 0, "Export of IXF w XML (XmlSaveSchema=$save, XmlInSepFiles=$sep) - exported $rc rows");
        }
    }
}

$rc = DB2::Admin->Disconnect('Database' => $db_name);
ok($rc, "Disconnect - $db_name");
