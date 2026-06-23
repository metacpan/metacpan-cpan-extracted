package # hide from PAUSE
    MigrationsTest::Schema::Bookmark;

use strict;
use warnings;

use base qw/MigrationsTest::BaseResult/;

__PACKAGE__->table('bookmark');
__PACKAGE__->add_columns(
    'id' => {
        data_type => 'integer',
        is_auto_increment => 1
    },
    'link' => {
        data_type => 'integer',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');

require MigrationsTest::Schema::Link; # so we can get a columnlist
__PACKAGE__->belongs_to(
    link => 'MigrationsTest::Schema::Link', 'link', {
    on_delete => 'SET NULL',
    join_type => 'LEFT',
    proxy => { map { join('_', 'link', $_) => $_ } MigrationsTest::Schema::Link->columns },
});

1;
