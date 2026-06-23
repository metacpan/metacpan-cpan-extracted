# DBIO::Firebird

Firebird and InterBase database driver for DBIO (fork of DBIx::Class).

## Supports

- desired-state deployment via test-deploy-and-compare ([DBIO::Firebird::Deploy](https://metacpan.org/pod/DBIO::Firebird::Deploy))
- native introspection ([DBIO::Firebird::Introspect](https://metacpan.org/pod/DBIO::Firebird::Introspect))
- native diff ([DBIO::Firebird::Diff](https://metacpan.org/pod/DBIO::Firebird::Diff))
- native DDL generation ([DBIO::Firebird::DDL](https://metacpan.org/pod/DBIO::Firebird::DDL))

## Usage

    package MyApp::DB;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('Firebird');

    my $schema = MyApp::DB->connect('dbi:Firebird:database=myapp');

DBIO core autodetects `dbi:Firebird:` DSNs and loads this storage automatically.

## Firebird Features

**Types**
- `INTEGER`, `BIGINT`, `SMALLINT` - numeric types
- `VARCHAR`, `CHAR`, `BLOB` - string/binary types
- `DATE`, `TIME`, `TIMESTAMP` - temporal types
- `DECIMAL`, `NUMERIC` - fixed-point numeric
- `FLOAT`, `DOUBLE` - floating-point

**Schema Support**
- RDB$ system tables for introspection
- Firebird-specific generators/sequences for auto-increment

**Introspection (RDB$)**
- `RDB$RELATIONS` - table metadata
- `RDB$FIELDS` - column types
- `RDB$INDICES` - index information
- `RDB$TRIGGERS` - triggers and generators

**Firebird-Specific**
- Generator-based auto-increment
- `SELECT GEN_ID(generator, 1) FROM RDB$DATABASE` pattern
- Transaction isolation levels
- Multi-database support via unified API

## Deploy

[DBIO::Firebird::Deploy](https://metacpan.org/pod/DBIO::Firebird::Deploy) orchestrates test-deploy-and-compare:

1. Introspect live database via RDB$ tables ([DBIO::Firebird::Introspect](https://metacpan.org/pod/DBIO::Firebird::Introspect))
2. Deploy desired schema to a temporary database file
3. Introspect the temporary database the same way
4. Diff source vs target ([DBIO::Firebird::Diff](https://metacpan.org/pod/DBIO::Firebird::Diff))

Install (`install_ddl`) creates fresh schema. Upgrade diffs live vs. desired.

## Testing

Requires a running Firebird instance:

```bash
export DBIO_TEST_FIREBIRD_DSN="dbi:Firebird:database=myapp"
export DBIO_TEST_FIREBIRD_USER=sysdba
export DBIO_TEST_FIREBIRD_PASS=secret
prove -l t/
```

## Requirements

- Perl 5.36+
- [DBD::Firebird](https://metacpan.org/pod/DBD::Firebird)
- DBIO core

## See Also

[DBIO::Introspect::Base](https://metacpan.org/pod/DBIO::Introspect::Base), [DBIO::Diff::Base](https://metacpan.org/pod/DBIO::Diff::Base), [DBIO::Deploy](https://metacpan.org/pod/DBIO::Deploy)

## Repository

[https://codeberg.org/dbio/dbio-firebird](https://codeberg.org/dbio/dbio-firebird)
