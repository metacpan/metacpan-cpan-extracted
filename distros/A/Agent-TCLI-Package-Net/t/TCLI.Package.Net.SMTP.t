#!/usr/bin/env perl
# $Id: TCLI.Package.Net.SMTP.t 68 2007-06-06 18:13:38Z hacker $

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

use_ok('Agent::TCLI::Package::Net::SMTP');

my $testee = "smtp";

# Need to use the test-builder for diagnostic output instead of printing
# Using a ref to verbose to support dynamic changing of verbosity while running
my $test1 = Agent::TCLI::Package::Net::SMTP->new({
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

my $test_c1_0 = $test_c1->{'smtp'};

is($test_c1_0->name,'smtp', '$test_c1_0->name ');
is($test_c1_0->usage,'smtp send to=joe@example.com from=jane@example.com subject=Hi body="hi"', '$test_c1_0->usage');
is($test_c1_0->help,'smtp client to send mail', '$test_c1_0->help ');
is($test_c1_0->topic,'net', '$test_c1_0->topic get');
is($test_c1_0->command,'tcli_'.$testee, '$test_c1_0->command  ');
is($test_c1_0->handler,'establish_context', '$test_c1_0->handler  ');
is($test_c1_0->call_style,'session', '$test_c1_0->call_style ');


$t->is_body('smtp','Context now: smtp','Context now: smtp');
$t->ok('set to=testing@example.com');
$t->like_body('show to',qr(testing\@example.com));
$t->ok('set from=testee@example.com');
$t->like_body('show from',qr(testee\@example.com));
$t->ok('set subject="Test Message"');
$t->like_body('show subject',qr(Test Message));

$t->like_body('show server',qr(localhost));
$t->ok('set server=127.0.0.1');
$t->like_body('show server',qr(127.0.0.1));
$t->ok('set server=localhost');
$t->like_body('show server',qr(localhost));

$t->like_body('show port',qr(25));
$t->ok('set port=925');
$t->like_body('show port',qr(925));
$t->ok('set port=25');
$t->like_body('show port',qr(25));

# Bad cases
$t->not_ok('set port=smtp');


$test_master->run;

