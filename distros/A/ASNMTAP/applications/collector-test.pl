#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, collector-test.pl for ASNMTAP::Asnmtap::Applications::Collector
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use File::stat;
use Time::Local;
use Getopt::Long;
use Date::Calc qw(Delta_DHMS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time v3.002.003;
use ASNMTAP::Time qw(&get_datetimeSignal &get_csvfiledate &get_csvfiletime &get_logfiledate &get_datetime &get_timeslot);

use ASNMTAP::Asnmtap::Applications::Collector v3.002.003;
use ASNMTAP::Asnmtap::Applications::Collector qw(:APPLICATIONS :COLLECTOR :DBCOLLECTOR);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use lib ( "$CHARTDIRECTORLIB" );
use perlchartdir;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($opt_H  $opt_M $opt_C $opt_W $opt_A $opt_N $opt_s $opt_S $opt_D $opt_V $opt_h $PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "collector.pl";
my $prgtext     = "Collector for the '$APPLICATION'";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $status      = 'N';                                          # default
my $dumphttp    = 'N';                                          # default
my $debug       = 'F';                                          # default
my $logging     = '<NIHIL>';                                    # default
my $httpdump    = '<NIHIL>';                                    # default
my $lockMySQL   = 0;                                            # default
my $alarm       = 5;                                            # default 5

my $perfParseMethode = 'PULP';                           # 'AIP', default

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $boolean_screenDebug = 0;									# default
my $boolean_debug_all   = 0;									# default
my $boolean_debug_NOK   = 0;									# default

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $boolean_loopQuit    = 0;

my ($directory, $action, $dproc, $dcron);
my ($tmin, $thour, $tmday, $tmon, $twday, $tinterval, $tcommand);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');

GetOptions (
  "H=s" => \$opt_H, "hostname=s"      => \$opt_H,
  "M=s" => \$opt_M, "mode=s"          => \$opt_M,
  "C=s" => \$opt_C, "collectorlist=s" => \$opt_C,
  "W:s" => \$opt_W, "screenDebug:s"   => \$opt_W,
  "A:s" => \$opt_A, "allDebug:s"      => \$opt_A,
  "N:s" => \$opt_N, "nokDebug:s"      => \$opt_N,
  "s:s" => \$opt_s, "dumphttp:s"      => \$opt_s,
  "S:s" => \$opt_S, "status:s"        => \$opt_S,
  "D:s" => \$opt_D, "debug:s"         => \$opt_D,
  "V"   => \$opt_V, "version"         => \$opt_V,
  "h"   => \$opt_h, "help"            => \$opt_h
);

if ($opt_V) { print_revision($PROGNAME, $version); exit $ERRORS{OK}; }
if ($opt_h) { print_help(); exit $ERRORS{OK}; }

($opt_H) || usage("MySQL hostname/address not specified\n");
my $serverName = $1 if ($opt_H =~ /([-.A-Za-z0-9]+)/);
($serverName) || usage("Invalid MySQL hostname/address: $opt_H\n");

($opt_M) || usage("Mode not specified\n");
my $mode = $opt_M if ($opt_M eq 'O' || $opt_M eq 'L' || $opt_M eq 'C');
($mode) || usage("Invalid mode: $opt_M\n");
if ($mode eq 'O') { $boolean_loopQuit = 1; }

($opt_C) || usage("collectorlist not specified\n");
my $collectorlist = $1 if ($opt_C =~ /([-.A-Za-z0-9]+)/);
($collectorlist) || usage("Invalid collectorlist: $opt_C\n");

if ($opt_W) {
  if ($opt_W eq 'F' || $opt_W eq 'T') {
    $boolean_screenDebug = ($opt_W eq 'T') ? 1 : 0;
  } else {
    usage("Invalid all screendebugging: $opt_W\n");
  }
}

if ($opt_A) {
  if ($opt_A eq 'F' || $opt_A eq 'T') {
    $boolean_debug_all = ($opt_A eq 'T') ? 1 : 0;
  } else {
    usage("Invalid all file debugging: $opt_A\n");
  }
}

if ($opt_N) {
  if ($opt_N eq 'F' || $opt_N eq 'T') {
    $boolean_debug_NOK = ($opt_N eq 'T') ? 1 : 0;
  } else {
    usage("Invalid nok file debugging: $opt_N\n");
  }
}

my $asnmtapEnv = (($boolean_screenDebug) ? 'T' : 'F') .'|'. (($boolean_debug_all) ? 'T' : 'F') .'|'. (($boolean_debug_NOK) ? 'T' : 'F');

if ($opt_S) {
  if ($opt_S eq 'N' || $opt_S eq 'S') {
    $status = $opt_S;
  } else {
    usage("Invalid status: $opt_S\n");
  }
}

if ($opt_D) {
  if ($opt_D eq 'F' || $opt_D eq 'T' || $opt_D eq 'L') {
    $debug = $opt_D;
  } else {
    usage("Invalid debug: $opt_D\n");
  }
}

if ($opt_s) {
  if ($opt_s eq 'N' || $opt_s eq 'A' || $opt_s eq 'W' || $opt_s eq 'C' || $opt_s eq 'U') {
    $dumphttp = $opt_s;
  } else {
    usage("Invalid dumphttp: $opt_s\n");
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $logger = LOG_init_log4perl ( "collector::$collectorlist", undef, $boolean_debug_all );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $boolean_daemonQuit    = 0;
my $boolean_signal_hup    = 0;
my $boolean_signal_kill   = 0;
my $boolean_daemonControl = !$boolean_loopQuit;

my @crontabtable = ();
my $pidfile = $PIDPATH .'/'. $collectorlist .'.pid';

$directory = $HTTPSPATH .'/nav';
create_dir ($directory);

$directory = $HTTPSPATH .'/nav/index';
create_dir ($directory);

create_dir ($RESULTSPATH);

my $boolean_perfParseInstalled = ( $PERFPARSEENABLED and -e "${HTTPSPATH}${PERFPARSECGI}" ) ? 1 : 0;

if ($mode eq 'C') {
  create_header ($RESULTSPATH .'/HEADER.html');
  create_footer ($RESULTSPATH .'/FOOTER.html');

  printDebugAll ("read table: <$collectorlist>");
  @crontabtable = read_table($prgtext, $collectorlist, 1, $debug);
  resultsdirCreate();
  printDebugAll ("Uitvoeren crontab - : <$PROGNAME v$version -C $collectorlist> pid: <$pidfile>");

  unless (fork) {                                  # unless ($pid = fork) {
    unless (fork) {
      # if ($boolean_daemonControl) { sleep until getppid == 1; }

      printDebugAll ("Main Daemon control loop for: <$PROGNAME v$version -C $collectorlist> pid: <$pidfile>\n");
      write_pid();

      if ($boolean_daemonControl) {
        printDebugAll (print "Set daemon catch signals for: <$PROGNAME v$version -C $collectorlist> pid: <$pidfile>\n");
        $SIG{HUP} = \&signalHUP;
        $SIG{QUIT} = \&signalQUIT;
        $SIG{__DIE__} = \&signal_DIE;
        $SIG{__WARN__} = \&signal_WARN;
      } else {
        $boolean_daemonQuit = 1;
      }

      do {
        # Catch signals implementation
        if ($boolean_signal_hup) {
		      printDebugAll ("read table: <$collectorlist>");
		      @crontabtable = read_table($prgtext, $collectorlist, 2, $debug);
          resultsdirCreate();
		      $boolean_signal_hup = 0;
		    }

        # Update access and modify epoch time from the PID time
        utime (time(), time(), $pidfile) if (-e $pidfile);

        # Crontab implementation
        do_crontab ();
      } until ($boolean_daemonQuit);

      exit 0;
    }

    exit 0;
  }

  printDebugAll ("Einde ... Crontab - : <$PROGNAME v$version -C $collectorlist> pid: <$pidfile>");
  # if ($boolean_daemonControl) { waitpid($pid,0); }
} else {
  printDebugAll ("read table: <$collectorlist>");
  my @processtable = read_table($prgtext, $collectorlist, 0, $debug);

  do {
    printDebugAll ("Start collector - : <$mode> <$PROGNAME v$version -C $collectorlist>");

    foreach $dproc (@processtable) {
      my ($catalogID_uniqueKey, $resultsdir, $title, $command) = split(/\#/, $dproc, 4);

      my ($catalogID, $uniqueKey) = split(/_/, $catalogID_uniqueKey);

      unless ( defined $uniqueKey ) {
        $uniqueKey = $catalogID;
        $catalogID = $CATALOGID;
        $catalogID_uniqueKey = $catalogID .'_'. $uniqueKey unless ( $catalogID eq 'CID' );
      }

      $logging = $RESULTSPATH .'/'. $resultsdir;
      create_dir ($logging);

      $httpdump = $logging .'/'. $DEBUGDIR;
      create_dir ($httpdump);

      $logging .= "/";
      create_header ($logging ."HEADER.html");
      create_footer ($logging ."FOOTER.html");

      $httpdump .= "/";
      create_header ($httpdump ."HEADER.html");
      create_footer ($httpdump ."FOOTER.html");
  
      my $tlogging = $logging . get_logfiledate();

      $title =~ s/^[\[[\S+|\s+]*\]\s+]{0,1}([\S+|\s+]*)/$1/g;
      $action = call_system ($asnmtapEnv, 0, $catalogID_uniqueKey, $catalogID, $uniqueKey, $resultsdir, $title, $command, $status, 0, 9, 9, 9, $debug, $logging, $tlogging, $httpdump, $dumphttp, 0);
    }

    printDebugAll ("Einde collector - : <$mode> <$PROGNAME v$version -C $collectorlist>") if ($debug eq 'T');
  } until ($boolean_loopQuit);
}

exit;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub resultsdirCreate {
  foreach $dcron (@crontabtable) {
    (undef, undef, undef, undef, undef, undef, $tcommand) = split(/ +/, $dcron, 7);
    my @scommand = split(/\|/, $tcommand);

    foreach my $dcommand (@scommand) {
      my (undef, $resultsdir, undef, undef, undef) = split(/\#/, $dcommand);

      $logging = $RESULTSPATH .'/'. $resultsdir;
      create_dir ($logging);

      $httpdump = $logging .'/'. $DEBUGDIR;
      create_dir ($httpdump);

      $logging .= "/";
      create_header ($logging."HEADER.html");
      create_footer ($logging."FOOTER.html");

      $httpdump .= "/";
      create_header ($httpdump."HEADER.html");
      create_footer ($httpdump."FOOTER.html");
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub do_crontab {
  my $currentDate = time();
  my ($min, $hour, $mday, $mon, $wday) = ((localtime($currentDate))[1,2,3], (localtime($currentDate))[4]+1, (localtime($currentDate))[6]);

  foreach $dcron (@crontabtable) {
    ($tmin, $thour, $tmday, $tmon, $twday, $tinterval, $tcommand) = split(/ +/, $dcron, 7);
    my ($doIt, $doOffline) = set_doIt_and_doOffline ($min, $hour, $mday, $mon, $wday, $tmin, $thour, $tmday, $tmon, $twday);

    if ( $doIt || $doOffline ) {
      printDebugAll ("Start CollectorCT - : <$PROGNAME v$version -C $collectorlist> pid: <$pidfile>");
      my @scommand = split(/\|/, $tcommand);

      foreach my $dcommand (@scommand) {
        my ($catalogID_uniqueKey, $resultsdir, $title, $command, $noOFFLINE) = split(/\#/, $dcommand);

        my ($catalogID, $uniqueKey) = split(/_/, $catalogID_uniqueKey);

        unless ( defined $uniqueKey ) {
          $uniqueKey = $catalogID;
          $catalogID = $CATALOGID;
          $catalogID_uniqueKey = $catalogID .'_'. $uniqueKey unless ( $catalogID eq 'CID' );
        }

        $title =~ s/^[\[[\S+|\s+]*\]\s+]{0,1}([\S+|\s+]*)/$1/g;

        $logging  = $RESULTSPATH .'/'. $resultsdir .'/';
        $httpdump = $RESULTSPATH .'/'. $resultsdir .'/'. $DEBUGDIR .'/';

        my $tlogging = $logging . get_logfiledate();
        my ($queryMySQL, $instability, $persistent, $downtime);
        $queryMySQL = $instability = $persistent = $downtime = 0;

        if ($doIt) {
          # open connection to database and query comment data
          my ($sth, $sql, $firstRecordPersistentTrue, $firstRecordPersistentFalse, $activationTimeslotPersistentTrue, $activationTimeslotPersistentFalse, $suspentionTimeslotPersistentTrue, $suspentionTimeslotPersistentFalse);
          $firstRecordPersistentTrue = $firstRecordPersistentFalse = 1;

          my ($dbh, $rv, $alarmMessage) = DBI_connect ( $DATABASE, $SERVERNAMEREADWRITE, $SERVERPORTREADWRITE, $SERVERUSERREADWRITE, $SERVERPASSREADWRITE, $alarm, \&errorTrapDBIdowntime, [$collectorlist, "Cannot connect to the database"], \$logger, $debug, $boolean_debug_all );

          if ($dbh and $rv) {
            $sql = "select SQL_NO_CACHE activationTimeslot, suspentionTimeslot, instability, persistent from $SERVERTABLCOMMENTS where catalogID = '$catalogID' and uKey = '$uniqueKey' and downtime = '1' and problemSolved = '0' order by persistent desc";
            $sth = $dbh->prepare( $sql ) or $rv = errorTrapDBIdowntime($collectorlist, "Cannot dbh->prepare: $sql", \$logger, $debug);
            ($rv, undef) = DBI_execute ($rv, \$sth, $alarm, \&errorTrapDBIdowntime, [$collectorlist, "Cannot sth->execute: $sql"], \$logger, $debug);

            if ( $rv ) {
              if ( $sth->rows ) {
                my ($TactivationTimeslot, $TsuspentionTimeslot, $Tinstability, $Tpersistent);
                $activationTimeslotPersistentTrue = $activationTimeslotPersistentFalse = 9999999999;
                $suspentionTimeslotPersistentTrue = $suspentionTimeslotPersistentFalse = 0;

                while( ($TactivationTimeslot, $TsuspentionTimeslot, $Tinstability, $Tpersistent) = $sth->fetchrow_array() ) {
                  $instability = ( $Tinstability ) ? 1 : $instability;

                  if ( $Tpersistent ) {
                    if ( $firstRecordPersistentTrue ) {
                      $firstRecordPersistentTrue = 0;
                      $suspentionTimeslotPersistentTrue = int($TsuspentionTimeslot);
                    }

                    $activationTimeslotPersistentTrue = ($activationTimeslotPersistentTrue < int($TactivationTimeslot)) ? $activationTimeslotPersistentTrue : int($TactivationTimeslot);
                    $suspentionTimeslotPersistentTrue = ($suspentionTimeslotPersistentTrue > int($TsuspentionTimeslot)) ? $suspentionTimeslotPersistentTrue : int($TsuspentionTimeslot);
                  } else {
                    if ( $firstRecordPersistentFalse ) {
                      $firstRecordPersistentFalse = 0;
                      $suspentionTimeslotPersistentFalse = int($TsuspentionTimeslot);
                    }

                    $activationTimeslotPersistentFalse = ($activationTimeslotPersistentFalse < int($TactivationTimeslot)) ? $activationTimeslotPersistentFalse : int($TactivationTimeslot);
                    $suspentionTimeslotPersistentFalse = ($suspentionTimeslotPersistentFalse > int($TsuspentionTimeslot)) ? $suspentionTimeslotPersistentFalse : int($TsuspentionTimeslot);
                  }
                }
              }

              $sth->finish() or $rv = errorTrapDBIdowntime($collectorlist, "Cannot sth->finish: $sql", \$logger, $debug) if $rv;
            }

            $dbh->disconnect or $rv = errorTrapDBIdowntime($collectorlist, "Sorry, the database was unable to add your entry.", \$logger, $debug);
          } else {
            $logger->info("     DBI_connect - Cannot connect to the database - alarm: $alarm - alarmMessage: $alarmMessage") if ( defined $logger and $logger->is_info() );
          }

          unless ( $firstRecordPersistentTrue and $firstRecordPersistentFalse ) {
            my $currentDowntimeTimeslot = timelocal (0, (localtime)[1,2,3,4,5]);
            print "$catalogID_uniqueKey\ncurrentTimeslot                  : $currentDowntimeTimeslot\n" if ($debug eq 'T');

            unless ( $firstRecordPersistentTrue ) {
              if ($debug eq 'T') {
                print "activationTimeslotPersistentTrue : $activationTimeslotPersistentTrue\n";
                print "suspentionTimeslotPersistentTrue : $suspentionTimeslotPersistentTrue\n";
              }

              if ( $activationTimeslotPersistentTrue <= $currentDowntimeTimeslot and $currentDowntimeTimeslot <= $suspentionTimeslotPersistentTrue ) {
                $persistent = $downtime = 1;
              }
            }

            if ( (! $downtime) and (! $firstRecordPersistentFalse) ) {
              if ($debug eq 'T') {
                print "activationTimeslotPersistentFalse: $activationTimeslotPersistentFalse\n";
                print "suspentionTimeslotPersistentFalse: $suspentionTimeslotPersistentFalse\n";
              }

              if ( $activationTimeslotPersistentFalse <= $currentDowntimeTimeslot and $currentDowntimeTimeslot <= $suspentionTimeslotPersistentFalse ) {
                $downtime = 1;
              }
            }

            print "instability: $instability, persistent: $persistent, downtime: $downtime\n" if ($debug eq 'T');
          }

          # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

          unless ( $downtime ) {
            if ($noOFFLINE) {
              if ($noOFFLINE eq 'multiOFFLINE') {
                $queryMySQL = 1;
                printDebugAll ("multi OFFLINE: call_system <$catalogID_uniqueKey><$command>") if ($debug eq 'T');
              } elsif ($noOFFLINE eq 'noTEST') {
                $queryMySQL = 1;
                printDebugAll ("no TEST: call_system <$catalogID_uniqueKey><$command>") if ($debug eq 'T');
              }
            }

            $action = call_system ($asnmtapEnv, $currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $resultsdir, $title, $command, $status, int($tinterval), $instability, $persistent, $downtime, $debug, $logging, $tlogging, $httpdump, $dumphttp, $queryMySQL);
          }
        }

        if ($doOffline or $downtime) {
          print "Write 'Offline/No Test' status to mysql databases on: ", get_csvfiletime(), "\n" if ($debug eq 'T');

          my ($startDate, $startTime, $endDate, $endTime, $msgCommand);
          $startDate = get_csvfiledate();
          $startTime = get_csvfiletime();
          $endDate   = $startDate;
          $endTime   = $startTime;
          ($msgCommand, undef) = split(/\.pl/, $command);

          my $insertData = 1;
          my $status = 'OFFLINE';

          if ($noOFFLINE) {
  		    if ($noOFFLINE eq 'noOFFLINE') {
              if ($downtime) {
                $queryMySQL = 1;
              } else {
                $insertData = 0;
              }

              printDebugAll ("no OFFLINE: $msgCommand") if ($debug eq 'T');
  		    } elsif ($noOFFLINE eq 'multiOFFLINE') {
		      $queryMySQL = 1;
              printDebugAll ("multi OFFLINE: $msgCommand") if ($debug eq 'T');
  		    } elsif ($noOFFLINE eq 'noTEST') {
              $queryMySQL = 1;
              $status = 'NO TEST' unless ( $downtime );
              printDebugAll ("no TEST: $msgCommand") if ($debug eq 'T');
  		    }
          }

          if ($insertData) {
            my $rvOpen = open(CSV,">>$tlogging-$msgCommand-$catalogID_uniqueKey-csv.txt");

            if ($rvOpen) {
              print CSV '"', $catalogID, '","","', $uniqueKey, '","I","', $command, '","', $title, '","', $status, '","', $startDate, '","', $startTime, '","', $endDate, '","', $endTime, '","0","', $status, ' - Deze applicatie is niet toegankelijk","', int($tinterval)*60, '","', get_timeslot ($currentDate), '","', $instability, '","', $persistent, '","', $downtime, '","<NIHIL>"', "\n";
              close(CSV);
            } else {
              print "Cannot open $tlogging-$msgCommand-$catalogID_uniqueKey-csv.txt to print debug information\n";
            }

            insertEntryDBI ($currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $title, $logging.$msgCommand.'-'.$catalogID_uniqueKey.'-sql', $command, int($tinterval), $status, $tlogging, $debug, $startDate, $startTime, $endDate, $endTime, 0, "$status - Deze applicatie is niet toegankelijk", '', '<NIHIL>', $insertData, $queryMySQL, $instability, $persistent, $downtime);
          }
        }

        # Update access and modify epoch time from the PID time
        utime (time(), time(), $pidfile) if (-e $pidfile);
      }

      printDebugAll ("Einde CollectorCT - : <$PROGNAME v$version -C $collectorlist> pid: <$pidfile>") if ($debug eq 'T');
    } else {
      print "Nothing to do at: ", get_csvfiletime(), "\n" if ($debug eq 'T');
    }
  }

  my ($prevSecs, $currSecs);
  $currSecs = int((localtime)[0]);

  do {
    sleep 5;
    $prevSecs = $currSecs;
    $currSecs = int((localtime)[0]);
  } until ($currSecs < $prevSecs);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signal_DIE {
  # printDebugAll ("kill -DIE <$PROGNAME v$version -C $collectorlist> pid: <$pidfile>");

  # if ( $DBI_CONNECT_ALARM_OFF or $! =~ /\QDBI_CONNECT_ALARM_OFF = \E(\d*)\Q\n\E/ or $@ =~ /\QDBI_CONNECT_ALARM_OFF = \E(\d*)\Q\n\E/ ) {
  #   print "DBI_CONNECT_ALARM_OFF\n";
  # } elsif ( $DBI_EXECUTE_ALARM_OFF or $! =~ /\QDBI_EXECUTE_ALARM_OFF = \E(\d*)\Q\n\E/ or $@ =~ /\QDBI_EXECUTE_ALARM_OFF = \E(\d*)\Q\n\E/ ) {
  #   print "DBI_EXECUTE_ALARM_OFF\n";
  # } else {
  #   print "DBI_xxx_ALARM_OFF\n";
  # }

  # Make sure this application logs a message when it dies unexpectedly
  # -> log4perl.category = FATAL, Logfile
  #
  # if ( $^S ) {
  #   # We're in an eval {} and don't want log this message but catch it later
  #   return;
  # }
  #
  # $Log::Log4perl::caller_depth++;
  # my $logger = get_logger("");
  # $logger->fatal(@_);
  # die @_; # Now terminate really
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signal_WARN {
  # printDebugAll ("kill -WARN <$PROGNAME v$version -C $collectorlist> pid: <$pidfile>");

  if ( $CHILD_OFF or $! =~ /\QASNMTAP::Asnmtap::Applications::Collector::CHILD_OFF = \E(\d*)\Q\n\E/ or $@ =~ /\QASNMTAP::Asnmtap::Applications::Collector::CHILD_OFF = \E(\d*)\Q\n\E/ ) {
    my $alarm = ( ( defined $CHILD_OFF and $CHILD_OFF ) ? $CHILD_OFF : $1 );

    if ( defined $alarm ) {
      use Proc::ProcessTable;
      my $t = new Proc::ProcessTable;

      foreach my $process ( @{$t->table} ) {
        if ( $process->ppid == $$ and ( timelocal( (localtime)[0,1,2,3,4,5] ) - $process->start ) >= $alarm ) {
          $process->kill(9);
          $boolean_signal_kill = 1;
          printDebugAll ("kill -9 <$PROGNAME v$version -C $collectorlist> pid: <". $process->pid ."> ppid: <$$>");
        }
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signalQUIT {
  printDebugAll ("kill -QUIT <$PROGNAME v$version -C $collectorlist> pid: <$pidfile>");
  printDebugAll ("           Wait until next timeslot");

  my ($prevSecs, $currSecs);
  $currSecs = int((localtime)[0]);

  do {
    sleep 1;
    $prevSecs = $currSecs;
    $currSecs = int((localtime)[0]);
  } until ($currSecs < $prevSecs);

  unlink $pidfile;
  printDebugAll ("           Done");
  $boolean_daemonQuit = 1;

  use Sys::Hostname;
  my $subject = "$prgtext\@". hostname() .": Config $APPLICATIONPATH/etc/$collectorlist successfully stopped at ". get_datetimeSignal();
  my $returnCode = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $subject ."\n", 0 );
  print "Problem sending email to the '$APPLICATION' server administrators\n" unless ( $returnCode );

  exit 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signalHUP {
  printDebugAll ("kill -HUP <$PROGNAME v$version -C $collectorlist> pid: <$pidfile>");
  $boolean_signal_hup = 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub write_pid {
  printDebugAll ("write PID <$PROGNAME v$version -C $collectorlist> pid: <$pidfile>");

  if (-e "$pidfile") {
    printDebugAll ("ERROR: couldn't create pid file <$pidfile> for <$PROGNAME v$version -C $collectorlist>");
    print "ERROR: couldn't create pid file <$pidfile> for <$PROGNAME v$version -C $collectorlist>\n";
    exit 0;
  } else {
    open(PID,">$pidfile") || die "Cannot open $pidfile!!\n";
    print PID $$;
    close(PID);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub create_dir {
  my ($directory) = @_;

  unless ( -e "$directory" ) { # create $directory
    my ($systemAction, $stdout, $stderr, $exit_value, $signal_num, $dumped_core);
    $systemAction = "mkdir $directory";
	
    if ($CAPTUREOUTPUT) {
      use IO::CaptureOutput qw(capture_exec);
     ($stdout, $stderr) = capture_exec("$systemAction");
    } else {
      system ("$systemAction"); $stdout = $stderr = '';
    }

    $exit_value  = $? >> 8;
    $signal_num  = $? & 127;
    $dumped_core = $? & 128;

    unless ( $exit_value == 0 && $signal_num == 0 && $dumped_core == 0 && $stderr eq '' ) {
      printDebugAll ("    create_dir ---- : mkdir $directory: <$exit_value><$signal_num><$dumped_core><$stderr>");
      printDebugNOK ("    create_dir ---- : mkdir $directory: <$exit_value><$signal_num><$dumped_core><$stderr>");
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub call_system {
  my ($asnmtapEnv, $currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $resultsdir, $title, $system_action, $status, $interval, $instability, $persistent, $downtime, $debug, $dbiFilename, $logging, $httpdump, $dumphttp, $queryMySQL) = @_;

  my $rvOpen;
  my $action = '';
  my $httpdumpFilename    = '';
  my $httpdumpFilenameTmp = '';
  my $debugFilename       = '<NIHIL>';
  my $dumphttpRename      = '<NIHIL>';
  my ($stdout, $stderr, $exit_value, $signal_num, $dumped_core);

  my ($loggedStatus, $returnStatus, $startDate, $startTime, $endDate, $endTime, $msgCommand);
  $startDate = get_csvfiledate();
  $startTime = get_csvfiletime();
  ($msgCommand, undef) = split(/\.pl/, $system_action);

  if ($dumphttp ne 'N') {
    $httpdumpFilename = $httpdump . get_datetime() .'-'. $msgCommand .'-'. $catalogID_uniqueKey;
    $httpdumpFilenameTmp = $httpdumpFilename .'.tmp';
  }

  $boolean_signal_kill = 0;

  if (-e "$PLUGINPATH/$msgCommand.pl") {
    my $systemAction = "cd $PLUGINPATH; ./$system_action --status=$status --debug=$debug --logging=$logging --asnmtapEnv='$asnmtapEnv'";
    $systemAction .= " --dumphttp=$httpdumpFilenameTmp" if ($dumphttp ne 'N');

    my $_handler = $SIG{ALRM};
    my $alarm = $interval * 60;
    $SIG{ALRM} = sub { $CHILD_OFF = $alarm; warn "ASNMTAP::Asnmtap::Applications::Collector::CHILD_OFF = $alarm\n" };
    alarm ( $alarm );

    if ($CAPTUREOUTPUT) {
      use IO::CaptureOutput qw(capture_exec);
      ($stdout, $stderr) = capture_exec("$systemAction");
      my (@returnStatus) = split (/\n/, $stdout);
      $returnStatus = $returnStatus[-1];
    } else {
      system ("$systemAction"); $stdout = $stderr = '';
    }

    $exit_value  = $? >> 8;
    $signal_num  = $? & 127;
    $dumped_core = $? & 128;
  # print "$CAPTUREOUTPUT -> <$returnStatus> < $stdout >< $stderr >< $exit_value >< $signal_num >< $dumped_core >\n";

    alarm (0);
    $CHILD_OFF = 0;
    $SIG{ALRM} = $_handler ? $_handler : 'DEFAULT';
  } else {
    $exit_value  = -1;
    $signal_num  = 1;
    $dumped_core = 0;
    $stdout = $stderr = '';
  }

  if ($exit_value >= 0 && $exit_value <= 4 && $signal_num == 0 && $dumped_core == 0) {
    $action = "Success";

    if ($exit_value == 0) {
      $dumphttpRename = "OK";
      printDebugAll ("    OK ------------ : <$PROGNAME v$version -C $collectorlist>");
    } elsif ($exit_value == 1) {
      $dumphttpRename = "WARNING";
      printDebugAll ("    WARNING ------- : <$PROGNAME v$version -C $collectorlist>");
      printDebugNOK ("    WARNING ------- : $system_action");
    } elsif ($exit_value == 2) {
      $dumphttpRename = "CRITICAL";
      printDebugAll ("    CRITICAL ------ : <$PROGNAME v$version -C $collectorlist>");
      printDebugNOK ("    CRITICAL ------ : $system_action");
    } elsif ($exit_value == 3) {
      $dumphttpRename = "UNKNOWN";
      printDebugAll ("    UNKNOWN ------- : <$PROGNAME v$version -C $collectorlist>");
      printDebugNOK ("    UNKNOWN ------- : $system_action");
    } elsif ($exit_value == 4) {
      $dumphttpRename = "DEPENDENT";
      printDebugAll ("    DEPENDENT ----- : <$PROGNAME v$version -C $collectorlist>");
      printDebugNOK ("    DEPENDENT ----- : $system_action");
    }

    if ($dumphttp ne 'N') {
      my $httpdumpFilenameTmpKnownError = $httpdumpFilenameTmp .'-KnownError';
      unlink ($httpdumpFilenameTmpKnownError) if (-e "$httpdumpFilenameTmpKnownError");

      if ($dumphttp eq 'A' || (($dumphttp eq 'W' or $dumphttp eq 'C' or $dumphttp eq 'U') && $exit_value > 0)) {
        if (-e "$httpdumpFilenameTmp") {
          $debugFilename = $httpdumpFilename .'-'. $dumphttpRename .'.htm';
          rename("$httpdumpFilenameTmp", "$debugFilename");
        }
      } else {
        unlink ($httpdumpFilenameTmp) if (-e "$httpdumpFilenameTmp");
      }
    }
  } else {
    $action = 'Failed';
    $dumphttpRename = 'UNKNOWN';
    printDebugAll ("    call_system --- : $system_action: <$exit_value><$signal_num><$dumped_core><$stderr>");
    printDebugNOK ("    call_system --- : $system_action: <$exit_value><$signal_num><$dumped_core><$stderr>");

    if ( $exit_value == -1 ) {
      $returnStatus = "$dumphttpRename - $title: PLUGIN '$msgCommand.pl' doesn't exist - contact administrators";
    } elsif ( $boolean_signal_kill ) {
      $returnStatus = "$dumphttpRename - $title: TIMING OUT SLOW PLUGIN";

      my $httpdumpFilenameTmpKnownError = $httpdumpFilenameTmp .'-KnownError';
      unlink ($httpdumpFilenameTmpKnownError) if (-e "$httpdumpFilenameTmpKnownError");
      unlink ($httpdumpFilenameTmp) if (-e "$httpdumpFilenameTmp");
    } else {
      $returnStatus = "$dumphttpRename - $title: ERROR NOT DEFINED - contact server administrators";
    }
  }

  $endDate = get_csvfiledate();
  $endTime = get_csvfiletime();

  unless ( $CAPTUREOUTPUT ) {
    $loggedStatus = ( $dumphttp ne 'N' ) ? $httpdumpFilenameTmp : $logging;
    $loggedStatus .= '-status.txt';
    $returnStatus = "<NIHIL> - $title: $loggedStatus";

    if (-e "$loggedStatus") {
      unless ( $boolean_signal_kill ) {
        $rvOpen = open(DEBUG, "$loggedStatus");

        if ($rvOpen) {
          while (<DEBUG>) {
	        chomp;
            $returnStatus = $_;
          }
	
          close(DEBUG);
        } else {
          $dumphttpRename = 'UNKNOWN';
          $returnStatus = "$dumphttpRename - $title: Cannot open $loggedStatus to retrieve debug information - contact server administrators";
        }
      }

      unlink ($loggedStatus);
    } else {
      $dumphttpRename = 'UNKNOWN';
      $returnStatus = "$dumphttpRename - $title: $loggedStatus doesn't exist - contact server administrators";
    }
  }

  my ($duration) = $returnStatus =~ m/Trendline=([0-9.]+)s;[0-9.]+;;;$/i;

  if (defined $duration) {
    my ($thour, $tmin, $tsec);
    $thour = int ($duration / 3600);
    $tmin  = int (int ($duration % 3600) / 60);
    $tsec  = int ($duration % 60);
    $duration = sprintf("%02d:%02d:%02d", $thour, $tmin, $tsec);
  } else {
    my ($tyear, $tmonth, $tday, $thour, $tmin, $tsec, @startDateTime, @endDateTime, @diffDateTime);

    ($tyear, $tmonth, $tday) = split(/\//, $startDate);
    ($thour, $tmin, $tsec)   = split(/\:/, $startTime);
    @startDateTime = ($tyear, $tmonth, $tday, $thour, $tmin, $tsec);

    ($tyear, $tmonth, $tday) = split(/\//, $endDate);
    ($thour, $tmin, $tsec)   = split(/\:/, $endTime);
    @endDateTime = ($tyear, $tmonth, $tday, $thour, $tmin, $tsec);

    @diffDateTime = Delta_DHMS(@startDateTime, @endDateTime);
    $duration = sprintf("%02d:%02d:%02d", $diffDateTime[1], $diffDateTime[2], $diffDateTime[3]);
  }

# my ($outputData, $performanceData) = split(/\|/, $returnStatus, 2);
  my $_returnStatus = reverse $returnStatus;
  my ($_outputData, $_performanceData) = reverse split(/\|/, $_returnStatus, 2);
  my $outputData = reverse $_outputData;
  my $performanceData = reverse $_performanceData;

  $rvOpen = open(CSV,">>$logging-$msgCommand-$catalogID_uniqueKey-csv.txt");

  if ($rvOpen) {
    print CSV '"', $catalogID, '","","', $uniqueKey, '","I","', $system_action, '","', $title, '","', $dumphttpRename, '","', $startDate, '","', $startTime, '","', $endDate, '","', $endTime, '","', $duration, '","', $outputData, '","', $performanceData, '","', int($tinterval)*60, '","', get_timeslot ($currentDate), '","', $instability, '","', $persistent, '","', $downtime, '","<NIHIL>"', "\n";
    close(CSV);
  } else {
    print "Cannot open $logging-$msgCommand-$catalogID_uniqueKey-csv.txt to print debug information\n";
  }

  if ( $boolean_perfParseInstalled ) {
    if (defined $performanceData) {
      my $perfParseTimeslot = get_timeslot ($currentDate);

      my $perfParseCommand;
      my $environment = (($system_action =~ /\-\-environment=([PASTDL])/) ? $1 : 'P');
      my $eTitle = $title .' ('. $ENVIRONMENT{$environment} .')' if (defined $environment);
	    $eTitle .= ' from '. $catalogID;

      if ( $perfParseMethode eq 'PULP' ) {
        $perfParseCommand = "$APPLICATIONPATH/sbin/perfparse_asnmtap_pulp_command.pl $PREFIXPATH/log/perfdata-asnmtap.log \"$perfParseTimeslot\t$eTitle\t$catalogID_uniqueKey\t$outputData\t$dumphttpRename\t$performanceData\"";
      } else {
        $perfParseCommand = "printf \"%b\" \"$perfParseTimeslot\t$eTitle\t$catalogID_uniqueKey\t$outputData\t$dumphttpRename\t$performanceData\n\" | $PERFPARSEBIN/perfparse-log2mysql -c $PERFPARSEETC/$PERFPARSECONFIG";
      }

      if ($CAPTUREOUTPUT) {
        use IO::CaptureOutput qw(capture_exec);
        ($stdout, $stderr) = capture_exec("$perfParseCommand");
      } else {
        system ("$perfParseCommand"); $stdout = $stderr = '';
      }

      $exit_value  = $? >> 8;
      $signal_num  = $? & 127;
      $dumped_core = $? & 128;
      printDebugNOK ("    perfParse ----- : $perfParseCommand: <$exit_value><$signal_num><$dumped_core><$stderr>") unless ( $exit_value == 0 && $signal_num == 0 && $dumped_core == 0 && $stderr eq '' );
    }
  }

  insertEntryDBI ($currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $title, $dbiFilename.$msgCommand.'-'.$catalogID_uniqueKey.'-sql', $system_action, $interval, $dumphttpRename, $logging, $debug, $startDate, $startTime, $endDate, $endTime, $duration, $outputData, ( defined $performanceData ) ? $performanceData : '', $debugFilename, 1, $queryMySQL, $instability, $persistent, $downtime);
  return $action;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printDebugAll {
  my ($l_text) = @_;

  if ($boolean_screenDebug or $boolean_debug_all) {
    chomp ($l_text);

    my $date = scalar(localtime());
    my $tlogging = $logging . get_logfiledate();
    print "$l_text $date\n" if ( $boolean_screenDebug );

    if ($boolean_debug_all and $logging ne '<NIHIL>') {
      my $rvOpen = open(ALLDEBUG,">>$tlogging-all.txt");

      if ($rvOpen) {
        print ALLDEBUG "$l_text $date\n";
        close(ALLDEBUG);
      } else {
        print "Cannot open $tlogging-all.txt to print debug information\n";
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printDebugNOK {
  my ($l_text) = @_;

  if ($boolean_debug_NOK and $logging ne '<NIHIL>') {
    chomp ($l_text);

    my $date = scalar(localtime());
    my $tlogging = $logging . get_logfiledate();
    my $rvOpen = open(NOKDEBUG,">>$tlogging-nok.txt");

    if ($rvOpen) {
      print NOKDEBUG "$l_text $date\n";
      close(NOKDEBUG);
    } else {
      print "Cannot open $tlogging-nok.txt to print debug information\n";
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub insertEntryDBI {
  my ($currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $title, $dbiFilename, $test, $interval, $status, $logging, $debug, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $filename, $insertMySQL, $queryMySQL, $instability, $persistent, $downtime) = @_;

  return ( 1 ) unless ( $insertMySQL );

  my ($sth, $lockString, $findString, $updateString, $insertString, $flushString, $unlockString, $insertEntryDBI, $updateEntryDBI);
  $insertEntryDBI = 0;
  $updateEntryDBI = 0;
  my ($dbh, $rv, $alarmMessage) = DBI_connect ( $DATABASE, $serverName, $SERVERPORTREADWRITE, $SERVERUSERREADWRITE, $SERVERPASSREADWRITE, $alarm, \&errorTrapDBI, [$currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot connect to the database"], \$logger, $debug, $boolean_debug_all );

  if ($dbh and $rv) {
    if ($queryMySQL) {
      my $numbersEntryDBI = 0;
      $findString = 'select SQL_NO_CACHE status from '.$SERVERTABLEVENTS.' where catalogID = "' .$catalogID. '" and uKey = "' .$uniqueKey. '" and step <> "0" and timeslot = "' . get_timeslot ($currentDate) . '" order by id desc';
      printDebugAll ("query Entry DBI: <$findString>") if ($debug eq 'T');
      $sth = $dbh->prepare($findString) or $rv = errorTrapDBI($currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot dbh->prepare: $findString", \$logger, $debug);
      ($rv, undef) = DBI_execute ($rv, \$sth, $alarm, \&errorTrapDBI, [$currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot sth->execute: $findString"], \$logger, $debug);

      if ($rv) {
  	    while (my $ref = $sth->fetchrow_hashref()) {
	      $numbersEntryDBI++;
          if ( $ref->{status} eq '<NIHIL>' or $ref->{status} eq 'OFFLINE' or $ref->{status} eq 'NO TEST' ) { $updateEntryDBI = 1; }
        }

        $insertEntryDBI = 1 unless ( $numbersEntryDBI );
        printDebugAll ("query Entry DBI: # <$numbersEntryDBI> insert <$insertEntryDBI> change <$updateEntryDBI>") if ($debug eq 'T');
      }

      $sth->finish() or $rv = errorTrapDBI($currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot sth->finish: $findString", \$logger, $debug);
    } else {
      $insertEntryDBI = 1;
    }
  } else {
    $logger->info("     DBI_connect - Cannot connect to the database - alarm: $alarm - alarmMessage: $alarmMessage") if ( defined $logger and $logger->is_info() );
  }

  if ($insertEntryDBI or $updateEntryDBI) {
    if ($lockMySQL) {
      if ($dbh and $rv) {
        $lockString = 'LOCK TABLES ' .$SERVERTABLEVENTS. ' WRITE, ' .$SERVERTABLEVENTSCHNGSLGDT. ' WRITE';
        ($rv, undef, undef) = DBI_do ($rv, \$dbh, $lockString, $alarm, \&errorTrapDBI, [$currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot dbh->do: $lockString"], \$logger, $debug);
      }
    }

    if ($dbh and $rv) {
      $statusMessage =~ s/"/'/g;

      if ($updateEntryDBI) {
        $updateString = 'UPDATE ' .$SERVERTABLEVENTS. ' SET catalogID="' .$catalogID. '", uKey="' .$uniqueKey. '", replicationStatus="U", test="' .$test. '", title="' .$title. '", status="' .$status. '", startDate="' .$startDate. '", startTime="' .$startTime.'", endDate="' .$endDate. '", endTime="' .$endTime. '", duration="' .$duration. '", statusMessage="' .$statusMessage. '", perfdata="' .$perfdata. '", step="' .($interval*60). '", timeslot="' .get_timeslot ($currentDate). '", instability="' .$instability. '", persistent="' .$persistent. '", downtime="' .$downtime. '", filename="' .$filename. '" where catalogID="' .$catalogID. '" and uKey = "' .$uniqueKey. '" and step <> "0" and timeslot = "' . get_timeslot ($currentDate) . '" order by id desc';
        ($rv, undef, undef) = DBI_do ($rv, \$dbh, $updateString, $alarm, \&errorTrapDBI, [$currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot dbh->do: $lockString"], \$logger, $debug);
      } elsif ($insertEntryDBI) {
        $insertString = 'INSERT INTO ' .$SERVERTABLEVENTS. ' SET catalogID="' .$catalogID. '", uKey="' .$uniqueKey. '", replicationStatus="I", test="' .$test. '", title="' .$title. '", status="' .$status. '", startDate="' .$startDate. '", startTime="' .$startTime.'", endDate="' .$endDate. '", endTime="' .$endTime. '", duration="' .$duration. '", statusMessage="' .$statusMessage. '", perfdata="' .$perfdata. '", step="' .($interval*60). '", timeslot="' .get_timeslot ($currentDate). '", instability="' .$instability. '", persistent="' .$persistent. '", downtime="' .$downtime. '", filename="' .$filename. '"';
        ($rv, undef, undef) = DBI_do ($rv, \$dbh, $insertString, $alarm, \&errorTrapDBI, [$currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot dbh->do: $lockString"], \$logger, $debug);
      }

      my ( $lastStatus, $lastTimeslot, $prevStatus, $prevTimeslot ) = ( $status, get_timeslot ($currentDate), '', '' );
      my $sql = "select SQL_NO_CACHE lastStatus, lastTimeslot from $SERVERTABLEVENTSCHNGSLGDT where catalogID = '$catalogID' and uKey = '$uniqueKey'";
      my $sth = $dbh->prepare( $sql ) or $rv = errorTrapDBI($currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot dbh->prepare: $sql", \$logger, $debug);
      ($rv, undef) = DBI_execute ($rv, \$sth, $alarm, \&errorTrapDBI, [$currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot sth->execute: $sql"], \$logger, $debug);

      if ( $rv ) {
        if ( $sth->rows ) {
	      ($prevStatus, $prevTimeslot) = $sth->fetchrow_array() or $rv = errorTrapDBI($currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot sth->fetchrow_array: $sql", \$logger, $debug);
          $sth->finish() or $rv = errorTrapDBI($currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot sth->finish: $sql", \$logger, $debug);
          $updateString = 'UPDATE ' .$SERVERTABLEVENTSCHNGSLGDT. ' SET replicationStatus="U", lastStatus="' .$lastStatus. '", lastTimeslot="' .$lastTimeslot. '", prevStatus="' .$prevStatus. '", prevTimeslot="' .$prevTimeslot. '" where catalogID="' .$catalogID. '" and uKey="' .$uniqueKey. '"';
          ($rv, undef, undef) = DBI_do ($rv, \$dbh, $updateString, $alarm, \&errorTrapDBI, [$currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot dbh->do: $lockString"], \$logger, $debug);
        } else {
          $insertString = 'INSERT INTO ' .$SERVERTABLEVENTSCHNGSLGDT. ' SET catalogID="' .$catalogID. '", uKey="' .$uniqueKey. '", replicationStatus="I", lastStatus="' .$lastStatus. '", lastTimeslot="' .$lastTimeslot. '", prevStatus="' .$prevStatus. '", prevTimeslot="' .$prevTimeslot. '"';
          ($rv, undef, undef) = DBI_do ($rv, \$dbh, $insertString, $alarm, \&errorTrapDBI, [$currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot dbh->do: $lockString"], \$logger, $debug);
        }
      }
    }

    if ($lockMySQL) {
      if ($dbh and $rv) {
        $unlockString = 'UNLOCK TABLES';
        ($rv, undef, undef) = DBI_do ($rv, \$dbh, $unlockString, $alarm, \&errorTrapDBI, [$currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Cannot dbh->do: $lockString"], \$logger, $debug);
      }
    }
  }

  if ($dbh and $rv) {
    $dbh->disconnect or $rv = errorTrapDBI($currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, "Sorry, the database was unable to add your entry.", \$logger, $debug);
    my $environment = (($test =~ /\-\-environment=([PASTDL])/) ? $1 : 'P');
    $rv = graphEntryDBI ($catalogID, $uniqueKey, $title, $environment, $dbiFilename, $interval, 121, 6, 1, 0, get_trendline_from_test ($test), 0, $debug) if ($interval > 0);
  }

  return $rv;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapDBI {
  my ($currentDate, $catalogID_uniqueKey, $catalogID, $uniqueKey, $test, $title, $status, $startDate, $startTime, $endDate, $endTime, $duration, $statusMessage, $perfdata, $interval, $instability, $persistent, $downtime, $filename, $error_message, $logger, $debug) = @_;

  print $error_message, "\nERROR: $DBI::err ($DBI::errstr)\n";

  my $tlogging = $logging . get_logfiledate();

  my ($msgCommand, undef) = split(/\.pl/, $test);

  # APE # TODO - REMOVE
  # my $rvOpen = open(DEBUG,">>$tlogging-$msgCommand-$catalogID_uniqueKey.sql");

  # if ($rvOpen) {
  #   print DEBUG '"', $catalogID, '","","', $uniqueKey, '","I","', $test, '","', $title, '","', $status, '","', $startDate, '","', $startTime, '","', $endDate, '","', $endTime, '","', $duration, '","', $statusMessage, '","', $perfdata, '","', $interval*60, '","', get_timeslot ($currentDate), '","', $instability, '","', $persistent, '","', $downtime, '","', $filename, '"', "\n";
  #   close(DEBUG);
  # } else {
  #   print "Cannot open $tlogging-$msgCommand-$catalogID_uniqueKey.sql to print debug information\n";
  # }

  my %VALUES = (
    'catalogID'         => $catalogID,
    'id'                => 0,
    'uKey'              => $uniqueKey,
    'replicationStatus' => 'I',
    'test'              => $test,
    'title'             => $title,
    'status'            => $status,
    'startDate'         => $startDate,
    'startTime'         => $startTime,
    'endDate'           => $endDate,
    'endTime'           => $endTime,
    'duration'          => $duration,
    'statusMessage'     => $statusMessage,
    'perfdata'          => $perfdata,
    'step'              => $interval * 60,
    'timeslot'          => get_timeslot ($currentDate),
    'instability'       => $instability,
    'persistent'        => $persistent,
    'downtime'          => $downtime,
    'filename'          => $filename
  );

  my $_debug = ( ( $debug eq 'T' ) ? 1 : 0);
  my $dbh = CSV_prepare_table ($logging, get_logfiledate() . "-$msgCommand-$catalogID_uniqueKey", '.sql', $SERVERTABLEVENTS, \@EVENTS, \%EVENTS, \$logger, $_debug);
  my $rv = CSV_insert_into_table (1, $dbh, $SERVERTABLEVENTS, \@EVENTS, \%VALUES, 'id', \$logger, $_debug);
  CSV_cleanup_table ($dbh, \$logger, $_debug);

  my $rvOpen = open(DEBUG,">>$tlogging-$msgCommand-$catalogID_uniqueKey-sql-error.txt");

  if ($rvOpen) {
    print DEBUG $error_message, "\n--> ERROR: $DBI::err ($DBI::errstr)\n";
    print DEBUG $CATALOGID, " --> ", $catalogID, " <-> ", $uniqueKey, " <-> ", $title, " <-> ", $status, "\n--> ", $startDate, " <-> ", $startTime, " <-> ", $endDate, " <-> ", $endTime, " <-> ", $duration, " <-> ", $interval*60, " <-> ", get_timeslot ($currentDate), " <-> ", $instability, " <-> ", $persistent, " <-> ", $downtime, "\n";
    close(DEBUG);
  } else {
    print "Cannot open $tlogging-$msgCommand-$catalogID_uniqueKey-sql-error.txt to print debug information\n";
  }

  unless ( -e "$RESULTSPATH/$collectorlist-MySQL-sql-error.txt" ) {
    my $tDebug = ($debug eq 'T') ? 2 : 0;
    my $subject = "$prgtext / Current status for $collectorlist: " . get_datetimeSignal();
    my $message = get_datetimeSignal() . " $error_message\n--> ERROR: $DBI::err ($DBI::errstr)\n";
    my $returnCode = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $message, $tDebug );
    print "Problem sending email to the '$APPLICATION' server administrators\n" unless ( $returnCode );
  }

  $rvOpen = open(DEBUG,">>$RESULTSPATH/$collectorlist-MySQL-sql-error.txt");

  if ($rvOpen) {
    print DEBUG get_datetimeSignal, " ", $error_message, "\n--> ERROR: $DBI::err ($DBI::errstr)\n";
    close(DEBUG);
  } else {
    print "Cannot open $RESULTSPATH/$collectorlist-MySQL-sql-error.txt to print debug information\n";
  }

  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapDBIdowntime {
  my ($collectorlist, $error_message, $logger, $debug) = @_;

  print $collectorlist, "\n", $error_message, "\nERROR: $DBI::err ($DBI::errstr)\n";
  $$logger->error("$collectorlist:\n" .$error_message. "\nERROR: $DBI::err ($DBI::errstr)") if ( defined $$logger and $$logger->is_error() );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub graphEntryDBI {
  my ($catalogID, $uniqueKey, $title, $environment, $dbiFilename, $interval, $limitTest, $xLabelStep, $withBorder, $markOrZone, $yMarkValue, $xRealtime, $debug) = @_;

  $title .= ' ('. $ENVIRONMENT{$environment} .')' if (defined $environment);
  $title .= ' from '. $catalogID;

  # $limitTest -> 241: (120*2.0)+1, x = 2.0 -> $xLabelStep = 6 * x -> 12
  #               181: (120*1.5)+1, x = 1.5 -> $xLabelStep = 6 * x ->  9
  #               121: (120*1.0)+1, x = 1.0 -> $xLabelStep = 6 * x ->  6

  my $width      = 893;
  my $hight      = 558;
  my $xOffset    = 74;
  my $yOffset    = 28;
  my $yMarkColor = 0xFFFFDC;
  my $background = 0xF7F7F7;

  print "Generating RRD alike graph\n" if ($debug eq 'T');

  my (@dataOK, @dataCritical, @dataWarning, @dataUnknown, @dataNoTest, @dataOffline, @RRDlabels);
  my ($step, $lastTimeslot, $firstTimeslot, $duration, $startTime, $status, $timeslot, $findString);

  $step          = $interval * 60;
  $lastTimeslot  = timelocal (0, (localtime)[1,2,3,4,5]);
  $firstTimeslot = $lastTimeslot - ($step * ($limitTest));
  $findString    = "select SQL_NO_CACHE duration, startTime, status, timeslot from $SERVERTABLEVENTS force index (uKey) where catalogID = '$catalogID' and uKey = '$uniqueKey' and step <> '0' and (timeslot between '$firstTimeslot' and '$lastTimeslot') order by id desc limit $limitTest";
  print "$findString\n" if ($debug eq 'T');

  # data en labels in array zetten
  my ($counter, $seconden, $ttimeslot);

  for ( $counter = 0; $counter < $limitTest; $counter++) {
    push (@dataOK,       "0");
    push (@dataWarning,  "0");
    push (@dataCritical, "0");
    push (@dataUnknown,  "0");
    push (@dataNoTest,   "0");
    push (@dataOffline,  "0");
    push (@RRDlabels,    " ");
  }

  # db connect & sql query
  my ($dbh, $rv, $alarmMessage) = DBI_connect ( $DATABASE, $serverName, $SERVERPORTREADWRITE, $SERVERUSERREADWRITE, $SERVERPASSREADWRITE, $alarm, \&errorTrapDBIgraphEntry, ["Cannot connect to the database"], \$logger, $debug, $boolean_debug_all );

  if ($dbh and $rv) {
    my $sth = $dbh->prepare( $findString ) or $rv = errorTrapDBIgraphEntry("Cannot dbh->prepare: $findString", \$logger, $debug);
    ($rv, $alarmMessage) = DBI_execute ($rv, \$sth, $alarm, \&errorTrapDBIgraphEntry, ["Cannot sth->execute: $findString"], \$logger, $debug);

    unless ( $rv ) {
      $title .= " - DBI_execute - alarm: $alarm - $alarmMessage";
    } else {
      $sth->bind_columns( \$duration, \$startTime, \$status, \$timeslot ) or $rv = errorTrapDBIgraphEntry("Cannot sth->bind_columns: $findString", \$logger, $debug);

      unless ( $rv ) {
        $title .= " - Cannot sth->bind_columns";
      } else {
        $counter = 0;
        my $limitTrendline = ($yMarkValue) ? $yMarkValue * 2.5 : 9000;

        while( $sth->fetch() ) {
          $seconden  = int(substr($duration, 6, 2)) + int(substr($duration, 3, 2)*60) + int(substr($duration, 0, 2)*3600);
          $seconden += 0.5 if ($seconden == 0); # correction for to fast testresults
          $ttimeslot = abs((($lastTimeslot - $timeslot) / $step) - $limitTest);

          if ($ttimeslot >= 0) {
            $status = 'UNKNOWN' if ($status eq '<NIHIL>');

      	    if ($status eq 'OK') {
              $dataOK[$ttimeslot] = ($seconden < $limitTrendline) ? $seconden : $limitTrendline;
            } elsif ($status eq 'CRITICAL') {
              $dataCritical[$ttimeslot] = '-5';
            } elsif ($status eq 'WARNING'){
              $dataWarning[$ttimeslot]  = '-5';
            } elsif ($status eq 'UNKNOWN'){
              $dataUnknown[$ttimeslot]  = '-5';
            } elsif ($status eq 'NO TEST') {
              $dataNoTest[$ttimeslot]   = '-5';
            } elsif ($status eq 'OFFLINE') {
              $dataOffline[$ttimeslot]  = '-5';
            }
          }

  	      $RRDlabels[int($limitTest - $counter - 1)] = substr($startTime, 0, 5) unless ( $counter % $xLabelStep );
          $counter++;
        }
      }

      $sth->finish() or $rv = errorTrapDBIgraphEntry("Cannot sth->finish: $findString", \$logger, $debug);
	}

    $dbh->disconnect or $rv = errorTrapDBIgraphEntry("Sorry, the database was unable to add your entry.", \$logger, $debug);
  } else {
    $title .= " - DBI_connect - Cannot connect to the database - alarm: $alarm - alarmMessage: $alarmMessage";
    $logger->info("     DBI_connect - Cannot connect to the database - alarm: $alarm - alarmMessage: $alarmMessage") if ( defined $logger and $logger->is_info() );
  }

  # Create a XYChart object of size $width x $hight pixels, using 0xf0e090 as background color, with a black border, and 0 pixel 3D border effect
  my $c = new XYChart($width, $hight, $background, 0x0, 0);

  # Set the plotarea at (xOffset, yOffset) and of size $width - 95 x $hight - 78 pixels, with white background. Set border and grid line colors.
  $c->setPlotArea($xOffset, $yOffset, $width - 95, $hight - 78, 0xffffff, -1, 0xa08040, $c->dashLineColor(0x0, 0x0101), $c->dashLineColor(0x0, 0x0101))->setGridWidth(1);

  # Add a title box to the chart using 10 pts Arial Bold Italic font. The text is white (0x000000)
  $c->addText($width/2, 14, "$title", "arialbi.ttf", 10, 0x000000, 5, 0);

  # Set labels on the x axis
  unless ( $xRealtime ) {
    for ($counter = 0; $counter < $limitTest; $counter += $xLabelStep) {
      $RRDlabels[int($limitTest - $counter - 1)] = substr(scalar(localtime(($lastTimeslot - ($step * ($counter))))), 11, 5); 
    }
  }

  $c->xAxis()->setLabels(\@RRDlabels);

  for ($counter = 0; $counter < $limitTest - $xLabelStep; $counter += $xLabelStep) {
    my $labelStep = $xLabelStep / 3;
    $c->xAxis()->addMark($counter + $labelStep, $c->dashLineColor(0x0, 0x103))->setDrawOnTop(0);
    $c->xAxis()->addMark($counter + ($labelStep * 2), $c->dashLineColor(0x0, 0x103))->setDrawOnTop(0);
  }

  # Set labels on the y axis
  $c->yAxis()->setLabelFormat("{value|2,.}");

  # Add a stacked bar layer to the chart
  my $layer = $c->addBarLayer2($perlchartdir::Stack);

  # Set the axes width to 1 pixels
  $c->yAxis()->setWidth(1);
  $c->xAxis()->setWidth(1);

  # Add a title to the y axis
  $c->yAxis()->setTitle("Response time", "arial.ttf", 9);

  # Set the margins at the two ends of the axis during auto-scaling, and whether to start the axis from zero
  $c->yAxis()->setAutoScale(0, 0, 0);

  # Add a mark line ore zone to the chart and add the first two data sets to the chart as a stacked bar group
  if ($yMarkValue) {
	if ($markOrZone) {
	  $c->yAxis()->addMark($yMarkValue, $yMarkColor);
  	} else {
	  $c->yAxis()->addZone($yMarkValue, 3600, $yMarkColor);
	  $c->yAxis()->addZone(0, -6, $yMarkColor);
    }

    $layer->addDataSet(\@dataOK, $layer->yZoneColor($yMarkValue, $COLORSRRD {OK}, $COLORSRRD {TRENDLINE}), " Duration");
  } else {
	$c->yAxis()->addZone(0, -6, $yMarkColor) unless ( $markOrZone );
    $layer->addDataSet(\@dataOK, $COLORSRRD {OK}, " Duration");
  }

  $layer->addDataSet(\@dataWarning,  $COLORSRRD {WARNING},   " Warning");
  $layer->addDataSet(\@dataCritical, $COLORSRRD {CRITICAL},  " Critical");
  $layer->addDataSet(\@dataUnknown,  $COLORSRRD {UNKNOWN},   " Unknown");
  $layer->addDataSet(\@dataNoTest,   $COLORSRRD {"NO TEST"}, " No test");
  $layer->addDataSet(\@dataOffline,  $COLORSRRD {OFFLINE},   " Offline");

  # Set the sub-bar gap to 0, so there is no gap between stacked bars with a group
  $layer->setBarGap(-1.7E-100, 0);

  # Set the bar border to transparent
  if ($withBorder) {
    $layer->setBorderColor(0xF0F0F0);
  } else {
    $layer->setBorderColor($perlchartdir::Transparent);
  }

  # Add a legend box
  $c->addLegend(2, $hight - 34, 0, "arial.ttf", 8)->setBackground($perlchartdir::Transparent);

  # Add a custom CDML text at the bottom right of the plot area as the logo
  $c->addText($width - 3, 92, $APPLICATION . " @ " . $BUSINESS, "arial.ttf", 8, 0x999999, 6, 270);
  $c->addText($width - 18, $hight - 21, "Interval: " . $interval . " min, " . $DEPARTMENT . " @ " . $BUSINESS . ", created on: " . scalar(localtime()) . ".", "arial.ttf", 8, 0x000000, 6, 0);

  #output the chart
  $c->makeChart("$dbiFilename.png");
	
  return $rv;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapDBIgraphEntry {
  my ($error_message, $logger, $debug) = @_;

  print 'errorTrapDBIgraphEntry', "\n", $error_message, "\nERROR: $DBI::err ($DBI::errstr)\n";
  $$logger->error("errorTrapDBIgraphEntry:\n" .$error_message. "\nERROR: $DBI::err ($DBI::errstr)") if ( defined $$logger and $$logger->is_error() );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_usage () {
  print "Usage: $PROGNAME -H <MySQL hostname> [-M <mode>] [-C <collectorlist>] [-W <screenDebug>] [-A <allDebug>] [-N <nokDebug>] [-s <dumphttp>] [-S <status>] [-D <debug>] [-V version] [-h help]\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help () {
  print_revision($PROGNAME, $version);
  print "ASNMTAP Collector for the '$APPLICATION'

-H, --hostname=<HOSTNAME>
   HOSTNAME   : hostname/address from the MySQL server
-M, --mode=O|L|C
   O(nce)     : run the program once
   L(oop)     : run the program as a loop
   C(rontab)  : run the program crontab based
-C, --collectorlist=<FILENAME>
   FILENAME   : filename from the collectorlist for the loop of crontab
-W, --screenDebug=F|T
   F(alse)    : all screendebugging off (default)
   T(true)    : all screendebugging on
-A, --allDebug=F|T
   F(alse)    : all file debugging off (default)
   T(true)    : all file debugging on
-N, --nokDebug=F|T
   F(alse)    : nok file debugging off (default)
   T(true)    : nok file debugging on
-s, --dumphttp=N|A|W|C|U
   N(one)     : httpdump off (default)
   A(ll)      : httpdump for all events
   W(arning)  : httpdump only the warning, critical and unknown critical events
   C(ritical) : httpdump only the critical and unknown critical events
   U(nknown)  : httpdump only the unknown critical events
-S, --status=N|S
   N(agios): Nagios custom plugin output (default)
   S(nmp)  : SNMP ...
-D, --debug=F|T|L
   F(alse)    : screendebugging off (default)
   T(true)    : normal screendebugging on
   L(ong)     : long screendebugging on
-V, --version
-h, --help

Send email to $SENDEMAILTO if you have questions regarding
use of this software. To submit patches or suggest improvements, send
email to $SENDEMAILTO

";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
