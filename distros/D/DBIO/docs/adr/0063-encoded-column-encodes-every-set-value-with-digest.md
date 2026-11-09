# ADR 0063 — EncodedColumn encodes every set value with Digest

- Status: accepted (maintainer decisions of 2026-10-10, karr k288)
- Date: 2026-10-12
- Tags: encoded-column, passwords, data-at-rest
- The default `encode_class` and the `accept_unencoded` default are set by ADR 0073.

## Context

`DBIO::EncodedColumn` stores `dbio$<algorithm>$<salt_b64>$<digest_b64>`. This ADR
fixes what a column declaration may say and which values the component encodes.

## Decision

1. **Only Digest.** `register_column` throws when the class is loaded for an
   `encode_class` other than `Digest`, an `encode_args` key other than
   `algorithm`, `salt_length`, `accept_unencoded`, an algorithm `Digest` cannot
   build, or a `salt_length` that is not a non-negative integer.
2. **The value names its algorithm.** A check uses exactly the algorithm in the
   value; one this installation cannot build is `0`.
3. **bcrypt is verified, not written.** A bcrypt hash gets into a column by
   import (`set_column`, a literal) and is checked with `Crypt::Bcrypt`
   (`bcrypt_check`), an optional dependency of the group `encoded_column`. Without
   the module the check throws and names it.
4. **The filter encodes what is set.** A defined value that is neither a reference
   nor a literal, set through the accessor, `new`, `create` or `update`, is
   encoded. A finished hash is imported through `set_column` or a literal
   (`\[ '?', $hash ]`), which the filter does not touch. `copy` takes the stored
   value as it is.
5. **Values without a hash format** are compared in constant time and answer `0`
   or `1`; `encode_args accept_unencoded => 0` switches matching them off. A value
   that claims a hash format and is not a valid one never matches.

## Rationale

The rule has no special case and matches DBIx::Class::EncodedColumn 0.11, which
encodes every defined value. Import is the explicit act, `set_column` or a
literal. `$row->password($row->password)` therefore encodes the stored value
again; leave the value unset, or use `set_column`.

## Consequences

- A class that declares another `encode_class`, `format`, `cost` or a misspelled
  algorithm does not load; existing `dbio$SHA-256$...` rows stay valid.
- Foreign formats (`DBIx::Class::EncodedColumn` hex digests, crypt
  `$1$`/`$5$`/`$6$`, `{SSHA}`) are not recognised and need their own decision.
