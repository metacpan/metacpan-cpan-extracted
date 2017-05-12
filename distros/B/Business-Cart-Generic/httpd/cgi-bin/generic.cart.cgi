#!/usr/bin/env perl

use strict;
use warnings;

use CGI;
use CGI::Application::Dispatch;

# ---------------------

CGI::Application::Dispatch -> dispatch
(
 args_to_new => {QUERY => CGI -> new},
 prefix      => 'Business::Cart::Generic::Controller',
 table       =>
 [
  ''              => {app => 'Initialize', rm => 'display'},
  ':app'          => {rm => 'display'},
  ':app/:rm/:id?' => {},
 ],
);
