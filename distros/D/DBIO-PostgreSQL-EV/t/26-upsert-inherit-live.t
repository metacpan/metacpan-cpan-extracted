use strict;
use warnings;
use Test::More;
use Test::Exception;

# LIVE-Verifikation für karr k26 (ADR 0036, Follow-up zu dbio-postgresql k43):
# erbt der EV-Transport die Upsert-Fähigkeit des PostgreSQL-Basis-Driver?
#
# Der Offline-Teil (t/08-upsert-inherit.t) pinnt SQLMaker-Klasse, byte-identische
# ON CONFLICT-SQL zum Basis-Driver und den _run_crud-RETURNING-Pfad ohne DB.
# Offen war nur der LIVE-Teil: der row-returning-Pfad (RETURNING) durch den
# async-Transport -- die eine Stelle, die plausibel differieren konnte -- plus
# die SET-Binds einfacher Werte: _insert_on_conflict (dbio-postgresql
# SQLMaker) bildete sie hartkodiert als [ $col => $val ] (columns-Form), was
# EV::Pg zu 'ARRAY(0x...)' stringifizierte (karr k26). Seit dbio-postgresql
# k122 (karr k88) folgt der Bind dem bindtype -- unter 'normal' der nackte Wert.
#
# Dieser Test fährt beides gegen echtes PostgreSQL: die Vererbung über den
# SQLMaker-Seam (supports_upsert sichtbar, ON CONFLICT-SQL läuft, RETURNING
# liefert die Zeile inkl. autoinc-PK durch EV::Pg und wird von
# _insert_returned_columns auf die ResultSource-Spalten gezippt) und die
# SET-Binds einfacher Werte (Text, Integer, bedingter Zweig).

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use Future;
use DBIO::PostgreSQL::EV::Storage;

use constant UPSERT_TABLE => 'dbio_upsert_live_artist';

# The test login as the libpq parameters the transport reads it as; a server
# that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;
my %ci = LiveServer->conninfo;

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ \%ci, {} ]);

sub await {
  my $f = shift;
  EV::run(EV::RUN_ONCE) until $f->is_ready;
  return $f->get;
}

sub run_raw {
  my ($sql) = @_;
  return await($storage->pool->acquire->then(sub {
    my $pg = shift;
    my $f  = Future->new;
    $pg->query($sql, sub {
      my (undef, $err) = @_;
      $storage->pool->release($pg);
      $err ? $f->fail($err) : $f->done;
    });
    return $f;
  }));
}

# --- ResultSource-Stub: liefert name + columns in Declarations-Order (der
#     RETURNING *-Spaltenreihenfolge), damit _insert_returned_columns die
#     positionelle Zeile zippen kann -- der Beweis, dass die Zeile WIRKLICH
#     durch den Transport zurückkommt. (Gleiches Muster wie t/22.) ---

{
  package DbioUpsertArtist26;
  sub new     { bless {}, shift }
  sub name    { main::UPSERT_TABLE() }
  sub columns { qw(artistid name rank note) }
}

my $rsrc = DbioUpsertArtist26->new;

lives_ok {
  run_raw("DROP TABLE IF EXISTS " . UPSERT_TABLE);
  run_raw("CREATE TABLE " . UPSERT_TABLE
    . ' (artistid serial PRIMARY KEY, name text NOT NULL UNIQUE, '
    . 'rank int, note text)');
} 'test table created';

# --- (a) supports_upsert sichtbar + ON CONFLICT-SQL läuft live ----------------
# Die Fähigkeit kommt über den SQLMaker-Seam an (t/08 pinnt die Identität zum
# Basis-Driver offline); hier der Live-Nachweis, dass die so erzeugte SQL gegen
# echtes PostgreSQL läuft.

is $storage->sql_maker_class, 'DBIO::PostgreSQL::SQLMaker',
  'Capability via SQLMaker-Seam: gleiche sql_maker_class wie der Basis-Driver';

# Einfacher Insert zuerst: RETURNING * liefert den autoinc-PK durch den
# async-Transport, _insert_returned_columns zippt ihn auf die ResultSource.
my $ins = await($storage->insert_async($rsrc, { name => 'foo', rank => 3 }));
is ref $ins, 'HASH', 'insert_async resolved a returned-columns HASHREF (ADR 0031 §3)';
is $ins->{artistid}, 1, 'RETURNING * delivered the autoinc PK through the async transport';
is $ins->{rank}, 3, '... and the supplied value';

# ON CONFLICT DO NOTHING: der Konflikt-Fall legt keine zweite Zeile an.
await($storage->insert_async($rsrc, { name => 'foo', rank => 3 },
  { on_conflict => { target => ['name'], action => 'nothing' } }));
my @all = await($storage->select_async(UPSERT_TABLE, ['name'], {}));
is scalar(@all), 1, 'ON CONFLICT DO NOTHING did not duplicate the row';

# ON CONFLICT DO UPDATE (EXCLUDED) + RETURNING: die aktualisierte Zeile kommt
# durch den async-Transport zurück -- die eine Stelle, die plausibel hätte
# differieren können.
my $up = await($storage->insert_async($rsrc, { name => 'foo', rank => 7 },
  {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
    },
  }));
is $up->{rank}, 7,
  'DO UPDATE ... EXCLUDED applied; RETURNING * returned the updated row';
is $up->{artistid}, 1, '... same row (artistid stable)';

my @rows = await($storage->select_async(UPSERT_TABLE, ['rank'], { name => 'foo' }));
is $rows[0][0], 7, 'readback confirms the upserted rank';

# --- (b) SET-Binds einfacher Werte kommen als Werte an (dbio-postgresql k122) --
# Die EV-Bind-Liste ist flach: ['foo', 11, 'fixed']. Der Text kommt als Wert an,
# nicht als stringifizierter Arrayref.
my $nb = await($storage->insert_async($rsrc, { name => 'foo', rank => 11 },
  {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { note => 'fixed' },
    },
  }));
is $nb->{note}, 'fixed', 'a plain-value text SET arrives as the value';
is $nb->{rank}, 7, '... and only the SET column changed';

my @nb_rows = await($storage->select_async(UPSERT_TABLE, ['note'], { name => 'foo' }));
is $nb_rows[0][0], 'fixed', 'readback confirms the SET value';

# (i) a plain integer SET value (it used to abort loudly)
my $int = await($storage->insert_async($rsrc, { name => 'foo', rank => 1 },
  {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => 42 },
    },
  }));
is $int->{rank}, 42, 'a plain integer SET value is returned by RETURNING';
my @int_rows = await($storage->select_async(UPSERT_TABLE, ['rank'], { name => 'foo' }));
is $int_rows[0][0], 42, '... and read back';

# (ii) update_where: DO UPDATE ... WHERE guard
my $hit = await($storage->insert_async($rsrc, { name => 'foo', rank => 1 },
  {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { note => 'guarded' },
      where  => { rank => { '<' => 100 } },
    },
  }));
is $hit->{note}, 'guarded', 'update_where: condition holds, the row is updated and returned';
my @hit_rows = await($storage->select_async(UPSERT_TABLE, ['note'], { name => 'foo' }));
is $hit_rows[0][0], 'guarded', '... read back';

my $miss = await($storage->insert_async($rsrc, { name => 'foo', rank => 1 },
  {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { note => 'ungated' },
      where  => { rank => { '<' => 10 } },
    },
  }));
# RETURNING yields no row when the guard does not hold; insert_async then
# resolves the values that were supplied (no artistid, nothing of the stored
# row) -- not the row in the table, not undef.
is_deeply $miss, { name => 'foo', rank => 1 },
  '... insert_async resolves the supplied values, not the stored row';
my @miss_rows = await($storage->select_async(UPSERT_TABLE, ['note', 'rank'], { name => 'foo' }));
is_deeply $miss_rows[0], [ 'guarded', 42 ],
  'update_where: condition does not hold, the row is unchanged';

# --- cleanup ---

lives_ok { run_raw("DROP TABLE IF EXISTS " . UPSERT_TABLE) } 'test table dropped';

$storage->disconnect;

done_testing;
