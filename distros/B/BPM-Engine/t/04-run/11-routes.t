use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Moose;
use t::TestUtils;

use BPM::Engine;

no warnings 'redefine';
sub diag {}
use warnings;

my $testfailed = 0;
ok(my $engine = BPM::Engine->new(
  log_dispatch_conf => {
    class     => 'Log::Dispatch::Screen',
    min_level => 'warning',
    stderr    => 1,
    format    => '[%p] %m at %F line %L%n',
    },
  schema => schema(),
  callback => sub {
    my($runner, $entity, $event, $node, $instance) = @_;

    my $act = $entity eq 'process' ? $node->process_uid : $instance->activity->activity_uid;
    #warn "$event $entity $act";

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

    #$pi->attribute(run_test2 => 1);
    if($pi->process->process_uid eq 'production' && $act_id eq 'Test1') {
        if($pi->attribute('test1_ok')->value) {
            #$pi->attribute(test1_ok => 0);
            #$pi->attribute(test2_ok => 0);
            }
        elsif($testfailed) {
            $pi->attribute(test1_ok => 1);
            $pi->attribute(test2_ok => 1);
            }
        $testfailed++;
        }

    return 1;
    },
  ));

my($package, $process);

#-- Samples

ok($package = $engine->create_package('./t/var/08-samples.xpdl'));

diag('unstructured-inclusive-tasks');
ok($process = $package->processes({ process_uid => 'unstructured-inclusive-tasks' })->first);
is(sequence_for( splitA => 'B1',  splitB => 'B1'), 'A-B1-B2-C-D',   'sequence matches');
is(sequence_for( splitA => undef, splitB => ''  ), 'A-B-B1-B2-C-D', 'sequence matches');
is(sequence_for( splitA => undef, splitB => 'B1'), 'A-B-B1-B2-C-D', 'sequence matches');
is(sequence_for( splitA => 'B',   splitB => 'C' ), 'A-B-C-D',       'sequence matches');

diag('inclusive-splits-and-joins');
ok$process = $package->processes({ process_uid => 'inclusive-splits-and-joins' })->first;
is(sequence_for( splitA => 'B',   splitB => 'D', splitC => undef  ), 'A-B-D-E-F',     'sequence matches');
is(sequence_for( splitA => undef,   splitB => undef, splitC => undef  ), 'A-B-C-D-E-F',     'sequence matches');


diag('mixed-join');
$process = $package->processes({ process_uid => 'mixed-join' })->first;
is(sequence_for(), 'Start-End', 'sequence matches');
is(sequence_for(data_ok => 0), 'Start-End', 'sequence matches');
is(sequence_for(data_ok => 1), 'Start-A-B-C-D-E-End', 'sequence matches');

#diag('deadlock');

diag('production');
ok($process = $package->processes({ process_uid => 'production' })->first);
is(sequence_for(run_test2 => 1), 'Start-Assemble-Join1-Configure-Test1-Split1-Test2-Split2-Join1-Configure-Test1-Split1-Test2-Split2-Join2-Package-End', 'sequence matches');
is(sequence_for(run_test2 => 1, test2_ok => 1), 'Start-Assemble-Join1-Configure-Test1-Split1-Test2-Split2-Join2-Package-End', 'sequence matches');
is(sequence_for(run_test2 => 0, test1_ok => 1, test2_ok => 1), 'Start-Assemble-Join1-Configure-Test1-Split1-Join2-Package-End', 'sequence matches');
#is(sequence_for(run_test2 => 0, test1_ok => 0, test2_ok => 1), 'Start-Assemble-Join1-Configure-Test1-Split1-Join2-Package-End', 'sequence matches');

#ok($package = $engine->create_package('./t/var/01-basic.xpdl'));
#ok($package = $engine->create_package('./t/var/02-branching.xpdl'));
#ok($package = $engine->create_package('./t/var/07-termination.xpdl'));

undef $package;
undef $process;
undef $engine;

done_testing();


sub sequence_for {
    my %args = @_;
    my $pi = $engine->create_process_instance($process->id);
    $engine->start_process_instance($pi, \%args);
    is($pi->workflow_instance->state->name, 'closed.completed', $process->process_uid . ' completed');
    return $pi->attribute('pathtaken')->value;
    }

