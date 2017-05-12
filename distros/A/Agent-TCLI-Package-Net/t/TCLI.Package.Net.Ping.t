#!/usr/bin/env perl
# $Id: TCLI.Package.Net.Ping.t 61 2007-05-02 17:35:42Z hacker $

use Test::More tests => 29;
use lib 'blib/lib';
use warnings;
use strict;

sub VERBOSE () { 0 }

use Getopt::Lucid qw(:all);

my ($opt, $verbose, $poe_td, $poe_te);

eval {$opt = Getopt::Lucid->getopt([
		Counter("poe_debug|d"),
		Counter("poe_event|e"),
		Counter("verbose|v"),
	])};
if($@) {die "ERROR: $@";}

$verbose = $opt->get_verbose ? $opt->get_verbose : VERBOSE;

$poe_td = $opt->get_poe_debug;
$poe_te = $opt->get_poe_event;

sub POE::Kernel::TRACE_DEFAULT  () { $poe_td }
sub POE::Kernel::TRACE_EVENTS  () { $poe_te }

use Agent::TCLI::Transport::Test;
use Agent::TCLI::Testee;
use POE;

# TASK Test suite is not complete. Need testing for catching errors.

use_ok('Agent::TCLI::Package::Net::Ping');

my $test1 = Agent::TCLI::Package::Net::Ping->new({
	'verbose'		=> \$verbose,
#	'do_verbose'	=> sub { diag( @_ ) },
	});

my $test_master = Agent::TCLI::Transport::Test->new({
#	'peers'	=> \@users,

    'verbose'   	=> \$verbose,        # Verbose sets level or warnings
	'do_verbose'	=> sub { diag( @_ ) },

    'control_options'	=> {
	     'packages' 	=> [ $test1, ],
    },

});

my $ping = Agent::TCLI::Testee->new(
	'test_master'	=> $test_master,
	'addressee'		=> 'self',
);

is($test1->name,'tcli_ping', '$test1->name initialized');
my $test_c1 = $test1->commands();
is(ref($test_c1),'HASH', '$test1->commands is a hash');
my $test_c1_0 = $test_c1->{'ping'};
is($test_c1_0->name,'ping', '$test_c1_0->name loaded ok');
is($test_c1_0->usage,'ping target example.com', '$test_c1_0->usage ok');
is($test_c1_0->help,'check to see if a host is alive', '$test_c1_0->help ok');
is($test_c1_0->topic,'network', '$test_c1_0->topic ok');
is($test_c1_0->command,'tcli_ping', '$test_c1_0->command ok');
is($test_c1_0->handler,'ping', '$test_c1_0->handler ok');
is($test_c1_0->call_style,'session', '$test_c1_0->call_style ok');

$ping->like_body( 'ping show timeout',qr(timeout.*?10), 'ping show timeout');
$ping->like_body( 'ping show retry_count',qr(retry_count.*?1), 'ping show retry count');
$ping->like_body( 'ping show target',qr(#!undefined), 'ping show target not set');
$ping->ok( 'ping set target 127.0.0.1', 'ping set target');
$ping->like_body( 'ping show target',qr(target.*?127.0.0.1), 'ping show target');
$ping->ok( 'ping set timeout 30', 'ping set timeout');
$ping->like_body( 'ping show timeout',qr(timeout.*?30), 'ping show timeout');
$ping->ok( 'ping set retry_count 3', 'ping set retry_count');
$ping->like_body( 'ping show retry_count',qr(retry_count.*?3), 'ping show retry count');

$ping->like_body( 'ping target localhost',qr(pong));

$ping->like_body( 'ping target www.google.com',qr(pong), 'ping google');

$ping->like_body( 'ping target localhost retry_count 10',qr(pong));
#$ping->like_body( 'ping target 127.0.0.1',qr(Error: ping already in progress for), 'ping 127.0.0.1');

$ping->ok('ping');

$ping->like_body( 'ping set target abcd',qr(Invalid: target), 'ping BAD set target ');
$ping->like_body( 'ping set retry_count abcd',qr(Invalid: retry_count), 'ping BAD set retry_count' );
$ping->like_body( 'ping set timeout abcd',qr(Invalid: timeout), 'ping BAD set timeout');

$ping->like_body( 'ping target ""',qr(Target must be defined in command line or in default settings.));


$test_master->run;




