# DBIO::Oracle

Oracle database driver for DBIO (fork of DBIx::Class).

## Supports

- desired-state deployment via test-deploy-and-compare ([DBIO::Oracle::Deploy](https://metacpan.org/pod/DBIO::Oracle::Deploy))
- native introspection ([DBIO::Oracle::Introspect](https://metacpan.org/pod/DBIO::Oracle::Introspect))
- native diff ([DBIO::Oracle::Diff](https://metacpan.org/pod/DBIO::Oracle::Diff))
- native DDL generation ([DBIO::Oracle::DDL](https://metacpan.org/pod/DBIO::Oracle::DDL))

## Usage

    package MyApp::DB;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('Oracle');

    my $schema = MyApp::DB->connect('dbi:Oracle:database=myapp');

DBIO core autodetects `dbi:Oracle:` DSNs and loads this storage automatically.

## Oracle Features

**Types**
- `NUMBER`, `INTEGER`, `BINARY_FLOAT` - numeric types
- `VARCHAR2`, `CHAR`, `CLOB`, `NCLOB` - string types
- `BLOB`, `RAW`, `LONG RAW` - binary types
- `DATE`, `TIMESTAMP`, `INTERVAL` - temporal types

**Schema Support**
- `USER_TAB_COLUMNS`, `USER_TABLES` for introspection
- `USER_SEQUENCES` for sequence-based auto-increment
- Oracle-specific sequence objects

**Introspection (USER_*, ALL_*)**
- `USER_TABLES` - table metadata
- `USER_TAB_COLUMNS` - column metadata
- `USER_INDEXES`, `USER_IND_COLUMNS` - index information
- `USER_CONSTRAINTS`, `USER_CONS_COLUMNS` - constraints

**Oracle-Specific**
- Sequence-based auto-increment (`SELECT seq.nextval FROM dual`)
- `RETURNING INTO` clause for inserted row retrieval
- Advanced queuing (AQ) support
- Flashback queries
- Database links

## Deploy

[DBIO::Oracle::Deploy](https://metacpan.org/pod/DBIO::Oracle::Deploy) orchestrates test-deploy-and-compare:

1. Introspect live database via USER_* views ([DBIO::Oracle::Introspect](https://metacpan.org/pod/DBIO::Oracle::Introspect))
2. Deploy desired schema to a temporary tablespace
3. Introspect the temporary schema the same way
4. Diff source vs target ([DBIO::Oracle::Diff](https://metacpan.org/pod/DBIO::Oracle::Diff))

Install (`install_ddl`) creates fresh schema. Upgrade diffs live vs. desired.

## Testing

Requires a running Oracle instance:

```bash
export DBIO_TEST_ORA_DSN="dbi:Oracle:host=localhost;service_name=myapp"
export DBIO_TEST_ORA_USER=myapp
export DBIO_TEST_ORA_PASS=secret
prove -l t/
```

## Requirements

- Perl 5.36+
- [DBD::Oracle](https://metacpan.org/pod/DBD::Oracle)
- DBIO core

## See Also

[DBIO::Introspect::Base](https://metacpan.org/pod/DBIO::Introspect::Base), [DBIO::Diff::Base](https://metacpan.org/pod/DBIO::Diff::Base), [DBIO::Deploy](https://metacpan.org/pod/DBIO::Deploy)

## Repository

[https://codeberg.org/dbio/dbio-oracle](https://codeberg.org/dbio/dbio-oracle)
