#!/usr/bin/env perl
# $Id: TCLI.Package.Net.HTTP.t 61 2007-05-02 17:35:42Z hacker $

use Test::More qw(no_plan);
use lib 'blib/lib';
use warnings;
use strict;

use Getopt::Long;

# process options
my ($verbose,$poe_td,$poe_te);
eval { GetOptions (
  		"verbose+"		=> \$verbose,
  		"event_trace+"		=> \$poe_te,
  		"default_trace+"		=> \$poe_td,
)};
if($@) {die "ERROR: $@";}

$verbose = 0 unless defined($verbose);
$poe_td = 0 unless defined($poe_td);
$poe_te = 0 unless defined($poe_te);

sub POE::Kernel::TRACE_DEFAULT  () { $poe_td }
sub POE::Kernel::TRACE_EVENTS  () { $poe_te }

use POE;
use Agent::TCLI::Transport::Test;
use Agent::TCLI::Testee;

# TASK Test suite is not complete. Need testing for catching errors.

use_ok('Agent::TCLI::Package::Net::HTTP');

my $testee = "http";

# Need to use the test-builder for diagnostic output instead of printing
# Using a ref to verbose to support dynamic changing of verbosity while running
my $test1 = Agent::TCLI::Package::Net::HTTP->new({
	'verbose' 	=> \$verbose,
	'do_verbose'	=> sub { diag( @_ ) },
	});

my $test_master = Agent::TCLI::Transport::Test->new({

#    'verbose'   	=> \$verbose,        # Verbose sets level or warnings
	'do_verbose'	=> sub { diag( @_ ) },

    'control_options'	=> {
	     'packages' 	=> [ $test1 ],
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

my $test_c1_0 = $test_c1->{'http'};

is($test_c1_0->name,'http', '$test_c1_0->name get from init args');
is($test_c1_0->usage,'http tget url=http:\example.com\request resp=404', '$test_c1_0->usage get from init args');
is($test_c1_0->help,'http web cient environment', '$test_c1_0->help get from init args');
is($test_c1_0->topic,'net', '$test_c1_0->topic get from init args');
is($test_c1_0->command,'tcli_'.$testee, '$test_c1_0->command get from init args');
is($test_c1_0->handler,'establish_context', '$test_c1_0->handler get from init args');
is($test_c1_0->call_style,'session', '$test_c1_0->call_style get from init args');


$t->is_body('http','Context now: http','Context now: http');
$t->not_ok('tget','tget no args');
$t->ok('tget url=http://testing.erichacker.com/404.html resp=404',
		'tget for 404' );
$t->like_body('tget url=http://testing.erichacker.com/404.html resp=200',
		qr(failed), 'tget failed for bad request');
$t->like_body('tget url=http://testing.erichacker.com/ resp=200',
		qr(ok), 'tget for 200');

$t->like_body('cget url=http://testing.erichacker.com/404.html',
		qr(resp=404), 'cget for 404 url' );
$t->like_body('cget url=http://testing.erichacker.com/',
		qr(resp=200), 'cget for good url');

#retries
$t->like_body('cget url=http://testing.erichacker.com/ resp=200 rc=2 ri=10',
		qr(http://testing.erichacker.com/ resp=200 try=1), 'Retry count 1 of 2');
$t->ok('','Retry count 2 of 2');

# Bad cases
$t->like_body('cget http://testing.erichacker.com/',
		qr(Invalid.*?url),  'Forgot url= in command');
$t->not_ok('cget url=htpp://testing.erichacker.com/',
		'Invalid url= in command');

$test_master->run;

