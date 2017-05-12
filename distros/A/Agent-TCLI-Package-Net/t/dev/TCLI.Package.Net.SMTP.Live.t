#!/usr/bin/env perl
# $Id: TCLI.Package.Net.SMTP.Live.t 74 2007-06-08 00:42:53Z hacker $

# This test requires that the system be running a SMTP daemon on
# localhost at port 25. Without changes, it will generate emails
# to the author, which won't do anyone else much good.

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

$t->is_body('smtp','Context now: smtp','Context now: smtp');
$t->ok('set to=hacker@testing.erichacker.com');
$t->ok('set from=testee@testing.erichacker.com');
$t->ok('set subject="Test Body Message"');
$t->ok('send body="test 1"');
$t->ok('set subject="Test File Message"');
$t->ok('sendtext textfile="Build.PL"');

$t->ok('set subject="Test Msg Message"');
$t->ok('sendmsg msgfile="t/dev/email.wmsg"');

# Other address formats
$t->ok('set from="\"Testee\" <testee@testing.erichacker.com>"');
$t->ok('send subj="test address escaped quotes"');

$t->ok('set from="\"Testee Jr\" <testee@testing.erichacker.com>"');
$t->ok('send subj="test address escaped quotes with space"');

$t->ok('set from="Testee Jr <testee@testing.erichacker.com>"');
$t->ok('send subj="test address space no quotes"');


# fail for noexistant file
$t->not_ok('sendtext textfile="DONTREADME"');

# fail for bad address
$t->not_ok('set from="Testee testee@testing.erichacker.com"');



$test_master->run;

