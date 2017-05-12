package Data::Record::Serialize::Encode::types_ns;

use Moo::Role;

before BUILD => sub {

    $_[0]->_set__use_integer( 0 );

};


with 'Data::Record::Serialize::Encode::null';
with 'Data::Record::Serialize::Sink::null';

1;
