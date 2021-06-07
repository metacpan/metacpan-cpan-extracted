#!/usr/bin/perl
use CGI::AuthRegister;

&import_dir_and_config; # Even with no config file uses current dir as name
$CGI::AuthRegister::AllowSignup = 1; # allow new user signup (registration)
&require_https;  # Require HTTPS connection
&require_login;  # Require login and print HTTP header, and handles logout too

print "<html><body>Successfully logged in as $UserEmail\n";
print "<p>To logout, click here:\n",
 "<a href=\"$ENV{SCRIPT_NAME}?logout\">Logout</a>\n";
