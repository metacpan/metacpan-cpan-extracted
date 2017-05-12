use strict;
use warnings;
use Test::More;
use Test::Exception;
use t::TestUtils;

use BPM::Engine;
use BPM::Engine::Store;
use DateTime;
use Data::Dumper;

my ($engine, $process);

# samples.xpdl
#-----------------------------------------------
$engine = BPM::Engine->new(schema => schema());
$engine->create_package('./t/var/08-samples.xpdl');

# unstructured-inclusive-tasks - OR split/join
if(1) {
    my ($r,$p,$i) = runner($engine, 'unstructured-inclusive-tasks', { splitA => 'B1', splitB => undef });

    my $activity = $p->start_activities->[0];
    my $ai_A = #$r->_create_activity_instance($activity);
        $activity->new_instance({ 
                process_instance_id => $i->id 
                });
    # main path (before splitted or after joined) doesn't have a parent_token
    # OR any ai not directly after a split doesn't have a parent_token, use ->prev instead ??
    #ok(!$ai_A->parent_token_id, 'A has no parent');
    #ok(!$ai_A->prev, 'A has no previous');

# B1-JOIN

    #- follow transition A-B1 (split->join)
    #-----------------------------------------
    ok(my $t_A_B1 = $activity->transitions->find({ transition_uid => 'ex4.A-B1'}));    
    ok(my $a_B1 = $t_A_B1->to_activity);

    ok(my $t_A_B = $activity->transitions->find({ transition_uid => 'ex4.A-B'}));
    ok(my $a_B = $t_A_B->to_activity);

    ok(my $t_B_B1 = $a_B->transitions->find({ transition_uid => 'ex4.B-B1'}));
    ok(my $t_B1_B2 = $a_B1->transitions->find({ transition_uid => 'ex4.B1-B2'}));
    ok(my $a_B2 = $t_B1_B2->to_activity);

    ok(my $t_B_C = $a_B->transitions->find({ transition_uid => 'ex4.B-C'}));
    ok(my $t_B2_C = $a_B2->transitions->find({ transition_uid => 'ex4.B2-C'}));
    ok(my $a_C = $t_B_C->to_activity);

    ok(my $t_B2_D = $a_B2->transitions->find({ transition_uid => 'ex4.B2-D'}));
    ok(my $t_C_D = $a_C->transitions->find({ transition_uid => 'ex4.C-D'}));
    ok(my $a_D = $t_B2_D->to_activity);

    my $attrs = { activity => $a_B1,  };
    my @args = ();

    my $ai_B1 = $t_A_B1->derive_and_accept_instance($ai_A, $attrs, @args);
    is($ai_B1->activity->activity_uid, 'ex4.B1','derive_and_accept results in B1');

    # transition in joinA set to 'taken' since we're coming from a split    
    is($ai_A->split->states->{$t_A_B1->id}, 'taken', "Transition A-B1 state is 'taken'");

    # after a split, the parent_token of the new ai is set to the split-ai
    #is($ai_B1->parent_token_id, $ai_A->id, 'Parent matches');
    #is($ai_B1->parent->id, $ai_A->id, 'Parent matches');
    is($ai_B1->prev->id, $ai_A->id, 'Prev matches');

    # join B1 should not fire, since although we didn't follow the path from A to B, A-B was not blocked either
  # TODO: verify this is not a problem in runner!!
    ok(!$ai_B1->is_enabled(), 'Join B1 should not fire');

    # set A-B blocked, and see B1 enabled
    $ai_A->split->discard_changes();
    my $states = $ai_A->split->states;
    $states->{$t_A_B->id} = 'blocked';
    $ai_A->split->update({ states => $states })->discard_changes;
    $ai_A->update({ completed => DateTime->now() });

    ok($ai_B1->is_enabled(), 'Join B1 should fire');

    is($ai_A->split->states->{$t_A_B->id}, 'blocked', "Transition A-B state is 'blocked'");
    is($ai_A->split->states->{$t_A_B1->id}, 'taken', "Transition A-B1 state is 'taken'");
    is($ai_B1->prev->split->states->{$t_A_B1->id}, 'taken', "Transition A-B1 state is 'taken'");

    $ai_A->update({ completed => \'NULL' })->discard_changes;
    delete $states->{$t_A_B->id};
    $ai_A->split->update({ states => $states })->discard_changes;
    ok(!$ai_B1->is_enabled(), 'Join B1 should not fire');

    $ai_B1->update({ deferred => DateTime->now() });

    #- follow transition A-B (split->split)
    #-----------------------------------------
    $attrs = { activity => $a_B  };
    @args = ();

    $ai_A->update({ completed => DateTime->now() });
    my $ai_B = $t_A_B->derive_and_accept_instance($ai_A, $attrs, @args);
    is($ai_B->activity->activity_uid, 'ex4.B','derive_and_accept results in B');

    # transition in joinA set to 'taken' since we're coming from a split    
    $ai_A->split->discard_changes();
    is($ai_A->split->states->{$t_A_B->id}, 'taken', "Transition A-B state is 'taken'");
    is($ai_A->split->states->{$t_A_B1->id}, 'taken', "Transition A-B1 state is 'taken'");

    # now join B1 should NOT fire, since the path from A to B didn't come in yet
    ok(!$ai_B1->is_enabled(), 'Join B1 should not fire anymore');

    #- follow transition B-B1 (split->join)
    #-----------------------------------------
    $attrs = { activity => $a_B1 }; # $t_B_B1->to_activity
    @args = ();

    $ai_B->update({ completed => DateTime->now() });
    my $ai_B1b = $t_B_B1->derive_and_accept_instance($ai_B, $attrs, @args);
    is($ai_B1b->activity->activity_uid, 'ex4.B1','derive_and_accept results in B1');

    # transition in join-for-split set to 'taken'
    is($ai_B->split->states->{$t_B_B1->id}, 'taken');

    # join B1 should now fire, as seen from all sides
    ok($ai_B1b->is_enabled(), 'Join B1b should also fire');
    #ok($ai_B1->is_enabled(), 'Join B1 should now fire again');

    # fire the join
    ok($ai_B1->is_deferred);
    ok($ai_B1b->is_active);
    #$ai_B1->fire_join();
    $ai_B1b->fire_join();
   #is($ai_A->split->states->{$t_A_B->id}, 'joined', "Transition A-B state is 'joined'");
   #is($ai_A->split->states->{$t_A_B1->id}, 'joined', "Transition A-B1 state is 'joined'");
   #is($ai_B1->prev->split->states->{$t_A_B1->id}, 'joined', "Transition A-B1 state is 'joined'");
   #is($ai_B->split->states->{$t_B_B1->id}, 'joined');
    ok($ai_B->is_completed);
   #ok($ai_B1->is_completed);
    ok($ai_B1b->is_active);    

# C-JOIN

    #- follow transition B1-B2 (join->split)
    #-----------------------------------------
    $attrs = { activity => $a_B2  };

    $ai_B1b->update({ completed => DateTime->now() });
    ok($ai_B1b->is_completed);
    my $ai_B2 = $t_B1_B2->derive_and_accept_instance($ai_B1b, $attrs, @args);
    is($ai_B2->activity->activity_uid, 'ex4.B2','derive_and_accept results in B2');

    #- follow transition B-C (split->join)
    #-----------------------------------------
    $attrs = { activity => $a_C  };

    my $ai_C = $t_B_C->derive_and_accept_instance($ai_B, $attrs, @args);
    is($ai_C->activity->activity_uid, 'ex4.C','derive_and_accept results in C');    

    ok(!$ai_C->is_enabled(), 'Join C should not fire yet');
    $ai_C->update({ deferred => DateTime->now() });

    #- follow transition B2-C (split->join)
    #-----------------------------------------
    $attrs = { activity => $t_B2_C->to_activity,  };

    $ai_B2->update({ completed => DateTime->now() });
    my $ai_Cb = $t_B2_C->derive_and_accept_instance($ai_B2, $attrs, @args);
    is($ai_Cb->activity->activity_uid, 'ex4.C','derive_and_accept results in C');

    # join C should now fire from either B or B2
    ok($ai_Cb->is_enabled(), 'Join C should now fire');
    #ok($ai_C->is_enabled(), 'Join C should now fire');

    # fire the join
    $ai_Cb->fire_join();

# D-JOIN

    #- follow transition B2-D (split->join)
    #-----------------------------------------
    $attrs = { activity => $a_D  };

    # join D should not fire, path C-D hasn't come in yet
    #ok(!$a_D->should_join_fire($t_B2_D, $ai_B2), 'Join should not fire from B2');
    
    $ai_B2->update({ completed => DateTime->now() });
    my $ai_D = $t_B2_D->derive_and_accept_instance($ai_B2, $attrs, @args);
    is($ai_D->activity->activity_uid, 'ex4.D','derive_and_accept results in D');

    ok(!$ai_D->is_enabled(), 'Join D should not fire yet');
    $ai_D->update({ deferred => DateTime->now() });
    
    #- follow transition C-D (join->join)
    #-----------------------------------------
    $attrs = { activity => $a_D,  };

    # join D should now fire
    #ok($a_D->should_join_fire($t_C_D, $ai_C), 'Join D should fire from C');
    # and also from B2, now
    #ok($a_D->should_join_fire($t_B2_D, $ai_B2), 'Join D should fire from B2'); # SHOULD DIE DOUBLE DIP

    $ai_Cb->update({ completed => DateTime->now() });
    my $ai_Db = $t_C_D->derive_and_accept_instance($ai_Cb, $attrs, @args);
    is($ai_Db->activity->activity_uid, 'ex4.D','derive_and_accept results in D');

    ok($ai_Db->is_enabled(), 'Join D should now fire');
    #$ai_Db->fire_join();
}


# OR split/join
if(000) {
    $engine = BPM::Engine->new(schema => schema());
    #$engine->create_package('./t/var/04-or-split-and-join.xpdl');

    my ($r,$p,$i) = runner($engine, 'inclusive-split-and-join', { splitA => 'B1', splitB => undef });
    my @args = ();

    my $tAB = $p->transitions->find({ transition_uid => 'A-B' });
    my $tAC = $p->transitions->find({ transition_uid => 'A-C' });
    my $tBD = $p->transitions->find({ transition_uid => 'B-D' });
    my $tCD = $p->transitions->find({ transition_uid => 'C-D' });

    my $aA = $p->activities->find({ activity_uid => 'A' });
    my $aB = $p->activities->find({ activity_uid => 'B' });
    my $aC = $p->activities->find({ activity_uid => 'C' });
    my $aD = $p->activities->find({ activity_uid => 'D' });

    #my $activity = $p->start_activities->[0];
    my $ai_A = $aA->new_instance({ 
                process_instance_id => $i->id 
                });

    my $ai_B = $tAB->derive_and_accept_instance($ai_A, { activity => $aB }, @args);
    is($ai_B->activity->activity_uid, 'B','derive_and_accept results in B');
    #warn Dumper $ai_A->split->states;

    my $ai_C = $tAC->derive_and_accept_instance($ai_A, { activity => $aC }, @args);
    is($ai_C->activity->activity_uid, 'C','derive_and_accept results in C');
    #warn Dumper $ai_A->split->states;

    my $ai_D = $tBD->derive_and_accept_instance($ai_B, { activity => $aD }, @args);
    is($ai_D->activity->activity_uid, 'D','derive_and_accept results in D');

    my $ai_D2 = $tCD->derive_and_accept_instance($ai_C, { activity => $aD }, @args);
    is($ai_D2->activity->activity_uid, 'D','derive_and_accept results in D');
}                

if(1) {
    my ($r,$p,$i) = runner($engine, 'multi-inclusive-split-and-join', { splitA => 'B1', splitB => undef });
    my @args = ();

    my $tAB  = $p->transitions->find({ transition_uid => 'ex1.A-B' });
    my $tAB1 = $p->transitions->find({ transition_uid => 'ex1.A-B1' });
    my $tBB1 = $p->transitions->find({ transition_uid => 'ex1.B-B1' });
    my $tBC  = $p->transitions->find({ transition_uid => 'ex1.B-C' });
    my $tB1D = $p->transitions->find({ transition_uid => 'ex1.B1-D' });
    my $tCD  = $p->transitions->find({ transition_uid => 'ex1.C-D' });

    my $aA  = $p->activities->find({ activity_uid => 'ex1.A' });
    my $aB  = $p->activities->find({ activity_uid => 'ex1.B' });
    my $aB1 = $p->activities->find({ activity_uid => 'ex1.B1' });
    my $aC  = $p->activities->find({ activity_uid => 'ex1.C' });
    my $aD  = $p->activities->find({ activity_uid => 'ex1.D' });

    my $ai_A = $aA->new_instance({ 
                process_instance_id => $i->id 
                });
    #ok(!$ai_A->split->should_fire($tAB, 1)); # dies with transition not taken

    # A-B
    $ai_A->update({ completed => DateTime->now() }); # normally done in processrunner complete_activity
    my $ai_B = $tAB->derive_and_accept_instance($ai_A, { activity => $aB }, @args);
    is($ai_B->activity->activity_uid, 'ex1.B','derive_and_accept results in B');

    # trans A-B set to 'taken'
    is(scalar keys %{ $ai_A->split->states }, 1);
    is($ai_A->split->states->{2}, 'taken');
    # split not complete yet, this should not make sense at this point
    ok(!$ai_A->split->should_fire($tAB, 1)); # not joined yet

    # A-B1
    my $ai_B1a = $tAB1->derive_and_accept_instance($ai_A, { activity => $aB1 }, @args);
    is($ai_B1a->activity->activity_uid, 'ex1.B1','derive_and_accept results in B1');

#    is($ai_A->split->states->{1}, 'taken');
#    is($ai_A->split->states->{2}, 'taken');

    ok(!$ai_B1a->is_enabled(), 'Join B1 should not fire');
    ok(!$ai_B1a->is_enabled(), 'Join B1 should not fire');
    # trans A-B1 set to 'taken'
    $ai_A->split->discard_changes;
#    is($ai_A->split->states->{1}, 'joined');
#    is($ai_A->split->states->{2}, 'taken');
    ok(!$ai_A->split->should_fire($tAB1, 1));
    ok(!$ai_A->split->should_fire($tAB, 1));

    # B-B1
    $ai_B->update({ completed => DateTime->now() });
    my $ai_B1b = $tBB1->derive_and_accept_instance($ai_B, { activity => $aB1 }, @args);
    is($ai_B1b->activity->activity_uid, 'ex1.B1','derive_and_accept results in B1');

# is_enabled is always called after ALL split paths have been set to 'taken'
# by derive_and_accept_instance, meaning path B-C, so this is bogus:
    #ok($ai_B1a->is_enabled(), 'Join B1 should fire');
    #ok($ai_B1a->is_enabled(), 'Join B1 should fire');
#  ok($ai_B1b->is_enabled(), 'Join B1 should fire');
#  ok($ai_B1b->is_enabled(), 'Join B1 should fire');

    $ai_B1a->update({ completed => DateTime->now() });

#warn Dumper $ai_B->split->states;
# path B-C not taken yet

#    is($ai_B->split->states->{3}, 'taken');
    $ai_B->split->discard_changes;
#    is($ai_B->split->states->{3}, 'joined');
    is(scalar keys %{ $ai_B->split->states }, 1);

    # this is never called in real life
# ok($ai_B->split->should_fire($tBB1, 1)); # only one token

    # B-C
    my $ai_C = $tBC->derive_and_accept_instance($ai_B, { activity => $aC }, @args);
    is($ai_C->activity->activity_uid, 'ex1.C','derive_and_accept results in C');

#    ok($ai_C->is_reachable_from($aA));
#    ok($ai_C->is_reachable_from($aB));
#    ok(!$ai_C->is_reachable_from($aB1));    
#    ok(!$ai_C->is_reachable_from($aD));

    ok(!$ai_B->split->should_fire($tBB1, 1));
    ok(!$ai_B->split->should_fire($tBC, 1));

    # C-D
    $ai_C->update({ completed => DateTime->now() });
    my $ai_Db = $tCD->derive_and_accept_instance($ai_C, { activity => $aD }, @args);
    is($ai_Db->activity->activity_uid, 'ex1.D','derive_and_accept results in D');
    ok(!$ai_Db->is_enabled(), 'Join D should not fire');

    $ai_A->split->discard_changes;
# ok($ai_A->split->should_fire($tAB1, 1));
# ok($ai_A->split->should_fire($tAB, 1));
   

    # B1-D
    $ai_B1b->update({ completed => DateTime->now() });
    my $ai_Da = $tB1D->derive_and_accept_instance($ai_B1b, { activity => $aD }, @args);
    is($ai_Da->activity->activity_uid, 'ex1.D','derive_and_accept results in D');
#    ok($ai_Da->is_enabled(), 'Join D should fire');
#    ok($ai_Db->is_enabled(), 'Join D should fire');

#warn Dumper $ai_A->split->states;
}

if(1) {
    my ($r,$p,$i) = runner($engine, 'unstructured-inclusive-tasks', { splitA => 'B1', splitB => undef });
    my @args = ();

    ok(my $tAB  = $p->transitions->find({ transition_uid => 'ex4.A-B' }));
    ok(my $tAB1 = $p->transitions->find({ transition_uid => 'ex4.A-B1' }));
    ok(my $tBB1 = $p->transitions->find({ transition_uid => 'ex4.B-B1' }));
    ok(my $tBC  = $p->transitions->find({ transition_uid => 'ex4.B-C' }));
    ok(my $tB1B2 = $p->transitions->find({ transition_uid => 'ex4.B1-B2' }));
    ok(my $tB2C = $p->transitions->find({ transition_uid => 'ex4.B2-C' }));
    ok(my $tB2D = $p->transitions->find({ transition_uid => 'ex4.B2-D' }));
    ok(my $tCD  = $p->transitions->find({ transition_uid => 'ex4.C-D' }));

    ok(my $aA  = $p->activities->find({ activity_uid => 'ex4.A' }));
    ok(my $aB  = $p->activities->find({ activity_uid => 'ex4.B' }));
    ok(my $aB1 = $p->activities->find({ activity_uid => 'ex4.B1' }));
    ok(my $aB2 = $p->activities->find({ activity_uid => 'ex4.B2' }));
    ok(my $aC  = $p->activities->find({ activity_uid => 'ex4.C' }));
    ok(my $aD  = $p->activities->find({ activity_uid => 'ex4.D' }));

    #-- follow all transitions
  if(1) {
    my $ai_A = $aA->new_instance({ 
                process_instance_id => $i->id 
                });

    # A-B
    $ai_A->update({ completed => DateTime->now() }); # normally done in processrunner complete_activity
    my $ai_B = $tAB->derive_and_accept_instance($ai_A, { activity => $aB }, @args);
    is($ai_B->activity->activity_uid, 'ex4.B','derive_and_accept results in B');

    # trans A-B set to 'taken'
    is(scalar keys %{ $ai_A->split->states }, 1);
    is($ai_A->split->states->{$tAB->id}, 'taken');
    # split not complete yet, this should not make sense at this point
    ok(!$ai_A->split->should_fire($tAB, 1)); # not joined yet

    # A-B1
    my $ai_B1a = $tAB1->derive_and_accept_instance($ai_A, { activity => $aB1 }, @args);
    is($ai_B1a->activity->activity_uid, 'ex4.B1','derive_and_accept results in B1');

    is($ai_A->split->states->{$tAB1->id}, 'taken');
    is($ai_A->split->states->{$tAB->id}, 'taken');

    ok(!$ai_B1a->is_enabled(), 'Join B1 should not fire');
    $ai_B1a->update({ deferred => DateTime->now });
    
    # trans A-B1 set to 'taken'
    $ai_A->split->discard_changes;
    #is($ai_A->split->states->{$tAB1->id}, 'joined');
    is($ai_A->split->states->{$tAB->id}, 'taken');
    ok(!$ai_A->split->should_fire($tAB1, 1));
    ok(!$ai_A->split->should_fire($tAB, 1));

    # B-B1
    $ai_B->update({ completed => DateTime->now() });
    my $ai_B1b = $tBB1->derive_and_accept_instance($ai_B, { activity => $aB1 }, @args);
    is($ai_B1b->activity->activity_uid, 'ex4.B1','derive_and_accept results in B1');

    is($ai_B->split->states->{$tBB1->id}, 'taken');
    ok($ai_B1b->is_enabled(), 'Join B1 should fire');

    $ai_B1b->fire_join;
    is($ai_B->split->discard_changes->states->{$tBB1->id}, 'joined');
    is(scalar keys %{ $ai_B->split->states }, 1);

    # this is never called in real life
    ok($ai_B->split->should_fire($tBB1, 1)); # only one token

    # B-C
    my $ai_C = $tBC->derive_and_accept_instance($ai_B, { activity => $aC }, @args);
    is($ai_C->activity->activity_uid, 'ex4.C','derive_and_accept results in C');

    ok(!$ai_B->split->should_fire($tBB1, 1));
    ok(!$ai_B->split->should_fire($tBC, 1));

    ok(!$ai_C->is_enabled(), 'Join C should not fire');
    #ok($ai_B1b->is_enabled(), 'Join B1 should still fire');
    $ai_C->update({ deferred => DateTime->now });

    # B1-B2
    ok(!$ai_C->is_enabled(), 'Join C should not fire');
    $ai_B1b->update({ completed => DateTime->now() });
    my $ai_B2 = $tB1B2->derive_and_accept_instance($ai_B1b, { activity => $aB2 }, @args);
    is($ai_B2->activity->activity_uid, 'ex4.B2','derive_and_accept results in B2');
    
    # B2-D
    $ai_B2->update({ completed => DateTime->now() });
    ok($ai_B2->is_completed);
    ok(my $ai_D = $tB2D->derive_and_accept_instance($ai_B2, { activity => $aD }, @args));

    # Block B2-C
    #ok(!$ai_C->is_enabled(), 'Join C should not fire'); # needs block when B2 completed
    my $split = $ai_B2->split or die("No join found for split");
    $split->set_transition($tB2C->id, 'blocked');
    ok($ai_C->is_enabled(), 'Join C should fire');

    $ai_C->update({ deferred => undef })->discard_changes;
    $ai_C->fire_join;

    ok(!$ai_D->is_enabled(), 'Join D should not fire');
    $ai_D->update({ deferred => DateTime->now });

    # C-D
    $ai_C->update({ completed => DateTime->now() });
    my $ai_D2 = $tCD->derive_and_accept_instance($ai_C, { activity => $aD }, @args);
    #ok($ai_D->is_enabled(), 'Join D should fire');
    ok($ai_D2->is_enabled(), 'Join D should fire');

    }

    #-- follow some transitions
  else {
    my $ai_A = $aA->new_instance({ 
                process_instance_id => $i->id 
                });

    # A-B
    $ai_A->update({ completed => DateTime->now() }); # normally done in processrunner complete_activity
    my $ai_B = $tAB->derive_and_accept_instance($ai_A, { activity => $aB }, @args);

    # B-B1
    $ai_B->update({ completed => DateTime->now() });
    my $ai_B1b = $tBB1->derive_and_accept_instance($ai_B, { activity => $aB1 }, @args);
    ok(!$ai_B1b->is_enabled(), 'Join B1 should not fire');

    my $split = $ai_A->split or die("No join found for split");
    $split->set_transition($tAB1->id, 'blocked');
    ok($ai_B1b->is_enabled(), 'Join B1 should fire');
    }

}


# patterns: 06-iteration.xpdl
#-----------------------------------------------

# WCP10: Arbitrary Cycles (nested-loops) - test tokensets
if(1) {
    $engine->create_package('./t/var/06-iteration.xpdl');
    
    my ($r,$p,$i) = runner($engine, 'wcp10b2', { inner_loop => '1', outer_loop => 1 });
    my @args = ();

    ok(my $t0A = $p->transitions->find({ transition_uid => 'wcp10b.Start-A-XOR-Join' }));
    ok(my $tAB = $p->transitions->find({ transition_uid => 'wcp10b.A-XOR-Join-B-OR-Join' }));
    ok(my $tBC = $p->transitions->find({ transition_uid => 'wcp10b.B-OR-Join-C-OR-Split' }));
    ok(my $tCB = $p->transitions->find({ transition_uid => 'wcp10b.C-OR-Split-B-OR-Join' }));
    ok(my $tCD = $p->transitions->find({ transition_uid => 'wcp10b.C-OR-Split-D-XOR-Split' }));
    ok(my $tDA = $p->transitions->find({ transition_uid => 'wcp10b.D-XOR-Split-A-XOR-Join' }));
    ok(my $tD0 = $p->transitions->find({ transition_uid => 'wcp10b.D-XOR-Split-End' }));

    ok(my $aS = $p->activities->find({ activity_uid => 'wcp10b.Start' }));
    ok(my $aA = $p->activities->find({ activity_uid => 'wcp10b.A-XOR-Join' }));
    ok(my $aB = $p->activities->find({ activity_uid => 'wcp10b.B-OR-Join' }));
    ok(my $aC = $p->activities->find({ activity_uid => 'wcp10b.C-OR-Split' }));
    ok(my $aD = $p->activities->find({ activity_uid => 'wcp10b.D-XOR-Split' }));
    ok(my $aE = $p->activities->find({ activity_uid => 'wcp10b.End' }));

    my $ai_S = $aS->new_instance({ process_instance_id => $i->id });

    # Start-A
    $ai_S->update({ completed => DateTime->now() });
    my $ai_A = $t0A->derive_and_accept_instance($ai_S, { activity => $aA }, @args);
    ok($ai_A->is_enabled(), 'Join1 should fire');

    # A-B (Join1-Join2)
    $ai_A->update({ completed => DateTime->now() });
    my $ai_B1 = $tAB->derive_and_accept_instance($ai_A, { activity => $aB }, @args);
    ok($ai_B1->is_enabled(), 'Join2 should fire');

    # B-C : Split2 loops back to Join2 AND goes downstream to Split1
    $ai_B1->update({ completed => DateTime->now() });
    my $ai_C1 = $tBC->derive_and_accept_instance($ai_B1, { activity => $aC }, @args);
    $ai_C1->update({ completed => DateTime->now() });

    # C-B
    my $ai_B2 = $tCB->derive_and_accept_instance($ai_C1, { activity => $aB }, @args);

    # C-D
    my $ai_D = $tCD->derive_and_accept_instance($ai_C1, { activity => $aD }, @args);

    # D-A : Split1 creates another cycle through Join1
    $ai_D->update({ completed => DateTime->now() });
    my $ai_A2 = $tDA->derive_and_accept_instance($ai_D, { activity => $aA }, @args);
    ok($ai_A2->is_enabled(), 'Join1 should fire');

    # B and C have active instances 
    my $rs = $engine->schema->resultset('ActivityInstance');
    is($rs->active({ process_instance_id => $i->id })->count, 2);
    is($i->activity_instances->active->count, 2);

    ok($ai_B2->is_enabled(), 'First join2 should fire');

    $ai_A2->update({ completed => DateTime->now() });

    # A-B
    my $ai_B3 = $tAB->derive_and_accept_instance($ai_A2, { activity => $aB }, @args);
    ok($ai_B3->is_enabled(), 'Second join1 should fire');

    # B should fire twice, separately
    $ai_B3->update({ completed => DateTime->now() });
    my $ai_C2 = $tBC->derive_and_accept_instance($ai_B3, { activity => $aC }, @args);

    # cycles still have 2 active tokens, one in B/Join2 and one in C/Join1
    is($i->activity_instances->active->count, 2);
}

done_testing();
