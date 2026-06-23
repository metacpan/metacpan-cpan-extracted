use strict;
use warnings;
use Test::More;

use DBIO::SQLite::Util qw(column_is_nullable);

# column_is_nullable: a column is logically NOT NULL when declared NOT NULL
# OR part of the primary key (SQLite PRAGMA reports PK columns as notnull=0).
is(column_is_nullable(0, 0), 1, 'plain nullable column is nullable');
is(column_is_nullable(1, 0), 0, 'declared NOT NULL is not nullable');
is(column_is_nullable(0, 1), 0, 'PK column is not nullable despite notnull=0');
is(column_is_nullable(1, 1), 0, 'NOT NULL + PK is not nullable');

done_testing;
