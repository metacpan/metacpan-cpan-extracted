#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use DBIx::Class::Async::Schema;

eval { require DBD::Pg; 1 }
    or plan skip_all => 'DBD::Pg required';
eval { require DateTime::Format::Pg; 1 }
    or plan skip_all => 'DateTime::Format::Pg required';

eval "use Test::PostgreSQL::v2 2.02";
plan skip_all => 'Test::PostgreSQL::v2 required' if $@;

my $pg = Test::PostgreSQL::v2->new()
    or plan skip_all => "Could not start PostgreSQL: " . Test::PostgreSQL::v2->errstr;

my $loop   = IO::Async::Loop->new;
my $schema = DBIx::Class::Async::Schema->connect(
    $pg->dsn, $pg->user, '',
    {
        AutoCommit    => 1,
        on_connect_do => "SET client_min_messages = WARNING",
    },
    {
        workers      => 2,
        schema_class => 'TestSchema',
        async_loop   => $loop,
    },
);

$schema->await( $schema->deploy({ add_drop_table => 1 }) );

# ----------------------------------------------------------------
# RT#133621 reproduced via DBIx::Class::Async
#
# Two bugs interact on the async path:
#
# BUG 1: InflateColumn::DateTime does not fire through the async
# worker. The column accessor returns a plain string instead of a
# DateTime object because the async deserialisation path
# reconstructs rows from raw data without triggering DBIC's
# inflation machinery.
#
# BUG 2 (compound, from DBIx-Class PR#138): Even when inflation
# does fire, no formatter is set on the resulting DateTime object.
# Stringification falls back to DateTime's own ISO8601 output
# ("2009-01-15T11:00:00") instead of the PostgreSQL-aware format
# ("2009-01-15 11:00:00+0000").
# ----------------------------------------------------------------

my $dt = DateTime->new(
    year      => 2009,
    month     => 1,
    day       => 15,
    hour      => 11,
    minute    => 0,
    second    => 0,
    time_zone => 'UTC',
);

my $row = $schema->resultset('Job')->create({ created_at => $dt })->get;
ok $row, 'Created row with timestamptz column via async path';

my $fetched = $schema->resultset('Job')->find( $row->id )->get;
ok $fetched, 'Fetched row fresh from DB via async worker';

my $created_at  = $fetched->created_at;
my $stringified = "$created_at";

# ----------------------------------------------------------------
# BUG 1: Inflation not firing through async worker
# Expected: ref eq 'DateTime'
# Got:      plain string e.g. "2009-01-15 11:00:00+00"
# ----------------------------------------------------------------
is ref($created_at), 'DateTime',
    'BUG 1: created_at must be a DateTime object, not a plain string';

# ----------------------------------------------------------------
# BUG 2: Formatter not set (DBIx-Class PR#138), checked only if
# inflation is working so we get a clean skip rather than a fatal
# "Can't locate object method" crash.
# ----------------------------------------------------------------
SKIP: {
    skip 'Skipping formatter checks until BUG 1 (inflation) is fixed', 4
        unless ref($created_at) eq 'DateTime';

    unlike $stringified, qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/,
        'BUG 2: DateTime must NOT stringify with bare ISO8601 (T separator, no offset)';

    # PostgreSQL returns +00 or +0000 depending on driver version —
    # accept both in the regex
    like $stringified, qr/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}[+-]\d{2}/,
        'BUG 2: DateTime must stringify with space separator and timezone offset';

    ok $created_at->formatter,
        'BUG 2: Inflated DateTime must have a formatter set';

    isa_ok $created_at->formatter, 'DateTime::Format::Pg',
        'BUG 2: Formatter must be DateTime::Format::Pg for a Pg connection';
}

done_testing;
