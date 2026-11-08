---
name: dbio-perl-pod
description: Use when writing or editing POD in a DBIO distribution — # ABSTRACT, =attr/=method/=seealso, what PodWeaver generates.
user-invocable: false
---

# POD under `[@DBIO]`

`# ABSTRACT:` required on every .pm. `=attr name` after
`has`/`mk_group_accessors` → ATTRIBUTES. `=method name` after `sub` →
METHODS — both class methods and package functions; the DBIO bundle has no
separate `=func` directive. Non-method subs like `DBIO::Util` or
`DBIO::Diff::Compare` are therefore documented as `=method` even when called
as functions; the methods section header is the only collector the bundle
knows for subs. Omit NAME, VERSION, AUTHORS, COPYRIGHT (auto-generated). POD
inline — never a block after the final `1;`. `=seealso` — written without
argument text, followed by an `=over`/`=item` list — → SEE ALSO, placed at
the end of the body, before AUTHOR. A regular `=head1 SEE ALSO` section works
too (core's modules use it) and is emitted with the other hand-written
sections; one or the other per file. Cross-refs: `L<DBIO::Module>`. An
internal `L<...>` link that does not resolve is a `Pod::Checker` error and
fails `dzil test` / `dzil release` (`DBIO::PodCheckerTest`).

POD describes the code as it stands, in the present tense. The karr card of a
change lives in its commit message; POD, README and error messages explain the
behaviour on their own.

`=encoding` in the source is stripped by `-SingleEncoding` and emitted once at build
time — see `dbio-perl-syntax` for when the source still needs it.
