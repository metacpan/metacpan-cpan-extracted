#!/usr/bin/env perl

use strict;
use warnings;

use CGI;

use Data::Session;

use File::Spec;
use File::Temp;

# -------------------

# The EXLOCK is for BSD-based systems.

my($directory)   = File::Temp::newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($data_source) = 'dbi:SQLite:dbname=' . File::Spec -> catdir($directory, 'sessions.sqlite');
my($session)     = Data::Session -> new(data_source => $data_source) || die $Data::Session::errstr;

$session -> expire(10);

my($my_header) = $session -> http_header;

print "<$my_header>\n";

my($q)          = CGI -> new;
my($cgi_cookie) = $q -> cookie(-name => 'CGISESSID', -value => $session -> id, -expires => '+10s');
my($cgi_header) = $q -> header(-cookie => $cgi_cookie, -type => 'text/html');

print "<$cgi_header>\n";

print $my_header eq $cgi_header ? 'Same' : 'Different';
print "\n";
