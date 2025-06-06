package DBIx::Class::Helper::ResultSet::CorrelateRelationship;
$DBIx::Class::Helper::ResultSet::CorrelateRelationship::VERSION = '2.037000';
# ABSTRACT: Easily correlate your ResultSets

use strict;
use warnings;

use DBIx::Class::Helper::ResultSet::Util
   correlate => { -as => 'corr' };

sub correlate { corr(@_) }

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::CorrelateRelationship - Easily correlate your ResultSets

=head1 SYNOPSIS

 package MyApp::Schema::ResultSet::Author;

 use parent 'DBIx::Class::ResultSet';

 __PACKAGE__->load_components(qw(Helper::ResultSet::CorrelateRelationship));

 sub with_book_count {
   my $self = shift;

   $self->search(undef, {
     '+columns' => {
       book_count => $self->correlate('books')->count_rs->as_query
     }
   });
 }

 1;

And then elsewhere, like in a controller:

 my $rows = $schema->resultset('Author')->with_book_count->all;

=head1 DESCRIPTION

Correlated queries are one of the coolest things I've learned about for SQL
since my initial learning of SQL.  Unfortunately they are somewhat confusing.
L<DBIx::Class> has supported doing them for a long time, but generally people
don't think of them because they are so rare.  I won't go through all the
details of how they work and cool things you can do with them, but here are a
couple high level things you can use them for to save you time or effort.

If you want to select a list of authors and counts of books for each author,
you B<could> use C<group_by> and something like C<COUNT(book.id)>, but then
you'd need to make your select list match your C<group_by> and it would just
be a hassle forever after that.  The L</SYNOPSIS> is a perfect example of how
to implement this.

If you want to select a list of authors and two separate kinds of counts of
books for each author, as far as I know, you B<must> use a correlated subquery
in L<DBIx::Class>.  Here is an example of how you might do that:

 package MyApp::Schema::ResultSet::Author;

 use parent 'DBIx::Class::ResultSet';

 __PACKAGE__->load_components(qw(Helper::ResultSet::CorrelateRelationship));

 sub with_good_book_count {
   my $self = shift;

   $self->search(undef, {
     '+columns' => {
       good_book_count => $self->correlate('books')->good->count_rs->as_query
     }
   });
 }

 sub with_bad_book_count {
   my $self = shift;

   $self->search(undef, {
     '+columns' => {
       bad_book_count => $self->correlate('books')->bad->count_rs->as_query
     }
   });
 }

 1;

And then elsewhere, like in a controller:

 my $rows = $schema->resultset('Author')
   ->with_bad_book_count
   ->with_good_book_count
   ->all;

This assumes that the Book resultset has C<good> and C<bad> methods.

See L<DBIx::Class::Helper::ResultSet/NOTE> for a nice way to apply it to
your entire schema.

=head1 METHODS

=head2 correlate

 $rs->correlate($relationship_name)

Correlate takes a single argument, a relationship for the invocant, and returns
a resultset that can be used in the selector list.

=head1 EXAMPLES

=head2 counting CD's and Tracks of Artists

If you had an Artist ResultSet and you wanted to count the tracks and CD's per
Artist, here is a recipe that will work:

 sub with_track_count {
   my $self = shift;

   $self->search(undef, {
     '+columns' => {
       track_count => $self->correlate('cds')
         ->related_resultset('tracks')
         ->count_rs
         ->as_query
     }
   });
 }

 sub with_cd_count {
   my $self = shift;

   $self->search(undef, {
     '+columns' => {
       cd_count => $self->correlate('cds')
         ->count_rs
         ->as_query
     }
   });
 }

 # elsewhere

 my @artists = $artists->with_cd_count->with_track_count->all;

Note that the following will B<not> work:

 sub BUSTED_with_track_count {
   my $self = shift;

   $self->search(undef, {
     '+columns' => {
       track_count => $self->related_resultset('cds')
         ->correlate('tracks')
         ->count_rs
         ->as_query
     }
   });
 }

The above is broken because C<correlate> returns a fresh resultset that will
only work as a subquery to the ResultSet it was chained off of.  The upshot
of that is that the above C<tracks> relationship is on the C<cds> ResultSet,
whereas the query is for the Artist ResultSet, so the correlation will be
"broken" by effectively "joining" to columns that are not in the current scope.

For the same reason, the following will also not work:

 sub BUSTED2_with_track_count {
   my $self = shift;

   $self->search(undef, {
     '+columns' => {
       track_count => $self->correlate('cds')
         ->correlate('tracks')
         ->count_rs
         ->as_query
     }
   });
 }

=head1 SEE ALSO

=over

=item * L<Introducing DBIx::Class::Helper::ResultSet::CorrelateRelationship|https://blog.afoolishmanifesto.com/posts/introducing-dbix-class-helper-resultset-correlaterelationship/>

=item * L<Set-based DBIx::Class Advent Article|http://www.perladvent.org/2012/2012-12-21.html>

=back

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
