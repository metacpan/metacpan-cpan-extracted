package # hide from PAUSE 
    TestSchema::One::Result::AuditChange;

use base 'DBIx::Class::Core';

__PACKAGE__->table("audit_change");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "changeset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "elapsed",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "action",
  { data_type => "char", is_nullable => 0, size => 6 },
  "source",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "row_key",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "changeset",
  "TestSchema::One::Result::AuditChangeSet",
  { id => "changeset_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->has_many(
  "audit_change_columns",
  "TestSchema::One::Result::AuditChangeColumn",
  { "foreign.change_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


1;
