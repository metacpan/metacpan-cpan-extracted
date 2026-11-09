# DBIO Deferred Test Future Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** k202 liefert eine manuell erfüllbare `DBIO::Test::Future`, migriert vier lokale Immediate-Doubles und macht sieben rein interne Async-Testdateien unabhängig von der optionalen CPAN-Distribution `Future`.

**Architecture:** Der neue Helper ist eine eigenständige pending-fähige Test-Future mit einer bewusst kleinen, durch `DBIO::Future->validate` akzeptierten Oberfläche; `DBIO::Test::Storage` bleibt unverändert Immediate. Die Tests werden zuerst vollständig auf den neuen Klassennamen und den kleinen Vertrag umgestellt, danach implementiert `dbio-worker` den Helper; CPAN-only Beobachter wie `failure`, `on_fail` und `is_done` werden durch `is_failed`, `catch`, `get` und `is_ready` ersetzt.

**Tech Stack:** Perl 5, `DBIO::Future`, `DBIO::Exception`, `Scalar::Util`, `Test::More`, `Test::Exception`, `DBIO::Storage::PoolBase`, Dist::Zilla, `maint/capped-test`.

**Spec:** `docs/superpowers/specs/2026-09-14-dbio-core-async-hardening-design.md`

## Global Constraints

- Dieses Dokument implementiert ausschließlich k202; es ändert keine Runtime-Default-Future und registriert keinen Async-Modus.
- `DBIO::Test::Future` ist keine Subklasse von `DBIO::Future::Immediate`.
- Öffentliche Oberfläche exakt: `new`, Klassen-/Objekt-`done`, Klassen-/Objekt-`fail`, `is_ready`, `is_failed`, `get`, `then`, `catch`, `needs_all`.
- Bewusst nicht vorhanden: `on_ready`, `on_fail`, `failure`, `is_done`, `await`, `cancel`, `retain`.
- Pending Callbacks laufen FIFO und genau einmal; Callback-Rückgaben werden im Skalarkontext ausgewertet; eine zurückgegebene pending `DBIO::Test::Future` wird geflattet.
- `get` auf pending und Double-Settlement werden laut über die DBIO-Exception-Taxonomie verweigert; es gibt kein Polling und kein Blocking.
- Der zweite Callback von `then` behandelt nur einen bereits fehlgeschlagenen Parent; eine Exception im gepaarten Success-Callback failt direkt die abgeleitete Future.
- `needs_all` wartet auf alle Erfolge, bewahrt Input-Reihenfolge, konkateniert Ergebnislisten und failt beim ersten beobachteten Fehler.
- `DBIO::Future->validate($future)` wird nicht erweitert; der Helper erfüllt dessen aktuelle Prüfmethoden `then`, `catch`, `get`, `is_ready`, `is_failed`.
- Die sieben migrierten Dateien müssen mit einer absichtlich nicht ladbaren `Future.pm` ohne Whole-file-Skip laufen.
- `cpanfile` behält `suggests 'Future', '0'`, weil `DBIO::Storage::PoolBase` in Produktion weiterhin `'Future'` als Default führt.
- Keine reale Datenbank, kein SQLite-DSN, kein Event Loop, kein Driver-Repo, keine `@ISA`-Änderung.
- Nur Main claimt, staged, committed und mutiert karr; genau ein lokaler Commit für k202.
- Der Arbeitsbaum ist nach dem Plan-Commit clean. `.claude/skills/kanban-issues-karr-cli/SKILL.md` ist nicht Teil von k202 und bleibt aus dem Ticket-Commit ausgeschlossen.
- Kein Push und kein Release.

---

## Aktueller Codebestand und Dateiverantwortung

### Neu

- `lib/DBIO/Test/Future.pm` — pending State Machine, Settlement, Chaining und Aggregation; neue vorgeschlagene private Helfer `_settle`, `_drain_callbacks`, `_run_callback` und `_adopt_result` bleiben außerhalb des öffentlichen Driver-Vertrags.
- `t/test/31_test_future.t` — alleiniger Contract-Test des Testhelpers.

### Vier lokale Doubles

- `t/test/15_async_orchestration.t:19-66` — entfernt `Test::SyncFuture`; `Test::SyncPool`, `Test::SyncBackend` und `Test::DecliningBackend` verwenden `DBIO::Test::Future`.
- `t/test/16_async_future_io_convention.t:23-65` — entfernt `AsyncConv::SyncFuture`; Pool und Adapter verwenden `DBIO::Test::Future`.
- `t/test/19_async_deploy.t:18-46` — entfernt `Test::SyncFuture`; `Test::SyncPool` und `Test::DeployBackend` verwenden `DBIO::Test::Future`.
- `t/resultset/with_context.t:22-55` — entfernt `Test::SyncFuture`; `Test::SyncPool` und `Test::CtxBackend` verwenden `DBIO::Test::Future`.

### Sieben Whole-file-Skips

- `t/storage/pool_base.t:5` — entfernt den exakten `BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }`-Block; ausführbare Pools erhalten `future_class => 'DBIO::Test::Future'`, die Assertion auf den Produktionsdefault `'Future'` bleibt ohne Instanziierung erhalten.
- `t/storage/pool_readiness.t:23` — entfernt den Skip; `SyncPool`, `CountPool` und `AsyncPool` verwenden den Helper; direkte `Future->done/new`-Aufrufe und `failure`-Assertions werden migriert.
- `t/storage/pool_ready_wiring.t:26` — entfernt den Skip; alle ausführbaren Pools und die pending Readiness-Future verwenden den Helper; `failure` wird nicht nachgebaut.
- `t/storage/pool_connect_actions.t:19` — entfernt den Skip; `RecBackend::future_class` liefert den Helper und `RecBackend::pool` reicht ihn an `RecPool` weiter; `on_fail` und `is_done` werden auf den kleinen Vertrag abgebildet.
- `t/storage/async_connect_info_leak.t:8` — entfernt den Skip; `Karr66::Storage::Async::future_class` und `Karr66::MockPool` teilen den Helper.
- `t/storage/async_access_broker.t:7` — entfernt den Skip; `MockAsyncStorage`, `MockPool` und `BareAsync` verwenden denselben Helper.
- `t/composed/async_mirror.t:7` — entfernt den Skip; `T::AM::RecordingTransport::future_class` und der direkte ready-Wert verwenden den Helper.

### Notwendige Repository-Tripwires aus der Dateisichtung

- `dist.ini:23-33` — im bestehenden `[MetaNoIndex]`-Kommentar wird `DBIO::Test::Future` in die Liste der absichtlich indexierten öffentlichen Test-Facilities aufgenommen; der Satz `DBIO::Test::Future was removed in 2e34555f and is gone.` entfällt.
- `Changes` — ein Eintrag unter dem passenden `{{$NEXT}}`-Abschnitt dokumentiert die neue Core-eigene Deferred-Test-Future und dass sieben Offline-Async-Tests nicht mehr von CPAN `Future` abhängen.
- `t/55namespaces_cleaned.t:156-160` — die aktuelle Ausnahme `next if $f eq 'catch' and $mod->isa('DBIO::Future::Immediate') || $mod eq 'DBIO::Future::Immediate';` wird minimal um die parallelen `DBIO::Test::Future`-Bedingungen erweitert, damit der neue absichtliche Methodenname nicht als Namespace-Leak fehlklassifiziert wird; k202 korrigiert die bestehende Operatorpräzedenz nicht nebenbei.
- `lib/DBIO/Test/Future.pm` trägt wie alle ausgelieferten Module `our $VERSION = '0.900004'`.
- `t/test/09_async.t` bleibt der unveränderte Produktionsvertrag für `DBIO::Future::Immediate`.
- `t/test/30_async_harness.t` behält `T::AH::Future`; dessen Tick-Countdown ist eine andere Fixture und gehört nicht zu den vier Migrationen.
- `xt/podcoverage.t` braucht keine Änderung, weil `DBIO::Test*` bereits ausgeschlossen ist.

---

### Task 1: k202 claimen und roten Test-Diff delegieren

**Files:**
- Create by test agent: `t/test/31_test_future.t`
- Modify by test agent: `t/test/15_async_orchestration.t`
- Modify by test agent: `t/test/16_async_future_io_convention.t`
- Modify by test agent: `t/test/19_async_deploy.t`
- Modify by test agent: `t/resultset/with_context.t`
- Modify by test agent: `t/storage/pool_base.t`
- Modify by test agent: `t/storage/pool_readiness.t`
- Modify by test agent: `t/storage/pool_ready_wiring.t`
- Modify by test agent: `t/storage/pool_connect_actions.t`
- Modify by test agent: `t/storage/async_connect_info_leak.t`
- Modify by test agent: `t/storage/async_access_broker.t`
- Modify by test agent: `t/composed/async_mirror.t`
- Modify by test agent: `t/55namespaces_cleaned.t`

**Interfaces:**
- Consumes: aktueller `DBIO::Future->validate($obj)`-Vertrag aus `lib/DBIO/Future.pm:21-80` und die k202-Semantik der freigegebenen Spec.
- Produces: einen uncommitteten Test-Diff, dessen erster roter Zeuge ausschließlich am noch fehlenden `DBIO::Test::Future` scheitert; Main übergibt diesen Diff unverändert an `dbio-worker`.

- [ ] **Step 1: Prüfe und claime k202 als Main**

Run:

```bash
TICKET_ID=202
CLAIM=$(karr agent-name)
karr show "$TICKET_ID"
karr move "$TICKET_ID" in-progress --claim "$CLAIM"
```

Expected: k202 war unclaimed und unblocked; nur k202 steht danach unter dem Main-Claim.

- [ ] **Step 2: Prüfe den unveränderten Git-Index und den bekannten Fremd-Diff**

Run:

```bash
test -z "$(git diff --cached --name-only)"
git status --short
```

Expected vor dem Test-Handoff: keine Ausgabe.

- [ ] **Step 3: Delegiere den Contract-Test an `dbio-test-mock-writer`**

Handoff prompt:

```text
Implementiere ausschließlich den roten k202-Test-Diff aus
`docs/superpowers/plans/2026-09-14-dbio-test-future.md`, Task 1.
Lies zusätzlich die vollständige freigegebene Spec
`docs/superpowers/specs/2026-09-14-dbio-core-async-hardening-design.md`.
Erzeuge `t/test/31_test_future.t` mit den neun im Plan benannten Subtests.
Migriere danach nur die zwölf weiteren erlaubten Testdateien; ändere keine
Produktionsdatei, `dist.ini`, Git-Index oder karr. Führe den roten Contract-Test
über `maint/capped-test` aus und berichte exakten Fehler und Claim. Der erwartete
erste Fehler ist ausschließlich das fehlende `DBIO/Test/Future.pm`.
```

Expected returned artifacts: uncommitteter Test-Diff, neun Contract-Subtestnamen, roter Befehl, rote Diagnose, Claim-Satz.

- [ ] **Step 4: Schreibe den pending-/validate-Contract-Test**

Der Testagent erstellt exakt diesen ersten Subtest:

```perl
subtest 'new is pending and get never blocks' => sub {
  my $future = DBIO::Test::Future->new;

  ok !$future->is_ready,  'new Future is pending';
  ok !$future->is_failed, 'pending Future is not failed';
  lives_ok { DBIO::Future->validate($future) }
    'pending test Future satisfies the public minimal validator';
  throws_ok { $future->get } qr/pending/i,
    'get on pending Future refuses instead of polling';
};
```

Imports:

```perl
use Test::More;
use Test::Exception;

use DBIO::Future ();
use DBIO::Test::Future ();
```

- [ ] **Step 5: Schreibe die Settlement- und Double-settlement-Subtests**

Der Testagent ergänzt:

```perl
subtest 'class and object done/fail forms' => sub {
  my $ready = DBIO::Test::Future->done(qw/one two/);
  is_deeply [ $ready->get ], [qw/one two/],
    'class done preserves all values';

  my $pending = DBIO::Test::Future->new;
  is $pending->done('value'), $pending,
    'object done returns the settled object';
  is $pending->get, 'value', 'object done stores the value';

  my $failed = DBIO::Test::Future->fail('class failure');
  ok $failed->is_ready && $failed->is_failed,
    'class fail creates a ready failed Future';
  throws_ok { $failed->get } qr/class failure/,
    'failed get propagates the class-form error';

  my $object_failed = DBIO::Test::Future->new;
  is $object_failed->fail('object failure'), $object_failed,
    'object fail returns the settled object';
  throws_ok { $object_failed->get } qr/object failure/,
    'failed get propagates the object-form error';
};

subtest 'double settlement is rejected' => sub {
  for my $first (qw/done fail/) {
    for my $second (qw/done fail/) {
      my $future = DBIO::Test::Future->new;
      $future->$first("first $first");
      throws_ok { $future->$second("second $second") } qr/already|settled/i,
        "$first followed by $second is rejected";
    }
  }
};
```

- [ ] **Step 6: Schreibe FIFO-, Skalarkontext- und pending-Flattening-Subtests**

Der Testagent ergänzt:

```perl
subtest 'pending continuations run FIFO exactly once' => sub {
  my $source = DBIO::Test::Future->new;
  my @seen;
  my $first  = $source->then(sub { push @seen, 'first';  'A' });
  my $second = $source->then(sub { push @seen, 'second'; 'B' });

  ok !$first->is_ready && !$second->is_ready,
    'derived Futures remain pending with their source';
  $source->done('source');
  is_deeply \@seen, [qw/first second/], 'callbacks run FIFO once';
  is $first->get,  'A', 'first result is preserved';
  is $second->get, 'B', 'second result is preserved';
};

subtest 'then uses scalar callback context and flattens pending futures' => sub {
  my $callback_context;
  my $scalar = DBIO::Test::Future->done->then(sub {
    $callback_context = wantarray;
    return (10, 20);
  });
  ok defined($callback_context) && !$callback_context,
    'success callback runs in scalar context';
  is $scalar->get, 20, 'scalar callback result is used';

  my $inner = DBIO::Test::Future->new;
  my $derived = DBIO::Test::Future->done->then(sub { $inner });
  ok !$derived->is_ready, 'returned pending Future keeps chain pending';
  $inner->done('later');
  is $derived->get, 'later', 'pending Future result is flattened';
};
```

- [ ] **Step 7: Schreibe Failure-routing- und `catch`-Subtests**

Der Testagent ergänzt konkrete Fälle für Parent-Fehler, Callback-Throws und Success-Passthrough:

```perl
subtest 'then routes parent failure through only the failure callback' => sub {
  my @called;
  my $recovered = DBIO::Test::Future->fail('parent')->then(
    sub { push @called, 'success'; 'wrong' },
    sub { push @called, "failure:$_[0]"; 'recovered' },
  );
  is $recovered->get, 'recovered', 'failure callback may recover';
  is_deeply \@called, ['failure:parent'], 'success callback was skipped';

  my $propagated = DBIO::Test::Future->fail('unchanged')->then(sub { 'wrong' });
  throws_ok { $propagated->get } qr/unchanged/,
    'missing failure callback propagates the parent error';

  my $paired_failure_called = 0;
  my $success_throw = DBIO::Test::Future->done->then(
    sub { die "success callback exploded\n" },
    sub { $paired_failure_called++; 'wrong recovery' },
  );
  throws_ok { $success_throw->get } qr/success callback exploded/,
    'success callback exception fails the derived Future';
  is $paired_failure_called, 0,
    'paired failure callback does not catch success callback exceptions';

  my $failure_throw = DBIO::Test::Future->fail('source')->then(
    sub { 'wrong' },
    sub { die "failure callback exploded\n" },
  );
  throws_ok { $failure_throw->get } qr/failure callback exploded/,
    'failure callback exception fails the derived Future';
};

subtest 'catch preserves success and recovers failure' => sub {
  my $success = DBIO::Test::Future->done(qw/a b/)->catch(sub { 'wrong' });
  is_deeply [ $success->get ], [qw/a b/],
    'catch preserves successful values';

  my $pending = DBIO::Test::Future->new;
  my $caught = $pending->catch(sub { "caught $_[0]" });
  ok !$caught->is_ready, 'catch follows pending source';
  $pending->fail('late');
  is $caught->get, 'caught late', 'catch receives and recovers the error';
};
```

- [ ] **Step 8: Schreibe `needs_all`- und bewusst-kleine-Oberfläche-Subtests**

Der Testagent ergänzt:

```perl
subtest 'needs_all waits preserves input order and fails' => sub {
  my $left  = DBIO::Test::Future->new;
  my $right = DBIO::Test::Future->new;
  my $all   = DBIO::Test::Future->needs_all($left, $right);

  $right->done('right');
  ok !$all->is_ready, 'aggregate still waits for left input';
  $left->done(qw/left one/);
  is_deeply [ $all->get ], [qw/left one right/],
    'aggregate concatenates values in input order';

  my $failed = DBIO::Test::Future->needs_all(
    DBIO::Test::Future->done('ok'),
    DBIO::Test::Future->fail('aggregate failure'),
  );
  throws_ok { $failed->get } qr/aggregate failure/,
    'aggregate preserves input failure';
  is_deeply [ DBIO::Test::Future->needs_all->get ], [],
    'zero-input aggregate is immediately successful';
};

subtest 'unsupported CPAN-only surface stays absent' => sub {
  my $future = DBIO::Test::Future->new;
  ok !$future->can($_), "$_ is intentionally absent"
    for qw/on_ready on_fail failure is_done await cancel retain/;
  ok !DBIO::Test::Future->isa('DBIO::Future::Immediate'),
    'test Future is independent from Immediate';
};
```

- [ ] **Step 9: Migriere die vier lokalen Doubles**

In allen vier Dateien lädt der Testagent:

```perl
use DBIO::Test::Future ();
```

Er entfernt die vollständigen Package-Blöcke `Test::SyncFuture` beziehungsweise `AsyncConv::SyncFuture`, ersetzt deren `future_class`-Rückgaben durch:

```perl
sub future_class { 'DBIO::Test::Future' }
```

und aktualisiert jede betroffene `isa_ok`-Erwartung auf `DBIO::Test::Future`. `use Scalar::Util` entfällt in diesen vier Dateien, sofern nach Entfernung des Doubles kein anderer Aufruf verbleibt.

- [ ] **Step 10: Entferne die sieben Whole-file-Skips und setze die Pool-Future explizit**

Der Testagent entfernt in jeder der sieben Dateien exakt:

```perl
BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }
```

Ausführbare `PoolBase->new`-Aufrufe erhalten:

```perl
future_class => 'DBIO::Test::Future',
```

Die bestehende Assertion, dass der ungeänderte Produktionsdefault von `PoolBase` den String `'Future'` liefert, bleibt bestehen und konstruiert keine Instanz über diesen Default.

- [ ] **Step 11: Ersetze CPAN-only Observer in den sieben Dateien**

In `t/storage/pool_base.t` bleibt die bestehende Fehlermeldung der abstrakten Seam der Claim:

```perl
ok $bare_f->is_failed, '_create_connection required (a failed Future, not a throw)';
eval { $bare_f->get };
like $@, qr/Subclass must override _create_connection/,
  'and the failure names the hook the subclass has to supply';
```

In `t/storage/pool_readiness.t` ersetzt der Testagent die `failure`-Aufrufe durch Status plus `get`:

```perl
$bad->fire_error('could not connect to server');
ok $ef->is_ready,  'acquire Future becomes ready after a connect error';
ok $ef->is_failed, 'acquire Future FAILED (rather than hanging) on connect error';
eval { $ef->get };
like $@, qr/could not connect/, 'failure carries the connect error';

$pool->release($bad);
my $ef2 = $pool->acquire;
ok $ef2->is_ready && $ef2->is_failed,
  'reacquiring a failed connection fails fast (no hang on a stale future)';
```

In `t/storage/pool_ready_wiring.t` gelten diese exakten Formen:

```perl
$conn->fire_error('could not connect to server');
ok $f->is_ready,  'acquire became ready after a pre-connect error';
ok $f->is_failed, 'acquire FAILED rather than hanging';
eval { $f->get };
like $@, qr/could not connect/, 'the failure carries the connect error';

my $g = $pool->acquire;
my $ok = $pool->{_built}[1];
$ok->fire_connect;
ok $g->is_ready && !$g->is_failed, 'second connection came up cleanly';
$ok->fire_error('later runtime error');
ok !$g->is_failed,
  'an error AFTER connect does not fail the already-resolved future';
```

Die abstrakten Fälle derselben Datei verwenden `is_failed`, `get` und ihre bestehenden exakten Diagnosen:

```perl
ok $f->is_failed, '_create_connection is still required (a failed Future)';
eval { $f->get };
like $@, qr/Subclass must override _create_connection/,
  'and still with the same message';

ok $f->is_failed, '_create_ready_connection without _new_connection fails';
eval { $f->get };
like $@, qr/Subclass must override _new_connection/,
  'and names the seam that is missing';
```

In `t/storage/pool_connect_actions.t` wird der operative Fehler so beobachtet:

```perl
isa_ok $f, 'DBIO::Test::Future',
  'select_async still handed back a Future';
ok $f->is_ready,  'the returned Future is already resolved';
ok $f->is_failed, 'and it is failed, not done';
my $caught;
$f->catch(sub { $caught = $_[0]; return $_[0] });
like $caught, qr/connect action refused: REFUSE SET search_path/,
  'catch receives the connect-action error the server raised';

my $af;
lives_ok { $af = $backend->pool->acquire }
  'pool->acquire does not throw either';
ok $af->is_failed, 'pool->acquire hands back a failed Future';
```

Der reparierte nächste Acquire verwendet statt `is_done`:

```perl
ok $good->is_ready && !$good->is_failed,
  'the next acquire after a fixed connect action resolves';
```

`RecBackend::pool` reicht zusätzlich die Backend-Wahl weiter:

```perl
future_class => $self->future_class,
```

Dasselbe Forwarding gilt für `Karr66::MockPool` in `t/storage/async_connect_info_leak.t` und `MockPool` in `t/storage/async_access_broker.t`.

- [ ] **Step 12: Erweitere den Namespace-Test ausschließlich für den neuen legitimen `catch`**

Der Testagent ersetzt die aktuelle einzeilige Ausnahme durch diese logisch gruppierte, aber praktisch semantikgleiche Erweiterung:

```perl
next if
     ($f eq 'catch' && $mod->isa('DBIO::Future::Immediate'))
  || $mod eq 'DBIO::Future::Immediate'
  || ($f eq 'catch' && $mod->isa('DBIO::Test::Future'))
  || $mod eq 'DBIO::Test::Future';
```

Die beiden neuen Bedingungen spiegeln die vorhandene Immediate-Ausnahme; eine weitergehende Bereinigung der alten exakten-Class-Klausel gehört nicht zu k202.

- [ ] **Step 13: Führe den neuen Contract-Test rot aus**

Run as Main:

```bash
set -o pipefail
maint/capped-test prove -l t/test/31_test_future.t 2>&1 \
  | tee /tmp/dbio-k202-red.log
```

Expected: FAIL ausschließlich mit `Can't locate DBIO/Test/Future.pm`; der Test darf nicht wegen Syntax, Fixture oder optionalem CPAN `Future` skippen.

- [ ] **Step 14: Formuliere den roten Claim vor der Implementierung**

Main checkpoint:

```text
k202 behauptet: Core besitzt noch keine pending-fähige, manuell erfüllbare
Test-Future, die den minimalen DBIO::Future-Validator erfüllt und die exakt
festgelegte Settlement-/Chaining-Semantik ohne CPAN Future bereitstellt.
```

Expected: Dieser Claim bleibt während der Implementierung unverändert.

---

### Task 2: Minimalen Helper implementieren und Repository-Tripwires nachziehen

**Files:**
- Create by worker: `lib/DBIO/Test/Future.pm`
- Modify by worker: `dist.ini`
- Modify by worker: `Changes`
- Read: `lib/DBIO/Future.pm:21-80`
- Read: `lib/DBIO/Future/Immediate.pm:41-177`
- Test: der uncommittete Diff aus Task 1

**Interfaces:**
- Consumes: die roten neun Contract-Subtests und die migrierten Fixtures aus Task 1.
- Produces: `DBIO::Test::Future` mit den verifizierten öffentlichen Signaturen `new($class)`, `done($class_or_object, @values)`, `fail($class_or_object, $error)`, `is_ready($self)`, `is_failed($self)`, `get($self)`, `then($self, $on_done, $on_fail_optional)`, `catch($self, $on_fail)`, `needs_all($class, @test_futures)`.

- [ ] **Step 1: Delegiere ausschließlich Helper und Packaging-Hinweis an `dbio-worker`**

Handoff prompt:

```text
Implementiere ausschließlich k202 Task 2 aus
`docs/superpowers/plans/2026-09-14-dbio-test-future.md` gegen den bereits
vorliegenden, vom Main bestätigten roten Test-Diff. Lies die vollständige Spec.
Erzeuge nur `lib/DBIO/Test/Future.pm`, korrigiere nur den veralteten
DBIO::Test::Future-Hinweis in `dist.ini` und ergänze den k202-Eintrag in
`Changes`. Ändere keine Tests, keine anderen Produktionsdateien, Git-Index oder
karr. Verwende DBIO::Exception für neue Refusals. Berichte die geänderten
Methodennamen und den fokussierten grünen Lauf.
```

Expected returned artifacts: uncommitteter Modul-/`dist.ini`-Diff, Methodenliste, fokussierter PASS.

- [ ] **Step 2: Lege Modulpräambel und pending Zustand an**

Der Worker verwendet diese konkrete Form:

```perl
package DBIO::Test::Future;
# ABSTRACT: Manually settled Future for deterministic DBIO tests

use strict;
use warnings;

our $VERSION = '0.900004';

use Scalar::Util ();
use DBIO::Exception ();

sub new {
  my ($class) = @_;
  return bless {
    state     => 'pending',
    values    => [],
    callbacks => [],
  }, $class;
}
```

- [ ] **Step 3: Implementiere Klassen-/Objekt-Settlement**

Vorgeschlagene neue private Naht und öffentliche Aufrufer:

```perl
sub done {
  my $invocant = shift;
  my $self = ref $invocant ? $invocant : $invocant->new;
  return $self->_settle(done => @_);
}

sub fail {
  my $invocant = shift;
  my $self = ref $invocant ? $invocant : $invocant->new;
  return $self->_settle(failed => @_);
}

sub _settle {
  my ($self, $state, @values) = @_;
  DBIO::Exception->throw('DBIO::Test::Future is already settled')
    unless $self->{state} eq 'pending';
  $self->{state}  = $state;
  $self->{values} = \@values;
  $self->_drain_callbacks;
  return $self;
}
```

- [ ] **Step 4: Implementiere Readiness und nichtblockierendes `get`**

Der Worker setzt die aktuellen Validator-Methoden um:

```perl
sub is_ready  { return $_[0]{state} ne 'pending' }
sub is_failed { return $_[0]{state} eq 'failed' }

sub get {
  my ($self) = @_;
  DBIO::Exception->throw('Cannot get a pending DBIO::Test::Future')
    unless $self->is_ready;
  DBIO::Exception->throw($self->{values}[0])
    if $self->is_failed;
  return wantarray ? @{ $self->{values} } : $self->{values}[0];
}
```

Der Helper schläft, pollt und blockiert nirgends.

- [ ] **Step 5: Implementiere `then` und `catch` als registrierte Continuations**

Der Worker verwendet diese konkrete Struktur:

```perl
sub then {
  my ($self, $on_done, $on_fail) = @_;
  my $derived = ref($self)->new;
  push @{ $self->{callbacks} }, [ $derived, $on_done, $on_fail ];
  $self->_drain_callbacks if $self->is_ready;
  return $derived;
}

sub catch {
  my ($self, $on_fail) = @_;
  return $self->then(undef, $on_fail);
}

sub _drain_callbacks {
  my ($self) = @_;
  while (my $entry = shift @{ $self->{callbacks} }) {
    $self->_run_callback(@$entry);
  }
  return;
}
```

- [ ] **Step 6: Implementiere skalare Callback-Auswertung und Failure-Routing**

Der vorgeschlagene neue private `_run_callback` unterscheidet Parent-Status, passt ohne Handler die Originalwerte durch und fängt nur den tatsächlich aufgerufenen Callback:

```perl
sub _run_callback {
  my ($self, $derived, $on_done, $on_fail) = @_;
  my $callback = $self->is_failed ? $on_fail : $on_done;

  unless ($callback) {
    return $self->is_failed
      ? $derived->fail(@{ $self->{values} })
      : $derived->done(@{ $self->{values} });
  }

  my ($ok, $result, $error);
  {
    local $@;
    $ok = eval {
      $result = scalar $callback->(@{ $self->{values} });
      1;
    };
    $error = $@ unless $ok;
  }
  return $derived->fail($error) unless $ok;
  return $self->_adopt_result($derived, $result);
}
```

- [ ] **Step 7: Implementiere pending-Flattening ausschließlich für den Testhelper**

Der vorgeschlagene neue private `_adopt_result` übernimmt auch eine noch pending Test-Future:

```perl
sub _adopt_result {
  my ($self, $derived, $result) = @_;
  unless (Scalar::Util::blessed($result)
      && $result->isa('DBIO::Test::Future')) {
    return $derived->done($result);
  }

  $result->then(
    sub {
      $derived->done(@_);
      return;
    },
    sub {
      $derived->fail($_[0]);
      return;
    },
  );
  return $derived;
}
```

Andere Future-Klassen werden nicht still als kompatibel behauptet.

- [ ] **Step 8: Implementiere `needs_all` mit Input-Reihenfolge**

Der Worker verwendet pro Input einen Slot und settled das Aggregat höchstens einmal:

```perl
sub needs_all {
  my ($class, @futures) = @_;
  my $aggregate = $class->new;
  return $aggregate->done unless @futures;

  my $remaining = scalar @futures;
  my @results;
  for my $index (0 .. $#futures) {
    $futures[$index]->then(
      sub {
        $results[$index] = [ @_ ];
        unless (--$remaining) {
          $aggregate->done(map { @$_ } @results)
            unless $aggregate->is_ready;
        }
        return;
      },
      sub {
        $aggregate->fail($_[0]) unless $aggregate->is_ready;
        return;
      },
    );
  }
  return $aggregate;
}
```

- [ ] **Step 9: Beende das Modul, korrigiere Packaging und dokumentiere k202**

Das Modul endet mit:

```perl
1;
```

In `dist.ini` lässt der Worker `[MetaNoIndex]` und die Entscheidung, öffentliche Test-Facilities indexiert zu lassen, unverändert. Er ersetzt nur das Ende des vorhandenen Kommentars durch:

```ini
; structural check, used by four driver dists in their t/00-load.t),
; DBIO::Test::AsyncHarness (the live-harness base the EV transports
; inherit from), and DBIO::Test::Future (the manually settled helper for
; deterministic core async tests).
```

Es wird kein `no_index`, Prerequisite- oder Bundle-Umbau eingeführt. In `Changes` ergänzt der Worker im bestehenden `{{$NEXT}}`-Bereich einen knappen k202-Eintrag: Core liefert nun eine deterministische Deferred-Test-Future; sieben rein offline laufende Async-/Pooltests benötigen CPAN `Future` nicht mehr.

- [ ] **Step 10: Prüfe den Produktions-Diff gegen die Allowlist**

Run as Main:

```bash
git diff --name-only -- lib/DBIO/Test/Future.pm dist.ini Changes
git diff -- lib/DBIO/Test/Future.pm dist.ini Changes
```

Expected: genau die Modulneuanlage, der einzelne historische `dist.ini`-Hinweis und der k202-Eintrag in `Changes`; keine Teständerung durch den Worker.

- [ ] **Step 11: Führe den Contract-Test grün aus**

Run as Main:

```bash
set -o pipefail
maint/capped-test prove -l t/test/31_test_future.t 2>&1 \
  | tee /tmp/dbio-k202-contract-green.log
```

Expected: PASS; alle neun Subtests laufen, kein Skip.

---

### Task 3: Migration ohne CPAN Future verifizieren, installieren und übergeben

**Files:**
- Verify: alle in Task 1 und Task 2 genannten Dateien
- Reference unchanged: `cpanfile`, `t/test/09_async.t`, `t/test/30_async_harness.t`, `xt/podcoverage.t`
- Protect from ticket commit: `.claude/skills/kanban-issues-karr-cli/SKILL.md`

**Interfaces:**
- Consumes: den grünen Helper und den vollständigen Test-Diff.
- Produces: einen einzelnen lokalen k202-Commit und den Main-seitigen Handoff mit realen Testzahlen.

- [ ] **Step 1: Führe die vier Fake-Migrationen fokussiert aus**

Run:

```bash
set -o pipefail
maint/capped-test prove -l \
  t/test/15_async_orchestration.t \
  t/test/16_async_future_io_convention.t \
  t/test/19_async_deploy.t \
  t/resultset/with_context.t \
  2>&1 | tee /tmp/dbio-k202-local-fakes.log
```

Expected: PASS, keine Skips, alle `isa_ok`-Checks nennen `DBIO::Test::Future`.

- [ ] **Step 2: Installiere eine absichtlich nicht ladbare CPAN-Future-Schattenklasse in `/tmp`**

Run:

```bash
rm -rf /tmp/dbio-k202-no-cpan-future
mkdir -p /tmp/dbio-k202-no-cpan-future
printf '%s\n' 'die "CPAN Future must not load in k202 offline tests\n";' \
  > /tmp/dbio-k202-no-cpan-future/Future.pm
```

Expected: nur `/tmp/dbio-k202-no-cpan-future/Future.pm` entsteht; der Repo-Arbeitsbaum ändert sich nicht.

- [ ] **Step 3: Führe die sieben ehemals geskippeden Dateien gegen die Schattenklasse aus**

Run:

```bash
set -o pipefail
maint/capped-test env \
  PERL5LIB="/tmp/dbio-k202-no-cpan-future${PERL5LIB:+:$PERL5LIB}" \
  prove -l \
    t/storage/pool_base.t \
    t/storage/pool_readiness.t \
    t/storage/pool_ready_wiring.t \
    t/storage/pool_connect_actions.t \
    t/storage/async_connect_info_leak.t \
    t/storage/async_access_broker.t \
    t/composed/async_mirror.t \
  2>&1 | tee /tmp/dbio-k202-no-cpan-future.log
```

Expected: PASS, die absichtliche Meldung `CPAN Future must not load` erscheint nicht und keine Datei meldet `skip_all`.

- [ ] **Step 4: Führe Validator-, Namespace- und Produktions-Immediate-Referenzen aus**

Run:

```bash
set -o pipefail
maint/capped-test prove -l \
  t/test/09_async.t \
  t/test/31_test_future.t \
  t/55namespaces_cleaned.t \
  2>&1 | tee /tmp/dbio-k202-contract-reference.log
```

Expected: PASS; Immediate-Vertrag und Test-Future-Vertrag bleiben getrennt.

- [ ] **Step 5: Führe alle k202-Dateitests in einem zählbaren fokussierten Lauf aus**

Run:

```bash
set -o pipefail
maint/capped-test prove -l \
  t/test/09_async.t \
  t/test/15_async_orchestration.t \
  t/test/16_async_future_io_convention.t \
  t/test/19_async_deploy.t \
  t/test/31_test_future.t \
  t/resultset/with_context.t \
  t/storage/pool_base.t \
  t/storage/pool_readiness.t \
  t/storage/pool_ready_wiring.t \
  t/storage/pool_connect_actions.t \
  t/storage/async_connect_info_leak.t \
  t/storage/async_access_broker.t \
  t/composed/async_mirror.t \
  t/55namespaces_cleaned.t \
  2>&1 | tee /tmp/dbio-k202-focused.log
```

Expected: PASS, keine Skips in den dreizehn direkt migrierten/neu angelegten Tests.

- [ ] **Step 6: Führe die vollständige rekursive Suite aus**

Run:

```bash
set -o pipefail
maint/capped-test dzil test 2>&1 | tee /tmp/dbio-k202-full.log
```

Expected: Exit 0 und `Result: PASS`; rekursive Unterverzeichnisse sind enthalten.

- [ ] **Step 7: Installiere den abgeschlossenen Core**

Run:

```bash
set -o pipefail
maint/capped-test dzil install 2>&1 | tee /tmp/dbio-k202-install.log
```

Expected: Exit 0; der aktuelle Core einschließlich `DBIO::Test::Future` ist installiert.

- [ ] **Step 8: Räume nur die `/tmp`-Schattenklasse auf**

Run:

```bash
rm -rf /tmp/dbio-k202-no-cpan-future
```

Expected: kein Repo-Pfad wird entfernt.

- [ ] **Step 9: Stage exakt die k202-Allowlist**

Run:

```bash
git add -- \
  lib/DBIO/Test/Future.pm \
  dist.ini \
  Changes \
  t/test/31_test_future.t \
  t/test/15_async_orchestration.t \
  t/test/16_async_future_io_convention.t \
  t/test/19_async_deploy.t \
  t/resultset/with_context.t \
  t/storage/pool_base.t \
  t/storage/pool_readiness.t \
  t/storage/pool_ready_wiring.t \
  t/storage/pool_connect_actions.t \
  t/storage/async_connect_info_leak.t \
  t/storage/async_access_broker.t \
  t/composed/async_mirror.t \
  t/55namespaces_cleaned.t
```

Expected: Die nicht ticketrelevante Skill-Datei ist nicht gestaged.

- [ ] **Step 10: Prüfe Cached Diff und verbotene Pfade**

Run:

```bash
git diff --cached --check
git diff --cached --name-only
test -z "$(git diff --cached --name-only -- \
  .claude/skills/kanban-issues-karr-cli/SKILL.md cpanfile)"
```

Expected: exakt die sechzehn in Step 9 genannten Dateien; kein `cpanfile` und kein `.claude`-Pfad.

- [ ] **Step 11: Committe k202 lokal**

Run:

```bash
git commit \
  -m "test(async): add deterministic deferred Future (karr k202)" \
  -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

Expected: genau ein lokaler k202-Commit; kein Push.

- [ ] **Step 12: Prüfe den Arbeitsbaum nach dem Commit**

Run:

```bash
git status --short
```

Expected: keine Ausgabe.

- [ ] **Step 13: Übergib k202 Main-seitig und seriell nach Review**

Run:

```bash
TICKET_ID=202
CLAIM=$(karr agent-name)
FOCUSED=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k202-focused.log)
FULL=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k202-full.log)
karr handoff "$TICKET_ID" --claim "$CLAIM" \
  --note "Commit $(git rev-parse --short HEAD). Focused: $FOCUSED, Result: PASS, no skips. Full: $FULL, Result: PASS. maint/capped-test dzil install: PASS. CPAN Future shadow test: PASS." \
  -t
```

Expected: k202 steht in `review`; erst danach darf Main k200 claimen.

## Exakter Rollback für einen blockierten k202-Zustand

Vor einem Blocker-Handoff führt Main aus:

```bash
git restore --staged -- .
git restore --worktree -- \
  Changes \
  dist.ini \
  t/test/15_async_orchestration.t \
  t/test/16_async_future_io_convention.t \
  t/test/19_async_deploy.t \
  t/resultset/with_context.t \
  t/storage/pool_base.t \
  t/storage/pool_readiness.t \
  t/storage/pool_ready_wiring.t \
  t/storage/pool_connect_actions.t \
  t/storage/async_connect_info_leak.t \
  t/storage/async_access_broker.t \
  t/composed/async_mirror.t \
  t/55namespaces_cleaned.t
git clean -f -- lib/DBIO/Test/Future.pm t/test/31_test_future.t
rm -rf /tmp/dbio-k202-no-cpan-future
git status --short
```

Expected: Der Arbeitsbaum ist clean. Main setzt anschließend `TICKET_ID=202`, formuliert `BLOCK_REASON` aus der exakten roten Diagnose und führt den im Masterplan definierten seriellen `karr edit "$TICKET_ID" --block "$BLOCK_REASON" --release` aus.
