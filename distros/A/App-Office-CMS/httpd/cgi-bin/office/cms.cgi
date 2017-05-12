#!/usr/bin/perl

use lib '/home/ron/perl5/lib/perl5';
use common::sense;

use CGI;
use CGI::Application::Dispatch;

# ---------------------

CGI::Application::Dispatch -> dispatch
(
 args_to_new => {QUERY => CGI -> new},
 prefix      => 'App::Office::CMS::Controller',
 table       =>
 [
  ''              => {app => 'Initialize', rm => 'display'},
  ':app'          => {rm => 'display'},
  ':app/:rm/:id?' => {},
 ],
);
