use Test::More tests => 17;
use Test::Carp;

use lib 'lib', '../lib';

BEGIN {
use_ok( 'Class::Action::Step' );
}

diag( "Testing Class::Action::Step $Class::Action::Step::VERSION" );

package Object;
@Object::ISA=qw(TestAct);
sub execute { Test::More::ok(1, 'Object used'); 1 };

package String;
@String::ISA=qw(TestAct);
sub execute { 
    Test::More::ok(1, 'String used'); 
    Test::More::is_deeply($_[0]->{'_'}[1], 'X','String args'); 
    Test::More::ok($_[2] eq 'X','execute String Args');
    return 1; 
};

package ArrayRef;
@ArrayRef::ISA=qw(TestAct);
sub execute { 
    Test::More::ok(1, 'ArrayRef used');
    Test::More::is_deeply($_[0]->{'_'}, ['ArrayRef',1,2,['X']],'ArrayRef args'); 
    Test::More::ok($_[2] eq 'X','execute Arrayref Args');
    return 1;
};

package TestAct;

@TestAct::ISA = qw(Class::Action::Step);
sub new { return bless { '_' => \@_ }, $_[0] }
sub clone_obj { return bless {}, $_[0] }
sub state { return '' }
sub reset_obj_state { %{ $_[0] } = () }
sub execute { return 1 }
sub exec_stack_runtime_handler {
    Test::More::ok(ref($_[1]) eq 'HASH', ref($_[0]) . " calls exec_stack_runtime_handler w/ HASH");
}

sub get_class_action_steps {
    
    return [
        __PACKAGE__->setup_class_execute_and_get_class_action_steps(
            ['A' => \&execute],
            ['B' => \&execute, sub { 1 } ],
            ['C' => \&execute],
            ['D' => \&execute],
        ),
        'String',
        Object->new(),
        ['ArrayRef',1,2],
    ];
}

package main;

my $act = TestAct->get_action_object();
$act->execute('X');

ok(!defined &TestAct::A::undo, 'sanity check for next test');
ok(defined &TestAct::B::undo, 'second code ref becomes undo');
# ok(\&TestAct::A::undo && \\&TestAct::A::undo eq \&TestAct::C::undo, 'sanity check for next test');
# ok(\&TestAct::B::undo ne \&TestAct::A::undo, 'second code ref becomes undo');