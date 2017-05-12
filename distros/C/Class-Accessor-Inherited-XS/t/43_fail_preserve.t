use strict;
use Test::More;
use Class::Accessor::Inherited::XS;

BEGIN {
    Class::Accessor::Inherited::XS::register_type(
        die_write => {write_cb => \&CORE::die},
    );
    Class::Accessor::Inherited::XS::register_type(
        die_read  => {read_cb  => \&CORE::die},
    );
}

use Class::Accessor::Inherited::XS
    die_write => {now => 'key'},
    die_read  => {nor => 'key'},
;

for my $obj ('main', bless({})) {
    is($obj->nor(42), 42);

    is(eval {$obj->nor; 1}, undef);
    is $obj->now, 42;

    is(eval {$obj->now(42); 1}, undef);
    is $obj->now, 42;
}

done_testing;
