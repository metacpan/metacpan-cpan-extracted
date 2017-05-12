use strict;
use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? ('no_plan') : (skip_all => 'requires Test::LeakTrace');
use Test::LeakTrace;
use Class::Accessor::Inherited::XS;

BEGIN {
    Class::Accessor::Inherited::XS::register_type(
        component => {
            read_cb  => sub {shift, shift, shift, my $a={1,2}; 42},
            write_cb => sub {shift, shift, shift, my $a={1,2}; 42},
        }
    );
    Class::Accessor::Inherited::XS::register_type(
        die => {
            read_cb  => sub {shift, shift, shift, my $a={1,2}; die},
            write_cb => sub {shift, shift, shift, my $a={1,2}; die},
        }
    );
}

use Class::Accessor::Inherited::XS
    component => ['foo'],
    die       => ['fire'],
;

for my $obj ('main', bless({})) {
    no_leaks_ok {
        eval { $obj->foo(12) } for (1..10);
    };

    no_leaks_ok {
        eval { $obj->foo; } for (1..10);
    };

    no_leaks_ok {
        eval { $obj->fire(12) } for (1..10);
    };

    no_leaks_ok {
        eval { $obj->fire; } for (1..10);
    };
}
