# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, package ASNMTAP::Asnmtap::Applications::CGI
# ----------------------------------------------------------------------------------------------------------

package ASNMTAP::Asnmtap::Applications::CGI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(cluck);
use Time::Local;

# include the class files - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time qw(&get_datetimeSignal);

use ASNMTAP::Asnmtap::Applications qw(:APPLICATIONS :COMMANDS :_HIDDEN :CGI);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Applications::CGI::ISA         = qw(Exporter ASNMTAP::Asnmtap::Applications);

  %ASNMTAP::Asnmtap::Applications::CGI::EXPORT_TAGS = (ALL         => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO $TYPEMONITORING $RUNCMDONDEMAND
                                                                           $CAPTUREOUTPUT
                                                                           $PREFIXPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH
                                                                           %ERRORS %STATE %TYPE

                                                                           &call_system &sending_mail

                                                                           $CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND

                                                                           &_checkAccObjRef
                                                                           &_checkSubArgs0 &_checkSubArgs1 &_checkSubArgs2
                                                                           &_checkReadOnly0 &_checkReadOnly1 &_checkReadOnly2
                                                                           &_dumpValue

                                                                           $APPLICATIONPATH $PLUGINPATH
																		   
                                                                           $ASNMTAPMANUAL
                                                                           $DATABASE $CATALOGID
                                                                           $AWSTATSENABLED
                                                                           $CONFIGDIR $CGISESSDIR $DEBUGDIR $REPORTDIR $RESULTSDIR
                                                                           $CGISESSPATH $HTTPSPATH $IMAGESPATH $PDPHELPPATH $RESULTSPATH $SSHKEYPATH $WWWKEYPATH
                                                                           $HTTPSSERVER $REMOTE_HOST $REMOTE_ADDR $HTTPSURL $IMAGESURL $PDPHELPURL $RESULTSURL
                                                                           $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                                                                           $SSHLOGONNAME $RSYNCIDENTITY $SSHIDENTITY $WWWIDENTITY
                                                                           $RMVERSION $RMDEFAULTUSER
                                                                           $CHARTDIRECTORLIB
                                                                           $HTMLTOPDFPRG $HTMLTOPDFHOW $HTMLTOPDFOPTNS
                                                                           $PERFPARSEBIN $PERFPARSEETC $PERFPARSELIB $PERFPARSESHARE $PERFPARSECGI $PERFPARSEENABLED
                                                                           $PERFPARSEVERSION $PERFPARSECONFIG $PERFPARSEDATABASE $PERFPARSEHOST $PERFPARSEPORT $PERFPARSEUSERNAME $PERFPARSEPASSWORD
                                                                           $RECORDSONPAGE $NUMBEROFFTESTS $VERIFYNUMBEROK $VERIFYMINUTEOK $FIRSTSTARTDATE $STRICTDATE
                                                                           %COLORS %COLORSPIE %COLORSRRD %COLORSTABLE %ICONS %ICONSACK %ICONSUNSTABLE %ICONSRECORD %ICONSSYSTEM %ENVIRONMENT %SOUND %QUARTERS
                                                                           &get_session_param
                                                                           &set_doIt_and_doOffline
                                                                           &encode_html_entities &print_header &print_legend

                                                                           $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE
                                                                           $SERVERNAMEREADONLY $SERVERPORTREADONLY $SERVERUSERREADONLY $SERVERPASSREADONLY
                                                                           $SERVERTABLCATALOG $SERVERTABLCLLCTRDMNS $SERVERTABLCOMMENTS $SERVERTABLCOUNTRIES $SERVERTABLCRONTABS $SERVERTABLDISPLAYDMNS $SERVERTABLDISPLAYGRPS $SERVERTABLENVIRONMENT $SERVERTABLEVENTS $SERVERTABLEVENTSCHNGSLGDT $SERVERTABLEVENTSDISPLAYDT $SERVERTABLHOLIDYS $SERVERTABLHOLIDYSBNDL $SERVERTABLLANGUAGE $SERVERTABLPAGEDIRS $SERVERTABLPLUGINS $SERVERTABLREPORTS $SERVERTABLREPORTSPRFDT $SERVERTABLRESULTSDIR $SERVERTABLSERVERS $SERVERTABLTIMEPERIODS $SERVERTABLUSERS $SERVERTABLVIEWS
					  
                                                                           &user_session_and_access_control
                                                                           &do_action_DBI &error_trap_DBI &check_record_exist &create_sql_query_events_from_range_year_month &create_sql_query_from_range_SLA_window
                                                                           &get_title &get_sql_startDate_sqlEndDate_numberOfDays_test &get_sql_crontab_scheduling_report_data
                                                                           &create_combobox_from_keys_and_values_pairs &create_combobox_from_DBI &create_combobox_multiple_from_DBI 
                                                                           &record_navigation_table &record_navigation_bar &record_navigation_bar_alpha ) ],

                                                      APPLICATIONS => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO $TYPEMONITORING $RUNCMDONDEMAND
                                                                           $CAPTUREOUTPUT
                                                                           $PREFIXPATH $PLUGINPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH
                                                                           %ERRORS %STATE %TYPE

                                                                           &sending_mail) ],

                                                      COMMANDS     => [ qw($CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND) ],

                                                     _HIDDEN       => [ qw(&_checkAccObjRef
                                                                           &_checkSubArgs0 &_checkSubArgs1 &_checkSubArgs2
                                                                           &_checkReadOnly0 &_checkReadOnly1 &_checkReadOnly2
                                                                           &_dumpValue) ],

                                                      CGI          => [ qw($APPLICATIONPATH

                                                                           $DATABASE $CATALOGID
                                                                           $AWSTATSENABLED
                                                                           $CONFIGDIR $CGISESSDIR $DEBUGDIR $REPORTDIR $RESULTSDIR
                                                                           $CGISESSPATH $HTTPSPATH $IMAGESPATH $PDPHELPPATH $RESULTSPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH $SSHKEYPATH $WWWKEYPATH
                                                                           $HTTPSSERVER $REMOTE_HOST $REMOTE_ADDR $HTTPSURL $IMAGESURL $PDPHELPURL $RESULTSURL
                                                                           $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                                                                           $CHARTDIRECTORLIB
                                                                           $HTMLTOPDFPRG $HTMLTOPDFHOW $HTMLTOPDFOPTNS
                                                                           $PERFPARSEBIN $PERFPARSEETC $PERFPARSELIB $PERFPARSESHARE $PERFPARSECGI $PERFPARSEENABLED
                                                                           $RECORDSONPAGE $NUMBEROFFTESTS $VERIFYNUMBEROK $VERIFYMINUTEOK $FIRSTSTARTDATE $STRICTDATE
                                                                           %ENVIRONMENT
                                                                           &encode_html_entities &print_header &print_legend

                                                                           &user_session_and_access_control
                                    	 	 					                         &do_action_DBI &error_trap_DBI &check_record_exist
                                                                           &get_title
                                                                           &create_combobox_from_keys_and_values_pairs &create_combobox_from_DBI &create_combobox_multiple_from_DBI
                                                                           &record_navigation_table &record_navigation_bar &record_navigation_bar_alpha ) ],


                                                      MEMBER       => [ qw(%COLORS %COLORSTABLE %ICONS %ICONSRECORD ) ],

                                                      MODERATOR    => [ qw(%COLORS %COLORSTABLE %ICONS %ICONSRECORD %ICONSSYSTEM
                                                                           $SSHLOGONNAME
                                                                           &get_session_param
                                                                           &set_doIt_and_doOffline

                                                                           &get_sql_crontab_scheduling_report_data ) ],

                                                      ADMIN        => [ qw(%COLORSTABLE %ICONSRECORD ) ],

                                                      SADMIN       => [ qw(%COLORSTABLE %ICONSRECORD
                                                                           $SSHLOGONNAME $RSYNCIDENTITY $SSHIDENTITY $WWWIDENTITY
                                                                           $RMVERSION $RMDEFAULTUSER ) ],

                                                      DBPERFPARSE  => [ qw($PERFPARSEVERSION $PERFPARSECONFIG $PERFPARSEDATABASE $PERFPARSEHOST $PERFPARSEPORT $PERFPARSEUSERNAME $PERFPARSEPASSWORD ) ],
                                                      DBREADONLY   => [ qw($SERVERNAMEREADONLY $SERVERPORTREADONLY $SERVERUSERREADONLY $SERVERPASSREADONLY ) ],
                                                      DBREADWRITE  => [ qw($SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE ) ],
                                                      DBTABLES     => [ qw($SERVERTABLCATALOG $SERVERTABLCLLCTRDMNS $SERVERTABLCOMMENTS $SERVERTABLCOUNTRIES $SERVERTABLCRONTABS $SERVERTABLDISPLAYDMNS $SERVERTABLDISPLAYGRPS $SERVERTABLENVIRONMENT $SERVERTABLEVENTS $SERVERTABLEVENTSCHNGSLGDT $SERVERTABLEVENTSDISPLAYDT $SERVERTABLHOLIDYS $SERVERTABLHOLIDYSBNDL $SERVERTABLLANGUAGE $SERVERTABLPAGEDIRS $SERVERTABLPLUGINS $SERVERTABLREPORTS $SERVERTABLREPORTSPRFDT $SERVERTABLRESULTSDIR $SERVERTABLSERVERS $SERVERTABLTIMEPERIODS $SERVERTABLUSERS $SERVERTABLVIEWS ) ],
													  
                                                      REPORTS      => [ qw(%COLORS %COLORSPIE %COLORSRRD %COLORSTABLE %ICONS %QUARTERS

                                                                           &create_sql_query_events_from_range_year_month
                                                                           &create_sql_query_from_range_SLA_window
                                                                           &get_sql_startDate_sqlEndDate_numberOfDays_test) ] );

  @ASNMTAP::Asnmtap::Applications::CGI::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Applications::CGI::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Applications::CGI::VERSION     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub user_session_and_access_control;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub do_action_DBI;
sub error_trap_DBI;
sub check_record_exist;
sub create_sql_query_events_from_range_year_month;
sub create_sql_query_from_range_SLA_window;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub get_title;
sub get_sql_crontab_scheduling_report_data;
sub get_sql_startDate_sqlEndDate_numberOfDays_test;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub create_combobox_from_keys_and_values_pairs;
sub create_combobox_from_DBI;
sub create_combobox_multiple_from_DBI;

sub record_navigation_table;
sub record_navigation_bar;
sub record_navigation_bar_alpha;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs without TAGS  = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Common variables  = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub user_session_and_access_control {
  my ($sessionControl, $level, $cgi, $pagedir, $pageset, $debug, $htmlTitle, $subTitle, $queryString) = @_;

  my ($errorUserAccessControl, $sessionID, $userType, $cfhOld, $cfhNew, $password);
  $sessionID = '';

  if (! $sessionControl or ( $ENV{REMOTE_ADDR} eq $REMOTE_ADDR and $ENV{HTTP_HOST} =~ /^${REMOTE_HOST}(:\d+)?/ )) {
    ($cfhOld) = $|; $cfhNew = select (STDOUT); $| = 1;
    print $cgi->header;
    $| = $cfhOld; select ($cfhNew);
    return ("", 0, 0, 0, 0, 1, 1, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle);
    #  --> ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable,
    #       $errorUserAccessControl, $CremoteUser, $CremoteAddr, $CremoteNetmask, $CgivenName, $CfamilyName,
    #       $Cemail, $Cpassword, $CuserType, $Cpagedir, $Cactivated, $CkeyLanguage, $subTitle)
  }

  sub setAccessControlParameters {
    my ($level, $pagedir, $pageset, $debug, $cgi, $session, $sessionID, $subTitle, $queryString) = @_;

    my $logonRequestLogoff = ($cgi->param('logonRequest') or "logon");

    if ( $logonRequestLogoff ne 'logoff' ) {
      if ( $session->param('~logged-in') ) {
        $subTitle .= "&nbsp;&nbsp;<a href=\"" .$ENV{SCRIPT_NAME}. "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;logonRequest=logoff\"><IMG SRC=\"$IMAGESURL/logoff.jpg\" title=\"Logoff " .$session->param('remoteUser'). "\" alt=\"Logoff " .$session->param('remoteUser'). "\" BORDER=0></a>";
      } else {
        $session->param('remoteUser', $ENV{REMOTE_USER}) if ($ENV{REMOTE_USER});
      }
    } else {
      if ( $debug eq 'T' and defined $queryString ) {
        # standard code to parse HTTP query parameters
        my %query = map { my($k, $v) = split(/=/) } split(/&/, $queryString);
        while (my ($key, $value) = each(%query)) { print "$key=$value<br>\n"; }
      }
    }

    return ($subTitle);
  }

  if ( $level eq 'guest' or $level eq 'member' ) {
    $sessionID = $cgi->cookie('asnmtap-root-cgisess') || $cgi->param("CGISESSID") || undef;
  } else {
    $sessionID = $cgi->param("CGISESSID") || undef;
  }

  use CGI::Session;
  my $session = CGI::Session->new ('driver:File;serializer:Default;id:MD5', $sessionID, {Directory=>"$CGISESSPATH"});
  $sessionID = $session->id();

  if ( $level eq 'guest' or $level eq 'member' ) {
    my $cookieID = ( defined $sessionID ) ? $sessionID : '1';
    my $domain = ( ( $ENV{REMOTE_ADDR} eq $REMOTE_ADDR and $ENV{HTTP_HOST} =~ /^${REMOTE_HOST}(:\d+)?/ ) ? $REMOTE_HOST : $HTTPSSERVER );
    my $cgiCookieOutRootCgisess = $cgi->cookie(-name=>'asnmtap-root-cgisess', -value=>"$cookieID", -expires=>'+10h', -path=>"$HTTPSURL/cgi-bin", -domain=>"$domain", -secure=>'0');
    ($cfhOld) = $|; $cfhNew = select (STDOUT); $| = 1;
    print $cgi->header(-cookie=>$cgiCookieOutRootCgisess);
    $| = $cfhOld; select ($cfhNew);
  } else {
    ($cfhOld) = $|; $cfhNew = select (STDOUT); $| = 1;
    print $cgi->header;
    $| = $cfhOld; select ($cfhNew);
  }

  my $logonRequestLogoff = ($cgi->param('logonRequest') or "logon");

  if ( $session->param('~logged-in') and $logonRequestLogoff ne 'logoff' ) {
    my $TuserType = (defined $session->param('userType')) ? $session->param('userType') : 0;
    my $Tpagedir  = (defined $session->param('pagedir'))  ? $session->param('pagedir')  : '<NIHIL>';
    my $accessGranted = 0;

    my ($Rpagedir, undef) = split (/\//, $pagedir, 2);

    if ($level eq 'sadmin') {                   # Server Administrator
      $accessGranted = 1 if ($TuserType == 8);
    } elsif ($level eq 'admin') {               # Administrator
      $accessGranted = 1 if ($TuserType >= 4);
    } elsif ($level eq 'moderator') {           # Moderator
      $accessGranted = 1 if ($TuserType >= 2);
    } elsif ($level eq 'member') {              # Member
      $accessGranted = 1 if ($TuserType >= 1 and $pagedir ne '<NIHIL>' and ($Tpagedir =~ /\/$Rpagedir\//));
    } else {                                    # Guest
      $accessGranted = 1 if ($pagedir ne '<NIHIL>' and ($Tpagedir =~ /\/$Rpagedir\//));
    }

    $subTitle = setAccessControlParameters( $level, $pagedir, $pageset, $debug, $cgi, $session, $sessionID, $subTitle, $queryString );
    return ($sessionID, $session->param('iconAdd'), $session->param('iconDelete'), $session->param('iconDetails'), $session->param('iconEdit'), $session->param('iconQuery'), $session->param('iconTable'), $errorUserAccessControl, $session->param('remoteUser'), $session->param('remoteAddr'), $session->param('remoteNetmask'), $session->param('givenName'), $session->param('familyName'), $session->param('email'), $session->param('password'), $session->param('userType'), $session->param('pagedir'), $session->param('activated'), $session->param('keyLanguage'), $subTitle) if ($accessGranted);

    print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
    $errorUserAccessControl = "You don\'t have enough permissions!";
    print "<br>\n<table WIDTH=\"100%\" border=0><tr><td class=\"HelpPluginFilename\">\n<font size=\"+1\">$errorUserAccessControl</font>\n</td></tr></table>\n<br>\n";
    return ("", 0, 0, 0, 0, 1, 1, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle);
  }

  $session->param('~logged-in', 0);
  $session->param('ASNMTAP', 'LEXY');
  $session->param('iconAdd',      0);
  $session->param('iconDelete',   0);
  $session->param('iconDetails',  0);
  $session->param('iconEdit',     0);
  $session->param('iconQuery',    1);
  $session->param('iconTable',    1);

  if ($level eq 'sadmin') {                     # Server Administrator
    $session->expire('+15m');                   # expire after 15 minutes
    $userType = 8;
  } elsif ($level eq 'admin') {                 # Administrator
    $session->expire('+30m');                   # expire after 30 minutes
    $userType = 4;
  } elsif ($level eq 'moderator') {             # Moderator
    $session->expire('+1h');                    # expire after 1 hour
    $userType = 2;
  } elsif ($level eq 'member') {                # Member
    $session->expire('+10h');                   # expire after 10 hours
    $userType = 1;
  } else {                                      # Guest
    $session->expire('+10h');                   # expire after 10 hours
    $userType = 0;
  }

  my $logonRequest = ($cgi->param('logonRequest') or "logonView");
  
  if( $logonRequest eq "logonView" or $logonRequest eq "logonCheck" ) {
    my $logonPassword  = ($cgi->param('logonPassword')     or undef);
    my $logonTimestamp = ($cgi->param('logonTimestamp')    or undef);
    my $loginTrials    = ($session->param('~login-trials') or 0);

    if ( $loginTrials >= 3 ) {
      $errorUserAccessControl = "You failed 3 times in a row.<br>Your session is blocked.<br>Please contact us with the details of your action";
    } elsif( $logonRequest eq "logonCheck" ) {
      my ($CremoteUser, $CremoteAddr, $CremoteNetmask, $CgivenName, $CfamilyName, $Cemail, $Cpassword, $CuserType, $Cpagedir, $Cactivated, $CkeyLanguage);
      $CremoteUser = ($cgi->param('remoteUser') or undef);
      $session->param('remoteUser', $CremoteUser) if (defined $CremoteUser);
      $CuserType = 0;

      if (defined $CremoteUser and defined $logonPassword and defined $logonTimestamp) {
        my $rv = 1;

        if (defined $CremoteUser) {
          my ($dbh, $sth, $sql);
          $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, 'Logon', 3600, '', $sessionID);

          if ($dbh and $rv) {
            $sql = "select remoteAddr, remoteNetmask, givenName, familyName, email, password, userType, pagedir, activated, keyLanguage from $SERVERTABLUSERS where catalogID = '$CATALOGID' and remoteUser = '$CremoteUser'";
            $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, 'Logon', 3600, '', $sessionID);
            $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, 'Logon', 3600, '', $sessionID) if $rv;

            if ( $rv ) {
              if ($sth->rows) {
                ($CremoteAddr, $CremoteNetmask, $CgivenName, $CfamilyName, $Cemail, $Cpassword, $CuserType, $Cpagedir, $Cactivated, $CkeyLanguage) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, 'Logon', 3600, '', $sessionID);

                if ( $rv ) {
                  $errorUserAccessControl = "Remote User '$CremoteUser' not yet activated." if ($Cactivated != 1);
                } else {
                  $errorUserAccessControl = "Problems with retreiving data from the MySQL database.";
                }
              } else {
                $errorUserAccessControl = "Remote User '$CremoteUser' invalid.";
              }

              $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, 'Logon', 3600, '', $sessionID) if $rv;
            } else {
              $errorUserAccessControl = "Problems with a MySQL database statement.";
            }
          } else {
            $errorUserAccessControl = "Problems with the MySQL database.";
	      }
        } else {
          $errorUserAccessControl = "Remote User missing.";
        }

        my $currentTime = time();
		
        if (defined $errorUserAccessControl) {
          $errorUserAccessControl .= "<br>Please contact us with the details of your action.";

          unless ( $rv ) {
            print "<br>\n<table WIDTH=\"100%\" border=0><tr><td class=\"HelpPluginFilename\">\n<font size=\"+1\">$errorUserAccessControl</font>\n</td></tr></table>\n<br>\n";
            return ("", 0, 0, 0, 0, 1, 1, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle);
          }
        } elsif ( $Cpassword ne $logonPassword ) {
          $errorUserAccessControl = "Bad password";
        } elsif( $logonTimestamp > $currentTime or $logonTimestamp < ($currentTime - 300) ) {
          $errorUserAccessControl = "Time stamp invalid";
        } else {
          if ( $ENV{REMOTE_ADDR} ) {
            if ( $CremoteAddr ne '' ) {
              use NetAddr::IP;
              my $netmask = (int($CremoteNetmask) or 32);
              my $ipAddr  = NetAddr::IP->new($ENV{REMOTE_ADDR});
              my $ipRange = NetAddr::IP->new("$CremoteAddr/$netmask");
              $errorUserAccessControl = "IP Address Forbidden." unless ( $ipRange->contains ( $ipAddr ) );
            }
          }

          $errorUserAccessControl = "You don't have enough permissions!" if ( $userType > int($CuserType) );

		  unless ( defined $errorUserAccessControl ) {
            my $accessGranted = 0;

            my ($Rpagedir, undef) = split (/\//, $pagedir, 2);

            if ($level eq 'sadmin') {                   # Server Administrator
              $accessGranted = 1 if ($CuserType == 8);
            } elsif ($level eq 'admin') {               # Administrator
              $accessGranted = 1 if ($CuserType >= 4);
            } elsif ($level eq 'moderator') {           # Moderator
              $accessGranted = 1 if ($CuserType >= 2);
            } elsif ($level eq 'member') {              # Member
              $accessGranted = 1 if ($CuserType >= 1 and $pagedir ne '<NIHIL>' and ($Cpagedir =~ /\/$Rpagedir\//));
            } else {                                    # Guest
              $accessGranted = 1 if ($pagedir ne '<NIHIL>' and ($Cpagedir =~ /\/$Rpagedir\//));
            }

            $errorUserAccessControl = "You are onto the wrong place to be!" unless ( $accessGranted );

  		    unless ( defined $errorUserAccessControl ) {
              $session->param('~logged-in',   1);
              $session->clear(['~login-trials']);

              if ( $CuserType eq "8" ) {      # Server Administrator
                $session->param('iconAdd',      1);
                $session->param('iconDelete',   1);
                $session->param('iconEdit',     1);
                $session->param('iconDetails',  1);
              } elsif ( $CuserType eq "4" ) { # Administrator
                $session->param('iconAdd',      1);
                $session->param('iconEdit',     1);
                $session->param('iconDetails',  1);
              } elsif ( $CuserType eq "2" ) { # Moderator
                $session->param('iconEdit',     1);
                $session->param('iconDetails',  1);
              } elsif ( $CuserType eq "1" ) { # Member
                $session->param('iconDetails',  1);
              } elsif ( $CuserType ne "0" ) { # Guest
                $errorUserAccessControl = "You are onto the wrong place to be!";
              }

              $session->param('iconQuery',    1);
              $session->param('iconTable',    1);

              $session->param('remoteUser',    $CremoteUser);
              $session->param('remoteAddr',    $CremoteAddr);
              $session->param('remoteNetmask', $CremoteNetmask);
              $session->param('givenName',     $CgivenName);
              $session->param('familyName',    $CfamilyName);
              $session->param('email',         $Cemail);
              $session->param('keyLanguage',   $CkeyLanguage);
              $session->param('password',      $Cpassword);
              $session->param('userType',      $CuserType);
              $session->param('pagedir',       $Cpagedir);
              $session->param('activated',     $Cactivated);
            }
          }
        }

        $password = $Cpassword;
      } else {
        $errorUserAccessControl = "Remote User, Password and/or Time stamp are missing";
      }
    }

    if (defined $errorUserAccessControl) {
      $logonRequest = "logonView";
      my $trials = $session->param('~login-trials') || 0;
      $session->param('~login-trials', ++$trials);

      if ( $debug eq 'T' and defined $queryString ) {
        my %query = map { my($k, $v) = split(/=/) } split(/&/, $queryString);
        while (my ($key, $value) = each(%query)) { print "$key=$value<br>\n"; }
        print "&lt;$password&gt; " if (defined $password);
        print "&lt;$logonPassword&gt;<br>\n";
      }
    }

    if( $logonRequest eq "logonView" ) {
      $logonTimestamp = time();
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, 'Logon', 3600, '', 'F', "<script language=\"JavaScript1.2\" type=\"text/javascript\" src=\"$HTTPSURL/md5.js\"></script>", $sessionID);
      print "<br>\n<table WIDTH=\"100%\" border=0><tr><td class=\"HelpPluginFilename\">\n<font size=\"+1\">$errorUserAccessControl</font>\n</td></tr></table>\n<br>\n" if ( defined $errorUserAccessControl );

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function validateForm() {
  // The password must contain at least 1 number, at least 1 lower case letter, and at least 1 upper case letter.
  var objectRegularExpressionPasswordFormat = /\^[\\w|\\W]*(?=[\\w|\\W]*\\d)(?=[\\w|\\W]*[a-z])(?=[\\w|\\W]\*[A-Z])[\\w|\\W]*\$/;

  if ( document.usac.remoteUser.value == null || document.usac.remoteUser.value == '' ) {
    document.usac.remoteUser.focus();
    alert('Please enter a remote user!');
    return false;
  }

  if ( document.usac.logonPassword.value == null || document.usac.logonPassword.value == '' ) {
    document.usac.logonPassword.focus();
    alert('Please enter a password!');
    return false;
  } else {
    if ( ! objectRegularExpressionPasswordFormat.test(document.usac.logonPassword.value) ) {
      document.usac.logonPassword.focus();
      alert('Please re-enter password: Bad password format!');
      return false;
    }

    document.usac.logonPassword.value = hex_md5(document.usac.logonPassword.value);
  }

  return true;
}
</script>
<br>
<form action="$ENV{SCRIPT_NAME}" method="post" name="usac" onSubmit="return validateForm();">
  <input type="hidden" name="pagedir"        value="$pagedir">
  <input type="hidden" name="pageset"        value="$pageset">
  <input type="hidden" name="debug"          value="$debug">
  <input type="hidden" name="CGISESSID"      value="$sessionID">
  <input type="hidden" name="logonRequest"   value="logonCheck">
  <input type="hidden" name="logonTimestamp" value="$logonTimestamp">
HTML

      if ( defined $queryString ) {
        my %query = map { my($k, $v) = split(/=/) } split(/&/, $queryString);
        while (my ($key, $value) = each(%query)) { print "<input type=\"hidden\" name=\"$key\" value=\"$value\">\n"; }
      }

      print <<HTML;
  <table border="0" cellspacing="0" cellpadding="0">
    <tr><td><b>Remote User: </b></td><td>
      <input type="text" name="remoteUser" value="" size="15" maxlength="15">
    </td></tr><tr><td><b>Password: </b></td><td>
      <input type="password" name="logonPassword" value="" size="15" maxlength="32">&nbsp;&nbsp;The password must contain at least 1 number, at least 1 lower case letter, and at least 1 upper case letter.
    </td></tr><tr align="left"><td align="right"><br><input type="submit" value="Logon"></td><td><br><input type="reset" value="Reset"></td></tr>
  </table>
</form>
<br>
HTML

      $errorUserAccessControl = $logonRequest;
    }
  } elsif( $logonRequest eq "logoff" ) {
    print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, "Logoff", 3600, '', 'F', '', $sessionID);
    $errorUserAccessControl = "Logged off remote user: " .$session->param('givenName'). " " .$session->param('familyName');
    print "<br>\n<h1 align=\"center\">$errorUserAccessControl</h1>\n";
    $session->delete();
    return ("", 0, 0, 0, 0, 1, 1, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle);
  }

  $subTitle = setAccessControlParameters( $level, $pagedir, $pageset, $debug, $cgi, $session, $sessionID, $subTitle, $queryString );
  return ($sessionID, $session->param('iconAdd'), $session->param('iconDelete'), $session->param('iconDetails'), $session->param('iconEdit'), $session->param('iconQuery'), $session->param('iconTable'), $errorUserAccessControl, $session->param('remoteUser'), $session->param('remoteAddr'), $session->param('remoteNetmask'), $session->param('givenName'), $session->param('familyName'), $session->param('email'), $session->param('password'), $session->param('userType'), $session->param('pagedir'), $session->param('activated'), $session->param('keyLanguage'), $subTitle);
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub do_action_DBI {
  my ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug) = @_;

  my $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
  my $numberRecordsIntoQuery = ($rv) ? $sth->fetchrow_array() : 0;
  $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

  return ($rv, $numberRecordsIntoQuery);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub error_trap_DBI {
  my ($HTML, $error_message, $debug, $pagedir, $pageset, $htmlTitle, $subTitle, $refresh, $onload, $sessionID) = @_;

  my $subject = "$htmlTitle / error_trap_DBI: " . get_datetimeSignal();
  my $message = get_datetimeSignal() . "\npagedir   : $pagedir\npageset   : $pageset\nhtml title: $htmlTitle\n\nerror message:\n$error_message\n\n--> ERROR: $DBI::err ($DBI::errstr)\n";
  my $returnCode = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $message, $debug );
  print "Problem sending email to the '$APPLICATION' server administrators\n" unless ( $returnCode );

  if ( $refresh == 0 ) {
    return (0, $error_message, "DBI Error: $DBI::err", "DBI String: $DBI::errstr");
  } elsif ( $refresh == -1 ) {
    print "<H1>DBI Error:</H1>\n", $error_message, "\n<br><br>ERROR: $DBI::err ($DBI::errstr)\n<BR>";
    return 0;
  } else {
    print_header ($HTML, $pagedir, $pageset, $htmlTitle, $subTitle, $refresh, $onload, 'F', '', $sessionID);
    print "<H1>DBI Error:</H1>\n", $error_message, "\n<br><br>ERROR: $DBI::err ($DBI::errstr)\n<BR>";
    return 0;
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub check_record_exist {
  my ($rv, $dbh, $sql, $titleTXT, $keyTXT, $nameTXT, $matchingRecords, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug) = @_;

  my ($key, $title);
  my $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
  $sth->bind_columns( \$key, \$title ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

  if ( $rv ) {
    if ( $sth->rows ) {
      $matchingRecords .= "<h1>$titleTXT:</h1><table><tr><th>$keyTXT</th><th>$nameTXT</th></tr>";
      while( $sth->fetch() ) { $matchingRecords .= "<tr><td>" .encode_html_entities('K', $key). "</td><td>" .encode_html_entities('T', $title). "</td></tr>"; }
      $matchingRecords .= "</table>\n";
    }

    $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  }

  return ($rv, $matchingRecords);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub create_sql_query_events_from_range_year_month {
  my ($inputType, $startDate, $endDate, $sqlSelect, $sqlForce, $sqlWhere, $sqlPeriode, $sqlQuery, $sqlGroup, $sqlOrder, $sqlOrderUnion, $sqlUnionKeyword) = @_;

  $sqlUnionKeyword = 'ALL' if ($sqlUnionKeyword ne 'ALL' or $sqlUnionKeyword ne 'DISTINCT');

  my ($yearFrom,  $monthFrom,  $dayFrom) = split (/-/, $startDate);
  my ($yearTo,    $monthTo,    $dayTo)   = split (/-/, $endDate);

  use Date::Calc qw(Add_Delta_Days Delta_Days);
  my $deltaDays = Delta_Days ($yearFrom, $monthFrom, $dayFrom, $yearTo, $monthTo, $dayTo);

  my ($sql, $sqlUnion);

  if ( $deltaDays >=0 ) {
    my $sqlCommon = "$sqlSelect FROM `$SERVERTABLEVENTS` $sqlForce $sqlWhere $sqlPeriode $sqlQuery $sqlGroup $sqlOrder";

    if ( $SERVERMYSQLMERGE eq '1' ) {
      if ($inputType eq "year" and $yearFrom = $yearTo) {
        $sqlUnion = "union $sqlUnionKeyword ($sqlSelect FROM `". $SERVERTABLEVENTS. "_". sprintf ("%04d", $yearFrom) ."` $sqlForce $sqlWhere $sqlPeriode $sqlQuery $sqlGroup $sqlOrder)";
      } elsif ($inputType eq "quarter" and $monthFrom = $monthTo) {
        $sqlUnion = "union $sqlUnionKeyword ($sqlSelect FROM `". $SERVERTABLEVENTS. "_". sprintf ("%04d", $yearFrom) ."_Q". (int(($monthFrom+2)/3)) ."` $sqlForce $sqlWhere $sqlPeriode $sqlQuery $sqlGroup $sqlOrder)";
      }
    }

    unless (defined $sqlUnion) {
      foreach my $year ($yearFrom..$yearTo) {
        my $monthF = ($year == $yearFrom) ? $monthFrom : 1;
        my $monthT = ($year == $yearTo or $yearFrom == $yearTo) ? $monthTo : 12;

        foreach my $month ($monthF..$monthT) {
          my $yearTable  = sprintf ("%04d", $year);
          my $monthTable = sprintf ("%02d", $month);
          $sqlUnion .= " union $sqlUnionKeyword ($sqlSelect FROM `". $SERVERTABLEVENTS. "_". $yearTable ."_". $monthTable ."` $sqlForce $sqlWhere $sqlPeriode $sqlQuery $sqlGroup $sqlOrder)";
        }
      }
    }

    if (defined $sqlUnion) {
      $sql = "($sqlCommon) $sqlUnion $sqlOrderUnion";
    } else {
      $sql = $sqlCommon;
    }
  }
 
  return $sql;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub create_sql_query_from_range_SLA_window {
  my (@days) = @_; # @_ => ($sunday, $monday, $tuesday, $wednesday, $thursday, $friday, $saturday)

  my ($day, $windowSLA) = (0);

  foreach my $periode (@days) {
    $day++;

    if ( defined $periode and $periode and $periode !~ /00:00-24:00/ ) {
      my @range = split (/,/, $periode);
      my $windowToday;

      foreach my $range (@range) {
        my ($from, $to) = split (/-/, $range);

        if ( defined $from and defined $to ) {
          $windowToday .= ' or ' if ( defined $windowToday );
          $windowToday .= "startTime BETWEEN '$from:00' and '$to:00'";
        }
      }

      if ( defined $windowToday ) {
        $windowSLA .= ' or ' if ( defined $windowSLA );
        $windowSLA .= '( DAYOFWEEK(startDate) = '. $day .' and ( '. $windowToday .' ) )'
      }
    }
  }

  return ( defined $windowSLA ? ' and ( '. $windowSLA .' )' : '' );
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub get_title {
  my ($dbh, $rv, $catalogID, $uKey, $debug, $refresh, $sessionID) = @_;

  my ($sql, $sth, $errorMessage, $dbiErrorCode, $dbiErrorString, $title, $environment, $trendline, $step, $applicationTitle, $trendValue, $stepValue);
  $sql = "select concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ), $SERVERTABLPLUGINS.environment, trendline, step from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT WHERE catalogID = '$catalogID' and uKey = '$uKey' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment";
  $sth = $dbh->prepare( $sql ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot dbh->prepare: $sql", $debug, '', "", '', "", $refresh, '', $sessionID);
  $sth->execute() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->execute: $sql", $debug, '', "", '', "", $refresh, '', $sessionID) if $rv;
  $sth->bind_columns( \$title, \$environment, \$trendline, \$step ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->bind_columns: $sql", $debug, '', "", '', "", $refresh, '', $sessionID) if $rv;

  if ( $rv ) {
    while( $sth->fetch() ) {
      $title =~ s/^[\[[\S+|\s+]*\]\s+]{0,1}([\S+|\s+]*)/$1/g;
      $applicationTitle = $title;
      $trendValue = $trendline;
      $stepValue = $step;
    }

    $sth->finish() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", $refresh, '', $sessionID);
  }

  if ( $refresh == 0 ) {
    return ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString, $applicationTitle, $trendValue, $stepValue);
  } elsif ( $refresh == -1 ) {
    return ($rv, $applicationTitle);
  } else {
    return ($rv, $applicationTitle, $trendValue);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_sql_crontab_scheduling_report_data {
  my ($dbh, $sql, $rv, $errorMessage, $dbiErrorCode, $dbiErrorString, $sessionID, $hight, $hightMin, $uKeys, $labels, $stepValue, $catalogID, $uKeysSqlWhere, $debug) = @_;

  my ($collectorDaemon, $uKey, $lineNumber, $minute, $hour, $dayOfTheMonth, $monthOfTheYear, $dayOfTheWeek, $noOffline, $applicationTitle, $step);
  my $sth = $dbh->prepare( $sql ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot dbh->prepare: $sql", $debug, '', "", '', "", 0, '', $sessionID);
  $sth->execute() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->execute: $sql", $debug, '', "", '', "", 0, '', $sessionID) if $rv;
  $sth->bind_columns( \$collectorDaemon, \$uKey, \$lineNumber, \$minute, \$hour, \$dayOfTheMonth, \$monthOfTheYear, \$dayOfTheWeek, \$noOffline ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->bind_columns: $sql", $debug, '', "", '', "", 0, '', $sessionID) if $rv;

  my $numberOfLabels = 0;

  if ( $rv ) {
    if ( $sth->rows ) {
      while( $sth->fetch() ) {
        if (exists $$uKeys{$uKey}) {
          $$uKeys{$uKey}->{collectorDaemon} .= '|' .$collectorDaemon if ($collectorDaemon ne $$uKeys{$uKey}->{collectorDaemon});
          $$uKeys{$uKey}->{noOffline}       .= '|' .$noOffline if ($noOffline ne $$uKeys{$uKey}->{noOffline});
        } else {
          $$uKeys{$uKey}->{collectorDaemon}  = $collectorDaemon;
          $$uKeys{$uKey}->{noOffline}        = $noOffline;
          $$uKeys{$uKey}->{numberOfLabel}    = $numberOfLabels;

          if (defined $$uKeysSqlWhere) { $$uKeysSqlWhere .= (($$uKeysSqlWhere) ? ' OR ' : '') . "$SERVERTABLEVENTS.uKey = '$uKey'"; }

         ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString, $applicationTitle, undef, $step) = get_title( $dbh, $rv, $catalogID, $uKey, $debug, 0, $sessionID );

          if ($rv) {
            @$labels[$numberOfLabels] = $applicationTitle;
            @$stepValue[$numberOfLabels] = $step;
          }

          $numberOfLabels++;
        }

        $$uKeys{$uKey}->{lineNumbers}->{$lineNumber} = { minute => $minute, hour => $hour, dayOfTheMonth => $dayOfTheMonth, monthOfTheYear => $monthOfTheYear, dayOfTheWeek => $dayOfTheWeek };
      }
    } else {
      $hight = $hightMin; $rv = 0; $errorMessage = "There are no Crontabs available";
    }

    $sth->finish() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", 0, '', $sessionID);
  }

  return ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString, $hight, $numberOfLabels);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_sql_startDate_sqlEndDate_numberOfDays_test {
  my ($strictDate, $firstStartDate, $inputType, $selYear, $selQuarter, $selMonth, $selWeek, $selStartDate, $selEndDate, $currentYear, $currentMonth, $currentDay, $debug) = @_;

  use Date::Calc qw(Add_Delta_Days check_date Days_in_Month Delta_Days Monday_of_Week Week_of_Year);

  my ($startDate, $endDate, $goodDate);

  if ($inputType eq "fromto") {
    if (defined $selEndDate and $selEndDate ne '') {
      $startDate = $selStartDate;
      $endDate   = $selEndDate;
    } else {
      $startDate = $selStartDate;
      $endDate   = $selStartDate;
    }
  } elsif ($inputType eq "year") {
    $startDate = "$selYear-1-1";
    $endDate   = "$selYear-12-31";
  } elsif ($inputType eq "quarter") {
    my $fromQuarterMonth = $QUARTERS{ $selQuarter };
    my $toQuarterMonth = $fromQuarterMonth + 2;
    my $toQuarterNumberOfDays = Days_in_Month($selYear, $toQuarterMonth);
    $startDate = "$selYear-$fromQuarterMonth-1";
    $endDate   = "$selYear-$toQuarterMonth-$toQuarterNumberOfDays";
  } elsif ($inputType eq "month") {
    my $daysInMonth = Days_in_Month($selYear, $selMonth);
    $startDate = "$selYear-$selMonth-1";
    $endDate   = "$selYear-$selMonth-$daysInMonth";
  } elsif ($inputType eq "week") {
    my ($yearFrom, $monthFrom, $dayFrom) = Monday_of_Week( $selWeek, $selYear );
    my ($yearTo, $monthTo, $dayTo) = Add_Delta_Days ( $yearFrom, $monthFrom, $dayFrom, 6 );
    $startDate = "$yearFrom-$monthFrom-$dayFrom";
    $endDate   = "$yearTo-$monthTo-$dayTo";
  } else {
    return (0, undef, undef, undef);
  }

  my ($fromYear, $fromMonth, $fromDay) = split (/-/, $startDate);
  $fromYear  = 0 if (! defined $fromYear or $fromYear !~ /^[0-9]+$/);
  $fromMonth = 0 if (! defined $fromMonth or $fromMonth !~ /^[0-9]+$/);
  $fromDay   = 0 if (! defined $fromDay or $fromDay !~ /^[0-9]+$/);

  my ($toYear, $toMonth, $toDay) = split (/-/, $endDate);
  $toYear    = 0 if (! defined $toYear or $toYear !~ /^[0-9]+$/);
  $toMonth   = 0 if (! defined $toMonth or $toMonth !~ /^[0-9]+$/);
  $toDay     = 0 if (! defined $toDay or $toDay !~ /^[0-9]+$/);

  return (0, undef, undef, undef) unless ( check_date ( $fromYear, $fromMonth, $fromDay) and check_date($toYear, $toMonth, $toDay ) );

  my $switchDate = Delta_Days($fromYear, $fromMonth, $fromDay, $toYear, $toMonth, $toDay);

  if ($switchDate < 0) {
    ($startDate, $endDate) = ($endDate, $startDate) ;
    ($fromYear, $fromMonth, $fromDay) = split (/-/, $startDate);
    ($toYear, $toMonth, $toDay) = split (/-/, $endDate);
  }

  my ($firstYear, $firstMonth, $firstDay) = split (/-/, $firstStartDate);
  $switchDate = Delta_Days($firstYear, $firstMonth, $firstDay, $fromYear, $fromMonth, $fromDay);

  if ($switchDate < 0) {
    $startDate = $firstStartDate;
    ($fromYear, $fromMonth, $fromDay) = split (/-/, $firstStartDate);
  }

  my $firstDeltaDays = Delta_Days($fromYear, $fromMonth, $fromDay, $toYear, $toMonth, $toDay);

  if ($firstDeltaDays < 0) {
    $goodDate = 0;
    print "-) $inputType, $selYear, $selQuarter, $selMonth, $selWeek, $selStartDate, $selEndDate, $startDate, $endDate, <- $firstStartDate, $goodDate\n" if ( $debug eq 'T' );
    return (0, $firstStartDate, $firstStartDate, 0);
  }
  
  my $fromDeltaDays = Delta_Days($fromYear, $fromMonth, $fromDay, $currentYear, $currentMonth, $currentDay);
  my $sqlStartDate = ($fromDeltaDays >= 0) ? $startDate : "$currentYear-$currentMonth-$currentDay";
  my ($yearFrom, $monthFrom, $dayFrom) = split(/-/, $sqlStartDate);

  my $toDeltaDays = Delta_Days($toYear, $toMonth, $toDay, $currentYear, $currentMonth, $currentDay);
  my $sqlEndDate = ($toDeltaDays >= 0) ? $endDate : "$currentYear-$currentMonth-$currentDay";
  my ($yearTo, $monthTo, $dayTo) = split(/-/, $sqlEndDate);

  my $numberOfDays = Delta_Days($yearFrom, $monthFrom, $dayFrom, $yearTo, $monthTo, $dayTo) + 1;
  my $sqlDeltaDays = Delta_Days($toYear, $toMonth, $toDay, $yearTo, $monthTo, $dayTo);

  if ($sqlDeltaDays == 0) {
    print "A) " if ( $debug eq 'T' );
    $goodDate = 1;
  } elsif ($strictDate) {
    print "B) " if ( $debug eq 'T' );
    $goodDate = 0;
  } elsif ($inputType eq "fromto") {
    print "C) " if ( $debug eq 'T' );
    $goodDate = ($sqlStartDate eq $sqlEndDate and $endDate ne $sqlEndDate ) ? 0 : 1;
  } elsif ($inputType eq "year" and $toYear == $yearTo) {
    print "D) " if ( $debug eq 'T' );
    $goodDate = 1;
  } elsif ($fromYear > $yearTo) { # or $toYear > $yearTo
    print "E) " if ( $debug eq 'T' );
    $goodDate = 0;
  } elsif ($inputType eq "quarter") {
    print "F) " if ( $debug eq 'T' );
    my $fromDays = Days_in_Month($fromYear, $fromMonth);
    my $daysFrom = Days_in_Month($yearFrom, $monthFrom);
    $goodDate = ($fromMonth != $monthFrom) ? 0 : 1;
  } elsif ($inputType eq "month") {
    print "G) " if ( $debug eq 'T' );
    $goodDate = ($toMonth > $monthTo) ? 0 : 1;
  } elsif ($inputType eq "week") {
    print "H) " if ( $debug eq 'T' );
    my ($toWeek, $toYear) = Week_of_Year( $toYear, $toMonth, $toDay );
    my ($weekTo, $yearTo) = Week_of_Year( $yearTo, $monthTo, $dayTo );
    $goodDate = ($toYear != $yearTo or $toWeek > $weekTo) ? 0 : 1;
  } else {
    print "I) " if ( $debug eq 'T' );
    $goodDate = 0;
  }

  print "$inputType, $selYear, $selQuarter, $selMonth, $selWeek, $selStartDate, $selEndDate, $startDate, $endDate, $sqlStartDate, $sqlEndDate, $fromDeltaDays, $toDeltaDays, $numberOfDays, $sqlDeltaDays, $goodDate\n" if ( $debug eq 'T' );
  return ($goodDate, $sqlStartDate, $sqlEndDate, $numberOfDays);
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub create_combobox_from_keys_and_values_pairs {
  my ($comboboxSelectKeysAndValuesPairs, $sortOn, $sortNumeric, $Ckey, $selectName, $selectValue, $selectLabel, $formDisabled, $onChange, $debug) = @_;

  my %comboSelectKeysAndValuesPairs = map { my ($key, $value) = split (/=>/) } split (/\|/, $comboboxSelectKeysAndValuesPairs);

  my $comboSelect  = "<select name=\"$selectName\" $formDisabled $onChange>\n";

  if ($selectLabel ne '') {
    $comboSelect .= "          <option value=\"$selectValue\"";
    $comboSelect .= " selected" if ($Ckey eq $selectValue);
    $comboSelect .= ">$selectLabel</option>\n";
  }

  if ($sortOn eq 'K') {
    foreach my $key ( sort keys ( %comboSelectKeysAndValuesPairs ) ) {
      my $value = $comboSelectKeysAndValuesPairs{$key};
      $comboSelect .= "          <option value=\"$key\"";
      $comboSelect .= " selected" if ($Ckey eq $key);
      $comboSelect .= ">$value</option>\n";
    }
  } elsif ($sortOn eq 'V') {
    if ($sortNumeric) {
      foreach my $key ( sort { $comboSelectKeysAndValuesPairs{$a} <=> $comboSelectKeysAndValuesPairs{$b}; } keys ( %comboSelectKeysAndValuesPairs ) ) {
        my $value = $comboSelectKeysAndValuesPairs{$key};
        $comboSelect .= "          <option value=\"$key\"";
        $comboSelect .= " selected" if ($Ckey eq $key);
        $comboSelect .= ">$value</option>\n";
      }
    } else {
      foreach my $key ( sort { $comboSelectKeysAndValuesPairs{$a} cmp $comboSelectKeysAndValuesPairs{$b}; } keys ( %comboSelectKeysAndValuesPairs ) ) {
        my $value = $comboSelectKeysAndValuesPairs{$key};
        $comboSelect .= "          <option value=\"$key\"";
        $comboSelect .= " selected" if ($Ckey eq $key);
        $comboSelect .= ">$value</option>\n";
      }
    }
  } else {
    foreach my $key ( keys ( %comboSelectKeysAndValuesPairs ) ) {
      my $value = $comboSelectKeysAndValuesPairs{$key};
      $comboSelect .= "          <option value=\"$key\"";
      $comboSelect .= " selected" if ($Ckey eq $key);
      $comboSelect .= ">$value</option>\n";
    }
  }

  $comboSelect .= "        </select>\n";
  return ($comboSelect);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub create_combobox_from_DBI {
  my ($rv, $dbh, $sql, $firstOption, $nextAction, $Ckey, $selectName, $selectValue, $selectLabel, $formDisabled, $onChange, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug) = @_;

  my ($key, $value);

  my $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
  $sth->bind_columns( \$key, \$value) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

  my $comboSelect  = "<select name=\"$selectName\" $formDisabled $onChange>\n";

  if ($selectLabel ne '') {
    if ($firstOption or (! $firstOption and $Ckey eq $selectValue)) {
      $comboSelect .= "          <option value=\"$selectValue\"";
      $comboSelect .= " selected" if ($Ckey eq $selectValue);
      $comboSelect .= ">$selectLabel</option>\n";
    }
  }

  if ( $rv ) {
    while( $sth->fetch() ) {
      $comboSelect .= "          <option value=\"$key\"";

      if ($Ckey eq $key) {
        $htmlTitle = "$value: $nextAction" if ($nextAction ne '');
        $comboSelect .= " selected";
      }

      $comboSelect .= ">$value</option>\n";
    }

    $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  }

  $comboSelect .= "        </select>\n";
  return ($rv, $comboSelect, $htmlTitle);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub create_combobox_multiple_from_DBI {
  my ($rv, $dbh, $sql, $action, $Ckey, $selectName, $selectValue, $selectSize, $textareaCols, $formDisabled, $onChange, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug) = @_;

  my ($key, $value);
  my $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
  $sth->bind_columns( \$key, \$value) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

  my $comboboxSelect = '';

  if ($rv) {
    if ( $sth->rows ) {
      my $comboboxSelectSize = 0;

      if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
        while( $sth->fetch() ) {
          $comboboxSelectSize++;
          $comboboxSelect .= "<option value=\"$key\"";
          $comboboxSelect .= " selected" if ($Ckey =~ /\/$key\//);
          $comboboxSelect .= ">$value</option>";
        }

        $comboboxSelectSize = ($comboboxSelectSize > $selectSize) ? $selectSize : $comboboxSelectSize;
        $comboboxSelect =  "<select name=\"$selectName\" id=\"${selectName}_id\" size=\"$comboboxSelectSize\" multiple $onChange>" .$comboboxSelect. "</select>";
      } else {
        while( $sth->fetch() ) {
          if ($Ckey =~ /\/$key\//) {
            $comboboxSelectSize++;
            $comboboxSelect .= "$value\n" if ($Ckey =~ /\/$key\//);
          }
        }

        $comboboxSelect = "<textarea name=$selectName cols=$textareaCols rows=$comboboxSelectSize $formDisabled>$comboboxSelect</textarea>";
      }
    } else {
      if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
        $comboboxSelect = "<select name=\"$selectName\" size=\"1\" multiple $onChange></select>";
      } else {
        $comboboxSelect = $selectValue;
      }
    }

    $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  }

  return ($rv, $comboboxSelect);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub record_navigation_table {
  my ($rv, $dbh, $sql, $label, $keyLabels, $keyNumbers, $ignoreFieldNumbers, $translationFieldsKeysAndValues, $addAccessParameters, $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug) = @_;

  my $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

  my $matchingRecords = '';

  if ( $rv ) {
    my @keyLabels  = split (/\|/, $keyLabels);
	my @keyNumbers = split (/\|/, $keyNumbers);

    my @translationFieldsKeysAndValues = split (/\|\|/, $translationFieldsKeysAndValues);
    my %translationFieldKeyAndValue = ();

    foreach $translationFieldsKeysAndValues (@translationFieldsKeysAndValues) {
      my ($translationField, $translationKeysAndValues) = split (/#/, $translationFieldsKeysAndValues, 2);

      if (defined $translationField) {
        my @translationKeyValuePairs = split (/\|/, $translationKeysAndValues);

        foreach my $translationKeyValuePairs (@translationKeyValuePairs) {
          my ($key, $value) = split (/=>/, $translationKeyValuePairs);
          $translationFieldKeyAndValue{$translationField}{$key} = $value;
        }
      }
    }

    my $actionPressend = ($iconAdd or $iconDelete or $iconDetails or $iconEdit) ? 1 : 0;
    my $actionHeader = ($actionPressend) ? "<th>Action</th>" : '';
    my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset$addAccessParameters";

    $matchingRecords = "\n      <table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='$COLORSTABLE{TABLE}'>\n	        <tr>$header$actionHeader</tr>\n";
    my $numFields = $sth->{NUM_OF_FIELDS}; my $colspan = $numFields + 1;

    if ( $sth->rows ) {
      while ( my $ref = $sth->fetchrow_arrayref ) {
        my $actionItem = ($actionPressend) ? "<td align=\"left\">&nbsp;" : '';
        my $actionKeys = ''; 
        my $actionSkip = 0;
        my $item       = 0;

        foreach my $keyLabels (@keyLabels) {
          $actionKeys .= "&amp;$keyLabels=$$ref[$keyNumbers[$item]]";
          $actionSkip = 1 if ( $label ne 'Catalog' and $keyLabels eq 'catalogID' and $$ref[$keyNumbers[$item]] ne $CATALOGID );
          $item++;
        }

        my $urlWithAccessParametersAction = "$urlWithAccessParameters$actionKeys&amp;orderBy=$orderBy&amp;action";
        $actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display $label\" alt=\"Display $label\" border=\"0\"></a>&nbsp;" if ($iconDetails);
        $actionItem .= "<a href=\"$urlWithAccessParametersAction=duplicateView\"><img src=\"$IMAGESURL/$ICONSRECORD{duplicate}\" title=\"Duplicate $label\" alt=\"Duplicate $label\" border=\"0\"></a>&nbsp;" if ($iconAdd);

        unless ( $actionSkip ) {
          $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit $label\" alt=\"Edit $label\" border=\"0\"></a>&nbsp;" if ($iconEdit);
          $actionItem .= "<a href=\"$urlWithAccessParametersAction=deleteView\"><img src=\"$IMAGESURL/$ICONSRECORD{delete}\" title=\"Delete $label\" alt=\"Delete $label\" border=\"0\"></a>&nbsp;" if ($iconDelete);
        }

        $actionItem .= "</td>" if ($actionPressend);

        $matchingRecords .= "        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\">";

        for (my $i = 0;  $i < $numFields;  $i++) {
          my $value;

          if ($ignoreFieldNumbers eq '') {
            $value = $$ref[$i];
          } else {
            $value = $$ref[$i] if ("|$ignoreFieldNumbers|" !~ /\|$i\|/);
          }

          if (defined $value) {
            $value = $translationFieldKeyAndValue{$i}{$$ref[$i]} if (defined $translationFieldKeyAndValue{$i}{$$ref[$i]});
            $matchingRecords .= "<td>" .encode_html_entities('T', $value). "</td>";
          }
        }

        $matchingRecords .= "$actionItem</tr>\n";
      }
    } else {
      $matchingRecords .= "        <tr><td colspan=\"$colspan\">No records found.</td></tr>\n";
    }

    $matchingRecords .= "        <tr><td colspan=\"$colspan\">$navigationBar</td></tr>\n" if ($navigationBar);
    $matchingRecords .= "      </table>\n";
    $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
    $nextAction = "listView";
  }

  return ($rv, $matchingRecords, $nextAction);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub record_navigation_bar {
  my ($currentPageNo, $numberRecordsIntoQuery, $showRecordsOnPage, $urlWithAccessParameters) = @_;

  my $navigationBar;

  if ( $numberRecordsIntoQuery > $showRecordsOnPage ) {
    my $numberOffPagesMax = int((($numberRecordsIntoQuery - 1) / $showRecordsOnPage) + 1);
    $currentPageNo = $numberOffPagesMax if ($currentPageNo > $numberOffPagesMax);
    my $wantedRecordFirst = (($currentPageNo - 1)  * $showRecordsOnPage) + 1;
    my $TwantedRecordLast = $wantedRecordFirst + ($showRecordsOnPage - 1);
    my $wantedRecordLast  = ($TwantedRecordLast < $numberRecordsIntoQuery) ? $TwantedRecordLast : $numberRecordsIntoQuery;

    my $numberOffRecords  = (($wantedRecordLast - 1) % $showRecordsOnPage) + 1;

    $navigationBar = "<table border=\"0\" width=\"100%\" bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td align=\"center\" width=\"36\">$currentPageNo/$numberOffPagesMax</td><td align=\"center\">";

    if ($wantedRecordLast > 1) {
      if ($currentPageNo > 1) {
        my $previousPage = $currentPageNo - 1;
        my $previousPageOffset = ($showRecordsOnPage * ($previousPage - 1));
        $navigationBar .= "&nbsp;<a href=\"$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{first}\" ALT=\"First\" BORDER=0></a>&nbsp;<a href=\"$urlWithAccessParameters&pageNo=$previousPage&pageOffset=$previousPageOffset\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{left}\" ALT=\"Left\" BORDER=0></a>&nbsp;&nbsp;<a href=\"$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0\">1</a>";
      } else {
        $navigationBar .= "&nbsp;1";
      }

      for (my $currentPage = 2; $currentPage < $numberOffPagesMax; $currentPage++) {
        if ( $currentPageNo != $currentPage ) {
          my $offsetOffRecords = ($showRecordsOnPage * ($currentPage - 1));
          $navigationBar .= "&nbsp;<a href=\"$urlWithAccessParameters&amp;pageNo=$currentPage&amp;pageOffset=$offsetOffRecords\">$currentPage</a>";
        } else {
          $navigationBar .= "&nbsp;$currentPage";
        }
      }

      if ($currentPageNo < $numberOffPagesMax) {
        my $nextPage = $currentPageNo + 1;
        my $nextPageOffset = ($showRecordsOnPage * ($nextPage - 1));
        my $lastPageOffset = ($showRecordsOnPage * ($numberOffPagesMax - 1));
        $navigationBar .= "&nbsp;<a href=\"$urlWithAccessParameters&amp;pageNo=$numberOffPagesMax&amp;pageOffset=$lastPageOffset\">$numberOffPagesMax</a>&nbsp;&nbsp;<a href=\"$urlWithAccessParameters&amp;pageNo=$nextPage&amp;pageOffset=$nextPageOffset\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{right}\" ALT=\"Right\" BORDER=0></a> <a href=\"$urlWithAccessParameters&amp;pageNo=$numberOffPagesMax&amp;pageOffset=$lastPageOffset\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{last}\" ALT=\"Last\" BORDER=0></a>";
      } else {
        $navigationBar .= "&nbsp;$numberOffPagesMax";
      }
    } else {
      $navigationBar .= "&nbsp;";
    }

    $navigationBar .= "</td></tr></table>\n";
  }

  return ($navigationBar);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub record_navigation_bar_alpha {
  my ($rv, $dbh, $table, $field, $where, $numberRecordsIntoQuery, $showRecordsOnPage, $urlWithAccessParameters, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug) = @_;

  my $navigationBarAlpha = '';

  if ( $numberRecordsIntoQuery > $showRecordsOnPage ) {
    $navigationBarAlpha = "<table border=\"0\" width=\"100%\" bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td align=\"center\">";

    my ($rownumber, $label);

    my $sql = "select DISTINCT \@rownum:=\@rownum+1 AS rownumber, LEFT($table.$field, 1) as AtoZ from (select \@rownum:=0) r, `$table` force index ($field) where $where group by AtoZ order by $field asc";
    my $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
    $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
    $sth->bind_columns( \$rownumber, \$label ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

    if ( $rv ) {
      if ( $sth->rows ) {
        while( $sth->fetch() ) {
          my $currentPage = int ( ( $rownumber / $showRecordsOnPage ) - 0.001 );
          my $offsetOffRecords = $currentPage * $showRecordsOnPage;
          $currentPage++;
          $navigationBarAlpha .= "&nbsp;<a href=\"$urlWithAccessParameters&amp;pageNo=$currentPage&amp;pageOffset=$offsetOffRecords&amp;orderBy=$field asc\">$label</a>";
        }
      }
    }

    $navigationBarAlpha .= "</td></tr></table>\n";
  }

  return ($navigationBarAlpha);
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Applications::CGI is a Perl module that provides a nice object oriented interface for ASNMTAP CGI Applications

=head1 Description

ASNMTAP::Asnmtap::Applications::CGI Subclass of ASNMTAP::Asnmtap::Applications

=head1 SEE ALSO

ASNMTAP::Asnmtap, ASNMTAP::Asnmtap::Applications

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2007 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

ASNMTAP is based on 'Process System daemons v1.60.17-01', Alex Peeters [alex.peeters@citap.be]

 Purpose: CronTab (CT, sysdCT),
          Disk Filesystem monitoring (DF, sysdDF),
          Intrusion Detection for FW-1 (ID, sysdID)
          Process System daemons (PS, sysdPS),
          Reachability of Remote Hosts on a network (RH, sysdRH),
          Rotate Logfiles (system activity files) (RL),
          Remote Socket monitoring (RS, sysdRS),
          System Activity monitoring (SA, sysdSA).

'Process System daemons' is based on 'sysdaemon 1.60' written by Trans-Euro I.T Ltd

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut
