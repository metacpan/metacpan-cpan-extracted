---
name: dbio-mysql-database
description: "MySQL and MariaDB knowledge for Perl driver development (DBD::mysql, storage engines, charset, MariaDB differences)"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

MySQL/MariaDB for Perl DB driver development.

## DBD::mysql

Handles both MySQL and MariaDB. Connection:
```perl
DBI->connect("dbi:mysql:database=mydb;host=localhost", $user, $pass)
```
Critical flags: `mysql_enable_utf8mb4 => 1` (Unicode), `mysql_auto_reconnect => 0` (transactions).

## MySQL vs MariaDB

| Feature | MySQL | MariaDB |
|---------|-------|---------|
| JSON type | Native `JSON` | Alias `LONGTEXT` (<10.5) |
| CTEs | 8.0+ | 10.2+ |
| Window functions | 8.0+ | 10.2+ |
| Sequences | No | 10.3+ |
| System versioning | No | 10.3+ |
| CHECK constraints | Ignored (<8.0.16) | Enforced |
| RETURNING clause | No | 10.5+ |
| UUID type | No | 10.7+ |

Detection: `($version =~ /MariaDB/i)`

## Storage Engines

InnoDB = default, row-level locking, ACID, FK. MyISAM = legacy, table-lock, no transactions. MEMORY = temp, lost on restart. Aria = MariaDB crash-safe MyISAM replacement.

Always assume InnoDB for DBIO driver.

## Character Sets

`utf8mb4` only — MySQL's `utf8` is 3-byte broken. Connection: `SET NAMES utf8mb4`. Table: `CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci` (MySQL 8.0+) or `utf8mb4_general_ci` (MariaDB default).

## Type System

Numeric: TINYINT(1), SMALLINT(2), MEDIUMINT(3), INT(4), BIGINT(8), DECIMAL, FLOAT, DOUBLE.
String: VARCHAR(65535), TEXT, MEDIUMTEXT(16MB), LONGTEXT(4GB), ENUM, SET, JSON(1GB).
Date: DATE, TIME, DATETIME, TIMESTAMP (1970-2038, UTC).

## Auto-Increment

`LAST_INSERT_ID()` per-connection. Perl: `$dbh->last_insert_id` or `$dbh->{mysql_insertid}`.

## Transactions & Locking

InnoDB: row-level locking, MVCC. `START TRANSACTION/COMMIT/ROLLBACK`. Savepoints: `SAVEPOINT sp` / `ROLLBACK TO sp` / `RELEASE SAVEPOINT sp`. `SELECT ... FOR UPDATE` (exclusive), `SELECT ... LOCK IN SHARE MODE` (shared). Deadlocks auto-detected.

## LIMIT/OFFSET

```sql
SELECT * FROM t LIMIT 10 OFFSET 20;
SELECT * FROM t LIMIT 20, 10;  -- offset, count (MySQL-specific order!)
```

## Testing Env Vars

`DBIO_TEST_MYSQL_DSN`, `DBIO_TEST_MYSQL_USER`, `DBIO_TEST_MYSQL_PASS`.
Docker: `mysql:8` or `mariadb:11`.
