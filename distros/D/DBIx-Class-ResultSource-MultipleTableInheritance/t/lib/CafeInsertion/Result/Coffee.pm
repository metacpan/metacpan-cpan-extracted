package    # hide from PAUSE
    CafeInsertion::Result::Coffee;

use strict;
use warnings;
use parent 'DBIx::Class::Core';
use aliased 'DBIx::Class::ResultSource::MultipleTableInheritance' => 'MTI';

__PACKAGE__->table_class(MTI);
__PACKAGE__->table('coffee');

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        sequence          => '_coffee_id_seq'
    },
    "flavor",
    { data_type => "text", default_value => "good" },
);

__PACKAGE__->set_primary_key("id");

1;
