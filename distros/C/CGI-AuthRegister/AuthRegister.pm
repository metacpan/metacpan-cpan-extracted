# <? read_starfish_conf(); &generate_header; !>
#+
# file: AuthRegister.pm
# CGI::AuthRegister - Simple CGI Authentication and Registration in Perl
# (c) 2012-14 Vlado Keselj http://web.cs.dal.ca/~vlado
# $Date: $
# $Id: $
#-

package CGI::AuthRegister;
use strict;
#<? &generate_standard_vars !>
#+
use vars qw($NAME $ABSTRACT $VERSION);
$NAME     = 'AuthRegister';
$ABSTRACT = 'Simple CGI Authentication and Registration in Perl';
$VERSION  = '1.0';
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
@EXPORT = qw($Error $SessionId $SiteId $SiteName $User
  $UserEmail $SendLogs $LogReport
  analyze_cookie header_delete_cookie header_session_cookie
  import_dir_and_config login logout
  require_https require_login send_email_reminder
  get_user get_user_by_userid set_new_session store_log
 );

use vars qw($Email_from $Email_bcc $Error $ErrorInternal $LogReport $Sendmail
  $Session $SessionId $SiteId $SiteName $Ticket $User $UserEmail $SendLogs);
# $Error = ''; # Appended error messages, OK to be sent to user
# $ErrorInternal = ''; # Appended internal error messages, intended
                       # for administrator
# $LogReport = '';  # Collecting some important log events if needed
# $Session   = '';  # Session data structure
# $SessionId = '';  # Session identifier, generated
$SiteId = 'Site';   # Site identifier, used in cookies and emails
$SiteName = 'Site'; # Site name, can include spaces
# $Ticket = '';     # Session ticket for security, generated
# $User      = '';  # User data structure
# $UserEmail = '';  # User email address
# $SendLogs  = '';  # If true, send logs by email to admin ($Email_bcc)

$Email_from = ''; # Example: $SiteId.' <vlado@cs.dal.ca>';
$Email_bcc  = ''; # Example: $SiteId.' Bcc <vlado@cs.dal.ca>';

$Sendmail = "/usr/lib/sendmail"; # Sendmail with full path

# Functions
sub putfile($@);

########################################################################
# Configuration
# sets site id as the base directory name; imports configuration.pl if exists
sub import_dir_and_config {
  my $base = `pwd`; $base =~ /\/([^\/]*)$/; $base = $1; $base =~ s/\s+$//;
  $SiteId = $SiteName = $base;
  if (-r 'configuration.pl') { package main; require 'configuration.pl'; }
}

########################################################################
# HTTPS Connection and Cookies Management

# Check that the connection is HTTPS and if not, redirect to HTTPS.
# It must be done before script produces any output.
sub require_https {
    if ($ENV{'HTTPS'} ne 'on') {
	print "Status: 301 Moved Permanently\nLocation: https://$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}\n\n";
	exit 0;
    }
}

# If not logged in, ask for userid/email and password.  Catches ?logout
# request as well. Allows parentheses in userid/email for login, which are
# removed.  This allows users to use auxiliary comments with userid, so that
# browser can distinguish passwords.
sub require_login {
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
    logout(); print header_delete_cookie(), $HTMLstart,
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
      print CGI::header(), CGI::start_html, CGI::h1("147-ERR:Login required");
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
# about the session is stored in db/sessions.d/$SessionId/session.info
# file.  The structures $Session and $User are set if successful.
sub analyze_cookie {
    my $c = cookie(-name=>$SiteId); # sessionid and ticket
    if ($c eq '') { $SessionId = $Ticket = ''; return; }
    ($SessionId, $Ticket) = split(/\s+/, $c);
    if ($SessionId !~ /^[\w.:-]+$/ or $Ticket !~ /^\w+$/)
    { $User = $SessionId = $Ticket = ''; return; }

    # check validity of session and set user variables
    my $sessioninfofile = "db/sessions.d/$SessionId/session.info";
    if (!-f $sessioninfofile) { $SessionId = $Ticket = ''; return; }
    my $se = &read_db_record("file=$sessioninfofile");
    if (!ref($se) or $Ticket ne $se->{'Ticket'})
    { $User = $SessionId = $Ticket = ''; return; }
    $Session = $se;
    $UserEmail = $se->{email};
    $User = &get_user_by_email($UserEmail);
    if ($Error ne '') {	$User = $SessionId = $Ticket = ''; return; }
}

########################################################################
# Session Management

# params: $email, opt: pwstore type: md5 raw
sub reset_password {
    my $email = shift; my $pwstore = shift; $pwstore = 'md5' if $pwstore eq '';
    my $password = &random_password(6);
    if (!-f 'db/passwords') {
      putfile 'db/passwords', ''; chmod 0600, 'db/passwords' }
    if (!&lock_mkdir('db/passwords')) { $Error.="95-ERR:\n"; return ''; }
    local *PH; open(PH,"db/passwords") or croak($!);
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
    putfile 'db/passwords', $content; chmod 0600, 'db/passwords';
    &unlock_mkdir('db/passwords');
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
  if ($Session eq '') { $Error.= "217-ERR: No session to log out\n"; return; }
  if (!-d "db/sessions.d/$SessionId") { $Error.="218-ERR: No session dir\n" }
  else {
    unlink(<db/sessions.d/$SessionId/*>); rmdir("db/sessions.d/$SessionId"); }
  $LogReport.=$Error."User $UserEmail logged out."; &store_log;
  $Session = $SessionId = $Ticket = '';
  return 1;
}

# The first parameter can be an userid and email. (diff by @)
sub login {
    my $email = shift; my $password = shift;
    $email = lc $email; my $userid;
    if ($email !~ /@/) { $userid=$email; $email=''; }
    if ($email ne '') {
      if (!&emailcheckok($email)) {
	$Error.="242-ERR:Incorrect email address format"; return; }
      #my $u = &get_user_by_email($email);
      my $u = &get_user_unique('email', $email);
      if ($u eq '') { $Error.='245-ERR:Email not registered'; return; }
      $userid = $u->{userid};
      $User = $u;
    } else {
      if ($userid eq '') { $Error.="249-ERR:Empty userid"; return; }
      #my $u = &get_user_by_userid($userid);
      my $u = &get_user_unique('userid', $userid);
      if ($u eq '') { $Error.='252-ERR:Not exist-unique'; return; }
      $email = $u->{email};
      $User = $u;
    }

    if (!password_check($User, $password)) {
      $Error.="258:Invalid password\n"; return ''; }

    &set_new_session($User);
    $LogReport.="User $UserEmail logged in.\n"; &store_log;
    return 1;
}

sub set_new_session {
  my $u = shift; my $email = $u->{email};
  mkdir('db', 0700) or croak unless -d 'db';
  mkdir('db/sessions.d', 0700) or croak unless -d 'db/sessions.d';

  my $sessionid = $email."______"; $sessionid =~ /.*?(\w).*?(\w).*?(\w).*?(\w).*?(\w).*?(\w)/;
  $sessionid = $1.$2.$3.$4.$5; $^T =~ /\d{6}$/; $sessionid.= "_$&";
  if (! mkdir("db/sessions.d/$sessionid", 0700)) {
    my $cnt=1; for(;$cnt<100 and !mkdir("db/sessions.d/${sessionid}_$cnt", 0700); ++$cnt) {}
    croak "Cannot create sessions!" if $cnt == 100;
    $sessionid = "${sessionid}_$cnt";
  }
  $SessionId = $sessionid; $Ticket = &random_name;
  putfile("db/sessions.d/$SessionId/session.info",
	  "SessionId:$SessionId\nTicket:$Ticket\nemail:$email\n");
  $UserEmail = $email;
  return $SessionId;
}

# Return 1 if OK, '' otherwise
sub password_check {
  my $u = shift; my $password = shift; my $pwstored = &find_password($u->{email});
  if ($pwstored =~ /^raw:/) {
    $pwstored=$'; return ( ($pwstored eq $password) ? 1 : '' ); }
  if ($pwstored =~ /^md5:/) {
    $pwstored=$'; return ( ($pwstored eq md5_base64($password)) ? 1 : ''); }
  $Error.="316-ERR:PWCheck error($pwstored)\n"; $ErrorInternal="AuthRegister:$Error"; return '';
}

sub find_password {
  my $email = shift; my $pwfile = "db/passwords";
  $email = lc $email;
  if (!-f $pwfile) { putfile $pwfile, ''; chmod 0600, $pwfile }
  if (!&lock_mkdir($pwfile)) { $Error.="309-ERR:\n"; return ''; }
  local *PH; if (!open(PH,$pwfile)) {
    &unlock_mkdir($pwfile);
    $Error.="312-ERR: Cannot open ($pwfile):$!\n"; return ''; }
  while (<PH>) {
    my ($e,$p) = split; $e = lc $e;
    if ($e eq $email) { close(PH); &unlock_mkdir($pwfile); return $p; }
  }
  $Error.="NOTFOUND($email)";
  close(PH); &unlock_mkdir($pwfile); return '';
}

sub random_name {
    my $n = shift; $n = 8 unless $n > 0;
    my @chars = (0..9, 'a'..'z', 'A'..'Z');
    return join('', map { $chars[rand($#chars+1)] } (1..$n));
}

sub store_log {
  if($#_>=-1) { $LogReport.=$_[0] }
  return if $LogReport eq '';
  if ($SendLogs) { &send_email_to_admin('Log entry', $LogReport) }
  $LogReport = '';
}

########################################################################
# Email communication

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
      $Error.="356-ERR:No e-mail provided to send password\n"; return; }
    if (!emailcheckok($email)) {
      $Error.="358-ERR:Invalid e-mail address provided($email)\n"; return; }
    my $user = get_user_by_email($email);
    if ($user eq '') {
      $Error.="361-ERR: No user with email ($email)\n"; return; }
    my $pw = find_password($email);
    if ($pw =~ /^raw:/) { $pw = $' }
    elsif ($pw ne '') { $Error.="364-ERR:Cannot retrieve password\n"; return; }
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
# Data checks

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

# Uses file db/users.db.  Empty string returned if unsuccessful, with
# error message appended to $Error.
sub get_user_by_email {
    my $email = shift;
    if (!-f 'db/users.db')
    { $Error.= "454-ERR: no file db/users.db\n"; return; }
    my @db = @{ &read_db('file=db/users.db') };
    for my $r (@db) { if (lc($email) eq lc($r->{email})) { return $User=$r } }
    $Error.="457-ERR: no user with email ($email)\n"; return $User='';
}

sub get_user_by_userid {
    my $userid = shift;
    if (!-f 'db/users.db')
    { $Error.= "463-ERR: no file db/users.db\n"; return; }
    my @db = @{ &read_db('file=db/users.db') };
    for my $r (@db) { if ($userid eq $r->{userid}) { return $User=$r } }
    $Error.="466-ERR: no user with userid ($userid)."; return $User='';
}

sub get_user {
  my $k = shift; my $v = shift;
  if (!-f 'db/users.db')
  { $Error.= "472-ERR: no file db/users.db\n"; return; }
  my @db = @{ &read_db('file=db/users.db') };
  for my $r (@db)
  { if (exists($r->{$k}) && $v eq $r->{$k}) { return $User=$r } }
  $Error.="476-ERR: no user with key=($k) v=($v)."; return $User='';
}

# Get user by a key,value, but make sure there is exactly one such user
# Normalizes whitespace and case insensitive
sub get_user_unique {
  my $k = shift; my $v = shift;
  if (!-f 'db/users.db')
  { $Error.= "455-ERR: no file db/users.db\n"; return ''; }
  my @db = @{ &read_db('file=db/users.db') };
  $v=~s/^\s+//; $v=~s/\s+$//; $v=~s/\s+/ /g; $v = lc $v;
  if ($k eq '' or $v eq '')
  { $Error.="461-ERR:Empty k or v ($k:$v)\n"; return ''; }
  my $u = '';
  for my $r (@db) {
    next unless exists($r->{$k}); my $v1 = $r->{$k};
    $v1=~s/^\s+//; $v1=~s/\s+$//; $v1=~s/\s+/ /g; $v1 = lc $v1;
    next unless $v eq $v1;
    if ($u eq '') { $u = $r; next; }
    $Error.= "467-ERR: double user key ($k:$v)\n"; return '';
  }
  return $User=$u unless $u eq '';
  $Error.="470-ERR: no user with key ($k:$v)\n"; return '';
}

# Read DB records in the RFC822-like style (to add reference).
sub read_db {
  my $arg = shift;
  if ($arg =~ /^file=/) {
    my $f = $'; if (!&lock_mkdir($f)) { return '' }
    local *F; open(F, $f) or die "cannot open $f:$!";
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
# Simple file locking using mkdir

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
