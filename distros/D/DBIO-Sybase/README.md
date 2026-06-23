# DBIO::Sybase

Sybase/ASE database driver for DBIO (fork of DBIx::Class).

## Supports

- desired-state deployment via test-deploy-and-compare ([DBIO::Sybase::Deploy](https://metacpan.org/pod/DBIO::Sybase::Deploy))
- native introspection ([DBIO::Sybase::Introspect](https://metacpan.org/pod/DBIO::Sybase::Introspect))
- native diff ([DBIO::Sybase::Diff](https://metacpan.org/pod/DBIO::Sybase::Diff))
- native DDL generation ([DBIO::Sybase::DDL](https://metacpan.org/pod/DBIO::Sybase::DDL))

## Usage

    package MyApp::DB;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('Sybase');

    my $schema = MyApp::DB->connect('dbi:Sybase:database=myapp');

DBIO core autodetects `dbi:Sybase:` DSNs and loads this storage automatically.

## Sybase Features

**Types**
- `INT`, `BIGINT`, `SMALLINT`, `TINYINT` - numeric types
- `VARCHAR`, `CHAR`, `TEXT` - string types
- `BINARY`, `VARBINARY`, `IMAGE` - binary types
- `DATE`, `TIME`, `DATETIME`, `DATETIME2` - temporal types
- `DECIMAL`, `NUMERIC` - fixed-point numeric

**Schema Support**
- `sysobjects`, `syscolumns` for introspection
- Identity columns for auto-increment
- Sybase-specific stored procedure language

**Introspection (sysobjects, syscolumns)**
- `sysobjects` - table metadata
- `syscolumns` - column metadata
- `sysindexes` - index information
- `sysreferences` - foreign key constraints

**Sybase-Specific**
- `SET IDENTITY_INSERT` for explicit identity insertion
- `@@IDENTITY` for inserted row retrieval
- Text/image data handling
- Server-level configuration

## Deploy

[DBIO::Sybase::Deploy](https://metacpan.org/pod/DBIO::Sybase::Deploy) orchestrates test-deploy-and-compare:

1. Introspect live database via sysobjects ([DBIO::Sybase::Introspect](https://metacpan.org/pod/DBIO::Sybase::Introspect))
2. Deploy desired schema to a temporary database
3. Introspect the temporary database the same way
4. Diff source vs target ([DBIO::Sybase::Diff](https://metacpan.org/pod/DBIO::Sybase::Diff))

Install (`install_ddl`) creates fresh schema. Upgrade diffs live vs. desired.

## Testing

Requires a running Sybase/ASE instance:

```bash
export DBIO_TEST_SYBASE_DSN="dbi:Sybase:database=myapp"
export DBIO_TEST_SYBASE_USER=sa
export DBIO_TEST_SYBASE_PASS=secret
prove -l t/
```

## Requirements

- Perl 5.36+
- [DBD::Sybase](https://metacpan.org/pod/DBD::Sybase)
- DBIO core

## See Also

[DBIO::Introspect::Base](https://metacpan.org/pod/DBIO::Introspect::Base), [DBIO::Diff::Base](https://metacpan.org/pod/DBIO::Diff::Base), [DBIO::Deploy](https://metacpan.org/pod/DBIO::Deploy)

## Repository

[https://codeberg.org/dbio/dbio-sybase](https://codeberg.org/dbio/dbio-sybase)
