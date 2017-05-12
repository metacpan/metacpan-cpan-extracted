package Blog::BookmarkEntry;
use strict;
use warnings;
use base qw(DBIx::MoCo::Join Blog::Bookmark Blog::Entry);
use Blog::DataBase;
use Blog::User;

__PACKAGE__->db_object('Blog::DataBase');
__PACKAGE__->table('bookmark inner join entry using(entry_id)');
__PACKAGE__->has_a(
    entry => 'Blog::Entry',
    { key => 'entry_id' }
);
__PACKAGE__->has_a(
    user => 'Blog::User',
    { key => 'user_id' }
);

1;
