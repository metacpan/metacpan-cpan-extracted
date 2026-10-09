#!perl

use strict;
use warnings;

use Test2::V1 qw( -utf8 -x );
use Test2::Plugin::BailOnFail;
use English qw( -no_match_vars );
use Path::Tiny qw( path );

T2->ok(path('README.md')->is_file(), 'File README.md exists');

my $got = path('README.md')->slurp_utf8 =~ s/[[:space:]]+$//rmsx;

my (@got_lines, @expected_lines);
foreach (split qr{\R}msx, $got) { push @got_lines, $_; }
do {
    local $INPUT_RECORD_SEPARATOR = undef;
    my $expected = <DATA>;
    $expected =~ s/[[:space:]]+$//msx;
    foreach (split qr{\R}msx, $expected) { push @expected_lines, $_; }
};
T2->is(\@got_lines, \@expected_lines, 'File README.md matches expected content');

T2->done_testing;

__DATA__
[![License: Artistic-2.0][perlLicenseBadge]](https://opensource.org/licenses/Artistic-2.0)
[![CPAN Version](https://img.shields.io/cpan/v/Dancer2-Session-Pg)](https://metacpan.org/dist/Dancer2-Session-Pg)
[![GitHub release (latest by date)][latestReleaseBadge]](https://github.com/mikkoi/dancer2-session-pg/releases/latest)
[![GitHub Release Date][releaseDateBadge]](https://github.com/mikkoi/dancer2-session-pg/releases)

[![kwalitee][kwaliteeBadge]](https://cpants.cpanauthors.org/dist/Dancer2-Session-Pg)
[![codecov][codecovBadge]](https://codecov.io/gh/mikkoi/dancer2-session-pg)
[![Coverage Status][coverallsBadge]](https://coveralls.io/github/mikkoi/dancer2-session-pg?branch=main)
[![DeepWiki][deepWikiBadge]](https://deepwiki.com/mikkoi/dancer2-session-pg)

[![GH Actions: Linux Build][ciLinux]](https://github.com/mikkoi/dancer2-session-pg/actions/workflows/linux.yml)
[![GH Actions: Windows Build][ciWindows]](https://github.com/mikkoi/dancer2-session-pg/actions/workflows/windows.yml)
[![GitHub repo size][repoSizeBadge]](https://github.com/mikkoi/dancer2-session-pg/archive/refs/heads/main.zip)
[![GitHub pull requests][githubPullRequestsBadge]](https://github.com/mikkoi/dancer2-session-pg/pulls)

# Dancer2-Session-Pg

PostgreSQL session backend for Dancer2


# VERSION

version 0.001

# STATUS

Package Dancer2::Session::Pg is under development so changes in the API
are possible, though not likely.

# SYNOPSIS

    use Dancer2::Session::Pg ();

    my $engine = Dancer2::Session::Pg->new(
        dsn              => 'dbi:Pg:dbname=app;host=db',
        dbuser           => 'app_web',
        dbpass           => $ENV{'APP_DB_PASSWORD'},
        dbtable          => 'sessions',          # required
        dbschema         => 'web',               # optional; else search_path
        session_duration => 900,

        # One or more SLOTS, each pairing a key with the cipher that uses it.
        # Exactly one is active: that is the one sessions are written with, and
        # the rest stay to be read. See SECURITY for where the key comes from.
        encryption_keys => {
            0 => {
                key    => $ENV{'SESSION_KEY_0'},
                alg    => 'AES-256-GCM',
                active => 1,
            },
        },

        # Optional; see THE PRINCIPAL COLUMN for whether you want it at all.
        principal_key    => 'principal',
        principal_column => 'account_id',
    );

Most applications configure this from `config.yml` rather than in Perl -- see
["A configuration file" in Dancer2::Session::Pg](https://metacpan.org/pod/Dancer2%3A%3ASession%3A%3APg#A-configuration-file). Installing the engine by hand is
for when `dbh` has to
be a coderef, something YAML cannot express, and there is a trap in doing it
which ["CONNECTIONS" in Dancer2::Session::Pg](https://metacpan.org/pod/Dancer2%3A%3ASession%3A%3APg#CONNECTIONS) describes.

# DESCRIPTION

Stores Dancer2 sessions in PostgreSQL, and uses PostgreSQL's own features to
make that storage safer than a serialised blob in a table.

A web session is not ordinary data. It frequently carries the credentials that
prove who somebody is -- with OpenID Connect, an access token and a refresh
token -- so the store is worth more than the account it belongs to. Three
properties follow from that, and each is provided by the database rather than by
convention:

- Authenticated encryption at rest

    The payload is encrypted with an AEAD cipher, so a dump, a backup or a support
    copy of the table does not hand over the contents of a session, and a row that
    has been altered fails to decrypt instead of deserialising into a structure the
    application would then trust.

    Nor does it hand over a way in. **The session id is stored as a SHA-256 digest,
    not verbatim**, because the id is the session cookie: a table full of raw ids
    would be a table full of working credentials, usable against the live
    application by anyone who read a backup, no key required. What a dump contains
    is digests, which open nothing.

    The id is also authenticated with the payload, so a sealed payload opens only
    under the session it was written for and cannot be moved from one row to
    another.
    ["SECURITY" in Dancer2::Session::Pg](https://metacpan.org/pod/Dancer2%3A%3ASession%3A%3APg#SECURITY) says what that stops, where the key should
    live, and when to rotate
    it.

    Which cipher is a property of the key it is used with, and both are
    **replaceable**: every payload records the key and the cipher that sealed it, so
    a cipher found wanting next year is three deployments rather than a forced
    logout. See ["THE STORED PAYLOAD" in Dancer2::Session::Pg](https://metacpan.org/pod/Dancer2%3A%3ASession%3A%3APg#THE-STORED-PAYLOAD),
    ["Rotating the key" in Dancer2::Session::Pg](https://metacpan.org/pod/Dancer2%3A%3ASession%3A%3APg#Rotating-the-key) and
    [Dancer2::Session::Pg::Cipher](https://metacpan.org/pod/Dancer2%3A%3ASession%3A%3APg%3A%3ACipher).

- Expiry decided by the server's clock

    `expires` is a `timestamptz` and every read filters on it. Application clocks
    drift; the database's clock is the one every process shares, so all of them
    agree about whether a session is still alive.

    The expiry is set when the row is created and **is not moved by later writes**.
    `session_duration` is therefore an absolute cap measured from creation, which is
    what [Dancer2::Core::Role::SessionFactory](https://metacpan.org/pod/Dancer2%3A%3ACore%3A%3ARole%3A%3ASessionFactory) describes: a limit on session
    validity, regardless of the cookie. An idle timeout is a different thing and is
    the cookie's job -- see `cookie_duration`, which slides.

    This matters more than it sounds. A cap that every request pushes further away is
    never reached by a session in continuous use, and a session in continuous use is
    what somebody holding stolen cookies has.

- Atomic writes

    Sessions are written with `INSERT ... ON CONFLICT DO UPDATE`, which is atomic.
    Any number of workers may write one session id concurrently without producing a
    duplicate row, a unique violation or a deadlock, and without moving the expiry
    cap.

    That is a guarantee about database integrity, not about every write succeeding:
    concurrent writers to one row serialise on its lock, and a waiter that exceeds
    `statement_timeout` is cancelled on purpose rather than holding a worker. See
    ["A blocked write fails rather than waiting" in Dancer2::Session::Pg](https://metacpan.org/pod/Dancer2%3A%3ASession%3A%3APg#A-blocked-write-fails-rather-than-waiting).

    It does **not** mean two workers cannot lose each other's changes. The payload is
    one encrypted blob, so a write replaces all of it and the last writer wins. See
    ["CONCURRENCY" in Dancer2::Session::Pg](https://metacpan.org/pod/Dancer2%3A%3ASession%3A%3APg#CONCURRENCY), which says exactly what is and is not
    promised, and is backed by
    a test rather than by this paragraph.

On top of that, an **optional** clear column beside the encrypted payload makes it
possible to find and end every session belonging to one account without
decrypting anything -- see ["destroy\_for\_principal" in Dancer2::Session::Pg](https://metacpan.org/pod/Dancer2%3A%3ASession%3A%3APg#destroy_for_principal).
Suspending an account has
little effect while the suspended user's cookie still works. That column is off
by default and need not exist; ["THE PRINCIPAL COLUMN" in Dancer2::Session::Pg](https://metacpan.org/pod/Dancer2%3A%3ASession%3A%3APg#THE-PRINCIPAL-COLUMN) is
about whether you want
it.

## Why this is PostgreSQL and not portable SQL

A reasonable question, since a session row is four columns and a blob. The
answer is that the three guarantees above are not properties of the schema --
they are properties of statements and settings that standard SQL either does not
have or does not define strongly enough to rely on.

- `INSERT ... ON CONFLICT DO UPDATE`, not `MERGE`

    The standard spells an upsert `MERGE`, PostgreSQL has had it since 15, and it
    is **not a substitute here**. `MERGE` decides between its `WHEN MATCHED` and
    `WHEN NOT MATCHED` branches from a snapshot; it does not take the speculative
    insertion lock that `ON CONFLICT` does, so when two transactions pick the
    `NOT MATCHED` branch for the same key, one of them inserts and the other
    raises a unique violation.

    That is not a theoretical difference. Sixteen processes upserting one key forty
    times each, on PostgreSQL 17:

        INSERT ... ON CONFLICT DO UPDATE    0 of 16 workers failed
        MERGE                               4 of 16 workers failed
                                            ERROR: duplicate key value violates
                                            unique constraint

    A session is written on more or less every request, and concurrent writes to one
    session id are the normal case, not the edge: a page with parallel `XHR`s does
    it by itself. With `MERGE` a quarter of those workers would have had to carry
    retry logic for a constraint violation that cannot happen with `ON CONFLICT`.
    Writing portable SQL here would mean writing `SELECT`-then-`INSERT`-or-`UPDATE`
    in the application, which has the same race and loses atomicity as well.

- `statement_timeout`, so a blocked write fails instead of hanging

    ["A blocked write fails rather than waiting" in Dancer2::Session::Pg](https://metacpan.org/pod/Dancer2%3A%3ASession%3A%3APg#A-blocked-write-fails-rather-than-waiting) is a
    guarantee about the worker,
    not the row, and it rests on a PostgreSQL setting applied per connection. The
    standard has no equivalent: there is no portable way to say "cancel this
    statement after 400ms". Without it a writer that lands behind an open
    transaction waits as long as that transaction lives, holding a web worker the
    whole time -- and a handful of those is an outage, for a session that was not
    worth waiting on.

- `bytea`, and a driver that binds it as binary

    The sealed payload is ciphertext: arbitrary bytes, which must come back byte for
    byte or the authentication tag fails and the session is lost. `bytea` with
    [DBD::Pg](https://metacpan.org/pod/DBD%3A%3APg)'s `PG_BYTEA` binding does that with no encoding in the middle. The
    standard `BLOB` is spelled and handled differently by every engine, and the
    usual portable workaround -- base64 into a text column -- inflates every row by
    a third and adds a transform to each read and write of a credential store.

- `timestamptz` and the server clock

    Expiry is decided by `now()` on the server, against `timestamptz`, so one
    clock decides whether a session is alive. Application clocks drift, and with
    several workers the answer would otherwise depend on which machine the request
    reached. `timestamptz` also removes the zone question entirely, because
    PostgreSQL stores it as an instant rather than a local time with an offset.

None of this rules out a portable session store -- it rules out a portable one
with these properties. A session table meant to run on several engines is a
reasonable thing to want, and it is a different module from this one. This one
is for the case where the session store is the most security-sensitive table in
the database, and you would rather the database enforced that than your
application remembered to.

# REQUIREMENTS

PostgreSQL **9.5** or later, for `INSERT ... ON CONFLICT DO UPDATE` -- see
["Why this is PostgreSQL and not portable SQL" in Dancer2::Session::Pg](https://metacpan.org/pod/Dancer2%3A%3ASession%3A%3APg#Why-this-is-PostgreSQL-and-not-portable-SQL) for why
that statement and not
the standard `MERGE`.

Perl **v5.14** or later (Dancer2's required Perl as per [Dancer2](https://metacpan.org/pod/Dancer2) **v1.0.0**).


## 💻 Contributors

[![GitHub Contributors Image][githubContributorsBadge]](https://github.com/mikkoi/dancer2-session-pg/graphs/contributors)


# LICENSE

This software is copyright (c) 2026 by Mikko Johannes Koivunalho <mikko.koivunalho@iki.fi>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Terms of the Perl programming language system itself:

a) the GNU General Public License as published by the Free
   Software Foundation; either version 1, or (at your option) any
   later version, or
b) the "Artistic License"

The complete licenses are in the files LICENSE-Artistic-2.0 and LICENSE-GPL-3
within this repository. If these files are missing, they can be downloaded
from the following urls:

    * https://www.gnu.org/licenses/
    * https://www.perlfoundation.org/artistic-license-20.html


[perlLicenseBadge]: https://img.shields.io/badge/License-Perl-0298c3.svg
[kwaliteeBadge]: https://cpants.cpanauthors.org/dist/Dancer2-Session-Pg.svg
[codecovBadge]: https://codecov.io/gh/mikkoi/dancer2-session-pg/graph/badge.svg?token=13NMY1T8LD
[coverallsBadge]: https://coveralls.io/repos/github/mikkoi/dancer2-session-pg/badge.svg?branch=main
[githubContributorsBadge]: https://contrib.rocks/image?repo=mikkoi/dancer2-session-pg&max=36&columns=12&anon=1
[ciBadge]: https://github.com/mikkoi/dancer2-session-pg/actions/workflows/ci.yml/badge.svg
[ciLink]: https://github.com/mikkoi/dancer2-session-pg/actions/workflows/ci.yml
[ciLinux]: https://github.com/mikkoi/dancer2-session-pg/actions/workflows/linux.yml/badge.svg?event=push&branch=main
[ciWindows]: https://github.com/mikkoi/dancer2-session-pg/actions/workflows/windows.yml/badge.svg?event=push&branch=main
[latestReleaseBadge]: https://img.shields.io/github/v/release/mikkoi/dancer2-session-pg
[releaseDateBadge]: https://img.shields.io/github/release-date/mikkoi/dancer2-session-pg
[repoSizeBadge]: https://img.shields.io/github/repo-size/mikkoi/dancer2-session-pg
[totalDownloadsBadge]: https://img.shields.io/github/downloads/mikkoi/dancer2-session-pg/total
[githubLicenseBadge]: https://img.shields.io/github/license/mikkoi/dancer2-session-pg
[githubIssuesBadge]: https://img.shields.io/github/issues/mikkoi/dancer2-session-pg
[githubPullRequestsBadge]: https://img.shields.io/github/issues-pr/mikkoi/dancer2-session-pg
[deepWikiBadge]: https://img.shields.io/badge/DeepWiki-mikkoi%2Fdancer2--session--pg-blue.svg?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAyCAYAAAAnWDnqAAAAAXNSR0IArs4c6QAAA05JREFUaEPtmUtyEzEQhtWTQyQLHNak2AB7ZnyXZMEjXMGeK/AIi+QuHrMnbChYY7MIh8g01fJoopFb0uhhEqqcbWTp06/uv1saEDv4O3n3dV60RfP947Mm9/SQc0ICFQgzfc4CYZoTPAswgSJCCUJUnAAoRHOAUOcATwbmVLWdGoH//PB8mnKqScAhsD0kYP3j/Yt5LPQe2KvcXmGvRHcDnpxfL2zOYJ1mFwrryWTz0advv1Ut4CJgf5uhDuDj5eUcAUoahrdY/56ebRWeraTjMt/00Sh3UDtjgHtQNHwcRGOC98BJEAEymycmYcWwOprTgcB6VZ5JK5TAJ+fXGLBm3FDAmn6oPPjR4rKCAoJCal2eAiQp2x0vxTPB3ALO2CRkwmDy5WohzBDwSEFKRwPbknEggCPB/imwrycgxX2NzoMCHhPkDwqYMr9tRcP5qNrMZHkVnOjRMWwLCcr8ohBVb1OMjxLwGCvjTikrsBOiA6fNyCrm8V1rP93iVPpwaE+gO0SsWmPiXB+jikdf6SizrT5qKasx5j8ABbHpFTx+vFXp9EnYQmLx02h1QTTrl6eDqxLnGjporxl3NL3agEvXdT0WmEost648sQOYAeJS9Q7bfUVoMGnjo4AZdUMQku50McDcMWcBPvr0SzbTAFDfvJqwLzgxwATnCgnp4wDl6Aa+Ax283gghmj+vj7feE2KBBRMW3FzOpLOADl0Isb5587h/U4gGvkt5v60Z1VLG8BhYjbzRwyQZemwAd6cCR5/XFWLYZRIMpX39AR0tjaGGiGzLVyhse5C9RKC6ai42ppWPKiBagOvaYk8lO7DajerabOZP46Lby5wKjw1HCRx7p9sVMOWGzb/vA1hwiWc6jm3MvQDTogQkiqIhJV0nBQBTU+3okKCFDy9WwferkHjtxib7t3xIUQtHxnIwtx4mpg26/HfwVNVDb4oI9RHmx5WGelRVlrtiw43zboCLaxv46AZeB3IlTkwouebTr1y2NjSpHz68WNFjHvupy3q8TFn3Hos2IAk4Ju5dCo8B3wP7VPr/FGaKiG+T+v+TQqIrOqMTL1VdWV1DdmcbO8KXBz6esmYWYKPwDL5b5FA1a0hwapHiom0r/cKaoqr+27/XcrS5UwSMbQAAAABJRU5ErkJggg==
