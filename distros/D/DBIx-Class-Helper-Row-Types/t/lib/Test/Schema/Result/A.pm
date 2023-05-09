package Test::Schema::Result::A;

use base qw/DBIx::Class::Core/;

use Types::SQL qw/ Serial Varchar /;
use Types::Standard qw/ Maybe /;
use Types::Common::String qw/ LowerCaseSimpleStr UpperCaseStr /;

__PACKAGE__->load_components(qw/ Helper::Row::Types /);

__PACKAGE__->table('a');

__PACKAGE__->add_columns(

    id => Serial,

    name => {
        isa    => LowerCaseSimpleStr,
        strict => 1,
    },

    model => {
        isa    => Maybe[UpperCaseStr],
        strict => 1,
        coerce => 1,
    },

    serial_number => {
        isa => Varchar [32], #
        is_numeric => 1,     # overridden
    },

);

__PACKAGE__->set_primary_key('id');

1;
