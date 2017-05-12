package # hide from PAUSE 
    DBICTest::Schema::CD;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( qw/ Row::Slave / );
__PACKAGE__->table('cd');
__PACKAGE__->add_columns(
  'cdid' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'artist' => {
    data_type => 'integer',
  },
  'title' => {
    data_type => 'varchar',
    size      => 100,
  },
  'year' => {
    data_type => 'varchar',
    size      => 100,
  },
);
__PACKAGE__->set_primary_key('cdid');
__PACKAGE__->add_unique_constraint([ qw/artist title/ ]);

__PACKAGE__->belongs_to( artist => 'DBICTest::Schema::Artist' );

__PACKAGE__->has_many( tracks => 'DBICTest::Schema::Track' );

1;
