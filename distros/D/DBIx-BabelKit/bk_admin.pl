#!/usr/bin/perl

#       #       #       #
#
# bk_admin.pl
#
# Local setup for bk_admin_main.pl.
# Customize this file to your environment!
#
# Copyright (C) 2003 John Gorman <jgorman@webbysoft.com>
# http://www.webbysoft.com/babelkit
#

use strict;
use warnings;
use DBI;
use DBIx::BabelKit;
use CGI;

use vars qw($dbh $cgi $bkh);
use vars qw($perm_add $perm_upd $perm_del);

require("bk_connect.pl");
$dbh = bk_connect();

$cgi = new CGI;
$bkh = new DBIx::BabelKit($dbh,
                getparam  => sub { $cgi->param(shift) },
                getparams => sub { $cgi->param((shift).'[]') }
                );

# Set security here.
$perm_add = 1;
$perm_upd = 1;
$perm_del = 1;                  # Set to 0 for most people!

# If you are keeping session ids in your urls.
sub bka_sess_url {
    return shift;               # No session id in url.
#   return $sess->url($url);    # Add session id to url.
}

#       #       #       #
# Do the actual work!
#
require("bk_admin_main.pl");
bka_admin_main();
