use strict;
use lib ".";
local $^W = 1;
use Test::More;
use Scalar::Util qw( refaddr );
use Class::InsideOut ();

$|++; # keep stdout and stderr in order on Win32 (maybe)

my %constructors_for = ( 
    't::Object::Singleton::Simple' => 'new',
    't::Object::Singleton::Hooked' => 'get_instance',
);

# Need Storable 2.14 ( STORABLE_attach support )
eval { require Storable and Storable->VERSION( 2.14 ) };
if ( $@ ) {
    plan skip_all => "Storable >= 2.14 needed for singleton support",
}
else {
    plan tests => 12 * scalar keys %constructors_for;
}

#--------------------------------------------------------------------------#

my $name =  "Neo"; 
my $name2 = "Mr. Smith";

#--------------------------------------------------------------------------#

for my $class ( keys %constructors_for ) {
    require_ok( $class );
    my $o;
    # create the object
    my $new = $class->can( $constructors_for{$class} );
    ok( $o = $new->($class),  
        "... Creating $class object"
    );
        
    # set a name
    $o->name( $name );
    is( $o->name(), $name,
        "... Setting 'name' to '$name'"
    );
        
    # freeze object
    my ( $frozen, $thawed );
    ok( $frozen = Storable::freeze( $o ),
        "... Freezing $class object"
    );

    # set a name
    $o->name( $name2);
    is( $o->name(), $name2,
        "... Setting 'name' to '$name2'"
    );
        
    # thaw object
    ok( $thawed = Storable::thaw( $frozen ),
        "... Thawing $class object"
    );
    is( refaddr $o, refaddr $thawed,
        "... Thawed $class object is the singleton"
    );

    # check it
    is( $thawed->name(), $name2,
        "... Thawed $class object 'name' is '$name2'"
    );

    # destroy the singleton
    {
        no strict 'refs';
        Class::InsideOut::_deregister( $o ) if $] < 5.006;
        ${"$class\::self"} = $thawed = $o = undef;
        is( ${"$class\::self"}, undef,
            "... Destroying $class singleton manually"
        );
        my @leaks = Class::InsideOut::_leaking_memory;
        is( scalar @leaks, 0, 
            "... $class is not leaking memory"
        ) or diag "Leaks detected in:\n" . join( "\n", map { q{  } . $_ } @leaks );
    }

    # recreate it
    ok( $thawed = Storable::thaw( $frozen ),
        "... Re-thawing $class object again (recreating)"
    );

    # check it
    if ( $class eq "t::Object::Singleton::Hooked" ) {
        is( $thawed->name(), $name,
            "... Re-thawed $class object 'name' is '$name'"
        );
    }
    else { # regular singleton doesn't reinitialize
        is( $thawed->name(), undef,
            "... Re-thawed $class object 'name' is undef"
        );
    }

}

    
        

