use strict;
use lib ".";
use Test::More 0.45;
use Class::InsideOut ();

$|++; # try to keep stdout and stderr in order on Win32

#--------------------------------------------------------------------------#

my @classes = qw(
    t::Object::Trivial
    t::Object::RegisterRef
    t::Object::RegisterClassname
);

my %objects_of;

#--------------------------------------------------------------------------#

plan tests => 1 + ( 8 * @classes );

is( Class::InsideOut::_object_count(), 0,
    "no objects registered"
);

my $expected_count;
# Build objects for each class
for my $class ( @classes ) {
    require_ok( $class );


    my $o;
    ok( ($o = $class->new()) && $o->isa($class),
        "Creating a $class object"
    );
    push @{$objects_of{$class}}, $o;
    $expected_count++;

    ok( ($o = $class->new()) && $o->isa($class),
        "Creating another $class object"
    );
    push @{$objects_of{$class}}, $o;
    $expected_count++;

    is( Class::InsideOut::_object_count(), 
        $expected_count,
        "object count correct"
    );
}

# Teardown objects
for my $class ( @classes ) {
    while ( @{$objects_of{$class}} ) {
        my $o = shift @{$objects_of{$class}};
        Class::InsideOut::_deregister( $o ) if $] < 5.006;
        undef $o;
        ok( ! defined $o,
            "Destroying an object"
        );
        $expected_count--;

        is( Class::InsideOut::_object_count(), 
            $expected_count,
            "object count correct"
        );
    }
}



