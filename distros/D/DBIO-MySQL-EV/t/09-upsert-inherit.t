use strict;
use warnings;
use Test::More;

use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::SQLMaker;

# karr #23 -- follow-up to dbio-mysql #27 (ON DUPLICATE KEY UPDATE + row
# identity, ADR 0036). The EV storage is a thin transport over
# DBIO::Storage::Async (ADR 0030 Model-B), so supports_upsert and the conflict
# clause arrive through the SQLMaker seam the transport does carry
# (sql_maker_class), not through any driver component in the MRO. These tests
# freeze exactly that for MySQL: the ODKU emission of the ev-mode maker is
# byte-identical to a standalone DBIO::MySQL::SQLMaker (the very class the
# base driver's storage hands out), and the ADR-0036 section 4 row-identity
# idiom is visible in the emitted conflict SQL. The session-state half -- does
# LAST_INSERT_ID() survive the async round-trip -- is a live concern; see the
# karr ticket for that finding.

my $storage = DBIO::MySQL::EV::Storage->new(undef);
my $sm = $storage->sql_maker;

# The transport brings the seam: the MySQL maker, not the base DBIO::SQLMaker.
isa_ok $sm, 'DBIO::MySQL::SQLMaker',
  'sql_maker is the MySQL-specific maker (the seam the transport carries)';

# An independent instance of the same class, wired the way the base driver's
# storage would wire one (backtick quoting). A connected DBIO::MySQL::Storage
# additionally stashes server-version facts (row alias, lock dialect) on its
# maker; a standalone maker has no server to ask and falls back to VALUES(col)
# -- the same fallback the ev transport hits, since it never talks to a server
# either. Same class, same standalone configuration, byte-identical emission.
my $base_sm = DBIO::MySQL::SQLMaker->new({
  quote_char => $sm->{quote_char} // '`',
  name_sep   => $sm->{name_sep}   // '.',
});

my %data = ( name => 'Tom', active => 1 );
my %on_conflict = (
  action          => 'update',
  set             => { name => { -attempted => 'name' } },
  identity_column => 'id',
);

my ($ev_sql,  @ev_bind)   = $sm->insert('artist', { %data }, { on_conflict => { %on_conflict } });
my ($base_sql, @base_bind) = $base_sm->insert('artist', { %data }, { on_conflict => { %on_conflict } });

is $ev_sql, $base_sql,
  'ev-mode ODKU emission is byte-identical to the MySQL base maker';
is_deeply \@ev_bind, \@base_bind,
  'ev-mode ODKU binds match the MySQL base maker';

# ADR 0036 section 4: the row-identity channel. `id` = LAST_INSERT_ID(`id`) is
# a no-op on the stored value; its only purpose is to make LAST_INSERT_ID()
# report the primary key of the row the statement actually touched, insert or
# update. Its presence in the built SQL is the offline-provable half of the
# identity path -- the value surviving the async round-trip is the live half.
like $ev_sql, qr/ON \s+ DUPLICATE \s+ KEY \s+ UPDATE/xi,
  'conflict clause is ON DUPLICATE KEY UPDATE';
like $ev_sql, qr/`id` \s* = \s* LAST_INSERT_ID \( `id` \)/xi,
  'row-identity idiom present in conflict SQL';
unlike $ev_sql, qr/ON \s+ CONFLICT/xi,
  'no PostgreSQL ON CONFLICT leak into MySQL emission';

done_testing;
