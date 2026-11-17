# Storage class details

Reference for `dbio-driver-development`.

### Composing cross-cutting Storage behaviour

When a driver needs cross-cutting Storage behaviour (LOB handling, savepoints,
identity/autoincrement, FK deferral, connect-time setup), put each concern in
its own module and compose it via **`use base`** (ISA) with C3 mro -- exactly
like `DBIO::Storage::DBI`'s own mixins and the Sybase driver:

```perl
package DBIO::DriverName::Storage;
use base qw/
  DBIO::DriverName::Storage::LOBSupport
  DBIO::DriverName::Storage::Savepoints
  DBIO::Storage::DBI
/;
use mro 'c3';
```

The role modules are plain packages (no `Exporter`); they define methods and
document in a comment what the consuming class must provide.

Roles are plain packages composed with `use base` and `use mro 'c3'`, so `next::method`
finds the next implementation: the package of a role's method is the role, and the role
sits in the class's MRO. (A sub imported by `use Role qw(method)` reports the role as its
package while the role is in no MRO; `$self->next::method(...)` then finds nothing.)

**Ordering matters:** a role that *overrides* a `DBIO::Storage::DBI` method
(e.g. an `_prep_for_execute` that adds behaviour then calls `next::method`)
must come **before** `DBIO::Storage::DBI` in the `use base` list, so its
override wins and its `next::method` chains forward to the base.

## DateTime Parsing

`datetime_parser_type` names a class providing `parse_datetime` /
`format_datetime` (class methods).

- DB has a maintained `DateTime::Format::<DB>` on CPAN → set it directly
  (Pg, MySQL, SQLite, Oracle, DB2 do this).
- No (or unmaintained) CPAN module → subclass the core fallback base
  `DBIO::Storage::DateTimeFormat`: declare strptime patterns, optionally
  prefer the CPAN module when it happens to be installed:

```perl
package DBIO::DriverName::DateTime::Format;
# ABSTRACT: DateTime parsing for DriverName
use base 'DBIO::Storage::DateTimeFormat';

__PACKAGE__->preferred_format_class('DateTime::Format::DriverName'); # optional
__PACKAGE__->datetime_parse_pattern('%Y-%m-%d %H:%M:%S.%3N');
__PACKAGE__->datetime_format_pattern('%Y-%m-%d %H:%M:%S.%3N');
__PACKAGE__->date_parse_pattern('%Y-%m-%d');    # optional, enables parse_date
__PACKAGE__->date_format_pattern('%Y-%m-%d');
```

Rules:
- The preferred CPAN class is used only when installed — cpanfile `suggests`,
  never `requires`. `DateTime::Format::Strptime` (the fallback engine) is only a
  `recommends` of core, loaded at the first parse/format, which throws when it
  is missing — core does not install it for the driver. A test that round-trips
  through the fallback patterns declares `DateTime` and
  `DateTime::Format::Strptime` under `on test` (dbio-mssql does).
- Fallback patterns MUST round-trip identically to the preferred class —
  contract-test BOTH paths (with and without the preferred class loadable).
- Never hand-roll a private strptime wrapper package inside Storage files.
