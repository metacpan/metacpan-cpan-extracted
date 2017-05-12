# -*-perl-*-

use strict;
use Test::More  tests => 39;

use lib qw( ./t ./lib );

require_ok( 'Class::Factory' );

my $rock_band     = 'Slayer';
my $rock_genre    = 'ROCK';
my $country_band  = 'Plucker';
my $country_genre = 'COUNTRY';

# First do the simple setting

{
    require_ok( 'MySimpleBand' );

    # Set the ISA of our two bands to the one we're testing now

    @MyRockBand::ISA    = qw( MySimpleBand );
    @MyCountryBand::ISA = qw( MySimpleBand );

    my @loaded_classes = MySimpleBand->get_loaded_classes;
    is( scalar @loaded_classes, 1, 'Number of classes loaded so far' );
    is( $loaded_classes[0], 'MyRockBand', 'Default class added' );

    my @loaded_types = MySimpleBand->get_loaded_types;
    is( scalar @loaded_types, 1, 'Number of types loaded so far' );
    is( $loaded_types[0], 'rock', 'Default type added' );

    my @registered_classes = MySimpleBand->get_registered_classes;
    is( scalar @registered_classes, 1, 'Number of classes registered so far' );
    is( $registered_classes[0], 'MyCountryBand', 'Default class registered' );

    my @registered_types = MySimpleBand->get_registered_types;
    is( scalar @registered_types, 1, 'Number of types registered so far' );
    is( $registered_types[0], 'country', 'Default type registered' );
    
	my $registered_class = MySimpleBand->get_registered_class( 'country' );
    is( $registered_class, 'MyCountryBand', 'Get registered class from type');

    my $rock = MySimpleBand->new( 'rock', { band_name => $rock_band } );
    is( ref( $rock ), 'MyRockBand', 'Type of added object returned' );
    is( $rock->band_name(), $rock_band,
        'Added object type super init parameter set' );
    is( $rock->genre(), $rock_genre,
        'Added object type self init parameter set' );
    is( $rock->get_my_factory, 'MySimpleBand',
        'Factory class retrievable from object' );
    is( $rock->get_my_factory_type, 'rock',
        'Factory type retrievable from object' );


    my $country = MySimpleBand->new( 'country', { band_name => $country_band } );
    is( ref( $country ), 'MyCountryBand', 'Type of registered object returned' );
    is( $country->band_name(), $country_band,
        'Registered object type super init parameter set' );
    is( $country->genre(), $country_genre,
        'Registered object type self init parameter set' );
    is( $country->get_my_factory, 'MySimpleBand',
        'Factory class retrievable from object' );
    is( $country->get_my_factory_type, 'country',
        'Factory type retrievable from object' );

    my @loaded_classes_new = MySimpleBand->get_loaded_classes;
    is( scalar @loaded_classes_new, 2, 'Classes loaded after all used' );
    is( $loaded_classes_new[0], 'MyCountryBand', 'Default registered class now loaded' );
    is( $loaded_classes_new[1], 'MyRockBand', 'Default added class still loaded' );

    my @loaded_types_new = MySimpleBand->get_loaded_types;
    is( scalar @loaded_types_new, 2, 'Types loaded after all used' );
    is( $loaded_types_new[0], 'country', 'Default registered type now loaded' );
    is( $loaded_types_new[1], 'rock', 'Default added type still loaded' );

    is( MySimpleBand->get_factory_class( 'country' ), 'MyCountryBand',
        'Proper class returned for registered type' );
    is( MySimpleBand->get_factory_class( 'rock' ), 'MyRockBand',
        'Proper class returned for added type' );

    # reissue an add to get a warning
    MySimpleBand->add_factory_type( rock => 'MyRockBand' );
    is( $MySimpleBand::log_msg,
        "Attempt to add type 'rock' to 'MySimpleBand' redundant; type already exists with class 'MyRockBand'",
        'Generated correct log message with duplicate factory type added' );

    # reissue a registration to get a warning
    MySimpleBand->register_factory_type( country => 'MyCountryBand' );
    is( $MySimpleBand::log_msg,
        "Attempt to register type 'country' with 'MySimpleBand' is redundant; type registered with class 'MyCountryBand'",
        'Generated correct log message with duplicate factory type registered' );

    # generate an error message
    MySimpleBand->add_factory_type( disco => 'SomeKeyboardGuy' );
    ok( $MySimpleBand::error_msg =~ /^Cannot add factory type 'disco' to class 'MySimpleBand': factory class 'SomeKeyboardGuy' cannot be required:/,
        'Generated correct error message when adding nonexistent class' );

    # generate an error message when creating an object of a nonexistent class
    MySimpleBand->register_factory_type( disco => 'SomeKeyboardGuy' );
    my $disco = MySimpleBand->new( 'disco', { shoes => 'white' } );
    ok( $MySimpleBand::error_msg =~ /^Cannot add factory type 'disco' to class 'MySimpleBand': factory class 'SomeKeyboardGuy' cannot be required:/,
        'Generated correct error message when instantiate object with nonexistent class registration' );

    MySimpleBand->unregister_factory_type('country');
    MySimpleBand->new( 'country', { band_name => $country_band } );
    ok( $MySimpleBand::error_msg =~ /^Factory type 'country' is not defined in 'MySimpleBand'/,
        'Error message for instantiating after the factory type was unregistered' );
    
    MySimpleBand->remove_factory_type('rock');
    MySimpleBand->new( 'rock', { band_name => $rock_band } );
    ok( $MySimpleBand::error_msg =~ /^Factory type 'rock' is not defined in 'MySimpleBand'/,
        'Error message for instantiating after the factory type was removed' );
    
    $MySimpleBand::log_msg = '';
    MySimpleBand->add_factory_type( rock => 'MyRockBand' );
    is( $MySimpleBand::log_msg, '', 'no warning after re-adding factory type');

    is(MySimpleBand->get_factory_type_for('MyRockBand'), 'rock',
        'Factory type retrievable for any given class');
    is(MySimpleBand->get_factory_type_for($rock), 'rock',
        'Factory type retrievable for any given object');

    is(MySimpleBand->get_factory_type_for('MyJPopBand'), undef,
        'Factory type undef for unknown class');
}
