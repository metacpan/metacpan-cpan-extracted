#!/usr/bin/perl -wT
#!/opt/local/bin/perl -wT
#
# Name:
#	echo.cgi.
#
# Purpose:
#	Let students input data to a form, and echo it back to them.

use lib '.';
use strict;

use CGI;
use CGI::Echo;

# -----------------------------------------------

my($q) = CGI -> new();

CGI::Echo -> new(q => $q) -> print();
