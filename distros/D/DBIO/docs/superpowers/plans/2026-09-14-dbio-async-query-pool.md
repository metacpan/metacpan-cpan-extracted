# DBIO Async Query and Pool Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** k193, k197 und k198 stellen in dieser Reihenfolge synchrone Select-Semantik, Readiness-Slot-Recovery und terminalen Pool-Shutdown für Core-Async wieder her.

**Architecture:** Async-SELECT delegiert seine vollständige Vorbereitung an die bestehende `_select_args`-Naht des owning Sync-Storage und wendet `software_limit` auf rohen Transportzeilen vor Inflation/Collapse an. Danach wird der Pool in zwei getrennten Inkrementen gehärtet: Readiness-Fehler benutzen ein idempotentes Retirement, anschließend markiert Shutdown die Poolinstanz terminal und settled Queue- sowie Readiness-Waiter deterministisch.

**Tech Stack:** Perl 5, `DBIO::Storage::Async`, `DBIO::Storage::DBI::_select_args`, `DBIO::ResultSet`, `DBIO::Storage::PoolBase`, `DBIO::Test::Storage`, `DBIO::Test::Future`, `Test::More`, `Test::Exception`, Dist::Zilla, `maint/capped-test`, karr.

**Spec:** `docs/superpowers/specs/2026-09-14-dbio-core-async-hardening-design.md`

## Global Constraints

- Reihenfolge in diesem Plan: k193 → k197 → k198; k197 muss vor k198 grün, installiert, committed und in Review sein.
- k193 ruft ausschließlich die bestehende Signatur `_select_args($ident, $select, $where, $orig_attrs)` des owning Sync-Storage auf; keine neue DBI-Hilfs-API.
- `_select_args` bleibt zuständig für `rows`-/`offset`-Diagnosen, Offset-only-`__max_int`, Join-Pruning, Complex-Prefetch-Rewrite und `_last_sqlmaker_alias_map`.
- `software_limit` wird wie synchron auf rohen Zeilen vor Inflation und Collapse angewendet. Fertige Hauptobjekte nach Collapse zu slicen ist verboten, weil Children abgeschnitten oder andere Parent-Grenzen erzeugt würden.
- Async SQLMaker behält rohe `?`-Platzhalter; kein Caller und keine neue Select-Naht formt Transport-Platzhalter.
- `select_single_async` wird nicht nebenbei um eine neue Software-limit-Semantik erweitert; es nutzt die Select-Vorbereitung, sein bestehender Einzelzeilen-Vertrag bleibt aber erhalten.
- Readiness-Fehler bleiben failed Futures, werfen nicht synchron, räumen `_connections` und `_ready` auf und geben den Slot unmittelbar frei.
- `_retire_connection` wird idempotent; eine nie ready gewordene Connection führt keine Disconnect-Actions aus.
- Shutdown ist terminal und idempotent für dieselbe Poolinstanz; Restart geschieht nur durch einen neuen Backend-/Pool-Aufbau im höheren DBIO-Reconnect-Pfad.
- Neue `acquire`-/`acquire_txn`-Aufrufe nach Shutdown liefern failed `DBIO::Test::Future`-kompatible Futures mit `Connection pool has been shut down`.
- Jede Connection wird höchstens einmal geschlossen; Late Releases füllen weder `_idle` noch `_waiters`.
- Core-Tests sind rein offline; keine reale DB, kein SQLite-DSN, kein Event Loop.
- Teständerungen gehören `dbio-test-mock-writer`, Produktions-/POD-/ADR-Änderungen `dbio-worker`, Claim/Diff/Test/Git/karr ausschließlich Main.
- Pro Ticket genau ein lokaler Commit mit `kNN` und Co-Author-Zeile; der Arbeitsbaum ist nach dem Plan-Commit clean und `.claude/skills/kanban-issues-karr-cli/SKILL.md` bleibt aus allen drei Ticket-Commits ausgeschlossen.
- Jedes Ticket ergänzt `Changes` im passenden `{{$NEXT}}`-Abschnitt und staged diesen Eintrag zusammen mit seinem Test-/Runtime-Diff.
- Nach jedem Ticket fokussierter capped Lauf, `maint/capped-test dzil test`, `maint/capped-test dzil install`, lokaler Commit, serieller Main-Handoff.
- Kein Push, Release oder Driver-Repo-Edit.

---

## Aktueller Call-Graph und Dateiverantwortung

### k193

- `lib/DBIO/ResultSet.pm:2265-2297` — `all_async($self)` ruft `_rs_run_async`, danach `_inflate_fetched_rows($self, $raw_rows)`.
- `lib/DBIO/ResultSet.pm:2233-2247` — `_inflate_fetched_rows` setzt temporär `DBIO::ResultSet::_PrefetchedCursor` ein.
- `lib/DBIO/ResultSet.pm:2500-2518` — `_PrefetchedCursor::all($self)` gibt derzeit jede Rohzeile unverändert zurück und kennt keine Softwaregrenze.
- `lib/DBIO/Storage/Async.pm:730-744` — `select_async($self, @args)` und `select_single_async($self, @args)`.
- `lib/DBIO/Storage/Async.pm:808-869` — `_run_crud($self, $op, $runner, @args)` rendert derzeit selbst und unterdrückt Limits bei `software_limit`/`collapse`.
- `lib/DBIO/Storage/Async.pm:974-990` — `_pool_runner` und `_pinned_runner($conn)` liefern Coderefs der Form `($sql, $bind_arrayref) -> Future`.
- `lib/DBIO/Storage/DBI.pm:3490-3613` — kanonische `_select_args`-Signatur und Reihenfolge.
- `lib/DBIO/Storage/QueryRewrite.pm:113-269` — bestehendes Complex-Prefetch-Rewrite.
- `lib/DBIO/Storage/DBI/Cursor.pm:117-202` und `lib/DBIO/Cursor.pm:76-85` — synchrone Raw-row-before-collapse-Referenz.
- `lib/DBIO/Manual/AsyncStorage.pod:78-106` — ersetzt die aktuelle Dokumentation der noch fehlenden Rewrite-Parität durch den implementierten Owner-Storage-Pfad.
- `t/test/15_async_orchestration.t:171-299` — echter `_run_crud`-Pfad über `sync_orch_backend`; neue Ergebnis-, Diagnose-, Join- und Rewrite-Zeugen.
- `t/resultset/async_backend.t:103-142` — unveränderte unabhängige Inflation-/Collapse-Oracle; `rowmock` umgeht `_run_crud` und ist deshalb kein alleiniger k193-Zeuge.
- `t/test/08_replicated.t:522-541` — synchrone instrumentierte Referenz für Complex-Prefetch-Join-Pruning mit `CD`, nichtmultiplying `artist`, multiplying `tracks` und `rows => 2`.
- `t/prefetch/with_limit.t:42-82` — synchrone Complex-Prefetch-SQL-Referenz.

### k197

- `lib/DBIO/Storage/PoolBase.pm:178-224` — `acquire($self)` und `_acquire_slot($self)`.
- `lib/DBIO/Storage/PoolBase.pm:291-301` — `_connection_ready_future($self, $conn)`.
- `lib/DBIO/Storage/PoolBase.pm:332-348` — `_create_ready_connection($self, @named_args)`.
- `lib/DBIO/Storage/PoolBase.pm:390-430` — `_register_connection_ready`, Lookup und Clear.
- `lib/DBIO/Storage/PoolBase.pm:512-572` — `_spawn_connection` und `_retire_connection($self, $conn)`.
- `t/storage/pool_readiness.t:183-209` — entfernt das maskierende manuelle `release($bad)` und fordert Retirement/Ersatzkapazität.
- `t/storage/pool_ready_wiring.t:120-151` — ergänzt exact-once Close/Clear im produktionsnäheren Wiring.
- `t/storage/pool_connect_actions.t:306-341` — unveränderte strukturelle Referenz für Slot-Retirement.

### k198

- `lib/DBIO/Storage/PoolBase.pm:108-139` — neue interne terminale Zustandszelle zusätzlich zu `_connections`, `_idle`, `_waiters`, `_ready`.
- `lib/DBIO/Storage/PoolBase.pm:490-510` — `shutdown($self)` wird terminal und settled Waiter.
- `lib/DBIO/Storage/PoolBase.pm:627-630` — `DESTROY` bleibt durch idempotenten Shutdown sicher.
- `lib/DBIO/Storage/Pool.pm:36-104` — formalisiert den bereits von Async aufgerufenen `shutdown`-Poolvertrag; dies ist eine neue vorgeschlagene abstrakte Methodendeklaration, keine aktuell vorhandene Signatur. Die sechs alten abstrakten Methoden verwenden noch `croak`; der neue F21-konforme Refusal benutzt `DBIO::Exception->throw`, ohne die Nachbarn nebenbei umzuschreiben.
- `lib/DBIO/Storage/DBI.pm:1333-1357` — unveränderter höherer Disconnect löscht `_async_storage_obj`.
- `lib/DBIO/Storage/Async.pm:1704-1709` — unveränderter Backend-Disconnect ruft Pool-Shutdown und verwirft `{pool}`.
- `lib/DBIO/Manual/AsyncStorage.pod:255-287` — dokumentiert terminale Poolinstanz und Reconnect über Neuanlage.
- `docs/adr/0030-async-explicit-per-connection-mode.md` — Amendment zum terminalen Shutdown und neuer Generation.
- `t/storage/pool_base.t` — Queue-Waiter, Post-shutdown Acquire, Late Release, doppelte Ausführung.
- `t/storage/pool_readiness.t` und `t/storage/pool_ready_wiring.t` — Shutdown während pending Readiness und späte Callbacks.
- `t/test/14_async_backend.t:229-243` — wird erst in k198 zu einem echten Rebuild-Zeugen erweitert; aktuell belegt der Block nur den alten Disconnect.

---

### Task 1: k193 — Async-Select-Parität

**Files:**
- Modify by worker: `Changes`
- Modify by test agent: `t/test/15_async_orchestration.t`
- Reference test: `t/resultset/async_backend.t`
- Reference test: `t/prefetch/with_limit.t`
- Modify by worker: `lib/DBIO/Storage/Async.pm`
- Modify by worker: `lib/DBIO/Manual/AsyncStorage.pod`
- Read-only reference: `lib/DBIO/Storage/DBI.pm`
- Read-only reference: `lib/DBIO/Storage/DBI/Cursor.pm`
- Read-only reference: `lib/DBIO/Cursor.pm`

**Interfaces:**
- Consumes: k195s validierte Context-Propagation und k202s `DBIO::Test::Future`; bestehende `_select_args($ident, $select, $where, $orig_attrs)` gibt `('select', $from, $select, $where, $attrs, @limit_args)` zurück.
- Produces: `_run_crud($self, 'select'|'select_single', $runner, @args)` rendert vorbereitete Owner-Storage-Argumente; bei `select` und `software_limit` löst die Future mit der gesliceten Rohzeilenliste auf.

- [ ] **Step 1: Prüfe und claime k193 als Main**

```bash
TICKET_ID=193
CLAIM=$(karr agent-name)
karr show "$TICKET_ID"
karr move "$TICKET_ID" in-progress --claim "$CLAIM"
```

Expected: k195 ist bereits in `review`; k193 war unclaimed und unblocked.

- [ ] **Step 2: Delegiere nur den roten k193-Test-Diff an `dbio-test-mock-writer`**

Handoff prompt:

```text
Schreibe ausschließlich die roten k193-Zeugen in
`t/test/15_async_orchestration.t` nach Task 1 von
`docs/superpowers/plans/2026-09-14-dbio-async-query-pool.md`.
Lies die vollständige Async-Hardening-Spec und konsumiere die installierten
k202-/k195-Commits. Ändere keine Produktionsdatei, keinen Git-Index und kein
karr. Miss Ergebnis-IDs und vollständige Children, nicht nur SQL. Verwende den
echten registrierten `sync_orch_backend`; `rowmock` aus
`t/resultset/async_backend.t` ist nur die unveränderte Collapse-Oracle.
Berichte roten Befehl, Diagnose und Claim.
```

Expected artifacts: Test-Diff nur in `t/test/15_async_orchestration.t`, neue Blocküberschriften, roter capped Lauf, Claim-Satz.

- [ ] **Step 3: Erweitere das Fake um SQL-abhängige Rohzeilen**

Der Testagent lässt den bestehenden `{next_rows}`-Pfad intakt und ergänzt in `Test::SyncBackend` einen optionalen Provider:

```perl
my @rows = $self->{row_provider}
  ? $self->{row_provider}->($sql, $bind)
  : @{ $self->{next_rows} || [] };
return $self->future_class->done(@rows);
```

Der Produktionsaufbau `DBIO::Storage::DBI->_async_storage` installiert bereits `_owner_storage($self)`; der bestehende `sync_orch_backend`-Block nutzt genau diesen Pfad. Nur direkte `new_backend()`-Aufrufe erhalten vor dem Return:

```perl
$backend->_owner_storage($schema->storage);
```

- [ ] **Step 4: Schreibe den roten Software-limit-Ergebniszeugen**

Der Testagent setzt vier vollständige Rohzeilen und fordert Raw-row-Slicing:

```perl
$backend->{next_rows} = [
  [ 1, 'Miles Davis' ],
  [ 2, 'John Coltrane' ],
  [ 3, 'Sun Ra' ],
  [ 4, 'Herbie Hancock' ],
];
my $rs = $schema->resultset('Artist')->search(undef, {
  rows           => 2,
  offset         => 1,
  software_limit => 1,
  order_by       => 'me.artistid',
});
my @artists = $rs->all_async->get;
is_deeply [ map { $_->artistid } @artists ], [2, 3],
  'software_limit slices raw rows before inflation';
unlike $backend->_last_sql, qr/\bLIMIT\b/i,
  'software_limit still suppresses the SQL limit';
```

Current failure: IDs sind `[1, 2, 3, 4]`.

- [ ] **Step 5: Schreibe die exakten Sync-Diagnose-Zeugen**

Der Testagent fordert synchrones Refusal vor Transportdispatch:

```perl
throws_ok {
  $backend->select_async('artist', ['artistid'], {}, {
    rows => 0, software_limit => 1,
  });
} qr/The rows attribute must be a positive integer if present/,
  'software-limit rows validation matches sync';

throws_ok {
  $backend->select_async('artist', ['artistid'], {}, {
    offset => -1, collapse => 1,
  });
} qr/A supplied offset attribute must be a non-negative integer/,
  'collapse offset validation matches sync';
```

Vor dem Fix werden beide ungültigen Werte wegen der Limit-Unterdrückung nicht von `_run_crud` validiert.

- [ ] **Step 6: Schreibe Offset-only- und Join-Pruning-Zeugen**

Der Offset-only-Fall verwendet einen ResultSet-Call über `sync_orch_backend`:

```perl
my $offset_rs = $schema->resultset('Artist')->search(undef, {
  offset   => 1,
  order_by => 'me.artistid',
});
$offset_rs->all_async->get;
like $backend->_last_sql, qr/LIMIT \? OFFSET \?/,
  'offset-only select receives the SQLMaker max-int limit';
```

Die in `t/test/15_async_orchestration.t:197-270` bereits vorhandenen Offset-only-Bind-Assertions bleiben unverändert und belegen `sql_maker->__max_int` plus Offset `1`.

Für Join-Pruning benutzt der Testagent die nachweislich gültige, bereits in `t/test/08_replicated.t:522-541` gepinnte Form; ein bare `Artist join => 'cds'` wäre falsch, weil der multiplying `cds`-Join absichtlich erhalten bleibt:

```perl
my @pruned;
{
  no warnings 'redefine';
  my $orig = \&DBIO::Storage::QueryRewrite::_prune_unused_joins;
  local *DBIO::Storage::QueryRewrite::_prune_unused_joins = sub {
    my ($self, @args) = @_;
    my ($from, $aliastypes) = $orig->($self, @args);
    push @pruned, (keys %{ $aliastypes || {} }) ? 1 : 0;
    return ($from, $aliastypes);
  };

  $backend->{next_rows} = [];
  $schema->resultset('CD')->search(
    { 'artist.name' => 'x' },
    {
      join     => 'artist',
      prefetch => 'tracks',
      rows     => 2,
      order_by => 'me.cdid',
    },
  )->all_async->get;
}
is_deeply \@pruned, [1, 0],
  'async complex prefetch runs owning-storage join pruning twice in the canonical shape';
```

Vor k193 bleibt `@pruned` leer, weil `_run_crud` den Owner-Storage umgeht.

- [ ] **Step 7: Schreibe den roten Complex-Prefetch-Zeugen mit vollständigen Children**

Der Provider besitzt drei Artists, liefert bei vorhandenem inneren Limit aber nur die ersten zwei Parents mit allen Child-Zeilen:

```perl
my @all_join_rows = (
  [ 1, 'Miles Davis',   13, undef, 10, 1, 'Kind of Blue',   1959, undef, undef ],
  [ 1, 'Miles Davis',   13, undef, 11, 1, 'Bitches Brew',   1970, undef, undef ],
  [ 2, 'John Coltrane', 13, undef, 20, 2, 'A Love Supreme', 1965, undef, undef ],
  [ 3, 'Sun Ra',        13, undef, 30, 3, 'Space Is the Place', 1973, undef, undef ],
);
$backend->{row_provider} = sub {
  my ($sql) = @_;
  return $sql =~ /\bLIMIT\b/i
    ? @all_join_rows[0 .. 2]
    : @all_join_rows;
};
my $prefetched = $schema->resultset('Artist')->search(undef, {
  prefetch => 'cds',
  rows     => 2,
  order_by => 'me.artistid',
});
my @artists = $prefetched->all_async->get;
is_deeply [ map { $_->artistid } @artists ], [1, 2],
  'complex prefetch returns two master rows';
is_deeply [ sort { $a <=> $b } map { $_->cdid } $artists[0]->cds->all ],
  [10, 11], 'last included master retains every prefetched child';
like $backend->_last_sql, qr/\bLIMIT\b/i,
  'complex prefetch uses an inner limited select';
```

Current failure: der direkte Async-SQLMaker-Pfad erzeugt kein Complex-Prefetch-Rewrite und liefert drei Masters.

- [ ] **Step 8: Führe k193 rot aus und fixiere den Claim**

```bash
set -o pipefail
maint/capped-test prove -l t/test/15_async_orchestration.t 2>&1 \
  | tee /tmp/dbio-k193-red.log
```

Expected: FAIL an Ergebnis-IDs, Sync-Diagnosen, Join-Pruning und innerem Prefetch-Limit; keine Fixture-/Syntaxfehler.

Claim:

```text
k193 behauptet: Async-SELECT muss exakt die owning `_select_args`-Vorbereitung
benutzen und `software_limit` auf Transportzeilen vor Inflation/Collapse
anwenden; SQL-only Assertions ohne Ergebnis- und Child-Parität genügen nicht.
```

- [ ] **Step 9: Delegiere die minimale Implementierung an `dbio-worker`**

Handoff prompt:

```text
Implementiere nur k193 Task 1 gegen den vom Main bestätigten roten Diff.
Ändere `lib/DBIO/Storage/Async.pm`, die betroffene Beschreibung in
`lib/DBIO/Manual/AsyncStorage.pod` und `Changes`. Verwende die bestehende
owner-storage `_select_args($ident,$select,$where,$attrs)`-Naht; ändere weder
DBI-Signatur noch Cursor. Slice nur `select`-Rohzeilen und gib aus dem
Continuation-Callback eine `future_class->done(@rows)` zurück. Ändere keine
Tests, Git-Index oder karr. Der Changes-Eintrag nennt Ergebnis- und
Complex-Prefetch-Parität.
```

Expected artifacts: Produktions-/POD-Diff, Methodenliste, fokussierter PASS, Bestätigung des unveränderten Claims.

- [ ] **Step 10: Ersetze die direkte Select-Vorbereitung durch `_select_args`**

Der Worker formt den Select-Zweig in `_run_crud` nach dieser exakten Struktur; `_prepare_select_args_async` ist ein neuer vorgeschlagener privater Name:

```perl
sub _prepare_select_args_async {
  my ($self, @args) = @_;
  my $owner = $self->_owner_storage;
  $self->throw_exception('async SELECT requires its owning sync storage')
    unless $owner && $owner->can('_select_args');
  my @prepared = $owner->_select_args(@args);
  shift @prepared;
  return @prepared;
}

if ($op eq 'select' || $op eq 'select_single') {
  @args = $self->_prepare_select_args_async(@args);
  my $attrs = $args[3] || {};
  my ($sql, @bind) = $self->sql_maker->select(@args);
  my $future = $runner->($sql, \@bind);
```

Der führende Rückgabewert `'select'` aus `_select_args` wird einmal entfernt; der Async-SQLMaker erhält `($from, $select, $where, $attrs, @limit_args)`.

- [ ] **Step 11: Slice nur `select`-Rohzeilen bei `software_limit`**

Der Worker ergänzt vor der bestehenden `select_single`-Abbildung:

```perl
  if ($op eq 'select' && $attrs->{software_limit}) {
    my $rows   = $attrs->{rows};
    my $offset = $attrs->{offset} || 0;
    my $fc = $self->future_class;
    $future = $future->then(sub {
      my @raw_rows = @_;
      splice @raw_rows, 0, $offset if $offset;
      splice @raw_rows, $rows if $rows && @raw_rows > $rows;
      return $fc->done(@raw_rows);
    });
  }
```

Danach bleibt der aktuelle `select_single`-Callback strukturell erhalten. Es wird niemals nach `_inflate_fetched_rows` oder `_construct_results` gesliced.

- [ ] **Step 12: Aktualisiere ausschließlich die veraltete AsyncStorage-Beschreibung**

`lib/DBIO/Manual/AsyncStorage.pod:78-106` beschreibt danach:

- Select-Argumente laufen über den owning Sync-Storage und `_select_args`;
- Complex-Prefetch-/Join-Rewrite geschieht vor SQLMaker;
- `software_limit` schneidet rohe Resultzeilen vor ORM-Inflation;
- Platzhalterformung bleibt ausschließlich Transportaufgabe.

- [ ] **Step 13: Führe k193 fokussiert grün aus**

```bash
set -o pipefail
maint/capped-test prove -l \
  t/test/15_async_orchestration.t \
  t/test/08_replicated.t \
  t/resultset/async_backend.t \
  t/prefetch/with_limit.t \
  2>&1 | tee /tmp/dbio-k193-focused.log
```

Expected: PASS; Ergebnis-IDs und Children stimmen, Sync-Oracle bleibt grün.

- [ ] **Step 14: Führe die vollständige rekursive Suite aus**

```bash
set -o pipefail
maint/capped-test dzil test 2>&1 | tee /tmp/dbio-k193-full.log
```

Expected: Exit 0, Full Suite `Result: PASS`.

- [ ] **Step 15: Installiere den abgeschlossenen Core**

```bash
set -o pipefail
maint/capped-test dzil install 2>&1 | tee /tmp/dbio-k193-install.log
```

Expected: Exit 0.

- [ ] **Step 16: Stage k193 exakt**

```bash
git add -- \
  Changes \
  lib/DBIO/Storage/Async.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  t/test/15_async_orchestration.t
```

Expected: Die vier k193-Dateien sind gestaged.

- [ ] **Step 17: Prüfe den k193-Cached-Diff**

```bash
git diff --cached --check
test -z "$(git diff --cached --name-only -- \
  .claude/skills/kanban-issues-karr-cli/SKILL.md)"
git diff --cached --name-only
```

Expected: exakt vier Dateien und kein Fremdpfad.

- [ ] **Step 18: Committe k193 lokal**

```bash
git commit \
  -m "fix(async): restore select preparation parity (karr k193)" \
  -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

Expected: genau ein lokaler k193-Commit; kein Push.

- [ ] **Step 19: Übergib k193 Main-seitig und seriell**

```bash
TICKET_ID=193
CLAIM=$(karr agent-name)
FOCUSED=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k193-focused.log)
FULL=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k193-full.log)
karr handoff "$TICKET_ID" --claim "$CLAIM" \
  --note "Commit $(git rev-parse --short HEAD). Focused: $FOCUSED, Result: PASS. Full: $FULL, Result: PASS. maint/capped-test dzil install: PASS. Raw-row software limit and complete-prefetch children verified." \
  -t
```

Expected: k193 in `review`; der Arbeitsbaum ist clean.

**k193 rollback:**

```bash
git restore --staged -- .
git restore --worktree -- \
  Changes \
  lib/DBIO/Storage/Async.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  t/test/15_async_orchestration.t
git status --short
```

---

### Task 2: k197 — Readiness-Fehler retiren

**Files:**
- Modify by worker: `Changes`
- Modify by test agent: `t/storage/pool_readiness.t`
- Modify by test agent: `t/storage/pool_ready_wiring.t`
- Reference test: `t/storage/pool_connect_actions.t`
- Modify by worker: `lib/DBIO/Storage/PoolBase.pm`

**Interfaces:**
- Consumes: k202s pending Test-Future und den bestehenden `_retire_connection($conn)`-Pfad.
- Produces: Readiness-Fehler retiren einmal, löschen `_connections`/`_ready`, schließen best-effort und lassen sofort Ersatz-Spawn zu; k198 konsumiert dieses idempotente Retirement.

- [ ] **Step 1: Prüfe und claime k197 als Main**

```bash
TICKET_ID=197
CLAIM=$(karr agent-name)
karr show "$TICKET_ID"
karr move "$TICKET_ID" in-progress --claim "$CLAIM"
```

Expected: k193 ist in `review`; k197 war unclaimed und unblocked.

- [ ] **Step 2: Delegiere die Readiness-Regressionsfälle an `dbio-test-mock-writer`**

Handoff prompt:

```text
Schreibe nur den roten k197-Diff in `t/storage/pool_readiness.t` und
`t/storage/pool_ready_wiring.t` nach Task 2 dieses Plans. Nutze
DBIO::Test::Future aus k202, max_size 1 und keinen manuellen release des
fehlgeschlagenen Handles. Fordere size 0, gelöschtes readiness bookkeeping,
exact-once close und unmittelbar erfolgreichen Ersatz-Spawn. Ändere keine
Produktionsdatei, Git-Index oder karr. Berichte roten capped Lauf und Claim.
```

- [ ] **Step 3: Ersetze den maskierenden Readiness-Test durch Retirement und Ersatz**

Der Testagent ändert den bestehenden Fehlerblock konkret zu:

```perl
my $failed = $pool->acquire;
my $bad = $pool->{_built}[0];
$bad->fire_error('could not connect to server');

ok $failed->is_ready && $failed->is_failed,
  'readiness failure settles acquire as failed Future';
is $pool->size, 0, 'failed readiness retires the occupied slot';
is $pool->_connection_ready_lookup($bad), undef,
  'failed readiness bookkeeping was cleared';
is $bad->{close_count}, 1, 'bad handle was closed exactly once';

my $replacement = $pool->acquire;
my $good = $pool->{_built}[1];
$good->fire_connect;
ok $replacement->is_ready && !$replacement->is_failed,
  'next acquire immediately uses replacement capacity';
```

`FakeAsyncConn::close` beziehungsweise dessen Test-Finish-Seam zählt statt nur einen Boolean zu setzen.

- [ ] **Step 4: Ergänze idempotentes Retirement und ursprünglichen Fehler**

Der Testagent ergänzt:

```perl
$pool->_retire_connection($bad);
is $bad->{close_count}, 1,
  'second retirement does not close the same handle again';
eval { $failed->get };
like $@, qr/could not connect to server/,
  'acquire Future preserves the readiness error';
```

Im wiring-nahen Test wird zusätzlich behauptet, dass eine nie ready gewordene Connection keine Disconnect-Action protokolliert.

- [ ] **Step 5: Führe k197 rot aus und fixiere den Claim**

```bash
set -o pipefail
maint/capped-test prove -l \
  t/storage/pool_readiness.t \
  t/storage/pool_ready_wiring.t \
  2>&1 | tee /tmp/dbio-k197-red.log
```

Expected: FAIL an `size == 0`, Readiness-Clear, Close und Ersatzkapazität; kein manueller Release kaschiert den Slot-Leak.

Claim:

```text
k197 behauptet: Jeder Readiness-Fehler bleibt eine failed Future und retirert
den bereits gezählten Pool-Slot genau einmal, bevor ein nächster Acquire über
das Größenbudget entscheidet.
```

- [ ] **Step 6: Delegiere die minimale PoolBase-Änderung an `dbio-worker`**

Handoff prompt:

```text
Implementiere nur k197 Task 2 in `lib/DBIO/Storage/PoolBase.pm` und `Changes`
gegen den bestätigten roten Diff. Ergänze eine Failure-Continuation am zentralen
Readiness-Gate und mache den bestehenden `_retire_connection($conn)`-Pfad
idempotent. Bewahre den ursprünglichen Fehler als failed Future; Cleanup ist
best-effort. Ändere keine Tests, keinen Git-Index und kein karr. Der Changes-
Eintrag nennt freigegebene Ersatzkapazität nach Readiness-Fehlern.
```

- [ ] **Step 7: Ergänze die zentrale Readiness-Failure-Continuation**

Der Worker strukturiert `acquire` so, dass auch ein synchroner Throw der Readiness-Seam als failed Future endet; `_retire_readiness_failure` ist ein neuer vorgeschlagener privater Name:

```perl
sub _retire_readiness_failure {
  my ($self, $conn, $error) = @_;
  eval { $self->_retire_connection($conn) };
  return $self->future_class->fail($error);
}
```

Die Continuation ruft ihn mit dem Originalfehler auf:

```perl
return $ready->then(
  sub { $self->future_class->done($conn) },
  sub { $self->_retire_readiness_failure($conn, $_[0]) },
);
```

Ein synchroner Wurf beim Ermitteln von `$ready` wird in derselben failed-Future-Form an `_retire_readiness_failure` übergeben.

- [ ] **Step 8: Mache `_retire_connection` durch Membership-Guard idempotent**

Vor dem bestehenden Filter-/Close-/Clear-Block prüft der Worker die aktuelle Registrierung über `Scalar::Util::refaddr`:

```perl
my $addr = Scalar::Util::refaddr($conn);
return unless grep {
  Scalar::Util::refaddr($_) == $addr
} @{ $self->{_connections} };
```

Danach bleiben die vorhandenen Operationen in dieser Reihenfolge: aus `_connections` entfernen, aus `_idle` entfernen falls vorhanden, Handle best-effort schließen, `_clear_connection_ready($conn)`. Disconnect-Actions werden auf diesem nie-ready Retirement-Pfad nicht ergänzt.

- [ ] **Step 9: Führe k197 fokussiert grün aus**

```bash
set -o pipefail
maint/capped-test prove -l \
  t/storage/pool_readiness.t \
  t/storage/pool_ready_wiring.t \
  t/storage/pool_connect_actions.t \
  2>&1 | tee /tmp/dbio-k197-focused.log
```

Expected: PASS; bestehender Connect-action-Retirement-Zeuge bleibt grün.

- [ ] **Step 10: Führe die vollständige rekursive Suite aus**

```bash
set -o pipefail
maint/capped-test dzil test 2>&1 | tee /tmp/dbio-k197-full.log
```

Expected: Exit 0, Full Suite `Result: PASS`.

- [ ] **Step 11: Installiere den abgeschlossenen Core**

```bash
set -o pipefail
maint/capped-test dzil install 2>&1 | tee /tmp/dbio-k197-install.log
```

Expected: Exit 0.

- [ ] **Step 12: Stage k197 exakt**

```bash
git add -- \
  Changes \
  lib/DBIO/Storage/PoolBase.pm \
  t/storage/pool_readiness.t \
  t/storage/pool_ready_wiring.t
```

Expected: vier Ticketdateien sind gestaged.

- [ ] **Step 13: Prüfe den k197-Cached-Diff**

```bash
git diff --cached --check
test -z "$(git diff --cached --name-only -- \
  .claude/skills/kanban-issues-karr-cli/SKILL.md)"
git diff --cached --name-only
```

Expected: exakt die vier k197-Dateien.

- [ ] **Step 14: Committe k197 lokal**

```bash
git commit \
  -m "fix(pool): retire readiness failures (karr k197)" \
  -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

Expected: genau ein lokaler k197-Commit.

- [ ] **Step 15: Übergib k197 Main-seitig und seriell**

```bash
TICKET_ID=197
CLAIM=$(karr agent-name)
FOCUSED=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k197-focused.log)
FULL=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k197-full.log)
karr handoff "$TICKET_ID" --claim "$CLAIM" \
  --note "Commit $(git rev-parse --short HEAD). Focused: $FOCUSED, Result: PASS. Full: $FULL, Result: PASS. maint/capped-test dzil install: PASS. max_size=1 replacement capacity and exact-once retirement verified." \
  -t
```

Expected: k197 in `review`; der Arbeitsbaum ist clean.

**k197 rollback:**

```bash
git restore --staged -- .
git restore --worktree -- \
  Changes \
  lib/DBIO/Storage/PoolBase.pm \
  t/storage/pool_readiness.t \
  t/storage/pool_ready_wiring.t
git status --short
```

---

### Task 3: k198 — Terminaler Pool-Shutdown

**Files:**
- Modify by worker: `Changes`
- Modify by test agent: `t/storage/pool_base.t`
- Modify by test agent: `t/storage/pool_readiness.t`
- Modify by test agent: `t/storage/pool_ready_wiring.t`
- Modify by test agent: `t/test/14_async_backend.t`
- Modify by worker: `lib/DBIO/Storage/PoolBase.pm`
- Modify by worker: `lib/DBIO/Storage/Pool.pm`
- Modify by worker: `lib/DBIO/Manual/AsyncStorage.pod`
- Modify by worker: `docs/adr/0030-async-explicit-per-connection-mode.md`
- Runtime references unchanged: `lib/DBIO/Storage/Async.pm`, `lib/DBIO/Storage/DBI.pm`

**Interfaces:**
- Consumes: k197s idempotentes `_retire_connection`, k202s pending Future und den bestehenden höheren Disconnect/Rebuild-Pfad.
- Produces: terminale Poolinstanz mit stabiler failed-Future-Diagnose, leeren Waiter-/Readiness-Strukturen und einem testbelegten neuen Backend-/Poolobjekt beim Reconnect.

- [ ] **Step 1: Prüfe und claime k198 als Main**

```bash
TICKET_ID=198
CLAIM=$(karr agent-name)
karr show "$TICKET_ID"
karr move "$TICKET_ID" in-progress --claim "$CLAIM"
```

Expected: k197 ist in `review`; k198 war unclaimed und unblocked.

- [ ] **Step 2: Delegiere ausschließlich terminale Pooltests an `dbio-test-mock-writer`**

Handoff prompt:

```text
Schreibe nur den roten k198-Diff in pool_base.t, pool_readiness.t,
pool_ready_wiring.t und t/test/14_async_backend.t nach Task 3 dieses Plans.
Nutze DBIO::Test::Future. Fordere zwei Queue-Waiter, einen readiness-pending
Acquire, Post-shutdown acquire/acquire_txn als failed Futures, Late-release
No-op, doppelten Shutdown und neuen Backend-/Pool-refaddr beim höheren
Reconnect. Ändere keine Produktion, Git-Index oder karr.
```

- [ ] **Step 3: Schreibe Queue-, Post-shutdown- und Late-release-Zeugen**

In `t/storage/pool_base.t` zählt `MockConn::close` Aufrufe. Der Testagent ergänzt:

```perl
my $held = $pool->acquire->get;
my $waiter_one = $pool->acquire;
my $waiter_two = $pool->acquire;
ok !$waiter_one->is_ready && !$waiter_two->is_ready,
  'both acquires are queued before shutdown';

$pool->shutdown;
for my $waiter ($waiter_one, $waiter_two) {
  ok $waiter->is_ready && $waiter->is_failed,
    'queued waiter fails during shutdown';
  eval { $waiter->get };
  like $@, qr/Connection pool has been shut down/,
    'queued waiter receives stable shutdown diagnostic';
}
is_deeply $pool->{_waiters}, [], 'waiters are detached before settlement';

$pool->release($held);
is_deeply $pool->{_idle}, [], 'late release cannot repopulate idle list';
```

- [ ] **Step 4: Schreibe neue-Acquire- und idempotente-Shutdown-Zeugen**

```perl
for my $method (qw/acquire acquire_txn/) {
  my $future;
  lives_ok { $future = $pool->$method }
    "$method after shutdown does not throw synchronously";
  ok $future->is_ready && $future->is_failed,
    "$method after shutdown returns a failed Future";
  eval { $future->get };
  like $@, qr/Connection pool has been shut down/,
    "$method names terminal shutdown";
}

$pool->shutdown;
is $held->{close_count}, 1, 'repeated shutdown does not close twice';
```

- [ ] **Step 5: Schreibe Shutdown-während-Readiness-Zeugen**

In beiden Readiness-Dateien startet der Testagent einen kalten Acquire, ruft vor `fire_connect` Shutdown auf und behauptet:

```perl
ok $acquire->is_ready && $acquire->is_failed,
  'readiness-pending acquire fails during shutdown';
is_deeply $pool->{_waiters}, [], 'no queue waiter remains';
is_deeply $pool->{_ready}, {}, 'readiness bookkeeping is empty';
is $conn->{close_count}, 1, 'cold handle closes exactly once';
$conn->fire_connect;
ok $acquire->is_failed, 'late connect callback cannot revive acquire';
is $conn->{close_count}, 1, 'late callback cannot close twice';
```

Eine kalte Connection führt weiterhin keine Disconnect-Action aus.

- [ ] **Step 6: Erweitere t/test/14 zum echten Rebuild-Zeugen**

Der Testagent ergänzt am Fake-Backend einen pro Instanz erzeugten Fake-Pool und vergleicht nach dem vorhandenen Disconnect:

```perl
my $old_backend = $storage->_async_storage;
my $old_pool = $old_backend->pool;
$storage->disconnect;
my $new_backend = $storage->_async_storage;
my $new_pool = $new_backend->pool;

isnt Scalar::Util::refaddr($new_backend), Scalar::Util::refaddr($old_backend),
  'reconnect resolves a fresh async backend instance';
isnt Scalar::Util::refaddr($new_pool), Scalar::Util::refaddr($old_pool),
  'fresh backend owns a fresh pool instance';
```

Damit wird der bisherige reine Teardown-Block erstmals zum in der Spec verlangten Reconnect-Zeugen.

- [ ] **Step 7: Führe k198 rot aus und fixiere den Claim**

```bash
set -o pipefail
maint/capped-test prove -l \
  t/storage/pool_base.t \
  t/storage/pool_readiness.t \
  t/storage/pool_ready_wiring.t \
  t/test/14_async_backend.t \
  2>&1 | tee /tmp/dbio-k198-red.log
```

Expected: Waiter bleiben aktuell pending, neuer Acquire spawnt erneut und Late Release füllt Idle; der Rebuild-Zeuge fehlt vor dem Test-Diff.

Claim:

```text
k198 behauptet: Shutdown ist ein terminaler, idempotenter Zustand derselben
Poolinstanz, settled alle intern gehaltenen Acquire-Futures und wird nur durch
den höheren Aufbau einer neuen Backend-/Poolgeneration verlassen.
```

- [ ] **Step 8: Delegiere Poolvertrag, Runtime und Docs an `dbio-worker`**

Handoff prompt:

```text
Implementiere nur k198 Task 3 in PoolBase.pm, Pool.pm, AsyncStorage.pod, ADR
0030 und `Changes` gegen den bestätigten roten Diff. Konsumiere k197s
idempotentes Retirement. Markiere Shutdown vor jeder Settlement-Callback-
Ausführung terminal, detach Waiter zuerst, fail pending Readiness, verhindere
neue Acquires und Late-release Repopulation und mache Wiederholung zum No-op.
`Storage::Async.pm` und `Storage::DBI.pm` bleiben unverändert. Ändere keine
Tests, Git-Index oder karr. Der Changes-Eintrag nennt terminalen Shutdown und
deterministisch fehlgeschlagene Waiter.
```

- [ ] **Step 9: Lege terminalen Zustand und stabile Fehler-Future an**

`PoolBase::new` initialisiert den neuen internen Zustand:

```perl
_shutdown => 0,
```

Der neue vorgeschlagene private Helper lautet:

```perl
sub _shutdown_failure {
  my ($self) = @_;
  return $self->future_class->fail('Connection pool has been shut down');
}
```

`acquire` prüft `{_shutdown}` vor `_acquire_slot`; `acquire_txn` läuft weiterhin über `acquire` und erbt denselben failed-Future-Vertrag.

- [ ] **Step 10: Mache `release` nach Shutdown zum No-op**

Am Anfang des bestehenden `release($self, $conn)`:

```perl
return if $self->{_shutdown};
```

Dadurch kann ein altes Handle weder `_waiters` settlen noch `_idle` füllen. Es wird nicht erneut geschlossen, weil der erste Shutdown alle registrierten Handles bereits abgearbeitet hat.

- [ ] **Step 11: Detache und settle Queue-Waiter zuerst**

Der Worker beginnt `shutdown` so:

```perl
return 1 if $self->{_shutdown};
$self->{_shutdown} = 1;

my @waiters = @{ $self->{_waiters} };
$self->{_waiters} = [];
for my $waiter (@waiters) {
  $waiter->fail('Connection pool has been shut down')
    unless $waiter->is_ready;
}
```

Die Queue ist leer, bevor ein Callback über `release` oder andere Poolmethoden zurücklaufen kann.

- [ ] **Step 12: Settle Readiness-pending Acquires und schließe genau einmal**

Über eine Kopie von `_connections` prüft der Worker den registrierten Ready-Future:

```perl
my @connections = @{ $self->{_connections} };
for my $conn (@connections) {
  my $ready = $self->_connection_ready_lookup($conn);
  if ($ready && !$ready->is_ready) {
    $ready->fail('Connection pool has been shut down');
    next;
  }
  next unless grep { Scalar::Util::refaddr($_)
    == Scalar::Util::refaddr($conn) } @{ $self->{_connections} };
  $self->_shutdown_ready_connection($conn);
}
```

`_shutdown_ready_connection($conn)` ist ein neuer vorgeschlagener privater Helper, der die vorhandenen Disconnect-Actions/Close/Clear-Schritte für nachweislich ready Handles kapselt. Ein pending Ready-Failure ruft synchron k197s Retirement-Continuation; der Membership-Check verhindert doppeltes Schließen.

- [ ] **Step 13: Leere alle Strukturen und formalisiere `Pool::shutdown`**

Am Ende von `PoolBase::shutdown` stehen:

```perl
$self->{_connections} = [];
$self->{_idle}        = [];
$self->{_waiters}     = [];
$self->{_ready}       = {};
return 1;
```

`DBIO::Storage::Pool` lädt zusätzlich compile-time:

```perl
use DBIO::Exception ();
```

und erhält die neue deklarierte Signatur:

```perl
sub shutdown {
  DBIO::Exception->throw('Subclass must override shutdown');
}
```

Die bestehenden sechs one-line-`croak`-Methoden bleiben als nicht ticketrelevanter Heritage-Code unberührt; der neue Refusal folgt der verbindlichen F21-Exception-Taxonomie. `DBIO::Storage::Pool` gehört nicht zu den fünf ADR-0024-Basistypen, daher löst diese formalisierte Pool-API keinen `$CONTRACT_VERSION`-Bump aus; das ADR-0030-Amendment dokumentiert sie.

- [ ] **Step 14: Dokumentiere terminale Instanz und Reconnect**

`lib/DBIO/Manual/AsyncStorage.pod` und das Amendment zu ADR 0030 halten exakt fest:

- Shutdown settled Queue- und Readiness-Acquires als failed Futures;
- Post-shutdown Acquire bleibt auf derselben Instanz verweigert;
- Late Release ist wirkungslos;
- ein erneuter DBIO-Connect baut Backend, Ownership-Generation und Pool neu;
- Pool-Restart, Cancellation und öffentliche Timeout-APIs sind nicht Teil dieser Änderung.

- [ ] **Step 15: Führe k198 fokussiert grün aus**

```bash
set -o pipefail
maint/capped-test prove -l \
  t/storage/pool_base.t \
  t/storage/pool_readiness.t \
  t/storage/pool_ready_wiring.t \
  t/storage/pool_connect_actions.t \
  t/test/14_async_backend.t \
  2>&1 | tee /tmp/dbio-k198-focused.log
```

Expected: PASS; keine Waiter pending, alle Close-Zähler exakt eins, Rebuild-Refs verschieden.

- [ ] **Step 16: Führe die vollständige rekursive Suite aus**

```bash
set -o pipefail
maint/capped-test dzil test 2>&1 | tee /tmp/dbio-k198-full.log
```

Expected: Exit 0, Full Suite `Result: PASS`.

- [ ] **Step 17: Installiere den abgeschlossenen Core**

```bash
set -o pipefail
maint/capped-test dzil install 2>&1 | tee /tmp/dbio-k198-install.log
```

Expected: Exit 0.

- [ ] **Step 18: Stage k198 exakt**

```bash
git add -- \
  Changes \
  lib/DBIO/Storage/PoolBase.pm \
  lib/DBIO/Storage/Pool.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  docs/adr/0030-async-explicit-per-connection-mode.md \
  t/storage/pool_base.t \
  t/storage/pool_readiness.t \
  t/storage/pool_ready_wiring.t \
  t/test/14_async_backend.t
```

Expected: neun k198-Dateien sind gestaged.

- [ ] **Step 19: Prüfe den k198-Cached-Diff**

```bash
git diff --cached --check
test -z "$(git diff --cached --name-only -- \
  .claude/skills/kanban-issues-karr-cli/SKILL.md \
  lib/DBIO/Storage/Async.pm lib/DBIO/Storage/DBI.pm)"
git diff --cached --name-only
```

Expected: exakt neun Dateien; die beiden Runtime-Referenzen bleiben unverändert.

- [ ] **Step 20: Committe k198 lokal**

```bash
git commit \
  -m "fix(pool): make shutdown terminal (karr k198)" \
  -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

Expected: genau ein lokaler k198-Commit.

- [ ] **Step 21: Übergib k198 Main-seitig und seriell**

```bash
TICKET_ID=198
CLAIM=$(karr agent-name)
FOCUSED=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k198-focused.log)
FULL=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k198-full.log)
karr handoff "$TICKET_ID" --claim "$CLAIM" \
  --note "Commit $(git rev-parse --short HEAD). Focused: $FOCUSED, Result: PASS. Full: $FULL, Result: PASS. maint/capped-test dzil install: PASS. Queue/readiness waiters, late release, idempotence and fresh backend/pool generation verified." \
  -t
```

Expected: k198 in `review`; erst danach darf Main k199 claimen.

**k198 rollback:**

```bash
git restore --staged -- .
git restore --worktree -- \
  Changes \
  lib/DBIO/Storage/PoolBase.pm \
  lib/DBIO/Storage/Pool.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  docs/adr/0030-async-explicit-per-connection-mode.md \
  t/storage/pool_base.t \
  t/storage/pool_readiness.t \
  t/storage/pool_ready_wiring.t \
  t/test/14_async_backend.t
git status --short
```
