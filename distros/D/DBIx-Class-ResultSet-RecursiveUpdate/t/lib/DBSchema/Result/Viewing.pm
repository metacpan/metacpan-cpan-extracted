package DBSchema::Result::Viewing;
use base 'DBIx::Class::Core';

__PACKAGE__->table('viewing');
__PACKAGE__->add_columns(
  'user_id' => { data_type => 'integer' },
  'dvd_id' => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key(qw/user_id dvd_id/);

__PACKAGE__->belongs_to(
    user => 'DBSchema::Result::User',
    {'foreign.id'=>'self.user_id'},
);

__PACKAGE__->belongs_to( 
    dvd => 'DBSchema::Result::Dvd',
    {'foreign.dvd_id'=>'self.dvd_id'},
);

;

1;
