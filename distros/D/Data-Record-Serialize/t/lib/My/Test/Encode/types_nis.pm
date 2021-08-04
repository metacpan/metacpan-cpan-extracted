package My::Test::Encode::types_nis;

use Moo::Role;

sub _map_types { { N => 'n', I => 'i', S => 's' } }

with 'Data::Record::Serialize::Encode::null';
with 'Data::Record::Serialize::Sink::null';

1;
