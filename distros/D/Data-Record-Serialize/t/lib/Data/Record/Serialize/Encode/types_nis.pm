package Data::Record::Serialize::Encode::types_nis;

use Moo::Role;

before BUILD => sub {

    $_[0]->_set__use_integer( 1 );

};


with 'Data::Record::Serialize::Encode::null';
with 'Data::Record::Serialize::Sink::null';

1;
