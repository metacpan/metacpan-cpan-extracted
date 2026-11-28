package DBIx::QuickORM::Manual::DBIC;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::DBIC - Coming from DBIx::Class: the concepts mapped, and the same tasks side by side.

=head1 DESCRIPTION

A mapping of DBIx::Class concepts to equivalent DBIx::QuickORM ones, then
each common task written both ways.

The DBIx::QuickORM examples use C<$orm>, an ORM connected to the database
under L</SCHEMA>. The DBIx::Class examples use C<$schema>, a C<My::Schema>
over its C<users> and C<posts> tables, with the Result classes
L</DEFINING THE SCHEMA> shows.

=head1 SCHEMA

The examples use PostgreSQL and this schema:

=for highlighter language=sql

    CREATE TABLE users (
        id          SERIAL PRIMARY KEY,
        name        TEXT NOT NULL,
        email       TEXT UNIQUE,
        prefs       JSON,
        referred_by INTEGER REFERENCES users (id),
        created     TIMESTAMP NOT NULL DEFAULT now()
    );

    CREATE TABLE posts (
        id      SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users (id),
        title   TEXT NOT NULL,
        views   INTEGER NOT NULL DEFAULT 0
    );

And a log whose C<user_id> has no foreign key constraint:

    CREATE TABLE audit_log (
        id      SERIAL PRIMARY KEY,
        user_id INTEGER,
        action  TEXT NOT NULL
    );

=head1 CONCEPT MAP

=over 4

=item Schema: the ORM object

C<< My::Schema->connect(...) >> becomes C<< DBIx::QuickORM->new(...) >>
(L<DBIx::QuickORM>). It holds the connection and the schema, which it reads
from the database. See L</CONNECTING>.

=item Result class, ResultSource: a scanned table

Tables, columns, primary keys, and foreign keys come from the database. A
table needs a class only to adjust what the scan found or to add row methods
(L<DBIx::QuickORM::DSL>, L<DBIx::QuickORM::Manual::Classes>). See
L</DEFINING THE SCHEMA>.

=item ResultSet: Handle

L<DBIx::QuickORM::Handle>: a query that runs when asked. Every modifier
returns a new handle, and the one it was called on never changes. It has
C<next> and C<reset>, and C<iter> returns an L<DBIx::QuickORM::Iterator> with
its own position. See L</QUERIES>.

=item Result object: Row

L<DBIx::QuickORM::Row>. Fields are read with C<field>. There are no setters and no dirty state:
C<update> writes at once. See L</CREATE, READ, UPDATE, DELETE>.

=item belongs_to, has_many: foreign keys, followed with C<follow_fk>

Relationships are not declared. The database's foreign keys are scanned.
C<< $row->follow_fk($table) >> is a handle on the linked rows. For a key the
database does not declare, C<via> names the fields on one call and C<fks>
declares the key for all (L<DBIx::QuickORM::Manual::ForeignKeys>).
See L</RELATIONSHIPS> and L</DEFINING THE SCHEMA>.

=item create_related: C<insert_fk> and C<insert_many_fk>

C<< $row->insert_fk($table, \%fields) >> inserts a row that points at this
one, filling in its foreign key fields. See L</RELATIONSHIPS>.

=item join, prefetch: C<join> and C<left_join>

Each result is a flat join row (L<DBIx::QuickORM::JoinRow>) holding one row
object per table. Nothing is collapsed into nested structures
(L<DBIx::QuickORM::Manual::Joins>). See L</JOINS AND PREFETCH>.

=item InflateColumn: types

Chosen from each column's declared type. JSON, UUID, date, and timestamp
columns inflate without being declared (C<TIME> does not). A type is a class
that consumes L<DBIx::QuickORM::Role::Type> (L<DBIx::QuickORM::Manual::Types>).
See L</INFLATION>.

=item txn_do, txn_scope_guard: C<txn>

C<txn> with a block, or C<txn> returning an object
(L<DBIx::QuickORM::Txn>) to C<commit> or C<rollback>. A nested C<txn> is always a savepoint
(L<DBIx::QuickORM::Manual::Transactions>). See L</TRANSACTIONS>.

=item deploy: nothing

The database is the only schema. Create tables with your own SQL or
migration tool. See L</DEPLOYING>.

=item Independent result objects: one canonical copy per row

DBIx::Class gives each query a fresh object for the same row, and each
writes the columns it changed. DBIx::QuickORM keeps one canonical copy of each
row's data and rejects a write through a row object whose data it has
superseded (L<DBIx::QuickORM::Manual::Caching>). See L</ONE COPY PER ROW>.

=item get_column, select and as, group_by: C<count> and computed columns

C<< $rs->get_column >> for an aggregate is a computed column in C<fields>,
read from an L<DBIx::QuickORM::AggregateRow>
(L<DBIx::QuickORM::Manual::Aggregates>). C<< $row->get_column >> is
C<raw_field>. See L</COUNTS AND AGGREGATES>.

=item C<\'NOW()'>, C<\['? + 1', 2]>: C<sql>

Literal SQL is C<sql(...)> from L<DBIx::QuickORM::Value>
(L<DBIx::QuickORM::Manual::Values>). See L</LITERAL SQL>.

=item new_result, insert, in_storage: C<vivify>, C<insert>, C<is_in_db>

See L</CREATE, READ, UPDATE, DELETE>.

=item find_or_create: C<find_or_insert>

See L</CREATE, READ, UPDATE, DELETE>.

=item HashRefInflator: C<data_only>

L<DBIx::QuickORM::Manual::RowClasses/HASHREFS>. See L</PLAIN HASHREFS>.

=item populate: C<insert_many>

L<DBIx::QuickORM::Manual::BulkInsert>. See L</BULK WRITES>.

=item discard_changes: C<refresh>

See L</CREATE, READ, UPDATE, DELETE>.

=back

=head1 DEFINING THE SCHEMA

DBIx::Class, in three files (C<load_namespaces> finds Result classes on
disk, but packages in one file register nothing).
F<lib/My/Schema/Result/User.pm>:

=for highlighter language=perl

    package My::Schema::Result::User;
    use base 'DBIx::Class::Core';

    __PACKAGE__->load_components('InflateColumn::DateTime');
    __PACKAGE__->table('users');
    __PACKAGE__->add_columns(
        id => {
            data_type         => 'integer',
            is_auto_increment => 1,
        },
        name  => {data_type => 'text'},
        email => {
            data_type   => 'text',
            is_nullable => 1,
        },
        prefs => {
            data_type   => 'json',
            is_nullable => 1,
        },
        referred_by => {
            data_type   => 'integer',
            is_nullable => 1,
        },
        # read back after create, like the key
        created => {
            data_type          => 'timestamp',
            retrieve_on_insert => 1,
        },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->has_many(posts => 'My::Schema::Result::Post', 'user_id');

    1;

F<lib/My/Schema/Result/Post.pm>:

    package My::Schema::Result::Post;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('posts');
    __PACKAGE__->add_columns(
        id => {
            data_type         => 'integer',
            is_auto_increment => 1,
        },
        user_id => {data_type => 'integer'},
        title   => {data_type => 'text'},
        views   => {
            data_type     => 'integer',
            default_value => 0,
        },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(author => 'My::Schema::Result::User', 'user_id');

    1;

F<lib/My/Schema.pm>:

    package My::Schema;
    use base 'DBIx::Class::Schema';

    __PACKAGE__->load_namespaces;

    1;

DBIx::QuickORM:

    my $orm = DBIx::QuickORM->new(credentials => {
        dsn  => $dsn,
        user => $user,
        pass => $pass,
    });    # scans the tables, columns, keys, and types

    my $alice = $orm->insert(users => {
        name  => 'Alice',
        email => 'alice@example.com',
        prefs => {theme => 'dark'},
    });

    my $post = $orm->insert(posts => {
        user_id => $alice->field('id'),
        title   => 'Hello',
    });

    my $author = $post->follow_fk('users')->only;                 # the foreign key was scanned, not declared
    my $year   = $alice->field('created')->datetime_ref->year;    # a lazy DateTime, from the column's type

Nothing is declared in Perl. To adjust a table or give its rows methods, see
L</ROW METHODS> and L<DBIx::QuickORM::Manual::Classes>.

A foreign key the database does not declare, such as C<audit_log.user_id>,
is followed by naming its fields with C<via>. DBIx::Class declares it as it
declares every relationship, with C<belongs_to> and C<has_many>.

    my $entry = $orm->insert(audit_log => {
        user_id => $alice->field('id'),
        action  => 'login',
    });

    my $by = $entry->follow_fk('users', via => {user_id => 'id'})->only;

To declare it once for every call, give it to C<new> with C<fks>. Then it is
followed like a scanned one.

    my $logged = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        fks => {audit_log => {users => [{user_id => 'id'}]}},    # audit_log.user_id points at users.id
    );

    my $entry = $logged->insert(audit_log => {
        user_id => $alice->field('id'),
        action  => 'login',
    });

    my $who = $entry->follow_fk('users')->only;
    my @log = $logged->find(users => $alice->field('id'))->follow_fk('audit_log')->all;

=head1 CONNECTING

DBIx::Class:

    my $schema = My::Schema->connect($dsn, $user, $pass, {AutoCommit => 1});
    $schema = My::Schema->connect(sub { DBI->connect($dsn, $user, $pass, {RaiseError => 1}) });

DBIx::QuickORM:

    my $orm = DBIx::QuickORM->new(credentials => {
        dsn  => $dsn,
        user => $user,
        pass => $pass,
    });

    # a new handle each call
    $orm = DBIx::QuickORM->new(
        connect => sub { DBI->connect($dsn, $user, $pass, {RaiseError => 1}) },
    );
    $orm = DBIx::QuickORM->new(dbh => $dbh);    # a handle you already have

Every form needs C<RaiseError> and C<AutoCommit> on, and C<credentials>
turns both on itself. With C<dbh> the ORM cannot open a second connection, so
a forked child, C<aside>, and C<forked> croak
(L<DBIx::QuickORM::Manual::Background>).

=head1 CREATE, READ, UPDATE, DELETE

DBIx::Class:

    my $alice = $schema->resultset('User')->create({name => 'Alice'});
    my $found = $schema->resultset('User')->find($alice->id);
    my $bob   = $schema->resultset('User')->search({email => 'bob@example.com'})->single;

    my $name = $alice->name;
    $alice->name('Alice Smith');
    $alice->update;    # or $alice->update({name => 'Alice Smith'})
    $alice->discard_changes;
    $alice->delete;

DBIx::QuickORM:

    my $alice = $orm->insert(users => {name => 'Alice'});
    my $found = $orm->find(users => $alice->field('id'));

    # undef when there is none, and croaks on more than one
    my $bob = $orm->handle('users')->where({email => 'bob@example.com'})->only;

    my $name = $alice->field('name');
    $alice->update({name => 'Alice Smith'});    # written now
    $alice->refresh;
    $alice->delete;

C<single> warns and returns the first row when more than one matches, but
C<only> croaks. C<find> takes the primary key only
(L<DBIx::QuickORM::Manual::Keys>): there is no lookup by another unique
constraint.

C<find_or_create> is C<find_or_insert>, finding by the C<by> fields (the
primary key by default):

    my $carol = $orm->find_or_insert(
        users => {
            name  => 'Carol',
            email => 'carol@example.com',
        },
        by => ['email'],
    );

C<new_result>, C<insert>, and C<in_storage> are C<vivify>, C<insert>, and
C<is_in_db>. A row not yet inserted changes with C<modify>:

    my $draft = $orm->vivify(users => {name => 'Draft'});    # not in the database yet
    $draft->modify({email => 'draft@example.com'});
    $draft->insert;
    my $stored = $draft->is_in_db;    # true

=head1 QUERIES

DBIx::Class:

    my $rs = $schema->resultset('Post')->search(
        {views => {'>' => 5}},
        {
            order_by => {-desc => 'views'},
            rows     => 10,
            offset   => 20,
        },
    );
    my $hellos = $rs->search({title => {-like => 'Hello%'}});    # ANDed onto the condition

    my $count = $rs->count;    # applies rows and offset: at most 10
    my @all   = $rs->all;
    while (my $post = $rs->next) {
        my $title = $post->title;
    }
    my $first = $rs->first;

DBIx::QuickORM:

    my $h = $orm->handle('posts')
        ->where({views => {'>' => 5}})
        ->order_by({-desc => 'views'})
        ->limit(10)
        ->offset(20);

    # and() adds to the condition, but where() replaces it
    my $hellos = $h->and({title => {-like => 'Hello%'}});

    my $count = $h->count;    # ignores limit and offset: every matching row
    my @all = $h->all;    # runs the query and fetches every row
    while (my $post = $h->next) {
        my $title = $post->field('title');
    }
    my $first = $h->first;
    my $it    = $h->iter;    # an independent cursor over the same rows

C<count> ignores C<limit> and C<offset>, so it gives the total DBIx::Class's
C<pager> would. DBIx::Class's C<count> applies C<rows> and C<offset>.

C<< $rs->next >> and C<< $rs->reset >> are C<< $h->next >> and
C<< $h->reset >>. A handle runs its query once, on the first read, and keeps
the rows until C<< $h->clear >>. Every read shares them. For independent
cursors over the same rows, take iterators with C<iter>.

Conditions take L<SQL::Abstract> syntax in both: DBIx::Class through
L<SQL::Abstract::Classic> and its extensions, DBIx::QuickORM through
L<SQL::Abstract> 2.x. The conditions shown work in both.

A C<where> may also be SQL you write: a plain string is used as written, and
C<sql()> adds binds (L<DBIx::QuickORM::Manual::Values/SQL>). C<and> and C<or>
put either in parentheses. Never
interpolate untrusted input into the string.

    use DBIx::QuickORM::Value qw/sql/;

    my $titled = $h->and("title <> ''");
    my $short  = $h->and(sql('length(title) < ?', 8));

A custom ResultSet class becomes a sub that takes a handle and returns a
narrower one. Unlike C<search>, C<and> and C<or> croak on a handle with no
C<where>. Start a condition with C<where>.

    sub popular {
        my ($posts) = @_;
        return $posts->and({views => {'>' => 5}});
    }

    my $n = popular($hellos)->count;

=head1 LITERAL SQL

DBIx::Class:

    my $ida = $schema->resultset('User')->create({name => 'Ida', created => \'NOW()'});
    $schema->resultset('Post')->search({id => $post_id})->update({views => \['views + ?', 2]});

DBIx::QuickORM:

    use DBIx::QuickORM::Value qw/sql/;

    my $ida = $orm->insert(users => {name => 'Ida', created => sql('now()')});
    $orm->handle('posts')->where({id => $post_id})->update({views => sql('views + ?', 2)});

C<sql()> takes the SQL and its binds, as a value or in a C<where>
(L<DBIx::QuickORM::Manual::Values/SQL>).

=head1 PLAIN HASHREFS

DBIx::Class:

    my @data = $schema->resultset('Post')->search(
        undef,
        {result_class => 'DBIx::Class::ResultClass::HashRefInflator'},
    )->all;

DBIx::QuickORM:

    my @data  = $orm->handle('posts')->data_only->all;    # row_class(undef)
    my $title = $data[0]->{title};

For every query of a table, C<< row_classes => {posts => undef} >> when
constructing the ORM. For every table, C<< row_class => undef >>
(L<DBIx::QuickORM::Manual::RowClasses/HASHREFS>).

=head1 RELATIONSHIPS

DBIx::Class:

    my $author = $post->author;     # belongs_to: a Result object
    my @posts  = $author->posts;    # has_many: the rows in list context
    my $rs     = $author->posts;    # a ResultSet in scalar context
    my $busy   = $author->search_related('posts', {views => {'>' => 5}})->count;
    my $new    = $author->create_related('posts', {title => 'New'});

DBIx::QuickORM:

    # single: user_id reaches the users primary key
    my $author = $post->follow_fk('users')->only;
    my @posts  = $author->follow_fk('posts')->all;    # multi: any number of posts
    my $h      = $author->follow_fk('posts');         # a handle
    my $busy   = $h->and({views => {'>' => 5}})->count;
    my $new    = $author->insert_fk('posts', {title => 'New'});    # user_id is filled in

C<insert_many_fk> inserts several, as C<insert_many> does:
C<< $author->insert_many_fk('posts', {title => 'A'}, {title => 'B'}) >>.

The direction comes from the key. Narrow a C<follow_fk> handle with C<and>:
C<where> replaces the whole condition, the key's part included. When two keys
connect the same tables, C<link> picks one
(L<DBIx::QuickORM::Manual::ForeignKeys>).

=head1 JOINS AND PREFETCH

DBIx::Class:

    my @posts = $schema->resultset('Post')->search(
        {'author.name' => 'Alice'},
        {
            prefetch => 'author',
            order_by => 'me.id',
        },
    );
    for my $post (@posts) {
        my $title  = $post->title;
        my $author = $post->author->name;    # prefetched: no second query
    }

DBIx::QuickORM:

    my @pairs = $orm->handle('posts')
        ->join('users')
        ->where({'users.name' => 'Alice'})
        ->order_by('posts.id')
        ->all;

    for my $pair (@pairs) {
        my $title  = $pair->row('posts')->field('title');
        my $author = $pair->row('users')->field('name');
    }

Fields are C<table.field>. The base table goes by its own name, and there is
no C<me>. Results are flat: a user with two posts appears in two join rows,
both holding the same user row object. C<left_join> is the LEFT JOIN
(L<DBIx::QuickORM::Manual::Joins>).

=head1 INFLATION

DBIx::Class:

    __PACKAGE__->load_components('InflateColumn::DateTime');
    __PACKAGE__->add_columns(created => {data_type => 'timestamp'});

    my $year = $alice->created->year;

DBIx::QuickORM:

    my $year  = $alice->field('created')->datetime_ref->year;    # a lazy DateTime
    my $theme = $alice->field('prefs')->{theme};                 # JSON as Perl data
    my $text  = $alice->raw_field('created');                    # as the database returned it

    my $plain = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        types => {users => {prefs => undef}},    # prefs stays text
    );

Types are chosen when the ORM is built, from each column's declared type.
C<types> adjusts them. L<DBIx::QuickORM::Manual::Types> is how to write one.

=head1 TRANSACTIONS

DBIx::Class:

    $schema->txn_do(sub {
        $schema->resultset('User')->create({name => 'Dave'});
    });

    my $guard = $schema->txn_scope_guard;
    $schema->resultset('User')->create({name => 'Eve'});
    $guard->commit;    # rolled back if the guard goes out of scope first

DBIx::QuickORM:

    $orm->txn(sub {
        $orm->insert(users => {name => 'Dave'});
    });    # commits on return. An exception rolls back and is rethrown

    my $txn = $orm->txn;
    $orm->insert(users => {name => 'Eve'});
    # or rollback. Unfinished when it goes out of scope: rolled back, with a warning
    $txn->commit;

A C<txn> inside another is always a savepoint (DBIx::Class makes one only
with C<< auto_savepoint => 1 >>). DuckDB has none and croaks. A root
transaction starts with an empty row cache: rows read before it are not
canonical inside it, so a write through one croaks until C<refresh>.
C<cas_update> writes one without a refresh
(L<DBIx::QuickORM::Manual::Transactions>).

=head1 BULK WRITES

DBIx::Class:

    $schema->resultset('User')->populate([{name => 'Fay'}, {name => 'Gus'}]);
    my $changed = $schema->resultset('Post')->search({views => 0})->update({views => 1});
    my $removed = $schema->resultset('Post')->search({views => {'<' => 0}})->delete;

DBIx::QuickORM:

    $orm->insert_many(users => [{name => 'Fay'}, {name => 'Gus'}]);    # void context: nothing read back
    my $changed = $orm->handle('posts')->where({views => 0})->update({views => 1});
    my $removed = $orm->handle('posts')->where({views => {'<' => 0}})->delete;

Like C<populate>, C<insert_many> in void context only inserts. Otherwise it
returns an arrayref of the new rows, or with C<< count => 1 >> how many it
inserted (L<DBIx::QuickORM::Manual::BulkInsert>).

Neither updates the row objects you hold. DBIx::Class's keep their old
values. DBIx::QuickORM's stop being canonical, so a write through one croaks
until C<refresh>.

=head1 COUNTS AND AGGREGATES

DBIx::Class:

    my $n   = $schema->resultset('Post')->count;
    my $top = $schema->resultset('Post')->get_column('views')->max;

    my @per_user = $schema->resultset('Post')->search(undef, {
        select   => [
            'user_id',
            {
                count => '*',
                -as   => 'posts',
            },
        ],
        as       => ['user_id', 'posts'],
        group_by => ['user_id'],
    });
    my $posts = $per_user[0]->get_column('posts');

DBIx::QuickORM:

    use DBIx::QuickORM::Value qw/sql/;

    my $n   = $orm->handle('posts')->count;
    my $top = $orm->handle('posts')
        ->fields({top => [max => 'views']})
        ->only
        ->field('top');

    my @per_user = $orm->handle('posts')
        ->group_by('user_id')
        ->fields({
            user_id => 'user_id',
            posts   => [count => '*'],
            views   => sql('SUM(views)'),    # any SQL
        })
        ->order_by('user_id')
        ->all;

    my $posts = $per_user[0]->field('posts');

A computed column is named once, in C<fields>. There is no separate C<as>
(L<DBIx::QuickORM::Manual::Aggregates>).

=head1 ONE COPY PER ROW

DBIx::Class:

    my $first  = $schema->resultset('User')->find($id);
    my $second = $schema->resultset('User')->find($id);    # a second, independent object

    $first->update({name => 'Ann'});
    my $old = $second->name;                        # still the name $second read
    $second->update({email => 'b@example.com'});    # writes only email: both changes survive
    $second->discard_changes;                       # now Ann

DBIx::QuickORM:

    my $first = $orm->find(users => $id);

    # a second object over the same canonical copy of the data
    my $second = $orm->find(users => $id);

    $first->update({name => 'Ann'});

    # still the name $second read
    my $old = $second->field('name');

    # false: $first's write superseded the data $second holds
    my $current = $second->is_canon;

    # croaks: $second is not canonical
    my $ok = eval { $second->update({email => 'b@example.com'}); 1 };

    # Ann, and canonical again
    $second->refresh;
    $second->update({email => 'b@example.com'});

DBIx::Class has no identity map (one object per row): each C<find> is a new
object, and each object writes the columns it changed, so both updates
survive. DBIx::QuickORM keeps one canonical copy of the data and refuses a
write through an object it has superseded. C<cas_update> writes such a row
safely by comparing with the database (L<DBIx::QuickORM::Manual::Caching>).

=head1 ROW METHODS

DBIx::Class:

    package My::Schema::Result::User;
    # the Result class from above

    sub display_name {
        my $self = shift;
        return $self->name . ' <' . $self->email . '>';
    }

DBIx::QuickORM:

    package My::User;
    use parent 'DBIx::QuickORM::Row';

    sub display_name {
        my $self = shift;
        return $self->field('name') . ' <' . $self->field('email') . '>';
    }

    package main;

    my $orm = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        row_classes => {users => 'My::User'},
    );

    my $label = $orm->find(users => $id)->display_name;

C<row_classes> names a class per table, C<row_class> one for every table
(L<DBIx::QuickORM::Manual::RowClasses>).

To skip listing them, name the classes after the tables, as
C<load_namespaces> does: C<users> gets C<My::Rows::Users>, when that module
exists.

    my $named = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        row_namespace => 'My::Rows',
    );

Or define the ORM as a package (L<DBIx::QuickORM::DSL>), with table
adjustments too. C<tables> names a namespace, and every module
under it is loaded. F<lib/My/ORM.pm>:

    package My::ORM;
    use DBIx::QuickORM::DSL ':orm';

    orm { tables 'My::Tables' };

    1;

Each module's C<table> block names its table, and its C<row> block makes the
module that table's row class. F<lib/My/Tables/Users.pm>:

    package My::Tables::Users;
    use DBIx::QuickORM::DSL qw/:table :row/;

    table { name 'users' };
    row { parent };

    sub display_name {
        my $self = shift;
        return $self->field('name') . ' <' . $self->field('email') . '>';
    }

    1;

C<< My::ORM->new >> takes the connection arguments, and its C<users> rows
are C<My::Tables::Users> objects (L<DBIx::QuickORM::Manual::Classes>).

=head1 DEPLOYING

DBIx::Class:

    $schema->deploy;    # CREATE TABLE from the Result classes

DBIx::QuickORM:

    $dbh->do($_) for @create_statements;    # your own SQL, or your migration tool
    my $orm = DBIx::QuickORM->new(dbh => $dbh);    # scans what is there

Nothing in Perl describes the tables, so there is nothing to deploy from.

=head1 WHAT YOU WRITE YOURSELF

C<create> with related rows: insert the row, then its related rows with
C<insert_many_fk>, in a transaction (L<DBIx::QuickORM::Manual::Transactions>).

    my $zed = $orm->txn(sub {
        my $zed = $orm->insert(users => {name => 'Zed'});
        $zed->insert_many_fk('posts', {title => 'One'}, {title => 'Two'});
        return $zed;
    });

Cascading deletes: DBIx::QuickORM does not cascade. Let the database do it:
declare the foreign key with C<ON DELETE CASCADE> in the schema
(C<< user_id INTEGER REFERENCES users (id) ON DELETE CASCADE >>).

Or delete the children first, in a transaction:

    $orm->txn(sub {
        $zed->refresh;    # read before the transaction, so not canonical in it
        $zed->follow_fk('posts')->delete;
        $zed->delete;
    });

Without either, deleting a referenced row croaks with the database's foreign
key error. DBIx::Class's C<has_many> cascade deletes the related rows after
the parent, so it only helps without a foreign key constraint.

Also without an equivalent: C<many_to_many> (join through the link table),
C<update_or_create>, components, and C<resultset_attributes>.
For the SQL as it runs, L<DBI>'s C<DBI_TRACE> stands in for C<DBIC_TRACE>.

=cut

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
