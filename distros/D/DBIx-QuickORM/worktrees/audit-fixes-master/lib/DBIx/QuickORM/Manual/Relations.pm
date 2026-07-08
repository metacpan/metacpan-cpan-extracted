package DBIx::QuickORM::Manual::Relations;
use strict;
use warnings;

our $VERSION = '0.000028';

1;

__END__

=head1 NAME

DBIx::QuickORM::Manual::Relations - A guide to relations: defining links
(foreign keys) and following them between rows, plus joins.

=head1 DESCRIPTION

A B<link> in L<DBIx::QuickORM> describes a directional relationship between two
tables: a set of local columns on one table that reference a set of other
columns on another table. This is what most ORMs call a "relationship" or
"foreign key". Once a link is defined you can follow it from a row to its
related rows, insert related rows, find a row's siblings, and build joins.

This guide covers the runtime side of relations: following links between
rows and building joins. For B<defining> links as part of a schema, see
L<DBIx::QuickORM::Manual::Schema> and the C<link> DSL reference in
L<DBIx::QuickORM>.

=head1 DEFINING A LINK (BRIEF)

Links are defined in the schema DSL with C<link>. They can be declared inside
a column (the column is then the local column), or at the schema level
naming both sides:

    table author => sub {
        column author_id => ...;
        column name      => ...;
    };

    table book => sub {
        column book_id   => ...;
        column author_id => sub {
            # This column is the local side; the link points at author.author_id
            link author => [author => ['author_id']];
        };
    };

    # Or declared at the schema level, naming both sides:
    link(
        {table => 'author', columns => ['author_id'], alias => 'books'},
        {table => 'book',   columns => ['author_id'], alias => 'author'},
    );

The full C<link> syntax (column-level form, two-node form, aliases, and the
hashref form) is documented under the C<link> DSL function in
L<DBIx::QuickORM>; composing it into a schema is covered in
L<DBIx::QuickORM::Manual::Schema>. The compiled result is a
L<DBIx::QuickORM::Link> object carrying the local table and columns, the other
table and columns, whether the link is C<unique> on the other side, and any
aliases naming it.

=head1 UNIQUE VS NON-UNIQUE LINKS

A link is either B<unique> or not, depending on whether the other side can
match at most one row:

=over 4

=item Unique link

The other columns are (covered by) a unique constraint or primary key, so
following the link reaches B<at most one> row. Example: a C<book> has one
C<author>. Use C<obtain> to get that single row.

=item Non-unique link

Following the link can reach B<many> rows. Example: an C<author> has many
C<book>s. Use C<follow> to get a handle over all of them.

=back

When a link is built against a schema its C<unique> flag is inferred
automatically from the unique constraints on the other table, so you usually
do not need to set it yourself. C<obtain> croaks if you call it on a
non-unique link.

=head1 RESOLVING A LINK

The relation methods all accept a B<link specification> rather than only a
fully-built L<DBIx::QuickORM::Link> object. A spec may be:

=over 4

=item * An existing L<DBIx::QuickORM::Link> object (used as-is).

=item * A bare string: a B<fuzzy> lookup matched against aliases, then table
names, then column keys (first hit wins).

=item * Keyword pairs that force a specific dimension instead of the fuzzy
match: C<< alias => $name >>, C<< table => $name >>, or
C<< table => $name, columns => \@cols >>.

=item * A hashref describing a new link, which is parsed into one.

=back

Resolution is provided by L<DBIx::QuickORM::Role::Linked> via
C<resolve_link>, which the source uses internally before each traversal. If a
spec is ambiguous (for example, two links to the same table and no alias to
disambiguate) it croaks and lists the candidates.

=head1 FOLLOWING LINKS BETWEEN ROWS

The row-level relation methods live in L<DBIx::QuickORM::Role::Row>. In each
case C<$link> is any spec accepted by C<resolve_link>.

=head2 follow

    my $handle = $row->follow($link);

Returns a L<DBIx::QuickORM::Handle> for the rows reached by following C<$link>
from this row. Because it returns a handle you can refine and iterate it like
any other query:

    my $author = $orm->connection->handle('author')->one(author_id => 1);

    # Every book by this author:
    for my $book ($author->follow('books')->all) {
        print $book->field('title'), "\n";
    }

    # Refine before fetching:
    my $recent = $author->follow('books')
        ->order_by({'-desc' => 'published'})
        ->limit(5);

See L<DBIx::QuickORM::Manual::Querying> for everything a handle can do.

=head2 obtain

    my $related = $row->obtain($link);

Like C<follow>, but for a B<unique> link: it returns the single related row
(equivalent to C<< $row->follow($link)->one >>). Croaks if the link is not
unique.

    my $book   = $orm->connection->handle('book')->one(book_id => 10);
    my $author = $book->obtain('author');
    print $author->field('name'), "\n";

=head2 siblings

    my $handle = $row->siblings($link_or_fields);

Returns a handle for rows that share the same values on the given link's
B<local> columns - this row's "siblings". You may pass a link spec (its local
columns are used) or an explicit arrayref of field names. The result
B<includes the original row>.

    # Other books by the same author (and this book too):
    my $book = $orm->connection->handle('book')->one(book_id => 10);
    my @same_author = $book->siblings([qw/author_id/])->all;

=head2 insert_related

    $row->insert_related($link, \%row_data);

Insert a new related row across C<$link>, automatically filling the linking
columns from this row. You provide the rest of the data; do not include the
linked columns yourself (it croaks if you do).

    my $author = $orm->connection->handle('author')->one(author_id => 1);

    $author->insert_related('books', {
        title     => 'New Book',
        published => '2026-01-01',
        # author_id is filled in automatically from $author
    });

=head1 AUTOROW LINK ACCESSORS

When you enable C<autorow> (see L<DBIx::QuickORM> and
L<DBIx::QuickORM::Manual::Schema>), the generated row classes get named
accessor methods for each link, so you rarely need to pass a link spec by
hand:

=over 4

=item * A B<unique> link generates a singular accessor that calls C<obtain>
and returns the one related row.

=item * A B<non-unique> link generates a plural accessor that calls C<follow>
and returns a handle.

=back

    my $author = $book->author;        # unique link -> obtain, single row
    my @books  = $author->books->all;  # non-unique link -> follow, a handle

The accessor names are derived automatically; you can control them with
C<< autoname link_accessor => sub { ... } >> as described in
L<DBIx::QuickORM>.

=head1 JOINS

Following links one row at a time issues a query per step. When you want a
single query spanning multiple tables, build a B<join> from a handle. The
join methods on L<DBIx::QuickORM::Handle> each take a link spec and return a
new handle whose source is a L<DBIx::QuickORM::Join>:

=over 4

=item C<< $h->join(@args) >>

=item C<< $h->left_join(@args) >>

=item C<< $h->right_join(@args) >>

=item C<< $h->inner_join(@args) >>

=item C<< $h->full_join(@args) >>

=item C<< $h->cross_join(@args) >>

=back

The directional variants are shortcuts that set the join type; a single
argument is taken as the link, otherwise pass key/value pairs (C<link>,
C<as>, C<from>, ...).

    my $h = $orm->connection->handle('book');

    # Books joined to their authors:
    my $joined = $h->left_join('author');

    for my $jrow ($joined->all) {
        # ...
    }

Fetching from a join yields L<DBIx::QuickORM::Join::Row> objects. A join row
holds the per-table pieces of each fetched record (the flat result is split
back out per component table by the join), so you can reach the individual
rows that made up the joined record. Each joined table is given a short alias;
the first/primary table is the anchor and additional tables are added by the
join methods. You can chain joins to span more than two tables, and use the
C<< "alias:link" >> form (or the C<from> parameter) to control which already
joined table a new link attaches to.

Joins have no primary key and are not directly cachable; they are a read-time
construct for fetching related data efficiently. For details on the join
source itself see L<DBIx::QuickORM::Join>.

=head1 SEE ALSO

=over 4

=item L<DBIx::QuickORM::Manual>

The documentation hub.

=item L<DBIx::QuickORM::Manual::QuickStart>

A fast end-to-end introduction, including following relations.

=item L<DBIx::QuickORM::Manual::Schema>

Defining links as part of a schema.

=item L<DBIx::QuickORM::Manual::Querying>

Working with the handles returned by C<follow>, C<siblings>, and the join
methods.

=item L<DBIx::QuickORM::Link>

The link object: local/other tables and columns, C<unique>, C<key>, and
aliases.

=item L<DBIx::QuickORM>

The C<link> DSL reference and C<autorow> link accessors.

=back

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
