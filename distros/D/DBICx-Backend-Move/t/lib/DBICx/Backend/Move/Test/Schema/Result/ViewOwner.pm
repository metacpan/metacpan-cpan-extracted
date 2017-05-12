package DBICx::Backend::Move::Test::Schema::Result::ViewOwner;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('view_owner');

__PACKAGE__->result_source_instance->is_virtual(0);
__PACKAGE__->result_source_instance->view_definition
    (
     "select owner.name as name, owner.surname as surname from owner"
    );

__PACKAGE__->add_columns
    (
     "name",    { data_type => "text",    is_nullable => 1 },
     "surname", { data_type => "varchar", default_value => "-", is_nullable => 0, size => 80 },
    );

1;
