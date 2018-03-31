package Data::Record::Serialize::Encode::types_nis;

use Moo::Role;

has '+_need_types' => ( is => 'rwp', default => 1 );
has '+_use_integer' => ( is => 'rwp', default => 1 );

with 'Data::Record::Serialize::Encode::null';
with 'Data::Record::Serialize::Sink::null';

1;
