#
# Test the backup functions
#
# $Id: 70backup.t,v 165.2 2009/02/24 14:46:03 biersma Exp $
#

#
# Get the database/schema/table names from the CONFIG file
#
our %myconfig;
require "util/parse_config";
my $db_name = $myconfig{DBNAME};

use strict;
use Data::Dumper;
use Test::More tests => 8;
BEGIN { use_ok('DB2::Admin'); }

die "Environment variable DB2_VERSION not set"
  unless (defined $ENV{DB2_VERSION});

#DB2::Admin->SetOptions('RaiseError' => 1);
#ok(1, "SetOptions");

#
# NOTE: this sets the null device based on the client platform.  For
# tests with DB2::Admin run on the database server, that's always
# correct; but if the client is Windows with the server on Unix, well
# you'll have to pick it manually ;-)
#
my $null_device = ($^O =~ /^MSWin/ ? 'nul:' : '/dev/null');


my $trackmod = 0;
{
    my @retval = DB2::Admin::->
      GetDatabaseConfig('Param'    => [ qw(trackmod) ],
                        'Flag'     => 'Delayed',
                        'Database' => $db_name);
    #print Dumper(\@retval);
    if ($retval[0]{Value}) {
        $trackmod = 1;
    }
    ok(1, "Get database config for trackmod");
}

#
# Start with a full offline backup to /dev/null.  If the "create test
# database" script was used, this will allow us to do
# online/incremental backups below.
#
my $rc = DB2::Admin->Backup('Database' => $db_name,
                            'Target'   => $null_device,
                            'Options'  => { 'Type'   => 'Full',
                                            'Online' => 0,
                                          },
                           );
ok(1, "Backup - whole database - Full, Off-line");

#
# Do full, incremental and delta backup to /dev/null
# Only try incremental/delta if trackmod set
#
SKIP: {
    foreach my $type (qw(Full Incremental Delta)) {
        unless ($type eq 'Full' || $trackmod) {
            skip("Skip $type backup as trackmod not set", 2);
        }

        my $rc = DB2::Admin->Backup('Database' => $db_name,
                                    'Target'   => $null_device,
                                    'Options'  => { 'Type'   => $type,
                                                    'Online' => 1,
                                                  },
                                   );
        ok(1, "Backup - whole database - $type");
        #print Dumper($rc);
    }
}

#
# Do a backup with a christmas tree of options
#
if (1) {
    my $options = { 'Type'           => 'Full',
                    'Action'         => 'ParamCheckOnly',
                    'Online'         => 1,
                    'Compress'       => 0,
                    'IncludeLogs'    => 1,
                    'ImpactPriority' => 75,
                    #'Parallelism'    => 8, # Conflicts with ParamCheckOnly
                    'NumBuffers'     => 64,
                    'BufferSize'     => 16,
                    #'Nodes'          => [ 2 ],
                  };
    my $rc = DB2::Admin->Backup('Database' => $db_name,
                                'Target'   => $null_device,
                                'Options'  => $options,
                               );
    ok(1, "Backup - parameter check only - many options");
    #print Dumper($rc);
}


#
# DPF test ('Nodes' option works on non-DPF, but it requires V9.5)
#
SKIP: {
    my $version = substr($ENV{DB2_VERSION}, 1); # Vx.y -> x.y
    skip("DPF backup not available in DB2 version < 9.5", 1)
      if ($version < 9.5);

    my $rc = DB2::Admin->Backup('Database' => $db_name,
                                #'Target'   => [ '/tmp/bogus', '/tmp/b' ],
                                'Target'   => $null_device,
                                'Options'  =>  { Online   => 1,
                                                 #Action   => 'ParamCheckOnly',
                                                 Compress => 1,
                                                 Nodes    => 'All',
                                               },
                               );
    ok(1, "Backup - DPF case");
    #print Dumper($rc);
}
