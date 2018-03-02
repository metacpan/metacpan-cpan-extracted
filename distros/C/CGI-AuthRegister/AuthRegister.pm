# <? read_starfish_conf(); &generate_header; !>
#+
# file: AuthRegister.pm
# CGI::AuthRegister - AuthRegister Module for Simple CGI Authentication and Registration in Perl
# (c) 2012-18 Vlado Keselj http://web.cs.dal.ca/~vlado
# $Date: $
# $Id: $
#-

package CGI::AuthRegister;
use strict;
#<? &generate_standard_vars !>
#+
use vars qw($NAME $ABSTRACT $VERSION);
$NAME     = 'AuthRegister';
$ABSTRACT = 'AuthRegister Module for Simple CGI Authentication and Registration in Perl';
$VERSION  = '1.1';
#-
use CGI qw(:standard);
# Useful diagnostics:
# use CGI qw(:standard :Carp -debug);
# use CGI::Carp 'fatalsToBrowser';
# use diagnostics; # verbose error messages
# use strict;      # check for mistakes
use Carp;
require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw($AddAuthenticatedUser $DebugLevel $Error $SessionId
  $SiteId $SiteName $User $UserEmail $UserId $SendLogs $LogReport
  $LDAPuse $LDAPserver $LDAPdn $LDAPaddUsers $LinkForgotpwd
  $GenCasPageCustom
  analyze_cookie header_delete_cookie header_session_cookie
  import_dir_and_config login logout
  require_https require_login run_cas send_email_reminder
  get_user get_user_by_userid set_new_session store_log
 );

use vars qw( $AddAuthenticatedUser
  $DBdir $DBusers $DBpwd $DBsessions $DBusersCas $DBpwdCas
  $DBsessionsCas $DBcasTokens $DebugLevel
  $Email_from $Email_bcc $Error $ErrorInternal
  $GenCasPageCustom $LogReport
  $LDAPuse $LDAPserver $LDAPdn $LDAPaddUsers $LinkForgotpwd
  $Sendmail $Session $SessionId $SiteId $SiteName $Ticket
  $User $UserEmail $UserId $SendLogs $SecretSalt);
$AddAuthenticatedUser = ''; # If user is authenticated and not in database,
      # add user to the database. (it should replace $LDAPaddUsers)!!!
$DBdir      = 'db'; # directory for stored data (822 db, sessions)
$DBusers    = 'users.db';      # Users db
$DBusersCas = 'users-cas.db';  # CAS users db
$DBpwd      = 'passwords';     # Passwords file
$DBpwdCas   = 'passwords-cas'; # CAS passwords
$DBsessions = 'sessions.d';    # Sessions
$DBsessionsCas = 'sessions-cas.d'; # CAS sessions
$DBcasTokens = 'cas-tokens.db'; # CAS Tokens
# $Error = ''; # Appended error messages, OK to be sent to user
# $ErrorInternal = ''; # Appended internal error messages, intended
                       # for administrator
# $LogReport = '';  # Collecting some important log events if needed
$SecretSalt = &random_name; # Secret salt for generating secrets (e.g. tokens)
# $Session   = '';  # Session data structure
# $SessionId = '';  # Session identifier, generated
$SiteId = 'Site';   # Site identifier, used in cookies and emails
$SiteName = 'Site'; # Site name, can include spaces
# $Ticket = '';     # Session ticket for security, generated
# $User      = '';  # User data structure
# $UserEmail = '';  # User email address
# $SendLogs  = '';  # If true, send logs by email to admin ($Email_bcc)

$Email_from = ''; # Example: $SiteId.' <vlado@dnlp.ca>';
$Email_bcc  = ''; # Example: $SiteId.' Bcc <vlado@dnlp.ca>';

$Sendmail = "/usr/lib/sendmail"; # Sendmail with full path

# Some function prototypes
sub putfile($@);

########################################################################
# Section: Configuration
# sets site id as the base directory name; imports configuration.pl if exists
sub import_dir_and_config {
  my $base = `pwd`; $base =~ /\/([^\/]*)$/; $base = $1; $base =~ s/\s+$//;
  $SiteId = $SiteName = $base;
  if (-r 'configuration.pl') { package main; require 'configuration.pl'; }
}

########################################################################
# Section: HTTPS Connection and Cookies Management

# Check that the connection is HTTPS and if not, redirect to HTTPS.
# It must be done before script produces any output.
sub require_https {
  if ($ENV{'HTTPS'} ne 'on') {
      print "Status: 301 Moved Permanently\n".
       "Location: https://$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}\n\n";
      exit 0; }
}

# Used to run a CAS service.  If not logged in, ask for userid and password.
# On success, offer to pass confirmation back to the site; on fail offer retry
# or go back to the site. If site not given, stay.  If previously logged in
# offer to pass confirmation to the site.  Handles ?logout requests.
# Allows parentheses in userid's for login, which are removed.  This allows
# users to use auxiliary comments with userid, so that browser can distinguish
# passwords.
sub run_cas {
  my %params = @_;
  my $querystring = $ENV{QUERY_STRING};
  $DBusers = $DBusersCas; $DBpwd = $DBpwdCas; $DBsessions = $DBsessionsCas;
  &import_dir_and_config; &require_https;
  if ($querystring eq '' && param('querystring')) {
    $querystring=param('querystring') }
  if ($querystring eq 'cas-all.css') { &deliver('cas-all.css') }
  if ($querystring eq 'cas-mobile.css') { &deliver('cas-mobile.css') }

  if (param('rt') ne '' && param('rt') eq 'verify') {
    my $username = param('username'); my $stoken = param('stoken');
    my $r = &_db8_find_first("$DBdir/$DBcasTokens", 'k=stoken', $stoken);
    my $ans = 'fail';
    if ($r ne '' and $r->{stoken} eq $stoken and $r->{userid} eq $username) {
      $ans = 'ok';
      if ($DebugLevel > 5) { $LogReport .= "CAS verification OK for ".
        "username($username) stoken($stoken)"; &store_log; }
    }
    if ($ans ne 'ok') {
      print header(), "answer:fail\n";
      if ($DebugLevel > 5) { $LogReport .= "CAS verify failed for ".
        "username($username) stoken($stoken)"; }
      &store_log; exit(); }
    &_db8_remove("$DBdir/$DBcasTokens", 'k=stoken', $stoken);
    print header(), "answer:ok\n"; exit();
  }
  
  my $redirect_uri;
  if (param('redirect_uri') ne '') { $redirect_uri = param('redirect_uri') }
  elsif (param('r') ne '') { $redirect_uri = param('r') }

  ### Helper functions: finishGeneral, finishWithPageBack

  local *finishGeneral = sub {
    my $page = &gen_cas_page;
    if ($redirect_uri ne '') {
      my $h = "<input type=\"hidden\" name=\"redirect_uri\" ".
	"value=\"$redirect_uri\">";
      $page=~ s/<!--!hiddenfields-->/$h\n$&/;
      my $t = "CAS Authentication requested by the following site:<br>\n".
	"<code>".&htmlquote($redirect_uri)."</code>";
      $page =~ s/(<!--38--)>(.*)/$1>$t/;
    }
    print $page; exit; };
  
  local *finishWithPageBack = sub {
    my $page = &gen_cas_page; my $h = 'Successful Authentication!';
    my $userid = $User->{userid};
    my $t = "You are authenticated with the userid '$userid'.\n";
    if ($redirect_uri ne '') { $t.="Click the button 'Proceed' to ".
      "pass the userid and an authentication code to the site:\n<br>".
      "<code>".&htmlquote($redirect_uri)."</code>"; }
    $page =~ s/(<!--37--)>(.*)/$1>$h/;
    $page =~ s/(<!--38--)>(.*)/$1>$t/;
    $page =~ s/<!--!username-->.*?\n\n/\n/s;
    $page =~ s/<!--!password-->.*?\n\n/\n/s;
    if ($redirect_uri ne '') {
      my $stoken = &gen_secret; $userid=~s/["<>]//g;
      my $f = "$DBdir/$DBcasTokens";
      if (!-f $f && !&check_db_files) { $LogReport.=$Error; &store_log;
	print "<html><body>Error: $Error"; exit; }
      if (!-f $f) { putfile $f, ''; chmod 0600, $f; }
      &_db8_append($f, "userid:$userid\nstoken:$stoken" );
      if ($Error ne '') { $LogReport.=$Error; &store_log;
        print "<html><body>Error: $Error"; exit; }
      my $h = "<input type=\"hidden\" name=\"username\" value=\"$userid\">";
      $page=~ s/<!--!hiddenfields-->/$h\n$&/;
      $h = "<input type=\"hidden\" name=\"stoken\" value=\"$stoken\">";
      $page=~ s/<!--!hiddenfields-->/$h\n$&/;
      $page =~ s/(<input class="inputButton" value=)"Login"/$1"Proceed_Back"/;
      my $r = &encodeuri($redirect_uri);
      $page =~ s/(<form id="login_form" action=)"\?login"/$1"$r"/;
    } else { $page =~ s/<input class="inputButton".*?>//s; }
    print $page; exit;
  };
  ### End of helper functions
  
  # Check redirect_uri
  if ($redirect_uri ne '' && $redirect_uri !~ /^https:\/\/(\w|[-.~\/])+/i) {
    my $page = &gen_cas_page;
    my $h = 'redirect_uri Error!';
    my $t = "URI of the requesting site is not in an acceptable format:<br>\n".
      "<code>".&htmlquote($redirect_uri)."</code><br>\n".
      "Please check with the CAS maintainer if you think that this URI ".
      "should be accepted.  The rules include a requirement that the URI ".
      "starts with 'https://' (including uppercase), and can have only some ".
      "standard characters.  It is possible that more characters should be ".
      "allowed.";
    $page =~ s/(<!--37--)>(.*)/$1>$h/;
    $page =~ s/(<!--38--)>(.*)/$1>$t/;
    $page =~ s/<!--username-->.*?<!--\/lastrow-->//s;
    print header(), $page; exit;
  }

  if ($querystring eq 'forgotpwd' or param('rt') eq 'forgotpwd') {
    if ($LinkForgotpwd) { print CGI::redirect(-uri=>$LinkForgotpwd); exit; }
    my $page = &gen_cas_page; my $h = 'Send Password';
    my $t = "Enter your UserID or Email to have password reset and sent to ".
      "you by email.\nIf you do not receive email, it may mean that you are ".
      "not registered in the system, and you should contanct the administrator.";
    $page =~ s/(<!--37--)>(.*)/$1>$h/;
    $page =~ s/(<!--38--)>(.*)/$1>$t/;
    $page =~ s/<!--!password-->.*?\n\n/\n/s;
    $page =~ s/(<input class="inputButton" value=)"Login"/$1"Send_Password"/;
    print header(), $page; exit;
  }
  
  my $title = "Login Page for Site: $CGI::AuthRegister::SiteName";
  my $HTMLstart = "<HTML><HEAD><TITLE>$title</TITLE><BODY><h1>$title</h1>\n";
  my $Formstart = "<form action=\"$ENV{SCRIPT_NAME}\" method=\"post\">";
  my $LoginForm =  "<p>Please login with your DalFCS Account userid and password:<br>\n".$Formstart.
    hidden('querystring',$querystring).
    "<table><tr><td align=right>CS Userid:</td><td>".
    textfield(-name=>"csuserid")."</td></tr>\n<tr><td align=right>".
    "Password:</td><td>".password_field(-name=>"password")."</td></tr>\n".
    '<tr><td>&nbsp;</td><td><input type="submit" name="request_type" value="Login"/>'.
    "</td></tr></table></form>\n";

  # $LoginForm.="<pre>LogReport:\n$CGI::AuthRegister::LogReport\nError=$CGI::AuthRegister::Error\n";

  &analyze_cookie;

  # Logout from CAS
  if ($CGI::AuthRegister::SessionId ne '' && param('keywords') eq 'logout') {
    CGI::AuthRegister::logout(); print header(); &finishGeneral; }
  
  if ($SessionId ne '') { print header(); &finishWithPageBack; }

  my $Request_type = param('request_type');

  if ($Request_type eq 'Login') {
    my $username = param('username'); my $password = param('password');
    $username =~ s/\(.*\)//g; $username =~ s/\s+$//; $username =~ s/^\s+//;

    if (! &login($username, $password) ) {
      my $page = &gen_cas_page;
      my $t = "<b>Unsuccessful login!</b><br>\n";
      if ($redirect_uri ne '') {
	my $h = "<input type=\"hidden\" name=\"redirect_uri\" ".
	  "value=\"$redirect_uri\">";
	$page=~ s/<!--!hiddenfields-->/$h\n$&/;
	$t.= "CAS Authentication requested by the following site:<br>\n".
	  "<code>".&htmlquote($redirect_uri)."</code>"; }
      $page =~ s/(<!--38--)>(.*)/$1>$t/;
      print header(), $page; $LogReport.=$Error; &store_log; exit;
    }
    else { print header_session_cookie(); &finishWithPageBack; }
  }
  elsif ($Request_type eq 'Send_Password') {
    &send_email_reminder(param('username'), 'raw');
    my $page = &gen_cas_page;
    my $h = 'Request Received';
    my $t = "Send password request received.  You should receive a password ".
      "if your email is registered at this site.\nIf you do not receive ".
      "a reminder, you should contact the administrator.";    
    $page =~ s/(<!--37--)>(.*)/$1>$h/;
    $page =~ s/(<!--38--)>(.*)/$1>$t/;
    $page =~ s/<!--username-->.*?<!--\/lastrow-->//s; # remove the form
    print header(), $page;
    $LogReport.=$Error; &store_log;
    exit;
  }
  else { # should be: $Request_type eq ''
    print header(); &finishGeneral; }
  die; # Not supposed to be reached
}


# If not logged in, ask for userid/email and password.  Catches ?logout
# request as well. Allows parentheses in userid/email for login, which are
# removed.  This allows users to use auxiliary comments with userid, so that
# browser can distinguish passwords.
sub require_login {
  my %args = @_; return &_require_login_using_cas(@_) if exists($args{-cas});
  my $title = "Login Page for Site: $SiteId";
  my $HTMLstart = "<HTML><HEAD><TITLE>$title</TITLE><BODY><h1>$title</h1>\n";
  my $Formstart = "<form action=\"$ENV{SCRIPT_NAME}\" method=\"post\">";
  my $Back = "<a href=\"$ENV{SCRIPT_NAME}\">Click here for the main page.</a>\n";
  my $LoginForm =  "<p>Please log in to access the site:<br>\n".$Formstart.
    "<table><tr><td align=right>Userid or email:</td><td>".
    textfield(-name=>"userid")."</td></tr>\n<tr><td align=right>".
    "Password:</td><td>".password_field(-name=>"password")."</td></tr>\n".
    '<tr><td>&nbsp;</td><td><input type="submit" name="request_type" value="Login"/>'.
    "</td></tr></table></form>\n";
  my $SendResetForm = "<p>If you forgot your password, it may be possible to ".
    "retrieve it by email:<br>\n".$Formstart."Email: ".
    textfield(-name=>"email_pw_send")."\n".
    '<input type="submit" name="request_type" value="Send_Password"/>'.
    "</form>\n".
    "Or, you can reqest password to be reset and sent to you:<br>\n".
    $Formstart."Email: ".textfield(-name=>"email_reset")."\n".
    '<input type="submit" name="request_type" value="Reset_Password"/>'.
    "</form>\n";

  &analyze_cookie;
  if ($SessionId ne '' && param('keywords') eq 'logout') {
    logout(); print header_delete_cookie(),$HTMLstart,
    "<p>You are logged out.\n", $LoginForm, $SendResetForm; exit; }

  if ($SessionId ne '') { print header(); return 1; }

  my $Request_type = param('request_type');

  if ($Request_type eq 'Login') {
    my $email = param('userid'); my $password = param('password');
    $email =~ s/\(.*\)//g; $email =~ s/\s+$//; $email =~ s/^\s+//;

    if (! &login($email, $password) ) { # checks for userid and email
      print header(), $HTMLstart, "Unsuccessful login!\n";
      print $LoginForm, $SendResetForm; exit;
    }
    else { print header_session_cookie(); return 1; }
  }
  elsif ($Request_type eq 'Send_Password') {
    &send_email_reminder(param('email_pw_send'), 'raw');
    print header(), $HTMLstart, "You should receive password reminder if ".
      "your email is registered at this site.\n".
      "If you do not receive remider, you can contact the administrator.\n",
      $LoginForm, $SendResetForm;
    $LogReport.=$Error; &store_log;
    exit;
  }
  elsif ($Request_type eq 'Reset_Password') {
    &reset_and_send_email_reminder(param('email_reset'), 'raw');
    print header(), $HTMLstart, "You should receive new password if ".
      "your email is registered at this site.\n".
      "If you do not receive remider, you can contact the administrator.\n",
      $LoginForm, $SendResetForm; exit;
  }
  else { # should be: $Request_type eq ''
    print header(), $HTMLstart, $LoginForm, $SendResetForm; exit; }
  
  die; # Not supposed to be reached
}

# parameters:
#   -return_status=>1  rather than exiting on failure, return status
#         return status values: 'logged out', 1, 'not logged in' 'login failed'
#
sub _require_login_using_cas {
  my %args = @_; my $casurl = $args{-cas};
  my $retStatus;
  $retStatus = $args{-return_status} if exists($args{-return_status});
  my $title = "Login Page for Site: $SiteId";
  my $HTMLstart = "<HTML><HEAD><TITLE>$title</TITLE><BODY><h1>$title</h1>\n";
  my $casurl_r = "$casurl?r=".url();
  my $LoginMsg = "<p>Please use <a href=\"".encodeuri($casurl_r)."\">CAS</a> ".
    "to login.\n";

  &analyze_cookie;
  if ($SessionId ne '' && param('keywords') eq 'logout') {
    logout(); print header_delete_cookie();
    if ($retStatus) { return 'logged out' }
    print $HTMLstart, "<p>You are logged out.\n", $LoginMsg; exit; }

  if ($SessionId ne '') { print header(); return 1; }

  my $request_type = param('request_type');
  if ($request_type ne 'Proceed_Back') {
    print header(); if ($retStatus) { return 'not logged in' }
    print $HTMLstart, $LoginMsg; exit; }
  my $username = param('username'); my $stoken = param('stoken');
  if ($username eq '' or $stoken eq '') {
    print header(); if ($retStatus) { return 'not logged in' }
    print $HTMLstart, $LoginMsg; exit; }

  if ($casurl !~ /^https:\/\//i) {
    my $u = CGI::url(); $u=~ s/\/[^\/]+$//; $casurl = "$u/$casurl"; }

  require LWP::UserAgent; require HTTP::Request; require Mozilla::CA;
  my $ua = LWP::UserAgent->new();
  use HTTP::Request::Common qw(POST);
  my $req = POST $casurl, [ rt=>'verify', username=>$username, stoken=>$stoken ];
  my $resp = $ua->request($req);
  my $result = 'fail';
  if ($resp->is_success) {
    my $message = $resp->decoded_content; $message =~ s/\s//g;
    if ($message eq 'answer:ok') { $result = 'ok'; &_dbg383; }
    else { $Error.=" message=($message);" }
  } else {
    $Error.= "HTTP POST error code: ". $resp->code. "\n".
      "HTTP POST error message: ".$resp->message."\n";
  }
  if ($result ne 'ok') {
    $Error.="ERR-384:verify failed, result=($result) casurl=($casurl)\n";
    print header(); $LogReport.=$Error; &store_log;
    if ($retStatus) { return 'login failed'; }
    print $HTMLstart, "Unsuccessful login!\n"; exit; }
  my $u = ($AddAuthenticatedUser ? &get_user_by_userid_or_add($username) :
	   &get_user_unique('userid', $username));
  if ($u eq '') {
    $Error.="382-ERR: no userid ($username)\n";
    $LogReport.=$Error; &store_log;
    print header(); if ($retStatus) { return 'login failed'; }
    print $HTMLstart, "Unsuccessful login!\n"; &store_log; exit; }
  $User = $u; &set_new_session($User);
  $LogReport.="User $UserEmail logged in.\n"; &store_log;
  print header_session_cookie(); return 1;
}

# Requires session (i.e., to be logged in).  Otherwise, makes redirection.
sub require_session {
  my %args=@_; my $defaultcgi = 'index.cgi';
  if (exists($args{-redirect}) && $args{-redirect} ne '' &&
      $args{-redirect} ne $ENV{SCRIPT_NAME})
  { $defaultcgi = $args{-redirect} }
  if (exists($args{-back}) && $args{-back}) {
    $defaultcgi.="?goto=$args{-back}";
  }
  &analyze_cookie;
  if ($SessionId eq '') {
    if ($ENV{SCRIPT_NAME} eq $defaultcgi) {
      print CGI::header(), CGI::start_html, CGI::h1("159-ERR:Login required");
      exit; }
    print CGI::redirect(-uri=>$defaultcgi); exit;
  }
}

# Prepare HTTP header. If SessionId is not empty, generate cookie with
# the sessionid and ticket.
sub header_session_cookie {
  my %args=@_; my $redirect=$args{-redirect};
  if ($redirect ne '') {
    if ($SessionId eq '') { return redirect(-uri=>$redirect) }
    else {
      return redirect(-uri=>$redirect,-cookie=>
		      cookie(-name=>$SiteId,
			     -value=>"$SessionId $Ticket"));
    }
  } else {
    if ($SessionId eq '') { return header } else
      { return header(-cookie=>cookie(-name=>$SiteId,
				      -value=>"$SessionId $Ticket")) }
  }
}

# Delete cookie after logging out. Return string.
sub header_delete_cookie {
  return header(-cookie=>cookie(-name=>$SiteId, -value=>'', -expires=>"now")) }

# Analyze cookie to detect session, and check the ticket as well.  It
# should be called at the beginning of a script.  $SessionId and
# $Ticket are set to empty string if not successful.  The information
# about the session is stored in $DBdir/$DBsessions/$SessionId/session.info
# file.  The structures $Session and $User are set if successful.
sub analyze_cookie {
    my $c = cookie(-name=>$SiteId); # sessionid and ticket
    if ($DebugLevel > 5) { $LogReport.="cookie:$SiteId:$c\n"; &store_log; }
    if ($c eq '') { $SessionId = $Ticket = ''; return; }
    ($SessionId, $Ticket) = split(/\s+/, $c);
    if ($SessionId !~ /^[\w.:-]+$/ or $Ticket !~ /^\w+$/)
    { $User = $SessionId = $Ticket = ''; return; }

    # check validity of session and set user variables
    my $sessioninfofile = "$DBdir/$DBsessions/$SessionId/session.info";
    if (!-f $sessioninfofile) { $SessionId = $Ticket = ''; return; }
    my $se = &read_db_record("file=$sessioninfofile");
    if (!ref($se) or $Ticket ne $se->{'Ticket'})
    { $User = $SessionId = $Ticket = ''; return; }
    $Session = $se;
    $UserEmail = $se->{email}; $UserId = $se->{userid};
    if ($UserEmail =~ /@/) { $User = &get_user_unique('email', $UserEmail) }
    elsif ($UserId ne '') { $User = &get_user_unique('userid', $UserId) }
    else { $Error.="435-ERR: Could not identify the user.\n"; goto E; }
    if ($UserId ne '' && $User->{userid} ne $UserId) {
      $Error.="437-ERR: Non-matching userid.\n"; goto E; }
    if ($Error ne '') { goto E }
    return 1;
  E:
    if ($Error ne '') { $LogReport.=$Error; &store_log; }
    $User = $SessionId = $Ticket = ''; return;
}

########################################################################
# Section: Session Management

# params: $email, opt: pwstore type: md5 raw
sub reset_password {
    my $email = shift; my $pwstore = shift; $pwstore = 'md5' if $pwstore eq '';
    my $password = &random_password(6); my $pwdf = "$DBdir/$DBpwd";
    if (!-f $pwdf) { putfile $pwdf, ''; chmod 0600, $pwdf }
    if (!&lock_mkdir($pwdf)) { $Error.="378-ERR:\n"; return ''; }
    local *PH; open(PH, $pwdf) or croak($!);
    my $content = '';
    while (<PH>) {
	my ($e,$p) = split;
	$content .= $_ if $e ne $email;
    }
    close(PH);
    $content .= "$email ";
    if   ($pwstore eq 'raw') { $content.="raw:$password" }
    elsif($pwstore eq 'md5') { $content.="md5:".md5_base64($password) }
    #else                     { $content.="md5:".md5_base64($password) }
    else                     { $content.="raw:$password" }
    $content .= "\n";
    putfile $pwdf, $content; chmod 0600, $pwdf; &unlock_mkdir($pwdf);
    return $password;
}

sub md5_base64 {
  my $arg=shift; require Digest::MD5; return Digest::MD5::md5_base64($arg); }

sub random_password {
    my $n = shift; $n = 8 unless $n > 0;
    my @chars = (2..9, 'a'..'k', 'm'..'z', 'A'..'N', 'P'..'Z',
                 qw(, . / ? ; : - = + ! @ $ % *) );
    return join('', map { $chars[rand($#chars+1)] } (1..$n));
}

# removes session file and return the appropriate HTTP header
sub logout {
  if ($Session eq '') { $Error.= "481-ERR: No session to log out\n"; return; }
  if (!-d "$DBdir/$DBsessions/$SessionId") { $Error.="482-ERR: No session dir\n" }
  else {
    unlink(<$DBdir/$DBsessions/$SessionId/*>);
    rmdir("$DBdir/$DBsessions/$SessionId"); }
  $LogReport.=$Error."User UserId:$UserId UserEmail:$UserEmail logged out.\n";
  &store_log; $Session = $SessionId = $Ticket = '';
  return 1;
}

# The first parameter can be an userid and email. (diff by @)
sub login {
    my $email = shift; my $password = shift;
    $email = lc $email; my $userid;
    if ($email !~ /@/) { $userid=$email; $email=''; }
    if ($email ne '') {
      if (!&emailcheckok($email)) {
	$Error.="402-ERR:Incorrect email address format"; return; }
      #my $u = &get_user_by_email($email);
      my $u = &get_user_unique('email', $email);
      if ($u eq '') { $Error.='405-ERR:Email not registered'; return; }
      $userid = $u->{userid};
      $User = $u;
    } else {
      if ($userid eq '') { $Error.="409-ERR:Empty userid"; return; }
      if ($LDAPuse and $LDAPaddUsers) {
	return _login_ldap_add($userid, $password); }
      my $u = &get_user_unique('userid', $userid);
      if ($u eq '') { $Error.='531-ERR:Not exist-unique'; &store_log; return; }
      $email = $u->{email};
      $User = $u;
    }
    # Randomize more salt
    $SecretSalt = md5_base64("$SecretSalt $password");

    if (!password_check($User, $password)) {
      $Error.="418:Invalid password\n"; return ''; }

    &set_new_session($User);
    $LogReport.="User $UserEmail logged in.\n"; &store_log;
    return 1;
}

sub _login_ldap_add {
  my $userid = shift; my $password = shift;
  if (!&password_check_ldap($userid, $password)) {
    $Error.="539-ERR:Invalid password for LDAP\n"; return ''; }
  my $u = &get_user_by_userid_or_add($userid);
  if ($u eq '') { $Error.="541-ERR:\n"; &store_log; return; }
  $User = $u;
  # Randomize more salt
  $SecretSalt = md5_base64("$SecretSalt $password");
  &set_new_session($User);
  $LogReport.="User userid:$userid logged in.\n"; &store_log;
  return 1;
}

sub set_new_session {
  my $u = shift;
  my $email = $u->{email};
  my $userid = $u->{userid};
  if ($email !~ /@/ && $userid !~ /\w/) {
    $Error .= "555-ERR: No email nor userid\n"; return '';  }
  my $sDir = "$DBdir/$DBsessions";
  if (!-d $sDir && !&check_db_files) { return ''; }

  $^T =~ /\d{6}$/; my $sessionid = 't'.$&.'_';
  my $a = $userid.'_'.$email,'______';
  $a =~ /.*?(\w).*?(\w).*?(\w).*?(\w).*?(\w).*?(\w)/;
  $sessionid.= $1.$2.$3.$4.$5;
  if (! mkdir("$sDir/$sessionid", 0700)) {
    my $cnt=1; for(;$cnt<100 and !mkdir("$sDir/${sessionid}_$cnt", 0700); ++$cnt) {}
    croak "Cannot create sessions!" if $cnt == 100;
    $sessionid = "${sessionid}_$cnt";
  }
  $SessionId = $sessionid; $Ticket = &gen_secret;
  my $sessionrecord = "SessionId:$SessionId\nTicket:$Ticket\n";
  $sessionrecord.="email:$email\n" if $email ne '';
  $sessionrecord.="userid:$userid\n" if $userid ne '';
  putfile("$sDir/$SessionId/session.info", $sessionrecord);
  $UserEmail = $email; $UserId = $userid; $User = $u;
  return $SessionId;
}

# Return 1 if OK, '' otherwise
sub password_check {
  my $u = shift; my $password = shift;
  if ($LDAPuse) { return &password_check_ldap($u->{userid}, $password); }
  my $pwstored = &find_password($u->{email});
  if ($pwstored =~ /^raw:/) {
    $pwstored=$'; return ( ($pwstored eq $password) ? 1 : '' ); }
  if ($pwstored =~ /^md5:/) {
    $pwstored=$'; return ( ($pwstored eq md5_base64($password)) ? 1 : ''); }
  $Error.="316-ERR:PWCheck error($pwstored)\n"; $ErrorInternal="AuthRegister:$Error"; return '';
}

# Modifying for LDAP; Return 1 if OK, '' otherwise
sub password_check_ldap {
  my $username = shift; my $password = shift;
  $username =~ s/[^a-zA-Z0-9._+=-]//g;
  if ($username eq '' or $LDAPserver eq '' or $LDAPdn eq '') { return '' }
  use Net::LDAP;
  my $dn = "uid=$username,$LDAPdn";
  my $ldap = Net::LDAP->new("ldaps://$LDAPserver") or die "$@";
  my $mesg = $ldap->bind($dn, password => $password);
  if ($mesg->code == 0) {
    # Password correct
    $ldap->unbind; $ldap->disconnect;
    return 1;
  }
  # else invalid password
  $ldap->unbind;
  $ldap->disconnect;
  return '';
}

sub find_password {
  my $email = shift; my $pwfile = "$DBdir/$DBpwd";
  $email = lc $email;
  if (!-f $pwfile && !&check_db_files) { return '' }
  if (!&lock_mkdir($pwfile)) { $Error.="431-ERR:\n"; return ''; }
  local *PH; if (!open(PH,$pwfile)) { &unlock_mkdir($pwfile);
    $Error.="433-ERR: Cannot open ($pwfile):$!\n"; return ''; }
  while (<PH>) {
    my ($e,$p) = split; $e = lc $e;
    if ($e eq $email) { close(PH); &unlock_mkdir($pwfile); return $p; }
  }
  $Error.="NOTFOUND($email)";
  close(PH); &unlock_mkdir($pwfile); return '';
}

# Try to generate a secure random secret
# The best option is to use Math::Random::Secure if available
# This implementation uses its own additional randomization
sub gen_secret {
  my $n = shift; $n = 10 unless $n > 0; my $ret;
  while (length($ret) < $n) {
    $SecretSalt.= md5_base64($SecretSalt.rand);
    my $a=md5_base64($SecretSalt.rand); $a=~ s/[+\/]//g; $ret.=$a;
  }
  return substr($ret, 0, $n);
}

sub random_name {
    my $n = shift; $n = 8 unless $n > 0;
    my @chars = (0..9, 'a'..'z', 'A'..'Z');
    return join('', map { $chars[rand($#chars+1)] } (1..$n));
}

sub store_log {
  if($#_>=-1) { $LogReport.=$_[0] }
  return if $LogReport eq '';
  if ($SendLogs) { &send_email_to_admin('Log entry', $LogReport); }
  $LogReport = '';
}

########################################################################
# Section: Email communication

# params: $email, opt: 'raw' or 'md5' to generate passord
sub reset_and_send_email_reminder {
    my $email = shift; my $pwstore = shift;
    $email=lc $email; $email =~ s/\s/ /g;
    if ($email eq '') {
      $Error.="328-ERR:No e-mail provided to send password\n"; return; }
    if (!emailcheckok($email)) {
      $Error.="330-ERR:Invalid e-mail address provided($email)\n"; return; }
    my $user = get_user_unique('email',$email);
    if ($user eq '') {
      $Error.="333-ERR: No user with email ($email)\n"; return; }
    my $pw = &reset_password($email, $pwstore);
    &send_email_reminder1($email, $pw);
    return 1;
}

# params: $email, opt: 'raw' or 'md5' to generate new password if not found
sub send_email_reminder {
    my $email = shift; my $pwstore = shift;
    $email=lc $email; $email =~ s/\s/ /g;
    if ($email eq '') {
      $Error.="505-ERR:No e-mail provided to send password\n"; return; }
    my $user;
    if ($email =~ /@/) { $user = &get_user_unique('email',  $email) }
    else               { $user = &get_user_unique('userid', $email) }
    if ($user eq '') {
      $Error.="510-ERR: No user with userid/email ($email)\n"; return; }
    $email = $user->{email};
    if (!emailcheckok($email)) {
      $Error.="513-ERR:Invalid e-mail address ($email)\n"; return; }
    my $pw = find_password($email);
    if ($pw =~ /^raw:/) { $pw = $' }
    elsif ($pw ne '') { $Error.="516-ERR:Cannot retrieve password\n"; return; }
    else { $pw = &reset_password($email, $pwstore) }

    &send_email_reminder1($email, $pw);
    return 1;
}

sub send_email_reminder1 {
  my $email = shift; my $pw = shift;
  my $httpslogin = "https://$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}";

  my $msg = "Hi,\n\nYour email and password for the $SiteId site is:\n\n".
    "Email: $email\nPassword: $pw\n\n".
      "You can log in at:\n\n$httpslogin\n\n\n".
        # "$HttpsBaseLink/login.cgi\n\n\n".
	"Best regards,\n$SiteId Admin\n";
  &send_email_to($email, "Subject: $SiteId Password Reminder", $msg);
}

sub send_email_to_admin {
  my $subject = shift; my $msg1 = shift;
  $subject =~ s/\s+/ /g;
  $subject = "Subject: [$SiteId System Report] $subject";
  return if $Email_bcc eq '';
  my $msg = '';
  $msg.="From: $Email_from\n" unless $Email_from eq '';
  $msg.="To: $Email_bcc\n";
  $msg.="$subject\n\n$msg1";
  &_send_email($msg);
}

sub send_email_to {
  my $email = shift; croak unless &emailcheckok($email);
  my $subject = shift; $subject =~ s/[\n\r]/ /g;
  if ($subject !~ /^Subject: /) { $subject = "Subject: $subject" }
  my $msg1 = shift;

  my $msg = '';
  $msg.="From: $Email_from\n" unless $Email_from eq '';
  $msg.="To: $email\n";
  $msg.="Bcc: $Email_bcc\n" unless $Email_bcc eq '';
  $msg.="$subject\n\n$msg1";
  &_send_email($msg);
}

sub _send_email {
  my $fullmessage = shift;
  if (! -x $Sendmail) {
    $Error.="390-ERR:No sendmail ($Sendmail)\n"; return ''; }
  local *S;
  if (!open(S,"|$Sendmail -ti")) {
    $Error.="393-ERR:Cannot run sendmail:$!\n"; return ''; }
  print S $fullmessage; close(S);
}

########################################################################
# Section: Data checks and transformations

# encode string into a \w* sequence
sub encode_w {
    local $_ = shift;
    s/[\Wx]/'x'.uc unpack("H2",$&)/ge;
    return $_;
}

sub decode_w {
    local $_ = shift;
    s/x([0-9A-Fa-f][0-9A-Fa-f])/pack("c",hex($1))/ge;
    return $_;
}

sub encodeuri($) {
  local $_ = shift;
  s/[^-A-Za-z0-9_.~:\/?=]/"%".uc unpack("H2",$1)/ge;
  return $_;
}

# Prepare for HTML display by quoting meta characters.
sub htmlquote($) { local $_ = shift; s/&/&amp;/g; s/</&lt;/g; return $_; }

sub emailcheckok {
    my $email = shift;
    if ($email =~ /^[a-zA-Z][\w\.+-]*[a-zA-Z0-9+-]@
         [a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/x)
    { return 1 }
    return '';
}

sub useridcheckok {
  my $userid = shift; return 1 if $userid=~/^[a-zA-Z0-9-]+$/; return ''; }

# DB related functions

sub read_users_db {
  my $f = "$DBdir/$DBusers";
  if (!-f $f) { $Error.= "636-ERR: no file $f\n"; return; }
  return &read_db("file=$f") }

sub _db8_find_first {
  my $dbf = shift; my $k = shift; my $v = shift;
  die unless $k =~ /^k=/; $k = $';
  my $db_ref = &read_db("file=$dbf");
  if (ref($db_ref) ne 'ARRAY') {
    $Error.="745-ERR: Could not read db file ($dbf)"; return ''; }
  my @db = @{ $db_ref };
  for my $r (@db) {
    if (exists($r->{$k}) && $v eq $r->{$k}) { $Error.="FOUND\n"; return $r } }
  return '';
}

sub get_user {
  my $k = shift; my $v = shift;
  my $db_ref = &read_users_db;
  if (ref($db_ref) ne 'ARRAY') {
    $Error.="644-ERR: Could not get users data (file system problem?)";
    return $User='';
  }
  my @db = @{ $db_ref };
  for my $r (@db)
  { if (exists($r->{$k}) && $v eq $r->{$k}) { return $User=$r } }
  $Error.="650-ERR: no user with key=($k) v=($v)\n"; return $User='';
}

sub get_user_by_email {
  my $email = shift;
  my $db_ref = &read_users_db;
  if (ref($db_ref) ne 'ARRAY') {
    $Error.="657-ERR: Could not get users data (file system problem?)";
    return $User=''; }
  my @db = @{ $db_ref };
  for my $r (@db) { if (lc($email) eq lc($r->{email})) { return $User=$r } }
  $Error.="661-ERR: no user with email ($email)\n"; return $User='';
}

sub get_user_by_userid { return &get_user('userid', $_[0]) }

# Get user by userid, or add userid if does not exist
sub get_user_by_userid_or_add {
  my $userid = shift; my $f = "$DBdir/$DBusers";
  if (!-f $f && !&check_db_files) { return '' }
  my @db = @{ &read_db("file=$f") };
  my $u = '';
  for my $r (@db) {
    next unless exists($r->{userid}); my $v1 = $r->{userid};
    $v1=~s/^\s+//; $v1=~s/\s+$//; $v1=~s/\s+/ /g; $v1 = lc $v1;
    next unless $v1 eq $userid;
    if ($u eq '') { $u = $r; next; }
    $Error.= "819-ERR: double userid ($userid)\n"; return '';
  }
  return $User=$u unless $u eq '';
  $userid =~ s/\s//g; &_db8_append($f, "userid:$userid");
  return get_user_by_userid($userid);
}

# Get user by a key,value, but make sure there is exactly one such user
# Normalizes whitespace and case insensitive
sub get_user_unique {
  my $k = shift; my $v = shift; my $f = "$DBdir/$DBusers";
  if (!-f $f && !&check_db_files) { return '' }
  my @db = @{ &read_db("file=$f") };
  $v=~s/^\s+//; $v=~s/\s+$//; $v=~s/\s+/ /g; $v = lc $v;
  if ($k eq '' or $v eq '')
  { $Error.="669-ERR:Empty k or v ($k:$v)\n"; return ''; }
  my $u = '';
  for my $r (@db) {
    next unless exists($r->{$k}); my $v1 = $r->{$k};
    $v1=~s/^\s+//; $v1=~s/\s+$//; $v1=~s/\s+/ /g; $v1 = lc $v1;
    next unless $v eq $v1;
    if ($u eq '') { $u = $r; next; }
    $Error.= "676-ERR: double user key ($k:$v)\n"; return '';
  }
  return $User=$u unless $u eq '';
  $Error.="866-ERR: no user with key ($k:$v)\n"; return '';
}

sub check_db_files {
  my $ret; my $pwfile = "$DBdir/$DBpwd";
  if (!-d $DBdir) { $ret = mkdir($DBdir, 0700);
    if (!$ret) { $Error.="687-ERR: Could not create dir '$DBdir'"; return ''; }}
  if (!-f $pwfile) { putfile $pwfile, ''; chmod 0600, $pwfile; }
  if (!-f $pwfile) { $Error.="689-ERR: Could not create $pwfile file";
		     return ''; }
  my $f = "$DBdir/$DBusers";
  if (!-f $f) { putfile $f, "#userid:someid\n#email:email\@domain.com\n";
		chmod 0600, $f; }
  if (!-f $f) { $Error.="694-ERR: Could not create $f file"; return ''; }
  $f = "$DBdir/$DBsessions";
  if (!-d $f) { $ret = mkdir($f, 0700);
    if (!$ret) { $Error.="708-ERR: Could not create dir '$f'"; return ''; }}

  return 1;
}

sub _db8_remove {
  my $dbf = shift; my $kdel = shift; my $vdel = shift;
  die unless $kdel =~ /^k=/; $kdel = $';
  if (!&lock_mkdir($dbf)) { $Error.="793-ERR"; return '' }
  local *F; if (!open(F, $dbf)) { &unlock_mkdir($dbf);
    $Error.="795-ERR: opening file $dbf: $!"; return ''; }
  my $arg = join('',<F>); close(F);

  my $arg_save = $arg; my $dbi = 0; my $argcopy = '';
  while ($arg) {
    my $prologue;
    if ($arg =~ /^([ \t\r]*(#.*)?\n)+/) { $prologue = $&; $arg = $'; }
    $argcopy.=$prologue;
    last if $arg eq ''; my $record; my $record_save;
    if ($arg =~ /([ \t\r]*\n){2,}/) {
      $record = "$`\n"; $arg = $'; $record_save = "$`$&"; }
    else { $record_save = $record = $arg; $arg = ''; }
    my $r = {};
    while ($record) {
      $record =~ /^[ \t]*([^\n:]*?)[ \t]*:/ or die "db8: no attribute";
      my $k = $1; $record = $';
      while ($record =~ /^(.*)(\\\r?\n|\r?\n[ \t]+)(\S.*)/)
      { $record = "$1 $3$'" }
      $record =~ /^[ \t]*(.*?)[ \t\r]*\n/ or die;
      my $v = $1; $record = $';
      if (exists($r->{$k})) {
	my $c = 0;
	while (exists($r->{"$k-$c"})) { ++$c }
	$k = "$k-$c";
      }
      $r->{$k} = $v;
    }
    if (exists($r->{$kdel}) && $r->{$kdel} eq $vdel) {}
    else { $argcopy .= $record_save }
  }

  if ($argcopy ne $arg_save) {
    if (!open(F, ">$dbf.lock/new")) { &unlock_mkdir($dbf);
      $Error.="828-ERR: opening file $dbf.lock/new: $!"; return ''; }
    print F $argcopy; close(F); chmod 0600, "$dbf.lock/new"; unlink($dbf);
    rename("$dbf.lock/new", $dbf); }
  &unlock_mkdir($dbf);
} # end of _db8_remove

# Read DB records in the RFC822-like style (to add reference).
sub read_db {
  my $arg = shift;
  if ($arg =~ /^file=/) {
    my $f = $'; if (!&lock_mkdir($f)) { return '' }
    local *F;
    if (!open(F, $f)) {
      $Error.="ERR-945: $f: $!"; &unlock_mkdir($f); return ''; }
    $arg = join('', <F>); close(F); &unlock_mkdir($f);
  }

  my $db = [];
  while ($arg) {
      $arg =~ s/^\s*(#.*\s*)*//;  # allow comments betwen records
      my $record;
      if ($arg =~ /\n\n+/) { $record = "$`\n"; $arg = $'; }
      else { $record = $arg; $arg = ''; }
      my $r = {};
      while ($record) {
        while ($record =~ /^(.*)(\\\n|\n[ \t]+)(.*)/)
	{ $record = "$1 $3$'" }
        $record =~ /^([^\n:]*):(.*)\n/ or die;
        my $k = $1; my $v = $2; $record = $';
        if (exists($r->{$k})) {
          my $c = 0;
          while (exists($r->{"$k-$c"})) { ++$c }
          $k = "$k-$c";
        }
        $r->{$k} = $v;
      }
      push @{ $db }, $r;
  }
  return $db;
}

# Append a record or records to db8
# Assumes that the file is in a good format
sub _db8_append {
  my $fdb=shift;
  if (!&lock_mkdir($fdb)) { $Error.="ERR-975: $!"; return '' }
  local *F; if (!open(F, ">>$fdb")) { &unlock_mkdir($fdb);
    $Error.="ERR-977: write file $fdb: $!"; return ''; }
  while (@_) { my $r=shift; $r =~ s/\s*$/\n/s; print F "\n$r"; }
  &unlock_mkdir($fdb);
}	  

# Read one DB record in the RFC822-like style (to add reference).
sub read_db_record {
    my $arg = shift;
    if ($arg =~ /^file=/) {
	my $f = $'; local *F; open(F, $f) or die "cannot open $f:$!";
	$arg = join('', <F>); close(F);
    }

    while ($arg =~ s/^(\s*|\s*#.*)\n//) {} # allow comments before record
    my $record;
    if ($arg =~ /\n\n+/) { $record = "$`\n"; $arg = $'; }
    else { $record = $arg; $arg = ''; }
    my $r = {};
    while ($record) {
        while ($record =~ /^(.*)(\\\n|\n[ \t]+)(.*)/)
	{ $record = "$1 $3$'" }
        $record =~ /^([^\n:]*):(.*)\n/ or die;
        my $k = $1; my $v = $2; $record = $';
        if (exists($r->{$k})) {
	    my $c = 0;
	    while (exists($r->{"$k-$c"})) { ++$c }
	    $k = "$k-$c";
        }
        $r->{$k} = $v;
    }
  return $r;
}

sub putfile($@) {
    my $f = shift; local *F;
    if (!open(F, ">$f")) { $Error.="325-ERR:Cannot write ($f):$!\n"; return; }
    for (@_) { print F } close(F);
}

########################################################################
# Section: Simple file locking using mkdir

# Exlusive locking using mkdir
# lock_mkdir($fname); # return 1=success ''=fail
sub lock_mkdir {
  my $fname = shift; my $lockd = "$fname.lock"; my $locked;
  # First, hopefully most usual case
  if (!-e $lockd && ($locked = mkdir($lockd,0700))) { return $locked }
  my $tryfor=10; #sec
  $locked = ''; # flag
  for (my $i=0; $i<2*$tryfor; ++$i) {
    select(undef,undef,undef,0.5); # wait for 0.5 sec
    !-e $lockd && ($locked = mkdir($lockd,0700));
    if ($locked) { return $locked }
  }
  $Error.="393-ERR:Could not lock file ($fname)\n"; return $locked;
}

# Unlock using mkdir
# unlock_mkdir($fname); # return 1=success ''=fail or no lock
sub unlock_mkdir {
    my $fname = shift; my $lockd = "$fname.lock";
    if (!-e $lockd) { $Error.="400-ERR:No lock on ($fname)\n"; return '' }
    if (-d $lockd) {  return rmdir($lockd) }
    if (-f $lockd or -l $lockd) { unlink($lockd) }
    $Error.="403-ERR:Unknown error"; return '';
}

########################################################################
# Section: Prepackaged HTML and CSS files

sub gen_cas_page {
  my $ret;
#<? my $c = getfile('cas-template/cas.html');
# echo "\$ret=<<'EOT';\n${c}EOT"; !>
#+
$ret=<<'EOT';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head><title>CAS - Central Authentication Service</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta name="Description" content="CAS - Central Authentication Service">
<meta name="viewport" content="width=device-width">
<link rel="stylesheet" href="cas-all.css" type="text/css" media="screen">
<link rel="stylesheet" href="cas-mobile.css"
 media="handheld, only screen and (max-device-width: 480px)" type="text/css">

<script type="text/javascript" language="javascript">
// <![CDATA[
function searchFocus(){document.getElementById('username').focus();}
// ]]>
</script>

<style type="text/css">
/* <![CDATA[ */
.formInput { float: left; }
/* ]]> */
</style>
</head>

<body onload="searchFocus();">
<div id="pagebox"> <div id="headerBox">
<h1>CAS <span class="hideInMobile">&ndash; Central Authentication
    </span>Service</h1></div>

<div id="content"><div id="content-left">

<form id="login_form" action="?login" method="post">
<table id="form-layout" cellspacing="0" cellpadding="5" border="0">
<tbody><tr><td width="" valign="top" align="left">&nbsp;</td>
 <td width="" valign="top" align="left">
 <h1><!--37-->Login Required
 </h1><p class="sans"><!--38-->CAS Authentication
</p></td></tr>

<!--!username--><tr><td width="" valign="top" align="left">
<p class="formLabel">UserID:</p></td>
<td width="" valign="top" align="left">
<input id="username" name="username" class="formInput" tabindex="1"
 size="20" autocomplete="off" type="text">
</td></tr>

<!--!password-->
<tr><td width="" valign="top" align="left">
<p class="formLabel">Password:</p></td>
<td width="" valign="top" align="left">
<input id="password" name="password" class="formInput" tabindex="2"
 value="" size="20" autocomplete="off" type="password">
</td></tr>

<tr><td width="" valign="top" align="left">&nbsp;</td>
<td width="" valign="top" align="left">
<!--!hiddenfields-->
<input class="inputButton" value="Login" type="submit"
 name="request_type"></td></tr>

<tr class="hideInMobile"><td width="" valign="top" align="left">
 &nbsp;</td><td width="" valign="top" align="left">
 <h2>Please note</h2><p class="sans"><!--60-->
 Before entering your userid and password, verify that the URL
 for this page begins with:
 <strong>_THIS_URL_</strong></p>
 <p class="sans">
 To protect your privacy, quit your web browser when you
 are done accessing services that require authentication.
 </p></td></tr>
<!--/lastrow-->
</tbody></table>
</form></div>

<div id="content-right">
<ul class="plain">
<!--!#forgot <li><a href="?rt=forgotpwd" target="_blank">Forgot your password?</a></li>-->
<!--!# <li class="disabled">CAS Login</li>-->
<!--!#logout <li><a href="?logout">CAS Logout</a></li>-->
<!--!# <li><a href="?help">Help with CAS</a></li>-->
<!--!# <li><span class="hideInMobile">-->
<!--!# <a href="?feeback" target="_blank">Feedback</a></span></li>-->
</ul>

<span class="hideInMobile">
<ul class="plain-serif"><li>
<!--!# <a href="?forgotpwd" target="_blank">Forgot your password?</a></li>-->
<!--!# <li><a href="?changepwd" target="_blank">Changing your password</a></li>-->
</ul>
</span><!--/hideInMobile-->

</div><!--content-right-->
<div style="clear:both;"></div></div></div>
</body></html>
EOT
#-
  if ($GenCasPageCustom ne '') { $ret = $GenCasPageCustom }
    
  my $cssCasAll = $ENV{SCRIPT_NAME}.'?cas-all.css';
  my $cssCasMobile = $ENV{SCRIPT_NAME}.'?cas-mobile.css';
  $ret=~ s/href="cas-all.css"/href="$cssCasAll"/;
  $ret=~ s/href="cas-mobile.css"/href="$cssCasMobile"/;

  my $redirect_uri;
  if (param('redirect_uri') ne '') { $redirect_uri = param('redirect_uri') }
  elsif (param('r') ne '') { $redirect_uri = param('r') }
  
  # Remove "Before entering" unless there is a URL to show (todo, for now,
  # just remove)
  $ret=~ s/<!--60-->.*?(<\/p>)/$1/s;

  my $forgotpassword = 1; # include link, todo for exclusion
  my $removerighthandside = 1;
  if ($forgotpassword) {
    $removerighthandside=''; $ret=~s/<!--!#forgot (.*?)-->/$1/g; }
  if ($SessionId ne '') { $ret=~s/<!--!#logout (.*?)-->/$1/g; }
  
  $ret=~s/<!--!#.*?-->//g;

  # Remove righthand side
  if($removerighthandside) {
    $ret =~
      s/(<div id="content-right">)(.*?)(<\/div><!--content-right-->)/$1$3/s;
  }
  else { # remove "hideinMobile"
    $ret =~ s/<span class="hideInMobile".*?<!--\/hideInMobile-->//; }
  
  return $ret;
}

sub deliver {
  my $par = shift;
  if ($par eq 'cas-all.css') {
    print "Content-Type: text/css; charset=UTF-8\n\n".
#<? my $c = getfile('cas-template/cas-all.css');
# echo "<<'EOT';\n${c}EOT\n;"; !>
#+
<<'EOT';
body {
 background-color: #D1AF55; /*#76A9DC;*/
 color: #444;
 font-family: "Times New Roman", Times, serif;
 margin: 30px;
 padding: 5px;
}

a:link    { text-decoration: none; }
a:visited { text-decoration: none; }
a:active  { text-decoration: none; }
a:hover   { text-decoration: underline; }
.hide	  { display: none; }

.shadow {
 box-shadow: 5px 5px 5px #ccc;
 -moz-box-shadow: 5px 5px 5px #ccc;
 -webkit-box-shadow: 5px 5px 5px #ccc;
}

#pagebox {
 background: #fff;
 border: 1px solid #000;
 box-shadow: 10px 10px 10px #444;
 -moz-box-shadow: 10px 10px 10px #444;
 -webkit-box-shadow: 10px 10px 20px #444;
 margin: 0px auto;
 width: 788px;
 height: 491px;
}

#headerBox {
 background: #A17F25;
 border-bottom: 1px solid #916F15;
 border-left: 1px solid  #916F15;
 border-right: 1px solid  #916F15;
 border-top: 1px solid  #916F15;
 clear: both;
 height: 82px;
 width: 786px;
 text-align:center;
 color: #ffffff;
}

#content-left {
 background: #fff;
 border-right: 1px solid #0F4D92;
 clear: both;
 float: left;
 height: 377px;
 margin: 0px;
 padding: 15px;
 width: 530px;
}

#content-right {
 background: #fafae8;
 border: 0px;
 float: right;
 height: 377px;
 margin: 0px;
 padding: 15px;
 width: 197px;
}

#content-left h1 {
 font-family: "Times New Roman", Times, serif;
 font-size: 20px;
 font-weight: normal;
 margin: 0px 0px 5px 0px;
}

#content-left h2 {
 font-family: "Times New Roman", Times, serif;
 font-size: 20px;
 font-weight: normal;
 margin: 5px 0px 5px 0px;
}

#content-left p.formLabel {
 color: #5F5F5F;
 font-family: "Times New Roman", Times, serif;
 font-size: 16px;
 font-weight: normal;
 margin: 6px 0px 0px 0px;
 text-align: right;
}
	
#content-left p.sans {
 color: #5F5F5F;
 font-family: Verdana, Arial, Helvetica, sans;
 font-size: 11px;
 font-weight: normal;
 line-height: 1.7em;
 margin: 5px 0px 5px 0px;
}
	
#content-left p.sansURL {
 color: #4e6d98;
 font-family: Verdana, Arial, Helvetica, sans;
 font-size: 11px;
 font-weight: normal;
 line-height: 1em;
 margin: 15px 0px 5px 0px;
}

#content ul.plain, ul.plain a { 
 color: #1A3E6F; 
 font-family: Verdana, Geneva, Arial, sans-serif;
 font-size: 14px;
 line-height: 1.5em;
 list-style: none;
 margin: .4em 0em .2em 0em;
 padding: 0em 0em 0em 0em;
 text-indent: 0em;
}
	
#content ul.plain li, ul.plain li a {
 padding-bottom: 0.8em;
}
	
#content ul.plain li.disabled {
 color: #bbb;
}
	
	
#content ul.plain-serif, ul.plain-serif a { 
 color: #1A3E6F; 
 font-family: "Times New Roman", Times, serif;
 font-size: 14px;
 line-height: 1.2em;
 list-style: none;
 margin: 30px 0px 0px 0px;
 padding: 0px 0px 0px 0px;
 text-indent: 0em;
}
	
#content ul.plain-serif li, ul.plain-serif li a {
 padding-bottom: 0.8em;
}
	
#content ol { 
 font-family: Verdana, Arial, Helvetica, sans;
 font-size: 11px;
 font-weight: normal;
 line-height: 1.8em;
 margin: 0px 0px 0px 20px;
 padding: 0px 0px 0px 0px;
 text-indent: 0em;
}
	
#content ol li, ol li a { padding-bottom: 0.8em; }
EOT
;
#-
  }
  elsif ($par eq 'cas-mobile.css') {
    print "Content-Type: text/css; charset=UTF-8\n\n".
#<? my $c = getfile('cas-template/cas-mobile.css');
# echo "<<'EOT';\n${c}EOT\n;"; !>
#+
<<'EOT';
body {
 background-color: #fff;
 color: #444;
 font-family: "Times New Roman", Times, serif;
 margin:  0px;
 padding: 0px;
}

a:link    { text-decoration: none; }
a:visited { text-decoration: none; }
a:active  { text-decoration: none; }
a:hover   { text-decoration: underline; }
.hide	  { display: none; }
.hideInMobile { display: none; }

#pagebox {
 border: 0px;
 background: #fff;
 margin: 0px;
 width: auto;
 height: auto;
 box-shadow: none;
 -moz-box-shadow: none;
 -webkit-box-shadow: none;
}
	
#headerBox {
 border: 0px;
 background: #A17F25;
 overflow: hidden;
 width: auto;
 height: auto;
}

#headerBox h1 { font-size: 14pt; }

#content-left {
 background: #fff;
 border: 0px;
 margin: 0px;
 padding: 15px;
 width: auto;
 height: auto;
 float: none;
}
	
#content-right {
 background: #fff;
 border: 0px;
 width: auto;
 height: auto;
 float: none;
 margin-left: 85px;
}

#form-layout { width: auto; }

#login_form input {
 background: #f8f8f8;
 border: 1px solid  #aaa;
 color: #555;
 font-family: Verdana, Arial, Helvetica, sans;
 font-weight: normal;
 margin: 0px 0px 0px 0px;
 font-size: 16px;
 padding: 5px;
}
	
#login_form input.inputButton {
 background: #F5F091; 
 border: 1px solid #aaa;
 color: #555;
 font-family: Georgia, "Times New Roman", Times, serif;
 font-weight: normal;
 margin: 10px 0px 10px 0px;
 font-size: 18px;
}

#login_form input.formInput {
 width: 170px;
 float: none;
}

h1.mobileTitle { display: none;	}
	
#content-left h1 {
 color: #883F0A;
 font-family: Georgia, "Times New Roman", Times, serif;
 font-weight: bold;
 margin: 0px 0px 5px 0px;
 font-size: 19px;
}
	
#content-left h2 { display: none; }
#content-left p.sans { display: none; }	
#content-left p.sansURL { display: none; }
#content-left p.mobile-tight { margin: 0; }

#content ul.plain, ul.plain a { 
 color: #1A3E6F; 
 font-family: Verdana, Geneva, Arial, sans-serif;
 line-height: 1.3em;
 list-style: none;
 margin: .4em 0em .2em 0em;
 padding: 0em 0em 0em 0em;
 text-indent: 0em;
 font-size: 14px;
}
	
#content ul.plain li, ul.plain li a {
 padding-bottom: 0.8em;
}
	
#content ul.plain li.disabled {
 color: #bbb;
}

#content ul.plain-serif, ul.plain-serif a { 
 display: none;
}
	
#content ul.plain-serif li, ul.plain-serif li a {
 padding-bottom: 0.8em;
}
	
#content ol { 
 color: #5F5F5F;
 font-family: Verdana, Arial, Helvetica, sans;
 font-size: 11px;
 font-weight: normal;
 line-height: 1.8em;
 margin: 0px 0px 0px 20px;
 padding: 0px 0px 0px 0px;
 text-indent: 0em;
}

#content ol li, ol li a {
 padding-bottom: 0.8em;
}
EOT
;
#-

  }
  exit;
} # end of sub deliver

########################################################################
# Section: Debug Functions

sub _dbg383 { return unless $DebugLevel > 5;
  $LogReport.="CAS client: Verification successful.\n"; &store_log; }

########################################################################
# Section: End of code; Documentation

1;

__END__
# Documentation
=pod

=head1 NAME

CGI::AuthRegister - Simple CGI Authentication and Registration in Perl

=head1 SYNOPSIS

Create sub-directory db in your CGI directory, and the file
db/users.db, which may look as follows (RFC822-like format):

  userid:someid
  email:myemail@domain.com

  userid:user2
  email:email2@domain2.com

It is important to separate records by empty lines, and email field is
important, while userid field is optional.  More fields can be added
if needed, this module does not use other fields.

This is a short and simple example of a CGI script index.cgi
(included as examples/2/index.cgi):

  #!/usr/bin/perl
  use CGI::AuthRegister;

  &require_https;  # Require HTTPS connection
  &require_login;  # Require login and print HTTP header,
                   # and handles logout too

  print "<html><body>Successfully logged in as $UserEmail\n";
  print "<p>To logout, click here:\n",
    "<a href=\"$ENV{SCRIPT_NAME}?logout\">Logout</a>\n";

The following script, named index.cgi, which is available with the
distribution in example/1, demonstrates the main module
functionalities:

  #!/usr/bin/perl
  use CGI qw(:standard);
  use CGI::AuthRegister;
  use strict;
  use vars qw($HTMLstart $Formstart $Back $Request_type);
  
  &require_https;  # Require HTTPS connection
  &analyze_cookie; # See if the user is already logged in
  
  # Some useful strings
  $HTMLstart = "<HTML><BODY><PRE>Site: $SiteId\n";
  $Formstart = "<form action=\"$ENV{SCRIPT_NAME}\" method=\"post\">";
  $Back = "<a href=\"$ENV{SCRIPT_NAME}\">Click here for the main page.</a>\n";
  
  $Request_type = param('request_type');
  $Request_type = '' unless grep {$_ eq $Request_type}
    qw(Login Logout Send_Password);
  
  if ($Request_type eq '') {
    print header(), $HTMLstart;
    if ($SessionId eq '') {
      print "You must login to access this site.\n".
        "You can login using the form with the site-specific password:\n".
        $Formstart."Userid or email: ".textfield(-name=>"userid")."\n".
        "Password: ".password_field(-name=>"password")."\n".
        '<input type="submit" name="request_type" value="Login"/>'.
        "</form>\n";
      print "If you forgot your password, you can retrieve it by email:\n";
      print $Formstart."Email: ".textfield(-name=>"email_pw_send")."\n".
        '<input type="submit" name="request_type" value="Send_Password"/>'.
        "</form>\n";
    } else {
      print "You are logged in as: $UserEmail\n",
        "You can logout by clicking this button:\n",
        $Formstart, '<input type="submit" name="request_type" value="Logout"/>',
        "</form>\n$Back";
    }
  }
  elsif ($Request_type eq 'Login') {
    if ($SessionId ne '') {
      print header(), $HTMLstart, "You are already logged in.\n",
        "You should first logout:\n",
        $Formstart, '<input type="submit" name="request_type" value="Logout"/>',
        "</form>\n$Back";
    }
    else {
      my $email = param('userid'); my $password = param('password');
      if (! &login($email, $password) ) { # checks for userid and email
        print header(), $HTMLstart, "Unsuccessful login!\n"; }
      else {
        print header_session_cookie(), $HTMLstart, "Logged in as $UserEmail.\n"; }
      print $Back; exit;
    }
  }
  elsif ($Request_type eq 'Send_Password') {
    &send_email_reminder(param('email_pw_send'), 'raw');
    print header(), $HTMLstart, "You should receive password reminder if ".
      "your email is registered at this site.\n".
      "If you do not receive remider, you can contact the administrator.\n$Back";
  }
  elsif ($Request_type eq 'Logout') {
    if ($SessionId eq '') {
      print header(), $HTMLstart, "Cannot log out when you are not logged in.\n",
        $Back;
    }
    else {
      logout(); print header_delete_cookie(), $HTMLstart, "Logged out.\n$Back"; }
  }


=head1 DESCRIPTION

CGI::AuthRegister is a Perl module for CGI user authentication and
registration.  It is created with objective to be simple, flexible,
and transparent.  For the sake of simplicity, it is not completely
portable, but mostly designed for Linux environment.  As an example,
it relies on a directly calling sendmail for sending email messages.

Example 1, included in the distribution, and shown above, illustrates
the main functionalities of the module in one CGI file.  The module is
designed with the assumption that the CGI programs run with user uid.

=head1 PREDEFINED VARIABLES

=head2 $CGI::AuthRegister::Email_bcc

For example,

  $CGI::AuthRegister::Email_bcc = 'Vlado Keselj <vlado+ar@cs.dal.ca>';

If nonempty, causes BCC copies of the emails to be sent to this address.
This is typically an administrator's address.

=head1 FUNCTIONS

=head2 analyze_cookie()

Analyzes cookied of the web page.  It is called at the beginning of
the script.  If the cookie contains a valid session id and security
ticket, it will set variables $SessionId, $Session (a hash),
$UseEmail, and $User (a hash).  A typical usage is as follows, at the
beginning of a CGI script, after 'use' and similar statements:

  &import_dir_and_config;  # load configuration.pl, optional
  &require_https;          # require HTTPS, optional
  &analyze_cookie;

=head2 import_dir_and_config()

Sets the SiteId as the base directory name.  Loads the configuration.pl
if it exists.

=head2 require_https()

Checks whether the connection is HTTPS.  If it is not, prints redirection
HTTP headers to the HTTPS version of the same URL and exits the program.

=head2 require_session(-redirect=>LoginScript, -back=>BackScript)

Analyzes the cookie and requires non-empty session, meaning a correctly
logged-in user.  If the session is empty, and the redirect argument is
provided (LoginScript) that is different from the current script,
redirection HTTP headers are printed for a redirection to LoginScript.
If LoginScript is not provided, index.cgi is used by default.
If LoginScript (or default index.cgi) is the same as the current script
(which would cause an infinite-loop behaviour), a simple error page is
printed.  If give, the back argument (BackScript) is passed to LoginScript
as a `goto' parameter.  LoginScript is supposed to use this parameter to
redirect back to this page after a successful login.

=head1 SEE ALSO

There are already several modules for CGI authentication in Perl, but
they do not seem to satisfy some specific requirements, that could be
vaguely described as: simple, flexible, robust, and transparent.
Additionally, they do not typically include registration process for
new users and password reminders using email, which are added here.

These are some of the current implementation:

=over 4

=item [CGI::Application::Plugin::Authentication]

Too complex, relies on plugins for different backends (database, flat
files).  The proposed module just uses flat files.

=item [CGI::Auth]

A lot of parameters; too high level, not sufficient flexibility.

=item [CGI::Auth::Auto]

Similar to CGI::Auth.

=item [Apache::AuthCookie]

Relies on the Apache web server; not very flexible.

=item [CGI::Session]

Seem to be too high-level and not leaving sufficient low-level control
and flexibility.

=back

=cut
