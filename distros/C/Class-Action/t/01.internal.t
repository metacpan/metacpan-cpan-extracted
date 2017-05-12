use Test::More tests => 80;
use lib 'lib', '../lib';
BEGIN {
use_ok( 'Class::Action' );
use_ok( 'Class::Action::Step' );
}

diag( "Testing Class::Action $Class::Action::VERSION internals" );

my $cmd = Class::Action->new();

# get/set
for my $func qw(errstr auto_rollback) {
    my $get = "get_$func";
    my $set = "set_$func";
    
    diag("\n\nStarting $get/$set\n\n");
    
    if ($func eq 'errstr') {
        ok(!defined $cmd->$get(), "$get default");
    }
    elsif ($func eq 'auto_rollback') {
        ok($cmd->$get() == 1, "$get default");
    }

    ok($cmd->$set(1) == 1, "$set 1");
    ok($cmd->$get() == 1, "$get new true val");

    ok($cmd->$set(0) == 0, "$set 0");
    ok($cmd->$get() == 0, "$get new false 0 val");

    ok(!defined $cmd->$set(undef), "$set undef");
    ok(!defined $cmd->$get(), "$get new false undef val");

    ok($cmd->$set(2) == 2, "$set back to true");
    ok($cmd->$get() == 2, "$get reset ok");

    ok(!defined $cmd->$set(), "$set no val");
    ok(!defined $cmd->$get(), "$get new false no val");
}


diag("\n\nStarting other internals\n\n");

ok(!defined $cmd->get_current_step, 'pre execute get_current_step');
ok($cmd->is_at_start, 'pre execute is_at_start');
ok(!$cmd->is_at_end, 'pre execute is_at_end');

my $curstep = $cmd->{'current_step'};
ok(!$cmd->next_step, 'empty stack next_step() RC false');
is_deeply($curstep, $cmd->{'current_step'}, 'empty stack next_step() does not touch current_step');

$cmd->{'step_stack'} = [1,2,3,4];
for my $idx (0 .. 3) {
    my $next = $cmd->next_step();
    ok($next eq $cmd->{'step_stack'}[$idx], "next_step() $next of 4");
}

$curstep = $cmd->{'current_step'};
ok(!$cmd->next_step, 'finished stack next_step() RC false');
is_deeply($cmd->{'current_step'}, $curstep, 'finished stack next_step() does not touch current_step');

ok($cmd->get_current_step eq '', 'post execute get_current_step');
ok(!$cmd->is_at_start, 'post execute is_at_start');
ok($cmd->is_at_end, 'post execute is_at_end');

my $new = Class::Action->new({
    'step_stack' => [1,2,3,4,5,6,7,8,9],
    'auto_rollback' => 0,
});

ok($new->get_auto_rollback() == 0, 'auto_rollback in constructor');

for (0..3) {
    $new->next_step();
}

for my $id (3,2,1,0) {
    my $prev = $new->prev_step();
    ok($prev eq $new->{'step_stack'}[$id], "prev_step() $prev of 4");
}

$curstep = $new->{'current_step'};
ok(!$new->prev_step, 'finished stack prev_step() RC false');
is_deeply($new->{'current_step'}, $curstep, 'finished stack prev_step() does not touch current_step');

ok(!defined $new->get_current_step, 'post rollback get_current_step');
ok($new->is_at_start, 'post rollback is_at_start');
ok(!$new->is_at_end, 'post rollback is_at_end');

ok(!exists $cmd->{'_execute'} && !$cmd->execute_called(), '!exists execute_called()');
ok(!exists $cmd->{'_execute'} && !$cmd->execute_failed(), '!exists execute_failed()');

$cmd->{'_execute'} = 0;
ok($cmd->{'_execute'} == 0 && $cmd->execute_called(), '0 execute_called()');
ok($cmd->{'_execute'} == 0 && !$cmd->execute_failed(), '0 execute_failed()');

$cmd->{'_execute'} = 1;
ok($cmd->{'_execute'} == 1 && $cmd->execute_called(), '1 execute_called()');
ok($cmd->{'_execute'} == 1 && $cmd->execute_failed(), '1 execute_failed()');

ok(!exists $cmd->{'_rollback'} && !$cmd->rollback_called(), '!exists rollback_called()');
ok(!exists $cmd->{'_rollback'} && !$cmd->rollback_failed(), '!exists rollback_failed()');

$cmd->{'_rollback'} = 0;
ok($cmd->{'_rollback'} == 0 && $cmd->rollback_called(), '0 rollback_called()');
ok($cmd->{'_rollback'} == 0 && !$cmd->rollback_failed(), '0 rollback_failed()');

$cmd->{'_rollback'} = 1;
ok($cmd->{'_rollback'} == 1 && $cmd->rollback_called(), '1 rollback_called()');
ok($cmd->{'_rollback'} == 1 && $cmd->rollback_failed(), ' execute_failed()');

my $xyz = Class::Action->new({
    'step_stack' => [1,2,3],    
});
is_deeply($xyz->{'step_stack'}, [1,2,3], 'stack in new');

is_deeply( [$xyz->get_steps()], [1,2,3], 'get_steps');

is_deeply( [$xyz->set_steps([4,5,6])], [4,5,6], 'set_steps array ref return');
is_deeply( [$xyz->get_steps()], [4,5,6], 'set_steps array ref result');

is_deeply( [$xyz->set_steps(7,8,9)], [7,8,9], 'set_steps array return');
is_deeply( [$xyz->get_steps()], [7,8,9], 'set_steps array result');

is_deeply( [$xyz->append_steps([10,11])], [7,8,9,10,11], 'append_steps array ref return'); #
is_deeply( [$xyz->get_steps()], [7,8,9,10,11], 'append_steps array ref result');

is_deeply( [$xyz->append_steps(12)], [7,8,9,10,11,12], 'append_steps array return'); #
is_deeply( [$xyz->get_steps()], [7,8,9,10,11,12], 'append_steps array result');

is_deeply( [$xyz->prepend_steps([5,6])], [5,6,7,8,9,10,11,12], 'prepend_steps array ref return'); #
is_deeply( [$xyz->get_steps()], [5,6,7,8,9,10,11,12], 'prepend_steps array ref result');

is_deeply( [$xyz->prepend_steps(4)], [4,5,6,7,8,9,10,11,12], 'prepend_steps array return'); #
is_deeply( [$xyz->get_steps()], [4,5,6,7,8,9,10,11,12], 'prepend_steps array result');

package HasSteps::List;

sub get_class_action_steps {
    my ($class,@args) = @_;
    return('x',@args);
}

package HasSteps::ArrayRef;

sub get_class_action_steps {
    my ($class,@args) = @_;
    return ['y',@args];
}

package main;

$xyz->set_steps(1,2,3);

$xyz->append_steps_from_class('HasSteps::List',1);
is_deeply($xyz->{'step_stack'}, [1,2,3,'x',1], 'append_steps_from_class array');

$xyz->prepend_steps_from_class('HasSteps::List',2);
is_deeply($xyz->{'step_stack'}, ['x',2,1,2,3,'x',1], 'append_steps_from_class array');

$xyz->set_steps(1,2,3);

$xyz->append_steps_from_class('HasSteps::ArrayRef',3);
is_deeply($xyz->{'step_stack'}, [1,2,3,'y',3], 'append_steps_from_class array ref');

$xyz->prepend_steps_from_class('HasSteps::ArrayRef',4);
is_deeply($xyz->{'step_stack'}, ['y',4,1,2,3,'y',3], 'prepend_steps_from_class array ref');

$xyz->set_steps_from_class('HasSteps::List',7,8,9);
is_deeply($xyz->{'step_stack'}, ['x',7,8,9], 'set_steps_from_class');


diag("\n\nYou will see one 'Class::Action::Stack does not implement get_class_action_steps()' carp below.\n\n");

$xyz->set_steps_from_class('Class::Action::Stack');
is_deeply($xyz->{'step_stack'}, [], 'set_steps_from_class that returns nothing');
