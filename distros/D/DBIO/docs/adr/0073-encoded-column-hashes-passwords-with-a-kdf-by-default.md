# ADR 0073 — EncodedColumn hashes passwords with a KDF by default

- Status: accepted (coordinator decision of 2026-10-29, karr k385, under the maintainer's order to resolve the security findings before the release)
- Date: 2026-10-29
- Tags: encoded-column, passwords, data-at-rest, tracing, changelog
- Supersedes the default of ADR 0063 (`encode_class` Digest)

## Context

`DBIO::EncodedColumn` is the component for passwords. ADR 0063 fixed what a
column declaration may say and which values are encoded; this ADR fixes with
which procedure a password is stored and what else follows from a column being
an encoded one.

## Decision

1. **`encode_class` names the procedure; the default is `Bcrypt`.**
   - `Bcrypt` writes Crypt::Bcrypt hashes, variant `2b`, `encode_args`
     `cost` (default 12).
   - `Argon2` writes Crypt::Argon2 argon2id hashes, `encode_args` `t_cost`,
     `m_cost`, `parallelism` (default: the library's recommended values).
   - `Digest` stays selectable for tokens and deduplication, with
     `algorithm` and `salt_length`.
   A class whose module is not installed throws from `register_column` when
   the schema is loaded and names the module. A check recognises `$2…$`,
   `$argon2id$` and `dbio$…`.
2. **A value enters every procedure as UTF-8 bytes**, on write and on check.
   Bcrypt refuses a value longer than 72 bytes or containing NUL, with a
   message pointing to `Argon2`; it never truncates.
3. **Digest allows SHA-256, SHA-384, SHA-512 and SHA3-\*.** MD5 and SHA-1 throw
   on write; stored `dbio$MD5$…` / `dbio$SHA-1$…` values remain checkable.
4. **`accept_unencoded` defaults to `0`.** With `1`, a successful comparison
   with an unencoded stored value writes the hash back (Rehash-on-Verify,
   `carp_unique`): an `UPDATE` of that column only, `WHERE` the primary key and
   the column still holding the compared value. A row that is not yet in the
   database gets the column value set only. The check method receives the
   column name for this.
5. **Randomness has one source:** `Crypt::URandom`, a `requires` of the
   distribution. Without it salt generation throws
   `no secure random source -- install Crypt::URandom`.
6. **Encoded columns carry `is_serializable => 0` and `changelog => 0`** unless
   the column definition says otherwise explicitly.
7. **Trace:** the bind attributes built from `column_info` mark the binds of
   `encode_column` columns; the default `redact_bind_value` shows a marked
   bind as `***`, without a fingerprint. This holds for join aliases, because
   the mark travels with the bind.

## Rationale

A password store needs a work factor; the procedure that has one is the
default, and the cheap digest is a named choice for values that are not
passwords. Marking the bind at the place where `column_info` is already
resolved means the redactor needs no knowledge of the source.

## Consequences

- A class that declares no `encode_class` needs `Crypt::Bcrypt`.
- Existing `dbio$SHA-256$…` rows stay valid for checks; migrating unencoded
  values uses `accept_unencoded => 1`.
- A column that should be serialized or logged says so explicitly.
