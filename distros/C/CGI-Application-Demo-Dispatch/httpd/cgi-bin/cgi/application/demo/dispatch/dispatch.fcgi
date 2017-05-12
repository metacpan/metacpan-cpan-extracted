#!/usr/bin/env perl
#
# Name:
# dispatch.

use strict;
use warnings;

use CGI::Application::Dispatch;
use CGI::Fast;
use FCGI::ProcManager;

# ---------------------

my($proc_manager) = FCGI::ProcManager -> new({n_processes => 2});

$proc_manager -> pm_manage();

my($cgi);

while ($cgi = CGI::Fast -> new() )
{
	$proc_manager -> pm_pre_dispatch();

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

	$proc_manager -> pm_post_dispatch();
}
