package # hide from PAUSE
    MigrationsTest::Schema::Lyrics;

use warnings;
use strict;

use base qw/MigrationsTest::BaseResult/;

__PACKAGE__->table('lyrics');
__PACKAGE__->add_columns(
  'lyric_id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'track_id' => {
    data_type => 'integer',
    is_foreign_key => 1,
  },
);
__PACKAGE__->set_primary_key('lyric_id');
__PACKAGE__->belongs_to('track', 'MigrationsTest::Schema::Track', 'track_id');
__PACKAGE__->has_many('lyric_versions', 'MigrationsTest::Schema::LyricVersion', 'lyric_id');

__PACKAGE__->has_many('existing_lyric_versions', 'MigrationsTest::Schema::LyricVersion', 'lyric_id', {
  join_type => 'inner',
});

1;
