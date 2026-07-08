package DBIx::QuickORM::Manual::Querying;
use strict;
use warnings;

our $VERSION = '0.000028';

1;

__END__

=head1 NAME

DBIx::QuickORM::Manual::Querying - A practical guide to fetching, creating,
updating, and deleting rows with handles.

=head1 DESCRIPTION

A B<handle> is the object you use to build and run queries against a source
(a table, view, join, or another query used as a subquery). It is the rough
equivalent of a ResultSet in other ORMs. This guide is a task-oriented tour of the handle. For the exhaustive
method-by-method reference see L<DBIx::QuickORM::Handle>.

The mental model is small:

=over 4

=item *

Get a handle on a source.

=item *

Refine it (WHERE, ORDER BY, LIMIT, field selection) to describe the query you
want. Each refinement returns a B<new> handle; the original is untouched.

=item *

Run a terminal method (C<one>, C<all>, C<insert>, C<update>, ...) to actually
talk to the database.

=back

Handles do not execute anything until you call a terminal method, so you can
compose and pass them around freely.

=head1 GETTING A HANDLE

Every handle operates through a L<DBIx::QuickORM::Connection>. The connection
itself is the easiest place to make one with C<< $con->handle(...) >>:

    my $con = qorm('my_orm');

    # A handle on the whole 'people' table (no query has run yet).
    my $people = $con->handle('people');

    # A handle already narrowed by a where clause.
    my $smiths = $con->handle('people' => {surname => 'smith'});

The constructor is forgiving about argument shape. A bare string is treated as
a source (table) name, a hashref as a WHERE clause, an arrayref as an ORDER BY,
and a plain integer as a LIMIT. So all of these are equivalent ways to spell
the same query:

    $con->handle('people', {surname => 'smith'}, ['first_name'], 10);
    $con->handle('people')->where({surname => 'smith'})->order_by('first_name')->limit(10);

See L<DBIx::QuickORM::Handle/"CONSTRUCTOR ARGS"> for the full list of accepted
arguments.

=head2 CONNECTION SHORTCUTS

For one-off queries you usually do not need to name the intermediate handle.
The connection proxies the common terminal methods straight through to a
handle, so these shortcuts build a handle and immediately run it:

    my @people = $con->all('people');
    my $person = $con->one('people' => {id => 1});
    my $count  = $con->count('people' => {surname => 'smith'});
    my $person = $con->by_id('people' => 1);

    $con->insert('people' => {name => 'Bob'});
    $con->update('people' => {surname => 'smith'} => {active => 0});
    $con->delete('people' => {id => 1});

Each is just C<< $con->handle(@args)->METHOD(...) >>. Reach for an explicit
handle when you want to refine in stages or reuse the same base query.

=head2 A HANDLE AS A SOURCE (SUBQUERIES)

A handle is itself a valid source, so you can pass one to
C<< $con->handle(...) >> to use it as a derived table (subquery). The inner
handle's query is spliced in as C<< ( <inner query> ) AS subquery >> and the
outer handle refines around it:

    my $recent = $con->handle('events')->where({ts => {'>' => $cutoff}});

    my @clicks = $con->handle($recent)->where({kind => 'click'})->all;
    # SELECT * FROM ( SELECT ... FROM events WHERE ts > ? ) AS subquery
    #   WHERE kind = ?

The derived table is aliased C<subquery> by default;
C<< $h->subquery_alias($alias) >> returns a clone with a different alias
(needed when two subqueries share one statement). A subquery source is
read-only: C<insert>, C<upsert>, C<update>, C<delete>, C<cas>, and C<omit>
through it croak. See L<DBIx::QuickORM::Handle/subquery_alias>.

=head1 THE IMMUTABLE BUILDER MODEL

Handles are B<immutable>. The builder methods never modify the handle they are
called on; they return a brand new handle with the change applied. This makes
it safe to derive several queries from a shared base:

    my $base   = $con->handle('people');
    my $smiths = $base->where({surname => 'smith'});
    my $jones  = $base->where({surname => 'jones'});
    # $base is still unrestricted.

Because the return value is the whole point, calling a builder method in void
context is a mistake and will croak. Always capture (or chain off) the result:

    $base->where({surname => 'smith'});            # WRONG: result thrown away, croaks
    my $h = $base->where({surname => 'smith'});    # right

The reference doc calls these methods I<Immutators> (always return a new
handle) and I<Immucessors> (return the current value when called with no
argument, or a new handle when called with one). See
L<DBIx::QuickORM::Handle/"Immutators"> and
L<DBIx::QuickORM::Handle/"Immucessors">.

=head1 REFINING A HANDLE

=head2 WHERE

C<where> sets the WHERE clause; the clause itself is a
L<SQL::Abstract>-style structure.

    my $h = $con->handle('people')->where({surname => 'smith'});

To extend an existing clause without rebuilding it, use C<and> / C<or>. They
combine the new condition with whatever the handle already had:

    # WHERE (surname = 'smith') AND (active = 1)
    my $h2 = $h->and({active => 1});

    # WHERE (surname = 'smith') OR (surname = 'jones')
    my $h3 = $h->or({surname => 'jones'});

=head2 Raw values in a clause

A value in a WHERE clause is normally deflated to its database form before it is
bound, so you can pass an inflated value (a hashref for a JSON column, a
C<DateTime> object, and so on) and it is matched correctly. When you already
hold the database-form value -- for example one read straight from a row's
stored data -- wrap it in L<DBIx::QuickORM::Raw> so it binds as-is instead of
being deflated a second time:

    use DBIx::QuickORM::Raw;

    my $raw = DBIx::QuickORM::Raw->new($row->raw_stored_field('data'));
    $con->handle('events')->where({data => {'-value' => $raw}})->all;

This matters for types whose deflation is not idempotent (encoding a JSON string
again would double-encode it), and it is the mechanism C<cas> uses for its
field-name guards.

=head2 ORDER BY, LIMIT, and OFFSET

    my $h = $con->handle('people')
        ->where({active => 1})
        ->order_by(['surname', 'first_name'])
        ->limit(25)
        ->offset(50);

C<order_by> accepts a single field, a list of fields, or an arrayref. C<limit>
caps the number of rows returned, and C<offset> skips that many matching rows
first, so C<< ->limit(25)->offset(50) >> fetches the third page of 25.

=head2 Choosing fields

By default a handle fetches the source's normal field set. You can narrow or
change that:

    # Only these fields.
    my $h = $con->handle('people')->fields(['id', 'first_name']);

    # Everything except the given fields. Primary key fields cannot be omitted.
    my $h = $con->handle('people')->omit(['bio', 'avatar']);

A source may mark some columns to be left out of the default fetch (for
example large blobs). C<all_fields> forces a handle to select every column
regardless:

    my $h = $con->handle('people')->all_fields;

C<distinct> makes the query select only distinct rows (a C<SELECT DISTINCT>),
which is most useful when you have narrowed the field set:

    my $h = $con->handle('people')->fields(['surname'])->distinct;

=head1 FETCHING ROWS

These terminal methods run a SELECT and hand back row objects (see
L<DBIx::QuickORM::Row>). They accept an optional trailing WHERE (hashref) or
row, so you can pass the condition inline instead of calling C<where> first.

=over 4

=item $row = $h->one

Fetch exactly one row. Returns C<undef> if nothing matches, and B<croaks> if
more than one row matches. Use this when the query should be unique.

    my $person = $con->handle('people')->one({id => 1});

=item $row = $h->first

Like C<one>, but tolerates extra matches and simply returns the first row.

=item @rows = $h->all

Return every matching row as a list.

    my @active = $con->handle('people')->where({active => 1})->all;

=item $iter = $h->iterator

Return a L<DBIx::QuickORM::Iterator> instead of slurping everything into
memory:

    my $iter = $con->handle('people')->iterator;
    while (my $person = $iter->next) {
        ...;
    }

=item $h->iterate(sub { my $row = shift; ... })

Run a callback once per matching row.

=item $count = $h->count

Return the number of rows the query would match (a C<COUNT(*)>), without
building row objects.

=item $row = $h->by_id($id)

Fetch a single row by primary key. C<$id> may be a scalar (single-column key),
an arrayref of values, or a hashref of C<< field => value >> pairs for a
compound key. If the row is already in the connection's cache no query is run
at all.

    my $person = $con->handle('people')->by_id(1);

C<< $h->by_ids(@ids) >> is the batch form, returning an arrayref of rows.

=back

=head2 Iterators

L<DBIx::QuickORM::Iterator> pulls rows lazily and caches them, so it can be
walked, reset, and walked again. Beyond C<next> it offers C<first> (reset and
return the first item), C<last>, C<list> (exhaust and return everything), and
C<ready> (true once results are available; always true for synchronous
queries). See L<DBIx::QuickORM::Iterator> for details.

=head1 CREATING, UPDATING, AND DELETING

=head2 Insert

    my $row = $con->handle('people')->insert({name => 'Bob', surname => 'smith'});

C<insert> returns a row object. By default only the primary key is read back
from the database after the insert; the rest of the row reflects the values
you supplied. If triggers or column defaults might change the stored data, use
C<insert_and_refresh> (or turn on C<auto_refresh>) to re-read the full row:

    my $row = $con->handle('people')->insert_and_refresh({name => 'Bob'});

=head2 Upsert

C<upsert> inserts the row, or updates it if a conflicting row already exists,
in a single statement (the exact SQL depends on the dialect). C<upsert_and_refresh>
adds the post-write refresh.

    my $row = $con->handle('people')->upsert({id => 1, name => 'Bob'});

=head2 Update

C<update> applies a hashref of changes to every row matching the handle's WHERE
clause:

    # Deactivate every smith.
    $con->handle('people')->where({surname => 'smith'})->update({active => 0});

Passing a row object instead writes that row's pending changes. C<update>
cannot be combined with C<limit> or C<order_by>.

=head2 Compare and set

C<cas> updates a single row only while a set of guard values still match, so
two writers cannot overwrite each other unnoticed. It runs one
C<UPDATE ... SET ... WHERE primary_key AND guard> statement and returns a
L<DBIx::QuickORM::CAS::Result> that is true only when a row was updated; a
failed guard is a normal C<lost> result, not an exception.

The simplest form is on a row: guard on the fields you read, then write only if
they have not changed since.

    my $row = $con->handle('counters')->by_id(1);

    my $result = $row->cas([qw/value/], {value => $row->field('value') + 1});

    if ($result) {
        # won: nobody else changed value
    }
    else {
        # lost: refetch and retry
    }

The changes should set a new value for at least one guard column, as the
incrementing C<value> does above; C<cas> warns otherwise, because a guard that
never changes lets two concurrent writers both win.

The guard can be a list of field names (compared against the row's stored
values), a single field name, or a where hashref. On a handle you supply
whichever half the handle is missing: C<< $h->row($row)->cas(\@fields, \%changes) >>
or C<< $h->where(\%guard)->cas($row, \%changes) >>. An async or aside handle
returns the same result object unresolved; poll C<< $result->ready >> or just
use it, and any other method blocks until the database answers.

=head2 Delete

C<delete> removes the rows the handle matches:

    $con->handle('people')->where({active => 0})->delete;

With no argument it deletes everything the handle would match. You may also
pass a row or a WHERE clause directly, which overrides whatever the handle
already carried:

    $con->handle('people')->delete({id => 1});

=head2 Vivify

C<vivify> gets you a row object to work with from a data hashref B<without>
touching the database, much like Perl autovivifies a nested hash slot. If a
row matching the data's primary key is already loaded it hands that one back;
otherwise it builds a new one. Nothing is written until you call
C<< $row->insert >> or C<< $row->save >> on it:

    my $row = $con->handle('people')->vivify({name => 'Bob'});
    $row->insert;    # now it hits the database

On a hit the existing row wins and your data is not applied to it (you get a
warning if that would silently drop differing values). To change a loaded row
use C<< $row->update >>; to ensure a row exists in the database use
C<find_or_insert> or C<update_or_insert>.

=head1 ROW OBJECTS

Fetching and mutating methods return L<DBIx::QuickORM::Row> objects. Briefly,
a row gives you C<< $row->field($name) >> (inflated value) and
C<< $row->raw_field($name) >> (raw stored value) for access, and
C<insert> / C<update> / C<delete> / C<save> / C<refresh> / C<discard> for
persistence. See L<DBIx::QuickORM::Row> for the full interface.

=head1 DATA-ONLY MODE

Sometimes you want plain hashrefs rather than blessed row objects (for
reporting, bulk export, or to skip the cache and inflation machinery).
C<data_only> gives you a handle that returns hashrefs from its fetch methods:

    my @rows = $con->handle('people')->data_only->all;
    # each element is a plain hashref, not a row object

C<data_only> applies to the read methods (C<one>, C<first>, C<all>,
C<iterator>, C<iterate>); it is not valid for inserts.

=head1 SEE ALSO

=over 4

=item L<DBIx::QuickORM::Handle>

The complete handle reference: every builder and terminal method, constructor
arguments, and flags.

=item L<DBIx::QuickORM::Row>

What you get back from a fetch, and how to mutate and persist it.

=item L<DBIx::QuickORM::Manual::Relations>

Defining links (foreign keys), following them between rows, and joining
sources. Joins are built from handles (C<< $h->join(...) >> and friends) but
are documented there.

=item L<DBIx::QuickORM::Manual::Async>

Running queries asynchronously, aside (on a second connection), or forked.
Handles toggle these modes with C<< $h->async >>, C<< $h->aside >>, and
C<< $h->forked >>; the mechanics live there.

=item L<DBIx::QuickORM::Manual::Transactions>

Wrapping work in transactions and savepoints, including the internal
transactions some multi-query handle operations use.

=item L<DBIx::QuickORM::Manual>

The documentation hub for the rest of the manual.

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
