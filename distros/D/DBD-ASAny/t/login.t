#!/usr/local/bin/perl
#
# $Id: login.t,v 1.1 1998/11/23 16:04:54 mpeppler Exp $

use lib 'blib/lib';
use lib 'blib/arch';

BEGIN {print "1..3\n";}
END {print "not ok 1\n" unless $loaded;}
use DBI;
$loaded = 1;
print "ok 1\n";

# Test for a good connect

my $dbh = DBI->connect("DBI:ASAny:UID=dba;PWD=sql;ENG=asademo;DBF=asademo.db", '', '', {PrintError => 0});

$dbh and print "ok 2\n"
    or print "not ok 2\n";

$dbh->disconnect if $dbh;

# Test for a bad connect

$dbh = DBI->connect("DBI:ASAny:UID=dba;PWD=xxx;ENG=asademo;DBF=asademo.db", '', '', {PrintError => 0});

$dbh and print "not ok 3\n"
    or print "ok 3\n";

$dbh->disconnect if $dbh;

exit(0);
