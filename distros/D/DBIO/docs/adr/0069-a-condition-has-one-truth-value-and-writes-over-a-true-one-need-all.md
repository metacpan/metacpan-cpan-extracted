# ADR 0069 — A condition has one truth value; update and delete over a true condition need `{ all => 1 }`

- Status: accepted (coordinator decision of 2026-10-30, karr k382, under the maintainer's order to resolve the security findings before the release)
- Date: 2026-10-30
- Tags: resultset, sqlmaker, conditions, update, delete, relates-0004

## Context

A condition is the first argument of `search` and the `where` of a
ResultSet. Its empty forms (`{}`, `[]`, `-and => []`, `-or => []`,
`-in => []`, `-not_in => []`) each stand for a truth value, and SELECT, UPDATE
and DELETE build their WHERE from the same condition. ADR 0004 put the
normalisation of the condition into the SQLMaker.

## Decision

### 1. Every node of a condition is TRUE, FALSE or SQL

The rule is recursive and the same for SELECT, UPDATE and DELETE.

| Node | Value |
|---|---|
| `{}`, `undef`, `-and => []`, `-and => {}`, `-not_in => []`, an `-and` group of TRUE nodes | TRUE |
| `[]` as a whole condition, `-or => []`, `-in => []`, an `-or` group of FALSE nodes | FALSE |

- In an `-and` group a FALSE member makes the group FALSE; TRUE members drop out.
- In an `-or` group a TRUE member makes the group TRUE; FALSE members drop out.
- A group left with no members is TRUE (`-and`) or FALSE (`-or`).

FALSE renders as `0=1`. TRUE is no restriction and renders no WHERE.

One function in `DBIO::SQLMaker` implements the rule: the group expansion
(`_expand_op_andor`) folds a group by its members, and the three WHERE clause
hooks (select, update, delete) drop a TRUE condition as a whole. The POD of
`search` states the rule.

### 2. Write statements over a TRUE condition need `{ all => 1 }`

`update`, `delete`, `update_all` and `delete_all` of a ResultSet whose
condition is TRUE throw:

    delete on an unrestricted resultset: pass { all => 1 }

(`update on ...`, `update_all on ...`, `delete_all on ...` accordingly.)

The release is given at the call and only there:

```perl
$rs->delete({ all => 1 });
$rs->update(\%set, { all => 1 });
```

`all` is the only key of the options hash; any other key throws. A ResultSet
with `rows` or `offset` is restricted (the statement runs over a subselect).
`{ all => 1 }` renders the statement as an unrestricted one is rendered.

The class call `Result->delete(\%cond)` takes no options: without a condition it
throws, and the whole table is deleted through the resultset
(`$rs->delete({ all => 1 })`).

### 3. Deliberate table-wide writes in core carry the release

Every place in core that changes a whole table on purpose passes
`{ all => 1 }`: the test helpers (`DBIO::Test::Conformance`,
`DBIO::Test::AsyncParity`) and the POD examples.

### 4. Collapsing a condition follows the same rule

`DBIO::Storage::QueryRewrite::_collapse_cond` folds a condition by the rule of
section 1: a FALSE part restricts and stays in the collapsed condition as
`-or => []` (rendered `0=1` by the SQLMaker, which folds it with the rest), a
TRUE part drops out, an `-or` group with a TRUE member is TRUE and collapses to
nothing. The collapsed condition renders the SQL of the original one.

### 5. The administration helper passes the release through

`DBIO::Admin` takes `all => 1` (`dbioadmin --all`) and hands `{ all => 1 }` to
`update_all` and `delete_all`. `update` and `delete` without a condition run
only with it and throw as the core does otherwise.

## Rationale

- **One reading of a condition.** An empty list of ids is FALSE whether it sits
  at the top, in a group or under a column, so SELECT, UPDATE and DELETE act on
  the same rows.
- **The release is visible where the statement is written.** A statement over
  the whole table is a decision of its call site.
