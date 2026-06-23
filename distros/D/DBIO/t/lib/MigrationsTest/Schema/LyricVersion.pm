package # hide from PAUSE
    MigrationsTest::Schema::LyricVersion;

use warnings;
use strict;

use base qw/MigrationsTest::BaseResult/;

__PACKAGE__->table('lyric_versions');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'lyric_id' => {
    data_type => 'integer',
    is_foreign_key => 1,
  },
  'text' => {
    data_type => 'varchar',
    size => 100,
  },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint ([qw/lyric_id text/]);
__PACKAGE__->belongs_to('lyric', 'MigrationsTest::Schema::Lyrics', 'lyric_id');

1;
