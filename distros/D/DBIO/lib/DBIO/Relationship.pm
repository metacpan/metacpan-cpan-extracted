package DBIO::Relationship;
# ABSTRACT: Relationship declaration helpers for DBIO result classes

use strict;
use warnings;

use base qw/DBIO::Base/;

__PACKAGE__->load_own_components(qw/
  Helpers
  Codegen
  CascadeActions
  Base
/);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Relationship - Relationship declaration helpers for DBIO result classes

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  ## Creating relationships
  MyApp::Schema::Actor->has_many('actorroles' => 'MyApp::Schema::ActorRole',
                                'actor');
  MyApp::Schema::Role->has_many('actorroles' => 'MyApp::Schema::ActorRole',
                                'role');
  MyApp::Schema::ActorRole->belongs_to('role' => 'MyApp::Schema::Role');
  MyApp::Schema::ActorRole->belongs_to('actor' => 'MyApp::Schema::Actor');

  MyApp::Schema::Role->many_to_many('actors' => 'actorroles', 'actor');
  MyApp::Schema::Actor->many_to_many('roles' => 'actorroles', 'role');

  ## Using relationships
  $schema->resultset('Actor')->find({ id => 1})->roles();
  $schema->resultset('Role')->find({ id => 1 })->actorroles->search_related('actor', { Name => 'Fred' });
  $schema->resultset('Actor')->add_to_roles({ Name => 'Sherlock Holmes'});

See L<DBIO::Manual::Cookbook> for more.

=head1 DESCRIPTION

The word I<Relationship> has a specific meaning in DBIO; see
L<DBIO::Manual::Glossary/Relationship> for the formal definition.

This module provides the declaration helpers used in result classes:
C<belongs_to>, C<has_many>, C<has_one>, C<might_have>, and
C<many_to_many>. These declarations are what let DBIO traverse between
tables, build joins automatically, and offer the various C<*_related>
methods on rows and resultsets.

Relationships are one of the most important parts of a DBIO schema. For
example, imagine a table C<Authors>:

  ID  | Name | Age
 ------------------
   1  | Fred | 30
   2  | Joe  | 32

and a table C<Books>:

  ID  | Author | Name
 --------------------
   1  |      1 | Rulers of the universe
   2  |      1 | Rulers of the galaxy

Without relationships, fetching all books by Fred looks like this:

 my $fred = $schema->resultset('Author')->find({ Name => 'Fred' });
 my $fredsbooks = $schema->resultset('Book')->search({ Author => $fred->ID });

With a C<has_many> relationship called C<books> on C<Author>, you can instead
write:

 my $fredsbooks = $schema->resultset('Author')->find({ Name => 'Fred' })->books;

Each relationship installs an accessor on
L<result objects|DBIO::Manual::Glossary/Result>, and the corresponding
L<DBIO::ResultSet> methods can follow the same relationship through
C<search_related>, C<related_resultset>, joins, and prefetches. In scalar
context you typically get a ResultSet back, which means these calls chain
naturally into larger queries while staying lazy until data is actually
requested.

 my $cheapfredbooks = $schema->resultset('Author')->find({
   Name => 'Fred',
 })->books->search_related('prices', {
   Price => { '<=' => '5.00' },
 });

This yields a query roughly like:

 SELECT * FROM Author me
 LEFT JOIN Books books ON books.author = me.id
 LEFT JOIN Prices prices ON prices.book = books.id
 WHERE prices.Price <= 5.00

all without manual join bookkeeping or multiple fetches.

This module documents the common relationship declaration helpers. For the
lower-level API, plus the full family of C<*_related> methods that appear as a
result, see L<DBIO::Relationship::Base>.

=head1 METHODS

All helper methods are called similar to the following template:

  __PACKAGE__->$method_name('rel_name', 'Foreign::Class', \%cond|\@cond|\&cond?, \%attrs?);

Both C<cond> and C<attrs> are optional. Pass C<undef> for C<cond> if
you want to use the default value for it, but still want to set C<attrs>.

See L<DBIO::Relationship::Base/condition> for full documentation on
definition of the C<cond> argument.

See L<DBIO::Relationship::Base/attributes> for documentation on the
attributes that are allowed in the C<attrs> argument.

=head2 belongs_to

=over 4

=item Arguments: $accessor_name, $related_class, $our_fk_column|\%cond|\@cond|\$cond?, \%attrs?

=back

Creates a relationship where the calling class stores the foreign
class's primary key in one (or more) of the calling class columns.
This relationship defaults to using C<$accessor_name> as the column
name in this class to resolve the join against the primary key from
C<$related_class>, unless C<$our_fk_column> specifies the foreign key column
in this class or C<cond> specifies a reference to a join condition.

=over

=item accessor_name

This argument is the name of the method you can call on a
L<Result|DBIO::Manual::ResultClass> object to retrieve the instance of the foreign
class matching this relationship. This is often called the
C<relation(ship) name>.

Use this accessor_name in L<DBIO::ResultSet/join>
or L<DBIO::ResultSet/prefetch> to join to the foreign table
indicated by this relationship.

=item related_class

This is the class name of the table referenced by the foreign key in
this class.

=item our_fk_column

The column name on this class that contains the foreign key.

OR

=item cond

A hashref, arrayref or coderef specifying a custom join expression. For
more info see L<DBIO::Relationship::Base/condition>.

=back

  # in a Book class (where Author has many Books)
  My::DBIO::Schema::Book->belongs_to(
    author =>
    'My::DBIO::Schema::Author',
    'author_id'
  );

  # OR (same result)
  My::DBIO::Schema::Book->belongs_to(
    author =>
    'My::DBIO::Schema::Author',
    { 'foreign.author_id' => 'self.author_id' }
  );

  # OR (similar result but uglier accessor name)
  My::DBIO::Schema::Book->belongs_to(
    author_id =>
    'My::DBIO::Schema::Author'
  );

  # Usage
  my $author_obj = $book->author; # get author object
  $book->author( $new_author_obj ); # set author object
  $book->author_id(); # get the plain id

  # To retrieve the plain id if you used the ugly version:
  $book->get_column('author_id');

If some of the foreign key columns are
L<nullable|DBIO::ResultSource/is_nullable> you probably want to set
the L<join_type|DBIO::Relationship::Base/join_type> attribute to
C<left> explicitly so that SQL expressing this relation is composed with
a C<LEFT JOIN> (as opposed to C<INNER JOIN> which is default for
L</belongs_to> relationships). This ensures that relationship traversal
works consistently in all situations. (i.e. resultsets involving
L<join|DBIO::ResultSet/join> or
L<prefetch|DBIO::ResultSet/prefetch>).
The modified declaration is shown below:

  # in a Book class (where Author has_many Books)
  __PACKAGE__->belongs_to(
    author =>
    'My::DBIO::Schema::Author',
    'author',
    { join_type => 'left' }
  );

Cascading deletes are off by default on a C<belongs_to>
relationship. To turn them on, pass C<< cascade_delete => 1 >>
in the $attr hashref.

By default, DBIO will return undef and avoid querying the database if a
C<belongs_to> accessor is called when any part of the foreign key IS NULL. To
disable this behavior, pass C<< undef_on_null_fk => 0 >> in the C<\%attrs>
hashref.

NOTE: If you are used to L<Class::DBI> relationships, this is the equivalent
of C<has_a>.

See L<DBIO::Relationship::Base/attributes> for documentation on relationship
methods and valid relationship attributes. Also see L<DBIO::ResultSet>
for a L<list of standard resultset attributes|DBIO::ResultSet/ATTRIBUTES>
which can be assigned to relationships as well.

=head2 has_many

=over 4

=item Arguments: $accessor_name, $related_class, $their_fk_column|\%cond|\@cond|\&cond?, L<\%attrs?|DBIO::ResultSet/ATTRIBUTES>

=back

Creates a one-to-many relationship where the foreign class refers to
this class's primary key. This relationship refers to zero or more
records in the foreign table (e.g. a C<LEFT JOIN>). This relationship
defaults to using the end of this classes namespace as the foreign key
in C<$related_class> to resolve the join, unless C<$their_fk_column>
specifies the foreign key column in C<$related_class> or C<cond>
specifies a reference to a join condition.

=over

=item accessor_name

This argument is the name of the method you can call on a
L<Result|DBIO::Manual::ResultClass> object to retrieve a resultset of the related
class restricted to the ones related to the result object. In list
context it returns the result objects. This is often called the
C<relation(ship) name>.

Use this accessor_name in L<DBIO::ResultSet/join>
or L<DBIO::ResultSet/prefetch> to join to the foreign table
indicated by this relationship.

=item related_class

This is the class name of the table which contains a foreign key
column containing PK values of this class.

=item their_fk_column

The column name on the related class that contains the foreign key.

OR

=item cond

A hashref, arrayref  or coderef specifying a custom join expression. For
more info see L<DBIO::Relationship::Base/condition>.

=back

  # in an Author class (where Author has_many Books)
  # assuming related class is storing our PK in "author_id"
  My::DBIO::Schema::Author->has_many(
    books =>
    'My::DBIO::Schema::Book',
    'author_id'
  );

  # OR (same result)
  My::DBIO::Schema::Author->has_many(
    books =>
    'My::DBIO::Schema::Book',
    { 'foreign.author_id' => 'self.id' },
  );

  # OR (similar result, assuming related_class is storing our PK, in "author")
  # (the "author" is guessed at from "Author" in the class namespace)
  My::DBIO::Schema::Author->has_many(
    books =>
    'My::DBIO::Schema::Book',
  );


  # Usage
  # resultset of Books belonging to author
  my $booklist = $author->books;

  # resultset of Books belonging to author, restricted by author name
  my $booklist = $author->books({
    name => { LIKE => '%macaroni%' },
    { prefetch => [qw/book/],
  });

  # array of Book objects belonging to author
  my @book_objs = $author->books;

  # force resultset even in list context
  my $books_rs = $author->books;
  ( $books_rs ) = $obj->books_rs;

  # create a new book for this author, the relation fields are auto-filled
  $author->create_related('books', \%col_data);
  # alternative method for the above
  $author->add_to_books(\%col_data);

Three methods are created when you create a has_many relationship.
The first method is the expected accessor method, C<$accessor_name()>.
The second is almost exactly the same as the accessor method but "_rs"
is added to the end of the method name, eg C<$accessor_name_rs()>.
This method works just like the normal accessor, except that it always
returns a resultset, even in list context. The third method, named C<<
add_to_$rel_name >>, will also be added to your Row items; this allows
you to insert new related items, using the same mechanism as in
L<DBIO::Relationship::Base/"create_related">.

If you delete an object in a class with a C<has_many> relationship, all
the related objects will be deleted as well.  To turn this behaviour off,
pass C<< cascade_delete => 0 >> in the C<$attr> hashref.

The cascaded operations are performed after the requested delete or
update, so if your database has a constraint on the relationship, it
will have deleted/updated the related records or raised an exception
before DBIO gets to perform the cascaded operation.

If you copy an object in a class with a C<has_many> relationship, all
the related objects will be copied as well. To turn this behaviour off,
pass C<< cascade_copy => 0 >> in the C<$attr> hashref. The behaviour
defaults to C<< cascade_copy => 1 >>.

See L<DBIO::Relationship::Base/attributes> for documentation on
relationship methods and valid relationship attributes. Also see
L<DBIO::ResultSet> for a L<list of standard resultset
attributes|DBIO::ResultSet/ATTRIBUTES> which can be assigned to
relationships as well.

=head2 might_have

=over 4

=item Arguments: $accessor_name, $related_class, $their_fk_column|\%cond|\@cond|\&cond?, L<\%attrs?|DBIO::ResultSet/ATTRIBUTES>

=back

Creates an optional one-to-one relationship with a class. This relationship
defaults to using C<$accessor_name> as the foreign key in C<$related_class> to
resolve the join, unless C<$their_fk_column> specifies the foreign key
column in C<$related_class> or C<cond> specifies a reference to a join
condition.

=over

=item accessor_name

This argument is the name of the method you can call on a
L<Result|DBIO::Manual::ResultClass> object to retrieve the instance of the foreign
class matching this relationship. This is often called the
C<relation(ship) name>.

Use this accessor_name in L<DBIO::ResultSet/join>
or L<DBIO::ResultSet/prefetch> to join to the foreign table
indicated by this relationship.

=item related_class

This is the class name of the table which contains a foreign key
column containing PK values of this class.

=item their_fk_column

The column name on the related class that contains the foreign key.

OR

=item cond

A hashref, arrayref  or coderef specifying a custom join expression. For
more info see L<DBIO::Relationship::Base/condition>.

=back

  # Author may have an entry in the pseudonym table
  My::DBIO::Schema::Author->might_have(
    pseudonym =>
    'My::DBIO::Schema::Pseudonym',
    'author_id',
  );

  # OR (same result, assuming the related_class stores our PK)
  My::DBIO::Schema::Author->might_have(
    pseudonym =>
    'My::DBIO::Schema::Pseudonym',
  );

  # OR (same result)
  My::DBIO::Schema::Author->might_have(
    pseudonym =>
    'My::DBIO::Schema::Pseudonym',
    { 'foreign.author_id' => 'self.id' },
  );

  # Usage
  my $pname = $author->pseudonym; # to get the Pseudonym object

If you update or delete an object in a class with a C<might_have>
relationship, the related object will be updated or deleted as well. To
turn off this behavior, add C<< cascade_delete => 0 >> to the C<$attr>
hashref.

The cascaded operations are performed after the requested delete or
update, so if your database has a constraint on the relationship, it
will have deleted/updated the related records or raised an exception
before DBIO gets to perform the cascaded operation.

See L<DBIO::Relationship::Base/attributes> for documentation on
relationship methods and valid relationship attributes. Also see
L<DBIO::ResultSet> for a L<list of standard resultset
attributes|DBIO::ResultSet/ATTRIBUTES> which can be assigned to
relationships as well.

Note that if you supply a condition on which to join, and the column in the
current table allows nulls (i.e., has the C<is_nullable> attribute set to a
true value), than C<might_have> will warn about this because it's naughty and
you shouldn't do that. The warning will look something like:

  "might_have/has_one" must not be on columns with is_nullable set to true (MySchema::SomeClass/key)

If you must be naughty, you can suppress the warning by setting
C<DBIO_DONT_VALIDATE_RELS> (legacy alias: C<DBIC_DONT_VALIDATE_RELS>)
environment variable to a true value.  Otherwise,
you probably just meant to use C<DBIO::Relationship/belongs_to>.

=head2 has_one

=over 4

=item Arguments: $accessor_name, $related_class, $their_fk_column|\%cond|\@cond|\&cond?, L<\%attrs?|DBIO::ResultSet/ATTRIBUTES>

=back

Creates a one-to-one relationship with a class. This relationship
defaults to using C<$accessor_name> as the foreign key in C<$related_class> to
resolve the join, unless C<$their_fk_column> specifies the foreign key
column in C<$related_class> or C<cond> specifies a reference to a join
condition.

=over

=item accessor_name

This argument is the name of the method you can call on a
L<Result|DBIO::Manual::ResultClass> object to retrieve the instance of the foreign
class matching this relationship. This is often called the
C<relation(ship) name>.

Use this accessor_name in L<DBIO::ResultSet/join>
or L<DBIO::ResultSet/prefetch> to join to the foreign table
indicated by this relationship.

=item related_class

This is the class name of the table which contains a foreign key
column containing PK values of this class.

=item their_fk_column

The column name on the related class that contains the foreign key.

OR

=item cond

A hashref, arrayref  or coderef specifying a custom join expression. For
more info see L<DBIO::Relationship::Base/condition>.

=back

  # Every book has exactly one ISBN
  My::DBIO::Schema::Book->has_one(
    isbn =>
    'My::DBIO::Schema::ISBN',
    'book_id',
  );

  # OR (same result, assuming related_class stores our PK)
  My::DBIO::Schema::Book->has_one(
    isbn =>
    'My::DBIO::Schema::ISBN',
  );

  # OR (same result)
  My::DBIO::Schema::Book->has_one(
    isbn =>
    'My::DBIO::Schema::ISBN',
    { 'foreign.book_id' => 'self.id' },
  );

  # Usage
  my $isbn_obj = $book->isbn; # to get the ISBN object

Creates a one-to-one relationship with another class. This is just
like C<might_have>, except the implication is that the other object is
always present. The only difference between C<has_one> and
C<might_have> is that C<has_one> uses an (ordinary) inner join,
whereas C<might_have> defaults to a left join.

The has_one relationship should be used when a row in the table must
have exactly one related row in another table. If the related row
might not exist in the foreign table, use the
L<DBIO::Relationship/might_have> relationship.

In the above example, each Book in the database is associated with exactly one
ISBN object.

See L<DBIO::Relationship::Base/attributes> for documentation on
relationship methods and valid relationship attributes. Also see
L<DBIO::ResultSet> for a L<list of standard resultset
attributes|DBIO::ResultSet/ATTRIBUTES> which can be assigned to
relationships as well.

Note that if you supply a condition on which to join, if the column in the
current table allows nulls (i.e., has the C<is_nullable> attribute set to a
true value), than warnings might apply just as with
L<DBIO::Relationship/might_have>.

=head2 many_to_many

=over 4

=item Arguments: $accessor_name, $link_rel_name, $foreign_rel_name, L<\%attrs?|DBIO::ResultSet/ATTRIBUTES>

=back

C<many_to_many> is a I<Relationship bridge> which has a specific
meaning in DBIO, see the definition in the
L<Glossary|DBIO::Manual::Glossary/Relationship bridge>.

C<many_to_many> is not strictly a relationship in its own right. Instead, it is
a bridge between two resultsets which provide the same kind of convenience
accessors as true relationships provide. Although the accessor will return a
resultset or collection of objects just like has_many does, you cannot call
C<related_resultset> and similar methods which operate on true relationships.

=over

=item accessor_name

This argument is the name of the method you can call on a
L<Result|DBIO::Manual::ResultClass> object to retrieve the rows matching this
relationship.

On a many_to_many, unlike other relationships, this cannot be used in
L<DBIO::ResultSet/search> to join tables. Use the relations
bridged across instead.

=item link_rel_name

This is the accessor_name from the has_many relationship we are
bridging from.

=item foreign_rel_name

This is the accessor_name of the belongs_to relationship in the link
table that we are bridging across (which gives us the table we are
bridging to).

=back

To create a many_to_many relationship from Actor to Role:

  My::DBIO::Schema::Actor->has_many( actor_roles =>
                                     'My::DBIO::Schema::ActorRoles',
                                     'actor' );
  My::DBIO::Schema::ActorRoles->belongs_to( role =>
                                            'My::DBIO::Schema::Role' );
  My::DBIO::Schema::ActorRoles->belongs_to( actor =>
                                            'My::DBIO::Schema::Actor' );

  My::DBIO::Schema::Actor->many_to_many( roles => 'actor_roles',
                                         'role' );

And, for the reverse relationship, from Role to Actor:

  My::DBIO::Schema::Role->has_many( actor_roles =>
                                    'My::DBIO::Schema::ActorRoles',
                                    'role' );

  My::DBIO::Schema::Role->many_to_many( actors => 'actor_roles', 'actor' );

To add a role for your actor, and fill in the year of the role in the
actor_roles table:

  $actor->add_to_roles($role, { year => 1995 });

In the above example, ActorRoles is the link table class, and Role is the
foreign class. The C<$link_rel_name> parameter is the name of the accessor for
the has_many relationship from this table to the link table, and the
C<$foreign_rel_name> parameter is the accessor for the belongs_to relationship
from the link table to the foreign table.

To use many_to_many, existing relationships from the original table to the link
table, and from the link table to the end table must already exist, these
relation names are then used in the many_to_many call.

In the above example, the Actor class will have 3 many_to_many accessor methods
set: C<roles>, C<add_to_roles>, C<set_roles>, and similarly named accessors
will be created for the Role class for the C<actors> many_to_many
relationship.

See L<DBIO::Relationship::Base/attributes> for documentation on
relationship methods and valid relationship attributes. Also see
L<DBIO::ResultSet> for a L<list of standard resultset
attributes|DBIO::ResultSet/ATTRIBUTES> which can be assigned to
relationships as well.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
