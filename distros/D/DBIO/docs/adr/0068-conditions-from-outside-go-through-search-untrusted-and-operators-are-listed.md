# ADR 0068 — A condition from outside goes through `search_untrusted`; operator names are a symbol or a listed word

- Status: accepted (coordinator decision of 2026-10-30, karr k378, under the maintainer's order to resolve the security findings before the release)
- Date: 2026-10-30
- Tags: resultset, sqlmaker, conditions, relates-0004, relates-0069

## Context

The structure of a condition — its keys, its operators and its hashes — is code
(`-literal`, `-func`, `-op` and an operator key are rendered as SQL). Values are
binds and identifiers are quoted. A program writes the structure and takes
values from a request. A condition whose structure is not written in the
program needs its own entry.

## Decision

### 1. The structure of a condition is code

The POD of `search` and `DBIO::Manual::Features` state it in a section
*Untrusted input*: keys, operators and hashes of a condition are written in the
program, a request supplies values. The same holds for every attribute
(`order_by`, `columns`, `having`, `result_class`, ...). The section points to
`search_untrusted`.

### 2. `search_untrusted(\%cond)`

A ResultSet method (not an attribute) with exactly one argument, an unblessed
hash or array reference. It walks the condition with two grammars and calls
`search` with the condition unchanged.

**Condition node.** A hashref (key → operand) or an arrayref of condition
nodes (OR). `-and` and `-or` take an arrayref or hashref of condition nodes,
recursively. A scalar as an element of a condition, a blessed container and a
cycle throw.

**Key.** A column of the source, or `alias.column` where the column is checked
against the source of exactly that alias in the resolved attributes
(`_resolved_attrs`) of the ResultSet.

**Operand.** One of

- a scalar (`undef` included),
- an arrayref of scalars (a list of values, an OR of equalities),
- a hashref with exactly one operator of `=`, `!=`, `<>`, `<`, `<=`, `>`,
  `>=`, `-like`, `-not_like`, `-in`, `-not_in`, `-between`, `-not_between`,
  `-is`, `-is_not`.

| Operator | Operand |
|---|---|
| `-in`, `-not_in` | arrayref of scalars |
| `-between`, `-not_between` | arrayref of exactly two scalars |
| `-is`, `-is_not` | `undef` |
| all others | a scalar |

Every other form throws with the path of its key: `-literal`, `-func`, `-op`,
`-ident`, `-value`, `-bool`, `-not` and every reference as a value (scalar
ref, ref ref, code ref, object). SQL::Abstract is not changed.

### 3. Operator names are a symbol or a listed word

`DBIO::SQLMaker` checks the operator of `{ column => { OPERATOR => value } }` at
its raw name, before a prefix is cut off (for `->` and `->>` the minus belongs
to the operator).

- **Word operators** are the entries of `DBIO::SQLMaker->operator_words`: like,
  not like, ilike, not ilike, in, not in, between, not between, is, is not,
  similar to, not similar to, regexp, not regexp, rlike, not rlike, and the
  operators SQL::Abstract knows as special operators. Case does not matter,
  `_` equals a space, a leading `-` is allowed.
- **Symbol operators** consist of the characters `+ - * / < > = ~ ! @ # % ^ & |`
  `` ` `` `?` and hold neither `--` nor `/*`.
- Anything else throws and names the operator.
- The rule holds at the raw name for both forms of an operator: the key in
  `{ column => { OPERATOR => value } }` and the first element of
  `-op => [ OPERATOR, ... ]`. The names the generator renders itself
  (`is_null`, `not`, `,`, ...) are its own and pass.
- A numeric suffix that SQL::Abstract cuts off (`-like_1`) is cut off before
  the check: the name without the suffix is the name that is checked.
- `attempted`, the marker of the upsert condition (ADR 0036), is a word of
  the list.

`operator_words` is a class method and the seam of a driver: a driver
SQLMaker returns the list of its parent plus its own words. The contract
version of `DBIO::SQLMaker` is 1.3 (ADR 0024).

## Rationale

- **One place for each decision.** The walker decides which structures an
  outside condition may have; the operator check decides which names an
  operator may have, for every condition.
- **A list the driver extends.** The core list holds the standard words; an
  engine with further words adds them where it renders them.
- **Symbols are a grammar.** Driver operators such as `@>`, `?|`, `->>` and
  `<->` need no entry.
