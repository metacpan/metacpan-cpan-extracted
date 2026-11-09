# ADR 0006 — The text of an ASE error names no value

- Status: accepted (coordinator decision of 2026-11-02, under the maintainer's order to check every driver for values in error texts; core ADR 0075)
- Date: 2026-11-02
- Tags: storage, exceptions, bind-values, ase, cslib

## Context

Core's ADR 0075 keeps bind values out of an error text: the exception names
the statement in placeholder form and the number of its binds, and the base
`_mask_error_values` replaces the bound values of at least four characters
that the engine repeats. ASE and its client library write values in forms
the base cannot know:

- Msg 247/249 quote the value of a conversion, and the value the server made of
  it (a SMALLINT column given 3000000000 reports `INT value '-1294967296'`).
- The client library reports `to_numeric() failed for '12345.7'` (the value
  after its rounding) and, for a conversion it merely warns about,
  `cs_convert failed (to_money(x))` through `warn`, not an error.
- `Create unique index aborted on duplicate key.  Primary key is '"x"'` holds
  the key, which may hold line breaks.
- Values of fewer than four characters (`7`, `ab`, `300`) are never masked
  by the base.

A bulk insert, the TEXT/IMAGE writer and the warning do not pass through
core's error handler.

## Decision

1. `DBIO::Sybase::Util::mask_error_details($text, \@binds)` holds the
   sentences above. It replaces the value by `***`, keeps the words around it
   (type, column, constraint, table, message number), and also replaces each
   bound value of four characters or more found elsewhere in the text.
2. `DBIO::Sybase::Storage::ASE::_mask_error_values` calls it and then
   `next::method`. The hook is on the ASE class and therefore on everything
   that inherits from it (NoBindVars, the FreeTDS class, the writer and bulk
   storages). It is not on `DBIO::Sybase::Storage`, which
   `DBIO::MSSQL::Storage::Sybase` shares: the sentences of Microsoft SQL Server
   are that distribution's to decide.
3. The ways around core's handler go through the hook: the cslib callback and
   the final exception of the bulk insert (values of the rows), the errstr
   of the TEXT/IMAGE calls (key values and content), and the `cs_convert
   failed` warning, which `_execute_sth` hands to the caller's `__WARN__`
   handler with the bound values of the statement (`ParamValues`) masked.
   Every other warning passes unchanged.
4. A message the driver writes itself names key columns, not key values (the
   TEXT/IMAGE writer's "Could not find row ...").

## Rationale

The rule is the family's: logs and applications read these texts. A rule is
one sentence of the engine; a value is not escaped in it and may hold quotes,
commas, colons or line breaks, so each rule ends the value at the last place
its sentence can end, and where that is uncertain it masks more.

## Consequences

- `$dbh->errstr` and `$sth->errstr` keep the engine's text (core ADR 0075,
  item 11). A caller's `syb_err_handler` receives the raw message; it is the
  caller's.
- Names (table, column, constraint, index) are not masked.
- A sentence of ASE this list does not know is passed on as it is, with the
  bound values of four characters or more masked by core. A new sentence is a
  new rule in `Util.pm` and a case in `t/119` and `t/120`.
- What the client library reports differs: over FreeTDS an INT overflow, an
  unsigned value and `'ab'` for an INT are converted on the client without any
  message. `t/120` tests what arrives on the library it runs with.
