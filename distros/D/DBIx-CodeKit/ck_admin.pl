#!/usr/bin/perl

#       #       #       #
#
# ck_admin.pl
#
# Local setup for ck_admin.pl.
# Customize this file to your environment!
#
# Copyright (C) 2003 John Gorman <jgorman@webbysoft.com>
# http://www.webbysoft.com/codekit
#

use strict;
use warnings;
use DBI;
use DBIx::CodeKit;
use CGI;

use vars qw($dbh $cgi $ckh);
use vars qw($perm_add $perm_upd $perm_del);

require("ck_connect.pl");
$dbh = ck_connect();

$cgi = new CGI;
$ckh = new DBIx::CodeKit($dbh,
                getparam  => sub { $cgi->param(shift) },
                getparams => sub { $cgi->param((shift).'[]') }
                );

# Set security here.
$perm_add = 1;
$perm_upd = 1;
$perm_del = 1;                  # Set to 0 for most people!

# If you are keeping session ids in your urls.
sub cka_sess_url {
    return shift;               # No session id in url.
#   return $sess->url($url);    # Add session id to url.
}

#       #       #       #
# Do the actual work!
#
require("ck_admin_main.pl");
cka_admin_main();
