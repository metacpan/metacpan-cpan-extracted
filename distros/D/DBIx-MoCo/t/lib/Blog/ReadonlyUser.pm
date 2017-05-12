package Blog::ReadonlyUser;
use strict;
use warnings;
use base qw(DBIx::MoCo::Readonly);
use Blog::DataBase;
use Blog::Entry;

__PACKAGE__->db_object('Blog::DataBase');
__PACKAGE__->table('user');
__PACKAGE__->has_many(
    entries => 'Blog::Entry',
    { key => 'user_id' }
);
__PACKAGE__->has_many(
    bookmarks => 'Blog::Bookmark',
    { key => 'user_id' }
);

1;
