# Security

This is the security policy for DBIx-Squirrel, the Perl distribution of
DBIx::Squirrel and its modules.

## Reporting a vulnerability

Please report a vulnerability privately, never in a public issue,
either way:

- on GitHub, with **Report a vulnerability** on the Security tab of the
  repository MetaCPAN links to (Security → Advisories → Report a
  vulnerability);
- by email, to the maintainer, Iain Campbell, at <cpanic@cpan.org>.

If you can't reach the maintainer, or have had no reply after a
reasonable time, contact the CPAN Security Group, at
<cpan-security@security.metacpan.org>.

A useful report has the version of DBIx::Squirrel, and of Perl, the DBI
and the driver; a reproduction, as small as you can make it; and what
an attacker could do with it. You'll get a reply when it has been read,
and credit in the advisory and in `Changes` if you'd like it.

## Scope

This policy covers the modules in this distribution. A vulnerability
in the DBI, a database driver, the database itself, or
Ekorn::Pipeline, which DBIx::Squirrel's pipeline comes from, belongs
to that project, though a report here that it reaches through
DBIx::Squirrel is welcome.

## Supported versions

Only the latest release is supported, on Perl 5.36 or later. The 1.x
series, whose last release is 1.6.5, gets no fixes.

## Fixes

Fixes go into a new release, and `Changes` says what it fixes. A
release on CPAN is never changed: a version with a vulnerability may be
deleted from CPAN, though BackPAN keeps it, and the fixed one replaces
it.

This project doesn't pay for reports.
