use strict;
use warnings;
use Test::More;

# OFFLINE-Verifikation für karr k26 (ADR 0036, Follow-up zu dbio-postgresql
# k43): Kommen supports_upsert und die ON CONFLICT-Clause auf dem EV-Transport
# an, ohne dass dieser Driver eigenes Upsert-Verhalten patchen muss? Kein EV::Pg,
# kein echtes DB -- der Test arbeitet auf der SQLMaker- und der _run_crud-Ebene.
#
# Der zentrale Befund: Der EV-Transport erbt von DBIO::Storage::Async, NICHT
# von DBIO::PostgreSQL::Storage -- DBIO::Storage::DBI und damit die
# Capability-Accessors (_use_supports_upsert & Co.) sind nicht im MRO. Das ist
# dokumentiertes Design, kein Fehler: dbio-postgresql Storage.pm POD
# "Extensions and the async backends see the capability declarations" -- async
# ist ein per-connection-Modus des Sync-Storage; der prüft die Capability und
# übergibt dem Transport nur die fertige SQL. Was der Transport mitbringt, ist
# der SQLMaker-Seam (sql_maker_class) -- und der spricht ON CONFLICT. Dieser
# Test friert genau das ein: gleiche SQLMaker-Klasse wie der Basis-Driver,
# identische Conflict-SQL, RETURNING-Pfad intakt.
#
# Früherer Nebenbefund, behoben (dbio-postgresql k122, karr k88):
# _insert_on_conflict pushte die SET-Binds hartkodiert als [ $col => $val ]
# (columns-Form); EV::Pg stringifizierte den Arrayref zu 'ARRAY(0x...)'. Der
# SQLMaker bildet den Bind jetzt per _bindtype($col, $val), unter bindtype
# normal also den nackten Wert -- die EV-Bind-Liste ist durchgehend flach.
#
# Der LIVE-Teil (RETURNING durch den async-Transport gegen echtes PostgreSQL)
# ist auf diesem Host nicht fahrbar (kein docker/kubectl) -- offener Befund in
# der Ticket-Notiz.

use Future;
use DBIO::PostgreSQL::EV::Storage;
use DBIO::PostgreSQL::Storage;

my $EV = 'DBIO::PostgreSQL::EV::Storage';

# --- (a) supports_upsert: die Fähigkeit kommt über den SQLMaker an -----------
# Der Transport trägt die Capability-Accessors bewusst NICHT (siehe Header).
# Der Guard friert das Design ein: ein künftiger Patch, der die Accessors
# auf den Transport zieht, würde hier rot.

ok !$EV->can('_use_supports_upsert'),
  'kein Capability-Accessor auf dem Transport (Design: die Fähigkeit lebt auf dem Sync-Storage)';
ok !$EV->can('_use_supports_upsert_where'),
  '... und auch kein Accessor für den bedingten DO UPDATE-Zweig';

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
my $pg      = DBIO::PostgreSQL::Storage->new(undef);

is $storage->sql_maker_class, $pg->sql_maker_class,
  'die Upsert-Fähigkeit kommt über den SQLMaker an: gleiche sql_maker_class wie der Basis-Driver';
is $storage->sql_maker_class, 'DBIO::PostgreSQL::SQLMaker',
  '... nämlich DBIO::PostgreSQL::SQLMaker';
isa_ok $storage->sql_maker, 'DBIO::PostgreSQL::SQLMaker',
  'ev sql_maker ist ein PostgreSQL-SQLMaker';

# --- (b) identische Conflict-SQL wie der Basis-Driver ------------------------
# Gleiche Klasse, gleiche Ausgabe: beide SQLMaker rendern on_conflict
# (ADR 0036) zu derselben SQL. Die Bind-FORM unterscheidet sich dabei
# transportbedingt (EV: bindtype normal, EV::Pg nimmt plain values; Sync:
# bindtype columns für DBI-Typ-Inflation) -- das ist kein Upsert-Erb-Thema,
# sondern der normale Transportunterschied.

my %data = ( name => 'foo', rank => 3 );
my $ev_sm = $storage->sql_maker;
my $pg_sm = $pg->sql_maker;

my $values = 'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)';

for my $oc (
  { target => 'any', action => 'nothing' },
  { target => ['name'], action => 'update', set => { rank => { -attempted => 'rank' } } },
  {
    target => ['name'],
    action => 'update',
    set    => { rank => { -attempted => 'rank' } },
    where  => { rank => { '<' => { -attempted => 'rank' } } },
  },
) {
  my ($ev_sql, @ev_bind) = $ev_sm->insert('artist', { %data }, { on_conflict => $oc });
  my ($pg_sql, @pg_bind) = $pg_sm->insert('artist', { %data }, { on_conflict => $oc });

  is $ev_sql, $pg_sql,
    'Conflict-SQL identisch zum Basis-Driver (on_conflict '
  . "$oc->{target} / $oc->{action})";
}

{
  my ($sql, @bind) = $ev_sm->insert('artist', { %data },
    { on_conflict => { target => 'any', action => 'nothing' } });
  is $sql, "$values ON CONFLICT DO NOTHING",
    "target 'any' + DO NOTHING ist der portable insert-unless-present";
  is_deeply \@bind, [ 'foo', 3 ],
    '... die EV-Bind-Form ist plain (bindtype normal, für EV::Pg)';
}

{
  my ($sql, @bind) = $ev_sm->insert('artist', { %data },
    {
      on_conflict => {
        target => ['name'],
        action => 'update',
        set    => { rank => { -attempted => 'rank' } },
      },
    });
  is $sql,
    "$values ON CONFLICT (\"name\") DO UPDATE SET \"rank\" = EXCLUDED.\"rank\"",
    'DO UPDATE von den versuchten Werten (EXCLUDED)';
  is_deeply \@bind, [ 'foo', 3 ],
    '... die Conflict-Clause selbst bindet nichts';
}

{
  # Der SET-Bind eines einfachen Werts folgt dem bindtype des SQLMakers
  # (dbio-postgresql k122): unter 'normal' (EV) der nackte Wert, so wie die
  # VALUES-Binds davor -- EV::Pg bekommt nur Skalare.
  my ($sql, @bind) = $ev_sm->insert('artist', { %data },
    {
      on_conflict => {
        target => ['name'],
        action => 'update',
        set    => { charfield => 'fixed' },
        where  => { rank => { '<' => 0 } },
      },
    });
  is $sql,
    "$values ON CONFLICT (\"name\") DO UPDATE SET \"charfield\" = ? "
  . 'WHERE "artist"."rank" < ?',
    'der bedingte DO UPDATE-Zweig (last-write-wins guard) rendert die WHERE-Clause, '
  . 'tabellenqualifiziert (dbio-postgresql k75)';
  is_deeply \@bind, [ 'foo', 3, 'fixed', 0 ],
    '... die Binds folgen den VALUES-Binds, der SET-Bind ist der nackte Wert '
  . '(bindtype normal, durchgehend flach)';
  is scalar(grep { ref } @bind), 0,
    '... kein Bind-Eintrag ist eine Referenz (EV::Pg stringifizierte sie)';
}

# --- (c) der row-returning Pfad bleibt erhalten ------------------------------
# _post_insert_sql ist der ev-spezifische Seam; _run_crud (geerbt aus
# DBIO::Storage::Async) hängt das RETURNING * an die Conflict-SQL an. Die
# Clause sitzt damit VOR dem RETURNING-Tail -- die einzige syntaktisch gültige
# Reihenfolge (ADR 0036 §4, t/41 des Basis-Driver).

is $storage->_post_insert_sql, ' RETURNING *', '_post_insert_sql seam';

my $captured;
my $f = $storage->_run_crud('insert', sub {
  my ($sql, $bind) = @_;
  $captured = [ $sql, $bind ];
  Future->done({});
}, 'artist', { name => 'foo', rank => 3 },
  {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
    },
  });
$f->get;

is $captured->[0],
  "$values ON CONFLICT (\"name\") DO UPDATE SET \"rank\" = EXCLUDED.\"rank\" "
  . 'RETURNING *',
  '_run_crud emittiert die komplette Upsert-SQL inkl. RETURNING * (row-returning Pfad)';
is_deeply $captured->[1], [ 'foo', 3 ],
  '... und reicht die unveränderten VALUES-Binds an den Transport durch';

# Die fertige SQL ist rohe '?'-Dialekt-SQL; die $N-Formung ist Sache des
# Query-Seams (_query_async/_transform_sql, t/03) -- hier nur der Hinweis,
# dass die Conflict-SQL dieselbe Formung durchläuft wie jeder andere Insert.
like $captured->[0], qr/\?/, '... im sql_maker-?-Dialekt (Transport formt intern zu \$N)';

done_testing;
