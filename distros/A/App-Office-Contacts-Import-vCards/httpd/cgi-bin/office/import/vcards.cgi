#!/usr/bin/perl
#
# Name:
# vards.cgi.

use strict;
use warnings;

use CGI;
use CGI::Application::Dispatch;

# ---------------------

CGI::Application::Dispatch -> dispatch
(
 args_to_new => {QUERY => CGI -> new},
 prefix      => 'App::Office::Contacts::Import::vCards::Controller',
 table       =>
 [
  ''         => {app => 'Initialize', rm => 'display'},
  ':app'     => {rm => 'display'},
  ':app/:rm' => {},
 ],
);
