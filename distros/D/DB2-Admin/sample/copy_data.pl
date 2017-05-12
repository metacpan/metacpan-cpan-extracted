#!/usr/bin/perl
#
# $Id: copy_data.pl,v 145.1 2007/08/06 18:50:50 biersma Exp $
#

use strict;
use DB2::Admin;
use Data::Dumper;

#
# Specify source and target database name
#
my $src_db = 'sample';
my $tgt_db = 'bdrplay2';

#
# Schema and table anme.  These may differ for source and target
# databases, as long as the structure is compatible.
#
my $schema = 'BIERSMA';
my $table = 'EMP_PHOTO';

#
# Directory for temporary data.  Also used for error log files.
#
my $export_dir = "/var/tmp";

#
# We use Kerberos, so empty userid and password.  YMMV.
#
my ($userid, $passwd) = ('', '');

#
# Trhow an exception on error
#
DB2::Admin->SetOptions('RaiseError' => 1);

#
# Export and Load require a database connection exists
#
DB2::Admin->Connect('Database' => $src_db,
		    'Userid'   => $userid,
		    'Password' => $passwd);

DB2::Admin->Connect('Database' => $tgt_db,
		    'Userid'   => $userid,
		    'Password' => $passwd);

#
# Export with LOBs using a DEL file
#
my $rows = DB2::Admin->Export('Database'    => $src_db,
				 'Schema'      => $schema,
				 'Table'       => $table,
				 'OutputFile'  => "$export_dir/$table.del",
				 'LogFile'     => "$export_dir/export.log",
				 'FileType'    => 'DEL',
				 'FileOptions' => { 'LobsInFile' => 1, },
				 'LobPath'     => $export_dir,
				 'LobFile'     => 'lob-prefix',
				);
print "Exported $rows rows\n";

#
# Load the data back in.  We specify the 'nonrecoverable' parameter
# but you'd better specify the 'CopyDirectory' parameter in real life,
# or take a backup as soon as the loads complete.
#
my $rc = DB2::Admin::->Load('Database'      => $tgt_db,
			   'Schema'        => $schema,
			   'Table'         => $table,
			   'InputFile'     => "$export_dir/$table.del",
			   'LogFile'       => "$export_dir/load.log",
			   'FileOptions'   => { 'LobsInFile' => 1, },
			   'SourceType'    => 'DEL',
			   'Operation'     => 'Replace',
			   #'CopyDirectory' => "/stable/path/on/server",
			   'LobPath'       => $export_dir,
			   'LoadOptions'   => { #'SaveCount'      => 10,
					       'NonRecoverable' => 1,
					       #'RowCount'       => 20,
					      },
			  );
print "Load results: ", Dumper($rc);

