#!/usr/bin/env perl
# $Id: TCLI.Package.Net.Traceroute.t 61 2007-05-02 17:35:42Z hacker $

use Test::More tests => 33;
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

# TASK Test suite is not complete. Need more testing for catching errors.

use_ok('Agent::TCLI::Package::Net::Traceroute');

my $test1 = Agent::TCLI::Package::Net::Traceroute->new({
	'verbose'		=> \$verbose,
	'do_verbose'	=> sub { diag( @_ ) },
	});

my $test_master = Agent::TCLI::Transport::Test->new({

    'verbose'   	=> \$verbose,        # Verbose sets level or warnings
	'do_verbose'	=> sub { diag( @_ ) },

    'control_options'	=> {
	     'packages' 	=> [ $test1, ],
    },

});

my $tracer = Agent::TCLI::Testee->new(
	'test_master'	=> $test_master,
	'addressee'		=> 'self',
);


is($test1->name,'tcli_trace', '$test1->name initialized');
my $test_c1 = $test1->commands();
is(ref($test_c1),'HASH', '$test1->commands is a hash');
my $test_c1_0 = $test_c1->{'traceroute'};
is($test_c1_0->name,'traceroute', '$test_c1_0->name loaded ok');
is($test_c1_0->usage,'traceroute target example.com', '$test_c1_0->usage ok');
is($test_c1_0->help,'determine route to a host', '$test_c1_0->help ok');
is($test_c1_0->topic,'network', '$test_c1_0->topic ok');
is($test_c1_0->command,'tcli_trace', '$test_c1_0->command ok');
is($test_c1_0->handler,'trace', '$test_c1_0->handler ok');
is($test_c1_0->call_style,'session', '$test_c1_0->call_style ok');

#defaults
$tracer->like_body( 'traceroute show firsthop',qr(firsthop: 1), 'traceroute show firsthop');
$tracer->like_body( 'traceroute show timeout',qr(timeout.*?0), 'traceroute show timeout');
$tracer->like_body( 'traceroute show querytimeout',qr(querytimeout.*?3), 'traceroute show querytimeout');
$tracer->like_body( 'traceroute show target',qr(!undefined), 'traceroute show target not set');
$tracer->like_body( 'traceroute show queries',qr(queries.*?3), 'traceroute show queries');
$tracer->like_body( 'traceroute show max_ttl',qr(max_ttl.*?30), 'traceroute show max_ttl');
$tracer->like_body( 'traceroute show baseport',qr(baseport.*?33434), 'traceroute show baseport');
$tracer->like_body( 'traceroute show useicmp',qr(!undefined), 'traceroute show useicmp not set');

$tracer->like_body( 'traceroute target localhost useicmp',qr(Traceroute results for 127.0.0.1), 'traceroute localhost');

$tracer->ok( 'traceroute set target 127.0.0.1', 'traceroute set target');
$tracer->like_body( 'traceroute show target',qr(target.*?127.0.0.1), 'traceroute show target');
$tracer->ok( 'traceroute set timeout 30', 'traceroute set timeout');
$tracer->like_body( 'traceroute show timeout',qr(timeout.*?30), 'traceroute show timeout');
$tracer->ok( 'traceroute set queries 4', 'traceroute set queries');
$tracer->like_body( 'traceroute show queries',qr(queries.*?4), 'traceroute show queries');

$tracer->like_body( 'traceroute target www.google.com useicmp',qr(Traceroute results for ), 'traceroute google');
$tracer->like_body( 'traceroute target 127.0.0.1',qr(Traceroute results for ), 'traceroute 127.0.0.1');

$tracer->ok( 'traceroute' );
$tracer->like_body( 'traceroute set target abcd',qr(Invalid: target), 'traceroute BAD set target ');
$tracer->like_body( 'traceroute set queries abcd',qr(Invalid: queries ), 'traceroute BAD set queries' );
$tracer->like_body( 'traceroute set timeout abcd',qr(Invalid: timeout ), 'traceroute BAD set timeout');

$test_master->run;




