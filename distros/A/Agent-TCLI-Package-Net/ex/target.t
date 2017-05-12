#!/usr/bin/perl

use warnings;
use strict;
use Test::More qw(no_plan);

sub VERBOSE () { 0 }

use Getopt::Lucid qw(:all);

my ($opt, $verbose,$domain,$username,$password,$resource,$host);

eval {$opt = Getopt::Lucid->getopt([
		Param("domain|d"),
		Param("username|u"),
		Param("password|p"),
		Param("resource|r"),
		Param("host"),
		Counter("verbose|v"),
	])};
if($@) {die "ERROR: $@";}

$verbose = $opt->get_verbose ? $opt->get_verbose : VERBOSE;

# xmpp username/password to log in with
$username = $opt->get_username ? $opt->get_username : 'username';
$password = $opt->get_password ? $opt->get_password : 'password';
$domain = $opt->get_domain ? $opt->get_domain : 'example.com';
$host = $opt->get_host ? $opt->get_host : $domain;
$resource = $opt->get_resource ? $opt->get_resource : 'test';

use POE;
use Agent::TCLI::Transport::Test;
use Agent::TCLI::Testee;
use Agent::TCLI::Transport::XMPP;
use Agent::TCLI::Package::XMPP;
use Agent::TCLI::Package::Net::HTTP;

# Need to set up transport to talk to other Agents

# Packages for XMPP

# Within test scripts, we use diag() to output verbose messages
# to ensure we don't mess up the Test::Harness processing.
my @packages = (
	# We need the transport controller package to shut down the transport at the
	# end of the testing.
	Agent::TCLI::Package::XMPP->new,

	Agent::TCLI::Package::Net::HTTP->new,
);

# Need a transport to deliver the tests to remote hosts
Agent::TCLI::Transport::XMPP->new(
    'jid'		=> Net::XMPP::JID->new($username.'@'.$domain.'/'.$resource),
    'jserver'	=> $host,
	'jpassword'	=> $password,
);

my $test_master = Agent::TCLI::Transport::Test->new({
    'control_options'	=> {
	    'packages' 		=> \@packages,
    },
});

# Set up the local test
my $local = Agent::TCLI::Testee->new(
	'test_master'	=> $test_master,
	'addressee'		=> 'self',
);

# Set up the remote test
my $remote = Agent::TCLI::Testee->new({
	'test_master'	=> $test_master,
	'addressee'		=> $username.'@'.$domain.'/tcli',
	'transport'		=> 'transport_xmpp',  # The default POE Session alias
	'protocol'		=> 'XMPP',
});

# Beginning of tests

# Remote up?
$remote->ok('status');

# get remotes IP address
$remote->ok('Control show local_address');
my $target = $remote->get_param('local_address','',30);

#add a new response to the webserver
$remote->ok('httpd uri add regex=/test2.* response=OK200');

# start remote web server with logging
$remote->ok('httpd set logging');
$remote->ok('httpd spawn port=8080');

# make sure those completed before proceeding
$test_master->done;

# have local query target webserver.
$local->ok('http tget url=http://'.$target.':8080/test1.htm resp=404');
$local->ok('http tget url=http://'.$target.':8080/test2.htm resp=200');

# check to see if it's in the logs
$remote->ok('tail test add like=test1', 'passed test test1');
$remote->ok('tail test add like=test2', 'passed test test2');

# shut down httpd
$remote->ok('httpd stop port=8080');

# make sure to shut down the transport or else the script will not stop.
$local->ok('xmpp shutdown');

# Though tests will start during building of the tests, POE isn't fully running
# and all tests will not complete until the master run is called.
$test_master->run;

