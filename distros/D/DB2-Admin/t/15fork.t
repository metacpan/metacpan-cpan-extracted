#
# Test the connect / disconnect functionality across a fork()
#
# $Id: 15fork.t,v 165.1 2009/02/24 14:47:40 biersma Exp $
#

use strict;
use File::Spec;
use Test::More tests => 5;
BEGIN { use_ok('DB2::Admin'); }

#
# Get the database/schema/table names from the CONFIG file
#
our %myconfig;
require "util/parse_config";
my $db_name = $myconfig{DBNAME};
my $schema_name = $myconfig{SCHEMA};
my $table_name = $myconfig{SOURCE_TABLE};
my $export_dir = $myconfig{EXPORT_DIRECTORY};
mkdir($export_dir, 0755);

SKIP: {
    #
    # Windows doesn't have a fork(), and DB2 requires special handling
    # (e.g. sqleAttachToCtx()) for the multi-threading perl uses to
    # emulate fork() on Windows.  Skip the tests on that platform.
    #
    if ($^O =~ /^MSWin/) {
        skip("fork() handling not implemented in DB2::Adminfor Windows", 5);
    }

    my $rc = DB2::Admin->Connect('Database' => $db_name);
    ok($rc, "Connect $db_name (parent)");

    do_something('parent');

    my $pid = fork();
    if ($pid > 0) {                     # This is the parent
        wait();
    } else {                    # This is the child
        $rc = DB2::Admin->Connect('Database' => $db_name);
        ok($rc, "Connect $db_name (child)");

        do_something('child');

        $rc = DB2::Admin->Disconnect('Database' => $db_name);
        ok($rc, "Disconnect $db_name (child)");

        exit(0);
    }

    #
    # Back to parent
    #
    do_something('parent');
    $rc = DB2::Admin->Disconnect('Database' => $db_name);
    ok($rc, "Disconnect $db_name (parent)");
}

# ------------------------------------------------------------------------

sub do_something {
    my ($label) = @_;

    my $out_file = File::Spec->catfile($export_dir, 'export-test.ixf');
    my $log_file = File::Spec->catfile($export_dir, 'export-test.log');
    my $rc = DB2::Admin->Export('Database'   => $db_name,
                                'Schema'     => $schema_name,
                                'Table'      => $table_name,
                                'OutputFile' => $out_file,
                                'LogFile'    => $log_file,
                                'FileType'   => 'IXF',
                                #'FileOptions' => { 'CharDel' => "'",
                                #                   'ColDel'  => '|',
                                #                 },
                            );
    ok($rc > 0, "Export ($label)");
}
