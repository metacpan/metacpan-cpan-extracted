---
name: dbio-mysql
description: "DBIO::MySQL driver — MySQL/MariaDB storage, SQLMaker, capabilities, deploy, introspect"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO MySQL/MariaDB driver. Follows dbio-driver-development conventions.

## Components

| Component | Class |
|-----------|-------|
| MySQL schema | `DBIO::MySQL` |
| MariaDB schema | `DBIO::MySQL::MariaDB` |
| MySQL storage | `DBIO::MySQL::Storage` |
| MariaDB storage | `DBIO::MySQL::Storage::MariaDB` |
| SQLMaker | `DBIO::MySQL::SQLMaker` |
| Deploy | `DBIO::MySQL::Deploy` |

## Storage Registration

`DBIO::MySQL::Storage->register_driver('mysql' => __PACKAGE__)` — DBD auto-detect.

`DBIO::MySQL::MariaDB` sets `storage_type('+DBIO::MySQL::Storage::MariaDB')`.

## Key Storage Methods

| Method | Description |
|--------|-------------|
| `dbio_deploy_class` | Returns `DBIO::MySQL::Deploy` |
| `sql_maker_class` | `DBIO::MySQL::SQLMaker` |
| `sql_quote_char` | `` ` `` (backtick) |
| `datetime_parser_type` | `DateTime::Format::MySQL` |
| `_use_multicolumn_in(1)` | Multi-column IN supported |
| `sqlt_type` | `'MySQL'` |
| `deploy_defaults` | `add_drop_table => 1` (MySQL no transactional DDL) |
| `deploy_setup` | Strip `NO_ZERO_DATE`/`NO_ZERO_IN_DATE` from sql_mode |
| `with_deferred_fk_checks` | `SET FOREIGN_KEY_CHECKS = 0/1` |
| `_dbh_last_insert_id` | `$dbh->{mysql_insertid}` |
| `_random_function` | `'RAND()'` |

## Auto-Reconnect

Disabled by default (silent transaction loss). Override: pass `mysql_auto_reconnect => 1` in connect attrs.

## Strict Mode

```perl
$schema->connect($dsn, $user, $pass, { on_connect_call => 'set_strict_mode' });
```
Sets `ANSI,TRADITIONAL,ONLY_FULL_GROUP_BY` sql_mode, disables `SQL_AUTO_IS_NULL`.

## SQLMaker: apply_limit

MySQL LIMIT syntax: `LIMIT offset, rows` (offset first, count second).

```sql
SELECT * FROM t LIMIT 20, 10  -- offset=20, rows=10
```

## Double-Subquery Hack

MySQL prohibits referencing the modification target in a subquery. `_prep_for_execute` detects UPDATE/DELETE self-reference and wraps in double subquery via `_modification_target_referenced_re`.

## Insert with no columns

MySQL uses `INSERT INTO t () VALUES ()` — not `DEFAULT VALUES`.

## MariaDB Detection

```perl
my $is_mariadb = ($version =~ /MariaDB/i);
```

## Testing

`DBIO_TEST_MYSQL_DSN`, `DBIO_TEST_MYSQL_USER`, `DBIO_TEST_MYSQL_PASS`.
SQLMaker tests: `DBIO::Test->init_schema(storage_type => 'DBIO::MySQL::Storage')`.
