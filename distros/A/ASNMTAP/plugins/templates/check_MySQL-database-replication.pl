#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_MySQL-database-replication.pl
# ----------------------------------------------------------------------------------------------------------
# A monitor to determine if a MySQL database server is operational
#
# To ensure that your SQL server is responding on the proper port, this 
# attempts to connect and test the database on a given database server.
#
# This monitor requires the perl5 DBI, and DBD::mysql modules, available from CPAN
# ----------------------------------------------------------------------------------------------------------
#   mysql> GRANT SELECT SHOW DATABASE ON asnmtap.* TO asnmtap@hostname;
# or when -C T
#   mysql> GRANT SELECT SHOW DATABASE, REPLICATION SLAVE, REPLICATION CLIENT, SUPER ON asnmtap.* TO asnmtap@hostname-server;
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Date::Calc qw(Delta_DHMS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_MySQL-database-replication.pl',
  _programDescription => "MySQL database replication plugin template for the '$APPLICATION'",
  _programVersion     => '3.002.003',
  _programUsagePrefix => '-w|--warning=<warning> -c|--critical=<critical> [-1|--database=<database>] [-2|--binlog=<binlog>] [-3|--table=<table>] [-4|--cluster=<cluster>]',
  _programHelpPrefix  => '-w, --warning=<WARNING>
   <WARNING> = last \'Update Time from Table\' seconds ago
-c, --critical=<CRITICAL>
   <CRITICAL> = last \'Update Time from Table\' seconds ago
-1, --database = <database> (default: asnmtap)
-2, --binlog   = <binlog>   (default: asnmtap)
-3, --table    = <table>    (default: events)
-4, --cluster  = S|M
   S(lave) : check slave replication on
   M(aster): check master replication on',
  _programGetOptions  => ['host|H=s', 'warning|w=s', 'critical|c=s', 'port|P:i', 'username|u|loginname:s', 'password|passwd|p:s', 'database|1:s', 'binlog|2:s', 'table|3:s', 'cluster|4:s', 'environment|e:s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);
  
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $hostname = $objectPlugins->getOptionsArgv ('host');

my $warning = $objectPlugins->getOptionsArgv ('warning');
my $critical = $objectPlugins->getOptionsArgv ('critical');
$objectPlugins->printUsage ('Critical update time '. $critical. ' should be larger than warning update time '. $warning) unless ( $critical > $warning );

my $port = $objectPlugins->getOptionsArgv ('port');
$port = '3306' unless (defined $port);

my $username = $objectPlugins->getOptionsArgv ('username');
$username = 'replication' unless (defined $username);

my $password = $objectPlugins->getOptionsArgv ('password');
$password = 'replication' unless (defined $password);

my $database = $objectPlugins->getOptionsArgv ('database');
$database = 'asnmtap' unless (defined $database);

my $binlog = $objectPlugins->getOptionsArgv ('binlog');
$binlog = '' unless (defined $binlog);

my $table = $objectPlugins->getOptionsArgv ('table');
$table = 'events' unless (defined $table);

my $cluster = $objectPlugins->getOptionsArgv ('cluster');
$cluster = 'F' unless (defined $cluster);
$objectPlugins->printUsage ('Invalid cluster option: '. $cluster) unless ($cluster =~ /^[FSM]$/);

my $debug = $objectPlugins->getOptionsValue ( 'debug' );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->pluginValue ( alert => "DBI:mysql:$database:$hostname:$port" );

my ( $returnCode, $alert, $dbh, $sth, $ref, @tables, $dtable, $exist, $prepareString );

$dbh = DBI->connect ("DBI:mysql:$database:$hostname:$port", "$username", "$password") or errorTrapDBI ( 'Could not connect to MySQL server '. $hostname, "$DBI::err ($DBI::errstr)" );
@tables = $dbh->tables() or errorTrapDBI ( 'No tables found for database '. $database .' on server '. $hostname, '');
foreach $dtable (@tables) { if ( $dtable =~ /(`$database`.){0,1}`$table`/ ) { $exist = 1; last; } else { $exist = 0;} }

if ( $exist ) {
  $returnCode = $ERRORS{OK};

  if ( $dbh ) {
    if ( $cluster =~ /^[SM]$/ ) {
      $prepareString = 'SHOW MASTER STATUS';
      $sth = $dbh->prepare($prepareString) or errorTrapDBI ( 'dbh->prepare '. $prepareString, "$DBI::err ($DBI::errstr)" );
      $sth->execute or errorTrapDBI ( 'sth->execute '. $prepareString, "$DBI::err ($DBI::errstr)" );

      $ref = $sth->fetchrow_arrayref;

      if ( $ref ) {
        print "M) File '$$ref[0]' Position '$$ref[1]'\nM) Binlog_do_db '$$ref[2]' Binlog_ignore_db '$$ref[3]'\n" if ( $debug ); 

        if ( (index $$ref[2], $binlog) ne -1 ) {
          $alert .= '+Binlog do DB';
		  print "M)+Binlog do DB '$binlog' present\n" if ( $debug ); 
        } else {
          $alert = "Binlog do DB '$binlog' not present";
		  print "M)-$alert\n" if ( $debug ); 
          $returnCode = $ERRORS{CRITICAL};
	  	}
	  }

      $sth->finish() or errorTrapDBI ( 'sth->finish '. $prepareString, "$DBI::err ($DBI::errstr)" );

      if ( $returnCode eq $ERRORS{OK} ) {
        $prepareString = 'SHOW SLAVE STATUS';
        $sth = $dbh->prepare($prepareString) or errorTrapDBI ( 'dbh->prepare '. $prepareString, "$DBI::err ($DBI::errstr)" );
        $sth->execute or errorTrapDBI ( 'sth->execute '. $prepareString, "$DBI::err ($DBI::errstr)" );

        $ref = $sth->fetchrow_arrayref;

        if ( $ref ) {
	      print "S) Slave_IO_State '$$ref[0]'\nS) Master_Host '$$ref[1]' Master_User '$$ref[2]'\nS) Master_Port '$$ref[3]' Connect_retry '$$ref[4]'\nS) Master_Log_File '$$ref[5]' Read_Master_Log_Pos '$$ref[6]'\nS) Relay_Log_File '$$ref[7]' Relay_Log_Pos '$$ref[8]'\nS) Relay_Master_Log_File '$$ref[9]' Slave_IO_Running '$$ref[10]'\nS) Slave_SQL_Running '$$ref[11]' Replicate_do_db '$$ref[12]'\nS) Replicate_ignore_db '$$ref[13]' Replicate_Do_Table '$$ref[14]'\nS) Replicate_Ignore_Table '$$ref[15]' Replicate_Wild_Do_Table '$$ref[16]'\nS) Replicate_Wild_Ignore_Table '$$ref[17]' Last_errno '$$ref[18]'\nS) Last_error '$$ref[19]' Skip_counter '$$ref[20]'\nS) Exec_master_log_pos '$$ref[21]' Relay_log_space '$$ref[22]'\nS) Seconds_Behind_Master '$$ref[23]'\n" if ( $debug );

          if ( (index $$ref[12], $binlog) ne -1 ) {
            if ( $cluster eq 'M' ) {
              $alert = "Replication for '$binlog' running on master server";
              print "S)-$alert\n" if ( $debug ); 
              $returnCode = $ERRORS{WARNING};
            } else {
              if ( $$ref[10] eq 'No' ) {
                $alert = "Replication ERROR: NO Slave IO Running";
                print "S)-$alert\n" if ( $debug ); 
                $returnCode = $ERRORS{CRITICAL};
              } elsif ( $$ref[11] eq 'No' ) {
                $alert = "Replication ERROR: NO Slave SQL Running";
                print "S)-$alert\n" if ( $debug ); 
                $returnCode = $ERRORS{CRITICAL};
              } elsif ( $$ref[18] ne '0' ) {
                $alert = "Replication ERROR '$$ref[18]' for '$binlog' running on slave server";
                print "S)-$alert\n" if ( $debug ); 
                $returnCode = $ERRORS{CRITICAL};
              } elsif ( $$ref[32] eq 'NULL' ) {
                $alert = "Seconds Behind Master: '$$ref[18]' for '$binlog' running on slave server";
                print "S)-$alert\n" if ( $debug );
                $returnCode = $ERRORS{CRITICAL};
              } else {
                $alert .= "+Replicate do DB+" . $$ref[0];
      	        print "S)+Replicate do DB '$binlog' present\n" if ( $debug ); 
              }
            }
          } else {
            $alert = "Replicate do DB '$binlog' not present";
	        print "S)-$alert\n" if ( $debug ); 
            $returnCode = $ERRORS{CRITICAL};
		  }
        } else {
          if ( $cluster eq 'S' ) {
            $alert = "Replication for '$binlog' not running on slave server";
            print "S)-$alert\n" if ( $debug );
            $returnCode = $ERRORS{WARNING};
          }
		}

        $sth->finish() or errorTrapDBI ( 'sth->finish '. $prepareString, "$DBI::err ($DBI::errstr)" );
      }
    }

  # if ( $returnCode eq $ERRORS{OK} ) {
  #   $prepareString = "SHOW TABLE STATUS FROM $database";
  #   $sth = $dbh->prepare($prepareString) or errorTrapDBI ( 'dbh->prepare '. $prepareString, "$DBI::err ($DBI::errstr)" );
  #   $sth->execute or errorTrapDBI ( 'sth->execute '. $prepareString, "$DBI::err ($DBI::errstr)" );

  #   while ( $ref = $sth->fetchrow_arrayref ) {
  #     if ( $$ref[1] eq $table ) {
  #       my $updateTime = $$ref[12];

  #       if ( $debug ) {
  #         print "T) <DBI:mysql:$database:$hostname:$port><$username><$password><$table>\n";
  #         my $autoIncrement = $$ref[10];
  #         my $createTime    = $$ref[11];
  #         if ( defined $autoIncrement ) { print "T) Auto increment <$autoIncrement>\n"; }
  #         if ( defined $createTime )    { print "T) Create  Time   <$createTime>\n"; }
  #         if ( defined $updateTime )    { print "T) Update  Time   <$updateTime>\n"; }

  #         # for(my $i=0; $i<$sth->{NUM_OF_FIELDS}; $i++) {
  #         #   my $field = $$ref[$i];
  #         #   if ( defined $field ) { print "<", $field, ">\n"; }
  #         # }
  #       }

  #       if ( defined $updateTime ) { 
  #         if ( $dbh && defined $warning && defined $critical ) {
  #           my (@currentTime, @updateTime, @diffDateTime);
  #           my ($year, $month, $day, $hour, $min, $sec, undef) = split(/\:/, get_yyyymmddhhmmsswday());
  #           @currentTime  = ($year, $month, $day, $hour, $min, $sec);
  #           print "T) Current Time   <$year-$month-$day $hour:$min:$sec>\n" if ( $debug );
  #           ($year, $month, $day) = split(/\-/, substr($updateTime, 0, 10));
  #           ($hour, $min, $sec)   = split(/\:/, substr($updateTime, 11));
  #           @updateTime   = ($year, $month, $day, $hour, $min, $sec);
  #           print "T) Update  Time   <$year-$month-$day $hour:$min:$sec>\n" if ( $debug );
  #           @diffDateTime = Delta_DHMS(@updateTime, @currentTime); 
  #           my $difference = ($diffDateTime[1]*3600)+($diffDateTime[2]*60)+$diffDateTime[3];
  #           print "T) Difference     <$difference> Warning <$warning> Critical <$critical>\n" if ( $debug );
  #           if ( $alert ne '' ) { $alert .= "+ "; }
  #           $alert .= "Last update from table '$table' is $difference seconds ago";

  #           if ( $difference > $critical ) {
  #             $returnCode = $ERRORS{CRITICAL};
  #           } elsif ( $difference > $warning ) {
  #             $returnCode = $ERRORS{WARNING};
  #           }
  #  	    }
  #       } else {
  #         $alert = "Update time for table '$table' doesn't exist";
  #         $returnCode = $ERRORS{CRITICAL};
  #       }
  #     }
  #  }

  #   $sth->finish() or errorTrapDBI ( 'sth->finish '. $prepareString, "$DBI::err ($DBI::errstr)" );
  # }
  }
} else {
  $alert = "table '$table' doesn't exist";
  $returnCode = $ERRORS{CRITICAL};
}

if ( $dbh ) { $dbh->disconnect or errorTrapDBI ( 'Could not disconnect from MySQL server '. $hostname, "$DBI::err ($DBI::errstr)" ); }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->pluginValues ( { stateValue => $returnCode, alert => $alert }, $TYPE{APPEND} );
$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapDBI {
  my ($error, $errorDBI) = @_;

  $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => "$error - $errorDBI" }, $TYPE{APPEND} );
  $objectPlugins->exit (7);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_MySQL-database-replication.pl

MySQL database replication plugin template for the 'Application Monitor'

The ASNMTAP plugins come with ABSOLUTELY NO WARRANTY.

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut

