# DBIx::Class::MockData

Generate mock test data for any DBIx::Class schema.

## SYNOPSIS

```perl
use DBIx::Class::MockData;

# Connect your schema the normal DBIx::Class way
my $schema = MyApp::Schema->connect($dsn, $user, $pass);

# Minimal usage: deploy tables then insert rows
DBIx::Class::MockData
    ->new(
        schema     => $schema,
        schema_dir => 't/lib',
    )
    ->deploy
    ->generate;

# With options
my $mock = DBIx::Class::MockData->new(
    schema     => $schema,
    schema_dir => 't/lib',
    rows       => 10,
    verbose    => 1,
    seed       => 42,
);

$mock->wipe->generate;
```

## USAGE

```bash
dbic-mockdata \
  --schema-dir t/lib          \
  --namespace  MyApp::Schema  \
  --dsn        "dbi:SQLite:dbname=test.db" \
  --deploy --rows 10
```

## OPTIONS

| Option         | Description                                   | Default |
|----------------|-----------------------------------------------|---------|
| `--schema-dir` | Directory containing schema classes           |         |
| `--namespace`  | Top-level schema package name                 |         |
| `--dsn`        | DBI DSN string                                |         |
| `--user`       | Database username                             |         |
| `--password`   | Database password                             |         |
| `--rows`       | Rows per table                                | 5       |
| `--seed`       | Random seed for reproducible output           |         |
| `--deploy`     | Create missing tables                         |         |
| `--wipe`       | Drop and recreate all tables (destructive)    |         |
| `--dry-run`    | Print values without inserting                |         |
| `--verbose`    | Debug output                                  |         |

## HOW IT WORKS

1. Introspects all result sources from the schema
2. Resolves FK dependencies via topological sort
3. Inserts parent rows before child rows
4. Generates values from declared `data_type`
5. Salts unique/PK columns to avoid cross-run collisions

## GENERATED VALUES

| data_type                 | Value                              |
|---------------------------|------------------------------------|
| integer / serial          | random int (unique: salt+row_num)  |
| numeric / decimal / float | random decimal (2 d.p.)            |
| boolean                   | 0 or 1                             |
| datetime / timestamp      | random datetime 2020–2024          |
| date                      | random date 2020–2024              |
| time                      | random HH:MM:SS                    |
| uuid                      | random UUID-shaped string          |
| json / jsonb              | `{"generated":true,"row":N}`       |
| text / varchar / char     | contextual string by column name   |
| unknown / blank           | `colname_N` (or `colname_N_SALT`)  |

## INSTALLATION

```bash
perl Makefile.PL && make && make test && make install
```

The `dbic-mockdata` script is installed from `script/dbic-mockdata` and will
be available in your `PATH` after `make install`.

## LICENSE

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0).
