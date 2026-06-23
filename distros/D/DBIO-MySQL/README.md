# DBIO::MySQL

MySQL and MariaDB driver for DBIO (fork of DBIx::Class::Storage::DBI::mysql).

## Supports

- desired-state deployment via test-deploy-and-compare ([DBIO::MySQL::Deploy](https://metacpan.org/pod/DBIO::MySQL::Deploy))
- native introspection ([DBIO::MySQL::Introspect](https://metacpan.org/pod/DBIO::MySQL::Introspect))
- native diff ([DBIO::MySQL::Diff](https://metacpan.org/pod/DBIO::MySQL::Diff))
- native DDL generation ([DBIO::MySQL::DDL](https://metacpan.org/pod/DBIO::MySQL::DDL))

Supports both [DBD::mysql](https://metacpan.org/pod/DBD::mysql) and [DBD::MariaDB](https://metacpan.org/pod/DBD::MariaDB). Install the one matching your server version.

## Usage

    package MyApp::DB;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('MySQL');

    my $schema = MyApp::DB->connect('dbi:mysql:database=myapp');

DBIO core autodetects `dbi:mysql:` DSNs and loads this storage automatically.

## MySQL / MariaDB Features

**Types**
- `INT`, `BIGINT`, `TINYINT`, `SMALLINT`, `MEDIUMINT` - integer types
- `VARCHAR`, `CHAR`, `TEXT`, `MEDIUMTEXT`, `LONGTEXT` - string types
- `ENUM` - enum values (enforced at insert time)
- `SET` - set values (multiple choice from list)
- `JSON` - JSON type (MySQL 5.7+, MariaDB 10.2+)
- `DATETIME`, `TIMESTAMP`, `DATE`, `TIME` - temporal types
- `DECIMAL` - exact numeric with precision
- `FLOAT`, `DOUBLE` - approximate numeric
- `BINARY`, `VARBINARY`, `BLOB` - binary data

**Indexes**
- `PRIMARY KEY`, `UNIQUE`, `INDEX`, `FULLTEXT` indexes
- `SPATIAL` indexes for GIS data (POINT, GEOMETRY)
- Composite indexes across multiple columns
- Prefix indexes on VARCHAR columns (`col(10)`)

**MySQL-Specific Features**
- `INSERT ... ON DUPLICATE KEY UPDATE` (upsert) via `insert_or_update`
- `REPLACE` for delete-and-reinsert semantics
- `SELECT ... FOR UPDATE` row locking
- `INSERT IGNORE` to skip duplicate key errors
- Prepared statement reuse across connections

**GIS Support (Spatial)**
- `POINT`, `GEOMETRY`, `LINESTRING`, `POLYGON` data types
- `ST_Distance`, `ST_Within`, `ST_Contains` spatial functions
- SPATIAL indexes for efficient queries

**Introspection**
- `INFORMATION_SCHEMA` tables for metadata
- `SHOW INDEX FROM table` for index details
- `SHOW CREATE TABLE` for table structure
- Sequence detection for AUTO_INCREMENT columns

## Deploy

[DBIO::MySQL::Deploy](https://metacpan.org/pod/DBIO::MySQL::Deploy) orchestrates test-deploy-and-compare:

1. Introspect live database via INFORMATION_SCHEMA ([DBIO::MySQL::Introspect](https://metacpan.org/pod/DBIO::MySQL::Introspect))
2. Deploy desired schema to a temporary database (`_dbio_tmp_<pid>_<time>`)
3. Introspect the temporary database the same way
4. Diff source vs target ([DBIO::MySQL::Diff](https://metacpan.org/pod/DBIO::MySQL::Diff))
5. Drop the temporary database

Install (`install_ddl`) creates fresh schema. Upgrade diffs live vs. desired.

## Testing

Requires a running MySQL or MariaDB instance:

```bash
export DBIO_TEST_MYSQL_DSN="dbi:mysql:database=myapp"
export DBIO_TEST_MYSQL_USER=root
export DBIO_TEST_MYSQL_PASS=secret
prove -l t/
```

Offline tests (`t/00-load.t`, SQLMaker tests) run without a database.

## Requirements

- Perl 5.36+
- [DBD::mysql](https://metacpan.org/pod/DBD::mysql) or [DBD::MariaDB](https://metacpan.org/pod/DBD::MariaDB)
- DBIO core

## See Also

[DBIO::Introspect::Base](https://metacpan.org/pod/DBIO::Introspect::Base), [DBIO::Diff::Base](https://metacpan.org/pod/DBIO::Diff::Base), [DBIO::Deploy](https://metacpan.org/pod/DBIO::Deploy)

## Repository

[https://codeberg.org/dbio/dbio-mysql](https://codeberg.org/dbio/dbio-mysql)