use strict;
use lib ".";
use Test::More;
use Class::InsideOut ();
use Scalar::Util qw( refaddr reftype );

$|++; # try to keep stdout and stderr in order on Win32

# Need Storable 2.04 ( relatively safe STORABLE_freeze support )
eval { require Storable and Storable->VERSION( 2.04 ) };
if ( $@ ) {
    plan skip_all => "Storable >= 2.04 not installed",
}

sub check_version {
    my ($class, $version) = @_;
    eval { require $class and $class->VERSION($version) };
    return $@ eq q{} ? 0 : 1;
}
    
my @serializers = (
    {
        class   => "Storable",
        version => 3.04,
        freeze  => sub { Storable::freeze( shift ) },
        thaw    => sub { Storable::thaw( shift ) },
    },
);

my @classes = qw(
    t::Object::Scalar
    t::Object::Array
    t::Object::Hash
    t::Object::Animal::Jackalope
);
    
my %custom_prop_for_class = (
    "t::Object::Scalar"  => {
        age => "32" 
    },
    "t::Object::Array"   => {
        height => "72 inches"
    },
    "t::Object::Hash"    => { 
        weight => "190 lbs" 
    },
    "t::Object::Animal::Jackalope" => {
        color => "white",
        speed => "60 mph",
        points => 13,
        kills => 23,
    },
);

my $prop_count;
$prop_count++ for map { keys %$_ } values %custom_prop_for_class;

my $tests_per_serializer = ( 1 + (11 * @classes) + (2 * $prop_count) );

plan tests => @serializers * $tests_per_serializer;

#--------------------------------------------------------------------------#
# Setup test data
#--------------------------------------------------------------------------#

my %content_for_type = (
    SCALAR  => \do { my $s = 3.14159 },
    ARRAY   => [1, 1, 2, 3, 5, 8 ],
    HASH    => { 1 => 1, 2 => 4, 3 => 9, 4 => 16 },
);

my %names_for_class = (
    "t::Object::Scalar"             => "Larry",
    "t::Object::Array"              => "Moe",
    "t::Object::Hash"               => "Curly",
    "t::Object::Animal::Jackalope"  => "Fred",
);

#--------------------------------------------------------------------------#
# tests
#--------------------------------------------------------------------------#

for my $s ( @serializers ) {

    SKIP:
    {
    
        skip "$s->{class} $s->{version} required", $tests_per_serializer
            unless check_version( $s->{class}, $s->{version} );
        
        require_ok( $s->{class} );

        for my $class ( @classes ) {
            no strict 'refs';
            require_ok( $class );
            my $o;
            # create the object
            ok( $o = $class->new(),  
                "... Creating $class object"
            );
            
            # note the underlying type
            my $type;
            ok( $type = reftype($o),
                "... Object is reftype $type"
            );
            
            # set a name
            my $name = $names_for_class{ $class };
            $o->name( $name );
            is( $o->name(), $name,
                "... Setting 'name' to '$name'"
            );
            
            # set class-specific properties
            for my $prop ( keys %{ $custom_prop_for_class{ $class } } ) {;
                my $val = $custom_prop_for_class{ $class }{ $prop };
                $o->$prop( $val );
                is( $o->$prop(), $val,
                    "... Setting custom '$prop' property to $val"
                );
            }
            
            # store class-specific data in the reference
            my $data = $content_for_type{ $type };
            for ( reftype $o ) {
                /SCALAR/ && do { $$o = $$data; last };
                /ARRAY/  && do { @$o = @$data; last };
                /HASH/   && do { %$o = %$data; last };
            }
            pass( "... Loading base $type with data" );

            # freeze object
            my ( $frozen, $thawed );
            ok( $frozen = $s->{freeze}->( $o ),
                "... Freezing object"
            );

            # thaw object
            ok( $thawed = $s->{thaw}->( $frozen ),
                "... Thawing object"
            );
            isnt( refaddr $o, refaddr $thawed,
                "... Thawed object is a copy"
            );
            # check name
            is( $thawed->name(), $name,
                "... Property 'name' for thawed object is correct?"
            ) ;

            # check class-specific properties
            for my $prop ( keys %{ $custom_prop_for_class{ $class } } ) {;
                my $val = $custom_prop_for_class{ $class }{ $prop };
                is( $thawed->$prop(), $val,
                    "... Property '$prop' for thawed objects is correct?"
                );
            }
            
            # check thawed contents
            is_deeply( $thawed, $data,
                "... Thawed object contents are correct"
            );
            
            my @leaks = Class::InsideOut::_leaking_memory;
            ok( ! scalar @leaks,
                "... $class not leaking memory"
            ) or diag "Leaks in: @leaks";
        };
    }
}

