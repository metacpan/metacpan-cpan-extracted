use strict;
use lib ".";
local $^W = 1;
use Test::More;
use Scalar::Util qw( refaddr );

$|++; # keep stdout and stderr in order on Win32 (maybe)

my %constructors_for = ( 
    't::Object::Singleton::MissingConstructor' => 'get_it',
);

# Need Storable 2.14 ( STORABLE_attach support )
eval { require Storable and Storable->VERSION( 2.14 ) };
if ( $@ ) {
    plan skip_all => "Storable >= 2.14 needed for singleton support",
}
else {
    plan tests => 6 * scalar keys %constructors_for;
}

#--------------------------------------------------------------------------#

my $name =  "Neo"; 

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

    # thaw object -- should die because no "new()" and no
    # STORABLE_attach_hook
    my $error;
    eval { 
        local $SIG{__WARN__} = sub { $error = shift }; 
        $thawed = Storable::thaw( $frozen );
    };

    like( $@, "/STORABLE_attach did not return a $class\/",
        "... Thawing without constructor throws error"
    ); 

    like( $error, "/Error attaching to $class\/",
        "... Warning message seen"
    ); 

}

    
        

