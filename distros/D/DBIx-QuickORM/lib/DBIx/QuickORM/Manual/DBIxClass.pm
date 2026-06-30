package DBIx::QuickORM::Manual::DBIxClass;
use strict;
use warnings;

our $VERSION = '0.000026';

1;

__END__

=head1 NAME

DBIx::QuickORM::Manual::DBIxClass - Concept map from DBIx::Class to DBIx::QuickORM.

=head1 DESCRIPTION

If you are coming from L<DBIx::Class>, this page maps its concepts to their
L<DBIx::QuickORM> equivalents so you can find the familiar thing quickly. It
is a concept guide, not a migration tool, and the mapping is approximate -
some things differ in important ways, called out under L</"NOTABLE
DIFFERENCES">.

=head1 QUICK REFERENCE

    DBIx::Class                         DBIx::QuickORM
    ------------------------------      ----------------------------------------
    Schema (class)                      an ORM defined with the DSL, or quick()
    $schema = ...->connect(...)         $orm = orm('name'); / DBIx::QuickORM->quick(...)
    $schema->storage                    DBIx::QuickORM::Connection
    ResultSource / Result class         DBIx::QuickORM::Schema::Table (a "source")
    ResultSet                           DBIx::QuickORM::Handle (a query/handle)
    Result / Row object                 DBIx::QuickORM::Row
    $rs->search(\%cond)                 $con->handle($table, \%where) / ->where(...)
    $rs->find($id)                      $con->by_id($table => $id)
    $rs->create(\%data)                 $con->insert($table => \%data)
    $rs->all                            ->all
    $rs->next (iterator)                ->iterator then ->next
    $rs->first / ->single               ->first / ->one
    $rs->count                          ->count
    $row->update(\%data) / ->delete     $row->update(\%data) / ->delete
    has_many / belongs_to / has_one     a link (foreign key)
    $row->related_resultset / rel       $row->follow($link) / $row->obtain($link)
    prefetch / join                     $handle->join(...) (see Relations)
    InflateColumn::*                    a DBIx::QuickORM::Role::Type class
    $schema->txn_do(sub {...})          $con->txn(sub {...})
    DBIx::Class::Schema::Loader         autofill (automatic schema)

=head1 CORE OBJECTS

=over 4

=item ResultSet -> Handle

A L<DBIx::QuickORM::Handle> is the closest analog to a C<ResultSet>: a query
object you refine and then execute. Like a C<ResultSet>, refining a handle
(C<where>, C<order_by>, C<limit>, ...) returns a B<new> handle rather than
mutating it, so handles compose the same way ResultSets chain. See
L<DBIx::QuickORM::Manual::Querying>.

=item Result / Row -> Row

A L<DBIx::QuickORM::Row> is the per-row object, like a DBIx::Class C<Result>.
Read fields with C<< $row->field('name') >>; C<save>/C<update>/C<delete>/
C<refresh>/C<discard> behave as you would expect.

=item ResultSource -> source (table/view/join/literal)

DBIx::Class's C<ResultSource> corresponds to a "source": usually a
L<DBIx::QuickORM::Schema::Table> (or a view, join, or literal SQL). A source
is what a handle queries against.

=item Schema -> ORM

A DBIx::Class C<Schema> class maps to an ORM defined with the
L<DBIx::QuickORM> DSL (or built on the fly with C<< DBIx::QuickORM->quick >>).
See L<DBIx::QuickORM::Manual::Schema>.

=item $schema->storage -> Connection

The live database connection is a L<DBIx::QuickORM::Connection>, where
transactions are controlled and handles are made. See
L<DBIx::QuickORM::Manual::Connections>.

=back

=head1 QUERYING

C<< $rs->search(\%cond, \%attrs) >> becomes a handle plus refinements:

    # DBIx::Class
    my $rs = $schema->resultset('People')->search({surname => 'smith'}, {order_by => 'first_name'});

    # DBIx::QuickORM
    my $h = $con->handle(people => {surname => 'smith'})->order_by('first_name');

Common methods map directly: C<find> -> C<by_id>, C<create> -> C<insert>,
C<all> -> C<all>, C<count> -> C<count>, C<first>/C<single> -> C<first>/C<one>.
For row-at-a-time iteration use an iterator:

    my $it = $h->iterator;
    while (my $row = $it->next) { ... }

See L<DBIx::QuickORM::Manual::Querying> for the full handle API.

=head1 RELATIONSHIPS

DBIx::Class relationship declarations (C<has_many>, C<belongs_to>,
C<might_have>, C<has_one>) map to a single concept: a B<link> (a foreign-key
relationship). At runtime you follow a link instead of calling a named
relationship accessor:

=over 4

=item C<< $row->follow($link) >>

Returns a handle for the related rows (like C<< $row->search_related >> /
C<related_resultset >>).

=item C<< $row->obtain($link) >>

Returns the single related row (for a unique link), like following a
C<belongs_to>/C<has_one>.

=back

With C<autorow>, named accessors are generated for links (singular for unique
links, plural otherwise), which is closer to DBIx::Class's named relationship
accessors. C<prefetch>/join-based queries map to joins on a handle. See
L<DBIx::QuickORM::Manual::Relations>.

=head1 RESULT CLASSES

In DBIx::Class you write a Result class per table. In DBIx::QuickORM you can
similarly define each table in its own file (and add custom row methods), or
let C<autorow> generate row classes for you. See
L<DBIx::QuickORM::Manual::Schema>. Custom inflation/deflation that DBIx::Class
does with C<InflateColumn::*> components is handled by type classes; see
L<DBIx::QuickORM::Manual::Types>.

=head1 CONNECTING AND LOADING SCHEMA

C<< Schema->connect(@info) >> maps to fetching a configured ORM and using its
connection (C<< orm('name') >> then C<< ->connection >>/C<< ->handle >>), or
to C<< DBIx::QuickORM->quick(...) >> when you just want a connection from a
DSN. See L<DBIx::QuickORM::Manual::QuickStart> and
L<DBIx::QuickORM::Manual::Connections>.

L<DBIx::Class::Schema::Loader> (generating a schema from an existing database)
corresponds to C<autofill>, except it happens at run time: DBIx::QuickORM
introspects the live database every connection rather than generating Result
classes ahead of time. See L<DBIx::QuickORM::Manual::Schema>.

=head1 TRANSACTIONS

C<< $schema->txn_do(sub {...}) >> and C<txn_scope_guard> map to
C<< $con->txn(sub {...}) >>; nested calls become savepoints. See
L<DBIx::QuickORM::Manual::Transactions>.

=head1 NOTABLE DIFFERENCES

=over 4

=item The database is canonical.

DBIx::QuickORM introspects table and column metadata from the live database;
user-provided schema fills gaps and wins on conflict. There is no "deploy"
step that creates tables from your classes the way DBIx::Class does.

=item Dialects, not just storage drivers.

Database-flavor behavior lives in a dialect (SQLite, PostgreSQL, MySQL and
its variants). See L<DBIx::QuickORM::Manual::Concepts>.

=item Row identity / caching is built in.

Each connection keeps at most one in-memory row object per primary key. See
L<DBIx::QuickORM::Manual::Caching>.

=item Async, aside, and forked queries.

Handles can run queries asynchronously, on a side connection, or in a forked
child. See L<DBIx::QuickORM::Manual::Async>.

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
