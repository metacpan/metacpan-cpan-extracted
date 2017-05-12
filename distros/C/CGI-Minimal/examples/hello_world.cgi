#!/usr/bin/perl -wT

###################################################################
# An example of a very simple CGI script 
#

use strict;
use CGI::Minimal;

{
    my $cgi         = CGI::Minimal->new;
    my $choice      = $cgi->param('choice');
    $choice         = defined($choice) ? '<p>(you chose "' . CGI::Minimal->htmlize($choice) . '")</p>' : '';
    my $script_name = CGI::Minimal->htmlize($ENV{'SCRIPT_NAME'});
    print <<"EOT";
Content-Type: text/html; charset=utf-8

<html>
 <head>
  <title>CGI::Minimal "Hello World" Script</title>
 </head>
 <body>
  <h2>CGI::Minimal Example Script ("Hello World")</h2>
  <p>
   Select either <a href="$script_name?choice=a">a</a> or <a href="$script_name?choice=b">b</a>
  </p>
  $choice
 </body>
</html>
EOT
}
