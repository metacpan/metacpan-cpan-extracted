#!/usr/bin/perl -wT

###########################################################################33
# This is a simple form debugging tool. It shows a table of the 
# calling environment variables and CGI parameters.
#

use strict;
use CGI::Minimal;

my $cgi           = CGI::Minimal->new;
my $calling_parms = $cgi->calling_parms_table;

print <<"EOT";
Content-Type: text/html; charset=utf-8

<html>
 <head>
  <title>Calling Parms</title>
 </head>
 <body>
$calling_parms
 </body>
</html>
EOT
