#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, session.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MODERATOR);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "sessions.pl";
my $prgtext     = "Blocked Sessions";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;
use DBI;
use Time::Local;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir    = (defined $cgi->param('pagedir'))   ? $cgi->param('pagedir')   : '<NIHIL>';   $pagedir =~ s/\+/ /g;
my $pageset    = (defined $cgi->param('pageset'))   ? $cgi->param('pageset')   : 'moderator'; $pageset =~ s/\+/ /g;
my $debug      = (defined $cgi->param('debug'))     ? $cgi->param('debug')     : 'F';
my $action     = (defined $cgi->param('action'))    ? $cgi->param('action')    : 'listView';
my $CsessionID = (defined $cgi->param('sessionID')) ? $cgi->param('sessionID') : '';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rvOpendir, @cgisessPathFilenames, $nextAction, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, $userType, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'moderator', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Sessions", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&action=$action&sessionID=$CsessionID";

# Debug information
print "<pre>pagedir     : $pagedir<br>pageset     : $pageset<br>debug       : $debug<br>CGISESSID   : $sessionID<br>action      : $action<br>session ID  : $CsessionID<br>URL ...     : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($matchingSessionDetails, $matchingSessionsBlocked, $matchingSessionsActive, $matchingSessionsExpired, $matchingSessionsEmpty, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID";

  if ($action eq 'deleteView') {
    $htmlTitle    = "Delete Session '$CsessionID'";
    $submitButton = "Delete";
    $nextAction   = "delete";
  } elsif ($action eq 'delete') {
    my $cgisessFilename = "cgisess_$CsessionID";

    if (-e "$CGISESSPATH/$cgisessFilename") {
      unlink ($CGISESSPATH.'/'.$cgisessFilename);	

      if (-e "$CGISESSPATH/$cgisessFilename") {
        $htmlTitle = "Session '$cgisessFilename' not deleted, not enough rights";
      } else {
        $htmlTitle = "Session '$cgisessFilename' deleted";
      }
    } else {
      $htmlTitle = "Session '$cgisessFilename' not deleted, doesn't exist";
    }
  } elsif ($action eq 'detailsView') {
    $htmlTitle    = "Details for session '$CsessionID'";
    $submitButton = "Display";
    $nextAction   = "listView";

	my $colspan = 2;
    my $cgisessFilename = "cgisess_$CsessionID";
    my ($sessionExists, %session) = get_session_param ($CsessionID, $CGISESSPATH, $cgisessFilename, $debug);

    $matchingSessionDetails = "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><th colspan=\"$colspan\">$htmlTitle</th></tr>\n";

    if ( $sessionExists ) {
      my $Temail = $session{email}; $Temail =~ s/\\//g;
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">_SESSION_ID</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{_SESSION_ID}. "</td></tr>\n" if (defined $session{_SESSION_ID});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">_SESSION_REMOTE_ADDR</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{_SESSION_REMOTE_ADDR}. "</td></tr>\n" if (defined $session{_SESSION_REMOTE_ADDR});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">_SESSION_CTIME</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .scalar(localtime($session{_SESSION_CTIME})). "</td></tr>\n" if (defined $session{_SESSION_CTIME});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">_SESSION_ATIME</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .scalar(localtime($session{_SESSION_ATIME})). "</td></tr>\n" if (defined $session{_SESSION_ATIME});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">_SESSION_ETIME</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{_SESSION_ETIME}. "</td></tr>\n" if (defined $session{_SESSION_ETIME});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">_SESSION_EXPIRE_LIST</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{_SESSION_EXPIRE_LIST}. "</td></tr>\n" if (defined $session{_SESSION_EXPIRE_LIST});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">~login-trials</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{'~login-trials'}. "</td></tr>\n" if (defined $session{'~login-trials'});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">~logged-in</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{'~logged-in'}. "</td></tr>\n" if (defined $session{'~logged-in'});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">remote user</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{remoteUser}. "</td></tr>\n" if (defined $session{remoteUser});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">remote address</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{remoteAddr}. "</td></tr>\n" if (defined $session{remoteAddr});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">remote netmask</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{remoteNetmask}. "</td></tr>\n" if (defined $session{remoteNetmask});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">given name</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .encode_html_entities('V', $session{givenName}). "</td></tr>\n" if (defined $session{givenName});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">surname</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .encode_html_entities('V', $session{familyName}). "</td></tr>\n" if (defined $session{familyName});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">email</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$Temail. "</td></tr>\n" if (defined $session{email});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">key language</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{keyLanguage}. "</td></tr>\n" if (defined $session{keyLanguage});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">password</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{password}. "</td></tr>\n" if (defined $session{password});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">user type</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{userType}. "</td></tr>\n" if (defined $session{userType});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">pagedir</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{pagedir}. "</td></tr>\n" if (defined $session{pagedir});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">activated</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{activated}. "</td></tr>\n" if (defined $session{activated});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">icon add</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{iconAdd}. "</td></tr>\n" if (defined $session{iconAdd});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">icon details</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{iconDetails}. "</td></tr>\n" if (defined $session{iconDetails});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">icon edit</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{iconEdit}. "</td></tr>\n" if (defined $session{iconEdit});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">icon delete</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{iconDelete}. "</td></tr>\n" if (defined $session{iconDelete});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">icon query</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{iconQuery}. "</td></tr>\n" if (defined $session{iconQuery});
      $matchingSessionDetails .= "        <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">icon table</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$session{iconTable}. "</td></tr>\n" if (defined $session{iconTable});
    } else {
      $matchingSessionDetails .= "        <tr><td colspan=\"$colspan\">No active sessions found</td></tr>\n";
    }

    $matchingSessionDetails .= "      </table>\n";
  } elsif ($action eq 'listView') {
    $htmlTitle    = "All sessions listed";

    my $actionPressend = ($iconDelete or $iconDetails) ? 1 : 0;
    my $actionHeader = ($actionPressend) ? "<th>Action</th>" : '';
    my $colspan = 7 + $actionPressend;

    my $table  = "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">\n";
    my $header = "        <tr><th> Session ID </th><th> Remote User </th><th> Name </th><th> IP address </th><th> Activated </th><th> Login Trials </th><th> eTime </th>$actionHeader</tr>\n";

    $matchingSessionsBlocked = "$table        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><th colspan=\"$colspan\">Blocked Sessions</th></tr>\n$header";
    $matchingSessionsActive  = "$table        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><th colspan=\"$colspan\">Active Sessions</th></tr>\n$header";
    $matchingSessionsExpired = "$table        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><th colspan=\"$colspan\">Expired Sessions</th></tr>\n$header";
    $matchingSessionsEmpty   = "$table        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><th colspan=\"$colspan\">Empty Sessions</th></tr>\n$header";

    my ($numberRecordsIntoQueryBlocked, $numberRecordsIntoQueryActive, $numberRecordsIntoQueryExpired, $numberRecordsIntoQueryEmpty);
    $numberRecordsIntoQueryBlocked = $numberRecordsIntoQueryActive = $numberRecordsIntoQueryExpired = $numberRecordsIntoQueryEmpty = 0;

    my $currentTime = time();
    my $solaris = (-e '/usr/sbin/nslookup') ? 1 : 0; # solaris

    @cgisessPathFilenames = glob("$CGISESSPATH/cgisess_*");

    foreach my $cgisessPathFilename (@cgisessPathFilenames) {
      my (undef, $cgisessFilename) = split (/^$CGISESSPATH\//, $cgisessPathFilename);
      (undef, $CsessionID) = split (/^cgisess_/, $cgisessFilename);
      my ($sessionExists, %session) = get_session_param ($CsessionID, $CGISESSPATH, $cgisessFilename, $debug);

      if ( $sessionExists ) {
        my $sessionCtime = (defined $session{_SESSION_CTIME})       ? $session{_SESSION_CTIME}       : undef;
        my $sessionAtime = (defined $session{_SESSION_ATIME})       ? $session{_SESSION_ATIME}       : undef;
        my $sessionEtime = (defined $session{_SESSION_ETIME})       ? $session{_SESSION_ETIME}       : undef;
        my $remoteAddr   = (defined $session{_SESSION_REMOTE_ADDR}) ? $session{_SESSION_REMOTE_ADDR} : '';

        if ($solaris) { # solaris
          my $TremoteAddr = `/usr/sbin/nslookup $remoteAddr`;

		  if ($TremoteAddr) {
            $TremoteAddr =~ /^Name:\s+(.*)$/m;
            $remoteAddr = $1 if (defined $1);
          }
        } else { # linux
          my $TremoteAddr = `host -t ptr $remoteAddr`;

		  if ($TremoteAddr) {
            $TremoteAddr =~ /domain name pointer (.*)/;
            $remoteAddr = $1 if (defined $1);
          }
        }

        my $actionItem = ($actionPressend) ? "<td align=\"center\">&nbsp;" : '';
        my $urlWithAccessParametersAction = "$urlWithAccessParameters&amp;sessionID=$CsessionID&amp;action";
        $actionItem .= "<a href=\"$urlWithAccessParametersAction=detailsView\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Session Details\" alt=\"Session Details\" border=\"0\"></a>&nbsp;" if ($iconDetails);

        if ($iconDelete and defined $session{ASNMTAP} and defined $session{'~login-trials'}) {
          if ( $session{'~login-trials'} >= 3) {
            $actionItem .= "<a href=\"$urlWithAccessParametersAction=unblockView\"><img src=\"$IMAGESURL/$ICONSRECORD{delete}\" title=\"Unblock Session\" alt=\"Unblock Session\" border=\"0\"></a>&nbsp;";
          } else {
            $actionItem .= "<a href=\"$urlWithAccessParametersAction=deleteView\"><img src=\"$IMAGESURL/$ICONSRECORD{delete}\" title=\"Delete Session\" alt=\"Delete Session\" border=\"0\"></a>&nbsp;";
          }
        } else {
          $actionItem .= "<a href=\"$urlWithAccessParametersAction=deleteView\"><img src=\"$IMAGESURL/$ICONSRECORD{delete}\" title=\"Delete Session\" alt=\"Delete Session\" border=\"0\"></a>&nbsp;";
        }

        $actionItem .= "</td>" if ($actionPressend);

        if (defined $session{ASNMTAP}) {
          my $loginTrials  = (defined $session{'~login-trials'}) ? $session{'~login-trials'} : 0;
          my $loggedIn     = (defined $session{'~logged-in'})    ? $session{'~logged-in'}    : undef;
          my $remoteUser   = (defined $session{remoteUser})      ? $session{remoteUser}      : 'UNKNOWN';
          my $givenName    = (defined $session{givenName})       ? $session{givenName}       : undef;
          my $familyName   = (defined $session{familyName})      ? $session{familyName}      : undef;
          my $activated    = (defined $session{activated})       ? $session{activated}       : 'UNKNOWN';

          my $username     = (defined $givenName and defined $familyName) ? encode_html_entities('V', $givenName). ", " .encode_html_entities('V', $familyName) : '';
 
          if ( $debug eq 'T' ) {
            $remoteAddr = 'c: '. scalar(localtime($currentTime));
            $remoteAddr .= ' A: '. scalar(localtime($sessionAtime)) if (defined $sessionAtime);
            $remoteAddr .= ' E: '. $sessionEtime .' ' if (defined $sessionEtime);
          }

          my $currentSession = "        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>$CsessionID</td><td>$remoteUser</td><td>$username</td><td>$remoteAddr</td><td>$activated</td><td align=\"right\">$loginTrials</td><td>" .scalar(localtime($sessionAtime+$sessionEtime)). "</td>$actionItem</tr>\n";

          if ( $loginTrials >= 3) {
            $numberRecordsIntoQueryBlocked++;
            $matchingSessionsBlocked .= $currentSession;
          } elsif (defined $sessionAtime and defined $sessionEtime and ($sessionAtime + $sessionEtime) <= $currentTime) {
            $numberRecordsIntoQueryExpired++;
            $matchingSessionsExpired .= $currentSession;
          } elsif (defined $loggedIn and $loggedIn) {
            $numberRecordsIntoQueryActive++;
            $matchingSessionsActive  .= $currentSession;
          } else {
            $numberRecordsIntoQueryEmpty++;
            $matchingSessionsEmpty   .= $currentSession;
          }
        } else {
          $numberRecordsIntoQueryEmpty++;
          $matchingSessionsEmpty   .= "        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>$CsessionID</td><td>&nbsp;</td><td>&nbsp;</td><td>$remoteAddr</td><td>&nbsp;</td><td align=\"right\">&nbsp;</td><td>" .scalar(localtime($sessionAtime)). "</td>$actionItem</tr>\n";
        }
      }
    }

    $matchingSessionsBlocked .= "        <tr><td colspan=\"$colspan\">No blocked sessions found for any user</td></tr>\n" unless ( $numberRecordsIntoQueryBlocked );
    $matchingSessionsBlocked .= "      </table>\n";

    $matchingSessionsActive  .= "        <tr><td colspan=\"$colspan\">No active sessions found for any user</td></tr>\n" unless ( $numberRecordsIntoQueryActive );
    $matchingSessionsActive  .= "      </table>\n";

    $matchingSessionsExpired .= "        <tr><td colspan=\"$colspan\">No expired sessions found for any user</td></tr>\n" unless ( $numberRecordsIntoQueryExpired );
    $matchingSessionsExpired .= "      </table>\n";

    $matchingSessionsEmpty   .= "        <tr><td colspan=\"$colspan\">No empty sessions found for any user</td></tr>\n" unless ( $numberRecordsIntoQueryEmpty );
    $matchingSessionsEmpty   .= "      </table>\n";

    $nextAction = "listView";
  } elsif ($action eq 'unblockView') {
    $htmlTitle    = "Unblock Session '$CsessionID'";
    $submitButton = "Unblock";
    $nextAction   = "unblock";
  } elsif ($action eq 'unblock') {
    my $cgisessFilename = "cgisess_$CsessionID";

    if (-e "$CGISESSPATH/$cgisessFilename") {
      unlink ($CGISESSPATH.'/'.$cgisessFilename);	
      $htmlTitle = "Session '$cgisessFilename' unblocked";
    } else {
      $htmlTitle = "Session '$cgisessFilename' not unblocked, doesn't exist";
    }
  }

  # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

  if ($action eq 'deleteView' or $action eq 'unblockView') {
    print <<HTML;
<form action=\"$ENV{SCRIPT_NAME}\" method=\"post\" name=\"sessions\">
  <input type="hidden" name="pagedir"   value="$pagedir">
  <input type="hidden" name="pageset"   value="$pageset">
  <input type="hidden" name="debug"     value="$debug">
  <input type="hidden" name="CGISESSID" value="$sessionID">
  <input type="hidden" name="action"    value="$nextAction">
  <input type="hidden" name="sessionID" value="$CsessionID">
HTML
  } else {
    print "<br>\n";
  }

  print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0">
        <tr><td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView">[List all sessions]</a></td></tr>
      </table>
    </td></tr>
HTML

  if ($action eq 'deleteView' or $action eq 'unblockView') {
    print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
      <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Session ID: </b></td><td><input type="text" name="sessionID" value="$CsessionID" size="40" maxlength="40" disabled></td></tr>
        <tr><td>&nbsp;</td><td><br><input type="submit" value="$submitButton">&nbsp;&nbsp;<input type="reset" value="Reset"></td></tr>
      </table>
    </td></tr>
HTML
  } elsif ($action eq 'delete' or $action eq 'unblock') {
    print "    <tr><td align=\"center\"><br><br><h1>Session ID: $htmlTitle</h1></td></tr>";
  } elsif ($action eq 'detailsView') {
    print <<HTML;
    <tr><td>
      <table border="0" cellspacing="0" cellpadding="0" align="center">
        <tr align="center"><td><br>$matchingSessionDetails</td></tr>
      </table>
    </td></tr>
HTML
  } else {
    print <<HTML;
    <tr><td>
      <table border="0" cellspacing="0" cellpadding="0" align="center">
        <tr align="center"><td><br>$matchingSessionsBlocked</td></tr>
        <tr align="center"><td><br>$matchingSessionsActive</td></tr>
        <tr align="center"><td><br>$matchingSessionsExpired</td></tr>
        <tr align="center"><td><br>$matchingSessionsEmpty</td></tr>
      </table>
    </td></tr>
HTML
  }

  print "  </table>\n";

  if ($action eq 'deleteView' or $action eq 'unblockView') {
    print "</form>\n";
  } else {
    print "<br>\n";
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
