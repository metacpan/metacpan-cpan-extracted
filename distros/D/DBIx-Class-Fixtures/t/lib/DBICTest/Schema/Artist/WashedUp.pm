package # hide from PAUSE 
    DBICTest::Schema::Artist::WashedUp;

use base 'DBIx::Class::Core';

__PACKAGE__->table('artist_washed_up');
__PACKAGE__->add_columns(
  'fk_artistid' => {
    data_type => 'integer',
  },
);

__PACKAGE__->set_primary_key('fk_artistid');
__PACKAGE__->belongs_to(
  'artist', 'DBICTest::Schema::Artist',
  { 'foreign.artistid' => 'self.fk_artistid' }
);

1;
