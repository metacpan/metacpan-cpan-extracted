#!/usr/bin/env perl

use warnings;
use strict;
# use diagnostics;

use CGI::Info;

my $info = CGI::Info->new();

my $tmpdir = $info->tmpdir();
my $script_name = $info->script_name();

my $domain = $info->domain_name();
my $host = $info->host_name();
my $is_mobile = $info->is_mobile();
my $is_robot = $info->is_robot();
my $script_dir = $info->script_dir();
my $rootdir = $info->rootdir();
my $is_search_engine = $info->is_search_engine();

print 'Status: ', $info->status(), "\n",
	"Content-type: text/plain\n\n";

print "Domain_name: $domain\n",
	"Host_name: $host\n",
	"Tmpdir: $tmpdir\n",
	"Is_mobile: $is_mobile\n",
	"Is_robot: $is_robot\n",
	"Is_search_engine: $is_search_engine\n",
	"Script_dir: $script_dir\n",
	"Rootdir: $rootdir\n",
	"Script_name: $script_name\n-----\n";

if($info->params()) {
	my %FORM = %{$info->params()};
	foreach (keys(%FORM)) {
		print "$_ => $FORM{$_}\n";
	}
}

if($ENV{'HTTP_COOKIE'}) {
	print 'HTTP_COOKIE: ', $ENV{'HTTP_COOKIE'}, "\n",
		"Cookies:\n";

	foreach my $cookie(split (/; /, $ENV{'HTTP_COOKIE'})) {
		my ($key, $value) = split(/=/, $cookie);

		print "Cookie $key:\n";
		my $c = $info->get_cookie(cookie_name => $key);
		if(!defined($c)) {
			print "ERROR: Expected $value, got undef\n";
		} elsif($c eq $value) {
			print "$c\n";
		} else {
			print "ERROR: Expected $value, got $c\n";
		}
	}
}
