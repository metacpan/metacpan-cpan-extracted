#!/usr/bin/perl

use strict;
use CGI::Carp qw(fatalsToBrowser);
use lib '/home/toki/Desktop/wtk/CGI-WebToolkit/lib';
use CGI::WebToolkit;

my $wtk = CGI::WebToolkit->new(
	-privatepath	=> '/home/toki/Desktop/wtk/CGI-WebToolkit/t/private',
	-publicpath		=> '/home/toki/Desktop/wtk/CGI-WebToolkit/t/public',
	-publicurl		=> 'http://localhost/',
	-cgipath		=> '/home/toki/Desktop/wtk/CGI-WebToolkit/t/cgi',
	-cgiurl			=> 'http://localhost/cgi/',
	
	# db
	-user			=> 'root',
	-name 			=> 'test',
	
	# session
	-sessiontable	=> 'session',
	
	# user
	-usertable		=> 'user',
	-checkrights	=> 1,
	
	# caching
	-cachetable		=> 'cache',
	
	-entryaction 	=> 'test.home',
);

print $wtk->handle();
