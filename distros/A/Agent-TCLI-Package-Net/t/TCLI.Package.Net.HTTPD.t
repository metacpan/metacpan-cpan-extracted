#!/usr/bin/env perl
# $Id: TCLI.Package.Net.HTTPD.t 63 2007-05-03 15:57:38Z hacker $

use Test::More tests => 65;
use warnings;
use strict;

use Getopt::Lucid qw(:all);

sub VERBOSE () { 0 }

my ($opt, $verbose,$domain,$username,$password,$host, $poe_td, $poe_te);

eval {$opt = Getopt::Lucid->getopt([
		Counter("poe_debug|d"),
		Counter("poe_event|e"),
		Counter("xmpp_debug|x"),
		Counter("verbose|v"),
		Switch("blib|b"),
	])};
if($@) {die "ERROR: $@";}

$verbose = $opt->get_verbose ? $opt->get_verbose : VERBOSE;

if ( $opt->get_blib )
{
	use lib 'blib/lib';
}

# xmpp username/password to log in with
$poe_td = $opt->get_poe_debug;
$poe_te = $opt->get_poe_event;

sub POE::Kernel::TRACE_DEFAULT  () { $poe_td }
sub POE::Kernel::TRACE_EVENTS  () { $poe_te }

use POE;
use Agent::TCLI::Transport::Test;
use Agent::TCLI::Testee;
use Agent::TCLI::Package::Net::HTTP;
use Agent::TCLI::Package::Tail;

# TASK Test suite is not complete. Need testing for catching errors.

use_ok('Agent::TCLI::Package::Net::HTTPD');

my $testee = "httpd";

# Need to use the test-builder for diagnostic output instead of printing
# Using a ref to verbose to support dynamic changing of verbosity while running
my $test1 = Agent::TCLI::Package::Net::HTTPD->new({
	'verbose' 	=> \$verbose,
	'do_verbose'	=> sub { diag( @_ ) },
	});

my $http = Agent::TCLI::Package::Net::HTTP->new({
	'verbose' 	=> \$verbose,
	'do_verbose'	=> sub { diag( @_ ) },
	});

my $tail = Agent::TCLI::Package::Tail->new({
	'verbose' 	=> \$verbose,
	'do_verbose'	=> sub { diag( @_ ) },
	});


my $test_master = Agent::TCLI::Transport::Test->new({

	'verbose'   	=> \$verbose,        # Verbose sets level or warnings
	'do_verbose'	=> sub { diag( @_ ) },

    'control_options'	=> {
	     'packages' 	=> [ $test1, $http, $tail ],
    },

});

my $t = Agent::TCLI::Testee->new(
	'test_master'	=> $test_master,
	'addressee'		=> 'self',
);

is($test1->name,'tcli_'.$testee, '$test1->Name get from init args');

# Test verbose get-set methods
my $tv = $test1->verbose;
# for init 'verbose'		=> '0',
ok($test1->verbose(1),'$test1->verbose set ');
is($test1->verbose,1, '$test1->verbose get from set');

like($test1->Verbose("ok"),qr(ok),'$test1->Verbose returns ok');
# put it back
$test1->verbose($tv);

my $test_c1 = $test1->commands();
is(ref($test_c1),'HASH', '$test1->commands is a hash');

my $test_c1_0 = $test_c1->{'httpd'};

is($test_c1_0->name,'httpd', '$test_c1_0->name get from init args');
is($test_c1_0->usage,'httpd spawn port=8080', '$test_c1_0->usage get from init args');
is($test_c1_0->help,'simple http web server', '$test_c1_0->help get from init args');
is($test_c1_0->topic,'net', '$test_c1_0->topic get from init args');
is($test_c1_0->command,'tcli_'.$testee, '$test_c1_0->command get from init args');
is($test_c1_0->handler,'establish_context', '$test_c1_0->handler get from init args');
is($test_c1_0->call_style,'session', '$test_c1_0->call_style get from init args');


$t->is_body('httpd','Context now: httpd','Context now: httpd');
$t->ok('spawn' );
$t->ok('stop' );

$t->like_body('show port',qr(8080),'show default port');
$t->ok('set port 8000');
$t->like_body('show port',qr(8000),'show set port');
$t->not_ok('set port eight');
$t->like_body('show port',qr(8000),'show set port');
$t->ok('set port 8080');

$t->like_body('show address',qr(#!undefined),'show default address');
$t->ok('set address 127.0.0.1');
$t->like_body('show address',qr(127.0.0.1),'show set address');
$t->not_ok('set address foobario');
$t->like_body('show address',qr(127.0.0.1),'show set address');

$t->ok('set hostname example.com');
$t->like_body('show hostname',qr(example.com),'show set hostname');

$t->ok('set regex ^/foo/.*');
$t->like_body('show regex',qr(\^/foo/\.\*),'show set regex');

$t->like_body('show response',qr(OK200),'show set response');
$t->ok('set response NA404');
$t->like_body('show response',qr(NA404),'show set response');
$t->not_ok('set response OK404');
$t->like_body('show response',qr(NA404),'show set response');
$t->ok('set response OK200');

$t->ok('uri add regex=foo');
$t->like_body('show handlers',qr(foo));
$t->ok('spawn' );
$t->ok('/http cget url=http://127.0.0.1:8080/foo.htm');
$t->ok('stop' );
$t->ok('uri delete regex=foo');
$t->unlike_body('show handlers',qr(foo),'foo gone');

$t->ok('set logging');
$t->like_body('show logging',qr(logging: 1) );
$t->ok('uri add regex=bar.*');
$t->like_body('show handlers',qr(bar.*));
$t->ok('spawn' );

$t->ok('/tail test add like 200.*?bar');
$t->ok('/http cget url=http://127.0.0.1:8080/bar.htm');
$t->ok('/tail test add like 404.*?foo');
$t->ok('/http cget url=http://127.0.0.1:8080/foo.htm');
$t->ok('/tail test add like 200.*?foobar');
$t->ok('/http cget url=http://127.0.0.1:8080/foobar.htm');

$t->ok('stop' );
$t->ok('uri delete regex=bar.*');
$t->unlike_body('show handlers',qr(bar),'bar gone');

# test for error on restarting on same port
$t->ok('spawn port 8000' );
$t->ok('/http cget url=http://127.0.0.1:8000/foo.htm','HTTPD up');
$t->not_ok('spawn port 8000' );
$t->not_ok('stop' );
$t->ok('stop port 8000' );

# Can't add handler after server up yet. Need to fix SimpleHTTP
# 13 tests
#$t->ok('spawn' );
#$t->ok('uri add regex=bar.*');
#$t->like_body('show handlers',qr(bar.*));
#
#$t->ok('/tail test add like 200.*?bar');
#$t->ok('/http cget url=http://127.0.0.1:8080/bar.htm');
#$t->ok('/tail test add like 404.*?foo');
#$t->ok('/http cget url=http://127.0.0.1:8080/foo.htm');
#$t->ok('/tail test add like 200.*?foobar');
#$t->ok('/http cget url=http://127.0.0.1:8080/foobar.htm');
#
#$t->ok('stop' );
#$t->ok('uri delete regex=bar.*');
#$t->unlike_body('show handlers',qr(bar),'bar gone');


$test_master->run;

