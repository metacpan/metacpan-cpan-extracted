package Schema::Nested::Result::State;

use strict;
use warnings;

use base 'Schema::Result';

__PACKAGE__->table("state");

__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
  name => { data_type => 'varchar', is_nullable => 0, size => '24' },
  abbreviation => { data_type => 'varchar', is_nullable => 0, size => '24' },
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(['name']);
__PACKAGE__->add_unique_constraint(['abbreviation']);

__PACKAGE__->validates(abbreviation => (presence=>1, length=>[2,2], with=>'is_existing_abbr'));

__PACKAGE__->has_many(
   people =>
  'Schema::Nested::Result::Person',
  { 'foreign.state_id' => 'self.id' }
);

sub is_existing_abbr {
  my ($self, $attribute_name, $value) = @_;
  return if my $result = $self->result_source->resultset->find({$attribute_name=>$value});
  $self->errors->add($attribute_name, \'{{value}} is not a valid State Abbreviation'); 
}

1;
