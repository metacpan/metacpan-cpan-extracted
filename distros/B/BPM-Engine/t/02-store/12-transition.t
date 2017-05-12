use strict;
use warnings;
use Test::More;
use Test::Exception;
use t::TestUtils;

use BPM::Engine;
use BPM::Engine::Store;
use DateTime;
use Data::Dumper;

#-- OR inclusive join
# after all valid transitions join fires
my $x = '<Activities>
                <Activity Id="A">
                    <TransitionRestrictions>
                        <TransitionRestriction>
                            <Split Type="Inclusive">
                                <TransitionRefs>
                                    <TransitionRef Id="A-B"/>
                                    <TransitionRef Id="A-C"/>
                                </TransitionRefs>
                            </Split>
                        </TransitionRestriction>
                    </TransitionRestrictions>
                </Activity>
                <Activity Id="B" StartMode="Manual" FinishMode="Manual">
                    <TransitionRestrictions>
                        <TransitionRestriction>
                            <Split Type="Inclusive">
                                <TransitionRefs>
                                    <TransitionRef Id="B-C"/>
                                    <TransitionRef Id="B-D"/>
                                </TransitionRefs>
                            </Split>
                        </TransitionRestriction>
                    </TransitionRestrictions>
                </Activity>
                <Activity Id="C" StartMode="Manual" FinishMode="Manual">
                    <TransitionRestrictions>
                        <TransitionRestriction>
                            <Join Type="Inclusive"/>
                        </TransitionRestriction>
                    </TransitionRestrictions>
                </Activity>
                <Activity Id="D" StartMode="Manual" FinishMode="Manual">
                    <TransitionRestrictions>
                        <TransitionRestriction>
                            <Join Type="Inclusive"/>
                        </TransitionRestriction>
                    </TransitionRestrictions>
                </Activity>
            </Activities>
            <Transitions>
                <Transition Id="A-B" From="A" To="B"/>
                <Transition Id="A-C" From="A" To="C"/>
                <Transition Id="B-C" From="B" To="C"/>
                <Transition Id="B-D" From="B" To="D"/>
                <Transition Id="C-D" From="C" To="D"/>
            </Transitions>
    ';

#$x =~ s/StartMode="Manual" FinishMode="Manual"//g;
my ($engine, $process) = process_wrap($x);
ok($process);

my $aiA = $process->start_activities->[0]->new_instance({
    process_instance_id => $process->new_instance->id
    });

my $tAB = $process->transitions->find({ transition_uid => 'A-B' });
my $tAC = $process->transitions->find({ transition_uid => 'A-C' });
my $tBC = $process->transitions->find({ transition_uid => 'B-C' });
my $tBD = $process->transitions->find({ transition_uid => 'B-D' });
my $tCD = $process->transitions->find({ transition_uid => 'C-D' });

#-- check roles

my $t_meta = $tAB->meta;
ok($t_meta->does_role('BPM::Engine::Store::ResultBase::ProcessTransition'), '... Transition->meta does_role Store::ResultBase::ProcessTransition');
ok($t_meta->does_role('BPM::Engine::Store::ResultRole::TransitionCondition'), '... Transition->meta does_role Store::ResultRole::TransitionCondition');
ok(!$t_meta->does_role('Class::Workflow::Transition'), '... Transition->meta does not do role Class::Workflow::Transition');
ok(!$t_meta->does_role('Class::Workflow::Transition::Validate::Simple'), '... Transition->meta does not do role Class::Workflow::Transition::Validate::Simple');
ok(!$t_meta->does_role('Class::Workflow::Transition::Deterministic'), '... Transition->meta does not do role Class::Workflow::Transition::Deterministic');
ok(!$t_meta->does_role('Class::Workflow::Transition::Strict'), '... Transition->meta does not do role Class::Workflow::Transition::Strict');

#-- step through the process

# before apply
$tAB->clear_validators();
$tAB->add_validator(sub {
    my ($transition, $activity_instance, $cmd) = @_;
    die("No command") unless $cmd;
    die("Something wrong") if $cmd eq 'die';
    return 0 if $cmd eq 'false';
    return 1 if $cmd eq 'true';
    die("Wrong command $cmd");
    });
# around apply
ok($tAB->validate($aiA, 'true')); # condition true
throws_ok(sub { $tAB->validate($aiA, 'false') }, 'BPM::Engine::Exception::Condition', 'condition false');
throws_ok(sub { $tAB->validate($aiA, 'false') }, qr/Condition\s+\(boolean\)\s+false/, 'condition false');
throws_ok(sub { $tAB->validate($aiA, 'die') }, qr/wrong/, 'dies ok');
throws_ok(sub { $tAB->validate($aiA, 'die') }, 'BPM::Engine::Exception', 'dies ok');
throws_ok(sub { $tAB->validate($aiA) }, qr/No command/, 'dies ok');
throws_ok(sub { $tAB->validate($aiA) }, 'BPM::Engine::Exception', 'dies ok');
$tAB->clear_validators();

# apply with false condition
$tAB->update({
    condition_expr => '1 + 2 - 3',
    condition_type => 'CONDITION',
    });
ok(!eval { $tAB->apply($aiA); });
throws_ok(sub { $tAB->apply($aiA) }, qr/Condition\s+\(boolean\)\s+false/);
throws_ok(sub { $tAB->apply($aiA) }, 'BPM::Engine::Exception::Condition');

$tAB->update({ condition_expr => 'Some string' });
throws_ok(sub { $tAB->apply($aiA) }, qr/Expected a semicolon or block end, but got 'string'/);
throws_ok(sub { $tAB->apply($aiA) }, 'BPM::Engine::Exception::Expression');

$tAB->update({ condition_expr => '"Some string"' });
throws_ok(sub { $tAB->apply($aiA) }, qr/not a number/);
throws_ok(sub { $tAB->apply($aiA) }, 'BPM::Engine::Exception::Expression');

$tAB->update({ condition_expr => '3' });
throws_ok(sub { $tAB->apply($aiA) }, qr/not boolean/);
throws_ok(sub { $tAB->apply($aiA) }, 'BPM::Engine::Exception::Expression');

$tAB->update({ condition_type => 'NONE' });

my $aiB = eval { $tAB->apply($aiA); };
ok($aiB);

my $aiC = eval { $tAC->apply($aiA); };

$aiC = eval { $tBC->apply($aiB); };
ok($aiC);
ok(!$aiC->is_enabled);

my $aiD = eval { $tBD->apply($aiB); };
#ok($aiC->is_enabled);

$aiD = eval { $tCD->apply($aiC); };
ok($aiD);
ok(!$aiD->is_enabled);    

done_testing();
