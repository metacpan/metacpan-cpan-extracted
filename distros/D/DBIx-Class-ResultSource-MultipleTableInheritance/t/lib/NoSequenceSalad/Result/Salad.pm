package    # hide from PAUSE
    NoSequenceSalad::Result::Salad;

use strict;
use warnings;
use parent 'DBIx::Class::Core';
use aliased 'DBIx::Class::ResultSource::MultipleTableInheritance' => 'MTI';

__PACKAGE__->table_class(MTI);
__PACKAGE__->table('salad');
__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        #sequence => '_salad_id_seq',
    },
    "fresh",
    { data_type => "boolean", },
);

__PACKAGE__->set_primary_key("id");

1;
