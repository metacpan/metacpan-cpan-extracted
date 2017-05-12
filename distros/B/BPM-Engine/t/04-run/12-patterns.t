use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Moose;
use t::TestUtils;

no warnings 'redefine';
sub diag {}
use warnings;

use BPM::Engine;
use BPM::Engine::Logger;

my $DEBUG = 0;

ok(my $engine = BPM::Engine->new(
  #logger => BPM::Engine::Logger->new,
  #log_dispatch_conf => 't/etc/log_screen.conf',
  log_dispatch_conf => {
    class     => 'Log::Dispatch::Screen',
    min_level => $DEBUG ? 'debug' : 'warning',
    stderr    => 1,
    format    => '[%p] %m at %F line %L%n',
    },
  schema => schema(),
  callback => sub {
    my($runner, $entity, $event, $node, $instance) = @_;

    my $act = $entity eq 'process' ? $node->process_uid : $instance->activity->activity_uid;
    #warn "$event $entity $act";
#return 0 if($entity eq 'process' && $event eq 'complete');
    return 1 unless($entity eq 'activity' && $event eq 'execute');

    #isa_ok($node,     'BPM::Engine::Store::Result::ActivityTask');
    #isa_ok($instance, 'BPM::Engine::Store::Result::ActivityInstance');

    my $pi = $instance->process_instance;
    my $taken = $pi->attribute('pathtaken')->value || '';
    $taken = $taken->[0] if(ref($taken));
    $taken .= '-' if $taken;

    my @act = split(/\./, $node->activity_uid);
    my $act_id = pop(@act);
    $pi->attribute('pathtaken', $taken . $act_id);

    # repeat+while loops
    if($pi->process->process_uid =~ /^wcp21/ && $act_id eq 'A') {
        $pi->attribute(cycle => $pi->attribute('cycle')->value - 1);
        }
    # nested-loops
    elsif($pi->process->process_uid eq 'wcp10b2') {
        $pi->attribute(inner_loop => $pi->attribute('inner_loop')->value - 1) if $act_id eq 'B-OR-Join';
        $pi->attribute(outer_loop => $pi->attribute('outer_loop')->value - 1) if $act_id eq 'A-XOR-Join';
        }

    return 1;
    },
  ));
my($package, $process);

##$package = $engine->get_packages({ package_uid => '01-basic.xpdl'})->first;
##$process = $engine->get_process_definitions({ package_id => $package->id, process_uid => 'wcp1' })->first;

#-- basic patterns
if(1) {
$package = $engine->create_package('./t/var/01-basic.xpdl');

# wcp1
diag('sequence');
ok($process = $package->processes({ process_uid => 'wcp1' })->first);
is(sequence_for(), 'A-B-C', 'wcp1 sequence matches');

# wcp2
diag('parallel split (AND-split) and synchronization (AND-join)');
$process = $package->processes({ process_uid => 'wcp2' })->first;
is(sequence_for(), 'A-B-C-D', 'wcp2 sequence matches');

# wcp4
diag('exclusive choice (XOR-split) + simple merge (XOR-join)');
$process = $package->processes({ process_uid => 'wcp4' })->first;
is(sequence_for(WhereToGo => 'B'), 'A-B-E', 'wcp4 sequence matches');
is(sequence_for(WhereToGo => 'C'), 'A-C-E', 'wcp4 sequence matches');
is(sequence_for(), 'A-D-E', 'wcp4 sequence matches');
#} 'no memory leaks';

#*

}

#-- branching & sync
if(1) {
$package = $engine->create_package('./t/var/02-branching.xpdl');

# wcp6
diag('Multiple Choice (OR-split) and Structured Synchronizing Merge (OR-join)');
$process = $package->processes({ process_uid => 'wcp6' })->first;
is(sequence_for(), 'A-GW1-D-GW2-E', 'wcp6 sequence matches');
is(sequence_for(do_B => 0, do_C => 0), 'A-GW1-D-GW2-E', 'wcp6 sequence matches');
is(sequence_for(do_B => 1), 'A-GW1-B-GW2-E', 'wcp6 sequence matches');
is(sequence_for(do_C => 1), 'A-GW1-C-GW2-E', 'wcp6 sequence matches');
is(sequence_for(do_B => 0, do_C => 1), 'A-GW1-C-GW2-E', 'wcp6 sequence matches');
is(sequence_for(do_B => 1, do_C => 1), 'A-GW1-B-C-GW2-E', 'wcp6 sequence matches');

# wcp8
diag('Multi Merge (AND/OR-split + XOR-join)');
$process = $package->processes({ process_uid => 'wcp8' })->first;
throws_ok { sequence_for() } qr/deadlock/i, 'deadlock caught okay'; # OTHERWISE transition missing
is(sequence_for(WhereToGo => 'B'), 'Start-A-B-E-End', 'wcp8 sequence matches');
is(sequence_for(WhereToGo => 'BC'), 'Start-A-B-C-E-E-End-End', 'wcp8 sequence matches');
is(sequence_for(WhereToGo => 'BCD'), 'Start-A-B-C-D-E-E-E-End-End-End', 'wcp8 sequence matches');
}

if(1) {
# wcp37
diag('Local Synchronizing Merge (acyclic OR-splits/joins)');
$process = $package->processes({ process_uid => 'wcp37' })->first;
is(sequence_for(), 'MC-A-SM-End', 'wcp37 sequence matches');
is(sequence_for(multi_choice => 'BC'), 'MC-B-C-DC-E-SM-End', 'wcp37 sequence matches');
is(sequence_for(multi_choice => 'BC', deferred_choice => 'D'), 'MC-B-C-DC-D-SM-End', 'wcp37 sequence matches');

# wcp38
diag('General Synchronizing Merge (cyclic OR-splits/joins)');
$process = $package->processes({ process_uid => 'wcp38' })->first;
is(sequence_for(), 'MC-A-SM-End', 'wcp38 sequence matches');
#is(sequence_for(), 'MC-A-B-C-SM-DC-D-E-SM-End', 'wcp38 sequence matches');
}

#-- iteration
if(1) {
$package = $engine->create_package('./t/var/06-iteration.xpdl');
if(1){
# wcp21
diag('Structured Loop (Pre-Test, while-loop)');
ok($process = $package->processes({ process_uid => 'wcp21a' })->first);
is(sequence_for(cycle => 0), 'Start-A-B-End', 'sequence matches');
is(sequence_for(cycle => 1), 'Start-A-B-End', 'sequence matches');
is(sequence_for(cycle => 2), 'Start-A-B-C-A-B-End', 'sequence matches');

# wcp21
diag('Structured Loop (Post-Test, repeat-loop)');
ok($process = $package->processes({ process_uid => 'wcp21b' })->first);
is(sequence_for(cycle => 0), 'Start-A-B-C-D', 'sequence matches');
is(sequence_for(cycle => 1), 'Start-A-B-C-D', 'sequence matches');
is(sequence_for(cycle => 2), 'Start-A-B-C-A-B-C-D', 'sequence matches');
is(sequence_for(cycle => 3), 'Start-A-B-C-A-B-C-A-B-C-D', 'sequence matches');
}

# wcp10
diag('Arbitrary Cycles - nested loops');
ok($process = $package->processes({ process_uid => 'wcp10b2' })->first);
is(sequence_for(outer_loop => 0, inner_loop => 0), 'Start-A-XOR-Join-B-OR-Join-C-OR-Split-D-XOR-Split-End', 'sequence matches');
is(sequence_for(outer_loop => 2, inner_loop => 0), 'Start-A-XOR-Join-B-OR-Join-C-OR-Split-D-XOR-Split-A-XOR-Join-B-OR-Join-C-OR-Split-D-XOR-Split-End', 'sequence matches');
}

#-- termination
#$package = $engine->create_package('./t/var/07-termination.xpdl');

undef $package;
undef $process;
undef $engine;

done_testing();

sub sequence_for {
    my %args = @_;

    my $pi = $engine->create_process_instance($process->id);
    $engine->start_process_instance($pi, \%args);

    is($pi->workflow_instance->state->name, 'closed.completed', $process->process_uid . ' completed');

    my $path_taken = $pi->attribute('pathtaken')->value;
    #$pi->delete();
    return $path_taken;
    }

