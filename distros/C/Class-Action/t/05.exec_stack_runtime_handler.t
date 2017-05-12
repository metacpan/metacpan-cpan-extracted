use Test::More tests => 6;
use Test::Carp;

use lib 'lib', '../lib';

BEGIN {
use_ok( 'Class::Action' );
use_ok( 'Class::Action::Step' );
}

diag( "Testing Class::Action $Class::Action::VERSION" );

package TestAct;

@TestAct::ISA = qw(Class::Action::Step);
sub new { return bless {}, $_[0] }
sub clone_obj { return bless {}, $_[0] }
sub state { return '' }
sub reset_obj_state { %{ $_[0] } = () }
sub execute { return 1 }
sub exec_stack_runtime_handler {
    Test::More::ok(ref($_[1]) eq 'HASH', ref($_[0]) . " calls exec_stack_runtime_handler w/ HASH");
}

sub get_class_action_steps {
    return ['TestAct::A', 'TestAct::B', 'TestAct::C', 'TestAct::D'];
}

package TestAct::A;

@TestAct::A::ISA = ('TestAct');

package TestAct::B;

@TestAct::B::ISA = ('TestAct');

package TestAct::C;

@TestAct::C::ISA = ('TestAct');

package TestAct::D;

@TestAct::D::ISA = ('TestAct');

package main;

my $act = Class::Action->new({'set_steps_from_class' => 'TestAct'});
$act->execute();





