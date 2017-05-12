use strict;
use lib ".";
use Test::More;
use Class::InsideOut ();

$|++; # keep stdout and stderr in order on Win32

plan tests => 9;

#--------------------------------------------------------------------------#

my $class    = "t::Object::Animal";
my $subclass = "t::Object::Animal::Antelope";

my ($o, $p);

#--------------------------------------------------------------------------#

require_ok( $class );
require_ok( $subclass );

ok( ($o = $class->new()) && $o->isa($class),
    "Creating a $class object"
);

ok( ($p = $subclass->new()) && $p->isa($subclass),
    "Creating a $subclass object"
);

is( $t::Object::Animal::animal_count, 2,
    "Count of animals is 2"
);

Class::InsideOut::_deregister( $p ) if $] < 5.006;
undef $p;
ok( ! defined $p,
    "Destroying the subclass object"
);

ok( ! scalar @t::Object::Animal::subclass_errors,
    "Subclass shouldn't inherit superclass DEMOLISH"
) or do {
    diag "  DEMOLISH improperly called by $_" 
        for @t::Object::Animal::subclass_errors;
};

Class::InsideOut::_deregister( $o ) if $] < 5.006;
undef $o;
ok( ! defined $o,
    "Destroying the first object"
);

is( $t::Object::Animal::animal_count, 1,
    "${class}::DEMOLISH decremented the count of animals to 1"
);

