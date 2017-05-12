package # hide from PAUSE 
    TestSchema::One::Result::AuditChangeSet;

use base 'DBIx::Class::Core';

__PACKAGE__->table("audit_change_set");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "changeset_ts",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "total_elapsed",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "user_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "client_ip",
  { data_type => "varchar", is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "audit_changes",
  "TestSchema::One::Result::AuditChange",
  { "foreign.changeset_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
