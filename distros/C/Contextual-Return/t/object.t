use Contextual::Return;
use Test::More 'no_plan';

ok(Contextual::Return::Value->isa('UNIVERSAL')  =>  'Handles class isa ok');
ok(Contextual::Return::Value->can('can')        =>  'Handles class can ok');

sub foo_no_obj {
    return
        VALUE { bless {}, 'Bar' }
    ;
}

sub foo_with_obj {
    return
        VALUE { 1 } 
        OBJREF { bless {}, 'Bar' }
    ;
}

sub foo_bad_obj {
    return
        VALUE { 1 } 
        OBJREF { 1 }
    ;
}


is foo_no_obj()->bar, "baaaaa!\n"       => 'VALUE returns object';
ok !eval{ foo_no_obj()->baz }           => 'Object has no baz() method';
like $@,
     qr/\A\QCan't call method 'baz' on VALUE value returned by main::foo_no_obj/
                                        => 'Error msg was correct';

is foo_with_obj()->bar, "baaaaa!\n"     => 'OBJREF returns object';
ok !eval{ foo_with_obj()->baz }         => 'Object still has no baz() method';
like $@,
     qr/\A\QCan't call method 'baz' on OBJREF value returned by main::foo_with_obj/
                                        => 'Error msg was also correct';

ok !eval{ foo_bad_obj()->bar }          => 'OBJREF returns bad object';
like $@,
     qr/\A\QCan't call method 'bar' on OBJREF value returned by main::foo_bad_obj/
                                        => 'Error msg was still correct';

ok !eval{ foo_with_obj()->bad }         => 'Other exceptions propagated';
like $@, qr/\ABad method! No biscuit!/  => 'Exception msg was correct';

# can_ok() checks against ref $proto || $proto. This bypasses the the
# obj de-ref that C::R::V provides. isa_ok() does check against the
# object, but I chose to write it as ok( $foo->isa() ) to maintain
# consistency and to provide the testname

ok foo_no_obj()->can('bar')
    => 'can() is checked against the object, not C::R::V';

ok foo_no_obj()->isa('Bar')
    => 'isa() is checked against the object, not C::R::V';

package Bar;

sub bar { "baaaaa!\n" }

sub bad {
    die "Bad method! No biscuit!";
}
