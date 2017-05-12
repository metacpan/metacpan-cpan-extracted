package Test::SchemaNonPK::Result::Session;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(TimeStamp));

__PACKAGE__->table("sessions");

__PACKAGE__->add_columns(
  "pk_id",
  { data_type => "integer", is_nullable => 0 },
  "sessions_id",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "session_data",
  { data_type => "text", is_nullable => 0 },
  "created",
  { data_type => "datetime", set_on_create => 1, is_nullable => 0 },
  "last_modified",
  { data_type => "datetime", set_on_create => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("pk_id");
__PACKAGE__->add_unique_constraint(
    'unique_sessions_id' => [ qw/ sessions_id / ],
);

1;
