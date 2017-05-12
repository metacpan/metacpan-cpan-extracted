#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, comments.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;
use DBI;
use Time::Local;
use Date::Calc qw(Add_Delta_Days);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MEMBER :DBREADONLY :DBREADWRITE :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "comments.pl";
my $prgtext     = "Comments";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $supportRequest  = ( (-s "$APPLICATIONPATH/custom/supportRequest.pm") ? 1 : 0 );

my $localYear       = sprintf ("%04d", (localtime)[5] );
my $localMonth      = sprintf ("%02d", (localtime)[4] );
my $currentYear     = sprintf ("%04d", (localtime)[5] + 1900 );
my $currentMonth    = sprintf ("%02d", (localtime)[4] + 1 );
my $currentDay      = sprintf ("%02d", (localtime)[3] );
my $currentHour     = sprintf ("%02d", (localtime)[2] );
my $currentMin      = sprintf ("%02d", (localtime)[1] );
my $currentSec      = sprintf ("%02d", (localtime)[0] );

# URL Access Parameters
my $cgi = new CGI;
my $pagedir         = (defined $cgi->param('pagedir'))        ? $cgi->param('pagedir')        : 'index'; $pagedir =~ s/\+/ /g;
my $pageset         = (defined $cgi->param('pageset'))        ? $cgi->param('pageset')        : 'index-cv'; $pageset =~ s/\+/ /g;
my $debug           = (defined $cgi->param('debug'))          ? $cgi->param('debug')          : 'F';
my $pageNo          = (defined $cgi->param('pageNo'))         ? $cgi->param('pageNo')         : 1;
my $pageOffset      = (defined $cgi->param('pageOffset'))     ? $cgi->param('pageOffset')     : 0;
my $action          = (defined $cgi->param('action'))         ? $cgi->param('action')         : 'listView';
my $CcatalogID      = (defined $cgi->param('catalogID'))      ? $cgi->param('catalogID')      : $CATALOGID;
my $Cid             = (defined $cgi->param('id'))             ? $cgi->param('id')             : '';
my $CuKey           = (defined $cgi->param('uKey'))           ? $cgi->param('uKey')           : 'none';
my $Ctitle          = (defined $cgi->param('title'))          ? $cgi->param('title')          : '';
my $Cinstability    = (defined $cgi->param('instability'))    ? $cgi->param('instability')    : 'off';
my $Cpersistent     = (defined $cgi->param('persistent'))     ? $cgi->param('persistent')     : 'off';
my $Cdowntime       = (defined $cgi->param('downtime'))       ? $cgi->param('downtime')       : 'off';
my $CactivationDate = (defined $cgi->param('activationDate')) ? $cgi->param('activationDate') : '';
my $CactivationTime = (defined $cgi->param('activationTime')) ? $cgi->param('activationTime') : '';
my $CsuspentionDate = (defined $cgi->param('suspentionDate')) ? $cgi->param('suspentionDate') : '';
my $CsuspentionTime = (defined $cgi->param('suspentionTime')) ? $cgi->param('suspentionTime') : '';
my $CproblemSolved  = (defined $cgi->param('problemSolved'))  ? $cgi->param('problemSolved')  : 0;
my $CremoteUser     = (defined $cgi->param('remoteUser'))     ? $cgi->param('remoteUser')     : 'none';
my $CcommentData    = (defined $cgi->param('commentData'))    ? $cgi->param('commentData')    : '';

$CcommentData =~ s/"/'/g;

my ($pageDir, $environment) = split (/\//, $pagedir, 2);
$environment = 'P' unless (defined $environment);

my $htmlTitle = $APPLICATION .' - '. $ENVIRONMENT{$environment};

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, $remoteUserLoggedOn, undef, undef, $givenNameLoggedOn, $familyNameLoggedOn, undef, undef, $userType, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'guest', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Comments", "catalogID=$CcatalogID&uKey=$CuKey");

unless ( defined $errorUserAccessControl ) {
  unless ( defined $userType ) {
    print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
    print "<br>\n<table WIDTH=\"100%\" border=0><tr><td class=\"HelpPluginFilename\">\n<font size=\"+1\">$errorUserAccessControl</font>\n</td></tr></table>\n<br>\n";
  } else {
    $action = "listView" if ( $userType == 0 and ($action eq 'insertView' or $action eq 'insert' or $action eq 'createView' or $action eq 'create' or $action eq 'deleteView' or $action eq 'delete' or $action eq 'editView' or $action eq 'edit' or $action eq 'updateView' or $action eq 'update' ) );
    my $urlWithAccessParameters = $ENV{SCRIPT_NAME} ."?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID";

    my ($CactivationTimeslot, $CsuspentionTimeslot, $tsec, $tmin, $thour, $tday, $tmonth, $tyear);

    if ($CactivationDate ne '' and $CactivationTime ne '') {
      ($tyear, $tmonth, $tday) = split(/\-/, $CactivationDate);
      $tyear -= 1900; $tmonth--;
      ($thour, $tmin, $tsec) = split(/:/, $CactivationTime);
      $CactivationTimeslot = timelocal($tsec, $tmin, $thour, $tday, $tmonth, $tyear);
    } else {
      $CactivationTimeslot = '';
    }

    if ($CsuspentionDate ne '' and $CsuspentionTime ne '') {
      ($tyear, $tmonth, $tday) = split(/\-/, $CsuspentionDate);
      $tyear -= 1900; $tmonth--;
      ($thour, $tmin, $tsec) = split(/:/, $CsuspentionTime);
      $CsuspentionTimeslot = timelocal($tsec, $tmin, $thour, $tday, $tmonth, $tyear);
    } else {
      $CsuspentionTimeslot = '';
    }

    my ($CentryDate, $CentryTime, $CentryTimeslot, $CsolvedDate, $CsolvedTime, $CsolvedTimeslot);

    if ($action eq 'historyView' or $action eq 'history') {
      $CentryDate = ($cgi->param('entryDate') or '');
      $CentryTime = ($cgi->param('entryTime') or '');

      if ($CentryDate ne '' and $CentryTime ne '') {
        ($tyear, $tmonth, $tday) = split(/\-/, $CentryDate);
        $tyear -= 1900; $tmonth--;
        ($thour, $tmin, $tsec) = split(/:/, $CentryTime);
        $CentryTimeslot = timelocal($tsec, $tmin, $thour, $tday, $tmonth, $tyear);
      } else {
        $CentryTimeslot = '';
      }

      $CsolvedDate = ($cgi->param('solvedDate') or '');
      $CsolvedTime = ($cgi->param('solvedTime') or '');

      if ($CsolvedDate ne '' and $CsolvedTime ne '') {
        ($tyear, $tmonth, $tday) = split(/\-/, $CsolvedDate);
        $tyear -= 1900; $tmonth--;
        ($thour, $tmin, $tsec) = split(/:/, $CsolvedTime);
        $CsolvedTimeslot = timelocal($tsec, $tmin, $thour, $tday, $tmonth, $tyear);
      } else {
        $CsolvedTimeslot = '';
      }
    } else {
      $CentryDate        = ($cgi->param('entryDate')      or "$currentYear-$currentMonth-$currentDay");
      $CentryTime        = ($cgi->param('entryTime')      or "$currentHour:$currentMin:$currentSec");
      $CentryTimeslot    = ($cgi->param('entryTimeslot')  or timelocal($currentSec, $currentMin, $currentHour, $currentDay, $localMonth, $localYear));

      if ($CproblemSolved) {
        $CsolvedDate     = ($cgi->param('solvedDate')     or "$currentYear-$currentMonth-$currentDay");
        $CsolvedTime     = ($cgi->param('solvedTime')     or "$currentHour:$currentMin:$currentSec");
        $CsolvedTimeslot = ($cgi->param('solvedTimeslot') or timelocal($currentSec, $currentMin, $currentHour, $currentDay, $localMonth, $localYear));
      } else {
        $CsolvedDate     = ($cgi->param('solvedDate')     or "0000-00-00");
        $CsolvedTime     = ($cgi->param('solvedTime')     or "00:00:00");
        $CsolvedTimeslot = ($cgi->param('solvedTimeslot') or '');
      }
    }

    # Init parameters
    my ($rv, $dbh, $sth, $sql, $numberRecordsIntoQuery, $uKey, $title, $dummy, $submitButton, $nextAction, $commentText, $commentData, $uKeySelect, $matchingComments, $navigationBar, $remoteUsersSelect);
    $nextAction = '';

    # Serialize the URL Access Parameters into a string
    my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&action=$action&catalogID=$CcatalogID&id=$Cid&uKey=$CuKey&title=$Ctitle&entryDate=$CentryDate&entryTime=$CentryTime&entryTimeslot=$CentryTimeslot&activationDate=$CactivationDate&activationTime=$CactivationTime&suspentionDate=$CsuspentionDate&suspentionTime=$CsuspentionTime&instability=$Cinstability&persistent=$Cpersistent&downtime=$Cdowntime&problemSolved=$CproblemSolved&solvedDate=$CsolvedDate&solvedTime=$CsolvedTime&solvedTimeslot=$CsolvedTimeslot&remoteUser=$CremoteUser&commentData=$CcommentData";

    # Debug information
    print "<pre>pagedir       : $pagedir<br>pageset       : $pageset<br>debug         : $debug<br>CGISESSID     : $sessionID<br>page no       : $pageNo<br>page offset   : $pageOffset<br>action        : $action<br>catalog ID    : $CcatalogID<br>id            : $Cid<br>uKey          : $CuKey<br>title         : $Ctitle<br>entryDate     : $CentryDate<br>entryTime     : $CentryTime<br>entryTimeslot : $CentryTimeslot<br>activationDate: $CactivationDate<br>activationTime: $CactivationTime<br>suspentionDate: $CsuspentionDate<br>suspentionTime: $CsuspentionTime<br>instability   : $Cinstability<br>persistent    : $Cpersistent<br>downtime      : $Cdowntime<br>problemSolved : $CproblemSolved<br>solvedDate    : $CsolvedDate<br>solvedTime    : $CsolvedTime<br>solvedTimeslot: $CsolvedTimeslot<br>remoteUser    : $CremoteUser<br>commentData   : $CcommentData<br>URL ...       : $urlAccessParameters</pre>" if ( $debug eq 'T' );

    # open connection to database and query data
    $rv  = 1;

    $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

    if ($dbh and $rv) {
      if ($action eq 'insertView' or $action eq 'createView' or $action eq 'historyView') {
        if ($CuKey eq 'none') {
          $sql = "select uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as optionValueTitle from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.environment = '$environment' and pagedir REGEXP '/$pageDir/' and production = '1' and activated = 1 and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by optionValueTitle";
        } else {
          $sql = "select uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where uKey = '$CuKey' and catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment";
        }

        ($rv, $uKeySelect, $htmlTitle) = create_combobox_from_DBI ($rv, $dbh, $sql, 0, ($supportRequest ? 'create' : 'insert'), $CuKey, 'uKey', 'none', '-Select-', '', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

        if ($rv) {
          $nextAction = ($action eq 'insertView') ? 'insert' : (($action eq 'createView') ? 'create' : 'history');
        }
      } else {
        ($rv, $Ctitle) = get_title( $dbh, $rv, $CcatalogID, $CuKey, $debug, -1, $sessionID );
        $Ctitle = $CuKey if (! defined $Ctitle or $Ctitle eq '');

        if ($action eq 'insert') {
          $htmlTitle    = "$Ctitle: id $Cid inserted";
          $nextAction   = "listView" if ($rv);
        } elsif ($action eq 'create') {
          $htmlTitle    = "$Ctitle: id $Cid created";
          $nextAction   = "listView" if ($rv);
        } elsif ($action eq 'deleteView') {
          $htmlTitle    = "$Ctitle: delete id $Cid ?";
          $commentText  = "Solution comment";
          $commentData  = '';
          $submitButton = "Solved";
          $nextAction   = "delete" if ($rv);
        } elsif ($action eq 'delete') {
          $htmlTitle    = "$Ctitle: id $Cid solved";
          $nextAction   = "listView" if ($rv);
        } elsif ($action eq 'editView') {
          $htmlTitle    = "$Ctitle: edit id $Cid ?";
          $commentText  = "Edit comment";
          $commentData  = '';
          $submitButton = "Edit";
          $nextAction   = "edit" if ($rv);
        } elsif ($action eq 'edit') {
          $htmlTitle    = "$Ctitle: id $Cid edited";
          $nextAction   = "listView" if ($rv);
        } elsif ($action eq 'listView') {
          $htmlTitle    = "$Ctitle: active id's listed";
          $nextAction   = "listView" if ($rv);
        } elsif ($action eq 'listAllView') {
          $htmlTitle    = "$Ctitle: all active id's listed";
          $nextAction   = "listAllView" if ($rv);
        } elsif ($action eq 'updateView') {
          $htmlTitle    = "$Ctitle: update id $Cid ?";
          $commentText  = "Update comment";
          $commentData  = '';
          $submitButton = "Update";
          $nextAction   = "update" if ($rv);
        } elsif ($action eq 'update') {
          $htmlTitle    = "$Ctitle: id $Cid updated";
          $nextAction   = "listView" if ($rv);
        } elsif ($action eq 'solvedView') {
          $htmlTitle    = "$Ctitle: solved id's listed";
          $nextAction   = "solvedView" if ($rv);
        } elsif ($action eq 'history') {
          $htmlTitle    = "$Ctitle: history id's listed";
          $nextAction   = "history" if ($rv);
        }
      }

      $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
    }

    if ( $rv ) {
      $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

      if ($action eq 'insertView' or $action eq 'createView' or $action eq 'historyView') {
        my ($remoteUser, $givenName, $familyName);

        if (($action eq 'insertView' or $action eq 'createView') and defined $remoteUserLoggedOn) {
          $CremoteUser = $remoteUserLoggedOn;
          $sql = "select remoteUser, email from $SERVERTABLUSERS where catalogID = '$CcatalogID' and remoteUser = '$CremoteUser'";
        } else {
          my $andActivated = ($action eq 'insertView' or $action eq 'createView') ? "and activated = 1" : '';
          $sql = "select remoteUser, email from $SERVERTABLUSERS where catalogID = '$CcatalogID' and pagedir REGEXP '/$pageDir/' and remoteUser <> 'admin' and remoteUser <> 'sadmin' $andActivated order by email";
        }

        ($rv, $remoteUsersSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 0, '', $CremoteUser, 'remoteUser', 'none', '-Select-', '', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      } else {
        if ($dbh and $rv) {
          if ($action eq 'insert' or $action eq 'create') {
            if ($CactivationDate eq '' or $CactivationTime eq '') {
              $CactivationDate     = $CentryDate;
              $CactivationTime     = $CentryTime;
              $CactivationTimeslot = $CentryTimeslot;
            }

            if ($CsuspentionDate eq '' or $CsuspentionTime eq '') {
              $CsuspentionDate     = "0000-00-00";
              $CsuspentionTime     = "00:00:00";
              $CsuspentionTimeslot = "9999999999";
            }

            if ($action eq 'create') {
              require "$APPLICATIONPATH/custom/supportRequest.pm";
              my ($description, $outageStartDate, $outageStartTime) = ('Description: Support Ticket ...');
              my ($succeeded, $alert, $error) = insertSupportRequest ($CcatalogID, $CuKey, $title, $CremoteUser, $outageStartDate, $outageStartTime, $description, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID, $debug);

              if (defined $outageStartDate and defined $outageStartTime) {
                $CactivationDate = $outageStartDate;
                $CactivationTime = $outageStartTime;
                ($tyear, $tmonth, $tday) = split(/\-/, $CactivationDate);
                $tyear -= 1900; $tmonth--;
                ($thour, $tmin, $tsec) = split(/:/, $CactivationTime);
                $CactivationTimeslot = timelocal($tsec, $tmin, $thour, $tday, $tmonth, $tyear);
              }

              unless ($succeeded) {
                $action = $nextAction = 'createError';
                $htmlTitle = "$Ctitle: id $Cid create error";
                $matchingComments = "<tr><td><H1>Error:</H1>\n'$error'<BR></td></tr>";
              }

              $CcommentData = 'Support Request: '. (($succeeded) ? "SR $succeeded" : "ERROR '$error'");
              $CcommentData .= ", $CactivationDate $CactivationTime";
            }

            my $dummyInstability = ($Cinstability eq 'on') ? 1 : 0;
            my $dummyPersistent  = ($Cpersistent  eq 'on') ? 1 : 0;
            my $dummyDowntime    = ($Cdowntime    eq 'on') ? 1 : 0;
            $sql = 'INSERT INTO ' .$SERVERTABLCOMMENTS. ' SET catalogID="' .$CcatalogID. '", uKey="' .$CuKey. '", replicationStatus="I", title="' .$Ctitle. '", entryDate="' .$CentryDate. '", entryTime="' .$CentryTime.'", entryTimeslot="' .$CentryTimeslot. '", instability="' .$dummyInstability. '", persistent="' .$dummyPersistent. '", downtime="' .$dummyDowntime. '", problemSolved="' .$CproblemSolved. '", solvedDate="' .$CsolvedDate. '", solvedTime="' .$CsolvedTime. '", solvedTimeslot="' .$CsolvedTimeslot. '", remoteUser="' .$CremoteUser. '", commentData="' .$CcommentData. '", activationDate="' .$CactivationDate. '", activationTime="' .$CactivationTime. '", activationTimeslot="' .$CactivationTimeslot. '", suspentionDate="' .$CsuspentionDate. '", suspentionTime="' .$CsuspentionTime. '", suspentionTimeslot="' .$CsuspentionTimeslot. '"';
            $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

            if ( $dummyDowntime ) {
              my $tDebug = ($debug eq 'T') ? 2 : 0;

              my ($Tpagedirs, $Temail, $Tpagedir, $sendEmailTo);
              $sql = "select pagedir from $SERVERTABLPLUGINS where catalogID = '$CcatalogID' and uKey = '$CuKey' order by uKey";
              $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
              $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

              if ( $rv ) {
                ($Tpagedirs) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
                $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
              }

              $sql = "select email, pagedir from $SERVERTABLUSERS where catalogID = '$CcatalogID' and activated = 1 and downtimeScheduling = 1 and userType > 0";
              $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
              $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
              $sth->bind_columns( \$Temail, \$Tpagedir ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

              if ( $rv ) {
                while( $sth->fetch() ) { 
                  chop $Tpagedir;
                  my (undef, @pagedirs) = split (/\//, $Tpagedir);

                  foreach my $pagedirs (@pagedirs) {
                    if ($Tpagedirs =~ /\/$pagedirs\//) {
                      $sendEmailTo .= "$Temail,";
                      last;
                    }
                  }
                }

                $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
              }

              my $header = "Downtime scheduling for $Ctitle from $CactivationDate $CactivationTime until ";
              $header .= ($CsuspentionDate eq '0000-00-00') ? '????-??-?? ??:??:??' : "$CsuspentionDate $CsuspentionTime.";
              my $subject = "$BUSINESS / $DEPARTMENT / $APPLICATION / $header";
              my $message = "Geachte, Cher,\n\n$header\n\n$CcommentData\n\n-- $givenNameLoggedOn $familyNameLoggedOn\n\n$APPLICATION\n$DEPARTMENT\n$BUSINESS\n";

              if (defined $sendEmailTo) {
                my $returnCode = sending_mail ( $SERVERLISTSMTP, $sendEmailTo, $SENDMAILFROM, $subject, $message, $tDebug );
                print "Problem sending email to the '$APPLICATION' members\n" unless ( $returnCode );
              }
            }
          } elsif ($action eq 'delete') {
            $sql = 'SELECT commentData from ' .$SERVERTABLCOMMENTS. ' where catalogID="' .$CcatalogID. '" and id="' .$Cid. '"';
            $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
            $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
            ($commentData) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, 'Logon', 3600, '', $sessionID) if ( $rv and $sth->rows);
 			      $commentData = "$commentData\n<hr>$CcommentData\n\nClosed by: $givenNameLoggedOn, $familyNameLoggedOn ($remoteUserLoggedOn) on $CsolvedDate $CsolvedTime";

            $sql = 'UPDATE ' .$SERVERTABLCOMMENTS. ' SET replicationStatus="U", problemSolved="' .$CproblemSolved. '", solvedDate="' .$CsolvedDate. '", solvedTime="' .$CsolvedTime. '", solvedTimeslot="' .$CsolvedTimeslot. '", commentData="' .$commentData. '" where catalogID="' .$CcatalogID. '" and id="' .$Cid. '"';
            $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          } elsif ($action eq 'editView') {
            $sql = 'SELECT commentData from ' .$SERVERTABLCOMMENTS. ' where catalogID="' .$CcatalogID. '" and id="' .$Cid. '"';
            $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
            $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
            ($commentData) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, 'Logon', 3600, '', $sessionID) if ( $rv and $sth->rows);
          } elsif ($action eq 'edit') {
 			      my $commentData = "$CcommentData\n\nEdited by: $givenNameLoggedOn, $familyNameLoggedOn ($remoteUserLoggedOn) on $CentryDate $CentryTime";
            $sql = 'UPDATE ' .$SERVERTABLCOMMENTS. ' SET replicationStatus="U", commentData="' .$commentData. '" where catalogID="' .$CcatalogID. '" and id="' .$Cid. '"';
            $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          } elsif ($action eq 'update') {
            $sql = 'SELECT commentData from ' .$SERVERTABLCOMMENTS. ' where catalogID="' .$CcatalogID. '" and id="' .$Cid. '"';
            $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
            $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
            ($commentData) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, 'Logon', 3600, '', $sessionID) if ( $rv and $sth->rows);
 			      $commentData = "$commentData\n<hr>$CcommentData\n\nUpdated by: $givenNameLoggedOn, $familyNameLoggedOn ($remoteUserLoggedOn) on $CentryDate $CentryTime";

            $sql = 'UPDATE ' .$SERVERTABLCOMMENTS. ' SET replicationStatus="U", commentData="' .$commentData. '" where catalogID="' .$CcatalogID. '" and id="' .$Cid. '"';
            $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          }

          if ($action eq 'deleteView' or $action eq 'editView' or $action eq 'updateView') {
            my ($id, $uKey, $title, $givenName, $familyName, $instability, $persistent, $downtime, $entryDate, $entryTime, $activationDate, $activationTime, $suspentionDate, $suspentionTime, $commentData);
            $sql = "select id, uKey, title, $SERVERTABLUSERS.givenName, $SERVERTABLUSERS.familyName, instability, persistent, downtime, entryDate, entryTime, activationDate, activationTime, suspentionDate, suspentionTime, commentData from $SERVERTABLCOMMENTS, $SERVERTABLUSERS where $SERVERTABLCOMMENTS.catalogID = '$CcatalogID' and id = '$Cid' and $SERVERTABLCOMMENTS.catalogID = $SERVERTABLUSERS.catalogID and $SERVERTABLCOMMENTS.remoteUser = $SERVERTABLUSERS.remoteUser";
            $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
            $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
            $sth->bind_columns( \$id, \$uKey, \$title, \$givenName, \$familyName, \$instability, \$persistent, \$downtime, \$entryDate, \$entryTime, \$activationDate, \$activationTime, \$suspentionDate, \$suspentionTime, \$commentData ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

            if ( $rv ) {
              $matchingComments = "\n      <table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='$COLORSTABLE{TABLE}'>\n        <tr><th colspan=\"9\">Catalog ID: $CcatalogID</th><th></th></tr>\n        <tr><th>Id</th><th>Title</th><th>Remote User</th><th>Entry Date/Time</th><th>Activation Date/Time</th><th>Suspention Date/Time</th><th>Instability</th><th>Persistent</th><th>Downtime</th></tr>\n";

              if ( $sth->rows ) {
                while( $sth->fetch() ) {
                  $commentData = encode_html_entities('C', $commentData);
                  $commentData =~ s/\n/<br>/g;
                  $matchingComments .= "        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td rowspan=\"2\" valign=\"top\">$id</td><td>$title</td><td>$givenName, $familyName</td><td>$entryDate \@ $entryTime</td><td>$activationDate \@ $activationTime</td><td>$suspentionDate \@ $suspentionTime</td><td>$instability</td><td>$persistent</td><td>$downtime</td></tr><tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td colspan=\"8\">$commentData</td></tr>\n";
                }
              } else {
                $matchingComments .= "        <tr><td colspan=9>No records found for catalog ID: $CcatalogID & id: $Cid</td></tr>\n";
              }

              $matchingComments .= "      </table>";
              $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
            }
  	      } elsif ( $action ne 'createError' ) {
            my ($sqlUKey, $sqlUKeyRows, $sqlWhere, $actionColspan, $actionHeader, $ActionItem, $navigationBarSqlWhere);
			
            if ($action eq 'solvedView' or $action eq 'historyView' or $action eq 'history') {
              $actionColspan = 1;
              $actionHeader  = "<th>Solved Date/Time</th>";
              $sqlUKey       = "$SERVERTABLCOMMENTS.catalogID = '$CcatalogID' and uKey = '$CuKey' and";
              $sqlUKeyRows   = "catalog ID: $CcatalogID & uKey: $CuKey";
              $sqlWhere      = '';

              if ($action eq 'history') {
                $sqlWhere .= "and $SERVERTABLCOMMENTS.remoteUser = '$CremoteUser' " if ($CremoteUser ne 'none');
                $sqlWhere .= "and entryTimeslot >= $CentryTimeslot " if ($CentryTimeslot ne '');
                $sqlWhere .= "and solvedTimeslot <= $CsolvedTimeslot " if ($CsolvedTimeslot ne '');
              }

              $navigationBarSqlWhere = "$sqlWhere and problemSolved = '1'";
              $sqlWhere .= "and problemSolved = '1' order by solvedTimeslot desc limit $pageOffset, $RECORDSONPAGE";
            } else {
              if ($action eq 'listAllView') {
                $actionHeader = '';
                $sqlUKey      = "$SERVERTABLCOMMENTS.catalogID = '$CcatalogID' and";
                $sqlUKeyRows  = "all plugins from catalog ID: $CcatalogID";
              } else {
                $actionHeader = "<th>Action</th>" if ( $userType != 0 );
                $sqlUKey      = "$SERVERTABLCOMMENTS.catalogID = '$CcatalogID' and uKey = '$CuKey' and";
                $sqlUKeyRows  = "catalog ID: $CcatalogID & uKey: $CuKey";
              }

              $actionColspan = 0;
              $navigationBarSqlWhere = "and problemSolved = '0'";
              $sqlWhere = "and problemSolved = '0' order by entryTimeslot limit $pageOffset, $RECORDSONPAGE";
	  	      }

            $sql = "select SQL_NO_CACHE count(id) from $SERVERTABLCOMMENTS, $SERVERTABLUSERS where $sqlUKey $SERVERTABLCOMMENTS.catalogID = $SERVERTABLUSERS.catalogID and $SERVERTABLCOMMENTS.remoteUser = $SERVERTABLUSERS.remoteUser $navigationBarSqlWhere";

            ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
            $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, "$urlWithAccessParameters&amp;catalogID=$CcatalogID&amp;uKey=$CuKey&amp;action=$nextAction");

    		    my ($id, $uKey, $title, $givenName, $familyName, $instability, $persistent, $downtime, $entryDate, $entryTime, $activationDate, $activationTime, $suspentionDate, $suspentionTime, $solvedDate, $solvedTime, $commentData);
            $sql = "select id, uKey, title, $SERVERTABLUSERS.givenName, $SERVERTABLUSERS.familyName, instability, persistent, downtime, entryDate, entryTime, activationDate, activationTime, suspentionDate, suspentionTime, solvedDate, solvedTime, commentData from $SERVERTABLCOMMENTS, $SERVERTABLUSERS where $sqlUKey $SERVERTABLCOMMENTS.catalogID = $SERVERTABLUSERS.catalogID and $SERVERTABLCOMMENTS.remoteUser = $SERVERTABLUSERS.remoteUser $sqlWhere";

            $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
            $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
            $sth->bind_columns( \$id, \$uKey, \$title, \$givenName, \$familyName, \$instability, \$persistent, \$downtime, \$entryDate, \$entryTime, \$activationDate, \$activationTime, \$suspentionDate, \$suspentionTime, \$solvedDate, \$solvedTime, \$commentData ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

            if ( $rv ) {
              $matchingComments = "\n      <table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='$COLORSTABLE{TABLE}'>\n        <tr><th colspan=\"". (10 + $actionColspan) ."\">Catalog ID: $CcatalogID</th></tr>\n        <tr><th>Id</th><th>Title</th><th>Remote User</th><th>Entry Date/Time</th><th>Activation Date/Time</th><th>Suspention Date/Time</th><th>Instability</th><th>Persistent</th><th>Downtime</th>$actionHeader</tr>\n";

              if ( $sth->rows ) {
                while( $sth->fetch() ) {
                  $commentData = encode_html_entities('C', $commentData);
                  $commentData =~ s/\n/<br>/g;

                  if ($action eq 'solvedView' or $action eq 'historyView' or $action eq 'history') {
		  	            $ActionItem = "<td>$solvedDate \@ $solvedTime</td>";
                  } elsif ($action eq 'listAllView') {
	  		            $ActionItem = '';
                  } else {
                    my $urlWithAccessParametersAction = "$urlWithAccessParameters&amp;id=$id&amp;catalogID=$CcatalogID&amp;uKey=$uKey";

                    if ( $userType != 0 ) {
  	  		            $ActionItem  = "<td align=\"center\" rowspan=\"2\" valign=\"middle\">";
	  		              $ActionItem .= "<a href=\"$urlWithAccessParametersAction&amp;action=editView&amp;problemSolved=0\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Problem\" alt=\"Edit Problem\" border=\"0\"></a>" if ( $userType >= 4 );
    	  		          $ActionItem .= "<a href=\"$urlWithAccessParametersAction&amp;action=updateView&amp;problemSolved=0\"><img src=\"$IMAGESURL/$ICONSRECORD{duplicate}\" title=\"Update Problem\" alt=\"Update Problem\" border=\"0\"></a>" if ( $userType >= 1 );
	  		              $ActionItem .= "<a href=\"$urlWithAccessParametersAction&amp;action=deleteView&amp;problemSolved=1\"><img src=\"$IMAGESURL/$ICONSRECORD{delete}\" title=\"Problem Solved\" alt=\"Problem Solved\" border=\"0\"></a>";
	  		              $ActionItem .= "</td>";
                    }
                  }

                  $matchingComments .= "        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td rowspan=\"2\" valign=\"top\">$id</td><td>$title</td><td>$givenName, $familyName</td><td>$entryDate \@ $entryTime</td><td>$activationDate \@ $activationTime</td><td>$suspentionDate \@ $suspentionTime</td><td>$instability</td><td>$persistent</td><td>$downtime</td>$ActionItem</tr><tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td colspan=\"". (8 + $actionColspan) ."\">$commentData</td></tr>\n";
                }
              } else {
                $matchingComments .= "        <tr><td colspan=\"". (10 + $actionColspan) ."\">No records found for $sqlUKeyRows</td></tr>\n";
              }

              $matchingComments .= "        <tr><td colspan=\"". (10 + $actionColspan) ."\">$navigationBar</td></tr>\n" if ($navigationBar);
              $matchingComments .= "      </table>\n";
              $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
            }
          }
        }

        $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      if ( $rv ) {
        # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        if ($action eq 'insertView' or $action eq 'createView' or $action eq 'deleteView' or $action eq 'editView' or $action eq 'historyView' or $action eq 'updateView' ) {
          print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', "<script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/TimeParserValidator.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/AnchorPosition.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/CalendarPopup.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/date.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/PopupWindow.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\">document.write(getCalendarStyles());</script>", $sessionID);

          if ($action eq 'insertView' or $action eq 'createView' or $action eq 'historyView') {
            if ($action eq 'insertView' or $action eq 'createView') {
              my ($firstYear, $firstMonth, $firstDay) = Add_Delta_Days ($currentYear, $currentMonth, $currentDay, -1);

              print <<HTML;
<script language="JavaScript" type="text/javascript" id="jsCal1Calendar">
  var cal1Calendar = new CalendarPopup("CalendarDIV");
  cal1Calendar.offsetX = 1;
  cal1Calendar.showNavigationDropdowns();
  cal1Calendar.addDisabledDates(null, "$firstYear-$firstMonth-$firstDay");
</script>
HTML
            } else {
              my ($firstYear, $firstMonth, $firstDay) = Add_Delta_Days ($currentYear, $currentMonth, $currentDay, +1);

              print <<HTML;
<script language="JavaScript" type="text/javascript" id="jsCal1Calendar">
  var cal1Calendar = new CalendarPopup("CalendarDIV");
  cal1Calendar.offsetX = 1;
  cal1Calendar.showNavigationDropdowns();
  cal1Calendar.addDisabledDates("$firstYear-$firstMonth-$firstDay", null);
</script>
HTML
            }

            print <<HTML;
<DIV ID="CalendarDIV" STYLE="position:absolute;visibility:hidden;background-color:black;layer-background-color:black;"></DIV>

<script language="JavaScript1.2" type="text/javascript">
function validateForm() {
  var now = new Date();
  currentlyFullYear = now.getFullYear();
  currentlyMonth    = now.getMonth();
  currentlyDay      = now.getDate();
  currentlyHours    = now.getHours();
  currentlyMinutes  = now.getMinutes();
  currentlySeconds  = now.getSeconds();

  var nowEpochtime  = Date.UTC(currentlyFullYear, currentlyMonth, currentlyDay, currentlyHours, currentlyMinutes, currentlySeconds);

  var objectRegularExpressionDateFormat = /\^20\\d\\d-\\d\\d-\\d\\d\$/;
  var objectRegularExpressionDateValue  = /\^20\\d\\d-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])\$/;

  var objectRegularExpressionTimeFormat = /\^\\d\\d:\\d\\d:\\d\\d\$/;
  var objectRegularExpressionTimeValue  = /\^[0-1]\\d|2[0-3]:[0-5]\\d:[0-5]\\d\$/;

  if( document.comments.uKey.options[document.comments.uKey.selectedIndex].value == 'none' ) {
    document.comments.uKey.focus();
    alert('Please create/select one of the applications!');
    return false;
  }

HTML

            if ($action eq 'insertView' or $action eq 'createView') {
              print <<HTML;
  if( document.comments.remoteUser.options[document.comments.remoteUser.selectedIndex].value == 'none' ) {
    document.comments.remoteUser.focus();
    alert('Please create/select one of the remote users!');
    return false;
  }

HTML

              if ($action eq 'insertView') {
                print <<HTML;
  if ( document.comments.commentData.value == null || document.comments.commentData.value == '' ) {
    document.comments.commentData.focus();
    alert('Please enter a comment!');
    return false;
  }

  if ( document.comments.activationDate.value != null && document.comments.activationDate.value != '' ) {
    if ( ! objectRegularExpressionDateFormat.test(document.comments.activationDate.value) ) {
      document.comments.activationDate.focus();
      alert('Please re-enter activation date: Bad date format!');
      return false;
    }

    if ( ! objectRegularExpressionDateValue.test(document.comments.activationDate.value) ) {
      document.comments.activationDate.focus();
      alert('Please re-enter activation date: Bad date value!');
      return false;
    }
  }

  if ( ( document.comments.activationDate.value == '' && document.comments.activationTime.value != '' ) || ( document.comments.activationDate.value != '' && document.comments.activationTime.value == '' ) ) {
    if ( document.comments.activationDate.value == '' ) {
      document.comments.activationDate.focus();
      alert('Please enter one activation date!');
    } else {
      document.comments.activationTime.focus();
      alert('Please enter one activation time!');
    }

    return false;
  } else if ( document.comments.activationDate.value != '' && document.comments.activationTime.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.comments.activationTime.value) ) {
      document.comments.activationTime.focus();
      alert('Please re-enter activation time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.comments.activationTime.value) ) {
      document.comments.activationTime.focus();
      alert('Please re-enter activation time: Bad time value!');
      return false;
    }
  }

  var activationEpochtime = 0;

  if ( document.comments.activationTime.value != null && document.comments.activationTime.value != '' ) {
    activationDate      = document.comments.activationDate.value;
    activationFullYear  = activationDate.substring(0, 4);
    activationMonth     = activationDate.substring(5, 7) - 1;
    activationDay       = activationDate.substring(8, 10);
    activationTime      = document.comments.activationTime.value;
    activationHours     = activationTime.substring(0, 2);
    activationMinutes   = activationTime.substring(3, 5);
    activationSeconds   = activationTime.substring(6, 8);
    activationEpochtime = Date.UTC(activationFullYear, activationMonth, activationDay, activationHours, activationMinutes, activationSeconds);

    if ( nowEpochtime > activationEpochtime ) {
      document.comments.activationDate.focus();
      alert('Please re-enter activation date/time: Date/Time are into the past!');
      return false;
    }
  } else {
    activationEpochtime = nowEpochtime;
  }

  if ( document.comments.suspentionDate.value != null && document.comments.suspentionDate.value != '' ) {
    if ( ! objectRegularExpressionDateFormat.test(document.comments.suspentionDate.value) ) {
      document.comments.suspentionDate.focus();
      alert('Please re-enter suspention date: Bad date format!');
      return false;
    }

    if ( ! objectRegularExpressionDateValue.test(document.comments.suspentionDate.value) ) {
      document.comments.suspentionDate.focus();
      alert('Please re-enter suspention date: Bad date value!');
      return false;
    }
  }

  if ( ( document.comments.suspentionDate.value == '' && document.comments.suspentionTime.value != '' ) || ( document.comments.suspentionDate.value != '' && document.comments.suspentionTime.value == '' ) ) {
    if ( document.comments.suspentionDate.value == '' ) {
      document.comments.suspentionDate.focus();
      alert('Please enter one suspention date!');
    } else {
      document.comments.suspentionTime.focus();
      alert('Please enter one suspention time!');
    }

    return false;
  } else if ( document.comments.suspentionDate.value != '' && document.comments.suspentionTime.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.comments.suspentionTime.value) ) {
      document.comments.suspentionTime.focus();
      alert('Please re-enter suspention time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.comments.suspentionTime.value) ) {
      document.comments.suspentionTime.focus();
      alert('Please re-enter suspention time: Bad time value!');
      return false;
    }
  }

  var suspentionEpochtime = 0;

  if ( document.comments.suspentionTime.value != null && document.comments.suspentionTime.value != '' ) {
    suspentionDate      = document.comments.suspentionDate.value;
    suspentionFullYear  = suspentionDate.substring(0, 4);
    suspentionMonth     = suspentionDate.substring(5, 7) - 1;
    suspentionDay       = suspentionDate.substring(8, 10);
    suspentionTime      = document.comments.suspentionTime.value;
    suspentionHours     = suspentionTime.substring(0, 2);
    suspentionMinutes   = suspentionTime.substring(3, 5);
    suspentionSeconds   = suspentionTime.substring(6, 8);
    suspentionEpochtime = Date.UTC(suspentionFullYear, suspentionMonth, suspentionDay, suspentionHours, suspentionMinutes, suspentionSeconds);

    if ( nowEpochtime > suspentionEpochtime ) {
      document.comments.suspentionDate.focus();
      alert('Please re-enter suspention date/time: Date/Time are into the past!');
      return false;
    }
  }

  if ( activationEpochtime != 0 && suspentionEpochtime != 0 ) {
    if ( activationEpochtime > suspentionEpochtime ) {
      document.comments.activationDate.focus();
      alert('Please re-enter activation/suspention date/time: Activation Date/Time > Suspention Date/Time !');
      return false;
    }
  }
HTML
            }
          } elsif ($action eq 'historyView') {
            print <<HTML;
  if ( document.comments.entryDate.value != null && document.comments.entryDate.value != '' ) {
    if ( ! objectRegularExpressionDateFormat.test(document.comments.entryDate.value) ) {
      document.comments.entryDate.focus();
      alert('Please re-enter entry date: Bad date format!');
      return false;
    }

    if ( ! objectRegularExpressionDateValue.test(document.comments.entryDate.value) ) {
      document.comments.entryDate.focus();
      alert('Please re-enter entry date: Bad date value!');
      return false;
    }
  }

  if ( ( document.comments.entryDate.value == '' && document.comments.entryTime.value != '' ) || ( document.comments.entryDate.value != '' && document.comments.entryTime.value == '' ) ) {
    if ( document.comments.entryDate.value == '' ) {
      document.comments.entryDate.focus();
      alert('Please enter one entry date!');
    } else {
      document.comments.entryTime.focus();
      alert('Please enter one entry time!');
    }

    return false;
  } else if ( document.comments.entryDate.value != '' && document.comments.entryTime.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.comments.entryTime.value) ) {
      document.comments.entryTime.focus();
      alert('Please re-enter entry time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.comments.entryTime.value) ) {
      document.comments.entryTime.focus();
      alert('Please re-enter entry time: Bad time value!');
      return false;
    }
  }

  var entryEpochtime = 0;

  if ( document.comments.entryTime.value != null && document.comments.entryTime.value != '' ) {
    entryDate      = document.comments.entryDate.value;
    entryFullYear  = entryDate.substring(0, 4);
    entryMonth     = entryDate.substring(5, 7) - 1;
    entryDay       = entryDate.substring(8, 10);
    entryTime      = document.comments.entryTime.value;
    entryHours     = entryTime.substring(0, 2);
    entryMinutes   = entryTime.substring(3, 5);
    entrySeconds   = entryTime.substring(6, 8);
    entryEpochtime = Date.UTC(entryFullYear, entryMonth, entryDay, entryHours, entryMinutes, entrySeconds);

    if ( entryEpochtime > nowEpochtime ) {
      document.comments.entryDate.focus();
      alert('Please re-enter entry date/time: Date/Time are into the future!');
      return false;
    }
  }

  if ( document.comments.solvedDate.value != null && document.comments.solvedDate.value != '' ) {
    if ( ! objectRegularExpressionDateFormat.test(document.comments.solvedDate.value) ) {
      document.comments.solvedDate.focus();
      alert('Please re-enter solved date: Bad date format!');
      return false;
    }

    if ( ! objectRegularExpressionDateValue.test(document.comments.solvedDate.value) ) {
      document.comments.solvedDate.focus();
      alert('Please re-enter solved date: Bad date value!');
      return false;
    }
  }

  if ( ( document.comments.solvedDate.value == '' && document.comments.solvedTime.value != '' ) || ( document.comments.solvedDate.value != '' && document.comments.solvedTime.value == '' ) ) {
    if ( document.comments.solvedDate.value == '' ) {
      document.comments.solvedDate.focus();
      alert('Please enter one solved date!');
    } else {
      document.comments.solvedTime.focus();
      alert('Please enter one solved time!');
    }

    return false;
  } else if ( document.comments.solvedDate.value != '' && document.comments.solvedTime.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.comments.solvedTime.value) ) {
      document.comments.solvedTime.focus();
      alert('Please re-enter solved time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.comments.solvedTime.value) ) {
      document.comments.solvedTime.focus();
      alert('Please re-enter solved time: Bad time value!');
      return false;
    }
  }

  var solvedEpochtime = 0;

  if ( document.comments.solvedTime.value != null && document.comments.solvedTime.value != '' ) {
    solvedDate      = document.comments.solvedDate.value;
    solvedFullYear  = solvedDate.substring(0, 4);
    solvedMonth     = solvedDate.substring(5, 7) - 1;
    solvedDay       = solvedDate.substring(8, 10);
    solvedTime      = document.comments.solvedTime.value;
    solvedHours     = solvedTime.substring(0, 2);
    solvedMinutes   = solvedTime.substring(3, 5);
    solvedSeconds   = solvedTime.substring(6, 8);
    solvedEpochtime = Date.UTC(solvedFullYear, solvedMonth, solvedDay, solvedHours, solvedMinutes, solvedSeconds);
	
    if ( solvedEpochtime > nowEpochtime) {
      document.comments.solvedDate.focus();
      alert('Please re-enter solved date/time: Date/Time are into the future!');
      return false;
    }
  }

  if ( entryEpochtime != 0 && solvedEpochtime != 0 ) {
    if ( entryEpochtime > solvedEpochtime ) {
      document.comments.entryDate.focus();
      alert('Please re-enter entry/solved date/time: entry Date/Time > solved Date/Time !');
      return false;
    }
  }
HTML
            }

            print <<HTML;
  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="comments" onSubmit="return validateForm();">
HTML
          } else {
            print "<form action=\"$ENV{\"SCRIPT_NAME\"}\" method=\"post\" name=\"comments\">\n";
          }

          print <<HTML;
  <input type="hidden" name="pagedir"    value="$pagedir">
  <input type="hidden" name="pageset"    value="$pageset">
  <input type="hidden" name="debug"      value="$debug">
  <input type="hidden" name="CGISESSID"  value="$sessionID">
  <input type="hidden" name="pageNo"     value="$pageNo">
  <input type="hidden" name="pageOffset" value="$pageOffset">
  <input type="hidden" name="action"     value="$nextAction">
HTML
        } else {
          print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
          print "<br>\n";
        }

        print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

        if ( $userType != 0 ) {
          print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=insertView&amp;catalogID=$CcatalogID&amp;uKey=$CuKey">[Insert comment]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML

          if ( $supportRequest ) {
            print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=createView&amp;catalogID=$CcatalogID&amp;uKey=$CuKey">[Create support request]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
          }
        }

        print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView&amp;catalogID=$CcatalogID&amp;uKey=$CuKey">[List active comments]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listAllView&amp;catalogID=$CcatalogID&amp;uKey=$CuKey">[List active comments for all plugins]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=solvedView&amp;catalogID=$CcatalogID&amp;uKey=$CuKey">[Show solved comments]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=historyView&amp;catalogID=$CcatalogID&amp;uKey=$CuKey">[Show history comments]</a></td>
	  </tr></table>
	</td></tr>
    <tr><td>&nbsp;</td></tr>
HTML

        my $creatviewDisabled = ($action eq 'createView') ? 'disabled' : '';

        if ($action eq 'insertView' or $action eq 'createView' or $action eq 'historyView') {
          my $instabilityDisabled = ($action eq 'createView' or $userType < 2) ? 'disabled' : '';
          my $persistentDisabled  = ($action eq 'createView' or $userType < 2) ? 'disabled' : '';
          my $downtimeDisabled    = ($action eq 'createView') ? 'disabled' : '';

          my $instabilityChecked  = ($Cinstability eq 'on') ? ' checked' : '';
          my $persistentChecked   = ($Cpersistent  eq 'on') ? ' checked' : '';
          my $downtimeChecked     = ($Cdowntime    eq 'on') ? ' checked' : '';

          print <<HTML;
    <tr><td><table border="0" cellspacing="0" cellpadding="0">
      <tr><td><b>Catalog ID: </b></td><td>
        <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled>
      </td></tr>
      <tr><td><b>Application: </b></td><td>
        $uKeySelect
      </td></tr><tr><td><b>Remote User: </b></td><td>
        $remoteUsersSelect
      </td>
HTML

          if ($action eq 'insertView' or $action eq 'createView') {
            print <<HTML;
      </tr><tr>
        <td valign="top"><b>Comment: </b></td>
        <td><textarea name=commentData cols=84 rows=13 $creatviewDisabled>$CcommentData</textarea></td>
      </tr><tr>
        <td><b>Instability: </b></td>
        <td><b><input type="checkbox" name="instability" $instabilityChecked $instabilityDisabled></b> 'checked' means 'instability' and 'not checked' means 'not instability'</td>
      </tr><tr>
        <td><b>Persistent: </b></td>
        <td><b><input type="checkbox" name="persistent" $persistentChecked $persistentDisabled></b> 'checked' means 'persistent' and 'not checked' means 'not persistent'</td>
      </tr><tr><td>&nbsp;</td><td>
          When 'Instability' and 'Persistent' are checked, this 'comment' will be not visible into the 'Minimal Condenced View'
		</td>
      </tr><tr>
        <td><b>Downtime: </b></td>
        <td><b><input type="checkbox" name="downtime" $downtimeChecked $downtimeDisabled></b> 'checked' means 'downtime scheduling' and 'not checked' means 'no downtime scheduling'</td>
      </tr><tr>
        <td>Activation: </td>
        <td>
          <b><input type="text" name="activationDate" value="$CactivationDate" size="10" maxlength="10" $creatviewDisabled></b>&nbsp;
		      <a href="#" onclick="cal1Calendar.select(document.forms[1].activationDate, 'activationDateCalendar','yyyy-MM-dd'); return false;" name="activationDateCalendar" id="activationDateCalendar"><img src="$IMAGESURL/cal.gif" alt="Calendar" border="0"></a>&nbsp;format: yyyy-mm-dd&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
          <b><input type="text" name="activationTime" value="$CactivationTime" size="8" maxlength="8" onChange="ReadISO8601time(document.forms['comments'].activationTime.value);" $creatviewDisabled></b> format: hh:mm:ss, 00:00:00 to 23:59:59
		</td>
      </tr><tr>
        <td>Suspention: </td>
        <td>
          <b><input type="text" name="suspentionDate" value="$CsuspentionDate" size="10" maxlength="10" $creatviewDisabled></b>&nbsp;
		      <a href="#" onclick="cal1Calendar.select(document.forms[1].suspentionDate, 'suspentionDateCalendar','yyyy-MM-dd'); return false;" name="suspentionDateCalendar" id="suspentionDateCalendar"><img src="$IMAGESURL/cal.gif" alt="Calendar" border="0"></a>&nbsp;format: yyyy-mm-dd&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
          <b><input type="text" name="suspentionTime" value="$CsuspentionTime" size="8" maxlength="8" onChange="ReadISO8601time(document.forms['comments'].suspentionTime.value);" $creatviewDisabled></b> format: hh:mm:ss, 00:00:00 to 23:59:59
		</td>
      </tr><tr><td>&nbsp;</td><td>
        <br>
        <b>Problem automatically solved when</b> ('not persistent' has higher priority then 'persistent')<b>:</b>
        <ul type="circle">
          <li>instability:
            <ul type="disc">
              <li>problem is <b>never</b> automatically solved</li>
            </ul>
          </li>
          <li>not persistent:
            <ul type="disc">
              <li>problem is automatically solved when 'last n results are OK' and 'current Timeslot' > 'Activation Date/time'</li>
        	  <li>problem is automatically solved when 'current Timeslot' > 'Suspention Date/time'</li>
            </ul>
          </li>
          <li>persistent:
            <ul type="disc">
              <li>problem is automatically solved when 'current Timeslot' > 'Suspention Date/time'</li>
              <li>problem is <b>never</b> automatically solved when 'Suspention Date/time' is missing</li>
            </ul>
          </li>
        </ul>
	  </td>
HTML

            $submitButton = ($action eq 'insertView') ? 'Insert' : 'Create';
          } elsif ($action eq 'historyView') {
            $submitButton = 'History';

            print <<HTML;
      </tr><tr>
        <td>Entry: </td>
        <td>
          <b><input type="text" name="entryDate" value="$CentryDate" size="10" maxlength="10"></b>&nbsp;<a href="#" onclick="cal1Calendar.select(document.forms[1].entryDate, 'entryDateCalendar','yyyy-MM-dd'); return false;" name="entryDateCalendar" id="entryDateCalendar"><img src="$IMAGESURL/cal.gif" alt="Calendar" border="0"></a>&nbsp;format: yyyy-mm-dd&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
          <b><input type="text" name="entryTime" value="$CentryTime" size="8" maxlength="8" onChange="ReadISO8601time(document.forms['comments'].entryTime.value);"></b> format: hh:mm:ss, 00:00:00 to 23:59:59
		</td>
      </tr><tr>
        <td>Solved: </td>
        <td>
          <b><input type="text" name="solvedDate" value="$CsolvedDate" size="10" maxlength="10"></b>&nbsp;<a href="#" onclick="cal1Calendar.select(document.forms[1].solvedDate, 'solvedDateCalendar','yyyy-MM-dd'); return false;" name="solvedDateCalendar" id="solvedDateCalendar"><img src="$IMAGESURL/cal.gif" alt="Calendar" border="0"></a>&nbsp;format: yyyy-mm-dd&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
          <b><input type="text" name="solvedTime" value="$CsolvedTime" size="8" maxlength="8" onChange="ReadISO8601time(document.forms['comments'].solvedTime.value);"></b> format: hh:mm:ss, 00:00:00 to 23:59:59
		</td>
      </tr><tr><td>&nbsp;</td><td>&nbsp;</td>
HTML
          }

          print <<HTML;
	  </tr><tr><td>&nbsp;</td><td>Please enter all required information before committing the command. Required fields are marked in bold.</td>
      </tr><tr align="left"><td align="right"><br><input type="submit" value="$submitButton"></td><td><br><input type="reset" value="Reset"></td></tr>
	</table></td></tr>
HTML
        } elsif ($action eq 'deleteView' or $action eq 'editView' or $action eq 'updateView') {
          print <<HTML;
      <tr align="center"><td>
        <input type="hidden" name="catalogID"      value="$CcatalogID">
        <input type="hidden" name="id"             value="$Cid">
        <input type="hidden" name="uKey"           value="$CuKey">
        <input type="hidden" name="problemSolved"  value="$CproblemSolved">
        <input type="hidden" name="solvedDate"     value="$CsolvedDate">
        <input type="hidden" name="solvedTime"     value="$CsolvedTime">
        <input type="hidden" name="solvedTimeslot" value="$CsolvedTimeslot">
      </td></tr><tr align="center"><td>
        <table align="center" border="0" cellspacing="0" cellpadding="0"><tr>
          <td colspan="2">$matchingComments</td>
        </tr><tr><td colspan="2">&nbsp;</td></tr><tr>
          <td valign="top"><b>$commentText:</b>&nbsp;&nbsp;</td>
          <td align="right"><textarea name=commentData cols=84 rows=13 $creatviewDisabled>$commentData</textarea></td>
        </tr></table>
      </tr><tr><td colspan="2">&nbsp;</td>
	  </tr><tr align="center"><td colspan="2"><input type="submit" value="$submitButton"> <input type="reset" value="Reset"></td></tr>
HTML
        } else {
          print "<tr align=\"center\"><td>$matchingComments</td></tr>\n";
        }

        print "  </table>\n";

        if ($action eq 'insertView' or $action eq 'createView' or $action eq 'deleteView' or $action eq 'editView' or $action eq 'historyView' or $action eq 'updateView') {
          print <<HTML;
        <input type="hidden" name="catalogID"      value="$CcatalogID">
        <input type="hidden" name="uKey"           value="$CuKey">
</form>
HTML
        } else {
          print "<br>\n";
        }
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
