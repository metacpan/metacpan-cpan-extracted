# ADR 0077 — Schema, extension and library names are identifiers

- Status: accepted (coordinator decision of 2026-10-30, karr k391, under the maintainer's order to resolve the security findings before the release)
- Date: 2026-10-30
- Tags: driver-contract, conformance, extension, connect-key-schema
- Relates to: ADR 0060 (conformance), ADR 0065 (connect key `schema`), ADR 0066 (extensions)

## Context

Three names reach a driver from the application and end up in a statement of
the engine: the namespace the connect key `schema` names (ADR 0065), the name
of a database extension of the declared list, and the name of a library an
extension loads (ADR 0066 activation). Core hands them over as data; what the
engine's statement looks like is the driver's.

## Decision

### 1. The three names are identifiers

A schema name, an extension name and a library name are identifiers. A driver
writes each into a statement only through its identifier quoting (or as a
bind), or refuses it with a `DBIO::Exception`. It does not build a statement
by joining the name into the text. The contract is stated in the POD of
`DBIO::Storage::DBI::_set_connection_schema`, `DBIO::Extension::Protocol` and
`DBIO::Test::StorageLayer`.

### 2. Core refuses what no driver takes

Core refuses a name that contains `;`, a line break (`\n`), a carriage return
or NUL, with a `DBIO::Exception` that names the key or option and never the
value. The check is `DBIO::Util::assert_identifier_text($what, $name)`. It is
made at:

- the connect key `schema` (`DBIO::Storage::DBI::_assert_connection_schema_name`),
- the extension names and the option `schema` of an extension in
  `DBIO::Extension::List`,
- the library names (`load`) and the `search_path` names of an activation in
  `DBIO::Extension::Protocol`.

Every other name (a double quote, a blank, a backslash, any other character)
is the driver's: it quotes it or refuses it.

### 3. The Names list of the conformance table

`DBIO::Test::Conformance` has the list `Names` (table version 1), cases
`name-<kind>-<name>` for the kinds `schema`, `extension` and `library`, each
with a plain name and with `a"b`, `a;b`, `a b`, a backslash name and a name
with a line break. There are two answers: the driver sets the name and
introspection shows it as given, or the driver refuses with a
`DBIO::Exception`. An error of the server (`DBIO::Exception::Server`), another
name on the server, or an exception that is not a `DBIO` exception fails the
case.

A driver declares the kinds its engine has with `conformance_name_kinds`; a
case of a kind it does not declare is not applicable (`na`). The driver does
one case in `conformance_apply_name($kind, $name)`: it connects, sets the
name, reads it back through introspection, cleans up and returns the name read
back. The list has no refusal declarations; a refusal is an answer.

## Rationale

- **A name is one thing.** The three names are the same kind of value, so one
  contract, one core check and one list of cases hold for all of them.
- **The driver knows its quoting.** Which characters an engine takes in an
  identifier differs per engine, so core refuses only what ends a statement in
  every engine and leaves the rest to the driver's quoting.
- **A case table states it once.** The expectation "set and readable, or
  refused" is the same for every driver, and every driver answers it.

## Consequences

- `DBIO::Util` exports `assert_identifier_text`.
- `DBIO::Test::Conformance` knows the area `Names`; the status `na` marks a
  kind the driver does not declare. A driver that has not raised
  `conformance_answered_through` for `Names` stays green outside
  `AUTHOR_TESTING` and `RELEASE_TESTING` (the cases run as `TODO`).
- A driver with namespaces, extensions or libraries declares the kinds and
  provides `conformance_apply_name` in its `DBIO::<Driver>::Test::Conformance`.
