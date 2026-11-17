---
name: dbio-mysql-database
description: Use when you need MySQL or MariaDB specifics for driver work — DBD::mysql, storage engines, character sets, the MariaDB differences.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

MySQL/MariaDB for Perl DB driver development.

## DBD drivers

DBD::MariaDB (recommended in the cpanfile) and DBD::mysql (suggested) both talk to MySQL and MariaDB servers. Connection:
```perl
DBI->connect("dbi:MariaDB:database=mydb;host=localhost", $user, $pass)
DBI->connect("dbi:mysql:database=mydb;host=localhost", $user, $pass)
```
Attributes carry the DBD's prefix: `mariadb_*` on DBD::MariaDB, `mysql_*` on DBD::mysql (`DBIO::MySQL::Storage::_dbd_attribute` names them per handle). Critical flags: `mysql_enable_utf8mb4 => 1` (Unicode, DBD::mysql only; DBD::MariaDB has no such attribute), `mysql_auto_reconnect => 0` / `mariadb_auto_reconnect => 0` (transactions).

## MySQL vs MariaDB

| Feature | MySQL | MariaDB |
|---------|-------|---------|
| JSON type | Native `JSON` | Alias for `LONGTEXT` with `JSON_VALID` |
| CTEs | 8.0+ | 10.2+ |
| Window functions | 8.0+ | 10.2+ |
| Sequences | No | 10.3+ |
| System versioning | No | 10.3+ |
| CHECK constraints | Ignored (<8.0.16) | Enforced |
| RETURNING clause | No | 10.5+ |
| UUID type | No | 10.7+ |

Detection: `$storage->_is_mariadb` (product from `SELECT VERSION()`).

## Storage Engines

InnoDB = default, row-level locking, ACID, FK. MyISAM = legacy, table-lock, no transactions. MEMORY = temp, lost on restart. Aria = MariaDB crash-safe MyISAM replacement.

Always assume InnoDB for DBIO driver.

## Character Sets

`utf8mb4` only — MySQL's `utf8` is 3-byte broken. Connection: `SET NAMES utf8mb4`. Table: `CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci` — the driver's DDL names this collation on both servers, not the server default.

## Type System

Numeric: TINYINT(1), SMALLINT(2), MEDIUMINT(3), INT(4), BIGINT(8), DECIMAL, FLOAT, DOUBLE.
String: VARCHAR(65535), TEXT, MEDIUMTEXT(16MB), LONGTEXT(4GB), ENUM, SET, JSON(1GB).
Date: DATE, TIME, DATETIME, TIMESTAMP (1970-2038, UTC).

## Auto-Increment

`LAST_INSERT_ID()` per-connection. Perl: `$dbh->last_insert_id` or `$dbh->{mysql_insertid}` / `$dbh->{mariadb_insertid}`.

## Transactions & Locking

InnoDB: row-level locking, MVCC. `START TRANSACTION/COMMIT/ROLLBACK`. Savepoints: `SAVEPOINT sp` / `ROLLBACK TO sp` / `RELEASE SAVEPOINT sp`. `SELECT ... FOR UPDATE` (exclusive), `SELECT ... FOR SHARE` (shared, MySQL 8.0.1+) or `SELECT ... LOCK IN SHARE MODE` (shared, older MySQL and MariaDB). Deadlocks auto-detected.

## LIMIT/OFFSET

`LIMIT 10 OFFSET 20` and `LIMIT 20, 10` (offset first) are the same; the driver's rendering is in the `dbio-mysql` skill.

## Testing Env Vars

`DBIO_TEST_MYSQL_DSN`, `DBIO_TEST_MYSQL_USER`, `DBIO_TEST_MYSQL_PASS`; runs and live setup are in the `dbio-mysql` skill.
Docker: `mysql:8` or `mariadb:11`.
