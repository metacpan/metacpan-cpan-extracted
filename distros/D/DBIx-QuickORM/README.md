# NAME

DBIx::QuickORM - Actively maintained Object Relational Mapping that makes
getting started Quick and has a rich feature set.

# EXTREMELY EARLY VERSION WARNING!

**THIS IS A VERY EARLY VERSION!**

- About 90% of the functionality from the features section is written.
- About 80% of the featrues have been listed.
- About 40% of the written code is tested.
- About 10% of the documentation has been written.

If you want to try it, go for it. Some of the tests give a pretty good idea of
how to use it.

**DO NOT USE THIS FOR ANYTHING PRODUCTION** it is not ready yet.

**The API can and will change!**

# DESCRIPTION

An actively maintained ORM tool that is qucik and easy to start with, but
powerful and expandable for long term and larger projects. An alternative to
[DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass), but not a drop-in replacement.

# SCOPE

The primary scope of this project is to write a good ORM for perl. It is very
easy to add scope, and try to focus on things outside this scope. I am not
opposed to such things being written around the ORM fucntionality, afterall the
project has a lot of useful code, and knowledge of the database. But the
primary focus must always be the ORM functionality, and it must not suffer in
favor of functionality beyond that scope.

# SYNOPSIS

FIXME!

# MOTIVATION

The most widely accepted ORM for perl, [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) is for all intents and
purposes, dead. There is only 1 maintainer, and that person has stated that the
project is feature complete. The project will recieve no updates apart from
critical bugs. The distribution has been marked such that it absolutely can
never be transferred to anyone else.

There are 4 ways forward:

- Use DBIx::Class it as it is.

    Many people continue to do this.

- Monkeypatch DBIx::Class

    I know a handful of people who are working on a way to do this that is not
    terrible and will effectively keep [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) on life support.

- Fork DBIx::Class

    I was initially going to take this route. But after a couple hours in the
    codebase I realized I dislike the internals of DBIx::Class almost as much as I
    dislike using its interface.

- Write an alternative

    I decided to take this route. I have never liked DBIx::Class, I find it
    difficult to approach, and it is complicated to start a project with it. The
    interface is unintuitive, and the internals are very opaque.

    My goal is to start with the interface, make it approachable, easy to start,
    etc. I also want the interface to be intuitive to use. I also want
    expandability. I also want to make sure I adopt the good ideas and capabilities
    from DBIx::Class. Only a fol would say DBIx::Class has nothing of value.

## MAINTENANCE COMMITMENT

I want to be sure that what happened to [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) cannot happen to this
project. I will maintain this as long as I am able. When I am not capable I
will let others pick up where I left off.

I am stating here, in the docs, for all to see for all time:

**If I become unable to maintain this project, I approve of others being given
cpan and github permissions to develop and release this distribution.**

Peferably maint will be handed off to someone who has been a contributor, or to
a group of contributors, If none can be found, or none are willing, I trust the
cpan toolchain group to takeover.

# FEATURE/GOAL OVERVIEW

## Quick to start

It should be very simple to start a project. The ORM should stay out of your
way until you want to make it do something for you.

## Intuitive

Names, interfaces, etc should make sense and be obvious.

## Declarative syntax

Look at the ["DECLARATIVE INTERFACE"](#declarative-interface) section below, or the ["SYNOPSIS"](#synopsis)
section above.

## SQL <-> Perl conversion

It can go either way.

### Generate the perl schema from a populated database.

    my $orm = orm 'MyOrm' => sub {
        # First provide db credentials and connect info
        db { ... };

        # Tell DBIx::QuickORM to do the rest
        autofill();
    };

    # Built for you by reading from the database.
    my $schema = $orm->schema;

### Generate SQL to populate a database from a schema defined in perl.

See [DBIx::QuickORM::Util::SchemaBuilder](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AUtil%3A%3ASchemaBuilder) for more info.

## Async query support

Async query support is a key and first class feature of DBIx::QuickORM.

### Single async query - single connection

Launch an async query on the current connection, then do other stuff until it
is ready.

See [DBIx::QuickORM::Select::Async](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ASelect%3A%3AAsync) for full details. but here are some teasers:

    # It can take more args than just \%where, this is just a simply case
    my $async = $orm->async(\%where)->start;
    until ($async->ready) { ... };
    my @rows = $async->all;

You can also turn any select into an async:

    my $select = $orm->select(...);
    my $async = $orm->async;
    $async->start;

### Multiple concurrent async query support - multiple connections on 1 process

DBIx::QuickORM calls this an 'aside'. See [DBIx::QuickORM::Select::Aside](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ASelect%3A%3AAside) for
more detail.

In this case we have 2 queries executing simeltaniously.

    my $aside  = $orm->aside(\%where)->start;    # Runs async query on a new connection
    my $select = $orm->select(\%where);
    my @rows1  = $select->all;
    my @rows2  = $aside->all;

Note that if both queries return some of the same rows there will only be 1
copy in cache, and both @row arrays will have the same object reference.

### Multiple concurrent async query support - emulation via forking

See [DBIx::QuickORM::Select::Forked](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ASelect%3A%3AForked) for more detail.

Similar to the 'aside' functionality above, but instead of running an async
query on a new connection, a new process is forked, and that process does a
synchronous query and returns the results. This is useful for emulating
aside/async with databases that do not support it such as SQLite.

## First class inflation and deflation (Conflation)

Inflation and Deflation of columns is a first-class feature. But since saying
'inflation and deflation' every time is a chore DBIx::QuickORM shortens the
concept to 'conflation'. No, the word "conflation" is not actually related to
"inflation" or "deflation", but it is an amusing pun, specially since it still
kind of works with the actual definition of "conflation".

If you specify that a column has a conflator, then using
`my $val = $row->column('name')` will give you the inflated form. You can
also set the column by giving it either the inflated or deflated form. You also
always have access to the raw values, and asking for either the 'stored' or
'dirty' value will give the raw form.

You can also use inflated forms in the %where argument to select/find.

The rows are also smart enough to check if your inflated forms have been
mutated and consider the row dirty (in need of saving or discarding) after the
mutation. This is done by deflating the values to compare to the stored form
when checking for dirtyness.

If your inflated values are readonly, locked restricted hashes, or objects that
implement the 'qorm\_immutible' method (and it returns true). Then the row is
smart enough to skip checking them for mutations as they cannot be mutated.

Oh, also of note, inflated forms do not need to be blessed, nor do they even
need to be references. You could write a conflator that inflates string to have
"inflated: " prefixed to them, and no prefix when they are raw/deflated. A
conflator that encrypts/decrypts passively is also possible, assuming the
encrypted and decrypted forms are easily distinguishable.

### UUID, UUID::Binary, UUID::Stringy

Automatically inflate and deflate UUID's. Your database can store it as a
native UUID, a BIN(16), a VARCHAR(36), or whatever. Tell the orm the row should
be conflated as a UUID and it will just work. You can set the value by
providing a string, binary data, or anything else the conflator recognizes. In
the DB it will store the right type, and in perl you will get a UUID object.

    schema sub {
        table my_table => sub {
            column thing_uuid => sub {
                conflate 'UUID'; # OR provide '+Your::Conflator', adds 'DBIx::QuickORM::Conflator::' without the '+'
            };
        };
    };

- [DBIx::QuickORM::Conflator::UUID](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AConflator%3A%3AUUID)

    Inflates to an object of this class, deflates to whatever the database column
    type is. Object stringifies as a UUID string, and you can get botht he string
    and binary value from it through accessors.

    If generating the SQL to populate the db this will tell it the column should be
    the 'UUID' type, and will throw an exception if that type is not supported by
    the db.

- [DBIx::QuickORM::Conflator::UUID::Binary](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AConflator%3A%3AUUID%3A%3ABinary)

    This is useful only if you are generating the schema SQL to populate the db and
    the db does not support UUID types. This will create the column using a binary
    data type like BIN(16).

- [DBIx::QuickORM::Conflator::UUID::Stringy](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AConflator%3A%3AUUID%3A%3AStringy)

    This is useful only if you are generating the schema SQL to populate the db and
    the db does not support UUID types. This will create the column using a stringy
    data type like VARCHAR(36).

### JSON, JSON::ASCII

This conflator will inflate the JSON into a perl data structure and deflate it
back into a JSON string.

This uses [Cpanel::JSON::XS](https://metacpan.org/pod/Cpanel%3A%3AJSON%3A%3AXS) under the hood.

- [DBIx::QuickORM::Conflator::JSON](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AConflator%3A%3AJSON)

    Defaults to `$json->utf8->encode_json`

    This produces a utf8 encoded json string.

- [DBIx::QuickORM::Conflator::JSON::ASCII](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AConflator%3A%3AJSON%3A%3AASCII)

    Defaults to `$json->ascii->encode_json`

    This produces an ASCII encoded json string with non-ascii characters escaped.

### DateTime - Will not leave a mess with Data::Dumper!

[DBIx::QuickORM::Conflator::DateTime](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AConflator%3A%3ADateTime)

This conflator will inflate dates and times into [DateTime](https://metacpan.org/pod/DateTime) objects. However
it also wraps them in an [DBIx::QuickORM::Util::Mask](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AUtil%3A%3AMask) object. This object
hides the DateTime object in a `sub { $datetime }`. When dumped by
Data::Dumper you get something like this:

    bless( [
             '2024-10-26T06:18:45',
             sub { "DUMMY" }
           ], 'DBIx::QuickORM::Conflator::DateTime' );

This is much better than spewing the DateTime internals, whcih can take several
pages of scrollback.

You can still call any valid [DateTime](https://metacpan.org/pod/DateTime) method on this object and it will
delegate it to the one that is masked beind the coderef.

### Custom conflator

See the [DBIx::QuickORM::Role::Conflator](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ARole%3A%3AConflator) role.

### Custom on the fly

Declarative:

    my $conflator = conflator NAME => sub {
        inflate { ... };
        deflate { ... };
    };

OOP:

    my $conflator = DBIx::QuickORM::Conflator->new(
        name => 'NAME',
        inflate => sub { ... },
        defalte => sub { ... }
    );

## Multiple ORM instances for different databases and schemas

    db develop    => sub { ... };
    db staging    => sub { ... };
    db production => sub { ... };

    my $app1 = schema app1 => { ... };
    my $app2 = schema app2 { ... };

    orm app1_dev => sub {
        db 'develop';
        schema 'app1';
    };

    orm app2_prod => sub {
        db 'production';
        schema 'app2';
    };

    orm both_stage => sub {
        db 'staging';

        # Builds a new schema object, does not modify either original
        schema $app1->merge($app2);
    };

## "Select" object that is very similar to DBIx::Class's ResultSet

ResultSet was a good idea, regardless of your opinion on [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass). The
[DBIx::QuickORM::Select](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ASelect) objects implement most of the same things.

    my $sel = $orm->select('TABLE/SOURCE', \%where)
    my $sel = $orm->select('TABLE/SOURCE', \%where, $order_by)
    my $sel = $orm->select('TABLE/SOURCE', where => $where, order_by => $order_by, ... );
    $sel = $sel->and(\%where);
    my @rows = $sel->all;
    my $row = $sel->next;
    my $total = $sel->count;

## Find exactly 1 row

    # Throws an exception if multiple rows are found.
    my $row = $orm->find($source, \%where);

## Fetch just the data, no row object (bypasses cache)

    my $data_hashref = $orm->fetch($source, \%where);

## Uses SQL::Abstract under the hood for familiar query syntax

See [SQL::Abstract](https://metacpan.org/pod/SQL%3A%3AAbstract).

## Built in support for transactions and nested transactions (savepoints)

See [DBIx::QuickORM::Transaction](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ATransaction) and ["TRANSACTIONS" in DBIx::QuickORM::ORM](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AORM#TRANSACTIONS)
for additional details.

- $orm->txn\_do(sub { ... });

    Void context will commit if there are no exceptions. It will rollback the
    transaction and re-throw the exception if it encounters one.

- $res = $orm->txn\_do(sub { ... });

    Scalar context.

    On success it will commit and return whatever the sub returns, or the number 1 if the sub
    returns nothing, or anything falsy. If you want to return a false value you
    must send it as a ref, or use the list context form.

    If an exception is thrown by the block then the transaction will be rolled back
    and $res will be false.

- ($ok, $res\_or\_err) = $orm->txn\_do(sub { ... });

    List context.

    On success it will commit and return `(1, $result)`.

    If an exception occurs in the block then the transaction will be rolled back,
    $ok will be 0, and $ret\_or\_err will contain the exception.

    $orm->txn_do(sub {
        my $txn = shift;

        # Nested!
        my ($ok, $res_or_err) = $orm->txn_do(sub { ... });

        if ($ok) { $txn->commit }
        else     { $txn->rollback };

        # Automatic rollback if an exception is thrown, or if commit is not called
    });

    # Commit if no exception is thrown, rollback on exception
    $orm->txn_do(sub { ... });

Or manually:

    my $txn = $orm->start_txn;

    if ($ok) { $txn->commit }
    else     { $txn->rollback };

    # Force a rollback unless commit or rollback were called:
    $txn = undef;

## Caching system

Each [DBIx::QuickORM::ORM](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AORM) instance has its own cache object.

### Default cache: Naive, only 1 copy of any row in active memory

[DBIx::QuickORM::Cache::Naive](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ACache%3A%3ANaive) is a basic caching system that insures you only
have 1 copy of any specific row at any given time (assuming it has a primary
key, no cahcing is attempted for rows with no primary key).

**Note:** If you have multiple ORMs connecting to the same db, they do not share
a cache and you can end up with the same row in memory twice with 2 different
references.

### 'None' cache option to skip caching, every find/select gets a new row instance

You can also choose to use [DBIx::QuickORM::Cache::None](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ACache%3A%3ANone) which is basically a
no-op for everything meaning there is no cache, every time you get an object
from the db it is a new copy.

### Write your own cache if you do not like these

Write your own based on the [DBIx::QuickORM::Cache](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ACache) base class.

## Multiple databases supported:

Database interactions are defined by [DBIx::QuickORM::DB](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADB) subclasses. The
parent class provides a lot of generic functionality that is fairly universal.
But the subclasses allow you to specify if a DB does or does not support
things, how to translate type names from other DBs, etc.

### PostgreSQL

Tells the ORM what features are supported by PostgreSQL, and how to access
them.

See [DBIx::QuickORM::DB::PostgreSQL](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADB%3A%3APostgreSQL), which uses [DBD::Pg](https://metacpan.org/pod/DBD%3A%3APg) under the hood.

### MySQL (Generic)

Tells the ORM what features are supported by any generic MySQL, and how to
access them.

This FULLY supports both [DBD::mysql](https://metacpan.org/pod/DBD%3A%3Amysql) and [DBD::MariaDB](https://metacpan.org/pod/DBD%3A%3AMariaDB) for connections,
pick whichever you prefer, the [DBIx::QuickORM::DB::MySQL](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADB%3A%3AMySQL) class is aware of
the differences and will alter behavior accordingly.

### MySQL (Percona)

Tells the ORM what features are supported by Percona MySQL, and how to
access them.

This FULLY supports both [DBD::mysql](https://metacpan.org/pod/DBD%3A%3Amysql) and [DBD::MariaDB](https://metacpan.org/pod/DBD%3A%3AMariaDB) for connections,
pick whichever you prefer, the [DBIx::QuickORM::DB::MySQL](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADB%3A%3AMySQL) and
[DBIx::QuickORM::DB::Percona](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADB%3A%3APercona) classes are aware of the differences and will
alter behavior accordingly.

### MariaDB

Tells the ORM what features are supported by MariaDB, and how to
access them.

This is essentially MySQL + the extra features MariaDB supports.

This FULLY supports both [DBD::mysql](https://metacpan.org/pod/DBD%3A%3Amysql) and [DBD::MariaDB](https://metacpan.org/pod/DBD%3A%3AMariaDB) for connections,
pick whichever you prefer, the [DBIx::QuickORM::DB::MySQL](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADB%3A%3AMySQL) and
[DBIx::QuickORM::DB::MariaDB](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADB%3A%3AMariaDB) classes are aware of the differences and will
alter behavior accordingly.

### SQLite

Tells the ORM what features are supported by SQLite, and how to
access them.

See [DBIx::QuickORM::DB::SQLite](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADB%3A%3ASQLite), which uses [DBD::SQLite](https://metacpan.org/pod/DBD%3A%3ASQLite) under the hood.

### Write your own orm <-> db link class

Take a look at [DBIx::QuickORM::DB](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADB) to see what you need to implement.

## Temporary tables and views

Each ORM object [DBIx::QuickORM::ORM](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AORM) has the static schema it is built with,
but it also has a second 'connection' schema. Using this second schema you can
define temporary views and tables (on supported databases).

    $orm->create_temp_table(...);
    $orm->create_temp_view(...);

See the [DBIx::QuickORM::ORM](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AORM) documentation for more details.

## Highly functional Row class, ability to use custom ones

[DBIx::QuickORM::Row](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ARow) is the base class for rows, and the default one used for
rows that are returned. It provides several methods for getting/setting
columns, including directly accessing stored, pending, and inflated values. It
also has methods for finding and fetching relations.

This row class does not provide any per-column accessors. For those you need one of the following:

- [DBIx::QuickORM::Row::AutoAccessors](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ARow%3A%3AAutoAccessors)

    This row class uses AUTOLOAD to generate accessors based on column names on the
    fly. So `my $val = $row->foo` is the same as `$row->column('foo')`.

    It also generates accessors for relationships on the fly.

- Create your own row subclasses and tell the schema to use them.

        table foo => sub {
            row_class 'My::Row::Class::Foo';
        };

- Create a class that defines the table and generates a table specific row class

    My::Table::Foo.pm:

        package My::Table::Foo
        use DBIx::QuickORM ':TABLE_CLASS';

        use DBIx::QuickORM::MetaTable foo => sub {
            column id => ...;
            column foo => ...;

            # Declarative keywords are removed after this scope ends.
        };

        # There are now accessors for all the columns and relationships.

        sub whatever_methods_you_want {
            my $self = shift;
            ...
        }

    Elsware...

        orm MyORM => sub {
            table My::Table::Foo;

            # or to load a bunch:
            tables 'My::Table'; # Loads all My::Table::* tables
        };

## Relation mapping and pre-fetching

TODO: Fill this in.

## Plugin system

There are a lot of hooks, essentially a plugin is either a codered called for
all hooks (with params telling you about the hook, or they are classes/objects
that define the 'qorm\_plugin\_action()" method or that consume the
[DBIx::QuickORM::Role::Plugin](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ARole%3A%3APlugin) role.

    plugin sub { ... }; # On the fly plugin writing
    plugin Some::Plugin; # Use a plugin class (does not have or need a new method)
    plugin Other::Plugin->new(...); Plugin that needs to be blessed

Bigger example:

    plugin sub {
        my $self = shift;
        my %params     = @_;
        my $hook       = $params{hook};
        my $return_ref = $params{return_ref};

        ...

        # if the hook expects you to return a value, instead of modifying a ref
        # in %params, then the return_ref will have a scalar reference to set.
        ${return_ref} = $out if defined($return_ref);
    };

Define custom plugin hooks in your custom tools:

    plugin_hook NAME => \%params; # Any/All plugins can take action here.

### Current hooks

- auto\_conflate => (data\_type => $dtype, sql\_type => $stype, column => $col, table => $table)

    Use this to automatically inject conflation when auto-generating perl-side
    schema from a populated db.

- post\_build => (build\_params => \\%params, built => $out, built\_ref => \\$out)

    Called after building an object (ORM, Schema, DB, etc).

- pre\_build => (build\_params => \\%params)

    Called before building an object (ORM, Schema, DB, etc).

- relation\_name => (default\_name => $alias, table => $table, table\_name => $tname, fk => $fk)

    use to rename relations when auto-generating perl-side schema from a populated db.

- sql\_spec => (column => $col, table => $table, sql\_spec => $spec)

    Opportunity to modify the [DBIx::QuickORM::SQLSpec](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ASQLSpec) data for a row.

- sql\_spec => (table => $table, sql\_spec => sql\_spec())

    Opportunity to modify the [DBIx::QuickORM::SQLSpec](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ASQLSpec) data for a table.

### Ability to customize relationship names when auto-generating perl schema from SQL schema

TODO: Fill this in.

## Does not use Moose under the hood (light weight)

Most objects in [DBIx::QuickORM](https://metacpan.org/pod/DBIx%3A%3AQuickORM) use [Object::HashBase](https://metacpan.org/pod/Object%3A%3AHashBase) which is what
[Test2](https://metacpan.org/pod/Test2) uses under the hood. [Object::HashBase](https://metacpan.org/pod/Object%3A%3AHashBase) is very lightweight and
performant.

For roles DBIx::QuickORM uses [Role::Tiny](https://metacpan.org/pod/Role%3A%3ATiny).

## Using Data::Dumper on a row does not dump all the ORM internals

[DBIx::QuickORM::Row](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ARow) objects need access to the source, and to the orm. If a
reference to these was simply put into the row objects hashref then
[Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper) is going to work hard to absolutely fill your scrollback with
useless info every time you dump your row. [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) suffers from this
issue.

For [DBIx::QuickORM](https://metacpan.org/pod/DBIx%3A%3AQuickORM) the source is an [DBIx::QuickORM::Source](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ASource) object. And it
is put into the `$row->{source}` hash key. But first it is masked using
[DBIx::QuickORM::Util::Mask](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AUtil%3A%3AMask) so that when dumped with [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper) you see
this:

    bless( {
             'source' => bless( [
                                  'DBIx::QuickORM::Source=HASH(0x59d72c1c33c8)',
                                  sub { "DUMMY" }
                                ], 'DBIx::QuickORM::Util::Mask' ),
             ...
                              }
           }, 'DBIx::QuickORM::Row' );

All methods that are valid on [DBIx::QuickORM::Source](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ASource) can be called on the
masked form and they will be delegated to the masked object.

This + the DateTime conflator mean that rows from DBIx::QuickORM can be dumped
by Data::Dumper without wiping out your scrollback buffer.

# DECLARATIVE INTERFACE

TODO - Fill this in.

# SOURCE

The source code repository for DBIx-QuickORM can be found at
[http://github.com/exodist/DBIx-QuickORM/](http://github.com/exodist/DBIx-QuickORM/).

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright Chad Granum <exodist7@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/)
