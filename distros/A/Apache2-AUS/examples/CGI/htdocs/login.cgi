#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Session::AUS;
use Schema::RDBMS::AUS::User;

my $cgi = CGI->new;
my $session = CGI::Session::AUS->new;

my $message;

unless($message = $ENV{REDIRECT_AUS_AUTH_FAILURE}) {
    if(my $user = $session->user) {
        $message = "Logged in as $user->{name} (#$user->{id}).";
    } else {
        $message = "";
    }
}

print $cgi->header('text/html'), <<"EOT";
<HTML>
 <HEAD>
  <TITLE>Login Test</TITLE>
 </HEAD>
 <BODY>
  <A HREF="login?logout=1&go=/test/apache2-aus-cgi/login.cgi">Log Out</A>
  <HR/>
  <FORM METHOD="POST" ACTION="login">
   <INPUT TYPE="HIDDEN" NAME="go" VALUE="/test/apache2-aus-cgi/env.cgi">
   <INPUT TYPE="HIDDEN" NAME="go_error" VALUE="/test/apache2-aus-cgi/login.cgi">
   User: <INPUT TYPE="TEXT" NAME="user" /><BR/>
   Pass: <INPUT TYPE="TEXT" NAME="password" /><BR/>
   <INPUT TYPE="SUBMIT" VALUE="Go" />
  </FORM>
  <HR/>
  <B>$message</B>
 </BODY>
</HTML>
EOT
