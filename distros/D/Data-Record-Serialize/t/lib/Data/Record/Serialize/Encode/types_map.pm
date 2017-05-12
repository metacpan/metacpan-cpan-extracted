package Data::Record::Serialize::Encode::types_map;

use Moo::Role;

before BUILD => sub {

    $_[0]->_set__use_integer( 1 );
    $_[0]->_set__map_types( { N => 'n', I => 'i', S => 's' } );

};


with 'Data::Record::Serialize::Encode::null';
with 'Data::Record::Serialize::Sink::null';

1;
