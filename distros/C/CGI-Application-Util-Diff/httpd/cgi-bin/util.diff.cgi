#!/usr/bin/perl
#
# Name:
# util.diff.cgi.
#
# Note:
# Need use lib here because CGI scripts don't have access to
# the PerlSwitches used in Apache's httpd.conf.
# Also, it saves having to install the module repeatedly during testing.

use lib '/home/ron/perl.modules/CGI-Application-Util-Diff/lib';
use strict;
use warnings;

use CGI;
use CGI::Application::Dispatch;

# ---------------------

my($cgi) = CGI -> new();

CGI::Application::Dispatch -> dispatch
(
 args_to_new => {QUERY => $cgi},
 prefix      => 'CGI::Application::Util',
 table       =>
 [
  ''      => {app => 'Diff', rm => 'initialize'},
  '/diff' => {app => 'Diff', rm => 'diff'},
 ],
);
