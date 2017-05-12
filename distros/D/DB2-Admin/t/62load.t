#
# Test the load functions (V8.2 only)
#
# $Id: 62load.t,v 165.3 2009/04/22 13:46:24 biersma Exp $
#

use strict;
#
# Get the database/schema/table names from the CONFIG file
#
our %myconfig;
require "util/parse_config";
my $db_name = $myconfig{DBNAME};
my $schema_name = $myconfig{SCHEMA};
my $table_name = $myconfig{TARGET_TABLE};
my $lob_table_name = $myconfig{TARGET_LOB_TABLE};
my $ex_table_name = $myconfig{EXCEPTION_TABLE};
my $export_dir = $myconfig{EXPORT_DIRECTORY};

use strict;
use Data::Dumper;
use File::Spec;
use Test::More tests => 21;
BEGIN { use_ok('DB2::Admin'); }

die "Environment variable DB2_VERSION not set"
  unless (defined $ENV{DB2_VERSION});

SKIP: {
    my $version = substr($ENV{DB2_VERSION}, 1); # Vx.y -> x.y

    DB2::Admin->SetOptions('RaiseError' => 1);
    ok(1, "SetOptions");

    my $rc = DB2::Admin->Connect('Database' => $db_name);
    ok($rc, "Connect - $db_name");

    my $in_file = File::Spec->catfile($export_dir, "export-test.del");
    my $log_file = File::Spec->catfile($export_dir, "load-test.log");
    unlink($log_file);

    #
    # Test DEL file without LOBs
    #
    my %load_params =
      ('Database'      => $db_name,
       'Schema'        => $schema_name,
       'Table'         => $table_name,
       #'TargetColumns' => [ qw(SALES_PERSON SALES_DATE) ],
       #'InputColumns'  => [ 2, 1 ],
       #'InputFile'     => $data_file,
       'InputFile'     => $in_file,
       #'InputStatement' => 'SELECT sales_date, sales_person FROM SALES',
       'LogFile'       => $log_file,
#       'FileOptions'   => { 'CharDel'           => "'",
#                           'ColDel'            => '|',
#                           'DumpFile'          => '/tmp/dump_file',
#                           'DumpFileAccessAll' => 1,
#                           'NoRowWarnings'     => 1,
#                         },
       #'FileLocation'  => 'Server',
       'SourceType'    => 'DEL',
       #'Operation'     => 'Insert',
       'Operation'     => 'Replace',
       #'CopyDirectory' => $myconfig{LOAD_COPY_DIRECTORY},,
       'LoadOptions'   => { #'SaveCount'      => 10,
                           'NonRecoverable' => 1,
                           #'RowCount'       => 20,
                          },
       #'TempFilesPath' => '/var/tmp',
       #'TempFilesPath' => '/does/not/exist', # Test failure
#       'DPFOptions' => { 'PortRange'              => [ 6000, 7000 ],
#                        'PartitioningDBPartNums' => [ 1, 2 ],
#                        'Trace'                  => 5,
#                        'MaxNumPartAgents'       => 5,
#                      },
       'DPFOptions'   => {},
      );

    my ($results, $rc2) = DB2::Admin->Load(%load_params);
    ok(defined $results, "Load succeeded - DEL file w/o LOBs");
    #print STDERR Dumper($results);
    #print STDERR Dumper($rc2);

    #
    # Test array of IXF files without LOBs
    #
    my @infile_list = ($in_file);
    foreach my $postfix (qw(2 3 4)) {
        my $clone_file = $in_file . $postfix;
        if ($^O =~ /^MSWin/) {
            system("copy", $in_file, $clone_file);
        } else {
            system("cp", $in_file, $clone_file);
        }
        push @infile_list, $clone_file;
    }
    $load_params{InputFile} = \@infile_list;
    $load_params{FileLocation}  = 'Client';
    $load_params{LogFile} = File::Spec->catfile($export_dir, "load-test-multiple.log");
    ($results, $rc2) = DB2::Admin->Load(%load_params);
    ok(defined $results, "Load succeeded - multiple DEL files w/o LOBs");
    #print STDERR Dumper($results);
    #print STDERR Dumper($rc2);

    #
    # Test with exception table
    $results = DB2::Admin->Load(%load_params,
                            'Operation'       => 'Insert',
                            'ExceptionSchema' => $schema_name,
                            'ExceptionTable'  => $ex_table_name,
                           );
    #print STDERR Dumper($results);
    ok(defined $results, "Load with exception table succeeded");

    #
    # Test DEL file with LOBs
    #
    $in_file = File::Spec->catfile($export_dir, "export-test-lob.del");
    $log_file = File::Spec->catfile($export_dir, "load-test-lob.log");
    %load_params =
      ('Database'      => $db_name,
       'Schema'        => $schema_name,
       'Table'         => $lob_table_name,
       'InputFile'     => $in_file,
       'LogFile'       => $log_file,
       'FileOptions'   => { 'LobsInFile' => 1, },
       'SourceType'    => 'DEL',
       'Operation'     => 'Replace',
       #'CopyDirectory' => $myconfig{LOAD_COPY_DIRECTORY},
       'LobPath'       => $myconfig{LOB_DIRECTORY},
       'LoadOptions'   => { #'SaveCount'      => 10,
                           'NonRecoverable' => 1,
                           #'RowCount'       => 20,
                          },
      );
    #print Dumper(\%load_params);
    $results = DB2::Admin->Load(%load_params);
    ok(defined $results, "Load succeeded - DEL file w LOBs");
    #print STDERR Dumper($results);

    #
    # Test a load from a SQL statement (load from cursor)
    #
    $results = DB2::Admin->
      Load('Database'       => $db_name,
           'Schema'         => $schema_name,
           'Table'          => $table_name,
           'SourceType'     => 'Statement',
           'LoadOptions'    => { 'NonRecoverable' => 1, },
           'Operation'      => 'Replace',
           'InputStatement' => "select * from $schema_name.$myconfig{SOURCE_TABLE}",
          );
    ok(defined $results, "Load succeeded - SQL statement");
    #print Dumper($results);


    skip("Load XML not available in DB2 version < 9.5", 12) if ($version < 9.5);

    $table_name = $myconfig{TARGET_XML_TABLE};
    foreach my $save (0, 1) {
        foreach my $sep (0, 1) {
            foreach my $xml_parse (undef, 'Strip', 'Preserve') {
                $in_file = File::Spec->catfile($export_dir, "export-test-xml-$save-$sep.ixf");
                $log_file = File::Spec->catfile($export_dir, "import-test-xml-$save-$sep.log");
                my $load_options = { 'NonRecoverable' => 1, };
                if (defined $xml_parse) {
                    $load_options->{XmlParse} = $xml_parse;
                }

                $results = DB2::Admin->
                  Load('Database'      => $db_name,
                       'Schema'        => $schema_name,
                       'Table'         => $table_name,
                       'InputFile'     => $in_file,
                       'LogFile'       => $log_file,
                       'SourceType'    => 'IXF',
                       'Operation'     => 'Replace',
                       'LoadOptions'   => $load_options,
                       'XmlPath'       => $myconfig{XML_DIRECTORY},
                      );
                my $parse = $xml_parse || '<undef>';
                ok(defined $results, "Load succeeded - IXF with XML (save=$save, sep=$sep, parse=$parse)");
                #print STDERR Dumper($results);
            }                   # End foreach: XmlParse option
        }                       # End foreach: sep
    }                           # End foreach: save

    $rc = DB2::Admin->Disconnect('Database' => $db_name);
    ok($rc, "Disconnect - $db_name");
}                               # End SKIP
