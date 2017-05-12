package # hide from PAUSE 
    TestSchema::One::Result::AuditChangeColumn;

use base 'DBIx::Class::Core';

__PACKAGE__->table("audit_change_column");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "change_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "column",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "old",
  { data_type => "mediumtext", is_nullable => 1 },
  "new",
  { accessor => undef, data_type => "mediumtext", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("change_id", ["change_id", "column"]);

__PACKAGE__->belongs_to(
  "change",
  "TestSchema::One::Result::AuditChange",
  { id => "change_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
