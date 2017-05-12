package AuditTestCascade::Schema::Result::Title;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components('AuditLog');

__PACKAGE__->table('title');

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "name",
    {   data_type     => "varchar",
        default_value => "",
        is_nullable   => 0,
        size          => 32
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->might_have(
    "book",
    "AuditTestCascade::Schema::Result::Book",
    { "foreign.id" => "self.id" },
);

__PACKAGE__->add_unique_constraint( "name", ["name"] );

1;
