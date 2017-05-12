#!/usr/bin/perl

use strict;
use warnings;

use CGI qw/fatalsToBrowser/;

# ---------------------------

my($q)			= CGI -> new;
my($package)	= $0;

print $q -> header({type => 'text/html;charset=ISO-8859-1'}),
	$q -> start_html({title => $package}),
	$q -> h1({align => 'center'}, $package),
	'URL: ', $q -> url(), '<br />',
	'Path info: ', $q -> path_info, '<br />',
	"CGI V: $CGI::VERSION<br />",
	$q -> end_html;

