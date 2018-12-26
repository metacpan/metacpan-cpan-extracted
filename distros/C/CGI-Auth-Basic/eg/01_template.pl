#!/usr/bin/perl -w
use strict;
use warnings;
use CGI;

my $my_auth = MyAuth->new( CGI->new );
# $auth->set_template(delete_all => 1);
$my_auth->check_user;
$my_auth->_screen(
   content => 'You can use this program',
   title   => 'Access Granted',
);

package MyAuth;
use CGI::Auth::Basic;

sub new {
   my $class = shift;
   my $cgi   = shift;
   CGI::Auth::Basic->fatal_header("Content-Type: text/html; charset=ISO-8859-9\n\n");
   %CGI::Auth::Basic::ERROR = error();
   my $auth = CGI::Auth::Basic->new(
               cgi_object     => $cgi,
               file           => './password.txt',
               http_charset   => 'ISO-8859-1',
               setup_pfile    => 1,
               logoff_param   => 'cik',
               changep_param  => 'changepassword',
               cookie_id      => 'passcookie',
               cookie_timeout => '10m',
               chmod_value    => 0777,
            );

   $auth->set_template(template());
   $auth->set_title(title());
   return $auth;
}

sub template {
   return login_form => <<"TEMPLATE",
<span class="error"><? PAGE_FORM_ERROR ?></span>
<form action="<? PROGRAM ?>" method="post">

<table border="0" cellpadding="0" cellspacing="0">
 <tr><td class="darktable">
  <table border="0" cellpadding="4" cellspacing="1">
 <tr>
   <td class="titletable" colspan="3">You need to login to use this function</td>
 </tr>
 <tr>
  <td class="lighttable">Enter <i>the</i> password to run this program:</td>
  <td class="lighttable"><input type="password" name="<? COOKIE_ID ?>"></td>
  <td class="lighttable" align="right"><input type="submit" name="submit" value="Login"></td>
 </tr>
</table>
</td> </tr>
</table>
</form>
TEMPLATE

change_pass_form => <<"TEMPLATE",
<span class="error"><? PAGE_FORM_ERROR ?></span>
<form action="<? PROGRAM ?>" method="post">

<table border="0" cellpadding="0" cellspacing="0">
 <tr><td class="darktable">
  <table border="0" cellpadding="4" cellspacing="1">
 <tr>
   <td class="titletable" colspan="3">
   Enter a password between 3 and 32 characters and no spaces allowed!</td>
 </tr>
 <tr>
  <td class="lighttable">Enter your new password:</td>
  <td class="lighttable"><input type="password" name="<? COOKIE_ID ?>_new"></td>
  <td class="lighttable" align="right">
  <input type="submit" name="submit" value="Change Password">
  <input type="hidden" name="change_password" value="ok"></td>
  <input type="hidden" name="<? CHANGEP_PARAM ?>" value="1"></td>

 </tr>
</table>
</td> </tr>
</table>
</form>
TEMPLATE

screen => <<"TEMPLATE",
<html>
   <head>
    <? PAGE_REFRESH ?>
    <title>My Ultra Secure Page -> <? PAGE_TITLE ?></title>
    <style>
      body       {font-family: Verdana, sans; font-size: 10pt}
      td         {font-family: Verdana, sans; font-size: 10pt}
     .darktable  { background: black;   }
     .lighttable { background: white;   }
     .titletable { background: #dedede; }
     .error      { color = red; font-weight: bold}
     .small      { font-size: 8pt}
    </style>
   </head>
   <body>
      <? PAGE_LOGOFF_LINK    ?>
      <? PAGE_CONTENT        ?>
      <? PAGE_INLINE_REFRESH ?>
   </body>
   </html>
TEMPLATE

   logoff_link => <<"TEMPLATE",
   <span class="small">[<a href="<? PROGRAM ?>?<? LOGOFF_PARAM ?>=1">Log-off</a> 
   - <a href="<? PROGRAM ?>?<? CHANGEP_PARAM ?>=1">Change password</a>]</span>
TEMPLATE
}

sub title {
return login_form       => 'Login',
   cookie_error     => 'Your invalid cookie has been deleted by the program',
   login_success    => 'You are now logged-in',
   logged_off       => 'You are now logged-off',
   change_pass_form => 'Change password',
   password_created => 'Password created',
   password_changed => 'Password changed successfully',
   error            => 'Error',
   ;
}

sub error {
return INVALID_OPTION    => q{Options must be in 'param => value' format!},
   CGI_OBJECT        => 'I need a CGI object to run!!!',
   FILE_READ         => 'Error opening pasword file: ',
   NO_PASSWORD       => 'No password specified (or password file can not be found)!',
   UPDATE_PFILE      => 'Your password file is empty and your current setting does not allow this code to update the file! Please update your password file.',
   ILLEGAL_PASSWORD  => 'Illegal password! Not accepted. Go back and enter a new one',
   FILE_WRITE        => 'Error opening paswword file for update: ',
   UNKNOWN_METHOD    => q{There is no method called '<b>%s</b>'. Check your coding.},
   EMPTY_FORM_PFIELD => q{You didn't set any password (password file is empty)!},
   WRONG_PASSWORD    => '<p>Wrong password!</p>',
   INVALID_COOKIE    => 'Your cookie info includes invalid data and it has been deleted by the program.',
   ;
}
