use strict;
use warnings;

package C3NT_nowarn;

{
    package C3NT::Foo;

    sub new { return bless {} => shift }

    sub basic        { 42 }
    sub c3_then_next { 21 }
    sub next_then_c3 { 22 }
}

{
    package C3NT::Bar;

    use base qw/C3NT::Foo/;

    no warnings 'Class::C3::Adopt::NEXT';

    sub basic               { shift->NEXT::basic                       }
    sub next_then_c3        { shift->next::method                      }
    sub actual_fail_halfway { shift->NEXT::ACTUAL::actual_fail_halfway }
}

{
    package C3NT::Baz;

    use base qw/C3NT::Foo/;

    no warnings 'Class::C3::Adopt::NEXT';

    sub basic        { shift->NEXT::basic        }
    sub c3_then_next { shift->NEXT::c3_then_next }
}

{
    package C3NT::Quux;

    use base qw/C3NT::Bar C3NT::Baz/;

    no warnings 'Class::C3::Adopt::NEXT';

    sub basic               { shift->NEXT::basic                       }
    sub non_exist           { shift->NEXT::non_exist                   }
    sub non_exist_actual    { shift->NEXT::ACTUAL::non_exist_actual    }
    sub actual_fail_halfway { shift->NEXT::ACTUAL::actual_fail_halfway }
    sub c3_then_next        { shift->next::method                      }
    sub next_then_c3        { shift->NEXT::next_then_c3                }
}

1;
