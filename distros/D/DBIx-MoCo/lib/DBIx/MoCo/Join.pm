package DBIx::MoCo::Join;
use strict;
use Carp;
use base qw(DBIx::MoCo::Readonly);

sub primary_keys {[]}
sub unique_keys {[]}
sub cache {}
sub columns {}

1;

=head1 NAME

DBIx::MoCo::Join - Base class for joined DBIx::MoCo classes.

=head1 SYNOPSIS

  package Blog::BookmarkEntry;
  use base qw(DBIx::MoCo::Join Blog::Bookmark Blog::Entry);

  __PACKAGE__->table('bookmark inner join entry using(entry_id)');
  __PACKAGE__->has_a(
    entry => 'Blog::Entry',
    { key => 'entry_id' },
  );

  1;

Then you can use this class for search etc...

  my $bookmarks = Blog::BookmarkEntry->search(
    where => ['uri = ?', $uri], # search by entry's field
  );
  print $bookmarks->first->title; # able to use Blog::Entry's method

=head1 SEE ALSO

L<DBIx::MoCo>

=head1 AUTHOR

Junya Kondo, E<lt>jkondo@hatena.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
