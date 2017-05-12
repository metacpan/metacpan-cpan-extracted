package AproJo::DB::Schema::Result::Party;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("parties");

__PACKAGE__->add_columns(
  "party_id",
  {data_type => "integer", is_auto_increment => 1, is_nullable => 0},
  "name",
  {data_type => "varchar", is_nullable => 0, size => 50},
  "address_id",
  {data_type => "integer", is_nullable => 0, is_foreign_key => 1},
  "billingaddress_id",
  {data_type => "integer", is_nullable => 0, is_foreign_key => 1},
  "deliveryaddress_id",
  {data_type => "integer", is_nullable => 0, is_foreign_key => 1},
  "comment",
  {data_type => "text", default_value => '', is_nullable => 1},
);

__PACKAGE__->set_primary_key("party_id");

__PACKAGE__->has_one(
  'address',
  'AproJo::DB::Schema::Result::Address',
  {'foreign.address_id' => 'self.address_id'},
  {cascade_delete       => 0}
);

__PACKAGE__->might_have(
  'billingaddress',
  'AproJo::DB::Schema::Result::Address',
  {'foreign.address_id' => 'self.billingaddress_id'},
  {cascade_delete       => 0}
);

__PACKAGE__->might_have(
  'deliveryaddress',
  'AproJo::DB::Schema::Result::Address',
  {'foreign.address_id' => 'self.deliveryaddress_id'},
  {cascade_delete       => 0}
);

1;
