# DBIO-Deprecated

Permanent home for CPAN redirect ("tombstone") stub modules covering
[DBIO](https://metacpan.org/pod/DBIO) modules that were renamed or retired.

PAUSE has no delete, and it indexes per **module name**, not per
distribution: once a module name is indexed against a release, it stays
there forever unless a *higher*-versioned release of that module name takes
it over -- whether the newer code lives in a different distribution or a
later release of the same one. When a DBIO module moves to a new
distribution, or is renamed/deleted within its own distribution's later
releases, the old name would otherwise keep resolving to stale, superseded
code with no hint a replacement exists. This distribution ships a tiny stub
package under each OLD name with a hand-set `$VERSION` higher than the last
release that shipped that name, taking over the PAUSE index entry. The stub
does nothing but `die` immediately on load with a message naming the
replacement (or saying plainly there is none).

## Current tombstones

From `dbio-mysql-ev` (old dist `DBIO-MySQL-Async`, last released `0.900000`):

| Old module | Redirects to |
|---|---|
| `DBIO::MySQL::Async` | `DBIO::MySQL::EV` |
| `DBIO::MySQL::Async::Pool` | `DBIO::MySQL::EV::Pool` |
| `DBIO::MySQL::Async::QueryExecutor` | `DBIO::MySQL::EV::QueryExecutor` |
| `DBIO::MySQL::Async::Storage` | `DBIO::MySQL::EV::Storage` |
| `DBIO::MySQL::Async::TransactionContext` | `DBIO::MySQL::EV::TransactionContext` |

From `dbio-postgresql-ev` (old dist `DBIO-PostgreSQL-Async`, last released `0.900000`):

| Old module | Redirects to |
|---|---|
| `DBIO::PostgreSQL::Async` | `DBIO::PostgreSQL::EV` |
| `DBIO::PostgreSQL::Async::ConnectInfo` | `DBIO::PostgreSQL::EV::ConnectInfo` |
| `DBIO::PostgreSQL::Async::Pool` | `DBIO::PostgreSQL::EV::Pool` |
| `DBIO::PostgreSQL::Async::Storage` | `DBIO::PostgreSQL::EV::Storage` |
| `DBIO::PostgreSQL::Async::TransactionContext` | `DBIO::PostgreSQL::EV::TransactionContext` |

From `dbio` core (dist `DBIO`):

| Old module | Redirects to |
|---|---|
| `DBIO::Test::Future` | `DBIO::Future::Immediate` |
| `DBIO::StartupCheck` | *(removed, no replacement)* |

From `dbio-dzil` (dist `Dist-Zilla-PluginBundle-DBIO`, same-distribution rename):

| Old module | Redirects to |
|---|---|
| `Dist::Zilla::Plugin::DBIO::SetCopyrightHolder` | `Dist::Zilla::Plugin::DBIO::SetMeta` |

## Adding a new tombstone

See the `dbio-deprecated` skill (`.claude/skills/dbio-deprecated/SKILL.md`)
for the step-by-step procedure the next time a DBIO module is renamed or
removed -- including how to audit the family for orphaned module names.

## License

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
