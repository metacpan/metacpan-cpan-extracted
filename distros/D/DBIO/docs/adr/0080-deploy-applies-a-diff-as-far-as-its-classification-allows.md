# ADR 0080 — The deploy applies a diff as far as its classification allows; destructive changes need `allow_destructive`

- Status: accepted (coordinator decision of 2026-10-30, karr k399, under the maintainer's order to resolve the security findings before the release)
- Date: 2026-10-30
- Tags: deploy, diff, admin, relates-0060, relates-0024

## Context

A diff holds operations, and `DBIO::Diff::Base::classify` (ADR 0060) sorts them
into additive, changing and destructive and lists the operations the diff
refuses. `DBIO::Deploy::Base` applies a diff (`apply`, `upgrade`), and
`DBIO::Admin` and `dbioadmin` run it from the command line.

## Decision

### 1. `apply` is the one place that reads the classification

`DBIO::Deploy::Base::apply` calls `classify` before the first statement.
`upgrade` is `diff` plus `apply`: it hands its arguments on to the same rule.
Nothing else in core executes a diff.

| The diff holds | `apply` |
|---|---|
| a refusal (`class` is undef, `refused` is not empty) | throws, always |
| a destructive operation, or an operation whose optional method `lossy` is true | runs with `allow_destructive => 1`, else throws |
| additive and changing operations | runs |

The exception is a `DBIO::Exception`. It names the `summary` of each operation
that refuses or needs the release, never a value, and it is thrown before the
first statement.

### 2. The release is `allow_destructive`

`allow_destructive => 1` is an attribute of the Deploy object (`new`, and the
setter `allow_destructive`) and an argument of `apply` and `upgrade`; an
argument given stands in for the attribute. It releases destructive and lossy
operations. It does not release a refusal, the model of the diff or the
extension protocol (ADR 0066): those keep their say.

### 3. `lossy` is an optional operation method

An operation may define `lossy`; true means the change it writes can lose or
alter stored data without being a drop (a column type change whose cast rounds
or truncates). An operation without the method is not lossy.
`DBIO::Diff::Base::destructive_operations` returns the operations that need the
release: the destructive ones of `classify` and the lossy ones. `classify`
keeps the class of an operation's `action`. Core ships the contract; a driver's
operation that knows a type change defines `lossy`.

### 4. `dry_run => 1`

`apply($diff, dry_run => 1)` and `upgrade(dry_run => 1)` execute nothing and
return the diff (false for a diff without changes). The caller reads
`$diff->as_sql`, `$diff->summary` and `$diff->classify`.

### 5. The administration helper asks

`DBIO::Admin::upgrade` takes the diff of the native deploy, lists the
`summary` of its destructive operations and asks for `YES` on STDIN, the
question `update` and `delete` ask. `force` (`dbioadmin --force`) answers it.
`dry_run` (`dbioadmin --dry-run`) prints the summary and the SQL and runs
nothing. A refusal goes to `apply` without a question and throws.
`DBIO::DeploymentHandler::upgrade` takes `{ allow_destructive => 1 }` and hands
it to the deploy.

### 6. Contract version

`DBIO::Diff::Base` and `DBIO::Deploy::Base` are at contract version 1.3
(ADR 0024): `destructive_operations`, the optional operation method `lossy`,
the arguments of `apply` and `upgrade`, and the attribute `allow_destructive`.
The two hooks of section 7 are new seams of `Deploy::Base` at the same
version.

### 7. Drivers take part through two hooks

`apply` and `upgrade` of `DBIO::Deploy::Base` are the entry points of every
driver's deploy class, and the driver class inherits both. `apply($diff, %opts)`
checks the options (`allow_destructive`, `dry_run`; any other name throws and is
named), returns for a diff without changes, returns the diff for `dry_run`
(nothing is executed or read from the live database), runs the guard of
section 1, then calls two hooks in this order:

- `_check_before_apply($diff)` holds the driver's checks of the diff against the
  live tables and throws a `DBIO::Exception` to stop the run. The default does
  nothing.
- `_execute_diff($diff)` executes the diff and returns true. The default renders
  `as_sql`, asks the extension protocol for refusals and hands the statements to
  `_execute_ddl`. A driver with its own execution (a table rebuild, statements
  after the DDL, a reorganisation before a column change) overrides this hook.

`upgrade(%opts)` is `diff` plus `apply($diff, %opts)`. The attribute
`allow_destructive` is the standing release; the argument of the call stands in
for it. `DBIO::Admin::upgrade` takes the diff, lists the destructive operations,
asks, and calls `apply($diff, allow_destructive => ...)`.

### 8. `column_change_lossy`

`DBIO::Diff::Compare::column_change_lossy(\%old, \%new, \%lossless_pairs)`
answers `lossy` for a column change. The change is lossless when the normalized
`data_type` is the same and every component of `size` (a number, `"p,s"` or an
array reference) is at least the live one with the scale equal, or when
`"old->new"` is a key of `\%lossless_pairs` (`integer->bigint`). Every other
change is lossy. The column-change operation of a driver defines `lossy` through
this function.

### 9. Conformance

The Diff list of `DBIO::Test::Conformance` (table version 4) holds three deploy
cases: the deploy class inherits `apply` and `upgrade` from `Deploy::Base` (the
same code reference); `apply($diff, dry_run => 1)` executes nothing; a diff with
a drop throws before the first statement without `allow_destructive` and runs
with it. A driver runs them through the optional seam `conformance_deploy`,
which returns its deploy object over the connected target schema; the default
returns undef and the cases are `na`.

## Rationale

- **The diff is read where it is executed.** A destructive operation shows in
  `summary` before it runs, so the run asks for it at the same moment.
- **One release, one name.** The call site that destroys data says so.
- **A refusal has no release.** An operation the diff cannot write safely does
  not run, whoever asks.
