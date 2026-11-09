# ADR 0062 — A statement the server refused fails its Future with an object that carries the SQLSTATE

- Status: accepted (maintainer decision 2026-10-09, dbio-postgresql-ev k74 option (b)); the BEGIN/COMMIT/ROLLBACK and synchronous-path questions decided 2026-10-12
- Date: 2026-10-10
- Tags: async, future, errors, contract, transport, addendum-to-0030, relates-0031, relates-0055

## Context

The Future of a statement the server refused failed with exactly one string. The
SQLSTATE stood only in the connection's own error fields, out of the caller's
reach. A `statement_timeout` abort (57014) arrives as text, and with
`lc_messages=de_DE` as German text, so a caller that must tell 40001, 40P01,
23505 and 57014 apart could not do it without parsing a locale-dependent
message (dbio-postgresql-ev k74).

What core carried for this: `DBIO::Exception` holds `{msg}` and nothing else, and
the synchronous path raises it from `Storage::DBI`'s `HandleError` handler as
`throw_exception("DBI Exception: $_[0]")` -- text only, `$h->state` is not read.
So there was no SQLSTATE anywhere in core to extend; the async contract had no
shape for an error beyond "a value the Future failed with".

## Decision

1. **The class.** `DBIO::Exception::Server`, a subclass of `DBIO::Exception`:
   one new thing beside it, not a second exception system. Constructor
   `DBIO::Exception::Server->new(message => $text, sqlstate => ..., constraint =>
   ..., table => ..., detail => ...)`; `message` is required (and true), the four
   fields are optional and `undef` when not given, unknown arguments are refused.
   Accessors `sqlstate`, `constraint`, `table`, `detail`. It adds no further field:
   no transport has one today.
2. **Text.** It stringifies to `message` -- the text the string had, untouched,
   no caller decoration -- through the overload `DBIO::Exception` already has.
   `eq`, `=~` and `like` behave as for the string.
3. **What a transport does.** Fails the Future with this object, as the one error,
   wherever the server refused a statement. Errors that are not the server's --
   a dropped connection, a client-side timeout -- stay what they were. A
   transport that never builds the object keeps working; core requires nothing.
4. **What core does.** Hands the object on as the same object (`refaddr` equal)
   through the places that carry a failure: statement Futures, `txn_do_async`
   (returned, awaited, unawaited, handled, thrown by the coderef), the context's
   `pipeline`, `Future::Immediate` and `Test::Future`. This needed no change in
   those places: they pass `$_[0]` on. It is pinned by
   `t/test/59_async_failure_object.t`, since a later change that stringifies at
   one of them would otherwise be silent.
5. **`DBIO::Future->validate`** is unchanged. It checks methods; what a Future
   is failed with is a value, with nothing on the class to probe. The shape is
   documented in `DBIO::Future` ("WHAT A TRANSPORT FAILS WITH") and
   `DBIO::Storage::Async/txn_do_async`.

## Consequences

- A driver (dbio-postgresql-ev k74 first) builds the object from its error
  fields and fails the Future with it; that is its own ticket.
- Code that tests `ref $error` for "an object that is not a string" now meets
  an object where it met a string. The class is a `DBIO::Exception`, as every
  other core exception is.

## Prefixed failures and the synchronous path

Decided by the maintainer 2026-10-12.

6. **`BEGIN`, `COMMIT`, `ROLLBACK`.** Where core puts the step's name in front
   of an error, a `DBIO::Exception::Server` stays an object. The caller gets a
   derived copy -- same class, `sqlstate`, `constraint`, `table` and `detail`
   unchanged -- with the optional field `context` set to `BEGIN`, `COMMIT` or
   `ROLLBACK`, and with the prefixed text as its message, so `$@ =~ /COMMIT
   failed/` and `eq` hold as they did. `with_context($context, $message)` makes
   the copy; it is not the object the transport failed with (`refaddr` differs),
   and the transport's object is not touched. An error that is no such object
   stays the string it was. For `Transaction aborted: $e. Rollback failed: $r`
   the object is the ROLLBACK's own failure `$r`, as a copy carrying that text and
   context `ROLLBACK`; with a string `$r` it stays the `DBIO::Exception` it was.
7. **The synchronous path.** `Storage::DBI`'s `HandleError` handler is the method
   `_dbi_handle_error`. It still goes through `throw_exception` with
   `DBI Exception: $msg` -- so the decorated text and the schema's
   `exception_action` are untouched -- and a plain `DBIO::Exception` that comes
   out is made a `DBIO::Exception::Server` of that text; any other object
   (an `exception_action`'s own) is left alone. `sqlstate` is the handle's
   `state`; DBI's "none" (`''`, `00000`, `S1000`) leaves it `undef`. The seam
   `_dbi_error_fields($handle)` answers the fields and is where a driver whose
   DBD names the constraint, table or detail adds them (`next::method` and more
   keys); the base reports `sqlstate` only. This holds for every driver of core,
   not only PostgreSQL. `TxnScopeGuard` treats the class like `DBIO::Exception`
   when it appends a failed rollback to the exception in flight.

