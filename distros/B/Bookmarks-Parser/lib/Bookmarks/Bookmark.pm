package Bookmarks::Bookmark;
use base 'Class::Accessor';
use warnings;

Bookmarks::Bookmark->mk_accessors(
    qw/created modified visited charset url name
        id personal icon description expanded
        trash order type/
);

=head1 NAME

Bookmarks::Bookmark - Object to represent a bookmark.

=head1 DESCRIPTION

This is just a simple representation of a bookmark.

=head1 Accessors

=head2 created

=head2 modified

=head2 visited

=head2 charset

=head2 url

=head2 name

=head2 id

=head2 personal

=head2 icon

=head2 description

=head2 expanded

=head2 trash

=head2 order

=head2 type


=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find
any

=head1 AUTHOR

Jess Robinson <castaway@desert-island.demon.co.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
