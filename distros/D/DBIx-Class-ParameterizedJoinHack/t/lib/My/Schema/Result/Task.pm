package My::Schema::Result::Task;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('tasks');

__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
  summary => { data_type => 'text', is_nullable => 0 },
  assigned_to_id => { data_type => 'integer', is_nullable => 0 },
  urgency => { data_type => 'integer', is_nullable => 0 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
  assigned_to => 'My::Schema::Result::Person',
  { 'foreign.id' => 'self.assigned_to_id' }
);

1;
