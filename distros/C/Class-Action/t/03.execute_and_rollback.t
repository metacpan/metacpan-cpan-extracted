use Test::More tests => 60;

use lib 'lib', '../lib';

BEGIN {
use_ok( 'Class::Action' );
use_ok( 'Class::Action::Step' );
}

diag( "Testing Class::Action $Class::Action::VERSION" );

package MyStep;

sub new {
    bless { 'reset' => 0 }, __PACKAGE__;
}
sub reset_obj_state {
   shift->{'reset'} = 1;
}

sub clone_obj {
    bless { 'reset' => 0 }, __PACKAGE__;
}

package main;

# reset() and clone() 
my $stepa = MyStep->new();
my $stepb = MyStep->new();
my $stepc = MyStep->new();

my $obj = Class::Action->new({
    'step_stack' => [$stepa, $stepb, $stepc],
});

# simulate non-fresh object:
$obj->{'last_errstr'}  = 'Wups';
$obj->{'current_step'} = 1;

ok($obj->{'last_errstr'} eq 'Wups', 'pre reset state a');
ok($obj->{'current_step'} == 1 ,'pre reset state b');
is_deeply($obj->{'step_stack'}, [$stepa, $stepb, $stepc], 'pre reset state c');

ok($stepa->{'reset'} == 0 && $stepb->{'reset'} == 0 && $stepc->{'reset'} == 0, 'pre reset state d');

$obj->reset();

ok(!defined $obj->{'last_errstr'}, 'post reset state a');
ok(!defined $obj->{'current_step'},'post reset state b');
is_deeply($obj->{'step_stack'}, [$stepa, $stepb, $stepc], 'post reset state c');
ok($stepa->{'reset'} == 1 && $stepb->{'reset'} == 1 && $stepc->{'reset'} == 1, 'post reset state d');

# simulate non-fresh object:
$obj->{'last_errstr'}  = 'Wups';
$obj->{'current_step'} = 1;
$stepa->{'reset'} = 0;
$stepb->{'reset'} = 0; 
$stepc->{'reset'} = 0;

my $clone = $obj->clone();

ok($obj->{'last_errstr'} eq 'Wups', 'post clone state a - orig');
ok($obj->{'current_step'} == 1 ,'post clone state b - orig');
is_deeply($obj->{'step_stack'}, [$stepa, $stepb, $stepc], 'post clone state c - orig');
ok($stepa->{'reset'} == 0 && $stepb->{'reset'} == 0 && $stepc->{'reset'} == 0, 'post clone state d - orig');

ok(!defined $clone->{'last_errstr'}, 'post clone state a - clone');
ok(!defined $clone->{'current_step'},'post clone state b - clone');
ok(
    $clone->{'step_stack'}->[0] ne $stepa &&
    $clone->{'step_stack'}->[0] ne $stepb &&
    $clone->{'step_stack'}->[0] ne $stepc, 
    'post clone state c - clone'
);
ok($stepa->{'reset'} == 0 && $stepb->{'reset'} == 0 && $stepc->{'reset'} == 0, 'post clone state d - clone');

#### execute() and rollback() tests ##


package MyTest;

sub get_class_action_steps {
    my ($class, $type) = @_;
    return [
          $type eq 'execute_ok'    ? (MyTest::A->new(1,1), MyTest::B->new(1,1), MyTest::C->new(1,1), MyTest::D->new(1,1))
        : $type eq 'execute_fail'  ? (MyTest::A->new(1,1), MyTest::B->new(1,1), MyTest::C->new(0,1), MyTest::D->new(1,1))
        : $type eq 'rollback_fail' ? (MyTest::A->new(1,1), MyTest::B->new(1,0), MyTest::C->new(0,1), MyTest::D->new(1,1))
        : $type eq 'undo_fail'     ? (MyTest::A->new(1,1), MyTest::B->new(1,0), MyTest::C->new(1,1), MyTest::D->new(1,1))
        :                            (MyTest::Err->new())
    ];
}
package MyTest::Err;

sub new {
   die 'Your test is broken: INVALID "TYPE" ARGUMENT TO MyTest->get_class_action_steps()';    
}

package MyTest::A;

@MyTest::A::ISA = ('Class::Action::Step');

sub new {
    my ($class,$exec,$undo) = @_;
    bless {
        'exec' => $exec,
        'undo' => $undo,
        'info' => [],
    }, $class;
}

sub clone_obj {
    my ($step_obj) = @_;
    return ref($step_obj)->new($step_obj->{'exec'}, $step_obj->{'undo'});
}

sub state {
    my ($step_obj) = @_;
    return \@{ $step_obj->{'info'} };
}

sub reset_obj_state {
    my ($step_obj) = @_;
    @{ $step_obj->{'info'} } = (ref($step_obj) . '->reset_obj_state');
    %{ $step_obj->{'count'} } = ();
}

sub execute {
    my ($step_obj, $global_data_hr, @args_to_execute) = @_;
    push @{$step_obj->{'info'}}, ref($step_obj) . '->execute';
    return 1 if $step_obj->{'exec'};
    return;
}

package MyTest::B;

@MyTest::B::ISA = ('MyTest::A');

sub retry_execute {
    my ($step_obj, $global_data_hr, @args_to_execute) = @_;
    push @{$step_obj->{'info'}}, ref($step_obj) . '->retry_execute';
    return if $step_obj->{'counts'}{'retry_execute'}++;
    return 1;
}

sub clean_failed_execute {
    my ($step_obj, $global_data_hr, @args_to_execute) = @_;
    push @{$step_obj->{'info'}}, ref($step_obj) . '->clean_failed_execute';
    return; # void context
}

sub undo {
    my ($step_obj, $global_data_hr, @args_to_execute) = @_;
    push @{$step_obj->{'info'}}, ref($step_obj) . '->undo';
    return 1 if $step_obj->{'undo'};
    return;
}

sub retry_undo {
    my ($step_obj, $global_data_hr, @args_to_execute) = @_;
    push @{$step_obj->{'info'}}, ref($step_obj) . '->retry_undo';
    return if $step_obj->{'counts'}{'retry_undo'}++;
    return 1;
}

sub clean_failed_undo {
    my ($step_obj, $global_data_hr, @args_to_execute) = @_;
    push @{$step_obj->{'info'}}, ref($step_obj) . '->clean_failed_undo';
    return; # void context
}

package MyTest::C;

@MyTest::C::ISA = ('MyTest::B');

sub undo {
    my ($step_obj, $global_data_hr, @args_to_execute) = @_;
    push @{$step_obj->{'info'}}, ref($step_obj) . '->undo OVERRIDE';
    return 1 if $step_obj->{'undo'};
    return;
}

package MyTest::D;

@MyTest::D::ISA = ('MyTest::B');

package main;

diag('AUTO_ROLLBACK OFF execute(), rollback(), and undo() behavior');
my $test = Class::Action->new({ 'auto_rollback' => 0, 'set_steps_from_class' => ['MyTest','execute_ok'] });
diag('testing execute() and rollback() behavior when execute() succeeds');
ok($test->execute(), 'execute returns true');
is_deeply(
    [$test->{'step_stack'}[0]->state(),$test->{'step_stack'}[1]->state(),$test->{'step_stack'}[2]->state(),$test->{'step_stack'}[3]->state()],
    [
       ['MyTest::A->execute'],
       ['MyTest::B->execute'],
       ['MyTest::C->execute'],
       ['MyTest::D->execute'],
    ],
    'items executed correct'
);

ok(!$test->rollback(), 'rollback returns false');
is_deeply(
    [$test->{'step_stack'}[0]->state(),$test->{'step_stack'}[1]->state(),$test->{'step_stack'}[2]->state(),$test->{'step_stack'}[3]->state()],
    [
        ['MyTest::A->execute'],
        ['MyTest::B->execute'],
        ['MyTest::C->execute'],
        ['MyTest::D->execute'],
    ],
    'items executed still correct'
);

ok($test->execute(), 'execute returns true'); 
is_deeply(
    [$test->{'step_stack'}[0]->state(),$test->{'step_stack'}[1]->state(),$test->{'step_stack'}[2]->state(),$test->{'step_stack'}[3]->state()],
    [
        [
            'MyTest::A->reset_obj_state',
            'MyTest::A->execute'
        ],
        [
            'MyTest::B->reset_obj_state',
            'MyTest::B->execute'
        ],
        [
            'MyTest::C->reset_obj_state',
            'MyTest::C->execute'
        ],
        [
            'MyTest::D->reset_obj_state',
            'MyTest::D->execute'
        ],
    ],
    'reset called'
);

$test->set_steps_from_class('MyTest','execute_fail');
diag('testing execute() and rollback() behavior when execute() fails');
ok(!$test->execute(), 'execute returns false');

my $state   = $test->get_execution_state();
my $state_x = $test->get_execution_state();
ok($state ne $state_x, 'get_execution_state() returns new ref');

my @actually_is = map { [$_->{'ns'}, $_->{'type'}, $_->{'status'}] } @{ $test->get_execution_state() };
# use Data::Dumper;diag(Dumper(\@actually_is));
is_deeply(\@actually_is, [
    ['MyTest::A', 'execute', 1],
    ['MyTest::B', 'execute', 1],
    ['MyTest::C', 'execute', undef],
    ['MyTest::C', 'execute', 0],
],'stack is as it should be');
    
ok($test->rollback(), 'rollback returns true');
@actually_is = map { [$_->{'ns'}, $_->{'type'}, $_->{'status'}] } @{ $test->get_execution_state() };
# use Data::Dumper;diag(Dumper(\@actually_is));
is_deeply(\@actually_is, [
    ['MyTest::A', 'execute', 1],
    ['MyTest::B', 'execute', 1],
    ['MyTest::C', 'execute', undef],
    ['MyTest::C', 'execute', 0],
    ['MyTest::C','rollback',1],
    ['MyTest::B','rollback',1],
    ['MyTest::A','rollback',1],  
],'stack is as it should be');

$test->set_steps_from_class('MyTest','rollback_fail');
diag('testing execute() and rollback() behavior when rollback() fails');
ok(!$test->execute(), 'execute returns false');
ok(!$test->rollback(), 'rollback returns false');
@actually_is = map { [$_->{'ns'}, $_->{'type'}, $_->{'status'}] } @{ $test->get_execution_state() };
# use Data::Dumper;diag(Dumper(\@actually_is));
is_deeply(\@actually_is, [
    ['MyTest::A', 'execute', 1],
    ['MyTest::B', 'execute', 1],
    ['MyTest::C', 'execute', undef],
    ['MyTest::C', 'execute', 0],
    ['MyTest::C','rollback',1],
    ['MyTest::B','rollback',undef], 
    ['MyTest::B','rollback',0], 
],'stack is as it should be');

diag('AUTO_ROLLBACK ON execute(), rollback(), and undo() behavior');
$test->reset();
$test->set_auto_rollback(1);
$test->set_steps_from_class('MyTest','execute_ok');
diag('testing execute() and rollback() behavior when execute() succeeds');
ok($test->execute(), 'execute returns true');
is_deeply(
    [$test->{'step_stack'}[0]->state(),$test->{'step_stack'}[1]->state(),$test->{'step_stack'}[2]->state(),$test->{'step_stack'}[3]->state()],
    [
        ['MyTest::A->execute'],
        ['MyTest::B->execute'],
        ['MyTest::C->execute'],
        ['MyTest::D->execute'],
    ],
    'items executed correct'
);
ok(!$test->rollback(), 'rollback returns false');
is_deeply(
    [$test->{'step_stack'}[0]->state(),$test->{'step_stack'}[1]->state(),$test->{'step_stack'}[2]->state(),$test->{'step_stack'}[3]->state()],
    [
        ['MyTest::A->execute'],
        ['MyTest::B->execute'],
        ['MyTest::C->execute'],
        ['MyTest::D->execute'],
    ],
    'items executed still correct'
);

ok($test->execute(), 'execute returns true'); 
is_deeply(
    [$test->{'step_stack'}[0]->state(),$test->{'step_stack'}[1]->state(),$test->{'step_stack'}[2]->state(),$test->{'step_stack'}[3]->state()],
    [
        [
            'MyTest::A->reset_obj_state',
            'MyTest::A->execute'
        ],
        [
            'MyTest::B->reset_obj_state',
            'MyTest::B->execute'
        ],
        [
            'MyTest::C->reset_obj_state',
            'MyTest::C->execute'
        ],
        [
            'MyTest::D->reset_obj_state',
            'MyTest::D->execute'
        ],
    ],
    'reset called'
);

$test->set_steps_from_class('MyTest','execute_fail');
diag('testing execute() and rollback() behavior when execute() fails');
ok(!$test->execute(), 'execute returns false');
ok((grep {$_->{'type'} eq 'rollback'} @{ $test->get_execution_state() }), 'exec_stack has rollback');

ok(!$test->rollback(), 'rollback returns false');

$test->set_steps_from_class('MyTest','rollback_fail');
diag('testing execute() and rollback() behavior when rollback() fails');
ok(!$test->execute(), 'execute returns false');
my $state_y = $test->get_execution_state();
ok((grep {$_->{'type'} eq 'rollback'} @{ $state_y }), 'exec_stack has rollback');
ok(!$test->rollback(), 'rollback returns false');
is_deeply($test->get_execution_state(),$state_y, 'rollback() after auto_rollback failed execute() short circuits call');

#### test undo() ##

$test->reset();

#  undo() successful execute()
$test->set_steps_from_class('MyTest','execute_ok');
ok($test->execute(), 'execute returns true');
ok(!$test->undo_called(), 'undo_called() false before undo() is called');
ok($test->undo(), 'undo() works after successful execute');
ok($test->undo_called(), 'undo_called() true after undo() is called');
ok(!$test->undo_failed(), 'good undo after good execute is not failure');

@actually_is = map { [$_->{'ns'}, $_->{'type'}, $_->{'status'}] } @{ $test->get_execution_state() };
# use Data::Dumper;diag(Dumper(\@actually_is));
is_deeply(\@actually_is, [
    ['MyTest::A', 'execute', 1],
    ['MyTest::B', 'execute', 1],
    ['MyTest::C', 'execute', 1],
    ['MyTest::D', 'execute', 1],
    ['MyTest::D','rollback',1],
    ['MyTest::C','rollback',1], 
    ['MyTest::B','rollback',1],
    ['MyTest::A','rollback',1],  
],'stack is as it should be w/ undo()');

#  undo() before execute()
$test->reset();
ok(!$test->undo(), 'undo() before execute() returns false');

#  undo() failed execute()
$test->set_steps_from_class('MyTest','execute_fail');
ok(!$test->execute(), 'execute returns false');
ok(!$test->undo(), 'undo() before execute() returns false');
ok(!$test->undo_failed(), 'undo before execute is not considered failure');

# undo_failed() 

$test->set_steps_from_class('MyTest','undo_fail');
ok($test->execute(), 'execute returns true');
ok(!$test->undo_called(), 'undo_called() false before undo() is called');
ok(!$test->undo(), 'undo() fails after successful execute');
ok($test->undo_called(), 'undo_called() true after undo() is called');
ok($test->undo_failed(), 'failed undo after good execute is failure');