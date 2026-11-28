package DBIx::QuickORM::Handle;
use strict;
use warnings;

our $VERSION = '0.000031';

use Atomic::Pipe();
use Carp qw/croak/;
use POSIX();
use Scalar::Util qw/blessed/;
use Storable qw/freeze thaw/;

use DBIx::QuickORM::AggregateRow();
use DBIx::QuickORM::Iterator();
use DBIx::QuickORM::Source::Join();
use DBIx::QuickORM::Value();

use Object::HashBase qw{
    <orm
    <source
    <state
    +where
    +order_by
    +limit
    +offset
    +fields
    +row_class
    +iterator
    +group_by
    +having
    <mode
    +columns
    +no_cache
    +where_builders
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Handle - Build a query and fetch its rows.

=head1 DESCRIPTION

A handle is a query over a source (L<DBIx::QuickORM::Role::Source>): a table,
an SQL query, or tables joined together. Modifiers such as C<where> and
C<order_by> each return a new handle, so a handle can be refined and reused
freely. The fetching methods run the query and hand out rows. The writing
methods update or delete what it matches.

A handle is stateless until its query is sent. Then the results are cached
on it until C<clear>. Every reading method and every C<iter> shares that one
run of the query. A modifier's new handle starts without it.

Running the query fetches every row at once, ingests the rows of a table with
a primary key into the lookup table (see L<DBIx::QuickORM>) unless the handle
is C<no_cache>, and hands them out through an iterator
(L<DBIx::QuickORM::Iterator>).

The SQL comes from the ORM's C<sql_builder>, whose documentation describes the
syntax of C<where> and C<order_by>. The default is
L<DBIx::QuickORM::SQLBuilder::SQLAbstract>, using L<SQL::Abstract>'s syntax.

Rows are built with the handle's C<row_class> when one was set (even to undef,
for row data), otherwise as the ORM resolves them for the table. Rows of a
query use the ORM's C<row_class>. Rows of a join are L<DBIx::QuickORM::JoinRow>
objects (see L</Joins>), and computed rows are L<DBIx::QuickORM::AggregateRow>
objects (see L</Computed columns>).

=head1 SYNOPSIS

    my $h = $orm->handle('users')
        ->where({name => {-like => 'A%'}})
        ->order_by('name')
        ->limit(10);

    my $n   = $h->count;
    my @all = $h->all;

    my $user = $orm->handle('users')->find($id);
    $orm->handle('posts')->where({views => 0})->delete;

=head1 EXAMPLES

=head2 Filter, sort, and page

    my @page = $orm->handle('users')
        ->where({
            name  => {-like => 'A%'},
            email => {'!=' => undef},
        })
        ->order_by([{-desc => 'created'}, 'name'])
        ->limit(20)
        ->offset(40)
        ->all;

=head2 Narrow or widen a condition

    my $alice   = $orm->handle('users')->where({name => 'Alice'});
    my $emailed = $alice->and({email => {'!=' => undef}});    # both conditions
    my $either  = $alice->or({name => 'Bob'});                # either condition
    my $bob     = $alice->where({name => 'Bob'});             # where replaces the condition

=head2 Compare with SQL

    use DBIx::QuickORM::Value qw/sql/;

    my @old = $orm->handle('users')
        ->where({created => {'<' => sql("now() - interval '30 days'")}})
        ->all;

=head2 Read only some fields

    my @users = $orm->handle('users')->fields(['name'])->all;    # name, plus the primary key
    # a field not fetched loads on first read
    my $email = $users[0]->field('email');

=head2 Get plain hashrefs instead of row objects

    my @data = $orm->handle('users')->data_only->all;
    my $name = $data[0]->{name};

=head2 Query with your own SQL

    my $dupes = $orm->handle(
        \['SELECT name, COUNT(*) AS n FROM users GROUP BY name HAVING COUNT(*) > ?', 1],
    );
    my @dupes = $dupes->all;
    my @named = $dupes->where({name => 'Alice'})->all;    # the query becomes a subquery

=head2 Insert many rows and get them back

    my $posts = $orm->handle('posts')->insert_many(
        [
            map {
                +{
                    user_id => $id,
                    title   => "Post $_",
                }
            } 1 .. 3
        ],
    );    # an arrayref of the new rows

=head2 Loop over the same rows twice at once

Each C<iter> call returns a new iterator with its own position, so each loop
has its own. They share the handle's one run of the query.

    my $h = $orm->handle('posts')->order_by('id');

    my @pairs;
    my $outer = $h->iter;
    while (my $left = $outer->next) {
        my $inner = $h->iter;    # the same rows, no second query
        while (my $right = $inner->next) {
            push @pairs => [$left->field('id'), $right->field('id')];
        }
    }

=head1 ATTRIBUTES

=over 4

=item $orm = $h->orm

=item $source = $h->source

Both required.

=item $state = $h->state

The iterator state (see L<DBIx::QuickORM::Iterator>), undef unless given. A
new C<where> (also through C<and> or C<or>) or a join drops it.

=item $mode = $h->mode

C<async>, C<aside>, or C<forked>, or undef for an ordinary handle.

=back

=cut

sub init {
    my $self = shift;
    croak "An 'orm' is required"                                    unless $self->{+ORM};
    croak "A 'source' is required (a DBIx::QuickORM::Role::Source)" unless blessed($self->{+SOURCE}) && $self->{+SOURCE}->DOES('DBIx::QuickORM::Role::Source');
}

=head1 PUBLIC METHODS

=head2 Modifiers

    my $users  = $orm->handle('users');
    my $recent = $users->order_by({-desc => 'created'})->limit(5);    # $users is unchanged
    # 5: without an argument, the setting
    my $limit  = $recent->limit;

Each returns a new handle with the one setting replaced and no cached rows, and
leaves the handle it was called on unchanged. So a modifier called in void
context would do nothing, and croaks instead. One that takes a value returns
the current setting when called without one. An argument of the wrong shape croaks, at the
latest when the query runs.

=over 4

=item $h2 = $h->where($where)

The condition: a hashref or arrayref in the builder's syntax, an C<sql()>
marker, or a plain string of SQL. The where builders render it (see
C<where_builders>).

A plain string is raw SQL, used as written. Never interpolate untrusted input
into it. Pass values as binds with C<sql('... ?', $value)>.

A new C<where> replaces the old one entirely, including one C<follow_fk> set.
Use C<and> to narrow a handle's condition instead.

=item $h2 = $h->and($where)

=item $h2 = $h->or($where)

The handle with its C<where> combined with C<$where>: rows must meet both
(C<and>) or either (C<or>).

Both need a condition to add to: on a handle without a C<where>, or with an
empty one (C<{}>, C<[]>, or C<''>), they croak. Use C<where> there. Value
markers work in either part. Neither returns the current setting, but
C<where> does.

A side that is wholly a string, C<sql()>, or C<< \[...] >> is put in
parentheses when combined, so an C<OR> in it stays grouped. A literal you nest
yourself inside C<-and> or C<-or> is yours to parenthesize.

=item $h2 = $h->order_by($order)

The order of the rows, in the builder's syntax.

=item $h2 = $h->limit($n)

=item $h2 = $h->offset($n)

The most rows to return, and how many rows to skip before them.

=item $h2 = $h->fields(\@fields)

Selects only these fields. The primary key is always added. Without it the
table's default fields are selected (every column for a query).

=item $h2 = $h->fields({$name => $spec, ...})

Computed columns, each selected as C<$name>. See L</Computed columns>. The
rows are computed rows.

=item $h2 = $h->group_by(@fields)

=item $h2 = $h->having($condition)

Group the rows by these fields, and keep the groups matching the condition.
The rows are computed rows.

C<having> is in the builder's syntax, as for C<where>. It can name grouped
fields and computed fields, or take an C<sql()> marker such as
C<< sql('COUNT(*) > ?', 2) >>. A computed field's name goes to MySQL and
MariaDB as written. Elsewhere the builder writes the field's SQL in its place
(PostgreSQL rejects a select alias in C<HAVING>).

Without computed fields the handle selects the grouped fields, or the
C<fields> given as a list. A handle with C<having> but neither croaks when
run.

SQLite sends a bind in an C<sql()> marker as text, which an aggregate's number
never matches. Cast the bind there:
C<< sql('COUNT(*) > CAST(? AS INTEGER)', $n) >>.

=item $h2 = $h->row_class($class_or_undef)

The class rows from this handle are built with. Undef means row data.

A class without a C<new> is loaded now, as the ORM loads its row classes. One
that cannot be loaded croaks.

=item $h2 = $h->data_only

Shorthand for C<row_class(undef)>: rows come back as row data, as the
CRUD operations' C<< data => 1 >> gives. A row object given to C<update_row> or
C<refresh_row> is still returned as itself. Pass C<< data => 1 >> for its row
data.

It takes no argument. C<row_class($class)> undoes it.

=item $h2 = $h->no_cache

Its queries skip the lookup table: rows come back as fetched, and nothing the
ORM holds changes. C<find> and C<refresh_row> use the cache as their own
options say. It takes no argument. Undo it with C<cache>.

The rows, row objects or hashrefs, are not canonical. Writing with them
croaks under the default C<enforce_canon>. C<find> or C<refresh_row> gives a
canonical row.

=item $h2 = $h->cache

Undoes C<no_cache>: reads go through the lookup table again and their rows are
canonical. It takes no argument.

=item $h2 = $h->where_builders(\@builders)

The where builders this handle's C<where> is rendered through, replacing the
ORM's C<where_builders> (see L<DBIx::QuickORM>). Each class is loaded as the
ORM loads them. Without an argument it returns the handle's own setting,
undef unless set.

=back

Computed rows are keyed by the selected names, which the order may name.
They belong to no table: no primary key is added and they never enter the
lookup table.

They are L<DBIx::QuickORM::AggregateRow> objects, which inflate and follow
foreign keys by each column's spec. When the row class resolved for the source
(the table's, or the ORM's) is undef they are hashrefs. A handle C<row_class>
replaces either: undef for hashrefs, or a class built as for a query's rows.

=head2 Computed columns

    use DBIx::QuickORM::Value qw/sql/;

    my @per_user = $orm->handle('posts')
        ->group_by('user_id')
        ->order_by('user_id')
        ->fields({
            # the field itself, with its type and foreign key
            user_id => 'user_id',
            # COUNT(*)
            posts   => [count => '*'],
            # an SQL expression: no type, no foreign key
            titles  => sql('COUNT(DISTINCT title)'),
            # SUM(views)
            views   => [sum => 'views'],
            # MAX(id), followed to that post
            latest  => {
                agg => [max => 'id'],
                fk  => 'posts',
            },
        })
        ->all;

    my $count  = $per_user[0]->field('posts');
    my $user   = $per_user[0]->follow_fk('users')->only;
    my $latest = $per_user[0]->follow_fk('posts')->only;

C<< fields({$name => $spec}) >> takes one of these per column:

=over 4

=item $name => 'field'

The field itself (C<alias.field> on a join), with the facts C<like> gives
below: its type and foreign keys.

=item $name => sql(...)

=item $name => \'SQL'

An SQL expression (see L<DBIx::QuickORM::Value>), with no type and no
foreign key. C<\'SQL'> is short for C<sql('SQL')>.

=item $name => [$func, 'field']

C<FUNC(field)>, the field quoted for the database. C<$func> must be a word
(it is written into the SQL), and the field must exist. When C<$func> is
C<min> or C<max>, or one of the ORM's C<like_aggregates> (any case), the
result is one of the field's values, so the column takes the field's type
and foreign keys. Any other function's result has neither.

The field C<*> gives C<FUNC(*)>: C<< [count => '*'] >> counts rows. Such a
column has no type or foreign key. A function that does not take C<*> fails
when the query runs, with the database's error.

=item $name => {sql => sql(...) | agg => [$func, 'field'], type => $type, db_type => $db_type, fk => $fk, like => 'field'}

Exactly one of C<sql> or C<agg>, which work as above. The other keys adjust
the column:

=over 4

=item like => 'field'

The column takes the field's facts: its type, its declared type (and what
follows from it, such as affinity), and its single-field foreign keys. With
C<like>, nothing comes from C<agg>'s field.

=item type => $type

The type, named as in the ORM's C<types>. Replaces what C<like> or C<agg>
gave.

=item db_type => $db_type

The declared type. Replaces what C<like> or C<agg> gave, but keeps the type
they implied. Give C<type> too to change it.

=item fk => $fk

A single-field foreign key, replacing what C<like> or C<agg> gave: a table
name (that table's primary key, which must be one field), C<[$table, $field]>,
or C<< {$table => $field} >>.

=back

=back

Croaks on an unknown key, an unknown field, a function name that is not a
word, or an C<fk> naming a table or field not in the map.

=head2 Running elsewhere

    # the query starts, and iter() returns at once
    my $it = $orm->handle('posts')->async->iter;
    do_something_else() until $it->ready;
    my @posts = $it->all;

    my $aside  = $orm->handle('posts')->aside->iter;     # on a second connection
    my $forked = $orm->handle('posts')->forked->iter;    # in a child process
    $orm->insert(users => {name => 'Busy'});             # the ORM's own connection stays free
    my @all = ($aside->all, $forked->all);

=over 4

=item $h2 = $h->async

The handle's query starts without waiting on its first read: C<iter> returns a
pending iterator (see L<DBIx::QuickORM::Iterator>), whose C<ready> checks without
waiting and whose reading methods wait for the rows. Every iterator of the
handle shares that one query.

The query runs on the ORM's own connection, so its rows are canonical like any
other's, inside a transaction or not. Until it is collected the connection is
busy, and every other query, write, and transaction statement on it croaks.

A query not yet collected is cancelled once nothing can read it: the handle
is freed or cleared, and so is every iterator over it. A transaction rolled
back because its block threw or it went out of scope cancels it too. Its
iterators then throw when read. On PostgreSQL, cancelling inside a
transaction aborts that transaction. MySQL and MariaDB cannot cancel, so they
wait for the result and discard it.

Needs a database with async queries (PostgreSQL, MySQL, MariaDB). Croaks on
any other. On some platforms a child forked while a PostgreSQL async query is
pending may crash on exit (L<https://github.com/bucardo/dbdpg/issues/218>).

=item $h2 = $h->aside

Like C<async>, but each query runs on a new connection from the ORM's
connector, so the ORM's own connection stays free.

The connection is closed once the rows are collected, or when the query is
cancelled before that. It sees only committed data. Its rows are ingested as
usual.

Starting the query, or reading its rows (C<ready> included), croaks while a
transaction is open. A query started before a transaction may run during it,
so read it after the transaction ends. Its rows may then be stale if the
transaction changed the same rows.

Needs a database with async queries that a second connection can reach (not
an in-memory database). On an ORM given a C<dbh>, C<aside> itself croaks.

=item $h2 = $h->forked

Each query runs in a forked child process, on a new connection from the
connector, and the child sends the rows back and exits.

The iterator is pending as for C<async>. Rows are ingested, and transactions
are refused, as for C<aside>. An error in the child is thrown on
collection as C<The forked query failed: ...> with the child's message.
Cancelling the query kills and reaps the child.

The child never touches the parent's connection. A forked query can race
changes the parent makes meanwhile to the same rows, as any other reader can.

Needs a database a second connection can reach (not DuckDB or an in-memory
SQLite database). On an ORM given a C<dbh>, C<forked> itself croaks.

=item $bool = $h->can_async

=item $bool = $h->can_aside

=item $bool = $h->can_forked

True when the mode can run here, false where it would croak.

=item $h2 = $h->maybe_async

=item $h2 = $h->maybe_aside

=item $h2 = $h->maybe_forked

The mode when it can run, otherwise no mode change. Either way a new handle
without cached rows, as for any modifier. Void context croaks.

On an ordinary handle, falling back runs the query normally on the ORM's
connection. A handle already in another mode keeps it. Inside a
transaction that query sees the transaction's own uncommitted writes, while
C<aside> and C<forked> see committed data only.

Everything else (C<iter>, C<ready>, C<all>, C<count>) works the same either
way.

=back

=head2 Joins

    my @rows = $orm->handle('posts')
        ->join('users', as => 'author')
        ->where({
            'author.name' => 'Alice',
            'posts.views' => {'>' => 10},
        })
        ->order_by('posts.id')
        ->all;

    for my $row (@rows) {
        my $post   = $row->row('posts');
        my $author = $row->row('author');
        my $title  = $row->data->{'posts.title'};
    }

    # Every user and their posts, keeping users without any.
    my @users = $orm->handle('users')
        ->left_join('posts', link => {id => 'user_id'})
        ->order_by('users.name')
        ->all;

=over 4

=item $h2 = $h->join($table, as => $name, from => $name, link => \%link)

=item $h2 = $h->join($table, as => $name, from => $name, via => \%via)

=item $h2 = $h->inner_join($table, ...)

=item $h2 = $h->left_join($table, ...)

Join another table to a table handle, or to a join handle (see
L<DBIx::QuickORM::Source::Join>). C<join> and C<inner_join> are inner joins,
C<left_join> a left join.

Options (an unknown one croaks):

=over 4

=item as => $name

The component's name, the table name by default. A table can be joined more
than once, even to itself, under different names. A name already taken croaks.

=item from => $name

The component the link starts at, the base table by default.

=item link => \%link

The foreign key to join on, C<< {from_field => field} >>, as C<follow_fk>
takes it (see L<DBIx::QuickORM/Following foreign keys>). Without it there
must be exactly one foreign key between the two tables.

=item via => \%via

The fields to join on when the map knows no key between the tables, in the
same form: C<< via => {editor_id => 'id'} >>. Every field must exist. Not with
C<link>.

=back

On a join handle C<where>, C<order_by>, C<fields>, C<group_by>, and C<having>
name fields as C<component.field>. C<fields> croaks for any other name.

The rows are L<DBIx::QuickORM::JoinRow> objects. With C<row_class(undef)> they
are each row's raw data instead, a hashref keyed C<component.field>. Any other
C<row_class> croaks. A join cannot be written through: write through its
component rows.

=back

=cut

sub where    { shift->_modify(where    => WHERE(),    @_) }
sub order_by { shift->_modify(order_by => ORDER_BY(), @_) }
sub limit    { shift->_modify(limit    => LIMIT(),    @_) }
sub offset   { shift->_modify(offset   => OFFSET(),   @_) }
sub fields   { shift->_modify(fields   => FIELDS(),   @_) }
sub having   { shift->_modify(having   => HAVING(),   @_) }

# Perl keywords, but fine as method names: they are only ever called as $h->and(...) and $h->or(...).
sub and { shift->_combine_where(and => @_) }
sub or  { shift->_combine_where(or  => @_) }

sub async  { $_[0]->_run_mode('async') }
sub aside  { $_[0]->_run_mode('aside') }
sub forked { $_[0]->_run_mode('forked') }

sub can_async  { $_[0]->_cannot_run('async')  ? 0 : 1 }
sub can_aside  { $_[0]->_cannot_run('aside')  ? 0 : 1 }
sub can_forked { $_[0]->_cannot_run('forked') ? 0 : 1 }

sub maybe_async  { $_[0]->_run_mode('async',  1) }
sub maybe_aside  { $_[0]->_run_mode('aside',  1) }
sub maybe_forked { $_[0]->_run_mode('forked', 1) }

sub join       { shift->_join([caller], join       => @_) }
sub inner_join { shift->_join([caller], inner_join => @_) }
sub left_join  { shift->_join([caller], left_join  => @_) }

sub row_class {
    my $self = shift;
    $self->{+ORM}->load_row_class($_[0]) if @_ == 1 && defined($_[0]) && !ref($_[0]);
    return $self->_modify(row_class => ROW_CLASS(), @_);
}

sub data_only {
    my $self = shift;
    croak "data_only() takes no arguments" if @_;
    return $self->_modify(data_only => ROW_CLASS(), undef);
}

sub no_cache {
    my $self = shift;
    croak "no_cache() takes no arguments" if @_;
    return $self->_modify(no_cache => NO_CACHE(), 1);
}

sub cache {
    my $self = shift;
    croak "cache() takes no arguments" if @_;
    return $self->_modify(cache => NO_CACHE(), 0);
}

sub where_builders {
    my $self = shift;
    my @args = @_ == 1 ? ($self->{+ORM}->_where_builders('where_builders()', $_[0])) : @_;
    return $self->_modify(where_builders => WHERE_BUILDERS(), @args);
}

sub group_by {
    my $self = shift;
    return $self->{+GROUP_BY} unless @_;
    croak "group_by() takes field names" if grep { !defined($_) || ref($_) || !length($_) } @_;
    return $self->_modify(group_by => GROUP_BY(), [@_]);
}

=head2 Fetching

    my $h = $orm->handle('users')->order_by('name');

    my $first = $h->first;    # runs the query
    my $last  = $h->last;     # same rows, no second query
    my @all   = $h->all;

    my $bob = $h->where({email => 'bob@example.com'})->only;    # one row or undef, croaks on more

    my @names;
    while (my $user = $h->next) {    # the handle's own position
        push @names => $user->field('name');
    }

    my $it = $h->iter;    # a new position over the same rows
    $h->clear;            # forget the rows, so the next read runs the query again

=over 4

=item $row = $h->first

=item $row = $h->last

=item @rows = $h->all

=item $row = $h->only

=item $bool = $h->ready

=item $row = $h->next

=item $h->reset

The iterator methods (see L<DBIx::QuickORM::Iterator>), on the handle's own
iterator over the handle's one run of the query.

The query runs on the first read (these or C<iter>), and the rows stay on the
handle until C<clear>. A modifier's new handle does not share them.

=back

=cut

sub first { $_[0]->_iter->first }
sub last  { $_[0]->_iter->last }
sub all   { $_[0]->_iter->all }
sub only  { $_[0]->_iter->only }
sub ready { $_[0]->_iter->ready }
sub next  { $_[0]->_iter->next }
sub reset { $_[0]->_iter->reset }

=pod

=over 4

=item $it = $h->iter

A new iterator, every call, with its own position over the handle's one run
of the query. The first read sends the query. Later calls reuse its rows.

In C<async>, C<aside>, or C<forked> mode there is one background query per
handle, however many iterators read it. Collecting through any of them
collects for all.

=back

=cut

sub iter {
    my $self = shift;
    return DBIx::QuickORM::Iterator->new(query => $self->_iter->query, state => $self->{+STATE});
}

=pod

=over 4

=item $h->clear

Forgets the handle's cached rows and its own position, in place, so the next
read sends the query again. Returns nothing.

Iterators already returned by C<iter> keep the old rows. The ORM's lookup
table is untouched. C<clear_cache> on the ORM clears that.

=back

=cut

sub clear { delete $_[0]->{+ITERATOR}; return }

=pod

=over 4

=item $n = $h->count

How many rows match the C<where>, counted by the database (C<SELECT
COUNT(*)>).

The order, limit, and offset are ignored, and nothing is ingested. It runs at
once on the ORM's connection, whatever the handle's mode. Croaks with
a C<group_by> or C<having>. Count groups with computed fields instead,
C<< fields({n => [count => '*']}) >>.

=back

=cut

sub count {
    my $self = shift;

    my @set = grep { defined $self->{$_} } GROUP_BY(), HAVING();
    croak "count() cannot count groups (the handle has a " . CORE::join(', ' => @set) . "); select fields({n => [count => '*']}) instead" if @set;

    my ($orm, $source) = @{$self}{+ORM, +SOURCE};
    my $conn = $orm->connection;
    my $row  = $conn->select($source, $orm->sql_builder->count($source, $conn->dialect, $self->_where_request))->[0];
    return (values %$row)[0];
}

=head2 Writing

    my $posts = $orm->handle('posts');

    my $post = $posts->insert({
        user_id => $id,
        title   => 'Draft',
    });
    $posts->update_row($post, {title => 'Final'});
    $posts->delete_row($post);

    my $changed = $posts->where({user_id => $id})->update({views => 0});    # how many rows changed
    my $deleted = $posts->where({views => 0})->delete;                       # how many rows went

These need a table handle. On a query or join handle they croak.

=over 4

=item $count = $h->update(\%changes)

=item $count = $h->delete

=item $count = $h->delete(mark_deleted => 1)

Updates or deletes every row matching the C<where> (every row of the table
without one) in one statement, and returns the number of rows the database
reports.

Changes are deflated as for C<update_row>, and a field the table does not have
croaks. C<update> takes exactly one hashref. C<delete> takes only
C<mark_deleted>. Both croak when the handle has an order, limit, offset,
C<group_by>, or C<having>.

The ORM then drops every canonical copy of the table's rows, since it cannot
tell which rows changed. Inside a transaction that includes the table's rows
cached from before the transaction began: they are dropped, and rolling the
outermost transaction back does not bring them back.

C<< mark_deleted => 1 >> makes C<delete> also learn which rows it deleted.
Held rows for them say C<was_deleted>, as after a row C<delete>. The table's
other rows are dropped as usual. A rollback undoes the marks. A table
without a primary key croaks.

    my $stale = $posts->find($post_id);
    $posts->where({views => 0})->delete(mark_deleted => 1);
    my $gone = $stale->was_deleted;    # true if that post had no views

The cost: the database sends back the primary key of every deleted row, and
the ORM holds them all at once, so a huge delete uses memory in proportion.

MySQL has no C<RETURNING> on C<DELETE> (MariaDB has), so there it is slower:
a C<SELECT ... FOR UPDATE> of the keys runs first, locking the rows until the
transaction ends, then the C<DELETE>. Outside a transaction both run in one
of their own. A row another session inserts and commits between the two
statements may be deleted without being marked (MySQL and Percona at
C<READ COMMITTED>, not MariaDB, which uses C<RETURNING>).

=back

=cut

sub update {
    my $self = shift;
    my ($changes) = @_;
    croak "update() takes one hashref of changes" unless @_ == 1 && ref($changes) eq 'HASH';

    my $table = $self->_bulk_table('update');
    my ($orm, $source) = @{$self}{+ORM, +SOURCE};
    my $conn = $orm->connection;
    return $conn->bulk_write($source, $orm->sql_builder->update($source, $conn->dialect, $conn->deflate($table, $changes), $self->_where_request));
}

sub delete {
    my $self = shift;
    croak "delete() takes only 'mark_deleted => \$bool'" unless !@_ || (@_ == 2 && $_[0] eq 'mark_deleted');
    my %params = @_;

    my $table = $self->_bulk_table('delete');
    my ($orm, $source) = @{$self}{+ORM, +SOURCE};
    my $conn    = $orm->connection;
    my $dialect = $conn->dialect;
    my $builder = $orm->sql_builder;
    my @where   = $self->_where_request;
    my ($sql, $binds) = $builder->delete($source, $dialect, @where);
    return $conn->bulk_write($source, $sql, $binds) unless $params{mark_deleted};

    my $pk = $conn->_table($table)->{pk};
    croak "delete(mark_deleted => 1) needs a primary key, and the table '$table' has none" unless $pk && @$pk;
    my @keys = $dialect->supports_returning_delete ? () : (keys => [$builder->select($source, $dialect, fields => $pk, @where)]);
    return $conn->bulk_write($source, $sql, $binds, mark_deleted => 1, @keys);
}

=pod

=over 4

=item $row = $h->insert(\%fields, %opts)

=item \@rows = $h->insert_many(\@rows, %opts)

=item $row = $h->find($pk, %opts)

=item $row = $h->update_row($row_or_data, \%changes, %opts)

=item $count = $h->delete_row($row_or_data, %opts)

=item $row = $h->refresh_row($row_or_data, %opts)

The ORM's CRUD operations (see L<DBIx::QuickORM/"CRUD operations">) on the
handle's table, with rows built as the handle builds them.

They follow the ORM's return rule, building rows with the handle's row class.

C<refresh_row> takes row data, a row, or a primary key. C<find> is
C<refresh_row> given a primary key. A key comes in any form:

    my $users = $orm->handle('users');
    my $user  = $users->find({id => $id});    # a hashref of the key fields (row data works)
    $user = $users->find([$id]);              # an arrayref of the values
    $user = $users->find($id);                # a single value, for a single-field key

The arrayref holds every key field's value, such as C<[$org_id, $user_id]>,
in the primary key's declared order, not the table's column order. A row
object works as its row data. Key values are deflated like any value sent,
so a C<DateTime> or a value marker works.

A typed key finds the cached row in any form: a C<DateTime> in any zone or
the database's text, a UUID in upper case or as 16 bytes.

The database gets the key as you pass it, deflated, while the cache matches
canonical values. On a text column, which compares exact text, pass the form
it stores, or give the field a C<format> (see
L<DBIx::QuickORM::Role::Type/Field hints>).

C<normalize_pk> in L<DBIx::QuickORM::Map> lists what croaks.

Each croaks when the handle has a C<where>, order, limit, offset, C<group_by>,
or C<having>.

=item $row = $h->find_or_insert(\%fields, by => \@fields, %opts)

The ORM's C<find_or_insert> (see L<DBIx::QuickORM/Finding or inserting>) on
the handle's table, building the row with the handle's row class.

It croaks as the CRUD operations above do, and on a join or query handle.

=back

=cut

sub insert      { my $self = shift; $self->_primitive(insert      => @_) }
sub insert_many { my $self = shift; $self->_primitive(insert_many => @_) }
sub update_row  { my $self = shift; $self->_primitive(update_row  => @_) }
sub refresh_row { my $self = shift; $self->_primitive(refresh_row => @_) }

sub find {
    my $self = shift;
    return $self->{+ORM}->_find([$self->_class], $self->_row_table('find'), @_);
}

sub find_or_insert {
    my $self = shift;
    return $self->{+ORM}->_find_or_insert([caller], [$self->_class], $self->_row_table('find_or_insert'), @_);
}

sub delete_row {
    my $self  = shift;
    my $table = $self->_row_table('delete_row');
    return $self->{+ORM}->connection->delete_row($table, @_);
}

=head1 PRIVATE METHODS

=over 4

=item $it = $h->_iter

The handle's own iterator, made on the first read by sending the query. It
holds the query every C<iter> shares, so a pending query lives as long as the
handle or any of its iterators.

=back

=cut

sub _iter { $_[0]->{+ITERATOR} //= DBIx::QuickORM::Iterator->new(query => $_[0]->_send, state => $_[0]->{+STATE}) }

=pod

=over 4

=item \%query = $h->_send

Sends the handle's query and returns the query hashref its iterators share
(see L<DBIx::QuickORM::Iterator>): the rows, or the pending query in a
background mode. C<aside> and C<forked> croak while a transaction is open,
and give the pending query a C<blocked> that refuses reads while one is.

=back

=cut

sub _send {
    my $self = shift;

    my ($orm, $source, $mode) = @{$self}{+ORM, +SOURCE, +MODE};
    my $conn    = $orm->connection;
    my @query   = ($source, $orm->sql_builder->select($source, $conn->dialect, $self->_select_request));
    my $results = $self->_results;

    unless ($mode) {
        my ($rows, $build) = $results->($conn->select(@query));
        return {rows => $rows, build => $build};
    }

    my $async = $mode eq 'async';
    croak "$mode() cannot start a query while a transaction is open; start it before the transaction, or after it ends" if !$async && @{$conn->txns};

    my $pending =
          $async           ? $conn->select(@query, async => 1)
        : $mode eq 'aside' ? $self->_aside($conn, @query)
        :                    $self->_forked($conn, @query);
    my $collect = $pending->{collect};
    my $blocked = $async ? undef : sub { @{$orm->connection->txns} ? "This $mode() query cannot be read while a transaction is open; read it after the transaction ends" : undef };
    return {pending => {%$pending, collect => sub { $results->($collect->()) }, blocked => $blocked}};
}

=pod

=over 4

=item $out = $h->_primitive($method, @args)

The ORM's CRUD operation on the handle's table, with rows built as the handle
builds them.

=back

=cut

sub _primitive {
    my $self = shift;
    my ($method, @args) = @_;
    return $self->{+ORM}->_primitive($method, [$self->_class], $self->_row_table($method), @args);
}

=pod

=over 4

=item $value = $h->_modify($method, $key)

=item $h2 = $h->_modify($method, $key, $value)

The setting, or a copy of the handle with it replaced, without the iterator
(and without the state when the C<where> or the source changes). C<$method>
is the public modifier, for messages. Croaks on more than one argument, a bad
C<fields> or C<row_class> value, or void context, where the copy would be
lost.

=back

=cut

sub _modify {
    my $self = shift;
    my ($method, $key, @args) = @_;
    return $self->{$key} unless @args;
    croak "$method() takes one argument" if @args > 1;

    my ($value) = @args;
    croak "fields() takes an arrayref of field names or a hashref of computed columns" if $key eq FIELDS()    && !$self->_fields_ok($value);
    croak "row_class() takes a class name or undef"                                    if $key eq ROW_CLASS() && ref($value);

    my %clone = (%$self, $key => $value);
    delete $clone{+ITERATOR};
    delete $clone{+STATE} if $key eq WHERE() || $key eq SOURCE();
    delete $clone{+COLUMNS} if $key eq FIELDS() || $key eq SOURCE() || $key eq GROUP_BY();

    my $clone = bless(\%clone, ref($self));
    $clone->_columns if $key eq FIELDS() && ref($value) eq 'HASH';
    croak "$method() returns a new handle and leaves this one unchanged; calling it in void context does nothing" unless defined wantarray;
    return $clone;
}

=pod

=over 4

=item $h2 = $h->_combine_where($op, $where)

The handle with its C<where> combined with C<$where> by the builder's
C<combine_where>. Croaks, pointing to C<where>, when the handle has no
C<where> or an empty one.

=back

=cut

sub _combine_where {
    my $self = shift;
    my ($op, @args) = @_;
    croak "$op() takes one condition" unless @args == 1;

    my $old  = $self->{+WHERE};
    my $type = ref($old);
    croak "$op() needs a where to combine with; this handle has none, use where() instead"
        if !defined($old) || ($type eq 'HASH' && !%$old) || ($type eq 'ARRAY' && !@$old) || ($type eq '' && $old eq '');

    return $self->_modify($op, WHERE(), $self->{+ORM}->sql_builder->combine_where(op => $op, left => $old, right => $args[0]));
}

=pod

=over 4

=item $h2 = $h->_join(\@frame, $method, $table, %opts)

The handle over its source with one more joined table, making a join from a
table source first. Link errors report at C<@frame>, the public method's
C<caller> frame.

=back

=cut

sub _join {
    my $self = shift;
    my ($frame, $method, $table, %opts) = @_;
    my $type = $method eq 'left_join' ? 'left' : 'inner';

    my @unknown = sort grep { !m/^(?:as|from|link|via)\z/ } keys %opts;
    croak "Unknown argument(s) to a join: " . CORE::join(', ' => @unknown) if @unknown;
    croak "A join needs the table to join" unless defined($table) && length($table);

    my $orm    = $self->{+ORM};
    my $map    = $orm->db_map;
    my $source = $self->{+SOURCE};
    unless ($source->isa('DBIx::QuickORM::Source::Join')) {
        croak "Joins start from a table handle" unless $source->isa('DBIx::QuickORM::Source::Table');
        $source = DBIx::QuickORM::Source::Join->new(db_map => $map, components => [{as => $source->table, table => $source->table}]);
    }

    my $link = $orm->_link_for($frame, $map, $source->component_table($opts{from}), $table, {link => delete $opts{link}, via => delete $opts{via}});
    return $self->_modify($method, SOURCE(), $source->extend($type, $table, %opts, link => $link));
}

=pod

=over 4

=item $h2 = $h->_run_mode($mode)

=item $h2 = $h->_run_mode($mode, $maybe)

The handle with the mode set. Without C<$maybe> it croaks with
C<_cannot_run>'s reason. With it, a mode that cannot run leaves the mode as
it was, but the handle is still a new one.

=item $reason = $h->_cannot_run($mode)

Why the mode cannot run, or undef when it can: the database has no async
queries, or the mode needs a second connection and none can reach the
database or the ORM was given a C<dbh>.

=back

=cut

sub _run_mode {
    my $self = shift;
    my ($mode, $maybe) = @_;

    my $reason = $self->_cannot_run($mode);
    croak $reason if $reason && !$maybe;
    return $self->_modify(($maybe ? "maybe_$mode" : $mode), MODE(), $reason ? $self->{+MODE} : $mode);
}

sub _cannot_run {
    my $self = shift;
    my ($mode) = @_;

    my $conn    = $self->{+ORM}->connection;
    my $dialect = $conn->dialect;
    my $name    = $dialect->name;
    return "The $name dialect has no async queries, so $mode() cannot run"                     if $mode ne 'forked' && !$dialect->supports_async;
    return "No second connection can reach this $name database, so $mode() cannot run"         if $mode ne 'async'  && !$dialect->supports_second_connection($conn->dbh);
    return "This ORM was given a 'dbh', so it cannot open the second connection $mode() needs" if $mode ne 'async'  && !$self->{+ORM}->_can_connect;
    return undef;
}

=pod

=over 4

=item \%pending = $h->_aside($conn, $source, $sql, \@binds)

Starts the query as an async one on a new Connection like C<$conn>, and
returns its pending code references, closing that connection once it is
collected or cancelled. The code references hold the ORM, not the handle.

=back

=cut

sub _aside {
    my $self = shift;
    my ($conn, @query) = @_;

    my $orm     = $self->{+ORM};
    my $aside   = $orm->_connect_like($conn);
    my $pending = $aside->select(@query, async => 1);
    my $close   = sub { $aside->dbh->disconnect };
    return {
        ready   => $pending->{ready},
        collect => sub {
            my $rows;
            my $ok  = eval { $rows = $pending->{collect}->(); 1 };
            my $err = $@;
            $close->();
            die $err unless $ok;
            return $rows;
        },
        cancel => sub {
            eval { $pending->{cancel}->(); 1 } or warn $@;
            $close->();
        },
    };
}

=pod

=over 4

=item \%pending = $h->_forked($conn, $source, $sql, \@binds)

Forks a child that runs the query on a new Connection like C<$conn>, writes
one message, and leaves through C<POSIX::_exit> on every path, so nothing it
inherited is destroyed there.

The message is a L<Storable> C<freeze> of C<< {rows => \@rows} >> or
C<< {error => $message} >>. It is not C<nfreeze>, which keeps no more than 15
significant digits of a float.
C<ready> reads without blocking, C<collect> blocks, and C<cancel> kills and
reaps the child.

=back

=cut

sub _forked {
    my $self = shift;
    my ($conn, @query) = @_;

    my $orm = $self->{+ORM};

    my ($reader, $writer) = Atomic::Pipe->pair;
    my $pid = fork // die "Could not fork: $!";
    unless ($pid) {
        my $out = eval {
            $reader->close;
            my $child = $orm->_connect_like($conn);
            my $rows  = $child->select(@query);
            $child->dbh->disconnect;
            +{rows => $rows};
        } || +{error => "$@"};
        eval { $writer->write_message(freeze($out)); $writer->close; 1 } or warn $@;
        POSIX::_exit(0);
    }
    $writer->close;

    my $msg;
    my $reap = sub { local $?; waitpid($pid, 0) };
    return {
        ready => sub {
            $reader->blocking(0);
            $msg //= $reader->read_message;
            my $ready = defined($msg) || $reader->eof;    # eof reads too, so it must not block either
            $reader->blocking(1);
            return $ready;
        },
        collect => sub {
            $msg //= $reader->read_message;
            $reap->();
            die "The forked query ended without sending its result\n" unless defined $msg;
            my $out = thaw($msg);
            die "The forked query failed: $out->{error}" . ($out->{error} =~ m/\n\z/ ? '' : "\n") if defined $out->{error};
            return $out->{rows};
        },
        cancel => sub { kill('KILL', $pid); $reap->() },
    };
}

=pod

=over 4

=item $code = $h->_results

A code reference turning fetched rows into C<(\@rows, \&build)> for an
iterator, given the rows: through the source's C<results>, ingesting them
unless the handle is C<no_cache>, or as computed rows. It holds
the ORM and the source, not the handle, so a pending iterator kept in the
handle makes no cycle.

=back

=cut

sub _results {
    my $self = shift;
    my ($orm, $source) = @{$self}{+ORM, +SOURCE};
    my @class  = $self->_class;
    my $cached = !$self->{+NO_CACHE};
    return sub { $source->results($orm, $_[0], $cached, @class) }
        unless $self->_computed;

    return sub { ($_[0], $orm->_row_builder(undef, @class)) }
        if @class;
    return sub { ($_[0], undef) }
        unless defined $orm->_row_class($source->table);

    my $columns = $self->_columns;
    return sub { ($_[0], sub { DBIx::QuickORM::AggregateRow->new(orm => $orm, source => $source, columns => $columns, row_data => $_[0]) }) };
}

=pod

=over 4

=item %request = $h->_select_request

The builder's C<select> request: the handle's settings (the C<where> through
C<_where_request>), with the primary key
added to C<fields>, or the source's default fields. For computed rows, each
column's expression under its name.

=back

=cut

sub _select_request {
    my $self   = shift;
    my $source = $self->{+SOURCE};

    my $given = $self->{+FIELDS};
    if ($self->_computed) {
        my $columns = $self->_columns;
        $given = {map { ($_ => $columns->{$_}->{expr}) } keys %$columns};
    }

    my %request = (fields => $source->select_fields($given), map { ($_ => $self->{$_}) } ORDER_BY(), LIMIT(), OFFSET(), GROUP_BY(), HAVING());
    return ($self->_where_request, map { defined($request{$_}) ? ($_ => $request{$_}) : () } keys %request);
}

=pod

=over 4

=item %request = $h->_where_request

The C<where> and C<where_builders> for a builder request: the handle's where
builders, or the ORM's. Empty without a C<where>.

=back

=cut

sub _where_request {
    my $self  = shift;
    my $where = $self->{+WHERE};
    return () unless defined $where;
    return (where => $where, where_builders => $self->{+WHERE_BUILDERS} // $self->{+ORM}->where_builders);
}

=pod

=over 4

=item $bool = $h->_computed

True when the handle yields computed rows.

=back

=cut

sub _computed {
    my $self = shift;
    return 1 if ref($self->{+FIELDS}) eq 'HASH';
    return defined($self->{+GROUP_BY}) || defined($self->{+HAVING}) ? 1 : 0;
}

=pod

=over 4

=item $bool = $h->_fields_ok($value)

True for what C<fields> takes: an arrayref of field names, or a non-empty
hashref (its columns are checked by C<_columns>).

=back

=cut

sub _fields_ok {
    my $self = shift;
    my ($value) = @_;
    return !grep { !$self->_is_name($_) } @$value if ref($value) eq 'ARRAY';
    return ref($value) eq 'HASH' && %$value ? 1 : 0;
}

=pod

=over 4

=item \%columns = $h->_columns

The computed columns, built once per handle: each name mapped to its field
record (as L<DBIx::QuickORM::AggregateRow> takes C<columns>) plus C<expr>, a
field name, an C<sql()> marker, or C<[$FUNC, $field]> (C<$field> may be C<*>). A record's C<name> is
the column's, and its C<table> the source's table, absent when it has none.
Without a C<fields> hashref, the grouped or listed fields each name
themselves. Croaks when C<having> has neither.

=back

=cut

sub _columns {
    my $self = shift;
    return $self->{+COLUMNS} if $self->{+COLUMNS};

    my $given = $self->{+FIELDS};
    if (ref($given) ne 'HASH') {
        my $names = $given // $self->{+GROUP_BY} // [];
        croak "A handle with having() needs group_by() or fields to select" unless @$names;
        $given = {map { $_ => $_ } @$names};
    }

    my %like  = map { (lc($_) => 1) } qw/min max/, @{$self->{+ORM}->like_aggregates // []};
    my $table = $self->{+SOURCE}->table;
    my %columns;
    for my $name (keys %$given) {
        # A column is named for itself, not for the field whose facts it took.
        my $column = $columns{$name} = $self->_column($name, $given->{$name}, \%like);
        $column->{name} = $name;
        delete $column->{table};
        $column->{table} = $table if defined $table;
    }

    return $self->{+COLUMNS} = \%columns;
}

my %COLUMN_KEYS = map { $_ => 1 } qw/sql agg type db_type fk like/;

=pod

=over 4

=item \%column = $h->_column($name, $spec, \%like)

One column of C<_columns>. C<%like> holds the lowercased names of the
aggregate functions that keep the field's facts.

=back

=cut

sub _column {
    my $self = shift;
    my ($name, $spec, $like) = @_;

    return {expr => $spec, $self->_field_facts($name, $spec)} if $self->_is_name($spec);
    $spec = DBIx::QuickORM::Value::sql($$spec) if ref($spec) eq 'SCALAR';    # \"SQL" is sql("SQL")
    $spec = $self->_is_sql($spec) ? {sql => $spec} : ref($spec) eq 'ARRAY' ? {agg => $spec} : $spec;
    croak "Column '$name' must be a field name, an sql() marker, \\'SQL', [func, field], or a hashref" unless ref($spec) eq 'HASH';

    my @unknown = sort grep { !$COLUMN_KEYS{$_} } keys %$spec;
    croak "Unknown key(s) in column '$name': " . CORE::join(', ' => @unknown) if @unknown;
    croak "Column '$name' needs exactly one of 'sql' or 'agg'" unless exists($spec->{sql}) xor exists($spec->{agg});

    my %column;
    if (exists $spec->{sql}) {
        croak "'sql' in column '$name' must be an sql() marker" unless $self->_is_sql($spec->{sql});
        $column{expr} = $spec->{sql};
    }
    else {
        my $agg = $spec->{agg};
        my ($func, $field) = ref($agg) eq 'ARRAY' && @$agg == 2 ? @$agg : ();
        croak "'agg' in column '$name' must be [func, field]" unless $self->_is_name($func) && $self->_is_name($field);
        croak "Column '$name' names the function '$func', which is not a word (/^\\w+\$/)" unless $func =~ m/^\w+\z/;
        # _field_facts also checks the field exists. '*' names no field, so has no facts.
        my %facts = $field eq '*' ? () : $self->_field_facts($name, $field);
        %column = (expr => [uc($func), $field], $like->{lc $func} && !defined($spec->{like}) ? %facts : ());
    }

    %column = (%column, $self->_field_facts($name, $spec->{like})) if defined $spec->{like};

    if (defined $spec->{db_type}) {
        delete $column{size};    # the dialect derives it from the db_type, or there is none
        %column = (%column, %{$self->{+ORM}->connection->dialect->field_facts($spec->{db_type})});
    }

    $column{fk} = $self->_column_fk($name, $spec->{fk}) if exists $spec->{fk};
    if (defined $spec->{type}) {
        # Recompute passthrough for the new type, as the map build does.
        my $type = $column{orm_type} = $self->{+ORM}->require_type($spec->{type}, 'type');
        delete $column{passthrough};
        $column{passthrough} = 1 if $type->can('inflate_is_identity') && $type->inflate_is_identity(\%column);
    }

    return \%column;
}

=pod

=over 4

=item %facts = $h->_field_facts($name, $field)

The field's record from the map (C<orm_type>, C<db_type>, C<type>, C<size>,
C<affinity>, as it has them) and its single-field foreign keys as C<fk>, for
the column C<$name>. Croaks when the field is not a field of the source. A
query source knows no fields, so a name passes unchecked with no facts.

=back

=cut

sub _field_facts {
    my $self = shift;
    my ($name, $field) = @_;

    croak "Column '$name' must name a field" unless $self->_is_name($field);

    my $source  = $self->{+SOURCE};
    my $records = $source->field_records;
    return () unless %$records;
    my $record = $records->{$field} or croak "Column '$name' names '$field', which is not a field of the handle's source";

    my ($alias, $short) = $field =~ m/^(?:(.+)\.)?([^.]+)\z/;
    my $table = $source->table                             // $source->component_table($alias);
    my $fks   = $self->{+ORM}->db_map->table($table)->{fk} // {};

    my %fk;
    for my $other (keys %$fks) {
        my @to = map { $_->{$short} } grep { keys(%$_) == 1 && exists $_->{$short} } @{$fks->{$other}};
        $fk{$other} = [map { +{$name => $_} } @to] if @to;
    }

    return (%$record, %fk ? (fk => \%fk) : ());
}

=pod

=over 4

=item \%fk = $h->_column_fk($name, $fk)

An C<fk> given for column C<$name> (a table, C<[$table, $field]>, or
C<< {$table => $field} >>) as C<< {$table => [{$name => $field}]} >>. Croaks
when its table or field is not in the map, or a bare table's primary key is
not one field.

=back

=cut

sub _column_fk {
    my $self = shift;
    my ($name, $fk) = @_;

    my $type  = ref($fk);
    my @parts = $type eq 'ARRAY' ? @$fk : $type eq 'HASH' ? %$fk : $type ? () : ($fk);
    my $ok    = (@parts == 1 && !$type) || (@parts == 2 && $type);
    croak "'fk' in column '$name' must be a table, [table, field], or {table => field}" unless $ok && !grep { !$self->_is_name($_) } @parts;

    my ($table, $field) = @parts;
    my $t = $self->{+ORM}->db_map->table($table) or croak "'fk' in column '$name' names the table '$table', which is not in the database map";
    unless (defined $field) {
        my $pk = $t->{pk};
        croak "'fk' in column '$name' names the table '$table', whose primary key is not a single field" unless $pk && @$pk == 1;
        $field = $pk->[0];
    }
    croak "'fk' in column '$name' names '$table.$field', which is not a field" unless $t->{fields}->{$field};

    return {$table => [{$name => $field}]};
}

=pod

=over 4

=item $bool = $h->_is_name($value)

True for a defined, non-empty plain string.

=item $bool = $h->_is_sql($value)

True for an C<sql()> marker.

=back

=cut

sub _is_name { defined($_[1]) && !ref($_[1])                         && length($_[1])        ? 1 : 0 }
sub _is_sql  { blessed($_[1]) && $_[1]->isa('DBIx::QuickORM::Value') && $_[1]->kind eq 'sql' ? 1 : 0 }

=pod

=over 4

=item @class = $h->_class

The row class override as a one-item list, or an empty list when none was set.

=back

=cut

sub _class { exists($_[0]->{+ROW_CLASS}) ? ($_[0]->{+ROW_CLASS}) : () }

=pod

=over 4

=item $row = $h->_row(\%data)

The row data built into a row as the handle builds rows, or undef for undef.

=back

=cut

sub _row {
    my $self = shift;
    my ($data) = @_;
    return $self->{+ORM}->_row($self->{+SOURCE}->table, $data, $self->_class);
}

=pod

=over 4

=item $table = $h->_table($action)

The source's table. Croaks naming the action for a source without one.

=back

=cut

sub _table {
    my $self     = shift;
    my ($action) = @_;
    my $table    = $self->{+SOURCE}->table;
    croak "$action() needs a handle on a table, not a query or join" unless defined $table;
    return $table;
}

=pod

=over 4

=item $table = $h->_bulk_table($action)

=item $table = $h->_row_table($action)

The table, after croaking for the settings the action cannot honor.

=back

=cut

sub _bulk_table {
    my $self     = shift;
    my ($action) = @_;
    my $table    = $self->_table($action);
    my @set      = grep { defined $self->{$_} } ORDER_BY(), LIMIT(), OFFSET(), GROUP_BY(), HAVING();
    croak "$action() cannot honor the handle's " . CORE::join(', ' => @set) if @set;
    return $table;
}

sub _row_table {
    my $self     = shift;
    my ($action) = @_;
    my $table    = $self->_table($action);
    my @set      = grep { defined $self->{$_} } WHERE(), ORDER_BY(), LIMIT(), OFFSET(), GROUP_BY(), HAVING();
    croak "$action() works on the whole table, but the handle has a " . CORE::join(', ' => @set) if @set;
    return $table;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

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
