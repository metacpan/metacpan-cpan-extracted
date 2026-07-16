package Schema::Nested::Result::XMiddle;

use base 'Schema::Result';

__PACKAGE__->table("middle");

__PACKAGE__->add_columns(
  middle_id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
  middle_value => { data_type => 'varchar', is_nullable => 0, size => 48 },
  top_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 }
);

__PACKAGE__->set_primary_key("middle_id");

__PACKAGE__->belongs_to(
  top =>
  'Schema::Nested::Result::XTop',
  { 'foreign.top_id' => 'self.top_id' },
);

__PACKAGE__->has_one(
  bottom =>
  'Schema::Nested::Result::XBottom',
  { 'foreign.middle_id' => 'self.middle_id' },
);


__PACKAGE__->validates(middle_value => (presence=>1, length=>[4,48]));
#__PACKAGE__->validates(bottom => ( result=>+{validations=>1} ));
__PACKAGE__->accept_nested_for(bottom => { update_only => 1 });

1;
