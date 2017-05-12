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
