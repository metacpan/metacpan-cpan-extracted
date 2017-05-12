#!/usr/bin/env perl
#
# Name:
# dispatch.cgi.

use strict;
use warnings;

use CGI;
use CGI::Application::Dispatch;

# ---------------------

my($cgi) = CGI -> new();

CGI::Application::Dispatch -> dispatch
(
 args_to_new => {QUERY => $cgi},
 prefix      => 'CGI::Application::Demo::Dispatch',
 table       =>
 [
  ''         => {app => 'Menu', rm => 'display'},
  ':app'     => {rm => 'display'},
  ':app/:rm' => {},
 ],
);
