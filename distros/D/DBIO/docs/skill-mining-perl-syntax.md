# Skill Mining — dbio-perl-syntax vs. aktueller Code

Run 1 · 2026-08-22 · Korpus: `dbio/lib/` (244 .pm) + `dbio/t/` (226 .t), HEAD 8123f25c

Methode: Regeln aus `dbio-perl-syntax` gegen den Code gezählt, Zahl + Gegenzahl.
Ziel: nicht "können wir den Skill verbessern", sondern "müssen wir Einheitlichkeit
erzwingen oder ist alles im Fluss". Verdicts vom Autor (Getty).

---

### C01 — trailing commas: lib/ meidet sie, t/ nutzt sie flächendeckend
Rule:     (offen — siehe Verdict)
Evidence: lib/DBIO/Optional/Dependencies.pm:627 · lib/DBIO/ResultSet.pm:692 ·
          t/00describe_environment.t:76
Spread:   lib 755 vs 4253 (15 %) · t 3571 vs 0 (100 %)
Target:   dbio-perl-syntax § Whitespace & idioms
verdict:  2026-08-22: ÜBERALL erlauben UND bevorzugen — Regel "No trailing commas"
          wird zu "Trailing commas sind der Standard". t/ war kein Erbe-Style,
          sondern der gewollte Diff-Stil; lib/ zieht nach.

### C02 — 4-Space-Indentation: 43 lib-Dateien + 32 t-Dateien brechen die 2-Space-Regel
Rule:     (offen — siehe Verdict)
Evidence: lib/DBIO/Test/Schema/Artist.pm:1 · lib/DBIO/Storage/QueryRewrite.pm:1 ·
          lib/DBIO/Test.pm:1 · lib/DBIO/Relationship/BelongsTo.pm:1
Spread:   Kern 16 vs 102 (13 % 4er) · Test-Schemas 25 vs 39 (39 % 4er)
          Alle 16 4er-Kern-Dateien sind Erbe (im Birth-Commit b65d776a vorhanden).
Target:   dbio-perl-syntax § Whitespace & idioms
verdict:  2026-08-22: 2er bleibt Regel, Erbe bleibt — 4er-Dateien werden NICHT
          umformatiert, solange sie nicht angefasst werden. Neue Dateien: 2er.

### C03 — require statt use: Util.pm selbst verletzt die Regel
Rule:     require bleibt verboten außer "essential"; NICHT breit erklären.
          ::Util-Klassen sind die Ausnahme — sie wrappen die verbotenen Dinge.
Evidence: lib/DBIO/Util.pm:309 (require File::Spec) · lib/DBIO/Util.pm:323 (require File::Path)
Spread:   118 require in lib, davon ~10 in Util.pm
Target:   dbio-perl-syntax § Module loading
verdict:  2026-08-22: Regel eng halten ("nur wenn essential"), Util als Ausnahme
          formulieren. Keine breite Ausnahme-Erklärung (Verschwendung).

### C04 — bare open: Util.pm nutzt es selbst
Rule:     bare open verboten in App-Code; ::Util-Klassen wrappen es (Ausnahme).
Evidence: lib/DBIO/Util.pm:317 · lib/DBIO/Util.pm:388 · lib/DBIO/Util.pm:397
Spread:   6 Stellen, 5 in Util.pm
Target:   dbio-perl-syntax § File I/O
verdict:  2026-08-22: Fluss — Util-Impl. darf es, Regel meint App-Code. Mit C03
          zusammen als "::Util-Klassen sind die Wrapper der verbotenen Dinge" fassen.

### C05 — JSON: drei Orte, drei Muster, keiner folgt der Regel buchstäblich
Rule:     (offen — siehe Verdict)
Evidence: lib/DBIO/ChangeLog.pm:11 (JSON::PP) · lib/DBIO/Admin.pm:10 (MaybeXS+relaxed) ·
          lib/DBIO/InflateColumn/Serializer/JSON.pm:9 (MaybeXS+convert_blessed)
Spread:   2 MaybeXS : 1 JSON::PP
Target:   dbio-perl-syntax § JSON
verdict:  2026-08-22: REGEL DURCHSETZEN — JSON::MaybeXS + canonical + convert_blessed
          überall. Code-Anpassung nötig: ChangeLog.pm (JSON::PP → MaybeXS),
          Admin.pm (relaxed behalten? canonical+convert_blessed ergänzen),
          Serializer/JSON.pm (canonical ergänzen). Behavior-relevant → dbio-worker.

### C06 — Data::Dumper in shipped code
Rule:     Data::Dumper verboten in shipped code; Util-Ausnahme für dump_value.
Evidence: lib/DBIO/Util.pm:112 (dump_value) · lib/DBIO/ResultSet.pm:692 (dark selector)
Spread:   2 Dateien
Target:   dbio-perl-syntax § Forbidden / anti-patterns
verdict:  2026-08-22: Fluss — Util-Impl-Ausnahme (dump_value ist Debug-Helper).
          ResultSet dark-selector (692) ist KEIN Debug-Rest, sondern funktionale
          Serialisierung (Terse+Indent(0)+Sortkeys) für die "unnamed selector"-
          Fehlermeldung. Regel bleibt; Ausnahme-Formulierung deckt beides ab:
          "dump_value ist der sanctioned debug helper" + funktionale Serialisierung
          für Fehlermeldungen ist ok.

### C07 — strict/warnings: 15 Dateien ohne explizites use strict
Rule:     strict+warnings müssen IMMER geladen sein — WER sie lädt ist egal.
          Moo/Moose/Cake laden sie selbst; das ist keine Ausnahme, sondern erfüllt
          die Regel. Kein "use strict; use warnings;"-Zwang in Klassen.
Evidence: lib/DBIO/Test/MooSchema/Result/CD.pm:1 (use DBIO::Moo) ·
          lib/DBIO/Test/Schema/ResultDDL/Result/Artist.pm:1 (use DBIO::Cake)
Spread:   15 ohne explizites strict : 244 gesamt
Target:   dbio-perl-syntax § File preamble
verdict:  2026-08-22: Regel umformulieren — "strict und warnings sind immer aktiv,
          egal wie sie geladen werden". Keine Ausnahme-Liste.

### C08 — 1; am Ende fehlt in 2 Dateien
Rule:     (kein Handlungsbedarf)
Evidence: lib/DBIO/Test/ErrorComponent.pm · lib/DBIO/Test/SyntaxErrorComponent3.pm
Spread:   2 : 244
Target:   dbio-perl-syntax § Whitespace & idioms
verdict:  2026-08-22: konform — SyntaxError-Testkomponenten sollen nicht kompilieren.
