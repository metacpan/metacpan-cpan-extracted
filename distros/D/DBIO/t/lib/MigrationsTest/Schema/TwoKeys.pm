package # hide from PAUSE
    MigrationsTest::Schema::TwoKeys;

use warnings;
use strict;

use base qw/MigrationsTest::BaseResult/;

__PACKAGE__->table('twokeys');
__PACKAGE__->add_columns(
  'artist' => { data_type => 'integer' },
  'cd' => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key(qw/artist cd/);

__PACKAGE__->belongs_to(
    artist => 'MigrationsTest::Schema::Artist',
    {'foreign.artistid'=>'self.artist'},
);

__PACKAGE__->belongs_to( cd => 'MigrationsTest::Schema::CD', undef, { is_deferrable => 0, on_update => undef, on_delete => undef, add_fk_index => 0 } );

__PACKAGE__->has_many(
  'fourkeys_to_twokeys', 'MigrationsTest::Schema::FourKeys_to_TwoKeys', {
    'foreign.t_artist' => 'self.artist',
    'foreign.t_cd' => 'self.cd',
});

__PACKAGE__->many_to_many(
  'fourkeys', 'fourkeys_to_twokeys', 'fourkeys',
);

1;
