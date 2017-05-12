#
# Test the configuration functions
#
# $Id: 40cfg.t,v 165.2 2009/04/22 13:46:32 biersma Exp $
#

use strict;
use Data::Dumper;
use Test::More tests => 12;
BEGIN { use_ok('DB2::Admin'); }

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
my $update_dbase_cfg = $myconfig{UPDATE_DATABASE_CONFIG};

DB2::Admin->SetOptions('RaiseError' => 1);
ok(1, "SetOptions");

my $retval = DB2::Admin->Attach();
ok ($retval, "Attach");

SKIP: {
    my @all_params;
    while (my ($param, $info) = each %{ $DB2::Admin::Constants::config_params} ) {
        next unless ($info->{Domain} eq 'Manager');
        next unless (DB2::Admin::Constants::->GetInfo($param));
        push @all_params, $info->{Name};
    }
    #print "Inquiring DBM cfg params [@all_params]\n";

    my @retval = DB2::Admin::->
      GetDbmConfig('Param' => \@all_params,
                   'Flag'  => 'Immediate');
    ok(scalar(@retval), "GetDbmConfig - all params");
    #print Dumper(\@retval);

    skip ("Do not set DBM config", 2) unless ($update_dbm_cfg);

    @retval = DB2::Admin::->
      GetDbmConfig('Param' => [ qw(jdk11_path intra_parallel) ],
                   'Flag'  => 'Immediate');
    ok(scalar(@retval), "GetDbmConfig - selected params");

    my $rc = DB2::Admin::->
      UpdateDbmConfig('Param' => [ { 'Name'  => 'jdk11_path',
                                     'Value' => $retval[0]{Value},
                                   },
                                   { 'Name'  => 'intra_parallel',
                                     'Value' => $retval[1]{Value},
                                   },
                                 ],
                      'Flag'  => 'Delayed');
    ok($rc, "UpdateDbmConfig");
}

SKIP: {
    my @all_params;
    while (my ($param, $info) = each %{ $DB2::Admin::Constants::config_params} ) {
        next unless ($info->{Domain} eq 'Database');
        next unless (DB2::Admin::Constants::->GetInfo($param));
        push @all_params, $info->{Name};
    }
    #print "Inquiring DB cfg params [@all_params]\n";

    #
    # Get delayed database config (no db connection required)
    #
    my @retval = DB2::Admin::->
      GetDatabaseConfig('Param'    => \@all_params,
                        'Flag'     => 'Delayed',
                        'Database' => $db_name);
    ok(scalar(@retval), "GetDatabaseConfig - all params - delayed");

    #
    # We must connect to a database to get the immediate values
    #
    my $rc = DB2::Admin::->Connect('Database' => $db_name);
    ok($rc, "Connect to $db_name");

    @retval = DB2::Admin::->
      GetDatabaseConfig('Param'    => \@all_params,
                        'Flag'     => 'Immediate',
                        'Database' => $db_name);
    ok(scalar(@retval), "GetDatabaseConfig - all params - immediate");

    #
    # Disconnect again
    #
    $rc = DB2::Admin::->Disconnect('Database' => $db_name);
    ok($rc, "Disconnect from $db_name");

    skip ("Do not set database config", 2) unless ($update_dbase_cfg);

    @retval = DB2::Admin::->
      GetDatabaseConfig('Param'    => [ qw(newlogpath dbheap) ],
                        'Flag'     => 'Delayed',
                        'Database' => $db_name);
    ok(scalar(@retval), "GetDatabaseConfig - selected params - delayed");

    $rc = DB2::Admin::->
      UpdateDatabaseConfig('Param'    => [ { 'Name'  => 'newlogpath',
                                             'Value' => $retval[0]{Value},
                                           },
                                           { 'Name'  => 'dbheap',
                                             'Value' => $retval[1]{Value},
                                           },
                                         ],
                           'Flag'     => 'Delayed',
                           'Database' => $db_name,
                          );
    ok($rc, "UpdateDatabaseConfig - delayed");
}
