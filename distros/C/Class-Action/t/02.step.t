use Test::More tests => 12;

use lib 'lib', '../lib';

BEGIN {
use_ok( 'Class::Action' );
use_ok( 'Class::Action::Step' );
}

diag( "Testing Class::Action::Step $Class::Action::::Step::VERSION" );

package XYZ::Frobnicate::Foo;

push @XYZ::Frobnicate::Foo::ISA, 'Class::Action::Step';

# an empty step

package main;

my $foo = bless {}, 'XYZ::Frobnicate::Foo';

diag("non implemented method defaults");

diag("\n\nYou will start seeing 'XYZ::Frobnicate::Foo does not implement METHOD()' carps below.\n\n");

for my $meth qw(new clone_obj state reset_obj_state) {
    ok(!$foo->$meth(), "$meth() returns false when not implemented");   
}
ok($foo->execute(), "execute() returns false when not implemented");

diag("\n\n'XYZ::Frobnicate::Foo does not implement METHOD()' carps should stop now.\n\n");

for my $meth qw(retry_execute clean_failed_execute retry_undo clean_failed_undo) {
    ok(!$foo->$meth(), "$meth() returns false when not implemented");   
}
ok($foo->undo(), "undo() returns false when not implemented");
