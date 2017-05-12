#!/usr/bin/env perl
# $Id: TCLI.Package.Tail.t 49 2007-04-25 10:32:36Z hacker $

use Test::More qw(no_plan);
use warnings;
use strict;

use Getopt::Lucid qw(:all);

my ($opt, $verbose, $poe_td, $poe_te);

eval {$opt = Getopt::Lucid->getopt([
		Counter("poe_debug|d"),
		Counter("poe_event|e"),
		Counter("verbose|v"),
		Switch("blib|b"),
	])};
if($@) {die "ERROR: $@";}

if ($opt->get_blib)
{
	use lib 'blib/lib';
}

print "opt->get_verbose(".$opt->get_verbose." )\n";

$verbose = $opt->get_verbose ? $opt->get_verbose  : 0;

print "verbose(".$verbose." )\n";

# xmpp username/password to log in with
$poe_td = $opt->get_poe_debug;
$poe_te = $opt->get_poe_event;

sub POE::Kernel::TRACE_DEFAULT  () { $poe_td }
sub POE::Kernel::TRACE_EVENTS  () { $poe_te }

use Agent::TCLI::Transport::Test;
use Agent::TCLI::Testee;
use POE;

use Agent::TCLI::Package::Tail;

my $testpackage = Agent::TCLI::Package::Tail->new({
	'verbose'		=> \$verbose,
	'do_verbose'	=> sub { diag( @_ ) },
	});


my $test1 = Agent::TCLI::Transport::Test->new({
    'verbose'   	=> \$verbose,        # Verbose sets level or warnings
	'do_verbose'	=> sub { diag( @_ ) },

    'control_options'	=> {
	     'packages' 	=> [ $testpackage, ],
    },
});

my $testee = Agent::TCLI::Testee->new(
	'test_master'	=> $test1,
	'addressee'		=> 'self',
);

# Initialization
is($test1->alias,'transport_test', '$test1->Name ');
is($test1->testees->[0]->addressee,'self','testee loaded ok');
is($test1->control_options->{'packages'}[0]->name,'tcli_tail','package loaded ok');

# Test verbose  methods
# Not happy. Disabling until I figure out if this is an OIO bug or not.
#is($test1->verbose, $verbose, '$test1->verbose get from init args');
#print "test1->verbose(".$test1->verbose." )\n";
#print "testee->verbose(".$testee->verbose." )\n";
#print "testpackage->verbose(".$testpackage->verbose." )\n";


ok($test1->verbose(1),'$test1->verbose set ');
is($test1->verbose ,1, '$test1->verbose get from set');
like($test1->Verbose("ok"),qr(ok),'$test1->Verbose returns ok');

is($test1->verbose(0),0,'$test1->verbose set 0');
is($test1->verbose,0,'$test1->verbose get from set');
is($test1->Verbose("ok"),undef,'$test1->Verbose returns undef');

ok($test1->verbose(\$verbose),'$test1->verbose set back');

$testee->ok('status');

my $status = $testee->get_responses('',5);

like($status,qr(TCLI.Transport.Test.t),'responses retrieved');






$test1->run;
