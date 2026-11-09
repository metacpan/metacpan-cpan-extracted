# Contributing

Thank you for wanting to help. DBIx-Squirrel welcomes **bug reports and
feature requests**, as issues on the repository MetaCPAN links to. It
doesn't accept pull requests.

## Why no pull requests

DBIx-Squirrel is written by Iain Campbell, with Claude, as the README's
Acknowledgements say, and every change goes through the same checks:
tests that compare its results with plain DBI's, across every Perl from
5.36 on, with floors on how much of the code they cover, and
documentation written alongside the code. Owning every line keeps the
credit honest, and the code safe to depend on: no one else's code can
be merged in, by mistake or by design.

A good report helps more than a pull request would. Its reproduction
becomes the failing test that comes before the fix. If you have a fix in
mind, sketch it in the issue: it will be written into the code with
tests, and you'll be thanked by name in `Changes`.

## A good bug report

- The versions: DBIx::Squirrel's
  (`perl -MDBIx::Squirrel -E 'say DBIx::Squirrel->VERSION'`), Perl's,
  the DBI's, and the driver's, such as DBD::SQLite's, with the
  database's.
- The smallest program that shows the problem, with the SQL and the
  values bound.
- What you expected, and what happened instead.
- What plain DBI does with the same SQL and values. Where DBIx::Squirrel
  and the DBI do the same thing, they should give the same result, so a
  difference is a bug, unless the reference says why.

## A good feature request

- What you're trying to do, more than how: the task, the data, and
  where the current interface gets in the way.
- How you'd do it with plain DBI, if you know.

Some requests will be out of scope. The README says what DBIx-Squirrel
is for, and saying no to a good idea that doesn't fit keeps it simple
to use. A stage that would suit any function, not only a database's,
may belong in Ekorn::Pipeline instead.

## Security

Please don't report a vulnerability in a public issue. See
[SECURITY.md](SECURITY.md).

## What to expect

DBIx-Squirrel is one person's project, kept up as time allows. Reports
are read, but a reply can take a while.
