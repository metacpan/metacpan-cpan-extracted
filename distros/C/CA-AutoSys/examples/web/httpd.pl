#!/bin/perl

#
# $Id: httpd.pl 45 2007-06-21 11:01:37Z sini $
#

use strict;
use warnings;

use Net::HTTPServer;
use Getopt::Long;
use CA::AutoSys;
use HTML::Macro;
use Pod::Usage;

my $port	= 8081;
my $docroot	= $ENV{PWD};

my $user	= "autosys";
my $passwd	= "autosys";
my $dsn;
my $job;

GetOptions( "port=i"	=> \$port,
			"dsn=s"		=> \$dsn,
			"docroot=s"	=> \$docroot,
			"user=s"	=> \$user,
			"passwd=s"	=> \$passwd,
			"job=s"		=> \$job);

if (!$job) {
	die("must specify a job pattern, e.g. --job=MY_JOBS%...\n");
}

if (!$dsn) {
	die("must specify an autosys dsn, e.g. --dsn=dbi:Sybase:server=MY_AUTOSYS_SERVER...\n");
}

my $http_server = new Net::HTTPServer(port => $port, docroot => $docroot, log => "STDOUT");
if (!$http_server) {
	die("can't create http server on port ".$port);
}

$http_server->RegisterURL("/", \&autosys_handler);

$http_server->Start();
$http_server->Process();

exit(0);

my $jobid;
sub autosys_handler {
	my $req = shift;
	my $res = $req->Response();

	my $autosys = CA::AutoSys->new(dsn => $dsn, user => $user, password => $passwd);
	if (!defined($autosys)) {
		die("can't connect to AutoSys DB: ".$CA::AutoSys::errstr);
	}

	foreach my $var (keys(%{$req->Env()})) {
		my ($x, $name) = split(':', $var);
		if ($x eq "job" && $req->Env($var) !~ m/^$/) {
			my $rc;
			if ($req->Env($var) =~ m/STATUS:(.*)/) {
				printf("changing status of %s to %s...", $name, $1);
				$rc = $autosys->send_event(job_name => $name, event => 'CHANGE_STATUS', status => $1);
			} else {
				printf("sending event %s to %s...", $req->Env($var), $name);
				$rc = $autosys->send_event(job_name => $name, event => $req->Env($var));
			}
			printf("%s\n", $rc == 1 ? "done" : "failed");
		}
	}

	my $html = new HTML::Macro("$docroot/autosys.html");

	my $jobs_loop = $html->new_loop("jobs", "id", "background", "job_name1", "job_name2", "last_start", "last_end", "status", "select_class");

	$jobid = 1;
	my $jobs = $autosys->find_jobs($job);
	while (my $job = $jobs->next_job()) {
		print_job_status($jobs_loop, $res, $job, 0);
	}

	$res->Print($html->process());

	return $res;
} # autosys_handler()

# prints a job's status the HTML way
sub print_job_status {
	my ($jobs_loop, $res, $job, $level) = @_;

	my $status = $job->get_status();

	my ($background, $job_name1, $stat, $select_class);
	if ($job->{job_type} eq "b") {
		$background = "rgb(255, 238, 187)";
		$job_name1 = '<b>'.$job->{job_name}.'</b>';
		$select_class = "select_box";
	} else {
		$background = "rgb(255, 255, 255)";
		$job_name1 = '&nbsp;&nbsp;'x$level.$job->{job_name};
		$select_class = "select_job";
	}

	if ($status->{name} eq "SUCCESS") {
		$stat = '<td style="color: rgb(0, 255, 0)";>'.$status->{name}.'</td>';
	} elsif ($status->{name} eq "RUNNING") {
		$stat = '<td style="color: rgb(0, 255, 0)";><blink><b>'.$status->{name}.'</b></blink></td>';
	} elsif ($status->{name} eq "FAILURE") {
		$stat = '<td style="color: rgb(255, 0, 0)";><blink><b>'.$status->{name}.'</b></blink></td>';
	} elsif ($status->{name} eq "TERMINATED") {
		$stat = '<td style="color: rgb(255, 0, 0)";>'.$status->{name}.'</td>';
	} else {
		$stat = '<td style="color: rgb(255, 200, 0);">'.$status->{name}.'</td>';
	}

	$jobs_loop->push_array($jobid++, $background, $job_name1, $job->{job_name}, CA::AutoSys::Status::format_time($status->{last_start}), CA::AutoSys::Status::format_time($status->{last_end}), $stat, $select_class);

	my $children = $job->find_children();
	while (my $child = $children->next_child()) {
		print_job_status($jobs_loop, $res, $child, $level+1);
	}
}	# print_job_status()
