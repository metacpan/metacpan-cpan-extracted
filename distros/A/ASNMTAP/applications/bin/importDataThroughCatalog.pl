#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, importDataThroughCatalog.pl for ASNMTAP::Applications
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Getopt::Long;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time v3.002.003;
use ASNMTAP::Time qw(&get_datetimeSignal &get_logfiledate &get_datetime);

use ASNMTAP::Asnmtap::Applications v3.002.003;
use ASNMTAP::Asnmtap::Applications qw(:APPLICATIONS

                                      $RESULTSPATH
                                      $SMTPUNIXSYSTEM $SERVERLISTSMTP $SERVERSMTP $SENDMAILFROM
                                      &init_email_report &send_email_report 
                                      &DBI_connect &DBI_do &DBI_execute &DBI_error_trap
                                      &LOG_init_log4perl

                                      $DATABASE $CATALOGID $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE
                                      $SERVERTABLCATALOG $SERVERTABLCLLCTRDMNS $SERVERTABLCOMMENTS $SERVERTABLCRONTABS $SERVERTABLDISPLAYDMNS $SERVERTABLDISPLAYGRPS $SERVERTABLEVENTS $SERVERTABLEVENTSCHNGSLGDT $SERVERTABLEVENTSDISPLAYDT $SERVERTABLHOLIDYS $SERVERTABLHOLIDYSBNDL $SERVERTABLPAGEDIRS $SERVERTABLPLUGINS $SERVERTABLREPORTS $SERVERTABLREPORTSPRFDT $SERVERTABLRESULTSDIR $SERVERTABLSERVERS $SERVERTABLTIMEPERIODS $SERVERTABLUSERS $SERVERTABLVIEWS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($opt_T  $opt_M $opt_V $opt_h $opt_D $PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "importDataThroughCatalog.pl";
my $prgtext     = "Import Data Through Catalog for the '$APPLICATION'";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $debug       = 0;                                            # default 0
my $limit       = 1000;                                         # default 1000
my $type        = 3;                                            # default 3
my $logging     = $RESULTSPATH .'/';                            # default $RESULTSPATH .'/', disabled by '<NIHIL>'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $alarm       = 30;                                           # default 15

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $boolean_screenDebug = 0;									# default 0
my $boolean_debug_all   = 0;									# default 0
my $boolean_debug_NOK   = 0;									# default 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $booleanQuit = 0;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');

GetOptions (
  "T:s" => \$opt_T, "type:s"        => \$opt_T,
  "M=s" => \$opt_M, "mode=s"        => \$opt_M,
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  "D:s" => \$opt_D, "debug:s"       => \$opt_D,
  "V"   => \$opt_V, "version"       => \$opt_V,
  "h"   => \$opt_h, "help"          => \$opt_h
);

if ($opt_V) { print_revision($PROGNAME, $version); exit $ERRORS{OK}; }
if ($opt_h) { print_help(); exit $ERRORS{OK}; }

($opt_M) || usage("Mode not specified\n");
my $mode = $opt_M if ($opt_M eq 'O' || $opt_M eq 'D');
($mode) || usage("Invalid mode: $opt_M\n");
if ($mode eq 'O') { $booleanQuit = 1; }

if ($opt_D) {
  if ($opt_D eq 'F' || $opt_D eq 'T' || $opt_D eq 'L') {
    $debug = 0 if ($opt_D eq 'F');
    $debug = 1 if ($opt_D eq 'T');
    $debug = 2 if ($opt_D eq 'L');
  } else {
    usage("Invalid debug: $opt_D\n");
  }
}

if ($opt_T) {
  if ($opt_T eq 'CONFIG') {
    $type = 1;
  } elsif ($opt_T eq 'DATA') {
    $type = 2;
  } elsif ($opt_T eq 'ALL') {
    $type = 3;
  } else {
    usage("Invalid type: $opt_T\n");
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $logger = LOG_init_log4perl ( 'import::data::through::catalog', undef, $boolean_debug_all );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $boolean_daemonQuit    = 0;
my $boolean_signal_hup    = 0;
my $boolean_daemonControl = !$booleanQuit;

my $pidfile = $PIDPATH .'/importDataThroughCatalog.pid';

# Init parameters
my ($rv, $dbh, $sth, $sql, $alarmMessage);

if ($mode eq 'D') {
  printDebugAll ("Uitvoeren import data through catalog - : <$PROGNAME v$version pid: <$pidfile>");

  unless (fork) {                                  # unless ($pid = fork) {
    unless (fork) {
      # if ($boolean_daemonControl) { sleep until getppid == 1; }

      printDebugAll ("Main daemon control loop for: <$PROGNAME v$version pid: <$pidfile>\n");
      write_pid();

      if ($boolean_daemonControl) {
        printDebugAll (print "Set daemon catch signals for: <$PROGNAME v$version pid: <$pidfile>\n");
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
		  $boolean_signal_hup = 0;
		}

        # Update access and modify epoch time from the PID time
        utime (time(), time(), $pidfile) if (-e $pidfile);

        # Daemon implementation
        do_importDataThroughCatalog ();

        my ($prevSecs, $currSecs);
        $currSecs = int((localtime)[0]);

        do {
          sleep 5;
          $prevSecs = $currSecs;
          $currSecs = int((localtime)[0]);
        } until ($currSecs < $prevSecs);
      } until ($boolean_daemonQuit);

      exit 0;
    }

    exit 0;
  }

  printDebugAll ("Einde ... import data through catalog - : <$PROGNAME v$version pid: <$pidfile>");
  # if ($boolean_daemonControl) { waitpid($pid,0); }
} else {
  my ($emailReport, $rvOpen) = init_email_report (*EMAILREPORT, 'importDataThroughCatalog.txt', $debug);
  printDebugAll ("Start collector - : <$mode> <$PROGNAME v$version");
  do_importDataThroughCatalog ();
  printDebugAll ("Einde collector - : <$mode> <$PROGNAME v$version") if ($debug eq 'T');
  my ($rc) = send_email_report (*EMAILREPORT, $emailReport, $rvOpen, $prgtext, $debug);
}

exit;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signal_DIE {
  # printDebugAll ("kill -DIE <$PROGNAME v$version pid: <$pidfile>");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signal_WARN {
  # printDebugAll ("kill -WARN <$PROGNAME v$version pid: <$pidfile>");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signalQUIT {
  printDebugAll ("kill -QUIT <$PROGNAME v$version pid: <$pidfile>");
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
  my $subject = "$prgtext\@". hostname() .": import data through catalog successfully stopped at ". get_datetimeSignal();
  my $returnCode = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $subject ."\n", 0 );
  print "Problem sending email to the '$APPLICATION' server administrators\n" unless ( $returnCode );

  exit 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signalHUP {
  printDebugAll ("kill -HUP <$PROGNAME v$version pid: <$pidfile>");
  $boolean_signal_hup = 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub write_pid {
  printDebugAll ("write PID <$PROGNAME v$version pid: <$pidfile>");

  if (-e "$pidfile") {
    printDebugAll ("ERROR: couldn't create pid file <$pidfile> for <$PROGNAME v$version>");
    print "ERROR: couldn't create pid file <$pidfile> for <$PROGNAME v$version>\n";
    exit 0;
  } else {
    open(PID,">$pidfile") || die "Cannot open $pidfile!!\n";
    print PID $$;
    close(PID);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printDebugAll {
  my ($l_text) = @_;

  if ($boolean_screenDebug or $boolean_debug_all) {
    chomp ($l_text);

    my $date = scalar(localtime());
    my $tlogging = $logging .'importDataThroughCatalog'. get_logfiledate();
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
    my $tlogging = $logging .'importDataThroughCatalog'. get_logfiledate();
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

sub do_importDataThroughCatalog {
  printDebugAll (" IN: do_importDataThroughCatalog <$PROGNAME v$version pid: <$pidfile>");
  ($dbh, $rv, $alarmMessage) = DBI_connect ( $DATABASE, $SERVERNAMEREADWRITE, $SERVERPORTREADWRITE, $SERVERUSERREADWRITE, $SERVERPASSREADWRITE, $alarm, \&DBI_error_trap, [*EMAILREPORT, "Cannot connect to the database"], \$logger, $debug, $boolean_debug_all );

  if ($dbh and $rv) {
    my ($catalogID, $catalogType, $databaseFQDN, $databasePort);
    $sql = "select catalogID, catalogType, databaseFQDN, databasePort from $SERVERTABLCATALOG where catalogID <> '$CATALOGID' and catalogType <> 'central' and activated = '1'";
    $sth = $dbh->prepare( $sql ) or $rv = DBI_error_trap(*EMAILREPORT, "Cannot dbh->prepare: $sql", \$logger, $debug);
    ($rv, undef) = DBI_execute ($rv, \$sth, $alarm, \&DBI_error_trap, [*EMAILREPORT, "Cannot sth->execute: $sql"], \$logger, $debug);
    $sth->bind_columns( \$catalogID, \$catalogType, \$databaseFQDN, \$databasePort ) or $rv = DBI_error_trap(*EMAILREPORT, "Cannot sth->bind_columns: $sql", \$logger, $debug) if $rv;

    if ( $rv ) {
      my %catalog;

      if ( $sth->rows ) {
        while( $sth->fetch() ) {
          print "- $catalogID, $catalogType, $databaseFQDN, $databasePort\n" if ($debug);
          $catalog{$catalogID}{catalogType}  = $catalogType;
          $catalog{$catalogID}{databaseFQDN} = $databaseFQDN;
          $catalog{$catalogID}{databasePort} = $databasePort;
        }
      }

      $sth->finish() or $rv = DBI_error_trap(*EMAILREPORT, "Cannot sth->finish: $sql", \$logger, $debug);

      foreach my $catalogID ( keys %catalog ) {
        if ($debug) {
          print "+ Catalog ID: $catalogID\n"; 
          print "  - catalogType  => ". $catalog{$catalogID}{catalogType} ."\n";
          print "  - databaseFQDN => ". $catalog{$catalogID}{databaseFQDN} ."\n";
          print "  - databasePort => ". $catalog{$catalogID}{databasePort} ."\n";
        }

        # Open connection to database and query data
        my $dbhSOURCE;
        ($dbhSOURCE, $rv, $alarmMessage) = DBI_connect ( $DATABASE, $catalog{$catalogID}{databaseFQDN}, $catalog{$catalogID}{databasePort}, $SERVERUSERREADWRITE, $SERVERPASSREADWRITE, $alarm, \&DBI_error_trap, [*EMAILREPORT, "Cannot connect to the database"], \$logger, $debug, $boolean_debug_all );

        if ($dbhSOURCE and $rv) {
          print EMAILREPORT "\nCatalog ID: $catalogID\n" unless ($debug);

          # config contrains: events, eventsChangesLogData & comments = = =
          if ( $type == 1 or $type == 3 ) {
            if ($debug) {
              print "- config contrains: events, eventsChangesLogData & comments\n";
            } else {
              print EMAILREPORT "\n- config contrains: events, eventsChangesLogData & comments\n";
            }

            # 1 - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLHOLIDYS,         "catalogID = '$catalogID'", 'holidayID');
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLUSERS,           "catalogID = '$catalogID'", 'remoteUser');
            # 2 - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLHOLIDYSBNDL,     "catalogID = '$catalogID'", 'holidayBundleID');
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLRESULTSDIR,      "catalogID = '$catalogID'", 'resultsdir');
            # 3 - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLPLUGINS,         "catalogID = '$catalogID'", 'uKey');
          }

          # events, eventsChangesLogData & comments = = = = = = = = = = =
          if ( $type >= 2 ) {
            if ($debug) {
              print "- events, eventsChangesLogData & comments\n";
            } else {
              print EMAILREPORT "\n- events, eventsChangesLogData & comments\n";
            }

            # 4 - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 1, $SERVERTABLEVENTS,          "catalogID = '$catalogID' and replicationStatus <> 'R'", 'uKey', 'timeslot');
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 1, $SERVERTABLEVENTSCHNGSLGDT, "catalogID = '$catalogID' and replicationStatus <> 'R'", 'uKey');
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 1, $SERVERTABLEVENTSDISPLAYDT, "catalogID = '$catalogID' and replicationStatus <> 'R'", 'uKey', 'posTimeslot');
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 1, $SERVERTABLCOMMENTS,        "catalogID = '$catalogID' and replicationStatus <> 'R'", 'uKey', 'entryTimeslot');
          }

          # config contrains: ALL = = = = = = = = = = = = = = = = = = = =

          if ( $type == 1 or $type == 3 ) {
            if ($debug) {
              print "- config contrains: ALL\n";
            } else {
              print EMAILREPORT "\n- config contrains: ALL\n";
            }

            # 1'- - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLTIMEPERIODS,     "catalogID = '$catalogID'", 'timeperiodID');
            # 2'- - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLDISPLAYGRPS,     "catalogID = '$catalogID'", 'displayGroupID');
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLPAGEDIRS,        "catalogID = '$catalogID'", 'pagedir');
            # 3'- - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLSERVERS,         "catalogID = '$catalogID'", 'serverID');
            # 4'- - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLCLLCTRDMNS,      "catalogID = '$catalogID'", 'collectorDaemon');
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLDISPLAYDMNS,     "catalogID = '$catalogID'", 'displayDaemon');
            # 5'- - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLCRONTABS,        "catalogID = '$catalogID'", 'lineNumber', 'uKey');
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLVIEWS,           "catalogID = '$catalogID'", 'uKey', 'displayDaemon');
            # 6'- - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLREPORTS,         "catalogID = '$catalogID'", 'id');
            importData (*EMAILREPORT, $dbhSOURCE, $dbh, 0, $SERVERTABLREPORTSPRFDT,    "catalogID = '$catalogID'", 'uKey', 'metric_id');
          }

          # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

          $dbhSOURCE->disconnect or $rv = DBI_error_trap(*EMAILREPORT, "Sorry, the database was unable to add your entry.", \$logger, $debug);
        }
      }
    }

    $dbh->disconnect or $rv = DBI_error_trap(*EMAILREPORT, "Sorry, the database was unable to add your entry.", \$logger, $debug);
  }

  printDebugAll ("OUT: do_importDataThroughCatalog <$PROGNAME v$version pid: <$pidfile>");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub importData {
  my ($EMAILREPORT, $dbhSOURCE, $dbh, $replicationStatus, $table, $whereCLAUSE, @primaryKeys) = @_;

  printDebugAll ("     IN: importData <$PROGNAME v$version pid: <$pidfile>: $replicationStatus, $table, $whereCLAUSE, @primaryKeys");
  print $EMAILREPORT "  - importData: $replicationStatus, $table, $whereCLAUSE, @primaryKeys\n" unless ($debug);

  my $sqlSOURCE = "select * from `$table` where $whereCLAUSE limit $limit";
  print "+ $sqlSOURCE\n" if ($debug);

  my $sthSOURCE = $dbhSOURCE->prepare( $sqlSOURCE ) or $rv = DBI_error_trap(*EMAILREPORT, "Cannot dbhSOURCE->prepare: $sqlSOURCE", \$logger, $debug);
  ($rv, undef) = DBI_execute ($rv, \$sthSOURCE, $alarm, \&DBI_error_trap, [*EMAILREPORT, "Cannot sthSOURCE->execute: $sqlSOURCE"], \$logger, $debug);

  if ( $rv ) {
    while (my $ref = $sthSOURCE->fetchrow_hashref()) {
      my ($whereReplicationStatus, $where, $action) = ("where $whereCLAUSE", '');
      foreach my $primaryKey (@primaryKeys) { $whereReplicationStatus .= " and $primaryKey = '$ref->{$primaryKey}'" };

      my $sqlVERIFY = "select count(catalogID) from `$table` $whereReplicationStatus";
      print "... $sqlVERIFY\n" if ( $debug );
      my $sthVERIFY = $dbh->prepare( $sqlVERIFY ) or $rv = DBI_error_trap(*EMAILREPORT, "Cannot dbh->prepare: $sqlVERIFY", \$logger, $debug);
     ($rv, undef) = DBI_execute ($rv, \$sthVERIFY, $alarm, \&DBI_error_trap, [*EMAILREPORT, "Cannot $sthVERIFY->execute: $sqlVERIFY"], \$logger, $debug);

      if ( $rv ) {
        my $updateRecord = $sthVERIFY->fetchrow_array();
        $sthVERIFY->finish() or $rv = DBI_error_trap(*EMAILREPORT, "Cannot sthVERIFY->finish: $sqlVERIFY", \$logger, $debug);

        if ( $updateRecord ) {
          $action = "UPDATE `$table` SET";
          $where  = $whereReplicationStatus;
        } else {
          $action = "INSERT INTO `$table` SET";
        }

        foreach my $databaseField ( @{$sthSOURCE->{NAME}} ) { 
          my $value = ( ( defined $ref->{$databaseField} ) ? $ref->{$databaseField} : '' );
          $action .= " $table.$databaseField = \"$value\",";
        }

        chop $action if (defined $action);

        my $sql = "$action $where";
        print "  - $sql\n" if ($debug);
        ($rv, undef, undef) = DBI_do ($rv, \$dbh, $sql, $alarm, \&DBI_error_trap, [*EMAILREPORT, "Cannot dbh->do: $sql"], \$logger, $debug);
		
        if ( $rv and $replicationStatus ) {
          $sql = "UPDATE `$table` SET replicationStatus = 'R' $whereReplicationStatus";
          print "  + $sql\n" if ($debug);
          $dbhSOURCE->do ( $sql ) or $rv = DBI_error_trap(*EMAILREPORT, "Cannot $dbhSOURCE->do: $sql", \$logger, $debug);
        }
      }
    }

    $sthSOURCE->finish() or $rv = DBI_error_trap(*EMAILREPORT, "Cannot sthSOURCE->finish: $sqlSOURCE", \$logger, $debug);
  }

  print $EMAILREPORT "  ERROR: DBH/STH\n" unless ($debug or $rv);
  printDebugAll ("    OUT: importData <$PROGNAME v$version pid: <$pidfile>");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_usage () {
  print "Usage: $PROGNAME [-T <CONFIG|DATA|ALL>] [-D <debug>] [-V version] [-h help]\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help () {
  print_revision($PROGNAME, $version);
  print "ASNMTAP Import Data Through Catalog for the '$APPLICATION'

-T, --type=<CONFIG|DATA|ALL> (default: current ALL)
-M, --mode=O|D
   O(nce)   : run the program once
   D(aemon) : run the program as a loop
-D, --debug=F|T|L
   F(alse)  : screendebugging off (default)
   T(true)  : normal screendebugging on
   L(ong)   : long screendebugging on
-V, --version
-h, --help

Send email to $SENDEMAILTO if you have questions regarding
use of this software. To submit patches or suggest improvements, send
email to $SENDEMAILTO

";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
