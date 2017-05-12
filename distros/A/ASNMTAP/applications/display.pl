#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, display.pl for ASNMTAP::Asnmtap::Applications::Display
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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time v3.002.003;
use ASNMTAP::Time qw(&get_datetimeSignal &get_hour &get_timeslot);

# because it is not yet exported by the ASNMTAP::Asnmtap::Applications::Display module
use ASNMTAP::Asnmtap::Applications v3.002.003;
use ASNMTAP::Asnmtap::Applications qw($SERVERTABLDISPLAYDMNS $SERVERTABLPLUGINS $SERVERTABLTIMEPERIODS $SERVERTABLVIEWS);

use ASNMTAP::Asnmtap::Applications::Display v3.002.003;
use ASNMTAP::Asnmtap::Applications::Display qw(:APPLICATIONS :DISPLAY :DBDISPLAY &encode_html_entities);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($opt_H $opt_V $opt_h $opt_C $opt_P $opt_D $opt_L $opt_t $opt_c $opt_T $opt_l $PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "display.pl";
my $prgtext     = "Display for the '$APPLICATION'";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $checklist   = "DisplayCT";                                  # default
my $htmlOutput  = $HTTPSPATH .'/nav/index/index';               # default
my $pagedir     = 'index';                                      # default
my $pageset     = 'index';                                      # default
my $debug       = 0;                                            # default
my $loop        = 0;                                            # default
my $trigger     = 0;                                            # default
my $creationTime;                                               # default
my $displayTime = 1;                                            # default
my $lockMySQL   = 0;                                            # default

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $displayTimeslot = 0;           # only for extra debugging information

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');

GetOptions (
  "V"   => \$opt_V, "version"        => \$opt_V,
  "h"   => \$opt_h, "help"           => \$opt_h,
  "H=s" => \$opt_H, "hostname=s"     => \$opt_H,
  "C:s" => \$opt_C, "checklist:s"    => \$opt_C,
  "P:s" => \$opt_P, "pagedir:s"      => \$opt_P,
  "D:s" => \$opt_D, "debug:s"        => \$opt_D,
  "L:s" => \$opt_L, "loop:s"         => \$opt_L,
  "t:s" => \$opt_t, "trigger:s"      => \$opt_t,
  "c:s" => \$opt_c, "creationTime:s" => \$opt_c,
  "T:s" => \$opt_T, "displayTime:s"  => \$opt_T,
  "l:s" => \$opt_l, "lockMySQL:s"    => \$opt_l
);

if ($opt_V) { print_revision($PROGNAME, $version); exit; }
if ($opt_h) { print_help(); exit; }

($opt_H) || usage("MySQL hostname/address not specified\n");
my $serverName = $1 if ($opt_H =~ /([-.A-Za-z0-9]+)/);
($serverName) || usage("Invalid MySQL hostname/address: $opt_H\n");

if ($opt_C) { $checklist = $1 if ($opt_C =~ /([-.A-Za-z0-9]+)/); }
if ($opt_P) { $pagedir = $opt_P; }

if ($opt_D) {
  if ($opt_D eq 'F' || $opt_D eq 'T') {
    $debug = ($opt_D eq 'F') ? 0 : 1;
  } else {
    usage("Invalid debug: $opt_D\n");
  }
}

if ($opt_L) {
  if ($opt_L eq 'F' || $opt_L eq 'T') {
    $loop = ($opt_L eq 'F') ? 0 : 1;

    if ($opt_c) {
      if ($opt_c =~ /^20\d\d-(?:0\d|1[0-2])-(?:[0-2]\d|3[0-1]) (?:[0-1]\d|2[0-3]):[0-5]\d:[0-5]\d$/) {
        $creationTime = $opt_c;
      } else {
        usage("Invalid creation time <YYYY-MM-DD HH:MM:SS>: $opt_c\n");
      }
    }
  } else {
    usage("Invalid loop: $opt_L\n");
  }
}

if ($opt_t) {
  if ($opt_t eq 'F' || $opt_t eq 'T') {
    $trigger = ($opt_t eq 'F') ? 0 : 1;
  } else {
    usage("Invalid trigger: $opt_t\n");
  }
}

if ($opt_T) {
  if ($opt_T eq 'F' || $opt_T eq 'T') {
    $displayTime = ($opt_T eq 'F') ? 0 : 1;
  } else {
    usage("Invalid displayTime: $opt_T\n");
  }
}

if ($opt_l) {
  if ($opt_l eq 'F' || $opt_l eq 'T') {
    $lockMySQL = ($opt_l eq 'F') ? 0 : 1;
  } else {
    usage("Invalid lockMySQL: $opt_l\n");
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($dchecklist, $dtest, $dfetch, $tinterval, $tgroep, $resultsdir, $ttest, $firstTimeslot, $lastTimeslot, $rvOpen);
my (@fetch, $dstart, $tstart, $start, $step, $names, $data, $rows, $columns, $line, $val, @vals);
my ($command, $tstatus, $tduration, $timeValue, $prevGroep, @multiarrayFullCondensedView, @multiarrayMinimalCondensedView);
my ($rv, $dbh, $sth, $lockString, $findString, $unlockString, $doChecklist, $timeCorrectie, $timeslot);
my ($groupFullView, $groupCondensedView, $emptyFullView, $emptyCondencedView, $emptyMinimalCondencedView, $itemFullCondensedView);
my ($checkOk, $checkSkip, $configNumber, $printCondensedView, $problemSolved, $verifyNumber, $inProgressNumber);
my ($playSoundInProgress, $playSoundPreviousStatus, $playSoundStatus, %tableSoundStatusCache);
my ($prevHour, $currHour, %timeperiodID_days, %catalogID_uKey_timeperiodID) = (-1, -1);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $boolean_daemonQuit    = 0;
my $boolean_signal_hup    = 0;
my $boolean_daemonControl = $loop;

my $colspanDisplayTime = $NUMBEROFFTESTS+2;
$colspanDisplayTime += $NUMBEROFFTESTS if $displayTime;

my $pidfile = $PIDPATH .'/'. $checklist .'.pid';

my @checklisttable = read_table($prgtext, $checklist, $loop, $debug);
resultsdirCreate();

my $pagedirBuildHash = ($pagedir =~ /^_loop_(?:[a-zA-Z0-9-]+)_(.*)$/) ? $1 : $pagedir;
build_hash_timeperiodID_days ($checklist, $pagedirBuildHash, \%timeperiodID_days, $debug);
build_hash_catalogID_uKey_timeperiodID ($checklist, $pagedirBuildHash, \%catalogID_uKey_timeperiodID, $debug);

my $directory = $HTTPSPATH .'/nav/'. $pagedir;
create_dir ($directory) unless ( -e "$directory" );

my $pagedirOrig = $pagedir;

unless (fork) {                                  # unless ($pid = fork) {
  unless (fork) {
#   if ($boolean_daemonControl) { sleep until getppid == 1; }

    print "Main Daemon control loop for: <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";
    write_pid() if ($boolean_daemonControl);

    if ($boolean_daemonControl) {
      print "Set daemon catch signals for: <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";
      write_tableSoundStatusCache ($checklist, $debug);
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
        @checklisttable = read_table($prgtext, $checklist, ( $loop ? 2 : 0 ), $debug);
        resultsdirCreate();

        build_hash_timeperiodID_days ($checklist, $pagedirBuildHash, \%timeperiodID_days, $debug);
        build_hash_catalogID_uKey_timeperiodID ($checklist, $pagedirBuildHash, \%catalogID_uKey_timeperiodID, $debug);

        $boolean_signal_hup = 0;
      }

      # Crontab implementation
      read_tableSoundStatusCache ($checklist, $debug);
      foreach ('P', 'A', 'S', 'T', 'D', 'L') { do_crontab ($_); }

      # Update access and modify epoch time from the PID time
      utime (time(), time(), $pidfile) if (-e $pidfile);

      if ( $loop ) {
        my ($prevSecs, $currSecs);
        $currSecs = int((localtime)[0]);

        do {
          sleep 5;
          $prevSecs = $currSecs;
          $currSecs = int((localtime)[0]);
        } until ($currSecs < $prevSecs);

        $currHour = get_hour();

        if ( $prevHour != $currHour ) {
          build_hash_timeperiodID_days ($checklist, $pagedirBuildHash, \%timeperiodID_days, $debug);
          build_hash_catalogID_uKey_timeperiodID ($checklist, $pagedirBuildHash, \%catalogID_uKey_timeperiodID, $debug);
          $prevHour = $currHour;
        }
      }

      write_tableSoundStatusCache ($checklist, $debug);
    } until ($boolean_daemonQuit);

    exit 0;
  }

  exit 0;
}

# if ($boolean_daemonControl) { waitpid($pid,0); }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub resultsdirCreate {
  foreach $dchecklist (@checklisttable) {
    my (undef, undef, $resultsdir, undef) = split(/\#/, $dchecklist, 4);
    my $logging = $RESULTSPATH .'/'. $resultsdir;
    create_dir ($logging);
    $logging .= "/";
    create_header ($logging ."HEADER.html");
    create_footer ($logging ."FOOTER.html");
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub read_tableSoundStatusCache {
  my ($checklist, $debug) = @_;

  %tableSoundStatusCache = ();

  if (-e "$APPLICATIONPATH/tmp/$checklist-sound-status.cache") {
    my $rvOpen = open(READ, "$APPLICATIONPATH/tmp/$checklist-sound-status.cache");

    if ($rvOpen) {
      while (<READ>) {
        chomp;

        if ($_ ne '') {
          my ($key, $value) = split (/=>/, $_);
          $tableSoundStatusCache { $key } = $value;
        }
      }

  	  close(READ);

      if ($debug) {
        print "$APPLICATIONPATH/tmp/$checklist-sound-status.cache: READ\n";
        print "-->\n";
        while ( my ($key, $value) = each(%tableSoundStatusCache) ) { print "'$key' => '$value'\n"; }
        print "<--\n";
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub write_tableSoundStatusCache {
  my ($checklist, $debug) = @_;

  my $rvOpen = open(WRITE, ">$APPLICATIONPATH/tmp/$checklist-sound-status.cache");

  if ($rvOpen) {
    print "\n$APPLICATIONPATH/tmp/$checklist-sound-status.cache: WRITE\n-->\n" if ($debug);

    while ( my ($key, $value) = each(%tableSoundStatusCache) ) { 
      print WRITE "$key=>$value\n";
      print "'$key' => '$value'\n" if ($debug); 
    }

    close(WRITE);
    print "<--\n" if ($debug);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub do_crontab {
  my ($Cenvironment) = @_;

  $pagedir = $pagedirOrig;
  $pagedir .= "/$Cenvironment" unless ($Cenvironment eq 'P');
  my $directory = $HTTPSPATH .'/nav/'. $pagedir;
  create_dir ($directory) unless ( -e "$directory" );
  $htmlOutput = $directory .'/'. $pageset;

  $rvOpen = open(HTML, ">$htmlOutput.tmp");

  unless ( $rvOpen ) {
    print "Cannot open $htmlOutput.tmp to create the html information\n";
    exit 0;
  }

  $rvOpen = open(HTMLCV, ">$htmlOutput-cv.tmp");

  unless ( $rvOpen ) {
    print "Cannot open $htmlOutput-cv.tmp to create the html information\n";
    exit 0;
  }

  $rvOpen = open(HTMLMCV, ">$htmlOutput-mcv.tmp");

  unless ( $rvOpen ) {
    print "Cannot open $htmlOutput-mcv.tmp to create the html information\n";
    exit 0;
  }

  $prevGroep = '';
  my $dstatusMessage;

  my $creationDate;

  if ( defined $creationTime ) {
    my ($date, $time) = split (/ /, $creationTime);
    my ($year, $month, $day) = split (/-/, $date);
    my ($hour, $minute, $seconds) = split (/:/, $time);
    $creationDate = timelocal ( $seconds, $minute, $hour, $day, $month-1, $year-1900 );
    printHtmlHeader( $APPLICATION .' - '. $ENVIRONMENT{$Cenvironment} .' from '. $CATALOGID .' ('. scalar(localtime($creationDate)) .')' );
  } else {
    $creationDate = time();
    printHtmlHeader( $APPLICATION .' - '. $ENVIRONMENT{$Cenvironment} .' from '. $CATALOGID );
  }

  $rv  = 1;
  $dbh = DBI->connect("DBI:mysql:$DATABASE:$serverName:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE") or $rv = errorTrapDBI($checklist, "Cannot connect to the database");

  if ($lockMySQL) {
    if ($dbh and $rv) {
      $lockString = 'LOCK TABLES ' .$SERVERTABLEVENTS. ' READ';
      $dbh->do ( $lockString ) or $rv = errorTrapDBI($checklist, "Cannot dbh->do: $lockString");
    }
  }

  $configNumber = $playSoundStatus = 0;
  $doChecklist = ($dbh and $rv) ? 1 : 0;
  $emptyFullView = $emptyCondencedView = $emptyMinimalCondencedView = 1;

  if ($doChecklist) {
    my %inMCV = ();
    $inMCV{WARNING}{CRITICAL}   = 1;
    $inMCV{WARNING}{UNKNOWN}    = 1;
    $inMCV{WARNING}{DEPENDENT}  = 1;

    $inMCV{CRITICAL}{WARNING}   = 1;
    $inMCV{CRITICAL}{UNKNOWN}   = 1;
    $inMCV{CRITICAL}{DEPENDENT} = 1;

    $inMCV{UNKNOWN}{WARNING}    = 1;
    $inMCV{UNKNOWN}{CRITICAL}   = 1;
    $inMCV{UNKNOWN}{DEPENDENT}  = 1;

    $inMCV{DEPENDENT}{WARNING}  = 1;
    $inMCV{DEPENDENT}{CRITICAL} = 1;
    $inMCV{DEPENDENT}{UNKNOWN}  = 1;

    $groupFullView = $groupCondensedView = 0;

    foreach $dchecklist (@checklisttable) {
      ($tinterval, $tgroep, $resultsdir, $ttest) = split(/\#/, $dchecklist, 4);
      my @stest = split(/\|/, $ttest);

      my $showGroepHeader = ($prevGroep ne $tgroep) ? 1 : 0;
      my $showGroepFooter = (($prevGroep ne '') && $showGroepHeader) ? 1 : 0;
      printGroepCV($prevGroep, $showGroepHeader, 1);
      $prevGroep = $tgroep;
      printGroepFooter('', $showGroepFooter);
      printGroepHeader($tgroep, $showGroepHeader);

      foreach $dtest (@stest) {
        my ($catalogID_uniqueKey, $title, $test, $help) = split(/\#/, $dtest);

        my ($catalogID, $uniqueKey) = split(/_/, $catalogID_uniqueKey);

        unless ( defined $uniqueKey ) {
          $uniqueKey = $catalogID;
          $catalogID = $CATALOGID;
          $catalogID_uniqueKey = $catalogID .'_'. $uniqueKey unless ( $catalogID eq 'CID' );
        }

        my ($command, undef) = split(/\.pl/, $test);

        my $environment = (($test =~ /\-\-environment=([PASTDL])/) ? $1 : 'P');
        next if (defined $environment and $environment ne $Cenvironment);
        $configNumber++;

        my $trendline = get_trendline_from_test($test);
        my $commandPopup = maskPassword ($test);
        $commandPopup =~ s/(?:\s+(--environment=[PASTDL]|--trendline=\d+))//g;
        my $popup = "<TR><TD BGCOLOR=#000080 WIDTH=100 ALIGN=RIGHT>Command</TD><TD BGCOLOR=#0000FF>$commandPopup</TD></TR><TR><TD BGCOLOR=#000080 WIDTH=100 ALIGN=RIGHT>Environment</TD><TD BGCOLOR=#0000FF>".$ENVIRONMENT{$environment}."</TD></TR><TR><TD BGCOLOR=#000080 WIDTH=100 ALIGN=RIGHT>Interval</TD><TD BGCOLOR=#0000FF>$tinterval</TD></TR><TR><TD BGCOLOR=#000080 WIDTH=100 ALIGN=RIGHT>Trendline</TD><TD BGCOLOR=#0000FF>$trendline</TD></TR>";
        print "<", $CATALOGID, "><", $environment, "><", $trendline, "><", $tgroep, "><", $resultsdir, "><", $catalogID_uniqueKey, "><", $catalogID, "><", $uniqueKey, "><", $title, "><", $test, ">\n" if ($debug);
        my $number = 1;
        my ($statusIcon, $itemTitle, $itemStatus, $itemTimeslot, $itemStatusIcon, $itemInsertInMCV, $inIMW);
        $itemTimeslot = $itemStatusIcon = $itemInsertInMCV = 0;
        $inIMW = 1;

        my @arrayStatusMessage = ();

        if ($dbh and $rv) {
          my ($acked, $sql, $tLastStatus, $tLastTimeslot, $tPrevStatus, $tPrevTimeslot, $activationTimeslot, $suspentionTimeslot, $instability, $persistent, $downtime, $suspentionTimeslotPersistentTrue, $suspentionTimeslotPersistentFalse, $comment);

          # TODO APE: Only one run a day is OK on 00:00:00 to cleanup automatically scheduled donwtimes
          my ($localYear, $localMonth, $currentYear, $currentMonth, $currentDay, $currentHour, $currentMin, $currentSec) = ((localtime)[5], (localtime)[4], ((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3,2,1,0]);

          if ( $currentHour == 0 and $currentMin <= 15 ) {
            my $solvedDate     = "$currentYear-$currentMonth-$currentDay";
            my $solvedTime     = "$currentHour:$currentMin:$currentSec";
            my $solvedTimeslot = timelocal($currentSec, $currentMin, $currentHour, $currentDay, $localMonth, $localYear);
            $sql = 'UPDATE ' .$SERVERTABLCOMMENTS. ' SET replicationStatus="U", problemSolved="1", solvedDate="' .$solvedDate. '", solvedTime="' .$solvedTime. '", solvedTimeslot="' .$solvedTimeslot. '" where catalogID="'. $CATALOGID. '" and problemSolved="0" and downtime="1" and persistent="0" and "' .$solvedTimeslot. '">suspentionTimeslot';
            $dbh->do ( $sql ) or $rv = errorTrapDBI($checklist, "Cannot dbh->do: $sql");
          }

          # <- end

          $sql = "select SQL_NO_CACHE lastStatus, lastTimeslot, prevStatus, prevTimeslot from $SERVERTABLEVENTSCHNGSLGDT where catalogID = '$catalogID' and uKey = '$uniqueKey'";
          $sth = $dbh->prepare( $sql ) or $rv = errorTrapDBI($checklist, "Cannot dbh->prepare: $sql");
          $sth->execute or $rv = errorTrapDBI($checklist, "Cannot sth->execute: $sql") if $rv;

          if ( $rv ) {
            ( $tLastStatus, $tLastTimeslot, $tPrevStatus, $tPrevTimeslot ) = $sth->fetchrow_array();
            $sth->finish() or $rv = errorTrapDBI($checklist, "Cannot sth->finish: $sql");
          }

          $sql = "select SQL_NO_CACHE activationTimeslot, suspentionTimeslot, instability, persistent, downtime, commentData, entryDate, entryTime, activationDate, activationTime, suspentionDate, suspentionTime from $SERVERTABLCOMMENTS where catalogID = '$catalogID' and uKey = '$uniqueKey' and problemSolved = '0' order by persistent desc, entryTimeslot desc";
          $sth = $dbh->prepare( $sql ) or $rv = errorTrapDBI($checklist, "Cannot dbh->prepare: $sql");
          $sth->execute or $rv = errorTrapDBI($checklist, "Cannot sth->execute: $sql") if $rv;
          my $statusOverlib = '<NIHIL>'; # $STATE{$ERRORS{'NO DATA'}};
          $instability = $downtime = 0;

          if ( $rv ) {
            my ($TactivationTimeslot, $TsuspentionTimeslot, $Tinstability, $Tpersistent, $Tdowntime, $TcommentData, $TentryDate, $TentryTime, $TactivationDate, $TactivationTime, $TsuspentionDate, $TsuspentionTime, $firstRecordPersistentTrue, $firstRecordPersistentFalse);
            $acked = $sth->rows;
            $persistent = -1;
            $activationTimeslot = 9999999999;
            $firstRecordPersistentTrue = $firstRecordPersistentFalse = 1;
            $suspentionTimeslot = $suspentionTimeslotPersistentTrue = $suspentionTimeslotPersistentFalse = 0;

            if ( $acked ) {
              while( ($TactivationTimeslot, $TsuspentionTimeslot, $Tinstability, $Tpersistent, $Tdowntime, $TcommentData, $TentryDate, $TentryTime, $TactivationDate, $TactivationTime, $TsuspentionDate, $TsuspentionTime) = $sth->fetchrow_array() ) {
                if ( int($TactivationTimeslot) <= get_timeslot ($creationDate) and get_timeslot ($creationDate) <= int($TsuspentionTimeslot) ) {
                  $instability = ( $Tinstability ) ? 1 : $instability;

                  if ( $Tpersistent ) {
                    if ( $firstRecordPersistentTrue ) {
                      $persistent = 1;
                      $firstRecordPersistentTrue = 0;
                      $suspentionTimeslotPersistentTrue = int($TsuspentionTimeslot);
                    }

                    $suspentionTimeslotPersistentTrue = ($suspentionTimeslotPersistentTrue > int($TsuspentionTimeslot)) ? $suspentionTimeslotPersistentTrue : int($TsuspentionTimeslot);
                  } else {
                    if ( $firstRecordPersistentFalse ) {
                      $persistent = $firstRecordPersistentFalse = 0;
                      $suspentionTimeslotPersistentFalse = int($TsuspentionTimeslot);
                    }

                    $suspentionTimeslotPersistentFalse = ($suspentionTimeslotPersistentFalse > int($TsuspentionTimeslot)) ? $suspentionTimeslotPersistentFalse : int($TsuspentionTimeslot);
                  }

                  $downtime = ( $Tdowntime ) ? 1 : $downtime;
                  $activationTimeslot = ($activationTimeslot < int($TactivationTimeslot)) ? $activationTimeslot : int($TactivationTimeslot);
                  $suspentionTimeslot = ($suspentionTimeslot > int($TsuspentionTimeslot)) ? $suspentionTimeslot : int($TsuspentionTimeslot);
                }

                $TcommentData =~ s/'/`/g;
                $TcommentData =~ s/[\n\r]+(Updated|Edited|Closed) by: (?:.+), (?:.+) \((?:.+)\) on (\d{4}-\d\d-\d\d) (\d\d:\d\d:\d\d)/\n\r$1 on $2 $3/g;
                $TcommentData =~ s/[\n\r]/<br>/g;
                $TcommentData =~ s/(?:<br>)+/<br>/g;
                $comment .= "<TABLE WIDTH=100% BORDER=0 CELLSPACING=1 CELLPADDING=2 BGCOLOR=#000000><TR><TD BGCOLOR=#000080 ALIGN=CENTER>&nbsp;Entry Date/Time&nbsp;</TD><TD BGCOLOR=#000080 ALIGN=CENTER>&nbsp;Activation Date/Time&nbsp;</TD><TD BGCOLOR=#000080 ALIGN=CENTER>&nbsp;Suspention Date/Time&nbsp;</TD><TD BGCOLOR=#000080 ALIGN=CENTER>&nbsp;Instability&nbsp;</TD><TD BGCOLOR=#000080 ALIGN=CENTER>&nbsp;Persistent&nbsp;</TD><TD BGCOLOR=#000080 ALIGN=CENTER>&nbsp;Downtime&nbsp;</TD></TR><TR><TD ALIGN=CENTER>&nbsp;$TentryDate - $TentryTime&nbsp;</TD><TD ALIGN=CENTER>&nbsp;$TactivationDate - $TactivationTime&nbsp;</TD><TD ALIGN=CENTER>&nbsp;$TsuspentionDate - $TsuspentionTime</TD><TD ALIGN=CENTER>&nbsp;".( $Tinstability ? '<IMG SRC='.$IMAGESURL.'/'.$ICONSUNSTABLE{OK}.' WIDTH=15 HEIGHT=15 title= alt= BORDER=0>' : '' ).'</TD><TD ALIGN=CENTER>&nbsp;'.( $Tpersistent ? '<IMG SRC='.$IMAGESURL.'/'.$ICONSACK{OK}.' WIDTH=15 HEIGHT=15 title= alt= BORDER=0>' : '' ).'</TD><TD ALIGN=CENTER>&nbsp;'.( $Tdowntime ? '<IMG SRC='.$IMAGESURL.'/'.$ICONSACK{OFFLINE}.' WIDTH=15 HEIGHT=15 title= alt= BORDER=0>' : '' )."</TD></TR></TABLE><TABLE WIDTH=100% BORDER=0 CELLSPACING=1 CELLPADDING=2 BGCOLOR=#000000><TR><TD BGCOLOR=#0000FF>$TcommentData</TD></TR></TABLE>";
              }
            }

            $sth->finish() or $rv = errorTrapDBI($checklist, "Cannot sth->finish: $sql");
          }

          $step          = $tinterval * 60;
          $lastTimeslot  = get_timeslot ($creationDate);
          $firstTimeslot = $lastTimeslot - ($step * $NUMBEROFFTESTS);
          $timeCorrectie = 0;

          if ( $trigger ) {
            $findString  = 'select SQL_NO_CACHE title, duration, timeslot, startTime, endTime, endDate, status, statusMessage, perfdata, filename from '.$SERVERTABLEVENTSDISPLAYDT.' where catalogID="' .$catalogID. '" and uKey = "'.$uniqueKey.'" and step <> "0" and (timeslot between "'.$firstTimeslot.'" and "'.$lastTimeslot.'") order by timeslot desc';
          } else {
            $findString  = 'select SQL_NO_CACHE title, duration, timeslot, startTime, endTime, endDate, status, statusMessage, perfdata, filename from '.$SERVERTABLEVENTS.' force index (uKey) where catalogID="' .$catalogID. '" and uKey = "'.$uniqueKey.'" and step <> "0" and (timeslot between "'.$firstTimeslot.'" and "'.$lastTimeslot.'") order by id desc';
          }

          print "<", $findString, ">\n" if ($debug);
          $sth = $dbh->prepare($findString) or $rv = errorTrapDBI($checklist, "Cannot dbh->prepare: $findString");
          $sth->execute or $rv = errorTrapDBI($checklist, "Cannot sth->execute: $findString") if $rv;

          my (@itemTimelocal, @itemStatus, @itemStarttime, @itemTimeslot, @tempStatusMessage);
          @itemTimelocal = @itemStatus = @itemStarttime = @itemTimeslot = @tempStatusMessage = ();
          $timeValue = $lastTimeslot;

          for (; $number <= $NUMBEROFFTESTS; $number++) {
            push (@itemTimelocal, $timeValue);
            push (@itemStatus, ($number == 1) ? 'IN PROGRESS' : 'NO DATA');
            push (@itemStarttime, sprintf ("%02d:%02d:%02d", (localtime($timeValue+$timeCorrectie))[2,1,0]));
            push (@itemTimeslot, $timeValue);
            push (@tempStatusMessage, undef);
            $timeValue -= $step;
          }

          $timeValue = $lastTimeslot;
          $inIMW = 1;

          if ($rv) {
            while (my $ref = $sth->fetchrow_hashref()) {
              $timeslot = ( $step ? int(($lastTimeslot - $ref->{timeslot}) / $step) : 0 );
              print "<", $timeslot, "><", $ref->{title}, "><", $ref->{startTime}, "><", $ref->{timeslot}, ">\n" if ($debug);

              if ($timeslot >= 0) {
                my $dstatus = ($ref->{status} eq '<NIHIL>') ? 'UNKNOWN' : $ref->{status};
	  	          $tstatus = $dstatus;

                if ($dstatus eq 'OK' and $trendline) {
                  my $tSeconden = int(substr($ref->{duration}, 6, 2)) + int(substr($ref->{duration}, 3, 2)*60) + int(substr($ref->{duration}, 0, 2)*3600);
			            $tstatus = 'TRENDLINE' if ($tSeconden > $trendline);
	  		        }

                $itemStatus[$timeslot] = $tstatus;
                $itemStarttime[$timeslot] = $ref->{startTime};
                $itemTimeslot[$timeslot]  = $ref->{timeslot};

                unless ( defined $ref->{perfdata} and $ref->{perfdata} ne '' ) { # remove performance data
                # ($ref->{statusMessage}, undef) = split(/\|/, $ref->{statusMessage}, 2);
                  my $statusMessage = reverse $ref->{statusMessage};
                  my ($_statusMessage, undef) = reverse split(/\|/, $statusMessage, 2);
                  $ref->{statusMessage} = reverse $_statusMessage;
                }

                if ( -e $RESULTSPATH .'/'. $ref->{filename} ) {
                  $ref->{filename} = $RESULTSURL .'/'. $ref->{filename};
                } else {
                  if ( -e $ref->{filename} ) {
                    $ref->{filename} =~ s/^$RESULTSPATH\//$RESULTSURL\//g;
                  } else { # work arround for when switching from ASNMTAP_PATH in mixed environment
                    $ref->{filename} =~ s*^/opt/asnmtap(-3.000.xxx)+/results/*$RESULTSPATH/*g;

                    if ( -e $ref->{filename} ) {
                      $ref->{filename} =~ s/^$RESULTSPATH\//$RESULTSURL\//g;
                    } else {
                      $ref->{filename} = '<NIHIL>';
                    }
                  }
                }

                my $tstatusMessage = ( ( $catalogID ne $CATALOGID or $ref->{filename} eq '<NIHIL>' ) ? encode_html_entities('M', $ref->{statusMessage}) : '<A HREF="'.$ref->{filename}.'" TARGET="_blank">'.encode_html_entities('M', $ref->{statusMessage}).'</A>');
                $statusIcon = ($acked and ($activationTimeslot - $step < $ref->{timeslot}) and ($suspentionTimeslot > $ref->{timeslot})) ? ( $instability ? $ICONSUNSTABLE {$tstatus} : $ICONSACK {$tstatus} ) : $ICONS{$tstatus};

                if ( $timeslot == 0 or $timeslot == 1 ) {
                  my ($year, $month, $day) = split (/-/, $ref->{endDate});
                  my ($hour, $minute, $seconds) = split (/:/, $ref->{endTime});
                  $itemTimelocal[$timeslot] = timelocal ( $seconds, $minute, $hour, $day, $month-1, $year-1900 );
                }

                if ( $timeslot == 0 or ( $timeslot == 1 and $itemStatus[0] eq 'IN PROGRESS' ) ) {
                  $statusOverlib = ( $timeslot ? $itemStatus[1] : $itemStatus[0] );

                  if ($pagedirOrig =~ /^(?:index|test)$/ and -s "$APPLICATIONPATH/custom/cartography.pm") {
                    require "$APPLICATIONPATH/custom/cartography.pm";
                    createGifForCartography( $catalogID_uniqueKey, $statusOverlib );
                  }

                  $inIMW = inIncidentMonitoringWindow ($catalogID, $uniqueKey, $ref->{timeslot}, $ref->{startTime}, $ref->{endTime}, $ref->{endDate}, \%timeperiodID_days, \%catalogID_uKey_timeperiodID, $debug);
                }

                if ($dstatus ne 'OK' and $dstatus ne 'OFFLINE' and $dstatus ne 'NO DATA' and $dstatus ne 'NO TEST') {
                  $tempStatusMessage[$timeslot] = '<IMG SRC="'.$IMAGESURL.'/'.$statusIcon.'" WIDTH="16" HEIGHT="16" BORDER=0 title="'.$tstatus.'" alt="'.$tstatus.'"></TD><TD class="StatusMessage">'.$ref->{startTime}.'</TD><TD class="StatusMessage">'.$tstatusMessage;

                  if ( $timeslot == 0 or ( $timeslot == 1 and $itemStatus[0] eq 'IN PROGRESS' ) ) {
                    $ref->{statusMessage} =~ s/'/`/g;
                    $ref->{statusMessage} =~ s/[\n\r]/<br>/g;
                    $popup .= '<TR><TD BGCOLOR=#000080 WIDTH=100 ALIGN=RIGHT VALIGN=TOP>Status</TD><TD BGCOLOR=#0000FF><IMG SRC='.$IMAGESURL.'/'.$statusIcon.' WIDTH=15 HEIGHT=15 title= alt= BORDER=0> '.$ref->{startTime}.' '.encode_html_entities('M', $ref->{statusMessage}).'</TD></TR>';
                  }
                }
              }
            }

            $sth->finish() or $rv = errorTrapDBI($checklist, "Cannot sth->finish: $findString");
          }

          printItemHeader($environment, $resultsdir, $catalogID_uniqueKey, $catalogID, $uniqueKey, $command, $title, $help, $popup, $statusOverlib, $comment);
          $playSoundPreviousStatus = $playSoundInProgress = 0;

          for ($number = 0; $number < $NUMBEROFFTESTS; $number++) {
            my $endTime = $itemStarttime[$number];
            $endTime .= '-'. $itemTimeslot[$number] if ($displayTimeslot);
            printItemStatus($tinterval, $number+1, $itemStatus[$number], $endTime, $acked, $itemTimeslot[$number], $activationTimeslot, $suspentionTimeslot, $instability, $persistent, $downtime, $suspentionTimeslotPersistentTrue, $suspentionTimeslotPersistentFalse, $catalogID_uniqueKey, $catalogID, $uniqueKey, $inIMW);
          }

          for ($number = 0; $number < $NUMBEROFFTESTS; $number++) {
            push (@arrayStatusMessage, $tempStatusMessage[$number] ) if (defined $tempStatusMessage[$number]);
          }

          $itemTitle       = $title;
          $itemStatus      = ( $itemStatus[0] eq 'IN PROGRESS' ) ? $itemStatus[1] : $itemStatus[0];
          $itemTimeslot    = ( $itemStatus[0] eq 'IN PROGRESS' ) ? $itemTimelocal[1] : $itemTimelocal[0];
          $itemStatusIcon  = ( $acked and ( $activationTimeslot - $step < $itemTimeslot ) and ( $suspentionTimeslot > $itemTimeslot ) ) ? 1 : 0;
          $itemInsertInMCV = ( $instability ) ? ( $persistent ? 0 : 1 ) : ( defined $inMCV{$tLastStatus}{$tPrevStatus} ? 1 : 0 );
        }

        printItemFooter($catalogID_uniqueKey, $catalogID, $uniqueKey, $itemTitle, $itemStatus, $itemTimeslot, $itemStatusIcon, $itemInsertInMCV, $inIMW, $itemFullCondensedView, $printCondensedView, \@arrayStatusMessage, \%catalogID_uKey_timeperiodID);
      }

      print "\n" if ($debug);
    }

    printGroepCV($prevGroep, 1, 0);

    if ($lockMySQL) {
      if ($dbh and $rv) {
        $unlockString = 'UNLOCK TABLES';
        $dbh->do ( $unlockString ) or $rv = errorTrapDBI($checklist, "Cannot dbh->do: $unlockString");
      }
    }

    $dbh->disconnect or $rv = errorTrapDBI($checklist, "Sorry, the database was unable to add your entry.") if ($dbh and $rv);
  }

  printGroepFooter('', 0);

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $emptyMinimalCondencedView = ( scalar ( @multiarrayMinimalCondensedView ) ? 0 : 1 );

  unless ( $emptyMinimalCondencedView ) {
    @multiarrayMinimalCondensedView = ( sort { $b->[2] <=> $a->[2] } @multiarrayMinimalCondensedView );
    @multiarrayMinimalCondensedView = ( sort { $b->[0] <=> $a->[0] } @multiarrayMinimalCondensedView );
    @multiarrayMinimalCondensedView = ( sort { $a->[3] <=> $b->[3] } @multiarrayMinimalCondensedView );
    @multiarrayMinimalCondensedView = ( sort { $a->[1] cmp $b->[1] } @multiarrayMinimalCondensedView );

    my $currPriorityGroup = '-MVM-P01-';

    foreach my $arrayFullCondensedView ( @multiarrayMinimalCondensedView ) {
      # print @$arrayFullCondensedView[2], "-", @$arrayFullCondensedView[0], "-", @$arrayFullCondensedView[3], "-", @$arrayFullCondensedView[1], "\n" if ($debug);

      if ( $currPriorityGroup ne @$arrayFullCondensedView[1] ) {
        $currPriorityGroup = @$arrayFullCondensedView[1];
        my (undef, undef, $priorityGroup) = split( /-/, $currPriorityGroup );
        print HTMLMCV '<TR><TD class="GroupHeader" COLSPAN=', $colspanDisplayTime, '>', 'Priority: '. $priorityGroup, '</TD></TR>', "\n";
      }

      print HTMLMCV @$arrayFullCondensedView[4];
    }

    print HTMLMCV '<tr style="{height: 4;}"><TD></TD></TR>', "\n";
 	  delete @multiarrayMinimalCondensedView[0..@multiarrayMinimalCondensedView];
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  printStatusHeader('', $configNumber, $emptyFullView, $emptyCondencedView, $emptyMinimalCondencedView, $playSoundStatus);

  printStatusFooter('', $emptyFullView, $emptyCondencedView, $emptyMinimalCondencedView, $playSoundStatus);

  printHtmlFooter('');

  close(HTML);
  rename("$htmlOutput.tmp", "$htmlOutput.html") if (-e "$htmlOutput.tmp");

  close(HTMLCV);
  rename("$htmlOutput-cv.tmp", "$htmlOutput-cv.html") if (-e "$htmlOutput-cv.tmp");

  close(HTMLMCV);
  rename("$htmlOutput-mcv.tmp", "$htmlOutput-mcv.html") if (-e "$htmlOutput-mcv.tmp");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signal_DIE {
  #print "kill -DIE <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signal_WARN {
  #print "kill -WARN <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signalQUIT {
  print "kill -QUIT <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";
  unlink $pidfile;
  $boolean_daemonQuit = 1;

  use Sys::Hostname;
  my $subject = "$prgtext\@". hostname() .": Config $APPLICATIONPATH/etc/$checklist successfully stopped at ". get_datetimeSignal();
  my $returnCode = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $subject ."\n", 0 );
  print "Problem sending email to the '$APPLICATION' server administrators\n" unless ( $returnCode );

  exit 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signalHUP {
  print "kill -HUP <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";
  $boolean_signal_hup = 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub write_pid {
  print "write PID <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";

  if (-e "$pidfile") {
    print "ERROR: couldn't create pid file <$pidfile> for <$PROGNAME v$version -C $checklist>\n";
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

  unless ( -e "$directory" ) {                            # create $directory
    my ($status, $stdout, $stderr) = call_system ("mkdir $directory", 0);
    print "    create_dir ---- : mkdir $directory: $status, $stdout, $stderr\n" if ( ! $status or $stderr ne '' );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapDBI {
  my ($checklist, $error_message) = @_;

  print $error_message, "\nERROR: $DBI::err ($DBI::errstr)\n";

  unless ( -e "$RESULTSPATH/$checklist-MySQL-sql-error.txt" ) {
    my $subject = "$prgtext / Current status for $checklist: " . get_datetimeSignal();
    my $message = get_datetimeSignal() . " $error_message\n--> ERROR: $DBI::err ($DBI::errstr)\n";
    my $returnCode = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $message, $debug );
    print "Problem sending email to the '$APPLICATION' server administrators\n" unless ( $returnCode );
  }

  $rvOpen = open(DEBUG,">>$RESULTSPATH/$checklist-MySQL-sql-error.txt");

  if ($rvOpen) {
    print DEBUG get_datetimeSignal, ' ', $error_message, "\n--> ERROR: $DBI::err ($DBI::errstr)\n";
    close(DEBUG);
  } else {
    print "Cannot open $RESULTSPATH/$checklist-MySQL-sql-error.txt to print debug information\n";
  }

  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub build_hash_timeperiodID_days {
  my ($checklist, $pagedir, $hash_timeperiodID_days, $debug) = @_;

  print "build_hash_timeperiodID_days: '$checklist', '$pagedir'\n" if ($debug);

  my $rv  = 1;
  my $dbh = DBI->connect("DBI:mysql:$DATABASE:$serverName:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE") or $rv = errorTrapDBI($checklist, "Cannot connect to the database");
  return () unless ($dbh and $rv);

  # (localtime)[6]: weekday Number of days since Sunday (0 - 6)
  my %WDAYS = ('sunday'=>'0','monday'=>'1','tuesday'=>'2','wednesday'=>'3','thursday'=>'4','friday'=>'5','saturday'=>'6');

  my $sql = "SELECT SQL_NO_CACHE DISTINCT $SERVERTABLVIEWS.catalogID, $SERVERTABLVIEWS.timeperiodID, $SERVERTABLTIMEPERIODS.sunday, $SERVERTABLTIMEPERIODS.monday, $SERVERTABLTIMEPERIODS.tuesday, $SERVERTABLTIMEPERIODS.wednesday, $SERVERTABLTIMEPERIODS.thursday, $SERVERTABLTIMEPERIODS.friday, $SERVERTABLTIMEPERIODS.saturday FROM `$SERVERTABLDISPLAYDMNS`, `$SERVERTABLVIEWS`, `$SERVERTABLPLUGINS`, `$SERVERTABLTIMEPERIODS` WHERE $SERVERTABLDISPLAYDMNS.pagedir = '$pagedir' AND $SERVERTABLDISPLAYDMNS.catalogID = $SERVERTABLVIEWS.catalogID AND $SERVERTABLDISPLAYDMNS.displayDaemon = $SERVERTABLVIEWS.displayDaemon AND $SERVERTABLVIEWS.catalogID = $SERVERTABLPLUGINS.catalogID AND $SERVERTABLVIEWS.uKey = $SERVERTABLPLUGINS.uKey AND $SERVERTABLVIEWS.timeperiodID = $SERVERTABLTIMEPERIODS.timeperiodID";
  print "<", $sql, ">\n" if ($debug);

  my $sth = $dbh->prepare( $sql ) or $rv = errorTrapDBI($checklist, "Cannot dbh->prepare: $sql");
  $sth->execute or $rv = errorTrapDBI($checklist, "Cannot sth->execute: $sql") if $rv;

  if ($rv) {
    if ( $sth->rows ) {
      while (my $ref = $sth->fetchrow_hashref()) {
        $$hash_timeperiodID_days{$ref->{catalogID}}->{$ref->{timeperiodID}}->{$WDAYS{sunday}}    = ( $ref->{sunday}    ) ? $ref->{sunday}    : '';
        $$hash_timeperiodID_days{$ref->{catalogID}}->{$ref->{timeperiodID}}->{$WDAYS{monday}}    = ( $ref->{monday}    ) ? $ref->{monday}    : '';
        $$hash_timeperiodID_days{$ref->{catalogID}}->{$ref->{timeperiodID}}->{$WDAYS{tuesday}}   = ( $ref->{tuesday}   ) ? $ref->{tuesday}   : '';
        $$hash_timeperiodID_days{$ref->{catalogID}}->{$ref->{timeperiodID}}->{$WDAYS{wednesday}} = ( $ref->{wednesday} ) ? $ref->{wednesday} : '';
        $$hash_timeperiodID_days{$ref->{catalogID}}->{$ref->{timeperiodID}}->{$WDAYS{thursday}}  = ( $ref->{thursday}  ) ? $ref->{thursday}  : '';
        $$hash_timeperiodID_days{$ref->{catalogID}}->{$ref->{timeperiodID}}->{$WDAYS{friday}}    = ( $ref->{friday}    ) ? $ref->{friday}    : '';
        $$hash_timeperiodID_days{$ref->{catalogID}}->{$ref->{timeperiodID}}->{$WDAYS{saturday}}  = ( $ref->{saturday}  ) ? $ref->{saturday}  : '';
      }
    }

    $sth->finish() or $rv = errorTrapDBI($checklist, "Cannot sth->finish: $sql");
  }

  $dbh->disconnect or $rv = errorTrapDBI($checklist, "Sorry, the database was unable to add your entry.") if ($dbh and $rv);

  if ($debug) {
    use Data::Dumper;
    print Dumper ( $hash_timeperiodID_days ), "\n\n";
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub build_hash_catalogID_uKey_timeperiodID {
  my ($checklist, $pagedir, $hash_catalogID_uKey_timeperiodID, $debug) = @_;

  print "build_hash_catalogID_uKey_timeperiodID: '$checklist', '$pagedir'\n" if ($debug);

  my $rv  = 1;
  my $dbh = DBI->connect("DBI:mysql:$DATABASE:$serverName:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE") or $rv = errorTrapDBI($checklist, "Cannot connect to the database");
  return () unless ($dbh and $rv);

  my $sql = "SELECT SQL_NO_CACHE $SERVERTABLPLUGINS.catalogID, $SERVERTABLPLUGINS.uKey, $SERVERTABLVIEWS.timeperiodID FROM `$SERVERTABLDISPLAYDMNS`, `$SERVERTABLVIEWS`, `$SERVERTABLPLUGINS` WHERE $SERVERTABLDISPLAYDMNS.pagedir = '$pagedir' AND $SERVERTABLDISPLAYDMNS.catalogID = $SERVERTABLVIEWS.catalogID AND $SERVERTABLDISPLAYDMNS.displayDaemon = $SERVERTABLVIEWS.displayDaemon AND $SERVERTABLVIEWS.catalogID = $SERVERTABLPLUGINS.catalogID AND $SERVERTABLVIEWS.uKey = $SERVERTABLPLUGINS.uKey";
  print "<", $sql, ">\n" if ($debug);

  my $sth = $dbh->prepare( $sql ) or $rv = errorTrapDBI($checklist, "Cannot dbh->prepare: $sql");
  $sth->execute or $rv = errorTrapDBI($checklist, "Cannot sth->execute: $sql") if $rv;

  if ($rv) {
    while (my $ref = $sth->fetchrow_hashref()) {
      $$hash_catalogID_uKey_timeperiodID{$ref->{catalogID}}->{$ref->{uKey}}->{ASNMTAP} = $ref->{timeperiodID};
    }

    $sth->finish() or $rv = errorTrapDBI($checklist, "Cannot sth->finish: $sql");
  }

  $dbh->disconnect or $rv = errorTrapDBI($checklist, "Sorry, the database was unable to add your entry.") if ($dbh and $rv);

  if (-s "$APPLICATIONPATH/custom/sde.pm") {
    require "$APPLICATIONPATH/custom/sde.pm";
    getTimeperiodRelationshipsSDE( $serverName, $checklist, $hash_catalogID_uKey_timeperiodID, $debug );
  }

  if ($debug) {
    use Data::Dumper;
    print Dumper ( $hash_catalogID_uKey_timeperiodID ), "\n\n";
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub inIncidentMonitoringWindow {
  my ($catalogID, $uniqueKey, $timeslot, $startTime, $endTime, $endDate, $timeperiodID_days, $catalogID_uKey_timeperiodID, $debug) = @_;

  my $InIMW;

  my ($year, $month, $day) = split (/[-\/]/, $endDate);

  if (defined $year and defined $month and defined $day) {
    my $Year  = $year-1900;
    my $Month = $month-1;
    my $wDay = (localtime( timelocal( 0, 0, 0, $day, $Month, $Year ) ))[6];
    my $timeperiodes = ( exists $$catalogID_uKey_timeperiodID{$catalogID}->{$uniqueKey}->{SDE_IMW}->{$wDay} ) ? $$catalogID_uKey_timeperiodID{$catalogID}->{$uniqueKey}->{SDE_IMW}->{$wDay} : $$timeperiodID_days{$catalogID}->{$$catalogID_uKey_timeperiodID{$catalogID}->{$uniqueKey}->{ASNMTAP}}->{$wDay};

    if ($debug) {
      # (localtime)[6]: weekday Number of days since Sunday (0 - 6)
      my %WDAYS = ('0'=>'sunday','1'=>'monday','2'=>'tuesday','3'=>'wednesday','4'=>'thursday','5'=>'friday','6'=>'saturday');
      print "catalogID: $catalogID, uniqueKey: $uniqueKey, year: $year, month: $month, day: $day, wDay: $wDay, ". $WDAYS{$wDay} .", timeperiodes: $timeperiodes\n";
      print "catalogID_uKey_timeperiodID: ". $$catalogID_uKey_timeperiodID{$catalogID}->{$uniqueKey}->{ASNMTAP} ."\n";
    }

    for my $timeperiode (split (/,/, $timeperiodes)) {
      my ($from, $to) = split (/-/, $timeperiode);

      if ( defined $from and defined $to ) {
        $to =~ s/24:00/23:59/g;
        print "$from, $to\n" if ($debug);
        my ($from_hour, $from_min) = split (/:/, $from);
        my ($to_hour, $to_min) = split (/:/, $to);

        if ( defined $from_hour and defined $from_min and defined $to_hour and defined $to_min ) {
          print "$from_hour, $from_min, $to_hour, $to_min\n" if ($debug);
          my $from_time = timelocal(0, $from_min, $from_hour, $day, $Month, $Year );
          my $to_time   = timelocal(59, $to_min, $to_hour, $day, $Month, $Year );

          if ( defined $from_time and defined $to_time ) {
            $InIMW = ( ( $from_time <= $timeslot and $timeslot <= $to_time ) ? 1 : ( ( defined $InIMW ) ? $InIMW : 0 ) );

            if ($debug) {
              print "$from_time, $timeslot, $to_time\n";
              print scalar (localtime($from_time)), "\n";
              print scalar (localtime($timeslot)), "\n";
              print scalar (localtime($to_time)), "\n";
              print "$InIMW !\n";
            }
          }
        }
      }
    }

    $InIMW = 1 unless (defined $InIMW);
  } else {
    $InIMW = 1;
  }

  return ($InIMW);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHtmlHeader {
  my $htmlTitle = shift(@_);

  print_header (*HTML, $pagedir, "$pageset-cv", $htmlTitle, "Full View", 60, "ONLOAD=\"startRefresh(); initSound();\"", 'T', "<script type=\"text/javascript\" src=\"$HTTPSURL/overlib.js\"><!-- overLIB (c) Erik Bosrup --></script>", undef);
  print HTML '<TABLE WIDTH="100%">', "\n";

  print_header (*HTMLCV, $pagedir, "$pageset-mcv", $htmlTitle, "Condenced View", 60, "ONLOAD=\"startRefresh(); initSound();\"", 'T', "<script type=\"text/javascript\" src=\"$HTTPSURL/overlib.js\"><!-- overLIB (c) Erik Bosrup --></script>", undef);
  print HTMLCV '<TABLE WIDTH="100%">', "\n";

  print_header (*HTMLMCV, $pagedir, "$pageset", $htmlTitle, "Minimal Condenced View", 60, "ONLOAD=\"startRefresh(); initSound();\"", 'T', "<script type=\"text/javascript\" src=\"$HTTPSURL/overlib.js\"><!-- overLIB (c) Erik Bosrup --></script>", undef);
  print HTMLMCV '<TABLE WIDTH="100%">', "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printGroepHeader {
  my ($title, $show) = @_;

  if ($show) {
    $groupFullView = $groupCondensedView = 0;
 	delete @multiarrayFullCondensedView[0..@multiarrayFullCondensedView];
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printStatusHeader {
  my ($title, $configNumber, $emptyFullView, $emptyCondencedView, $emptyMinimalCondencedView, $playSoundStatus) = @_;

  my ($emptyFullViewMessage, $emptyCondencedViewMessage, $emptyMinimalCondencedViewMessage);

  if ( $configNumber ) {                         # Monitored Applications
    if ( $emptyFullView ) {
      $emptyMinimalCondencedViewMessage = $emptyCondencedViewMessage = $emptyFullViewMessage = 'Contact ASAP the server administrators, probably collector/config problems!';
    } else {
      $emptyCondencedViewMessage        = 'All Monitored Applications are OK' if ( $emptyCondencedView );
      $emptyMinimalCondencedViewMessage = 'All Monitored Applications are OK' if ( $emptyMinimalCondencedView );
    }
  } elsif ( $emptyFullView and $emptyCondencedView and $emptyMinimalCondencedView ) {
    if ( $doChecklist ) {
      $emptyMinimalCondencedViewMessage = $emptyCondencedViewMessage = $emptyFullViewMessage = 'No Monitored Applications';
    } else {
      $emptyMinimalCondencedViewMessage = $emptyCondencedViewMessage = $emptyFullViewMessage = 'Contact ASAP the server administrators, probably database problems!';
    }
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  if (defined $emptyFullViewMessage) {
    print HTML   '<TR><TD class="StatusHeader" COLSPAN="', $colspanDisplayTime, '"><BR><H1>', $emptyFullViewMessage, '</H1></TD></TR>', "\n", '</TABLE>', "\n";
  } else {
    print HTML   '<TR><TD class="StatusHeader" COLSPAN="', $colspanDisplayTime, '">', $STATUSHEADER01, '</TD></TR>', "\n", '</TABLE>', "\n";
  }

  print_legend (*HTML);
  print HTML   '<TABLE WIDTH="100%">', "\n";

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  if (defined $emptyCondencedViewMessage) {
    print HTMLCV '<TR><TD class="StatusHeader" COLSPAN="', $colspanDisplayTime, '"><BR><H1>', $emptyCondencedViewMessage, '</H1></TD></TR>', "\n", '</TABLE>', "\n";
  } else {
    print HTMLCV '<TR><TD class="StatusHeader" COLSPAN="', $colspanDisplayTime, '">', $STATUSHEADER01, '</TD></TR>', "\n", '</TABLE>', "\n";
  }

  print_legend (*HTMLCV);
  print HTMLCV '<TABLE WIDTH="100%">', "\n";

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  if (defined $emptyMinimalCondencedViewMessage) {
    print HTMLMCV '<TR><TD class="StatusHeader" COLSPAN="', $colspanDisplayTime, '"><BR><H1>', $emptyMinimalCondencedViewMessage, '</H1></TD></TR>', "\n", '</TABLE>', "\n";
  } else {
    print HTMLMCV '</TABLE>', "\n";
  }

  print_legend (*HTMLMCV);
  print HTMLMCV '<TABLE WIDTH="100%">', "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printItemHeader {
  my ($environment, $resultsdir, $catalogID_uniqueKey, $catalogID, $uniqueKey, $command, $title, $help, $popup, $statusOverlib, $comment) = @_;

  unless ( defined $creationTime ) {
    my $htmlFilename = "$RESULTSPATH/$resultsdir/$command-$catalogID_uniqueKey";
    $htmlFilename .= "-sql.html";

    unless ( -e "$htmlFilename" ) {
      my $rvOpen = open(PNG, ">$htmlFilename");

      if ($rvOpen) {
        print PNG <<EOM;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD>
  <title>$APPLICATION @ $BUSINESS</title>
  <META HTTP-EQUIV="Expires" CONTENT="Wed, 10 Dec 2003 00:00:01 GMT">
  <META HTTP-EQUIV="Pragma" CONTENT="no-cache">
  <META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
  <META HTTP-EQUIV="Refresh" CONTENT="60">
  <link rel="stylesheet" type="text/css" href="$HTTPSURL/asnmtap.css">
</HEAD>
<BODY>
EOM

        print PNG '<IMG SRC="', $RESULTSURL, '/', $resultsdir, '/', $command, '-', $catalogID_uniqueKey, '-sql.png"></BODY></HTML>', "\n";
        close(PNG);
      } else {
        print "Cannot create $htmlFilename!\n";
      }
    }
  }

  my ($posTokenFrom, $posTokenTo, $groep, $test, $serverID);
  $posTokenFrom = index $title, '[';

  if ($posTokenFrom eq -1) {
    $groep = '';
    $test  = $title;
  } else {
    $posTokenTo = index $title, ']', $posTokenFrom+1;
    $groep = substr($title, $posTokenFrom, $posTokenTo+2);
    $test  = substr($title, $posTokenTo+2);
  }

  $posTokenFrom = index $test, ' {';

  if ($posTokenFrom eq -1) {
    $serverID = '';
  } else {
    $posTokenTo = index $test, '}', $posTokenFrom+2;
    $serverID = substr($test, $posTokenFrom+2); chop ($serverID);
    $test = substr($test, 0, $posTokenFrom);
  }

  # http://www.bosrup.com/web/overlib/?Command_Reference
  my $_exclaim = '';

  if (-s "$APPLICATIONPATH/custom/sde.pm") {
    require "$APPLICATIONPATH/custom/sde.pm";
    $_exclaim .= printRelationshipsSDE( $serverName, $checklist, $catalogID, $uniqueKey );
  }

  if (-s "$APPLICATIONPATH/custom/cartography.pm") {
    require "$APPLICATIONPATH/custom/cartography.pm";
    $_exclaim .= printLinkToCartography( $serverName, $checklist, $catalogID, $uniqueKey );
  }

  # debug: toggleDiv(), pop-up: overlib() & pop-down: nd()
  # onClick: overlib(), onDblClick: nd() & toggleDiv()

  $_exclaim = "<TABLE WIDTH=100% BORDER=0 CELLSPACING=1 CELLPADDING=2 BGCOLOR=#000000><TR><TD BGCOLOR=#000080 WIDTH=100 ALIGN=RIGHT>Plugin</TD><TD BGCOLOR=#0000FF>$test</TD></TR>$popup<TR><TD BGCOLOR=#000080 WIDTH=100 ALIGN=RIGHT>Unique Key</TD><TD BGCOLOR=#0000FF>$uniqueKey from $catalogID on $CATALOGID</TD></TR><TR><TD BGCOLOR=#000080 WIDTH=100 ALIGN=RIGHT>Executed on</TD><TD BGCOLOR=#0000FF>$serverID</TD></TR>$_exclaim</TABLE>";
  my $exclaim  = '<TD WIDTH="56"><a href="javascript:void(0);" onDblClick="nd(); return toggleDiv(\''.$catalogID_uniqueKey.'\');" onClick="return overlib(\''.$_exclaim.'\', CAPTION, \'Exclaim\', STICKY, CLOSECLICK, CAPCOLOR, \'#000000\', FGCOLOR, \'#000000\', BGCOLOR, \''.$COLORS{$statusOverlib}.'\', HAUTO, VAUTO, WIDTH, 692, OFFSETX, 16, OFFSETY, 16);" onmouseout="return nd();"><IMG SRC="'.$IMAGESURL.'/'.$environment.'.gif" WIDTH="15" HEIGHT="15" title="" alt="" BORDER=0></a> ';

  my $_comment = ( defined $comment ? 'onmouseover="return overlib(\''.$comment.'\', CAPTION, \'Comments\', STICKY, CLOSECLICK, CAPCOLOR, \'#000000\', FGCOLOR, \'#000000\', BGCOLOR, \''.$COLORS{$statusOverlib}.'\', HAUTO, VAUTO, WIDTH, 692, OFFSETX, 16, OFFSETY, 16);" onmouseout="return nd();"' : '' );
  my $comments = '<a href="'. $HTTPSURL .'/cgi-bin/comments.pl?pagedir='.$pagedir.'&amp;pageset='.$pageset.'&amp;debug=F&amp;CGICOOKIE=1&amp;action=listView&amp;catalogID='.$catalogID.'&amp;uKey='.$uniqueKey.'" target="_self" '.$_comment.'><IMG SRC="'.$IMAGESURL.'/'.$ICONSRECORD{maintenance}.'" WIDTH="15" HEIGHT="15" title="'.(defined $comment ? '' : 'Comments').'" alt="'.(defined $comment ? '' : 'Comments').'" BORDER=0></A> ';

  my $helpfile = (defined $help and $help eq '1') ? '<A HREF="'. $HTTPSURL .'/cgi-bin/getHelpPlugin.pl?pagedir='.$pagedir.'&amp;pageset='.$pageset.'&amp;debug=F&amp;CGICOOKIE=1&amp;catalogID='.$catalogID.'&amp;uKey='.$uniqueKey.'" target="_self"><IMG SRC="'.$IMAGESURL.'/question.gif" WIDTH="15" HEIGHT="15" title="Help" alt="Help" BORDER=0></A></TD>' : '<IMG SRC="'.$IMAGESURL.'/spacer.gif" WIDTH="15" HEIGHT="15" title="" alt="" BORDER=0></TD>';

  $checkOk = $checkSkip = $printCondensedView = $problemSolved = $verifyNumber = 0;
  $inProgressNumber = -1;

  $itemFullCondensedView = '  <TR>'."\n".'    '.$exclaim.$comments.$helpfile."\n";

  if ( $catalogID ne $CATALOGID or defined $creationTime ) {
    $itemFullCondensedView .= '    <TD class="ItemHeader">'.$groep. encode_html_entities('T', $test) .'</TD>'. "\n";
  } else {
    $itemFullCondensedView .= '    <TD class="ItemHeader">'.$groep.'<A HREF="#" class="ItemHeaderTest" onClick="openPngImage(\''. $RESULTSURL .'/'. $resultsdir .'/'. $command .'-'. $catalogID_uniqueKey ."-sql.html',912,576,null,null,'ChartDirector',10,false,'ChartDirector');\">". encode_html_entities('T', $test) .'</A></TD>'. "\n";
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printGroepCV {
  my ($title, $showGroup, $showFooter) = @_;

  if ($showGroup and $title ne '') {
    if ($groupFullView) {
	  $emptyFullView = ( scalar ( @multiarrayFullCondensedView ) ? 0 : 1 );

      unless ( $emptyFullView ) {
        print HTML '<TR><TD class="GroupHeader" COLSPAN=', $colspanDisplayTime, '>', encode_html_entities('T', $title), '</TD></TR>', "\n";

        foreach my $arrayFullCondensedView ( @multiarrayFullCondensedView ) {
          print HTML @$arrayFullCondensedView[4];
        }
      }

      print HTML '<tr style="{height: 4;}"><TD></TD></TR>', "\n", if $showFooter;
    }

    if ($groupCondensedView) {
	  $emptyCondencedView = ( scalar ( @multiarrayFullCondensedView ) ? 0 : 1 );

      unless ( $emptyCondencedView ) {
        @multiarrayFullCondensedView = ( sort { $a->[2] <=> $b->[2] } @multiarrayFullCondensedView );
        @multiarrayFullCondensedView = ( sort { $b->[0] <=> $a->[0] } @multiarrayFullCondensedView );
        @multiarrayFullCondensedView = ( sort { $a->[3] <=> $b->[3] } @multiarrayFullCondensedView );
        @multiarrayFullCondensedView = ( sort { $a->[1] <=> $b->[1] } @multiarrayFullCondensedView );

        print HTMLCV '<TR><TD class="GroupHeader" COLSPAN=', $colspanDisplayTime, '>', encode_html_entities('T', $title), '</TD></TR>', "\n";

        foreach my $arrayFullCondensedView ( @multiarrayFullCondensedView ) {
          print HTMLCV @$arrayFullCondensedView[4] if ( @$arrayFullCondensedView[5] );
        }
      }

      print HTMLCV '<tr style="{height: 4;}"><TD></TD></TR>', "\n", if $showFooter;
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printItemStatus {
  my ($interval, $number, $status, $endTime, $acked, $timeslot, $activationTimeslot, $suspentionTimeslot, $instability, $persistent, $downtime, $suspentionTimeslotPersistentTrue, $suspentionTimeslotPersistentFalse, $catalogID_uniqueKey, $catalogID, $uniqueKey, $inIMW) = @_;

  my $statusIcon = ($acked and ($activationTimeslot - $step < $timeslot) and ($suspentionTimeslot > $timeslot)) ? ( $instability ? $ICONSUNSTABLE {$status} : $ICONSACK {$status} ) : $ICONS{$status};

  my ($debugInfo, $boldStart, $boldEnd);
  $debugInfo = $boldStart = $boldEnd = '';

  if ($number == 0) {
    $printCondensedView = 1 unless ( $status eq 'IN PROGRESS' or $status eq 'OK' or $status eq 'NO TEST' or $status eq 'OFFLINE' );
    if ($ERRORS{$status} <= $ERRORS{UNKNOWN} or $ERRORS{$status} == $ERRORS{'NO DATA'}) { $playSoundStatus = ($playSoundStatus > $ERRORS{$status}) ? $playSoundStatus : $ERRORS{$status}; }
  } else {
    my $playSoundSet = 0;

    unless ( $printCondensedView or $problemSolved or $checkSkip == $inProgressNumber) {
      if ( $number == 1 ) {
        $verifyNumber = $VERIFYNUMBEROK;

	    if ( $interval and $interval < $VERIFYMINUTEOK ) {
          $verifyNumber = int($VERIFYMINUTEOK / $interval);

  	      if ( $verifyNumber > $NUMBEROFFTESTS ) {
            $verifyNumber = $NUMBEROFFTESTS;
          } elsif ($verifyNumber < $VERIFYNUMBEROK) {
            $verifyNumber = $VERIFYNUMBEROK;
	      }
        }

        $inProgressNumber = $verifyNumber;

        if ( $verifyNumber < $NUMBEROFFTESTS ) {
          $debugInfo .= "a-" if ($debug);
          $inProgressNumber++ if ( $status eq 'IN PROGRESS' );
  	    }

        if ( $status eq 'IN PROGRESS' ) {
          $playSoundInProgress = 1;
        } else {
          $playSoundPreviousStatus = $ERRORS{$status};
        }
      }

      my ($localYear, $localMonth, $currentYear, $currentMonth, $currentDay, $currentHour, $currentMin, $currentSec) = ((localtime)[5], (localtime)[4], ((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3,2,1,0]);
      my $solvedDate     = "$currentYear-$currentMonth-$currentDay";
      my $solvedTime     = "$currentHour:$currentMin:$currentSec";
      my $solvedTimeslot = timelocal($currentSec, $currentMin, $currentHour, $currentDay, $localMonth, $localYear);

      my $notDowntimeOrPersistent = 1;

      if ( $downtime or $persistent ) {
        $notDowntimeOrPersistent = ( $solvedTimeslot >= $activationTimeslot ? 0 : 1 );
      }

      if ( $number <= $inProgressNumber ) {
        $debugInfo .= "b-" if ($debug);
        $checkOk++ if ( $status eq 'OK' );

        if ( $notDowntimeOrPersistent and ($status eq 'IN PROGRESS' or $status eq 'OK' or $status eq 'NO TEST' or $status eq 'OFFLINE' ) ) {
          $checkSkip++ unless ( $acked and $status eq 'NO TEST' );
        } else {
          $printCondensedView = 1
        }
      } elsif ( $checkOk < $verifyNumber ) {
        $debugInfo .= "c-" if ($debug);
        $printCondensedView = ( $checkSkip == $inProgressNumber ) ? 0 : 1;
      }

      if ( $checkOk >= $verifyNumber ) {
        $debugInfo .= "s-" if ($debug);
        $problemSolved = 1;
      }

      $printCondensedView = 0 if ($downtime and ! $persistent);
      $debugInfo .= "$inIMW-$instability-$persistent-$downtime-$inProgressNumber-$verifyNumber-$checkOk-$checkSkip-$printCondensedView-$problemSolved-" if ($debug);

      my $update = 0;
      my $sqlWhere = '';

      if ( $persistent == 0 ) {
        if ( $problemSolved ) {
          if ($solvedTimeslot > $activationTimeslot and ! $downtime) {
  	        $sqlWhere = ' and persistent="0" and "' .$solvedTimeslot. '">activationTimeslot';
            $update = 1;
          }
        } elsif ($number == 1) {
          if ($activationTimeslot != 9999999999 and $suspentionTimeslotPersistentFalse != 0) {
            if ($suspentionTimeslotPersistentFalse < $solvedTimeslot) {
              $sqlWhere = ' and persistent="0" and "' .$solvedTimeslot. '">suspentionTimeslot';
              $update = 1;
            }
          }
        }
      } elsif ( $persistent == 1 ) {
        if ($number == 1) {
          if ($activationTimeslot != 9999999999 and $suspentionTimeslotPersistentTrue != 0) {
            if ($suspentionTimeslotPersistentTrue < $solvedTimeslot) {
              $sqlWhere = ' and persistent="1" and "' .$solvedTimeslot. '">suspentionTimeslot';
              $update = 1;
            }
          }
        }
      }

      if ($update and $instability == 0) {
        my $sql = 'UPDATE ' .$SERVERTABLCOMMENTS. ' SET replicationStatus="U", problemSolved="1", solvedDate="' .$solvedDate. '", solvedTime="' .$solvedTime. '", solvedTimeslot="' .$solvedTimeslot. '" where catalogID="' .$catalogID. '" and uKey="' .$uniqueKey. '" and problemSolved="0"' .$sqlWhere;
        $dbh->do ( $sql ) or $rv = errorTrapDBI($checklist, "Cannot dbh->do: $sql");
      }
    }

  	if ( $number == 2 ) {
      if ( $playSoundInProgress ) {
        $playSoundPreviousStatus = $ERRORS{$status};
      } else {
        $playSoundSet = 1;
      }
	} elsif ( $number == 3 and $playSoundInProgress ) {
      $playSoundSet = 1;
    }

    if ( $playSoundSet ) {
      $playSoundSet = 0;

      if ( ( $ERRORS{$status} == $ERRORS{OK} or ( $ERRORS{$status} >= $ERRORS{DEPENDENT} and $ERRORS{$status} != $ERRORS{'NO DATA'} and $ERRORS{$status} != $ERRORS{TRENDLINE} ) ) and ( ( $playSoundPreviousStatus >= $ERRORS{WARNING} and $playSoundPreviousStatus <= $ERRORS{UNKNOWN} ) or $playSoundPreviousStatus == $ERRORS{'NO DATA'} or $playSoundPreviousStatus == $ERRORS{TRENDLINE} ) ) {
        if ( defined $tableSoundStatusCache { $catalogID_uniqueKey } ) {
          if ( $tableSoundStatusCache { $catalogID_uniqueKey } ne $timeslot ) {
            $playSoundStatus = ($playSoundStatus > $playSoundPreviousStatus) ? $playSoundStatus : $playSoundPreviousStatus; 
            $tableSoundStatusCache { $catalogID_uniqueKey } = $timeslot;
            $debugInfo .= "$playSoundStatus-" if ($debug);
            $boldStart = "<b>["; $boldEnd = "]</b>";
          } else {
            $debugInfo .= "C-" if ($debug);
          }
        } else {
          $playSoundStatus = ($playSoundStatus > $playSoundPreviousStatus) ? $playSoundStatus : $playSoundPreviousStatus;
          $tableSoundStatusCache { $catalogID_uniqueKey } = $timeslot;
          $debugInfo .= "$playSoundStatus-" if ($debug);
          $boldStart = "<b>["; $boldEnd = "]</b>";
        }
      } else {
        delete $tableSoundStatusCache { $catalogID_uniqueKey } if ( defined $tableSoundStatusCache { $catalogID_uniqueKey } );
      }
    }
  }

  if ($displayTime) {
    $itemFullCondensedView .= '    <TD><IMG SRC="'. $IMAGESURL .'/'. $statusIcon .'" WIDTH="16" HEIGHT="16" BORDER=0 title="'. $status .'" alt="'. $status .'"></TD>'. "\n";
    $itemFullCondensedView .= '    <TD class="ItemStatus"><FONT COLOR="'. $COLORS{$status} .'">'. $debugInfo . $boldStart . $endTime . $boldEnd .'</FONT></TD>'. "\n";
  } else {
    $itemFullCondensedView .= '    <TD><IMG SRC="'. $IMAGESURL .'/'. $statusIcon .'" WIDTH="16" HEIGHT="16" BORDER=0 title="'. $endTime .'" alt="'. $endTime .'"></TD>'. "\n";
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printStatusMessage {
  my ($statusMessage) = @_;

  my $break = '';
  my $errorMessage;

  # ***************************************************************************
  # The 400 series of Web error codes indicate an error with your Web browser *
  # ***************************************************************************
  if ($statusMessage =~ /400 Bad Request/ ) {
    $errorMessage = 'The request could not be understood by the server due to incorrect syntax';
  } elsif ($statusMessage =~ /401 Unauthorized User/ ) {
    $errorMessage = 'The client does not have access to this resource, authorization is needed';
  } elsif ($statusMessage =~ /402 Payment Required/ ) {
    $errorMessage = 'Payment is required. Reserved for future use';
  } elsif ($statusMessage =~ /403 Forbidden Connection/ ) {
    $errorMessage = 'The server understood the request, but is refusing to fulfill it. Access to a resource is not allowed. The most frequent case of this occurs when directory listing access is not allowed';
  } elsif ($statusMessage =~ /404 Page Not Found/ ) {
    $errorMessage = 'The resource request was not found. This is the code returned for missing pages or graphics. Viruses will often attempt to access resources that do not exist, so the error does not necessarily represent a problem';
  } elsif ($statusMessage =~ /405 Method Not Allowed/ ) {
    $errorMessage = 'The access method (GET, POST, HEAD) is not allowed on this resource';
  } elsif ($statusMessage =~ /406 Not Acceptable/ ) {
    $errorMessage = 'None of the acceptable file types (as requested by client) are available for this resource';
  } elsif ($statusMessage =~ /407 Proxy Authentication Required/ ) {
    $errorMessage = 'The client does not have access to this resource, proxy authorization is needed';
  } elsif ($statusMessage =~ /408 Request Timeout/ ) {
    $errorMessage = 'The client did not send a request within the required time period';
  } elsif ($statusMessage =~ /409 Conflict/ ) {
    $errorMessage = 'The request could not be completed due to a conflict with the current state of the resource';
  } elsif ($statusMessage =~ /410 Gone/ ) {
    $errorMessage = 'The requested resource is no longer available at the server and no forwarding address is known. This condition is similar to 404, except that the 410 error condition is expected to be permanent. Any robot seeing this response should delete the reference from its information store';
  } elsif ($statusMessage =~ /411 Length Required/ ) {
    $errorMessage = 'The request requires the Content-Length HTTP request field to be specified';
  } elsif ($statusMessage =~ /412 Precondition Failed/ ) {
    $errorMessage = 'The precondition given in one or more of the request-header fields evaluated to false when it was tested on the server';
  } elsif ($statusMessage =~ /413 Request Entity Too Large/ ) {
    $errorMessage = 'The server is refusing to process a request because the request entity is larger than the server is willing or able to process';
  } elsif ($statusMessage =~ /414 Request URL Too Large/ ) {
    $errorMessage = 'The server is refusing to service the request because the Request-URI is longer than the server is willing to interpret The URL is too long (possibly too many query keyword/value pairs)';
  } elsif ($statusMessage =~ /415 Unsupported Media Type/ ) {
    $errorMessage = 'The server is refusing to service the request because the entity of the request is in a format not supported by the requested resource for the requested method';
  } elsif ($statusMessage =~ /416 Requested Range Invalid/ ) {
    $errorMessage = 'The portion of the resource requested is not available or out of range';
  } elsif ($statusMessage =~ /417 Expectation Failed/ ) {
    $errorMessage = 'The Expect specifier in the HTTP request header can not be met';
  # ***************************************************************************
  # The 500 series of Web error codes indicate an error with the Web server   *
  # ***************************************************************************
  } elsif ($statusMessage =~ /500 Can't connect to proxy/ ) {
    $errorMessage = 'The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message';
  } elsif ($statusMessage =~ /500 Connect failed/ ) {
    $errorMessage = 'The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message';
  } elsif ($statusMessage =~ /500 Internal Server Error/ ) {
    $errorMessage = 'The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message (client certificate maybe needed)';
  } elsif ($statusMessage =~ /500 Proxy connect failed/ ) {
    $errorMessage = 'The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message';
  } elsif ($statusMessage =~ /500 Server Error/ ) {
    $errorMessage = 'The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message';
  } elsif ($statusMessage =~ /500 SSL read timeout/ ) {
    $errorMessage = 'The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message';
  } elsif ($statusMessage =~ /501 Not Implemented/ ) {
    $errorMessage = 'Function not implemented in Web server software. The request needs functionality not available on the server';
  } elsif ($statusMessage =~ /502 Bad Gateway/ ) {
    $errorMessage = 'Bad Gateway: a server being used by this Web server has sent an invalid response. The response by an intermediary server was invalid. This may happen if there is a problem with the DNS routing tables';
  } elsif ($statusMessage =~ /503 Service Unavailable/ ) {
    $errorMessage = 'Service temporarily unavailable because of currently/temporary overload or maintenance';
  } elsif ($statusMessage =~ /504 Gateway Timeout/ ) {
    $errorMessage = 'The server did not respond back to the gateway within acceptable time period';
  } elsif ($statusMessage =~ /505 HTTP Version Not Supported/ ) {
    $errorMessage = 'The server does not support the HTTP protocol version that was used in the request message';
  # ***************************************************************************
  # Error codes indicate an error with the ...                                *
  # ***************************************************************************
  } elsif ($statusMessage =~ /Failure of server APACHE bridge/ ) {
    $errorMessage = 'Weblogic Bridge Message: Failure of server APACHE bridge';

    if ($statusMessage =~ /No backend server available for connection/ ) {
      $errorMessage .= ' - No backend server available for connection';
    } elsif ($statusMessage =~ /Cannot connect to the server/ ) {
      $errorMessage .= ' - Cannot connect to the server';
    } elsif ($statusMessage =~ /Cannot connect to WebLogic/ ) {
      $errorMessage .= ' - Cannot connect to WebLogic';
    }
  # ***************************************************************************
  # Error codes indicate an error with Cactus XML::Parser                     *
  # ***************************************************************************
  } elsif ($statusMessage =~ /Cactus XML::Parser:/ ) {
    $statusMessage =~ s/\+{2}/\+\+<br>/g;
  } elsif (-s "$APPLICATIONPATH/custom/display.pm") {
    require "$APPLICATIONPATH/custom/display.pm";
	  $errorMessage = printStatusMessageCustom( decode_html_entities('E', $statusMessage) );
  }

  my $returnMessage = '  <TR><TD WIDTH="56">&nbsp;</TD><TD VALIGN="TOP">' . $statusMessage . '</TD></TR>' . "\n";
  $returnMessage .= '  <TR><TD WIDTH="56">&nbsp;</TD><TD>&nbsp;</TD><TD>&nbsp;</TD><TD class="StatusMessageError">' . encode_html_entities('E', $errorMessage) . '</TD></TR>' . "\n" if ($errorMessage); 
  return ( $returnMessage );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHtmlFooter {
  my $title = @_;

  print HTML    "</BODY>\n</HTML>";
  print HTMLCV  "</BODY>\n</HTML>";
  print HTMLMCV "</BODY>\n</HTML>";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printGroepFooter {
  my ($title, $show) = @_;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printItemFooter {
  my ($catalogID_uniqueKey, $catalogID, $uniqueKey, $title, $status, $timeslot, $statusIcon, $insertInMCV, $inIMW, $itemFullCondensedView, $printCondensedView, $arrayStatusMessage, $catalogID_uKey_timeperiodID) = @_;

  $itemFullCondensedView .= "</TR>\n";

  if (@$arrayStatusMessage) {
    $itemFullCondensedView .= '<TR style="{height: 0;}"><TD COLSPAN="'. $colspanDisplayTime .'"><DIV id="'.$catalogID_uniqueKey.'" style="display:none"><TABLE WIDTH=100% BORDER=0 CELLSPACING=1 CELLPADDING=2>'. "\n";
    foreach my $arrayStatusMessage ( @$arrayStatusMessage ) { $itemFullCondensedView .= printStatusMessage ( $arrayStatusMessage ); }
    $itemFullCondensedView .= "</TABLE></DIV></TD></TR>\n";
  }

  $groupFullView += 1;

  $groupCondensedView += $printCondensedView;

  my $groep = ( $title =~ /^\[(\d+)\]/ ? $1 : 0);
  push ( @multiarrayFullCondensedView, [ $ERRORS{"$status"}, $groep, $timeslot, $statusIcon, $itemFullCondensedView, $printCondensedView ] );
  my $priorityGroup = '-MCV-' . ( ( exists $$catalogID_uKey_timeperiodID{$catalogID}->{$uniqueKey}->{SDE_IMW}->{priority} ) ? $$catalogID_uKey_timeperiodID{$catalogID}->{$uniqueKey}->{SDE_IMW}->{priority} : 'P01' ) . '-';
  push ( @multiarrayMinimalCondensedView, [ $ERRORS{"$status"}, $priorityGroup, $timeslot, $statusIcon, $itemFullCondensedView ] ) if ( ( ! $statusIcon or ( $statusIcon and $insertInMCV ) ) and $status !~ /(?:OK|DEPENDENT|OFFLINE|NO TEST|TRENDLINE)/ and $printCondensedView and $inIMW );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printStatusFooter {
  my ($title, $emptyFullView, $emptyCondencedView, $emptyMinimalCondencedView, $playSoundStatus) = @_;

  print HTML   '</TABLE>', "\n";

  print HTML <<EOH;
<script language="JavaScript" type="text/javascript">
  function toggleDiv (div_id){
    if (document.getElementById(div_id)) {
      if (document.getElementById(div_id).style.display == 'none') {
        document.getElementById(div_id).style.display = 'block';
      } else {
        document.getElementById(div_id).style.display = 'none';
      }
    }
  }
</script>
EOH

  if ($playSoundStatus) {
    print HTML <<EOH;
<script language="JavaScript" type="text/javascript">
  var soundState = getSoundCookie( 'soundState' );

  if ( soundState != null && soundState == 'on' ) {
    playSound = '<embed src="$HTTPSURL/sound/$SOUND{$playSoundStatus}" width="" height="" alt="" hidden="true" autostart="true" loop="false"><\\/embed>';
    dynamicContentNS4NS6FF ('SoundStatus', playSound, 1);
  }
</script>
EOH
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  print HTMLCV '</TABLE>', "\n";

  print HTMLCV <<EOH;
<script language="JavaScript" type="text/javascript">
  function toggleDiv (div_id){
    if (document.getElementById(div_id)) {
      if (document.getElementById(div_id).style.display == 'none') {
        document.getElementById(div_id).style.display = 'block';
      } else {
        document.getElementById(div_id).style.display = 'none';
      }
    }
  }
</script>
EOH

  if ($playSoundStatus) {
    print HTMLCV <<EOH;
<script language="JavaScript" type="text/javascript">
  var soundState = getSoundCookie( 'soundState' );

  if ( soundState != null && soundState == 'on' ) {
    playSound = '<embed src="$HTTPSURL/sound/$SOUND{$playSoundStatus}" width="" height="" alt="" hidden="true" autostart="true" loop="false"><\\/embed>';
    dynamicContentNS4NS6FF ('SoundStatus', playSound, 1);
  }
</script>
EOH
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  print HTMLMCV '</TABLE>', "\n";

  print HTMLMCV <<EOH;
<script language="JavaScript" type="text/javascript">
  function toggleDiv (div_id){
    if (document.getElementById(div_id)) {
      if (document.getElementById(div_id).style.display == 'none') {
        document.getElementById(div_id).style.display = 'block';
      } else {
        document.getElementById(div_id).style.display = 'none';
      }
    }
  }
</script>
EOH

  if ($playSoundStatus) {
    print HTMLMCV <<EOH;
<script language="JavaScript" type="text/javascript">
  var soundState = getSoundCookie( 'soundState' );

  if ( soundState != null && soundState == 'on' ) {
    playSound = '<embed src="$HTTPSURL/sound/$SOUND{$playSoundStatus}" width="" height="" alt="" hidden="true" autostart="true" loop="false"><\\/embed>';
    dynamicContentNS4NS6FF ('SoundStatus', playSound, 1);
  }
</script>
EOH
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub maskPassword {
  my ($parameters) =  @_;

  # --dnPass=
  if ($parameters =~ /--dnPass=/) {
    $parameters =~ s/(--dnPass=)\w+/$1********/g;
  }

  # --proxy=user:pasword\@proxy
  if ($parameters =~ /--proxy=/) {
    $parameters =~ s/(--proxy=\w*:)\w*(\@\w+)/$1********$2/g;
  }

  # -p user:pasword\@proxy
  if ($parameters =~ /-p / and ($parameters !~ /-u / and $parameters !~ /--username=/)) {
    $parameters =~ s/(-p \w*:)\w*(\@\w+)/$1********$2/g;
  }

  # --password=
  if ($parameters =~ /--password=/) {
    $parameters =~ s/(--password=)\w+/$1********/g;
  }

  # --username= or -u and --password= or -p (database plugins)
  if ($parameters =~ /-p / and ($parameters =~ /-u / or $parameters =~ /--username=/)) {
    $parameters =~ s/(-p )\w+/$1********/g;
  }

  # --username= or -U and --password= or -P (ftp plugins)
  if ($parameters =~ /-P / and ($parameters =~ /-U / or $parameters =~ /--username=/)) {
    $parameters =~ s/(-P )\w+/$1********/g;
  }

  # j_username= or j_password= (J2EE based Applications)
  if ($parameters =~ /j_username=/ and $parameters =~ /j_password=/) {
    $parameters =~ s/(j_password=)\w+/$1********/g;
  }

  return ($parameters);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_usage () {
  print "Usage: $PROGNAME -H <MySQL hostname> [-C <Checklist>] [-P <pagedir>] [-L <loop>] [-t <trigger>] [-c <YYYY-MM-DD HH:MM:SS> ] [-T <displayTime>] [-l <lockMySQL>] [-D <debug>] [-V version] [-h help]\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help () {
  print_revision($PROGNAME, $version);
  print "ASNMTAP Display for the '$APPLICATION'

-H, --hostname=<HOSTNAME>
   HOSTNAME : hostname/address from the MySQL server
-C, --checklist=<FILENAME>
   FILENAME : filename from the checklist for the html output loop (default 'DisplayCT')
-P, --pagedir=<PAGEDIR>
   PAGEDIR  : sub directory name for the html output (default 'index')
-L, --loop=F|T
   F(alse)  : loop off (default)
   T(rue)   : loop on
-t, --trigger=F|T
   F(alse)  : trigger off (default)
   T(rue)   : trigger on
-c, --creationTime=<YYYY-MM-DD HH:MM:SS>
   YYYY-MM-DD HH:MM:SS: year, month, day, hours, minutes and seconds to use instead of the current time when --loop = F
-T, --displayTime=F|T
   F(alse)  : display timeslots into html output off
   T(rue)   : display timeslots into html output (default)
-l, --lockMySQL=F|T
   F(alse)  : lock MySQL table off (default)
   T(rue)   : lock MySQL table on
-D, --debug=F|T
   F(alse)  : screendebugging off (default)
   T(true)  : normal screendebugging on
-V, --version
-h, --help

Send email to $SENDEMAILTO if you have questions regarding
use of this software. To submit patches or suggest improvements, send
email to $SENDEMAILTO

";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
