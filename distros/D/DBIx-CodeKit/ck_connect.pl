#!/usr/bin/perl

#       #       #       #
#
# ck_connect.pl
#
# Connect to the database.
# Customize this file to your environment!
#
# Copyright (C) 2003 John Gorman <jgorman@webbysoft.com>
# http://www.webbysoft.com/codekit
#

use strict;
use warnings;
use DBI;

# Database connection.  Set these parameters:

sub ck_connect {
    my $dbh = DBI->connect(
        "DBI:mysql:webbysoft:localhost",
        "webbysoft",
        "124c41"
        ) or die "DBI::connect: $DBI::errstr\n";

    return $dbh;
}

1;
