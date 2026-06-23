# DBIO::MSSQL

Microsoft SQL Server database driver for DBIO (fork of DBIx::Class).

## Supports

- desired-state deployment via test-deploy-and-compare ([DBIO::MSSQL::Deploy](https://metacpan.org/pod/DBIO::MSSQL::Deploy))
- native introspection ([DBIO::MSSQL::Introspect](https://metacpan.org/pod/DBIO::MSSQL::Introspect))
- native diff ([DBIO::MSSQL::Diff](https://metacpan.org/pod/DBIO::MSSQL::Diff))
- native DDL generation ([DBIO::MSSQL::DDL](https://metacpan.org/pod/DBIO::MSSQL::DDL))

## Usage

    package MyApp::DB;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('MSSQL');

    my $schema = MyApp::DB->connect('dbi:MSSQL:database=myapp');

DBIO core autodetects `dbi:MSSQL:` DSNs and loads this storage automatically.

## MSSQL Features

**Types**
- `INT`, `BIGINT`, `SMALLINT`, `TINYINT` - numeric types
- `VARCHAR`, `CHAR`, `NVARCHAR`, `NTEXT` - string types
- `BLOB`, `VARBINARY`, `IMAGE` - binary types
- `DATE`, `TIME`, `DATETIME`, `DATETIME2` - temporal types
- `DECIMAL`, `NUMERIC`, `MONEY` - fixed-point numeric
- `BIT` - boolean type

**Schema Support**
- `INFORMATION_SCHEMA` for standard introspection
- `sys.tables`, `sys.columns` for MSSQL-specific metadata
- Identity columns for auto-increment

**Introspection (INFORMATION_SCHEMA + sys)**
- `INFORMATION_SCHEMA.TABLES` - table metadata
- `INFORMATION_SCHEMA.COLUMNS` - column metadata
- `sys.indexes`, `sys.index_columns` - index information
- `sys.foreign_keys` - constraint information

**MSSQL-Specific**
- `OUTPUT INSERTED.*` for inserted row retrieval
- `SET IDENTITY_INSERT` for explicit identity insertion
- Window functions (`ROW_NUMBER()`, `RANK()`, etc.)
- CTEs (`WITH` clause) for complex queries

## Deploy

[DBIO::MSSQL::Deploy](https://metacpan.org/pod/DBIO::MSSQL::Deploy) orchestrates test-deploy-and-compare:

1. Introspect live database via INFORMATION_SCHEMA ([DBIO::MSSQL::Introspect](https://metacpan.org/pod/DBIO::MSSQL::Introspect))
2. Deploy desired schema to a temporary database
3. Introspect the temporary database the same way
4. Diff source vs target ([DBIO::MSSQL::Diff](https://metacpan.org/pod/DBIO::MSSQL::Diff))

Install (`install_ddl`) creates fresh schema. Upgrade diffs live vs. desired.

## Testing

```bash
export DBIO_TEST_MSSQL_DSN="dbi:MSSQL:database=myapp"
export DBIO_TEST_MSSQL_USER=sa
export DBIO_TEST_MSSQL_PASS=secret
prove -l t/
```

For ODBC connections:

```bash
export DBIO_TEST_MSSQL_ODBC_DSN="dbi:ODBC:Driver={SQL Server};Server=localhost;Database=myapp"
export DBIO_TEST_MSSQL_ODBC_USER=sa
export DBIO_TEST_MSSQL_ODBC_PASS=secret
prove -l t/
```

## Requirements

- Perl 5.36+
- [DBD::MSSQL](https://metacpan.org/pod/DBD::MSSQL) or [DBD::ODBC](https://metacpan.org/pod/DBD::ODBC)
- DBIO core

## See Also

[DBIO::Introspect::Base](https://metacpan.org/pod/DBIO::Introspect::Base), [DBIO::Diff::Base](https://metacpan.org/pod/DBIO::Diff::Base), [DBIO::Deploy](https://metacpan.org/pod/DBIO::Deploy)

## Repository

[https://codeberg.org/dbio/dbio-mssql](https://codeberg.org/dbio/dbio-mssql)
