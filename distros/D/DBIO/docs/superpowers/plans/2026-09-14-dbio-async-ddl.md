# DBIO Async Per-Statement DDL Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** k199 korrigiert den synchronen Run-versus-Statement-Warntext und spiegelt danach die bestehende per-Statement-DDL-Klassifikation seriell und exactly-once in `deploy_async`, gemeinsam in genau einem Ticket-Commit.

**Architecture:** Der synchrone Vorfix zählt in den bereits gebildeten Runs die tatsächlich nichttransaktionalen Statements, ohne den Driver-Hook erneut aufzurufen. Async zerlegt das DDL vor dem ersten Acquire, klassifiziert nur bei global aktivem `transactional_ddl`, gruppiert benachbarte gleiche Antworten und führt transaktionale Runs über `txn_do_async`, nichttransaktionale Runs über einen eigenen gepinnten Acquire/Release-Runner strikt nacheinander aus.

**Tech Stack:** Perl 5, `DBIO::Deploy::Base`, `DBIO::Storage::Async`, `DBIO::Storage::DBI::Capabilities`, `DBIO::SQL::Util`, `DBIO::Test::Storage`, `DBIO::Test::Future`, `Test::More`, `Test::Exception`, Dist::Zilla, `maint/capped-test`, karr.

**Spec:** `docs/superpowers/specs/2026-09-14-dbio-core-async-hardening-design.md`

## Global Constraints

- Dieses Dokument bearbeitet nur k199; der synchrone Warntext ist vorbereitender Teil desselben Tickets und desselben lokalen Commits, kein separates Ticket und kein separater Commit.
- k198 muss vorher installiert, committed und in `review` sein; k199 konsumiert außerdem k194s zentralen TransactionContext-Finalizer und k202s Deferred-Test-Future.
- `_ddl_statement_is_transactional($stmt)` bleibt der bereits vorhandene, driver-observable Hook des owning Sync-Storage; Async erfindet keinen parallelen Capability-Namen.
- `should_emit_if_exists($storage)` und jede IF-EXISTS-Entscheidung bleiben vollständig unberührt.
- `_use_transactional_ddl` ist der globale Gate. Bei false wird der per-Statement-Hook überhaupt nicht aufgerufen.
- Bei global true bedeutet ein fehlender Hook pro Statement `true`, wie `DBIO::Deploy::Base::_stmt_is_txn_safe` heute.
- Alle Statements werden vor dem ersten Acquire genau einmal klassifiziert; Hook-Throws sind synchron und erzeugen weder Acquire noch Query noch Release.
- Benachbarte gleiche Antworten bilden einen Run in Originalreihenfolge. `[T][N][T]` ergibt drei Runs; benachbarte `N` teilen genau eine gepinnte Connection.
- Transaktionale Runs laufen jeweils in genau einem `txn_do_async`; nichttransaktionale Runs laufen auf genau einer explizit gepinnten Connection ohne `BEGIN`/`COMMIT`.
- Der nächste Run beginnt erst nach Erfolg des vorherigen. Nach dem ersten failed Future oder synchronen Query-Seam-Throw startet kein weiterer Acquire.
- Jede nach erfolgreichem Acquire erhaltene Connection wird bei Erfolg, failed Future und synchronem Throw genau einmal released; Cleanup überschreibt den ursprünglichen Fehler nicht.
- `_execute_ddl_async($self, $conn, $ddl)` behält seine dokumentierte Signatur. Neue Arrayref-/Run-Helfer sind privat.
- Der synchrone Split-Warntext nennt die Zahl nichttransaktionaler Statements und die Zahl der Runs; der Async-Split-Warntext benutzt dieselbe Semantik und bleibt pro Backendklasse one-shot.
- Keine neue Driver-Anforderung, kein Contract-Version-Bump: `_ddl_statement_is_transactional` ist bereits Bestandteil von Contract 1.2; `Deploy::Base` erhält nur eine Zählkorrektur, keine neue öffentliche Form.
- Core-Tests bleiben mock-only, ohne SQLite-DSN, reale DB oder Event Loop.
- Teständerungen gehören `dbio-test-mock-writer`; Runtime/POD/ADR `dbio-worker`; Claim/Diff/Test/Git/karr nur Main.
- Der Arbeitsbaum ist nach dem Plan-Commit clean. `.claude/skills/kanban-issues-karr-cli/SKILL.md` bleibt aus dem k199-Commit ausgeschlossen; kein Push, Release oder CPAN-Upload.
- k199 ergänzt `Changes` im passenden `{{$NEXT}}`-Abschnitt und staged den Eintrag mit Sync-Warnfix und Async-DDL-Parität.

---

## Aktueller Codebestand und Dateiverantwortung

- `lib/DBIO/Deploy/Base.pm:302-351` — `_execute_ddl($self, $dbh, $sql)`; der Bug bei 315–323 setzt `$loose = scalar grep { !$_->[0] } @runs` und zählt damit Runs statt Statements.
- `lib/DBIO/Deploy/Base.pm:372-388` — `_group_ddl_statements($storage, $stmts)` produziert `[ $transactional, @statements ]` in Originalreihenfolge.
- `lib/DBIO/Deploy/Base.pm:397-401` — `_stmt_is_txn_safe($storage, $stmt)` delegiert auf den vorhandenen Hook und defaultet true.
- `lib/DBIO/Deploy/Base.pm:412-417` — `_warn_split_ddl_once($key, $msg)`.
- `lib/DBIO/Storage/DBI/Capabilities.pm:313-347,351-389` — vorhandene Hook-Signatur `_ddl_statement_is_transactional($self, $stmt)`, Default `1`, Capability-Accessoren `_use_transactional_ddl`/`_supports_transactional_ddl`.
- `lib/DBIO/Storage/Async.pm:1518-1562` — `deploy_async($self, $schema, $opts)` behandelt derzeit nur global alles-transaktional oder alles-bare.
- `lib/DBIO/Storage/Async.pm:1574-1577` — `_install_ddl($self, $schema)` ruft `_ddl_class->install_ddl($schema)`.
- `lib/DBIO/Storage/Async.pm:1592-1610` — vorhandene Owner-Delegation `_use_transactional_ddl($self)`.
- `lib/DBIO/Storage/Async.pm:1629-1642` — `_execute_ddl_async($self, $conn, $ddl)` splittet per `DBIO::SQL::Util::_split_statements` und sequenziert Queries.
- `lib/DBIO/Storage/Async.pm:1676-1681` — vorhandener one-shot Warnpfad für global nichttransaktionales DDL.
- `t/deploy-base.t:355-477` — synchrone per-Statement-Referenz; der erste Split-Test wird von `[T,N,T]` auf `[T,N,N,T]` erweitert.
- `t/test/19_async_deploy.t:142-309` — Async-Fixtures und bisher nur globale Deploy-Zeugen; nach k202 bereits auf `DBIO::Test::Future` migriert.
- `lib/DBIO/Storage/Async.pm:1466-1514` — Inline-POD dokumentiert künftig Run-Gruppierung und Cleanup.
- `lib/DBIO/Manual/AsyncStorage.pod` — das übergreifende Async-Handbuch erhält dieselbe Nutzerregel ohne neue API.
- `docs/adr/0026-ddl-transactional-safety-and-if-exists-capability-flag.md:155-223` — Async-Paritäts-Amendment und korrigierte Statementzählung.
- `t/test/12_contract_version.t:55-64` — Referenz, dass der Hook bereits zum unreleased Contract 1.2 gehört.

---

### Task 1: k199 — Synchronen Warntext korrigieren und Async-DDL gruppieren

**Files:**
- Modify by worker, phase B: `Changes`
- Modify by test agent, phase A: `t/deploy-base.t`
- Modify by worker, phase A: `lib/DBIO/Deploy/Base.pm`
- Modify by test agent, phase B: `t/test/19_async_deploy.t`
- Modify by worker, phase B: `lib/DBIO/Storage/Async.pm`
- Modify by worker, phase B: `lib/DBIO/Storage/DBI/Capabilities.pm` (POD only)
- Modify by worker, phase B: `lib/DBIO/Manual/AsyncStorage.pod`
- Modify by worker, phase B: `docs/adr/0026-ddl-transactional-safety-and-if-exists-capability-flag.md`
- Reference test: `t/test/12_contract_version.t`

**Interfaces:**
- Consumes: `_ddl_statement_is_transactional($stmt) -> Bool`, `_use_transactional_ddl() -> Bool`, `txn_do_async($coderef, @args) -> Future`, TransactionContext `txn_conn()`, `_query_async_pinned($conn, $sql, $bind_arrayref) -> Future`.
- Produces: die bestehende `_execute_ddl_async($conn, $ddl)`-Signatur bleibt; neue vorgeschlagene private Helfer `_ddl_runs_async($ddl)`, `_execute_ddl_statements_async($conn, $statements)`, `_execute_non_txn_ddl_run_async($statements)`, `_execute_ddl_runs_async($runs)` und `_warn_split_ddl_once($msg)` kapseln nur Core-Implementierung.

- [ ] **Step 1: Prüfe und claime k199 als Main**

```bash
TICKET_ID=199
CLAIM=$(karr agent-name)
karr show "$TICKET_ID"
karr move "$TICKET_ID" in-progress --claim "$CLAIM"
```

Expected: k198 ist bereits in `review`; k199 war unclaimed und unblocked.

- [ ] **Step 2: Prüfe den Ausgangszustand vor Phase A**

```bash
test -z "$(git diff --cached --name-only)"
git status --short
```

Expected: keine Ausgabe.

- [ ] **Step 3: Delegiere nur den roten synchronen Warntext-Zeugen an `dbio-test-mock-writer`**

Handoff prompt:

```text
Ändere ausschließlich den bestehenden per-Statement-Split-Block in
`t/deploy-base.t` nach k199 Task 1 Phase A. Erweitere ihn von [T,N,T] auf
[T,N,N,T], erwarte weiterhin zwei txn_do, vier SQL-Statements in Reihenfolge,
`2 statement(s)` und `3 runs`. Ändere keine Produktion, keinen Git-Index und
kein karr. Führe `maint/capped-test prove -l t/deploy-base.t` rot aus und
berichte Diagnose und Claim.
```

Expected artifacts: ein Test-Diff nur in `t/deploy-base.t`, rote Istzahl `1`, Claim-Satz.

- [ ] **Step 4: Erweitere den bestehenden synchronen Split-Zeugen konkret**

Der Testagent ersetzt im vorhandenen ersten `mk_picky()`-Block das DDL durch:

```perl
$deploy->_execute_ddl($storage->dbh,
  "CREATE TABLE a (id int);\n"
. "ALTER TYPE mood ADD VALUE 'ok';\n"
. "ALTER TYPE mood ADD VALUE 'great';\n"
. "ALTER TABLE a ADD c mood;");
```

Die Erwartungen lauten:

```perl
is $storage->{txn_do}, 2,
  'the batch keeps two bracketed transactional runs';
is_deeply $storage->{dbh}{stmts},
  [ 'CREATE TABLE a (id int)',
    "ALTER TYPE mood ADD VALUE 'ok'",
    "ALTER TYPE mood ADD VALUE 'great'",
    'ALTER TABLE a ADD c mood' ],
  'every statement runs in source order';
like $warnings[0], qr/2 statement\(s\) cannot run inside a transaction/,
  'warning counts non-transactional statements, not runs';
like $warnings[0], qr/batch was split into 3 runs/,
  'warning names the three contiguous runs';
```

Dieser vorhandene Block besitzt bereits den ersten one-shot-Warnaufruf für `InMemory::Deploy`; keine neue Deploy-Subklasse und keine `@ISA`-Änderung ist nötig.

- [ ] **Step 5: Führe den synchronen Warntext-Test rot aus**

```bash
set -o pipefail
maint/capped-test prove -l t/deploy-base.t 2>&1 \
  | tee /tmp/dbio-k199-sync-red.log
```

Expected: FAIL, weil der aktuelle Text `1 statement(s)` meldet; Reihenfolge und zwei Transaktionen bleiben bereits grün.

Claim:

```text
Der synchrone Split-Warntext muss die Zahl der false klassifizierten Statements
innerhalb der Runs nennen, ohne den Hook ein zweites Mal aufzurufen.
```

- [ ] **Step 6: Delegiere ausschließlich die Zählkorrektur an `dbio-worker`**

Handoff prompt:

```text
Behebe nur den roten k199-Phase-A-Claim in `lib/DBIO/Deploy/Base.pm`.
Zähle in den bereits klassifizierten false Runs die enthaltenen Statements;
rufe `_ddl_statement_is_transactional` nicht erneut auf. Ändere weder Tests,
Signaturen, Contract-Version, Git-Index noch karr. Berichte den fokussierten
PASS. Noch keinen Commit erstellen.
```

- [ ] **Step 7: Korrigiere die synchrone Zählung minimal**

Der Worker ersetzt nur die fehlerhafte Initialisierung:

```perl
my $loose = 0;
$loose += @$_ - 1 for grep { !$_->[0] } @runs;
```

Der bestehende vollständige Warntext bleibt:

```perl
"$class -- $loose statement(s) cannot run inside a transaction, so the "
. "batch was split into " . scalar(@runs) . " runs and is not atomic as a "
. "whole; recovery depends on the driver's version-row gate"
```

- [ ] **Step 8: Führe Phase A grün aus**

```bash
set -o pipefail
maint/capped-test prove -l t/deploy-base.t 2>&1 \
  | tee /tmp/dbio-k199-sync-green.log
```

Expected: PASS; Warning nennt zwei Statements und drei Runs.

- [ ] **Step 9: Delegiere nur den roten Async-Test-Diff an `dbio-test-mock-writer`**

Handoff prompt:

```text
Erweitere ausschließlich `t/test/19_async_deploy.t` um die k199-Phase-B-Zeugen
aus diesem Plan. Konsumiere DBIO::Test::Future aus k202 und den k194-Finalizer.
Erfasse Classify-/Acquire-/Query-/Release-Reihenfolge; teste [T,N,N,T],
Default-true, global false ohne Hook-Aufruf, Hook-Throw vor Acquire, failed
Future sowie synchronen Query-Throw in beiden Runtypen und one-shot Warnung.
Ändere keine Produktion, Git-Index oder karr. Berichte den roten Lauf und Claim.
```

- [ ] **Step 10: Mache DDL, Owner, Pool und Backend im Test gezielt konfigurierbar**

Der Testagent erweitert `Test::DDL` ohne Signaturänderung:

```perl
our $INSTALL_DDL;
sub install_ddl {
  my ($class, $schema) = @_;
  return $INSTALL_DDL if defined $INSTALL_DDL;
  return "CREATE TABLE artist (id int);\n"
       . "CREATE TABLE cd (id int);\n"
       . "-- a trailing comment;";
}
```

Eine neue vorgeschlagene Testklasse hält den vorhandenen no-hook `Test::Owner` intakt:

```perl
{
  package Test::ClassifyingOwner;
  sub new { my ($class, %args) = @_; bless \%args, $class }
  sub _use_transactional_ddl { $_[0]->{txn} }
  sub _ddl_statement_is_transactional {
    my ($self, $stmt) = @_;
    push @{ $self->{events} }, "classify:$stmt";
    die "classifier failed on $stmt\n"
      if $self->{throw_on} && $stmt =~ $self->{throw_on};
    return $stmt =~ /^N/ ? 0 : 1;
  }
}
```

`Test::SyncPool` zählt normale und Transaction-Acquires, liefert unterscheidbare Connection-Namen und protokolliert Releases:

```perl
sub new {
  my ($class, %args) = @_;
  return bless {
    released     => [],
    acquire_kinds => [],
    events       => $args{events} || [],
    available    => 1,
    sequence     => 0,
  }, $class;
}
sub _acquire {
  my ($self, $kind) = @_;
  push @{ $self->{acquire_kinds} }, $kind;
  push @{ $self->{events} }, "acquire:$kind";
  my $conn = uc(substr($kind, 0, 1)) . ++$self->{sequence};
  return DBIO::Test::Future->done($conn);
}
sub acquire     { return $_[0]->_acquire('normal') }
sub acquire_txn { return $_[0]->_acquire('txn') }
sub release {
  my ($self, $conn) = @_;
  push @{ $self->{released} }, $conn;
  push @{ $self->{events} }, "release:$conn";
  return 1;
}
```

`Test::DeployBackend::new` übernimmt die neue Fixture-Konfiguration ohne die produktiven Constructor-Signaturen zu ändern:

```perl
$self->{fail_on}  = $opt{fail_on};
$self->{throw_on} = $opt{throw_on};
$self->{events}   = $opt{events} || [];
$self->{pool}     = $opt{pool} || Test::SyncPool->new(events => $self->{events});
if ($opt{owner}) {
  $self->{_test_owner} = $opt{owner};
  $self->_owner_storage($self->{_test_owner});
}
elsif (exists $opt{txn}) {
  $self->{_test_owner} = Test::Owner->new($opt{txn});
  $self->_owner_storage($self->{_test_owner});
}
```

`_query_async_pinned` protokolliert wie bisher und ergänzt vor `fail_on`:

```perl
push @{ $self->{events} }, "query:$sql:$conn";
die "synchronous DDL throw on: $sql\n"
  if $self->{throw_on} && $sql =~ $self->{throw_on};
```

Nach k202 liefert `future_class` bereits `'DBIO::Test::Future'`.

- [ ] **Step 11: Schreibe `[T,N,N,T]` mit Pre-acquire-Klassifikation und Run-Reihenfolge**

```perl
local $Test::DDL::INSTALL_DDL = "T1;\nN1;\nN2;\nT2;";
my @events;
my $owner = Test::ClassifyingOwner->new(txn => 1, events => \@events);
my $backend = Test::DeployBackend->new(owner => $owner, events => \@events);
my $future = $backend->deploy_async('schema');
$future->get;

is_deeply [ grep { /^classify:/ } @events ],
  [ 'classify:T1', 'classify:N1', 'classify:N2', 'classify:T2' ],
  'every statement is classified once in source order';
is_deeply [ $backend->_sqls ],
  [qw/BEGIN T1 COMMIT N1 N2 BEGIN T2 COMMIT/],
  'three runs execute serially with transactions around T runs only';
is_deeply $backend->pool->{acquire_kinds}, [qw/txn normal txn/],
  'adjacent N statements share one ordinary acquire';
is scalar @{ $backend->pool->{released} }, 3,
  'every run releases exactly once';
```

Der Eventlog behauptet zusätzlich, dass alle vier `classify:`-Einträge vor dem ersten `acquire:`-Eintrag stehen.

- [ ] **Step 12: Schreibe Default-true und global-false-Zeugen**

Default-true verwendet den unveränderten `Test::Owner`, der keinen Statement-Hook besitzt:

```perl
local $Test::DDL::INSTALL_DDL = "T1;\nT2;";
my $default = Test::DeployBackend->new(txn => 1);
$default->deploy_async('schema')->get;
is_deeply [ $default->_sqls ], [qw/BEGIN T1 T2 COMMIT/],
  'missing classifier defaults every statement to transactional';
```

Global false erhält absichtlich einen Owner, dessen Hook werfen würde:

```perl
my $never_call = Test::ClassifyingOwner->new(
  txn => 0, events => \@events, throw_on => qr/.+/
);
my $bare = Test::DeployBackend->new(owner => $never_call, events => \@events);
lives_ok { $bare->deploy_async('schema')->get }
  'global false bypasses the classifier';
is_deeply $bare->pool->{acquire_kinds}, ['normal'],
  'global false uses one ordinary acquire';
unlike join('|', @events), qr/classify:/,
  'classifier was never consulted';
```

- [ ] **Step 13: Schreibe Hook-Throw-vor-Acquire-Zeugen**

```perl
local $Test::DDL::INSTALL_DDL = "T1;\nN_BAD;\nT2;";
my $owner = Test::ClassifyingOwner->new(
  txn => 1, events => \@events, throw_on => qr/N_BAD/
);
my $backend = Test::DeployBackend->new(owner => $owner, events => \@events);
throws_ok { $backend->deploy_async('schema') }
  qr/classifier failed on N_BAD/,
  'classifier failure is synchronous before execution';
is_deeply $backend->pool->{acquire_kinds}, [], 'hook failure acquires nothing';
is_deeply [ $backend->_sqls ], [], 'hook failure executes nothing';
is_deeply $backend->pool->{released}, [], 'hook failure releases nothing';
```

- [ ] **Step 14: Schreibe failed-Future- und synchronen-Throw-Cleanup-Zeugen**

Der Testagent verwendet jeweils ein DDL mit einem späteren dritten Run und fordert, dass dieser nie acquired wird:

```perl
my $future_failed = Test::DeployBackend->new(
  owner => $owner, fail_on => qr/N_FAIL/
);
my $f = $future_failed->deploy_async('schema');
ok $f->is_failed, 'bare-run failed Future propagates';
is scalar @{ $future_failed->pool->{released} }, 2,
  'completed T run and failed N run each release once';
is_deeply $future_failed->pool->{acquire_kinds}, [qw/txn normal/],
  'later T run never acquires after failure';

my $sync_throw = Test::DeployBackend->new(
  owner => $owner, throw_on => qr/N_THROW/
);
my $thrown = $sync_throw->deploy_async('schema');
ok $thrown->is_failed, 'bare synchronous query throw becomes failed Future';
is scalar @{ $sync_throw->pool->{released} }, 2,
  'bare synchronous throw still releases exactly once';
```

Parallelfälle mit `fail_on => qr/T_FAIL/` und `throw_on => qr/T_THROW/` belegen über k194 `ROLLBACK`, genau einen Release des transaktionalen Runs und keinen späteren Acquire.

- [ ] **Step 15: Schreibe den Async-Split-Warnzeugen**

Der erste Split derselben lokalen Backendklasse fängt Warnungen und fordert:

```perl
like $warnings[0],
  qr/2 statement\(s\) cannot run inside a transaction/,
  'async split warning counts statements';
like $warnings[0], qr/batch was split into 3 runs/,
  'async split warning counts runs';
```

Ein zweiter Split mit derselben Klasse erzeugt keinen zweiten `split DDL batch`-Warntext.

- [ ] **Step 16: Führe Phase B rot aus und fixiere den Claim**

```bash
set -o pipefail
maint/capped-test prove -l t/test/19_async_deploy.t 2>&1 \
  | tee /tmp/dbio-k199-async-red.log
```

Expected: FAIL, weil der Hook nicht aufgerufen wird, der gesamte Batch eine Transaktion erhält und bare synchrone Throws die Connection leaken.

Claim:

```text
Async deploy muss denselben per-Statement-Hook vor jedem Acquire einmal
konsultieren, contiguous Runs strikt seriell ausführen und jeden erfolgreichen
Acquire auf allen terminalen Pfaden genau einmal freigeben.
```

- [ ] **Step 17: Delegiere Async-Runtime und Dokumentation an `dbio-worker`**

Handoff prompt:

```text
Implementiere k199 Phase B nur in Storage/Async.pm sowie POD in
Storage/DBI/Capabilities.pm, Manual/AsyncStorage.pod, ADR 0026 und `Changes`.
Bewahre `_execute_ddl_async($conn,$ddl)`. Klassifiziere vor Acquire über den
owning Sync-Storage, default true, global false ohne Hook. Gruppiere contiguous
Runs, sequenziere über Futures, nutze txn_do_async für T und einen guarded
ordinary Acquire für N. Bewahre Originalfehler und exact-once release. Ändere
keine Tests, Contract-Version, Git-Index oder karr. Noch keinen Commit erstellen.
Der Changes-Eintrag nennt sowohl die korrigierte Warnzählung als auch die Async-
Parität zum k132-Statementvertrag.
```

- [ ] **Step 18: Parse und gruppiere vor dem ersten Acquire**

Der Worker führt einen neuen privaten Helper in dieser Form ein:

```perl
sub _ddl_runs_async {
  my ($self, $ddl) = @_;
  my @stmts = grep { !/^\s*--/ }
    DBIO::SQL::Util::_split_statements($ddl);
  return [] unless @stmts;
  return [ [ 0, @stmts ] ] unless $self->_use_transactional_ddl;

  my $owner = $self->_owner_storage;
  my @runs;
  for my $stmt (@stmts) {
    my $transactional = $owner && $owner->can('_ddl_statement_is_transactional')
      ? ($owner->_ddl_statement_is_transactional($stmt) ? 1 : 0)
      : 1;
    if (!@runs || $runs[-1][0] != $transactional) {
      push @runs, [ $transactional ];
    }
    push @{ $runs[-1] }, $stmt;
  }
  return \@runs;
}
```

Der direkte Aufruf in `deploy_async` lässt einen Hook-Throw synchron entweichen, bevor eine Future oder Connection entsteht.

- [ ] **Step 19: Bewahre `_execute_ddl_async` und extrahiere den Statement-Runner**

```perl
sub _execute_ddl_async {
  my ($self, $conn, $ddl) = @_;
  my @stmts = grep { !/^\s*--/ }
    DBIO::SQL::Util::_split_statements($ddl);
  return $self->_execute_ddl_statements_async($conn, \@stmts);
}

sub _execute_ddl_statements_async {
  my ($self, $conn, $stmts) = @_;
  my @remaining = @$stmts;
  my $fc = $self->future_class;
  my $recur;
  $recur = sub {
    my $stmt = shift @remaining;
    return $fc->done unless defined $stmt;
    return $self->_query_async_pinned($conn, $stmt, [])->then($recur);
  };
  return $recur->();
}
```

Die neue Arrayref-Signatur ist privat; Driver sehen weiterhin nur den vorhandenen String-Wrapper.

- [ ] **Step 20: Implementiere guarded bare-run Acquire/Release**

Der neue private `_execute_non_txn_ddl_run_async($stmts)` besitzt den Acquire und ermittelt die Runner-Future unter `eval`. Bei synchronem Throw wird daraus eine failed Future; Erfolg und Fehler laufen durch einen einzigen Release-Wrapper:

```perl
sub _execute_non_txn_ddl_run_async {
  my ($self, $stmts) = @_;
  my $fc = $self->future_class;

  return $self->pool->acquire->then(sub {
    my $conn = shift;
    my ($run_future, $thrown);
    {
      local $@;
      my $ok = eval {
        $run_future = $self->_execute_ddl_statements_async($conn, $stmts);
        1;
      };
      $thrown = $@ unless $ok;
    }
    $run_future = $fc->fail($thrown) if defined $thrown;
    return $run_future->then(
      sub {
        my @result = @_;
        my ($released, $release_error);
        {
          local $@;
          $released = eval { $self->pool->release($conn); 1 };
          $release_error = $@ unless $released;
        }
        return $released ? $fc->done(@result) : $fc->fail($release_error);
      },
      sub {
        my $error = shift;
        eval { $self->pool->release($conn) };
        return $fc->fail($error);
      },
    );
  });
}
```

Bei Acquire-Fehler existiert keine Connection und kein Release.

- [ ] **Step 21: Sequenziere Runs und emittiere den Split-Warntext**

`deploy_async` berechnet `$runs` einmal und warnt bei mehr als einem Run. Der neue private Run-Rekursor hat die in „Interfaces“ festgelegte Signatur und startet pro Schritt genau einen Runner:

```perl
sub _execute_ddl_runs_async {
  my ($self, $runs) = @_;
  my @remaining = @$runs;
  my $fc = $self->future_class;
  my $recur;
  $recur = sub {
    my $run = shift @remaining;
    return $fc->done unless $run;
    my ($transactional, @stmts) = @$run;
    my $future = $transactional
      ? $self->txn_do_async(sub {
          my ($ctx) = @_;
          return $self->_execute_ddl_statements_async($ctx->txn_conn, \@stmts);
        })
      : $self->_execute_non_txn_ddl_run_async(\@stmts);
    return $future->then($recur);
  };
  return $recur->();
}
```

Nach Warnungsentscheidung endet `deploy_async` mit:

```perl
return $self->_execute_ddl_runs_async($runs);
```

Der Async-Split-Count verwendet wie der korrigierte Sync-Pfad:

```perl
my $loose = 0;
$loose += @$_ - 1 for grep { !$_->[0] } @$runs;
```

- [ ] **Step 22: Bewahre global-false Warnung und ergänze Split-One-shot**

Bei global false bleibt die vorhandene Meldung:

```text
async DDL loop is not atomic; recovery depends on the driver's version-row gate
```

Bei global true und mehr als einem Run emittiert ein neuer klassen-keyed one-shot Helper denselben vollständigen Split-Text wie Sync:

```perl
my %_WARNED_SPLIT_DDL;
sub _warn_split_ddl_once {
  my ($self, $msg) = @_;
  my $class = ref($self) || $self;
  return if $_WARNED_SPLIT_DDL{$class}++;
  warn "split DDL batch on $msg\n";
}
```

Der Aufrufer baut `$msg` konkret aus denselben Zählern:

```perl
my $class = ref($self) || $self;
$self->_warn_split_ddl_once(
  "$class -- $loose statement(s) cannot run inside a transaction, so the "
. 'batch was split into ' . scalar(@$runs) . ' runs and is not atomic as a '
. "whole; recovery depends on the driver's version-row gate"
);
```

Der Helper liegt in `DBIO::Storage::Async`; er ruft nicht den privaten Package-Helper von `DBIO::Deploy::Base` cross-module auf.

- [ ] **Step 23: Aktualisiere POD und ADR ohne neuen Contract**

Der Worker dokumentiert konkret:

- `Storage::Async` und `Manual::AsyncStorage`: Vorabklassifikation, contiguous Runs, T via `txn_do_async`, N via pinned ordinary acquire, strikte Sequenz, exact-once Cleanup.
- `Storage::DBI::Capabilities` POD: Derselbe vorhandene Hook wird vom owning Sync-Storage auch für Async-Deploy konsumiert; Methodencode und Accessorgruppe bleiben unverändert.
- ADR 0026: Async-Paritätsaddendum und die Aussage, dass Warnungen Statements und Runs getrennt zählen.
- `$CONTRACT_VERSION` bleibt `1.2`; `t/test/12_contract_version.t` bleibt unverändert.

- [ ] **Step 24: Führe den endgültigen fokussierten k199-Lauf aus**

```bash
set -o pipefail
maint/capped-test prove -l \
  t/deploy-base.t \
  t/test/19_async_deploy.t \
  t/test/12_contract_version.t \
  2>&1 | tee /tmp/dbio-k199-focused.log
```

Expected: PASS; synchroner und asynchroner Warntext zählen zwei Statements/drei Runs, Fehlerpfade leaken nicht, Contract bleibt 1.2.

- [ ] **Step 25: Führe die vollständige rekursive Suite aus**

```bash
set -o pipefail
maint/capped-test dzil test 2>&1 | tee /tmp/dbio-k199-full.log
```

Expected: Exit 0, `Result: PASS`, keine Skips in den berührten Tests.

- [ ] **Step 26: Installiere den abgeschlossenen Core**

```bash
set -o pipefail
maint/capped-test dzil install 2>&1 | tee /tmp/dbio-k199-install.log
```

Expected: Exit 0.

- [ ] **Step 27: Stage exakt den gemeinsamen k199-Diff**

```bash
git add -- \
  Changes \
  lib/DBIO/Deploy/Base.pm \
  lib/DBIO/Storage/Async.pm \
  lib/DBIO/Storage/DBI/Capabilities.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  docs/adr/0026-ddl-transactional-safety-and-if-exists-capability-flag.md \
  t/deploy-base.t \
  t/test/19_async_deploy.t
```

Expected: Sync-Warnfix und Async-Parität sind gemeinsam gestaged.

- [ ] **Step 28: Prüfe Cached Diff, Contract und Fremdpfad**

```bash
git diff --cached --check
git diff --cached --name-only
test -z "$(git diff --cached --name-only -- \
  .claude/skills/kanban-issues-karr-cli/SKILL.md \
  t/test/12_contract_version.t)"
```

Expected: exakt die acht in Step 27 genannten Dateien; weder Skill-Datei noch Contract-Tripwire gestaged.

- [ ] **Step 29: Committe k199 lokal**

```bash
git commit \
  -m "fix(async): group DDL by statement contract (karr k199)" \
  -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

Expected: genau ein k199-Commit einschließlich synchroner Warntextkorrektur; kein Push.

- [ ] **Step 30: Prüfe den Arbeitsbaum**

```bash
git status --short
```

Expected: keine Ausgabe.

- [ ] **Step 31: Übergib k199 Main-seitig und seriell nach Review**

```bash
TICKET_ID=199
CLAIM=$(karr agent-name)
FOCUSED=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k199-focused.log)
FULL=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k199-full.log)
karr handoff "$TICKET_ID" --claim "$CLAIM" \
  --note "Commit $(git rev-parse --short HEAD). Focused: $FOCUSED, Result: PASS. Full: $FULL, Result: PASS. maint/capped-test dzil install: PASS. Sync warning and async [T,N,N,T], default/global-false, failure, throw and exact-once release paths verified in one commit." \
  -t
```

Expected: k199 steht in `review`; der Gesamtblock ist bereit für den finalen Master-Lauf.

## Exakter Rollback für k199

Vor Commit entfernt Main ausschließlich die sieben k199-Dateien aus Index und Arbeitsdiff:

```bash
git restore --staged -- .
git restore --worktree -- \
  Changes \
  lib/DBIO/Deploy/Base.pm \
  lib/DBIO/Storage/Async.pm \
  lib/DBIO/Storage/DBI/Capabilities.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  docs/adr/0026-ddl-transactional-safety-and-if-exists-capability-flag.md \
  t/deploy-base.t \
  t/test/19_async_deploy.t
git status --short
```

Expected: Der Arbeitsbaum ist clean. Main setzt `TICKET_ID=199`, formuliert den konkreten `BLOCK_REASON` aus dem roten Sync- oder Async-Claim und führt den Masterplan-Blocker-Handoff aus.
