package DBIx::QuickORM;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/carp croak/;
use List::Util qw/first/;
use Scalar::Util qw/blessed/;
use DBI();

use DBIx::QuickORM::Connection();
use DBIx::QuickORM::Handle();
use DBIx::QuickORM::LookupTable();
use DBIx::QuickORM::Map();
use DBIx::QuickORM::Row();
use DBIx::QuickORM::Source::Query();
use DBIx::QuickORM::Source::Table();
use DBIx::QuickORM::SQLBuilder::SQLAbstract();
use DBIx::QuickORM::WhereBuilder::RawSQL();
use DBIx::QuickORM::WhereBuilder::Simple();
use DBIx::QuickORM::WhereBuilder::SQLAbstract();
use DBIx::QuickORM::Value qw/raw sql/;

# Our own new() wraps init(). Predeclared so Object::HashBase does not add one.
sub new;

use Object::HashBase qw{
    <row_class
    <row_classes
    <row_namespace
    <row_class_name
    <omit
    <default_fields
    <types
    <autotype
    <append_autotype
    <fks
    <sql_builder
    <connector
    +connection
    <_can_connect
    <like_aggregates
    <type_options
    +table_sources
    <where_builders
    +fast_bless
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM - An ORM that quickly gives you what you need with minimal boilerplate, and easily extends to more complex use cases.

=head1 WHERE TO START

New to the ORM? Read L<DBIx::QuickORM::Manual::Quickstart>: short examples of
everything most applications need. See L<DBIx::QuickORM::Manual> for
additional resources.

=head1 DESCRIPTION

Connect and start working. DBIx::QuickORM scans the live database and uses
what it finds as the schema. There is no schema, table, or column metadata
to declare. Most of it is automatic. Insert, find, update, delete, and query
rows right away.

Rows come back as L<DBIx::QuickORM::Row> objects, but custom row classes can be
defined, or you can request plain hashrefs be returned if you do not want the
overhead of a full row object.

When the scan gets something wrong, or you need custom behavior, it is easy to
adjust: omit fields by default, give a field a data type for inflation, add
foreign keys the database does not declare, and so on. See C<new> (under
L</Constructor>), or the easy to use DSL (L<DBIx::QuickORM::DSL>), for details.

Larger applications can declare the ORM and its row classes in their own
modules. See L<DBIx::QuickORM::ORM>.

Supported databases: PostgreSQL, MySQL, MariaDB, SQLite, and DuckDB.

This distribution is still considered experimental and may change
significantly without warning.

=head1 SYNOPSIS

    use DBIx::QuickORM;

    my $orm = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
    );

    my $bob = $orm->insert(users => {name => 'Bob'});
    my $row = $orm->find(users => $bob->field('id'));

    $bob->update({name => 'Robert'});

    my @roberts = $orm->handle('users')
        ->where({name => 'Robert'})
        ->all;

    $orm->txn(sub {
        $orm->insert(users => {name => 'Ann'});
        $orm->insert(users => {name => 'Cy'});
    });

    $bob->delete;

=head1 PUBLIC METHODS

=head2 Constructor

=over 4

=item $orm = DBIx::QuickORM->new(%args)

=item $orm = DBIx::QuickORM->new(\%args)

Connects, scans the database into a map of its tables and fields
(L<DBIx::QuickORM::Map>), and returns the ORM. Pass exactly one of C<dbh>,
C<connect>, or C<credentials>. An unknown argument croaks.

    my $orm = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        omit         => {users => ['prefs']},    # selected only when asked for
        row_classes  => {posts => undef},        # posts come back as plain hashrefs
        retain_cache => 1,                       # keep rows cached until clear_cache()
    );

The connection argument, one of:

=over 4

=item dbh => $dbh

A connected L<DBI> handle with C<RaiseError> and C<AutoCommit> on. The ORM
takes it over and may change its attributes. Using it elsewhere is
unsupported.

With this form the ORM cannot open a second connection: using the ORM from a
forked child croaks, and so do C<aside> and C<forked> on its handles (see
L<DBIx::QuickORM::Handle/Running elsewhere>).

=item connect => sub { ... }

A code reference that returns a new, uncached handle with C<RaiseError> and
C<AutoCommit> on each time it is called.

=item credentials => {dsn => $dsn, user => $user, pass => $pass, attrs => \%attrs}

Arguments for C<< DBI->connect >>. C<dsn> is required. C<user>, C<pass>, and
C<attrs> are optional. Other keys croak. C<RaiseError> and C<AutoCommit> are
always turned on, and C<AutoCommit> given false in C<attrs> croaks.

=back

The ORM manages transactions, so every form needs C<AutoCommit> on. A handle
with C<AutoCommit> off, or with a transaction already open, croaks.

The remaining arguments adjust the map. The database is scanned into a
L<DBIx::QuickORM::Map> unless C<db_map> is given. These arguments then change
it, in this order. Each type or row class they name is loaded during C<new>.

Naming a table or field not in the map croaks, as does an argument of the
wrong type.

=over 4

=item db_map => $map

A L<DBIx::QuickORM::Map>, or a hashref of map data, used instead of a scan.
It is deep-copied, so the original is never changed. The arguments below
adjust the copy.

=item autotype => \@types

=item autotype => undef

=item append_autotype => \@types

The types tried, in order, on each field when the map is built. The first
that matches becomes the field's C<orm_type>. Default: C<UUID>, C<JSON>, then
C<DateTime> (L<DBIx::QuickORM::Type::UUID>, L<DBIx::QuickORM::Type::JSON>,
L<DBIx::QuickORM::Type::DateTime>).

C<< autotype => undef >> or C<[]> turns this off. C<append_autotype> adds to
the C<autotype> list, or to the default. With a C<db_map>, the map keeps its
types unless either is given. Then every field is typed again.

A type matches through its C<base_types> or C<matches> (see
L<DBIx::QuickORM::Role::Type>).

Type names work the same everywhere: a bare name such as C<JSON> means
C<DBIx::QuickORM::Type::JSON>, and a leading C<+> marks a full class name,
such as C<+My::Type>. The map holds the full name.

Array fields are never typed automatically: those whose C<db_type> ends in
C<[]> or C<[N]> (PostgreSQL arrays, DuckDB lists and fixed-size arrays). Use
C<types> to give one a type.

=item types => {table => {field => $type_or_undef}}

=item types => {table => {field => {class => $type_or_undef, format => \&code, generate => $mode}}}

Sets a field's type. Undef removes it.

The hashref form also sets field hints: C<format> and C<generate> (see
L<DBIx::QuickORM::Role::Type/Field hints>). Without C<class> it keeps the
field's type.

Either form replaces the field's hints with the ones given (none for the plain
form). C<type_options> then fills in the rest. Other keys croak, and so does a
hint on a field left without a type.

=item type_options => {$type => {format => \&code, generate => $mode}}

Field hints for every field of a type, such as C<< {UUID => {format => sub { uc $_[0] }}} >>.
A field's own hints in C<types> win, each hint separately.

=item fks => {table => {other_table => [{field => other_field}, ...]}}

Foreign keys to add to the scanned ones. A key identical to one the table
already has is ignored. A key over the same fields that maps them differently
croaks.

=item omit => {table => \@fields}

=item default_fields => {table => \@fields}

Set which fields a table's queries select by default (the table's
C<default_fields>).

C<omit> selects every field but the ones listed. C<default_fields> selects the
ones listed plus the primary key. A table named in neither selects every
field, unless a given C<db_map> sets its default fields.

Croaks when both name the same table, when C<omit> names a primary key field,
or when no field is left.

=item row_classes => {table => $class_or_undef}

The row class for one table's rows. Undef means hashrefs.

Every row class named anywhere is loaded unless it already has a C<new>
method. One that cannot be loaded croaks.

=item row_namespace => $namespace

Gives each table a row class under C<$namespace>, named from the table:
C<user_posts> gets C<${namespace}::UserPosts>.

A table with an entry in C<row_classes> (or in a given C<db_map>) keeps it.

A table whose class is not loaded and has no module keeps the default row
class. A module that
fails to load croaks with its error.

A class found this way must do L<DBIx::QuickORM::Role::Row>. One that does
not croaks, naming the table and the class.

A table name that gives no valid class name (it must start with a letter or
C<_> and hold only word characters) warns and keeps the default row class.

=item row_class_name => sub { my ($table) = @_; return $name }

Replaces how C<row_namespace> names a table's class. It gets the table name
and returns the part after the namespace, such as C<'Person'> for C<people>.

Returning undef keeps the default row class for that table, without a
warning. Returning an invalid name (one holding C<::>, say) warns and keeps
the default.

=back

C<row_class>, C<sql_builder>, C<where_builders>, and C<like_aggregates> are
described under L</ATTRIBUTES>. C<retain_cache>, C<enforce_canon>,
C<isolation>, C<time_zone> (or C<tz>), and C<datetime_parsers> are described
under L</Settings>. A setting of the wrong type croaks.

A subclass constructor can pass C<< caller => [caller] >> so errors from
C<new> name its own caller's line. It is not kept on the object.

=back

=cut

my %ARGS;
my @DEFAULT_WHERE_BUILDERS = map { "DBIx::QuickORM::WhereBuilder::$_" } qw/RawSQL Simple SQLAbstract/;

sub new {
    my $class = shift;
    my $self  = bless(@_ == 1 && ref($_[0]) eq 'HASH' ? {%{$_[0]}} : {@_}, $class);
    my $frame = delete($self->{caller}) // [caller];

    eval { $self->init; 1 } or _rethrow_at($frame, "$class->new()", $@);

    return $self;
}

sub init {
    my $self = shift;

    my @unknown = sort grep { !$ARGS{$_} } keys %$self;
    croak "Unknown argument(s) to new(): " . join(', ' => @unknown) if @unknown;

    $self->_check_args;

    $self->{+CONNECTOR}   = $self->_build_connector;
    $self->{+SQL_BUILDER} = $self->_build_sql_builder;

    $self->{+WHERE_BUILDERS} = $self->_where_builders("'where_builders'", $self->{+WHERE_BUILDERS} // [@DEFAULT_WHERE_BUILDERS]);

    $self->{+ROW_CLASS} = 'DBIx::QuickORM::Row' unless exists $self->{+ROW_CLASS};

    my %settings = map { exists($self->{$_}) ? ($_ => delete $self->{$_}) : () } qw/retain_cache enforce_canon isolation time_zone datetime_parsers/;
    my $given    = delete $self->{db_map};
    my $conn     = $self->{+CONNECTION} = $self->_connect(%settings, db_map => $self->_copy_map($given));
    $self->_setup_map($conn->db_map, defined $given);
}

=pod

=head2 Settings

=over 4

=item $conn = $orm->connection

The current L<DBIx::QuickORM::Connection>.

In a forked child, the ORM drops the inherited handle without closing the
parent's session. It then opens a new Connection from the connector, keeping
the map and settings.

That croaks when the ORM was given a C<dbh>, and when a second connection
cannot reach the same data (an in-memory SQLite database, or DuckDB).

=back

=cut

sub connection {
    my $self = shift;

    my $conn = $self->{+CONNECTION};
    return $conn if $conn->pid == $$;

    my $shared = $conn->dialect->supports_second_connection($conn->dbh);
    $conn->release_inherited;
    croak "This ORM's database cannot be opened by a second connection (an in-memory SQLite database, or DuckDB), so a forked child cannot reconnect" unless $shared;
    return $self->{+CONNECTION} = $self->_connect_like($conn);
}

=pod

=over 4

=item $map = $orm->db_map

The L<DBIx::QuickORM::Map> built when the ORM was constructed.

=item $bool = $orm->retain_cache

Whether canonical copies stay in the row cache outside a transaction.
Default 0.

With 0 they are held weakly and freed once nothing else uses them. With 1 they
stay until C<clear_cache>.

=item $bool = $orm->enforce_canon

Whether C<update_row> and C<delete_row> refuse row data that is not
canonical. Default 1.

Outside a transaction, they croak when given row data that is not the
canonical copy. Inside one, the check is on by default whatever this says. Each
call can override it.

=item $orm->set_enforce_canon($bool)

Change C<enforce_canon> on the current Connection, for every write after the
call.

=item $level = $orm->isolation

The default isolation level for outermost transactions. Undef means
C<'read committed'>. Takes the levels C<txn> takes (see C<txn> under
L</Transactions>).

=item $tz = $orm->time_zone

The session time zone, C<UTC> unless given. MySQL and MariaDB get C<UTC> as
C<+00:00>. SQLite has no session time zone.
C<new> also accepts it as C<tz>. Giving both croaks.

=item \@parsers = $orm->datetime_parsers

Parsers for date and time text that neither the database's own parser nor
L<DateTime::Format::ISO8601> reads, tried in order. Empty unless given.

    use DateTime::Format::Strptime;

    my $orm = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        datetime_parsers => [
            DateTime::Format::Strptime->new(pattern => '%d/%m/%Y %H:%M'),
            # epoch seconds
            sub { $_[0] =~ m/^\d+\z/ ? DateTime->from_epoch(epoch => $_[0]) : undef },
        ],
    );

Each is a class or object with C<parse_datetime>, or a code reference taking
the text. C<new> loads each class, and croaks when one cannot be loaded or has
no C<parse_datetime>.

A parser says no by returning undef or dying. The first DateTime returned
wins. Returning anything else croaks.

=item $orm->set_datetime_parsers(\@parsers)

Replace C<datetime_parsers> on the current Connection, checked as C<new>
checks it, for values read after the call.

A DateTime field read before the call keeps the parsers it was read with, even
while still unparsed.

=back

Only C<enforce_canon> and C<datetime_parsers> have setters. The other settings
are fixed when the ORM is built. Build a new ORM to change them. A forked
child's new Connection keeps the changed values.

=cut

sub db_map            { $_[0]->connection->db_map }
sub retain_cache      { $_[0]->connection->retain_cache }
sub enforce_canon     { $_[0]->connection->enforce_canon }
sub set_enforce_canon { $_[0]->connection->set_enforce_canon($_[1]) }
sub isolation         { $_[0]->connection->isolation }
sub time_zone         { $_[0]->connection->time_zone }
sub datetime_parsers  { $_[0]->connection->datetime_parsers }

sub set_datetime_parsers {
    my $self  = shift;
    my $frame = [caller];
    eval { $self->connection->set_datetime_parsers(@_); 1 } or _rethrow_at($frame, 'set_datetime_parsers()', $@);
}

=pod

=head2 The row cache

The ORM caches one canonical copy of each row's data, by primary key. A row
is canonical when its data is that copy. That does not mean it matches the
database right now.

=over 4

=item $bool = $orm->is_canon($table, $row_or_data)

True when the row data (or a row object's C<row_data>) is the canonical copy
for its primary key.

False when it is not, or when the row cache has no copy for that key. Croaks
when the primary key cannot be determined.

So a row missing part of its key (a new row from C<vivify>, say) croaks here,
while the row's own C<is_canon> answers false.

=item $orm->clear_cache

=item $orm->clear_cache($table)

=item $orm->clear_cache($table => $pk)

Forgets canonical copies: all of them, one table's, or one row's.
They are read from the database again when next looked up.

    my $user = $orm->find(users => $id);
    my $held = $orm->is_canon(users => $user);    # true: $user's data is the canonical copy

    $orm->clear_cache(users => $id);              # or clear_cache('users'), or clear_cache()
    my $still = $orm->is_canon(users => $user);   # false
    $user->refresh;                               # canonical again

C<$pk> takes the forms C<find> takes (see L<DBIx::QuickORM::Handle>), and its
values are deflated (turned into database form) the same way.

A typed key matches in any form: a C<DateTime> or the database's text, a
UUID in upper case or as 16 bytes.

Inside a transaction, it clears the current transaction or savepoint level,
and the cache from before the outermost transaction. A savepoint rollback
restores what the enclosing level held. L</Transactions> says what ending the
outermost transaction does.

A handle that already ran keeps its rows. Call its C<clear> to query again.

=back

=cut

sub is_canon { my $self = shift; $self->connection->is_canon(@_) }

sub clear_cache {
    my $self = shift;
    my ($table, @pk) = @_;
    my $conn = $self->connection;
    return $conn->lookup->forget(@_) unless @pk;
    return $conn->lookup->forget($table, $conn->_plain($conn->_pk_values($table, $pk[0])));
}

=head2 CRUD operations

    # a row object
    my $ann = $orm->insert(
        users => {
            name  => 'Ann',
            prefs => {theme => 'dark'},
        },
    );

    # row data: a hashref
    my $ben = $orm->insert(
        users => {name => 'Ben'},
        data  => 1,
    );

    $orm->insert(users => {name => 'Cy'});    # void: nothing read back

    # an arrayref of rows, or with count => 1, how many went in
    my $rows = $orm->insert_many(users => [{name => 'Di'}, {name => 'Ed'}]);
    my $n    = $orm->insert_many(
        users => [{name => 'Flo'}],
        count => 1,
    );

    $orm->update_row(users => $ann, {name => 'Anne'});    # updates the row object given

    my $fresh = $orm->update_row(
        users => $ben,
        {email => 'ben@example.com'},
        cas => ['email'],
    );

    my $again = $orm->refresh_row(users => {id => $ben->{id}});    # a row object, from the cache
    my $gone  = $orm->delete_row(users => $fresh);                 # 1

    # rows have the same operations as methods
    $ann->update({email => 'ann@example.com'});    # $orm->update_row(users => $ann, {...})
    $ann->refresh;                                 # $orm->refresh_row(users => $ann, cache => 0)
    $ann->delete;                                  # $orm->delete_row(users => $ann)

The CRUD operations work on row data: plain hashrefs where a missing key means
the field was not fetched and an undef value means NULL. Wherever row data is
expected, a row object works too, and its C<row_data> is used.

A row object given to C<update_row> or C<refresh_row> must also have
C<set_row_data>, which takes the new row data. One without it, or an aggregate
row, croaks before anything is sent.

Each CRUD operation croaks on an argument it does not know.

The CRUD operations that return rows (C<insert>, C<insert_many>,
C<update_row>, and C<refresh_row>) share one rule:

=over 4

=item *

In void context they do the work and return nothing.

=item *

Given a row object, C<update_row> and C<refresh_row> return that same object,
now holding the new row data (it takes the new data in void context too).

=item *

C<< data => 1 >> returns the row data instead of a row. A given row object
still takes the new data. A handle's C<data_only> does the same for the
rows it returns.

=item *

Otherwise they return a new row object. The class is the table's
C<row_class> in the map when set (even to undef), else the ORM's
C<row_class>. When that class is undef (as with C<< row_class => undef >>
to C<new>), they return the row data.

=item *

C<insert_many> returns an arrayref of these, never a list.

=item *

When no row matched, C<update_row> and C<refresh_row> return undef. A row
object given keeps its row data, but a C<refresh_row> that finds no row marks
it deleted (see C<was_deleted> in L<DBIx::QuickORM::Role::Row>).

=back

For row class authors: the object is built with
C<< $class->new(row_data => \%data, orm => $orm, table => $table) >>, or
blessed from those directly when the class's C<fast_bless> is true.

Writes replace the canonical copy for that primary key. A read keeps the
canonical copy when every fetched value matches it, adding any new fields.
Otherwise the read replaces it.

A row written through C<RETURNING> comes back with the table's default
fields. Without C<RETURNING> (MySQL always, MariaDB for updates) it holds only
the primary key.

Values sent are never copied into the returned row data (except with
C<insert>'s C<as_given>): defaults, triggers, and generated columns can change
them.

Every CRUD operation takes C<raw>. Without it, every value sent (inserted
values, changes, compare-and-swap values, and primary key values) is deflated,
turned from a Perl value into database form, by its field's type:

=over 4

=item *

A reference on a typed field is deflated.

=item *

A reference on a field without a type croaks.

=item *

A plain value on a typed field is deflated when the type's C<is_inflated> says
it is inflated. A plain value can be ambiguous (is C<123> JSON, or already
encoded?). Wrap it in C<raw()> or C<inflated()> to say which.

=item *

Anything else is sent as given.

=back

C<< raw => 1 >> says every value is already in database form and skips
deflation. It is also how to send a reference to a field without a type (a
PostgreSQL array, say).

C<raw> covers only the values you gave. Values the ORM generates, such as a
primary key from its type, are deflated as above whatever C<raw> says.

To mark one value instead of all, wrap it in a marker from
L<DBIx::QuickORM::Value>. A marker overrides both the default and C<raw>:

    use DBIx::QuickORM::Value qw/raw inflated sql/;

    my $dee = $orm->insert(
        users => {
            name    => 'Dee',
            prefs   => raw('{"theme":"dark"}'),    # already JSON text: sent as is
            created => sql('now()'),               # literal SQL
        },
    );

    # raw => 1 for every value, but deflate this one
    my $eli = $orm->insert(
        users => {
            name  => 'Eli',
            prefs => inflated({theme => 'light'}),
        },
        raw => 1,
    );

C<raw()> sends one value as given, and C<inflated()> deflates one even under
C<< raw => 1 >>. C<binary()> binds bytes, and C<sql()> is literal SQL.
L<DBIx::QuickORM::Manual::Values> covers each marker, deflation, and
inflation on read.

The single-row CRUD operations reuse prepared statements (DBI's
C<prepare_cached>). Behind a pooler in transaction mode, such as PgBouncer,
turn off server-side prepares (DBD::Pg's C<pg_server_prepare>).

=over 4

=item $row = $orm->insert($table => \%fields, raw => $bool)

=item \%data = $orm->insert($table => \%fields, data => 1, raw => $bool)

=item $row = $orm->insert($table => \%fields, as_given => 1, raw => $bool)

Inserts one row and returns it. At least one field is required.

The new primary key comes from C<RETURNING>, from the given values, or from
the database's last insert id for a single-field key.

A typed primary key field left out can get its value from its type (a version
7 UUID for a UUID field). The ORM skips this when the database fills the
column and can return it with C<RETURNING>. On MySQL it always generates. The
field's C<generate> hint changes this (see
L<DBIx::QuickORM::Role::Type/Field hints>).

A field passed as undef is sent as NULL and is not generated.

Generated values are sent like your own, and C<as_given> includes them.
C<insert_many> generates them the same way for each row.

In void context it only inserts. It sends no C<RETURNING>, caches no canonical
copy, builds no row, and skips the checks below.

Without C<RETURNING> (MySQL), unless in void context:

=over 4

=item *

A table without a primary key croaks.

=item *

A compound key not given in full croaks before anything is sent.

=item *

A single-field key not given (or given as C<sql()>) is read from the last
insert id after the insert. When the database generated none (a key that is
not auto-increment gives 0), the insert croaks with the row already in the
table.

=back

C<< as_given => 1 >> returns a copy of the fields as sent, in database form,
plus the new primary key, instead of reading the row back. Fields sent as
C<sql()> are left out.

The copy is not canonical, so C<update> and C<delete> on it croak while
C<enforce_canon> is on. Refresh it first. A row object fetches a field the
copy lacks when it is read.

On a table without a primary key it returns the copy even without
C<RETURNING>, but nothing can be written or fetched through it.

=back

=cut

sub insert { my $self = shift; $self->_primitive(insert => [], @_) }

=pod

=over 4

=item \@rows = $orm->insert_many($table => \@rows, raw => $bool)

=item \@data = $orm->insert_many($table => \@rows, data => 1, raw => $bool)

=item $count = $orm->insert_many($table => \@rows, count => 1, raw => $bool)

Inserts many rows and returns an arrayref of the new rows. Every row must
have the same fields, at least one.

On a table with a primary key, the new rows become canonical. Copies already
in the row cache stay.

C<< count => 1 >> returns how many rows were inserted instead. It works on
every database, never reads rows back, and cannot be combined with
C<< data => 1 >>.

In void context it only inserts: nothing is read back or made canonical.

An empty C<\@rows> sends nothing and returns an empty arrayref (0 with
C<count>).

The rows go in multi-row C<INSERT> statements, each holding as many rows as
the database's bind limit allows. When it takes more than one statement, they
run in one transaction, so either every row is inserted or none is.

Inside an open transaction it always takes a savepoint, even for one
statement: a failure rolls back only these rows and leaves the open
transaction usable. On DuckDB, which has no savepoints, the open transaction
is used as it is.

The returned rows come in the order the database gives them, with the table's
default fields.

Without C<RETURNING> (MySQL) each row holds only its primary key, so every
row must carry its whole primary key. A row without it, or a table without a
primary key, croaks before anything is sent. Use C<count> or void context.

=back

=cut

sub insert_many { my $self = shift; $self->_primitive(insert_many => [], @_) }

=pod

=over 4

=item $row = $orm->update_row($table, $row_or_data, \%changes, %opts)

=item \%data = $orm->update_row($table, $row_or_data, \%changes, data => 1, %opts)

Updates the row with the row data's primary key and returns it, or undef when
no row matched. At least one change is required. A row object given follows
the rule in L</"CRUD operations">.

Options:

=over 4

=item enforce_canon => $bool

When true, croaks unless the row data is canonical (see C<is_canon>). Undef or
absent means true inside a transaction, otherwise the ORM's C<enforce_canon>.

0 skips that check, but C<cas> and C<auto_cas> still apply. It also skips the
row state checks: a row not in the database (vivified, or deleted) is still
updated by its key, where the row's own C<update> croaks. Not recommended.

=item cas => \@fields

Compare-and-swap: update only while these fields still hold the row data's
values (undef matches NULL). Otherwise return undef and change nothing. Each
field must be in the row data, or it croaks.

It compares with C<=>, so it does not suit floats, PostgreSQL C<json>, or
MySQL C<JSON>.

=item auto_cas => $bool

Compare-and-swap on every field present in both the row data and the changes.

=back

=back

=cut

sub update_row { my $self = shift; $self->_primitive(update_row => [], @_) }

=pod

=over 4

=item $count = $orm->delete_row($table, $row_or_data, enforce_canon => $bool, raw => $bool)

Deletes the row with the row data's primary key and returns how many rows were
deleted (0 or 1). The ORM stops holding it and marks the row data deleted (see
C<was_deleted> in L<DBIx::QuickORM::Role::Row>).

A delete that matches no row also marks it deleted (it is not in the
database) and returns 0.

C<enforce_canon> is as for C<update_row>, including what 0 bypasses.

=back

=cut

sub delete_row {
    my $self = shift;
    return $self->connection->delete_row(@_);
}

=pod

=over 4

=item $row = $orm->refresh_row($table, $row_or_data, cache => $bool, db => $bool, fields => \@fields, raw => $bool)

=item \%data = $orm->refresh_row($table, $row_or_data, data => 1, %opts)

The canonical row for a primary key, or undef when there is none. It takes row
data, a row, or a primary key in any form (a value, an arrayref, or a
hashref).

A row object given follows the rule in L</"CRUD operations">.

It reads C<fields> plus the primary key, or the table's default fields.

By default it returns the canonical copy when that has every field asked for,
and reads the database otherwise. C<< cache => 0 >> always reads the database.
C<< db => 0 >> only looks in the cache, returning the canonical copy as it is,
or undef. Both 0 croaks.

=back

=cut

sub refresh_row { my $self = shift; $self->_primitive(refresh_row => [], @_) }

=head2 Finding by primary key

    my $user = $orm->find(users => $id);
    my $data = $orm->find(users => $id, data => 1);    # row data
    my $none = $orm->find(users => -1);                # undef

Reads one row by primary key, like C<refresh_row>. It never writes to the
database.

=over 4

=item $row = $orm->find($table, $pk, %opts)

=item \%data = $orm->find($table, $pk, data => 1, %opts)

The row with primary key C<$pk>, or undef. C<$pk> takes any key form (see
C<find> in L<DBIx::QuickORM::Handle>). The options are C<refresh_row>'s.

A row object passed in gives its key. It may also show the state the read
found, such as new values or that the row is gone.

=back

=cut

sub find { my $self = shift; $self->_find([], @_) }

=head2 Finding or inserting

    my $gil = $orm->find_or_insert(
        users => {
            name  => 'Gil',
            email => 'gil@example.com',
        },
        by => ['email'],
    );
    my $same = $orm->find_or_insert(
        users => {email => 'gil@example.com'},
        by    => ['email'],
    );

=over 4

=item $row = $orm->find_or_insert($table => \%fields, by => \@fields, raw => $bool)

=item \%data = $orm->find_or_insert($table => \%fields, data => 1, %opts)

Returns the row whose C<by> fields hold the given values, inserting it from
C<\%fields> when there is none. It follows the CRUD operations' return rule.

C<by> defaults to the primary key. A table without one needs C<by>. Every
C<by> field must be in C<\%fields>. Croaks when more than one row matches, or
for a field the table does not have, whether or not the row exists.

An undef C<by> value croaks: NULL does not identify a row, since a unique key
allows many.

The insert runs in a savepoint, or in a transaction when none is open, so a
failed insert leaves an open transaction usable. When the insert fails (say
another process inserted the row first), it looks the row up again and returns
it. If it still finds none, it rethrows the insert's error.

This recovery needs a unique key on the C<by> fields. Without one, two
racing calls can both insert.

Recovery works at the default C<'read committed'>. Inside a transaction at
C<'repeatable read'> or C<'serializable'> (when chosen, or the MySQL family's
server default under C<'server'>), the second lookup reads the transaction's
snapshot. A row another session committed after this transaction started
stays invisible, so the insert's error is rethrown.

C<< raw => 1 >> also covers the C<by> values used to look the row up. They
must then be in exact database form, or the lookup misses and the insert fails
on a duplicate key.

On DuckDB, which has no savepoints, an insert inside an open transaction runs
without one, and a failed insert leaves that transaction unusable.

A table handle has it too: C<< $h->find_or_insert(\%fields, %opts) >> (see
L<DBIx::QuickORM::Handle>).

=back

=cut

sub find_or_insert { my $self = shift; $self->_find_or_insert([caller], [], @_) }

=head2 Rows not in the database

A row can exist in memory before it is inserted. Change it with C<modify>,
then write it with its C<insert>.

=over 4

=item $row = $orm->vivify($table => \%fields)

A new row that is not in the database yet. Nothing is written until you call
its C<insert>. Until then, C<modify> changes it (see
L<DBIx::QuickORM::Role::Row>).

The fields are checked and deflated as C<insert> does, into a new hashref. An
empty hashref is fine. Fill it in with C<modify>. The row is built as the
CRUD operations build rows, so with no row class it is the row data.

=back

=cut

sub vivify {
    my $self = shift;
    my ($table, $fields) = @_;
    croak "vivify() needs a table and a hashref of fields" unless defined($table) && ref($fields) eq 'HASH';

    my $data = $self->connection->deflate($table, $fields);
    DBIx::QuickORM::LookupTable->mark_vivified($data);
    return $self->_row($table, $data);
}

=head2 Following foreign keys

    my $post = $orm->insert(
        posts => {
            user_id => $id,
            title   => 'Hi',
        },
    );

    my $author = $orm->follow_fk(posts => $post, 'users')->only;
    my @posts  = $orm->follow_fk(users => $author, 'posts')->order_by('id')->all;

    # the same, as a row method: no table needed
    my $writer = $post->follow_fk('users')->only;

=over 4

=item $h = $orm->follow_fk($table, $row_or_data, $other_table, link => \%link)

=item $h = $orm->follow_fk($table, $row_or_data, $other_table, via => \%via)

A table handle (L<DBIx::QuickORM::Handle>) on C<$other_table> for the rows
linked to this row by a foreign key: the row it points to, or the rows that
point to it.

The handle's C<where> holds the linked fields' values from the row, qualified
as C<other_table.field>, so the handle can be joined to other tables. Narrow
the handle with C<and>, since C<where> would replace the link.

C<link> is C<< {our_field => their_field, ...} >>, as foreign keys are written
in the map, and gives the direction. On a self-referencing C<employees> table,
C<< {manager_id => 'id'} >> follows to an employee's manager and
C<< {id => 'manager_id'} >> to their reports. It must match a foreign key of
C<$table> to C<$other_table>, or one of C<$other_table> to C<$table> reversed.
Without it there must be exactly one such key.

C<via> takes the same mapping for a key the map does not know, such as one
the database never declared: C<< via => {editor_id => 'id'} >>. No foreign key
need exist, but both tables must be in the map and every field it names must
exist. To declare the key for every call instead, give C<fks> to C<new>.

Croaks on a link that matches no key, on more than one key without a C<link>,
on a key to a table not in the map, on a C<via> field that does not exist, and
when given both C<link> and C<via>.

The handle expects one row (C<single>, see L<DBIx::QuickORM::Iterator>) when
the fields it looks up are the other table's primary key or a unique key.
Otherwise it expects many (C<multi>), whatever the data.

Linked fields missing from the row data are fetched first, with one
C<refresh_row>. It croaks if the row is gone. A NULL linked value refers to
nothing, so the handle matches no rows.

=back

=cut

sub follow_fk { my $self = shift; $self->_follow_fk([caller], @_) }

=head2 Inserting linked rows

    my $post = $orm->insert_fk(users => $alice, 'posts', {title => 'One'});
    my $posts = $orm->insert_many_fk(users => $alice, 'posts', {title => 'A'}, {title => 'B'});

    # the same, as row methods
    my $draft = $alice->insert_fk('posts', {title => 'Draft'});

Inserts rows into C<$other_table> that point at this row, filling their
foreign key fields from it. Only that direction: a key of C<$table> to
C<$other_table> cannot be followed this way, since the new row would have to
be written back into this one.

=over 4

=item $row = $orm->insert_fk($table, $row_or_data, $other_table, %opts, \%fields)

=item \@rows = $orm->insert_many_fk($table, $row_or_data, $other_table, %opts, @fields)

C<insert_fk> inserts exactly one row and returns it, as C<insert> does.
C<insert_many_fk> inserts any number, as C<insert_many> does: an arrayref of
rows, the count with C<< count => 1 >>, nothing in void context.

After C<$other_table>, a string is an option name taking the next argument as
its value, and every other hashref is a row's fields:

    $alice->insert_fk('posts', link => {id => 'user_id'}, {title => 'Linked'});

C<link> chooses the key when more than one of C<$other_table> points at
C<$table>, written C<< {our_field => their_field} >> as C<follow_fk> takes it.
C<via> gives a mapping with no key behind it, as for C<follow_fk>. The new
rows' right-hand fields are filled from this row's left-hand fields.
The other options are those of C<insert> (C<raw>, C<data>, C<as_given>) or
C<insert_many> (C<raw>, C<data>, C<count>).

Croaks, before anything is inserted, when the fields set a link field, when
the row's linked value is NULL, when the row is not in the database, and on a
C<link> that points from C<$table>. A linked field missing from the row data
is fetched first, with one C<refresh_row>. The linked values are sent as they
are in the row data, so a hashref must hold them in database form, as row
data does.

=back

=cut

sub insert_fk      { my $self = shift; $self->_insert_fk([caller], insert      => @_) }
sub insert_many_fk { my $self = shift; $self->_insert_fk([caller], insert_many => @_) }

=head2 Handles

    my @bobs = $orm->handle('users')
        ->where({name => 'Bob'})
        ->order_by('id')
        ->all;
    my @rows = $orm->handle(\['SELECT id, name FROM users WHERE id > ?', 10])->all;

=over 4

=item $h = $orm->handle($table)

=item $h = $orm->handle(\$sql)

=item $h = $orm->handle(\[$sql, @binds])

=item $h = $orm->handle($source)

A L<DBIx::QuickORM::Handle> over a table, an SQL query, or a source object
(L<DBIx::QuickORM::Role::Source>).

An SQL query runs as written, and its binds are not deflated. Its rows belong
to no table: they are never canonical and cannot be written through the ORM.

=back

=cut

sub handle {
    my $self = shift;
    my ($what) = @_;

    my $type = ref($what);
    my $source =
          blessed($what) && $what->DOES('DBIx::QuickORM::Role::Source') ? $what
        : $type eq 'SCALAR'                        ? DBIx::QuickORM::Source::Query->new(sql => $$what)
        : $type eq 'REF' && ref($$what) eq 'ARRAY' ? DBIx::QuickORM::Source::Query->new(sql => $$what->[0], binds => [@{$$what}[1 .. $#$$what]])
        : $type || !defined($what)                 ? croak "handle() takes a table name, \\\$sql, \\[\$sql, \@binds], or a source"
        : $self->db_map->table($what)              ? $self->_table_source($what)
        :                                            croak "The table '$what' is not in the database map";

    return DBIx::QuickORM::Handle->new(orm => $self, source => $source);
}

=head2 Transactions

L<DBIx::QuickORM::Txn> shows the block and object forms. Nesting gives
savepoints. C<isolation> sets the level and C<retry> replays a block:

    $orm->txn(sub {
        $orm->insert(users => {name => 'Outer'});
        eval {
            $orm->txn(sub {
                $orm->insert(users => {name => 'Inner'});
                die "undo only the inner work\n";
            });
        };
    });    # Outer is committed, Inner was rolled back with its savepoint

    my $count = $orm->txn(
        sub { $orm->handle('users')->count },    # the block's return value
        isolation => 'serializable',
        retry     => 3,
    );

=over 4

=item $txn = $orm->txn

=item $txn = $orm->txn(isolation => $level)

=item @result = $orm->txn(sub { my $txn = shift; ... })

=item @result = $orm->txn(sub { ... }, retry => $n, isolation => $level)

Opens a transaction, or a savepoint inside the open one, as a
L<DBIx::QuickORM::Txn>. Given a block, runs it with the transaction and
returns what the block returns.

Without a block, commit or roll back through the returned object. Only the
innermost open transaction can be committed or rolled back. One that goes out
of scope unfinished is rolled back with a warning.

With a block, a normal return commits, unless the block already committed or
rolled back the transaction. An exception rolls back and is rethrown.

C<< retry => $n >> runs the block of an outermost transaction again, up to
C<$n> more times, while the exception is a database error whose C<retriable>
is true (a deadlock, a serialization failure, or a lock timeout). See
L<DBIx::QuickORM::Exception::DB>. The block must be safe to run again.
C<retry> croaks without a block, and on a nested transaction, which cannot be
replayed alone.

An outermost transaction opens at the ORM's C<isolation>, or C<'read
committed'> by default. It states that level when it opens, so a changed
server or session default cannot alter it.

C<'server'> is the exception: it sends a plain C<BEGIN> and uses the
database's own default.

C<< isolation => $level >> opens an outermost transaction at another level:
C<'read committed'>, C<'repeatable read'>, C<'serializable'>, C<'read
uncommitted'>, or C<'server'>, in any case. Each C<retry> begins at the same
level.

C<isolation> croaks on a nested transaction and for any other value.

The ORM's C<isolation> setting takes the same levels, and C<new> croaks for
any other. It is undef unless given, and is stored in lower case.

SQLite and DuckDB cannot set a level. There the default is C<'server'>, and
any other level croaks when the transaction opens. PostgreSQL runs C<'read
uncommitted'> as C<'read committed'>.
L<DBIx::QuickORM::Manual::Transactions/ISOLATION> has the details.

Savepoints need a database that has them, so nesting croaks on DuckDB.

Inside a transaction, C<update_row> and C<delete_row> check that row data is
canonical by default, whatever C<enforce_canon> says. Canonical copies are
held strongly.

Inside a transaction, rows read before it are not canonical until read again.
A rollback restores the row cache and row state from before. A commit keeps
what the transaction read. After a rollback, refresh a row object you still
hold. See L<DBIx::QuickORM::Manual::Transactions> for the details.

=back

=cut

sub txn {
    my $self = shift;
    return $self->connection->txn(@_, caller => [caller]);
}

=head2 Loading classes

=over 4

=item $bool = DBIx::QuickORM->load_class($what, $class)

=item $bool = DBIx::QuickORM->load_class($what, $class, $missing_ok)

Loads a class from its module file and returns true. Croaks "$what could not
be loaded" with the error when it cannot.

With C<$missing_ok>, a missing module file returns false instead. An error
inside the file still croaks.

=back

=cut

sub load_class {
    my $self = shift;
    my ($what, $class, $missing_ok) = @_;

    (my $file = "$class.pm") =~ s{::}{/}g;
    return 1 if eval { require $file; 1 };
    return 0 if $missing_ok && $@ =~ m/^Can't locate \Q$file\E in \@INC/;
    croak "$what could not be loaded: $@";
}

=pod

=over 4

=item $class = $orm->require_type($type)

=item $class = $orm->require_type($type, $context)

Returns the full class name for a type name (C<JSON>, or C<+My::Type> for a
class outside C<DBIx::QuickORM::Type>), loading it unless it already has
C<deflate>.

Croaks when it cannot be loaded. C<$context>, when given, says in that error
what asked for the type.

=back

=cut

sub require_type {
    my $self = shift;
    my ($type, $context) = @_;

    my $class = $self->_type_class($type);
    return $class if $class->can('deflate');

    $self->load_class(defined($context) ? "'$context' names the type '$type', which" : "The type '$type'", $class);
    return $class;
}

=pod

=over 4

=item $orm->load_row_class($class)

Loads a row class unless it already has a C<new>. Croaks when the name is not
a valid package name or the class cannot be loaded.

=back

=cut

sub load_row_class {
    my $self = shift;
    my ($class) = @_;

    croak "The row class '$class' is not a valid package name" unless $class =~ m/^\w+(?:::\w+)*\z/;
    $self->load_class("The row class '$class'", $class)        unless $class->can('new');
}

=head1 ATTRIBUTES

Read-only accessors. Each returns the constructor argument of the same name,
or its default. C<connector>, C<sql_builder>, and C<where_builders> hold what
C<new> built from it.

=over 4

=item $class = $orm->row_class

The default row class, C<DBIx::QuickORM::Row> unless given. Undef means plain
hashrefs.

=item \%classes = $orm->row_classes

=item $namespace = $orm->row_namespace

=item $code = $orm->row_class_name

=item \%omit = $orm->omit

=item \%fields = $orm->default_fields

=item \%types = $orm->types

=item \%options = $orm->type_options

=item \@types = $orm->autotype

=item \@types = $orm->append_autotype

=item \%fks = $orm->fks

The arguments as given to C<new>, or undef. See C<new> for what each does.
C<db_map> holds the result. C<autotype> is undef unless given, even though a
default list applies.

=item $builder = $orm->sql_builder

The SQL builder that handles use. Default:
L<DBIx::QuickORM::SQLBuilder::SQLAbstract>.

C<new> takes an object composing L<DBIx::QuickORM::Role::SQLBuilder>, or the
name of a class that does. A class is loaded unless it has C<new>, then built
with no arguments. Anything else croaks.

=item \@builders = $orm->where_builders

The where builders that render a handle's C<where>. The first that can build
it wins (see L<DBIx::QuickORM::Role::WhereBuilder>).

Default: L<DBIx::QuickORM::WhereBuilder::RawSQL>,
L<DBIx::QuickORM::WhereBuilder::Simple>, then
L<DBIx::QuickORM::WhereBuilder::SQLAbstract>.

C<new> takes a non-empty arrayref of classes or objects composing the role. A
class is loaded unless it has C<build_where>. Anything else croaks. A handle
can use its own list through its C<where_builders>.

=item $code = $orm->connector

The code reference the ORM calls to open a database handle, built from the
connection argument.

=item \@names = $orm->like_aggregates

Extra aggregate functions whose result keeps the field's type and foreign
keys, like the built-in C<min> and C<max>. Undef unless given.

A computed column C<[$func, $field]> using one of them gets the field's type
and foreign keys (see L<DBIx::QuickORM::Handle/Computed columns>). Names are
matched case-insensitively.

=back

=head1 PRIVATE METHODS

=over 4

=item $out = $orm->_primitive($method, \@class, $table, $row_or_data, @args)

Runs the Connection's CRUD operation and returns its result by the rule the
CRUD operations share. In void context it returns nothing. Given a row object
for C<update_row> or C<refresh_row>, it returns that row after C<set_row_data>
(which runs in void context too). With C<< data => 1 >> it returns the row
data. Otherwise it returns a new row built by C<_row> with C<@class>.

An undef result is undef, and the row is left alone. Handles pass their
C<row_class> as C<@class>.

An arrayref result (C<insert_many>) comes back as an arrayref, of rows or of
row data. A plain result (C<insert_many>'s C<count>) comes back as it is.

Croaks before running the CRUD operation when a row object given to
C<update_row> or C<refresh_row> cannot take new data: it has no
C<set_row_data>, or it is an aggregate row.

=back

=cut

my %TAKES_ROW = (update_row => 1, refresh_row => 1);

sub _primitive {
    my $self = shift;
    my ($method, $class, $table, $arg, @args) = @_;

    my @changes = $method eq 'update_row' ? (shift @args) : ();
    my %opts    = @args;
    my $data    = $opts{count} ? undef : delete $opts{data};      # with count, data is left for the Connection to refuse
    my $void    = !defined wantarray;
    $opts{void} = 1 if $void && !$TAKES_ROW{$method};

    my $row = $TAKES_ROW{$method} && blessed($arg) && $arg->can('row_data') ? $arg : undef;
    croak "A row object passed to $method() must take new data with set_row_data; pass its row_data instead"
        if $row && (!$row->can('set_row_data') || $row->isa('DBIx::QuickORM::AggregateRow'));

    my $out = $self->connection->$method($table, $arg, @changes, %opts);
    $row->set_row_data($out) if $row && $out;

    return if $void;
    return $out unless ref $out;

    if (ref($out) eq 'ARRAY') {
        return $out if $data;
        my $build = $self->_row_builder($table, @$class) or return $out;
        return [map { $build->($_) } @$out];
    }

    return $data ? $out : $row || $self->_row($table, $out, @$class);
}

=pod

=over 4

=item $out = $orm->_find_or_insert(\@frame, \@class, $table, \%fields, %opts)

C<find_or_insert>, building the row with C<@class> as C<_row> does and
reporting its errors at C<@frame>. Handles pass their C<row_class> as
C<@class>.

=back

=cut

my %FIND_OR_INSERT_ARGS = map { $_ => 1 } qw/by data raw/;

sub _find_or_insert {
    my $self = shift;
    my ($frame, $class, $table, $fields, %opts) = @_;

    my @unknown = sort grep { !$FIND_OR_INSERT_ARGS{$_} } keys %opts;
    _croak_at($frame, "Unknown argument(s) to find_or_insert(): " . join(', ' => @unknown)) if @unknown;
    _croak_at($frame, "find_or_insert() needs the fields as a hashref") unless ref($fields) eq 'HASH';

    my $by = $opts{by} // $self->db_map->pk($table) // _croak_at($frame, "find_or_insert() needs 'by': the table '$table' has no primary key");
    _croak_at($frame, "'by' must be a non-empty arrayref of field names") unless ref($by) eq 'ARRAY' && @$by;
    my @missing = grep { !exists $fields->{$_} } @$by;
    _croak_at($frame, "find_or_insert() finds by (" . join(', ' => @missing) . "), which the fields do not give") if @missing;

    my $conn = $self->connection;
    $conn->_check_fields($table, sort keys %$fields);
    my $where = $conn->deflate($table, {map { $_ => $fields->{$_} } @$by}, raw => $opts{raw});
    my @undef = grep { !defined $where->{$_} } @$by;
    _croak_at($frame, "find_or_insert() cannot find by an undef value: (" . join(', ' => @undef) . ")") if @undef;

    my $h    = $self->handle($table)->data_only->where($where)->limit(2);
    my $find = sub {
        $h->clear;    # a retry after a failed insert must query again
        my @found = $h->all;
        _croak_at($frame, "find_or_insert() found more than one row in '$table' by (" . join(', ' => @$by) . ")") if @found > 1;
        return $found[0];
    };

    my $data = $find->();
    unless ($data) {
        my $insert = sub { $self->insert($table => $fields, data => 1, raw => $opts{raw}) };
        my $bare   = @{$conn->txns} && !$conn->dialect->supports_savepoints;
        unless (eval { $data = $bare ? $insert->() : $self->txn($insert); 1 }) {
            my $err = $@;
            $data = eval { $find->() } or die $err;
        }
    }

    return unless defined wantarray;
    return $opts{data} ? $data : $self->_row($table, $data, @$class);
}

=pod

=over 4

=item $out = $orm->_find(\@class, $table, $pk, %opts)

C<find>: C<_primitive> running C<refresh_row> on the key, with a row object
given as the key replaced by its row data. Handles pass their C<row_class> as
C<@class>.

=back

=cut

sub _find {
    my $self = shift;
    my ($class, $table, $pk, @args) = @_;
    $pk = $pk->row_data if blessed($pk) && $pk->can('row_data');
    return $self->_primitive(refresh_row => $class, $table, $pk, @args);
}

=pod

=over 4

=item $row = $orm->_row($table, \%data)

=item $row = $orm->_row($table, \%data, $class)

The row data, or a row object over it when the table has a row class. Undef
for undef. A given C<$class> (even undef) replaces the table's. Handles pass
their C<row_class> this way. Built by C<_row_builder>.

=back

=cut

sub _row {
    my $self = shift;
    my ($table, $data, @class) = @_;
    return undef unless $data;

    my $build = $self->_row_builder($table, @class) or return $data;
    return $build->($data);
}

=pod

=over 4

=item $build = $orm->_row_builder($table)

=item $build = $orm->_row_builder($table, $class)

What turns row data into rows of the table, resolved once for a whole result
set: a code reference taking the row data and returning the row object, or
undef when rows are hashrefs (no row class). C<$class> is as for C<_row>.

Every place that builds table rows uses it. When the class's C<fast_bless> is
true the row is blessed directly, otherwise built with C<new>. The ORM asks
each class for C<fast_bless> once and remembers the answer.

=back

=cut

sub _row_builder {
    my $self = shift;
    my ($table, @class) = @_;

    my $class = @class ? $class[0] : $self->_row_class($table);
    return undef unless defined $class;

    my $fast = $self->{+FAST_BLESS}->{$class} //= $class->can('fast_bless') && $class->fast_bless ? 1 : 0;
    return sub { bless({orm => $self, table => $table, row_data => $_[0]}, $class) }
        if $fast;
    return sub { $class->new(row_data => $_[0], orm => $self, table => $table) };
}

=pod

=over 4

=item $class = $orm->_row_class($table)

The table's row class: its C<row_class> in the map when set (even to undef),
otherwise the ORM's, which is also the class for an undef table.

=back

=cut

sub _row_class {
    my $self    = shift;
    my ($table) = @_;
    my $t       = defined($table) ? $self->db_map->table($table) : undef;
    return $t->{row_class} if $t && exists $t->{row_class};
    return $self->{+ROW_CLASS};
}

my $STR      = sub { defined($_[0]) && !ref($_[0]) && length($_[0]) };
my $OPT_STR  = sub { !defined($_[0]) || $STR->($_[0]) };
my $STR_LIST = sub {
    ref($_[0]) eq 'ARRAY' && !grep { !$STR->($_) } @{$_[0]};
};
my $HASH_OF = sub {
    my ($check) = @_;
    return sub {
        ref($_[0]) eq 'HASH' && !grep { !$check->($_) } values %{$_[0]};
    };
};
my $LINK = sub {
    ref($_[0]) eq 'HASH' && %{$_[0]} && !grep { !$STR->($_) } values %{$_[0]};
};

my %SHAPES = (
    row_class      => ['a class name or undef', $OPT_STR],
    row_namespace  => ['a package name',        sub { $STR->($_[0]) && $_[0] =~ m/^\w+(?:::\w+)*\z/ }],
    row_class_name => ['a code reference',      sub { ref($_[0]) eq 'CODE' }],
    retain_cache   => ['a boolean',             sub { !ref($_[0]) }],
    enforce_canon  => ['a boolean',             sub { !ref($_[0]) }],
    time_zone      => ['a time zone name',      $STR],

    like_aggregates => [
        'an arrayref of function names',
        sub {
            ref($_[0]) eq 'ARRAY' && !grep { !$STR->($_) || !m/^\w+\z/ } @{$_[0]};
        }
    ],

    where_builders => [
        'a non-empty arrayref of where builders: classes or objects',
        sub {
            ref($_[0]) eq 'ARRAY' && @{$_[0]} && !grep { !blessed($_) && !($STR->($_) && m/^\w+(?:::\w+)*\z/) } @{$_[0]};
        }
    ],
);

%ARGS = map { $_ => 1 } keys(%SHAPES), qw/datetime_parsers isolation tz dbh connect credentials db_map row_classes omit default_fields types type_options autotype append_autotype fks sql_builder/;

=pod

=over 4

=item $orm->_check_args

Turns C<tz> into C<time_zone>, then croaks naming the first argument in
C<%SHAPES> whose shape is wrong. The Connection checks C<datetime_parsers>.

=back

=cut

sub _check_args {
    my $self = shift;

    if (exists $self->{tz}) {
        croak "Give 'time_zone' or its alias 'tz', not both" if exists $self->{time_zone};
        $self->{time_zone} = delete $self->{tz};
    }

    for my $arg (sort keys %SHAPES) {
        next unless exists $self->{$arg};
        my ($want, $check) = @{$SHAPES{$arg}};
        croak "'$arg' must be $want" unless $check->($self->{$arg});
    }
}

=pod

=over 4

=item _croak_at(\@frame, $message)

Dies with the message at the frame's file and line, worded as C<croak> words
it. C<@frame> is a C<caller> frame that a public method captured, so an error
found deeper, reached through a handle or a row, reports the user's line.

=item _rethrow_at(\@frame, $what, $error)

Rethrows an error caught at a public entry, with the frame's file and line
appended: C<< (from $what at FILE line N) >>. The error keeps its own location,
so a bug report still shows where it was thrown. Exception objects are
rethrown unchanged, and so is a message that already ends at the frame's line.

Use it where one public call reaches many errors in other modules, such as
C<new>. C<_croak_at> suits a chain with a few known errors.

=back

=cut

sub _croak_at {
    my ($frame, $msg) = @_;
    die "$msg at $frame->[1] line $frame->[2].\n";
}

sub _rethrow_at {
    my ($frame, $what, $err) = @_;

    die $err if ref $err;

    my $at = " at $frame->[1] line $frame->[2].\n";
    die $err if substr($err, -length($at)) eq $at;

    chomp($err);
    die "$err\n    (from $what at $frame->[1] line $frame->[2])\n";
}

=pod

=over 4

=item $h = $orm->_follow_fk(\@frame, $table, $row_or_data, $other_table, %params)

C<follow_fk>, reporting its errors at C<@frame>: the C<caller> frame of the
public C<follow_fk> (the ORM's or a row's).

=back

=cut

my %FOLLOW_ARGS = (link => 1, via => 1);

sub _follow_fk {
    my $self = shift;
    my ($frame, $table, $data, $other, %params) = @_;

    my @unknown = sort grep { !$FOLLOW_ARGS{$_} } keys %params;
    _croak_at($frame, "Unknown argument(s) to follow_fk(): " . join(', ' => @unknown)) if @unknown;

    my $conn = $self->connection;
    my $map  = $conn->db_map;
    _croak_at($frame, "The table '$table' is not in the database map") unless defined($table) && $map->table($table);
    _croak_at($frame, "follow_fk() needs the table to follow to")      unless defined($other) && length($other);

    my $link = $self->_link_for($frame, $map, $table, $other, \%params);
    $data = $data->row_data if blessed($data) && $data->can('row_data');
    _croak_at($frame, "follow_fk() needs row data (a hashref) or a row object") unless ref($data) eq 'HASH';
    if (my @missing = grep { !exists $data->{$_} } sort keys %$link) {
        $data = $conn->refresh_row($table, $data, fields => \@missing) or _croak_at($frame, "Cannot follow the foreign key: the row is no longer in the table '$table'");
    }

    return $self->_fk_handle($other, {map { ($link->{$_} => $data->{$_}) } keys %$link});
}

=pod

=over 4

=item $out = $orm->_insert_fk(\@frame, $method, $table, $row_or_data, $other_table, @args)

C<insert_fk> (C<$method> C<insert>) or C<insert_many_fk> (C<insert_many>),
reporting its errors at C<@frame>: the C<caller> frame of the public method
(the ORM's or a row's).

=back

=cut

my %INSERT_FK_ARGS = (
    insert      => {map { $_ => 1 } qw/link via raw data as_given/},
    insert_many => {map { $_ => 1 } qw/link via raw data count/},
);

sub _insert_fk {
    my $self = shift;
    my ($frame, $method, $table, $data, $other, @args) = @_;
    my $name = "${method}_fk";

    my (%opts, @rows);
    while (@args) {
        my $arg = shift @args;
        if (ref($arg) eq 'HASH') { push @rows => $arg; next }
        _croak_at($frame, "$name() takes option => value pairs and hashrefs of fields, not " . ($arg // 'undef')) if ref($arg) || !defined($arg);
        _croak_at($frame, "Unknown argument to $name(): $arg")         unless $INSERT_FK_ARGS{$method}->{$arg};
        _croak_at($frame, "The option '$arg' to $name() has no value") unless @args;
        $opts{$arg} = shift @args;
    }
    _croak_at($frame, "insert_fk() inserts one row; use insert_many_fk() for more") if $method eq 'insert' && @rows != 1;

    my $conn = $self->connection;
    my $map  = $conn->db_map;
    _croak_at($frame, "The table '$table' is not in the database map") unless defined($table) && $map->table($table);
    _croak_at($frame, "$name() needs the table to insert into")        unless defined($other) && length($other);
    my $link = $self->_link_for($frame, $map, $table, $other, {map { ($_ => delete $opts{$_}) } grep { exists $opts{$_} } qw/link via/}, $name);

    $data = $data->row_data if blessed($data) && $data->can('row_data');
    _croak_at($frame, "$name() needs row data (a hashref) or a row object") unless ref($data) eq 'HASH';
    _croak_at($frame, "Cannot insert rows linked to a '$table' row that is not in the database") if DBIx::QuickORM::LookupTable->row_state($data);
    if (my @missing = grep { !exists $data->{$_} } sort keys %$link) {
        $data = $conn->refresh_row($table, $data, fields => \@missing) or _croak_at($frame, "Cannot insert linked rows: the row is no longer in the table '$table'");
    }
    my %values = map { ($link->{$_} => $data->{$_}) } keys %$link;
    if (my @null = sort grep { !defined $values{$_} } keys %values) {
        _croak_at($frame, "Cannot insert rows linked to a '$table' row whose linked value is NULL (" . join(', ' => @null) . ")");
    }
    for my $row (@rows) {
        my @set = sort grep { exists $row->{$_} } keys %values;
        _croak_at($frame, "$name() sets the link field(s) itself; remove " . join(', ' => @set) . " from the row") if @set;
    }

    my %link_values = map { ($_ => raw($values{$_})) } keys %values;    # row data is in database form already
    my @filled      = map { +{%$_, %link_values} } @rows;
    return $self->_primitive($method, [], $other, $method eq 'insert' ? $filled[0] : \@filled, %opts);
}

=pod

=over 4

=item \%link = $orm->_link_for(\@frame, $map, $table, $other, {link => \%link, via => \%via}, $insert_method)

The link a call's C<link> or C<via> option gives: C<_via_link> for C<via>,
otherwise C<_fk_link> with C<link> (undef when absent) and C<$insert_method>.
Croaks when both are given.

=item \%link = $orm->_via_link(\@frame, $map, $table, $other, \%via)

C<%via>, C<< {our_field => their_field} >>, as the link, with no foreign key
behind it. Croaks unless both tables are in the map, C<%via> is a non-empty
hashref, and every field it names is a field of its table.

=back

=cut

sub _link_for {
    my $self = shift;
    my ($frame, $map, $table, $other, $opts, $insert_method) = @_;
    _croak_at($frame, "Give 'link' or 'via', not both")                 if defined($opts->{link}) && defined($opts->{via});
    return $self->_via_link($frame, $map, $table, $other, $opts->{via}) if defined $opts->{via};
    return $self->_fk_link($frame, $map, $table, $other, $opts->{link}, $insert_method);
}

sub _via_link {
    my $self = shift;
    my ($frame, $map, $table, $other, $via) = @_;

    _croak_at($frame, "'via' must be a hashref of field => field") unless ref($via) eq 'HASH' && %$via;
    for my $t ($table, $other) {
        _croak_at($frame, "The table '$t' is not in the database map") unless $map->table($t);
    }
    for my $ours (sort keys %$via) {
        my $theirs = $via->{$ours};
        _croak_at($frame, "'via' names '$ours', which is not a field of '$table'")                        unless $map->field($table, $ours);
        _croak_at($frame, "'via' names '" . ($theirs // 'undef') . "', which is not a field of '$other'") unless defined($theirs) && $map->field($other, $theirs);
    }

    return {%$via};
}

=pod

=over 4

=item \%link = $orm->_fk_link(\@frame, $map, $table, $other, \%given)

=item \%link = $orm->_fk_link(\@frame, $map, $table, $other, \%given, $insert_method)

The link to follow, C<< {our_field => their_field} >>, from the foreign keys of
C<$table> to C<$other> and those of C<$other> to C<$table> turned around: the
one matching C<%given>, or the only one when C<%given> is undef. Croaks
otherwise, and when C<$other> is not in the map, reporting at C<@frame>.

With C<$insert_method> (the calling method's name, for messages), only the
keys of C<$other> to C<$table> count, and a C<%given> matching a key of
C<$table> to C<$other> croaks, naming the direction.

=back

=cut

sub _fk_link {
    my $self = shift;
    my ($frame, $map, $table, $other, $given, $insert_method) = @_;

    my $forward = ($map->table($table)->{fk} // {})->{$other} // [];
    _croak_at($frame, "'$table' has a foreign key to '$other', which is not in the database map") if @$forward && !$map->table($other);
    _croak_at($frame, "The table '$other' is not in the database map") unless $map->table($other);
    my @back  = map { +{reverse %$_} } @{($map->table($other)->{fk} // {})->{$table} // []};
    my @links = $insert_method ? @back : (@$forward, @back);

    my $key = sub {
        my ($l) = @_;
        join "\0" => map { "$_\0$l->{$_}" } sort keys %$l;
    };
    my %found;
    $found{$key->($_)} //= $_ for @links;

    if (defined $given) {
        _croak_at($frame, "'link' must be a hashref of field => field") unless ref($given) eq 'HASH' && %$given;
        if ($insert_method && !$found{$key->($given)} && first { $key->($_) eq $key->($given) } @$forward) {
            _croak_at($frame, "$insert_method() inserts rows that point at the '$table' row; the link (" . join(', ' => map { "$_ => $given->{$_}" } sort keys %$given) . ") points from it");
        }
        return $found{$key->($given)} // _croak_at($frame, "The link (" . join(', ' => map { "$_ => $given->{$_}" } sort keys %$given) . ") matches no foreign key between '$table' and '$other'");
    }

    my @keys = sort keys %found;
    _croak_at($frame, "$insert_method() inserts rows that point at the '$table' row, and '$other' has no foreign key to '$table'") if $insert_method && !@keys;
    _croak_at($frame, "There is no foreign key between '$table' and '$other'") unless @keys;
    _croak_at($frame, "There is more than one foreign key between '$table' and '$other'; choose one with 'link'") if @keys > 1;
    return $found{$keys[0]};
}

=pod

=over 4

=item $source = $orm->_table_source($table)

The table's L<DBIx::QuickORM::Source::Table>, built on first use and then
kept: sources are immutable, so every handle over the table shares it. Croaks
as the source's C<new> does, keeping nothing.

=back

=cut

sub _table_source {
    my $self = shift;
    my ($table) = @_;
    return $self->{+TABLE_SOURCES}->{$table // ''} //= DBIx::QuickORM::Source::Table->new(table => $table, db_map => $self->db_map);
}

=pod

=over 4

=item $h = $orm->_fk_handle($other, {$their_field => $value, ...})

A handle on the rows of C<$other> whose fields hold these values, each field
qualified as C<other.field> in the C<where>. An undef value refers to
nothing: its condition is C<sql('IS NULL AND 1 = 0')>, which is never true.
The handle is C<single> when the fields are exactly the primary key or a
unique key of C<$other>, otherwise C<multi>. Croaks when C<$other> is not in
the map.

=back

=cut

sub _fk_handle {
    my $self = shift;
    my ($other, $values) = @_;

    my $map = $self->db_map;
    my $t   = $map->table($other) or croak "The table '$other' is not in the database map";

    my $theirs = join "\0" => sort keys %$values;
    my $single = grep { join("\0" => sort @$_) eq $theirs } grep { $_ && @$_ } $t->{pk}, @{$t->{unique} // []};

    return DBIx::QuickORM::Handle->new(
        orm    => $self,
        source => $self->_table_source($other),
        where  => {map { ("$other.$_" => $values->{$_} // sql('IS NULL AND 1 = 0')) } keys %$values},
        state  => $single ? 'single' : 'multi',
    );
}

=pod

=over 4

=item $bool = $orm->_can_connect

True unless the ORM was given a C<dbh>: whether the connector can open another
connection.

=item $code = $orm->_build_connector

Turns the one connection argument into the connector, removing it from the
object, and sets C<_can_connect>.

=back

=cut

sub _build_connector {
    my $self = shift;

    my @forms = grep { exists $self->{$_} } qw/dbh connect credentials/;
    croak "new() needs exactly one of 'dbh', 'connect', or 'credentials'" . (@forms ? ", got: " . join(', ' => @forms) : '') unless @forms == 1;

    my ($form) = @forms;
    my $arg = delete $self->{$form};
    $self->{+_CAN_CONNECT} = $form ne 'dbh';

    if ($form eq 'connect') {
        croak "'connect' must be a code reference" unless ref($arg) eq 'CODE';
        return $arg;
    }

    if ($form eq 'dbh') {
        croak "'dbh' must be a DBI database handle" unless blessed($arg) && $arg->isa('DBI::db');
        return sub {
            croak "This ORM was given a 'dbh', so it cannot open another database connection" unless $arg;
            my $dbh = $arg;
            undef $arg;
            return $dbh;
        };
    }

    croak "'credentials' must be a hashref with a 'dsn'" unless ref($arg) eq 'HASH' && $STR->($arg->{dsn});
    my @unknown = sort grep { !m/^(?:dsn|user|pass|attrs)$/ } keys %$arg;
    croak "Unknown key(s) in 'credentials': " . join(', ' => @unknown) if @unknown;
    croak "'attrs' in 'credentials' must be a hashref"                 if defined($arg->{attrs}) && ref($arg->{attrs}) ne 'HASH';

    my ($dsn, $user, $pass) = @{$arg}{qw/dsn user pass/};
    croak "Do not turn AutoCommit off in 'credentials' attrs; the ORM manages transactions"
        if $arg->{attrs} && exists($arg->{attrs}->{AutoCommit}) && !$arg->{attrs}->{AutoCommit};

    my $attrs = {%{$arg->{attrs} // {}}, RaiseError => 1, AutoCommit => 1};
    return sub { DBI->connect($dsn, $user, $pass, $attrs) };
}

=pod

=over 4

=item $builder = $orm->_build_sql_builder

The C<sql_builder> argument as an object, the default when none was given.

=back

=cut

sub _build_sql_builder {
    my $self = shift;

    my $role    = 'DBIx::QuickORM::Role::SQLBuilder';
    my $builder = $self->{+SQL_BUILDER} // 'DBIx::QuickORM::SQLBuilder::SQLAbstract';

    unless (blessed($builder)) {
        croak "'sql_builder' must be a class name or object"                           unless $STR->($builder) && $builder =~ m/^\w+(?:::\w+)*$/;
        $self->load_class("'sql_builder' names the class '$builder', which", $builder) unless $builder->can('new');
        $builder = $builder->new;
    }

    croak "'sql_builder' must compose $role" unless $builder->DOES($role);
    return $builder;
}

=pod

=over 4

=item \@builders = $orm->_where_builders($what, \@builders)

A copy of the list, each class loaded unless it has C<build_where>. Croaks,
naming C<$what>, for a list of the wrong shape (as C<new> checks it) or a
builder not composing L<DBIx::QuickORM::Role::WhereBuilder>.

=back

=cut

sub _where_builders {
    my $self = shift;
    my ($what, $builders) = @_;

    my ($want, $check) = @{$SHAPES{where_builders}};
    croak "$what must be $want" unless $check->($builders);

    my $role = 'DBIx::QuickORM::Role::WhereBuilder';
    for my $builder (@$builders) {
        $self->load_class("$what names the class '$builder', which", $builder) unless blessed($builder) || $builder->can('build_where');
        croak "$what names '$builder', which does not compose $role"           unless $builder->DOES($role);
    }

    return [@$builders];
}

=pod

=over 4

=item $conn = $orm->_connect(%args)

A new Connection with these arguments and a handle from the connector.

=back

=cut

sub _connect {
    my $self = shift;
    return DBIx::QuickORM::Connection->new(@_, dbh => $self->{+CONNECTOR}->());
}

=pod

=over 4

=item $new = $orm->_connect_like($conn)

A new Connection from the connector with the map and settings of the given
one: for a forked child's reconnect, and for queries run on a second
connection.

=back

=cut

sub _connect_like {
    my $self = shift;
    my ($conn) = @_;
    return $self->_connect(map { $_ => $conn->$_ } qw/db_map retain_cache enforce_canon isolation time_zone datetime_parsers/);
}

my @DEFAULT_AUTOTYPE = qw/UUID JSON DateTime/;

=pod

=over 4

=item $map = $orm->_copy_map($db_map)

A copy of a given map as a L<DBIx::QuickORM::Map>, or undef for undef.

=back

=cut

sub _copy_map {
    my $self = shift;
    my ($given) = @_;
    return undef unless defined $given;

    my $data = blessed($given) && $given->isa('DBIx::QuickORM::Map') ? $given->tables : $given;
    croak "'db_map' must be a DBIx::QuickORM::Map or a hashref of map data" unless ref($data) eq 'HASH';
    return DBIx::QuickORM::Map->new(tables => $data)->clone;
}

=pod

=over 4

=item $orm->_setup_map($map, $given)

Adjusts the Connection's map in place by the arguments, in the order C<new>
lists them, through the methods below. C<$given> is true when the map came
from C<db_map> rather than a scan.

=back

=cut

sub _setup_map {
    my $self = shift;
    my ($map, $given) = @_;

    $self->_autotype($map, $given);
    $self->_apply_types($map);
    $self->_apply_fks($map);
    $self->_apply_default_fields($map);
    $self->_apply_row_classes($map);
    $self->_apply_key_types($map);
    $self->_apply_passthrough($map);
}

=pod

=over 4

=item $orm->_autotype($map, $given)

Sets each field's C<orm_type> from the autotype list, as C<new> describes. A
given map keeps its types, which are only loaded, when C<new> got neither
C<autotype> nor C<append_autotype>.

=back

=cut

sub _autotype {
    my $self = shift;
    my ($map, $given) = @_;

    my $asked  = exists $self->{+AUTOTYPE};
    my $append = exists $self->{+APPEND_AUTOTYPE};
    return $self->_require_map_types($map) if $given && !$asked && !$append;

    croak "'autotype' must be undef or an arrayref of type names" if $asked && defined($self->{+AUTOTYPE}) && !$STR_LIST->($self->{+AUTOTYPE});
    croak "'append_autotype' must be an arrayref of type names" if $append && !$STR_LIST->($self->{+APPEND_AUTOTYPE});

    my @types = (
        (map { $self->_load_type(autotype        => $_) } $asked  ? @{$self->{+AUTOTYPE} // []}  : @DEFAULT_AUTOTYPE),
        (map { $self->_load_type(append_autotype => $_) } $append ? @{$self->{+APPEND_AUTOTYPE}} : ()),
    );

    my $dialect = $self->{+CONNECTION}->dialect;
    for my $table (values %{$map->tables}) {
        for my $name (keys %{$table->{fields}}) {
            my $field = $table->{fields}->{$name};
            delete $field->{orm_type};
            next if ($field->{db_type} // '') =~ m/\[\d*\]\z/;

            my $type = first { $_->[1]->{$field->{type} // ''} || ($_->[2] && $_->[0]->matches($name, $field, $dialect)) } @types;
            $field->{orm_type} = $type->[0] if $type;
        }
    }
}

=pod

=over 4

=item $orm->_apply_types($map)

Applies C<types>, loading each type it names. A named field gets the type in
place of any autotype, or none for undef. Its C<format> and C<generate> hints
become the ones given (none for the plain form).

Then C<type_options> fills each hint a field of that type lacks. C<format> and
C<generate> fall back separately. Each type it names is loaded. A field left
with a hint but no type croaks.

=back

=cut

sub _apply_types {
    my $self = shift;
    my ($map) = @_;

    my %hints = (
        format   => ['a code reference',                     sub { ref($_[0]) eq 'CODE' }],
        generate => ["'none', 'prefer_db', or 'prefer_orm'", sub { defined($_[0]) && $_[0] =~ m/^(?:none|prefer_db|prefer_orm)\z/ }],
    );
    my $hint = sub {
        my ($arg, $name, $value) = @_;
        croak "'$arg' needs $hints{$name}->[0] for '$name'" unless $hints{$name}->[1]->($value);
        return $value;
    };

    my $spec  = sub { $OPT_STR->($_[0]) || ref($_[0]) eq 'HASH' };
    my $types = $self->_table_arg($map, TYPES(), 'a hashref of table => {field => type, undef, or {class => type, format => code, generate => mode}}', $HASH_OF->($spec));
    for my $table (sort keys %$types) {
        my $fields = $types->{$table};
        $self->_check_fields($map, TYPES(), $table, sort keys %$fields);

        for my $name (keys %$fields) {
            my $field = $map->field($table, $name);
            my $given = ref($fields->{$name}) ? $fields->{$name} : {class => $fields->{$name}};
            my @bad   = sort grep { $_ ne 'class' && !$hints{$_} } keys %$given;
            croak "'types' gives the field '$name' of the table '$table' the unknown key(s): " . join(', ' => @bad) if @bad;

            for my $h (sort keys %hints) {
                delete $field->{$h};
                $field->{$h} = $hint->(TYPES(), $h, $given->{$h}) if exists $given->{$h};
            }
            next unless exists $given->{class};
            delete $field->{orm_type};
            $field->{orm_type} = $self->require_type($given->{class}, TYPES()) if defined $given->{class};
        }
    }

    my $options = $self->{+TYPE_OPTIONS} // {};
    croak "'type_options' must be a hashref of type => {format => code, generate => mode}" unless $HASH_OF->(sub { ref($_[0]) eq 'HASH' })->($options);

    my %by_type;
    for my $type (sort keys %$options) {
        my @bad = sort grep { !$hints{$_} } keys %{$options->{$type}};
        croak "'type_options' gives the type '$type' the unknown key(s): " . join(', ' => @bad) if @bad;
        my $class = $self->require_type($type, TYPE_OPTIONS());
        $by_type{$class}{$_} = $hint->(TYPE_OPTIONS(), $_, $options->{$type}->{$_}) for grep { exists $options->{$type}->{$_} } sort keys %hints;
    }

    for my $table (sort keys %{$map->tables}) {
        my $fields = $map->table($table)->{fields};
        for my $name (sort keys %$fields) {
            my $field = $fields->{$name};
            for my $h (sort keys %hints) {
                my $value = $by_type{$field->{orm_type} // ''}{$h};
                $field->{$h} //= $value if defined $value;
                next unless defined($field->{$h}) && !$field->{orm_type};
                croak "The field '$name' of the table '$table' has a $h but no type; a $h applies only to a typed field";
            }
        }
    }
}

=pod

=over 4

=item $orm->_apply_fks($map)

Applies C<fks>: adds each link to the table's foreign keys, through C<_add_fk>.

=back

=cut

sub _apply_fks {
    my $self = shift;
    my ($map) = @_;

    my $links = sub {
        ref($_[0]) eq 'ARRAY' && !grep { !$LINK->($_) } @{$_[0]};
    };
    my $fks = $self->_table_arg($map, FKS(), 'a hashref of table => {table => [{field => field}]}', $HASH_OF->($links));

    for my $table (sort keys %$fks) {
        for my $other (sort keys %{$fks->{$table}}) {
            croak "'fks' names the table '$other', which is not in the database map" unless $map->table($other);

            for my $link (@{$fks->{$table}->{$other}}) {
                $self->_check_fields($map, FKS(), $table, sort keys %$link);
                $self->_check_fields($map, FKS(), $other, sort values %$link);
                $self->_add_fk($map, $table, $other, $link);
            }
        }
    }
}

=pod

=over 4

=item $orm->_apply_default_fields($map)

Applies C<omit> and C<default_fields>, setting each named table's default
fields, with the croaks C<new> lists.

=back

=cut

sub _apply_default_fields {
    my $self = shift;
    my ($map) = @_;

    my $omit   = $self->_table_arg($map, OMIT(),           'a hashref of table => [fields]', $STR_LIST);
    my $fields = $self->_table_arg($map, DEFAULT_FIELDS(), 'a hashref of table => [fields]', $STR_LIST);

    my @both = sort grep { exists $fields->{$_} } keys %$omit;
    croak "'omit' and 'default_fields' both name the table(s): " . join(', ' => @both) if @both;

    for my $table (sort keys %$omit) {
        $self->_check_fields($map, OMIT(), $table, @{$omit->{$table}});

        my %omit = map  { $_ => 1 } @{$omit->{$table}};
        my @pk   = grep { $omit{$_} } @{$map->pk($table) // []};
        croak "'omit' names primary key field(s) of the table '$table': " . join(', ' => @pk) if @pk;

        $self->_set_default_fields($map, OMIT(), $table, grep { !$omit{$_} } keys %{$map->table($table)->{fields}});
    }

    for my $table (sort keys %$fields) {
        $self->_check_fields($map, DEFAULT_FIELDS(), $table, @{$fields->{$table}});
        $self->_set_default_fields($map, DEFAULT_FIELDS(), $table, @{$fields->{$table}}, @{$map->pk($table) // []});
    }
}

=pod

=over 4

=item $orm->_apply_row_classes($map)

Applies C<row_classes>, then C<row_namespace> to each table left without a
row class (through C<_namespace_class>, and a class found there must do
L<DBIx::QuickORM::Role::Row>), then loads every row class the map
names and the ORM's C<row_class>, unless the class already has a C<new>.

=back

=cut

sub _apply_row_classes {
    my $self = shift;
    my ($map) = @_;

    my $classes = $self->_table_arg($map, ROW_CLASSES(), 'a hashref of table => class name or undef', $OPT_STR);
    $map->table($_)->{row_class} = $classes->{$_} for keys %$classes;

    if (defined(my $ns = $self->{+ROW_NAMESPACE})) {
        for my $name (grep { !exists $map->table($_)->{row_class} } sort keys %{$map->tables}) {
            my $class = $self->_namespace_class($ns, $name) or next;
            my $what  = "'row_namespace' gives the table '$name' the row class '$class', which";
            next unless $class->can('new') || $self->load_class($what, $class, 1);
            $class->DOES('DBIx::QuickORM::Role::Row') or croak "$what does not do DBIx::QuickORM::Role::Row";
            $map->table($name)->{row_class} = $class;
        }
    }

    $self->load_row_class($_) for grep { defined } $self->{+ROW_CLASS}, map { $_->{row_class} } values %{$map->tables};
}

=pod

=over 4

=item $class = $orm->_namespace_class($namespace, $table)

The table's row class under C<row_namespace>: the namespace and the part
C<row_class_name> gives for the table, or by default each C<_>-separated part
of the name with its first letter upper-cased, joined.

Undef when the part is undef. Warns and returns undef when the part is not an
identifier.

=back

=cut

my $DEFAULT_ROW_CLASS_NAME = sub {
    join '' => map { ucfirst } split /_/ => $_[0];
};

sub _namespace_class {
    my $self = shift;
    my ($ns, $table) = @_;
    my $part = ($self->{+ROW_CLASS_NAME} // $DEFAULT_ROW_CLASS_NAME)->($table);
    return undef unless defined $part;
    return "${ns}::$part" if $part =~ m/^[A-Za-z_]\w*\z/;
    carp "'row_namespace' skips the table '$table': '$part' is not a valid class name part";
    return undef;
}

=pod

=over 4

=item $orm->_apply_key_types($map)

Records each table's C<pk_types> (see L<DBIx::QuickORM::Map>) when a primary
key field has a type. Croaks when such a type has no
C<canonical_key_value>, and when a field whose type can generate values has
C<< generate => 'prefer_orm' >> on a column the database refuses values for.

=back

=cut

sub _apply_key_types {
    my $self = shift;
    my ($map) = @_;

    for my $name (keys %{$map->tables}) {
        my $table = $map->table($name);
        delete $table->{pk_types};
        my @types = map { $table->{fields}->{$_}->{orm_type} } @{$table->{pk} // []};
        next unless grep { defined } @types;

        for my $i (grep { defined $types[$_] } 0 .. $#types) {
            my $field = $table->{pk}->[$i];
            my $rec   = $table->{fields}->{$field};
            croak "The primary key field '$field' of the table '$name' has the type '$types[$i]', which has no canonical_key_value(); pass types => {'$name' => {'$field' => undef}} to key it by its plain value"
                unless $types[$i]->can('canonical_key_value');
            croak "The primary key field '$field' of the table '$name' has generate => 'prefer_orm', but the database refuses values for it (such as GENERATED ALWAYS AS IDENTITY); give it generate => 'prefer_db'"
                if ($rec->{generate} // '') eq 'prefer_orm' && $rec->{db_refuses_value} && $types[$i]->can('generate_key_value');
        }
        $table->{pk_types} = \@types;
    }
}

=pod

=over 4

=item $orm->_apply_passthrough($map)

Sets C<passthrough> on each typed field whose type's C<inflate_is_identity> is
true for that field, and removes it from every other field.

=back

=cut

sub _apply_passthrough {
    my $self = shift;
    my ($map) = @_;

    for my $table (values %{$map->tables}) {
        for my $field (values %{$table->{fields}}) {
            delete $field->{passthrough};
            my $type = $field->{orm_type} or next;
            $field->{passthrough} = 1 if $type->can('inflate_is_identity') && $type->inflate_is_identity($field);
        }
    }
}

=pod

=over 4

=item \%arg = $orm->_table_arg($map, $name, $want, \&check)

The named argument, or an empty hash when it was not given. Croaks unless it
is a hashref whose values pass C<check> (C<$want> describes the shape), or
when it names a table not in the map.

=back

=cut

sub _table_arg {
    my $self = shift;
    my ($map, $arg, $want, $check) = @_;

    return {} unless exists $self->{$arg};

    my $value = $self->{$arg};
    croak "'$arg' must be $want" unless $HASH_OF->($check)->($value);

    for my $table (sort keys %$value) {
        croak "'$arg' names the table '$table', which is not in the database map" unless $map->table($table);
    }

    return $value;
}

=pod

=over 4

=item $orm->_check_fields($map, $name, $table, @fields)

Croaks for the first field not in the table.

=back

=cut

sub _check_fields {
    my $self = shift;
    my ($map, $arg, $table, @fields) = @_;

    for my $field (@fields) {
        croak "'$arg' names the field '$field' of the table '$table', which is not in the database map" unless $map->field($table, $field);
    }
}

=pod

=over 4

=item $class = $orm->_type_class($type)

The full class name for a type name.

=back

=cut

sub _type_class {
    my $self = shift;
    my ($type) = @_;

    my $class = $type =~ m/^\+(.+)$/ ? $1 : "DBIx::QuickORM::Type::$type";
    croak "'$type' is not a valid type name" unless $class =~ m/^\w+(?:::\w+)*$/;

    return $class;
}

=pod

=over 4

=item $orm->_require_map_types($map)

Loads every type a given map names.

=back

=cut

sub _require_map_types {
    my $self = shift;
    my ($map) = @_;

    for my $table (values %{$map->tables}) {
        $self->require_type("+$_->{orm_type}", 'db_map') for grep { defined $_->{orm_type} } values %{$table->{fields}};
    }
}

=pod

=over 4

=item [$class, \%base_types, $has_matches] = $orm->_load_type($arg, $type)

Loads an autotype for C<_autotype>: its class, its C<base_types> as a set, and
whether it has C<matches>. Croaks naming the argument when the type cannot be
loaded, or has neither.

=back

=cut

sub _load_type {
    my $self = shift;
    my ($arg, $type) = @_;

    my $class = $self->require_type($type, $arg);

    my $matches = $class->can('matches') ? 1 : 0;
    croak "'$arg' names the type '$class', which has neither 'base_types' nor 'matches'" unless $matches || $class->can('base_types');

    my %base_types = map { $_ => 1 } $class->can('base_types') ? $class->base_types : ();
    return [$class, \%base_types, $matches];
}

=pod

=over 4

=item $orm->_add_fk($map, $table, $other, \%link)

Adds a foreign key from the table to the other one, unless the table already
has the same link. Croaks when it has a link on the same fields that points at
different fields of the other table.

=back

=cut

sub _add_fk {
    my $self = shift;
    my ($map, $table, $other, $link) = @_;

    my $ours  = join "\0" => sort keys %$link;
    my $known = $map->table($table)->{fk}->{$other} //= [];

    for my $have (@$known) {
        next   unless join("\0" => sort keys %$have) eq $ours;
        return unless grep { $have->{$_} ne $link->{$_} } keys %$link;
        croak "'fks' gives the table '$table' a foreign key to '$other' on (" . join(', ' => sort keys %$link) . ") that differs from the one it has";
    }

    push @$known => {%$link};
}

=pod

=over 4

=item $orm->_set_default_fields($map, $arg, $table, @fields)

Sets the table's default fields to C<@fields>, sorted and without duplicates.
Croaks naming the argument when C<@fields> is empty.

=back

=cut

sub _set_default_fields {
    my $self = shift;
    my ($map, $arg, $table, @fields) = @_;

    my %seen;
    @fields = sort grep { !$seen{$_}++ } @fields;
    croak "'$arg' leaves no fields to select from the table '$table'" unless @fields;

    $map->table($table)->{default_fields} = \@fields;
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
