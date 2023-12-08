# NAME

Aion::Query - functional interface for accessing database mysql and mariadb

# VERSION

0.0.3

# SYNOPSIS

File .config.pm:
```perl
package config;

config_module Aion::Query => {
    DRV  => "SQLite",
    BASE => "test-base.sqlite",
    BQ => 0,
};

1;
```

```perl
use Aion::Query;

query "CREATE TABLE author (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
)";

insert "author", name => "Pushkin A.S." # -> 1

touch "author", name => "Pushkin A."    # -> 2
touch "author", name => "Pushkin A.S."  # -> 1
touch "author", name => "Pushkin A."    # -> 2

query_scalar "SELECT count(*) FROM author"  # -> 2

my @rows = query "SELECT *
FROM author
WHERE 1
    if_name>> AND name like :name
",
    if_name => Aion::Query::BQ == 0,
    name => "P%",
;

\@rows # --> [{id => 1, name => "Pushkin A.S."}, {id => 2, name => "Pushkin A."}]

$Aion::Query::DEBUG[1]  # => query: INSERT INTO author (name) VALUES ('Pushkin A.S.')
```

# DESCRIPTION

When constructing queries, many disparate conditions are used, usually separated by different methods.

`Aion::Query` uses a different approach, which allows you to construct an SQL query in a query using a simple template engine.

The second problem is placing unicode characters into single-byte encodings, which reduces the size of the database. So far it has been solved only for the **cp1251** encoding. It is controlled by the parameter `BQ = 1`.

# SUBROUTINES

## query ($query, %params)

It provide SQL (DCL, DDL, DQL and DML) queries to DBMS with quoting params.

```perl
query "SELECT * FROM author WHERE name=:name", name => 'Pushkin A.S.' # --> [{id=>1, name=>"Pushkin A.S."}]
```

## LAST_INSERT_ID ()

Returns last insert id.

```perl
query "INSERT INTO author (name) VALUES (:name)", name => "Alice"  # -> 1
LAST_INSERT_ID  # -> 3
```

## quote ($scalar)

Quoted scalar for SQL-query.

```perl
quote undef     # => NULL
quote "abc"     # => 'abc'
quote 123       # => 123
quote "123"     # => '123'
quote(0+"123")  # => 123
quote(123 . "") # => '123'
quote 123.0       # => 123.0
quote(0.0+"126")  # => 126
quote("127"+0.0)  # => 127
quote("128"-0.0)  # => 128
quote("129"+1.e-100)  # => 129.0

# use for insert formula: SELECT :x as summ ⇒ x => \"xyz + 123"
quote \"without quote"  # => without quote

# use in: WHERE id in (:x)
quote [1,2,"5"] # => 1, 2, '5'

# use in: INSERT INTO author VALUES :x
quote [[1, 2], [3, "4"]]  # => (1, 2), (3, '4')

# use in multiupdate: UPDATE author SET name=CASE id :x ELSE null END
quote \[2=>'Pushkin A.', 1=>'Pushkin A.S.']  # => WHEN 2 THEN 'Pushkin A.' WHEN 1 THEN 'Pushkin A.S.'

# use for UPDATE SET :x or INSERT SET :x
quote {name => 'A.S.', id => 12}   # => id = 12, name = 'A.S.'

[map quote, -6, "-6", 1.5, "1.5"] # --> [-6, "'-6'", 1.5, "'1.5'"]

```

## query_prepare ($query, %param)

Replace the parameters in `$query`. Parameters quotes by the `quote`.

```perl
query_prepare "INSERT author SET name IN (:name)", name => ["Alice", 1, 1.0]  # => INSERT author SET name IN ('Alice', 1, 1.0)

query_prepare ":x :^x :.x :~x", x => "10"  # => '10' 10 10.0 '10'

my $query = query_prepare "SELECT *
FROM author
    words*>> JOIN word:_
WHERE 1
    name>> AND name like :name
",
    name => "%Alice%",
    words => [1, 2, 3],
;

my $res = << 'END';
SELECT *
FROM author
    JOIN word1
    JOIN word2
    JOIN word3
WHERE 1
    AND name like '%Alice%'
END

$query # -> $res
```

## query_do ($query)

Execution query and returns it result.

```perl
query_do "SELECT count(*) as n FROM author"  # --> [{n=>3}]
query_do "SELECT id FROM author WHERE id=2"  # --> [{id=>2}]
```

## query_ref ($query, %kw)

As `query`, but always returns a reference.

```perl
my @res = query_ref "SELECT id FROM author WHERE id=:id", id => 2;
\@res  # --> [[ {id=>2} ]]
```

## query_sth ($query, %kw)

As `query`, but returns `$sth`.

```perl
my $sth = query_sth "SELECT * FROM author";
my @rows;
while(my $row = $sth->fetchrow_arrayref) {
    push @rows, $row;
}
$sth->finish;

0+@rows  # -> 3
```

## query_slice ($key, $val, @args)

As query, plus converts the result into the desired data structure.

```perl
my %author = query_slice name => "id", "SELECT id, name FROM author";
\%author  # --> {"Pushkin A.S." => 1, "Pushkin A." => 2, "Alice" => 3}
```

## query_col ($query, %params)

Returns one column.

```perl
query_col "SELECT name FROM author ORDER BY name" # --> ["Alice", "Pushkin A.", "Pushkin A.S."]

eval {query_col "SELECT id, name FROM author"}; $@  # ~> Only one column is acceptable!
```

## query_row ($query, %params)

Returns one row.

```perl
query_row "SELECT name FROM author WHERE id=2" # --> {name => "Pushkin A."}

my ($id, $name) = query_row "SELECT id, name FROM author WHERE id=2";
$id    # -> 2
$name  # => Pushkin A.
```

## query_row_ref ($query, %params)

As `query_row`, but retuns array reference always.

```perl
my @x = query_row_ref "SELECT name FROM author WHERE id=2";
\@x # --> [{name => "Pushkin A."}]

eval {query_row_ref "SELECT name FROM author"}; $@  # ~> A few lines!
```

## query_scalar ($query, %params)

Returns scalar.

```perl
query_scalar "SELECT name FROM author WHERE id=2" # => Pushkin A.
```

## make_query_for_order ($order, $next)

Creates a condition for requesting a page not by offset, but by **cursor pagination**.

To do this, it receives `$order` of the SQL query and `$next` - a link to the next page.

```perl
my ($select, $where, $order_sel) = make_query_for_order "name DESC, id ASC", undef;

$select     # => name || ',' || id
$where      # -> 1
$order_sel  # -> undef

my @rows = query "SELECT $select as next FROM author WHERE $where LIMIT 2";

my $last = pop @rows;

($select, $where, $order_sel) = make_query_for_order "name DESC, id ASC", $last->{next};
$select     # => name || ',' || id
$where      # => (name < 'Pushkin A.'\nOR name = 'Pushkin A.' AND id >= '2')
$order_sel  # --> [qw/name id/]
```

See also:
1. Article [Paging pages on social networks
](https://habr.com/ru/articles/674714/).
2. [SQL::SimpleOps->SelectCursor](https://metacpan.org/dist/SQL-SimpleOps/view/lib/SQL/SimpleOps.pod#SelectCursor)

## settings ($id, $value)

Sets or returns a key from a table `settings`.

```perl
query "CREATE TABLE settings(
    id TEXT PRIMARY KEY,
	value TEXT NOT NULL
)";

settings "x1"       # -> undef
settings "x1", 10   # -> 1
settings "x1"       # -> 10
```

## load_by_id ($tab, $pk, $fields, @options)

Returns the entry by its id.

```perl
load_by_id author => 2  # --> {id=>2, name=>"Pushkin A."}
load_by_id author => 2, "name as n"  # --> {n=>"Pushkin A."}
load_by_id author => 2, "id+:x as n", x => 10  # --> {n=>12}
```

## insert ($tab, %x)

Adds a record and returns its id.

```perl
insert 'author', name => 'Masha'  # -> 4
```

## update ($tab, $id, %params)

Updates a record by its id, and returns this id.

```perl
update author => 3, name => 'Sasha'  # -> 3
eval { update author => 5, name => 'Sasha' }; $@  # ~> Row author.id=5 is not!
```

## remove ($tab, $id)

Remove row from table by it id, and returns this id.

```perl
remove "author", 4  # -> 4
eval { remove author => 4 }; $@  # ~> Row author.id=4 does not exist!
```

## query_id ($tab, %params)

Returns the id based on other fields.

```perl
query_id 'author', name => 'Pushkin A.' # -> 2
```

## stores ($tab, $rows, %opt)

Saves data (update or insert). Returns count successful operations.

```perl
my @authors = (
    {id => 1, name => 'Pushkin A.S.'},
    {id => 2, name => 'Pushkin A.'},
    {id => 3, name => 'Sasha'},
);

query "SELECT * FROM author ORDER BY id" # --> \@authors

my $rows = stores 'author', [
    {name => 'Locatelli'},
    {id => 3, name => 'Kianu R.'},
    {id => 2, name => 'Pushkin A.'},
];
$rows  # -> 3

my $sql = "query: INSERT INTO author (id, name) VALUES (NULL, 'Locatelli'),
(3, 'Kianu R.'),
(2, 'Pushkin A.') ON CONFLICT DO UPDATE SET id = excluded.id, name = excluded.name";

$Aion::Query::DEBUG[$#Aion::Query::DEBUG]  # -> $sql


@authors = (
    {id => 1, name => 'Pushkin A.S.'},
    {id => 2, name => 'Pushkin A.'},
    {id => 3, name => 'Kianu R.'},
    {id => 5, name => 'Locatelli'},
);

query "SELECT * FROM author ORDER BY id" # --> \@authors
```

## store ($tab, %params)

Saves data (update or insert). But one row.

```perl
store 'author', name => 'Bishop M.' # -> 1
```

## touch ($tab, %params)

Super-powerful function: returns id of row, and if it doesn’t exist, creates or updates a row and still returns.

```perl
touch 'author', name => 'Pushkin A.' # -> 2
touch 'author', name => 'Pushkin X.' # -> 7
```

## START_TRANSACTION ()

Returns the variable on which to set commit, otherwise the rollback occurs.

```perl
my $transaction = START_TRANSACTION;

query "UPDATE author SET name='Pushkin N.' where id=7"  # -> 1

$transaction->commit;

query_scalar "SELECT name FROM author where id=7"  # => Pushkin N.


eval {
    my $transaction = START_TRANSACTION;

    query "UPDATE author SET name='Pushkin X.' where id=7" # -> 1

    die "!";  # rollback
    $transaction->commit;
};

query_scalar "SELECT name FROM author where id=7"  # => Pushkin N.
```

## default_dsn ()

Default DSN for `DBI->connect`.

```perl
default_dsn  # => DBI:SQLite:dbname=test-base.sqlite
```

## default_connect_options ()

DSN, USER, PASSWORD and commands after connect.

```perl
[default_connect_options]  # --> ['DBI:SQLite:dbname=test-base.sqlite', 'root', 123, []]
```

## base_connect ($dsn, $user, $password, $conn)

Connect to base and returns connect and it identify.

```perl
my ($dbh, $connect_id) = base_connect("DBI:SQLite:dbname=base-2.sqlite", "toor", "toorpasswd", []);

ref $dbh     # => DBI::db
$connect_id  # -> -1
```

## connect_respavn ($base)

Connection check and reconnection.

```perl
my $old_base = $Aion::Query::base;

$old_base->ping  # -> 1
connect_respavn $Aion::Query::base, $Aion::Query::base_connection_id;

$old_base  # -> $Aion::Query::base
```

## connect_restart ($base)

Connection restart.

```perl
my $connection_id = $Aion::Query::base_connection_id;
my $base = $Aion::Query::base;

connect_restart $Aion::Query::base, $Aion::Query::base_connection_id;

$base->ping  # -> 0
$Aion::Query::base->ping  # -> 1
```

## query_stop ()

A request may be running - you need to kill it.

Creates an additional connection to the base and kills the main one.

It using `$Aion::Query::base_connection_id` for this.

SQLite runs in the same process, so `$Aion::Query::base_connection_id` has `-1`. In this case, this method does nothing.

```perl
my @x = query_stop;
\@x  # --> []
```

## sql_debug ($fn, $query)

Stores queries to the database in `@Aion::Query::DEBUG`. Called from `query_do`.

```perl
sql_debug label => "SELECT 123";

$Aion::Query::DEBUG[$#Aion::Query::DEBUG]  # => label: SELECT 123
```

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Surf module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
