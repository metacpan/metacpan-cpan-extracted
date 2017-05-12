package Blog::Bookmark;
use strict;
use warnings;
use base qw 'Blog::Class';
use Blog::User;
use Blog::Entry;

__PACKAGE__->table('bookmark');
__PACKAGE__->has_a(
    user => 'Blog::User',
    { key => 'user_id' }
);
__PACKAGE__->has_a(
    entry => 'Blog::Entry',
    { key => 'entry_id' }
);

1;
