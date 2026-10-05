# Airlock – Design

Datum: 2026-10-02 (Revision 3: beim Planen geklärte Details, siehe Abschnitt 11)
Status: freigegeben am 2026-10-02; Umsetzungsplan in `docs/superpowers/plans/2026-10-02-airlock-phase-1.md`
Distribution: `Airlock` (Repo `p5-airlock`), CPAN-fähig, `[@Author::GETTY]`

## 1. Was Airlock ist

**Airlock ist die Schleuse: eine wartende Anfrage wird von einer bereits vertrauten
Session bestätigt, bei Bedarf erst nach einem zweiten Faktor.**

Der erste und wichtigste Anwendungsfall ist die Server-Seite des OAuth 2.0 Device
Authorization Grant (RFC 8628): Ein Gerät oder CLI zeigt einen kurzen Code, ein
eingeloggter Mensch tippt oder scannt ihn woanders, sieht wer was will, bestätigt, und
das Gerät bekommt ein Token.

Airlock ist ein **Kern zum Einbauen**, keine fertige Anwendung. Die Host-App bringt mit:

- wer gerade eingeloggt ist (eigene Session, oder ein IdP wie Keycloak dahinter),
- die Bestätigungsseite in ihrem eigenen Look, mit ihren eigenen Templates,
- wo Daten liegen (eine Handvoll Subs gegen die Datenbank, die sie schon hat).

Airlock bringt mit: Codes, Zustandsautomat, Poll-Regeln, einmaliges Einlösen,
Step-up-Regeln, zweite Faktoren, QR-Codes, die beiden Maschinen-Endpunkte als PSGI, und
Funktionen für alles, was die Host-App selbst darstellen will.

Erster Nutzer ist Mothership (`mothership-web`, mehrere Prefork-Worker, Anbindung des
Stores über DBIO).

### Was Airlock nicht ist

- **Kein Identity Provider.** Keine Konten, keine Passwörter, kein Login-Formular, kein
  OIDC-Discovery für Dritte. Wer bestätigt, sagt die Host-App.
- **Keine Oberfläche.** Kein HTML, keine Templates, kein CSS. Airlock liefert der
  Bestätigungsseite die Daten und nimmt ihre Entscheidung entgegen; wie sie aussieht,
  gehört dem System, in das Airlock eingebaut wird.
- **Kein allgemeiner OAuth-Server.** Kein Authorization-Code-Flow, kein Client-Secret-
  Handling, keine Refresh-Tokens in v1.
- **Kein Ersatz für die MFA eines IdP.** Hat Keycloak den zweiten Faktor schon geprüft,
  übernimmt Airlock das Ergebnis und fragt nicht noch einmal.
- **Kein Datenbank-Treiber.** Kein DBI, kein ORM. Der Store ist eine Handvoll Coderefs.

## 2. Begriffe

| Begriff | Bedeutung |
|---|---|
| **Request** | Die wartende Anfrage: `device_code`, `user_code`, Client, Scopes, Zustand, Ablauf |
| **Client** | Wer anfragt (CLI, Gerät, App), identifiziert durch `client_id` |
| **Subject** | Wer bestätigt: die eingeloggte Person, von der Host-App geliefert |
| **Factor** | Ein zweiter Faktor, der eine Bestätigung absichert (TOTP, WebAuthn, …) |
| **Policy** | Entscheidet pro Request, welche Faktoren nötig sind |
| **Grant** | Die bestätigte, einlösbare Anfrage: Subject, Scopes, `amr`, `auth_time` |
| **Issuer** | Macht aus einem Grant die Token-Antwort |

Zustände eines Requests: `pending → approved | denied | expired`, und `approved → redeemed`
(genau einmal).

## 3. Schichten

```
Host-App (Mothership, …)
   │
   │  Maschinen-Seite (JSON)                 Menschen-Seite (Host-App rendert selbst)
   │  ───────────────────────                ─────────────────────────────────────────
   ├─ $airlock->to_app          PSGI         $airlock->inspect / requirements
   ├─ $airlock->handle($req)    HTTP::Request → HTTP::Response
   │                                         $airlock->approve / deny
   │                                         Airlock::QR
   │
   └─ Airlock                   Kern: Funktionen, kein Web-Framework
        ├─ store    => { ... }  vier Subs der Host-App (Memory eingebaut)
        ├─ factors  => [ ... ]  TOTP, Callback, Upstream, später WebAuthn
        ├─ policy               Step-up-Regeln
        ├─ issuer   => sub      Token-Ausgabe (Opaque eingebaut)
        ├─ Airlock::Code        Code-Erzeugung und -Normalisierung
        └─ Airlock::QR          SVG, Terminal, Data-URI

Airlock::Client                 Gegenseite: RFC-8628-Client für CLIs
```

Es gibt genau eine neutrale Stelle, an der eine Anfrage beantwortet wird:
`$airlock->respond($method, $path, \%params)` liefert `[$status, \%headers, \%json]`.
`to_app` und `handle` sind zwei dünne Hüllen darum. Wer ein anderes Framework hat, baut
die dritte Hülle in zehn Zeilen oder ruft die Kern-Methoden direkt.

## 4. Kern-API

```perl
my $airlock = Airlock->new(
  store   => { insert => sub {...}, find => sub {...}, update => sub {...}, purge => sub {...} },
  clients => { 'mothership-cli' => { name => 'Mothership CLI', scopes => [qw(read admin)] } },
  policy  => { step_up => { admin => ['totp'] }, max_auth_age => 300 },
  factors => [ Airlock::Factor::Callback->new(name => 'totp', amr => 'otp', verify => sub {...}) ],
  issuer  => sub ($grant) { ... },          # weglassen = eingebautes Opaque-Token
  verification_uri => 'https://my.example.org/airlock',
);

my $req    = $airlock->open(client_id => $id, scope => 'read admin', origin => { ip => ..., ua => ... });
my $view   = $airlock->inspect($user_code);                # für die Bestätigungsseite, oder undef
my $needs  = $airlock->requirements($view, $subject);      # z. B. ['totp'] oder []
my $done   = $airlock->approve($user_code, subject => $subject, proofs => { totp => '123456' });
my $done   = $airlock->deny($user_code, subject => $subject);
my $result = $airlock->redeem(device_code => $dc, client_id => $id);
```

- `open` liefert die Felder aus RFC 8628 §3.2 einschließlich `verification_uri_complete`.
- `inspect` liefert alles, was eine Bestätigungsseite zeigen muss: Client-Name, Scopes,
  Herkunft, Alter, Restlaufzeit. Reine Daten, kein Markup.
- `redeem` liefert genau einen von `granted`, `authorization_pending`, `slow_down`,
  `access_denied`, `expired_token`, `invalid_grant`. Bei `granted` hängt die Token-Antwort
  des Issuers dran.
- `subject` ist eine Struktur der Host-App: mindestens `id`, optional `amr`, `acr`,
  `auth_time` (siehe Abschnitt 7).
- Zeit kommt über ein injizierbares `now`, damit Tests Ablauf und `slow_down` ohne `sleep`
  prüfen.
- `on_event` (Callback) meldet `opened`, `approved`, `denied`, `redeemed`,
  `factor_failed`, `code_miss`. Daran hängt die Host-App Audit-Log und Rate-Limits.

## 5. Einbinden

### Maschinen-Endpunkte

```perl
# PSGI, ohne Plack-Abhängigkeit
builder { mount '/airlock' => $airlock->to_app; mount '/' => $app };

# überall sonst: HTTP::Request rein, HTTP::Response raus
my $res = $airlock->handle($http_request);
```

| Route | Zweck |
|---|---|
| `POST …/device` | Client holt Codes (RFC 8628 §3.1) |
| `POST …/token` | Client pollt (RFC 8628 §3.4) |

Mehr Routen gibt es nicht. `to_app` liest den form-kodierten Body selbst aus dem
PSGI-Env und braucht kein Plack. `handle` lädt `HTTP::Message` erst beim Aufruf; es ist
eine `recommends`-Abhängigkeit.

### Menschen-Seite

Die Host-App baut zwei Handler in ihrem eigenen Framework: einen, der mit `inspect` und
`requirements` die Seite füllt, und einen, der das Formular mit `approve` oder `deny`
abschließt. Login-Pflicht, CSRF und Templates sind ihre Sache. Airlock gibt ihr dazu den
QR-Code (Abschnitt 6) und klare Ergebnis-Objekte mit Fehlergrund.

`examples/` zeigt den vollständigen Einbau: eine Plack-App mit minimaler
Bestätigungsseite, dieselbe in Mojolicious, und den Store einmal mit DBI und einmal mit
DBIO. Ein Mojolicious-Plugin gibt es erst, wenn das Beispiel sich als zu viel Tipparbeit
herausstellt (Phase 2).

## 6. Bausteine

### Store: vier Subs

```perl
store => {
  insert => sub ($row)                         { ... },   # neuen Request ablegen
  find   => sub ($field, $value)               { ... },   # per user_code oder device_hash
  update => sub ($id, $from_state, \%changes)  { ... },   # nur wenn Zustand == $from_state; liefert wahr/falsch
  purge  => sub ($before_epoch)                { ... },   # optional: Abgelaufenes wegräumen
}
```

`$row` ist ein flacher Hash mit festen Schlüsseln (in der Doku als Tabelle, mit
SQL-Beispielschema in `examples/`). `update` ist die einzige Stelle, die atomar sein
muss: Die Bedingung auf den alten Zustand verhindert, dass zwei gleichzeitige Polls zwei
Tokens ergeben. Ohne `store` benutzt Airlock einen eingebauten Speicher im Prozess, für
Tests und Ein-Prozess-Apps.

`Airlock::Test::Store` prüft eine Store-Anbindung gegen den Vertrag: Wer seine vier Subs
schreibt, lässt die Suite dagegen laufen und weiß, ob sie stimmen. Dieselbe Suite prüft
den eingebauten Speicher und die Beispiele.

Der `device_code` kommt nur als SHA-256 im Store an.

### Factor (`Airlock::Factor`, Moo::Role)

`name`, `amr` (z. B. `otp`), `available_for($subject)`, `verify($subject, $proof)`.

- `Airlock::Factor::Callback`: Die Host-App prüft selbst. Das ist der Weg für Mothership,
  wo TOTP laut Design bei Stalwart liegt und Mothership nichts speichert.
- `Airlock::Factor::TOTP`: RFC 6238 mit `Digest::SHA`, Fenster ±1, Replay-Schutz über
  den letzten akzeptierten Zeitschritt, `otpauth://`-URI fürs Einrichten. Geheimnis und
  letzter Zeitschritt kommen über zwei Subs der Host-App.
- `Airlock::Factor::Upstream`: gilt als erfüllt, wenn das Subject passende `amr`/`acr`
  vom IdP mitbringt und `auth_time` frisch genug ist.
- Später: `Airlock::Factor::WebAuthn` über `Authen::WebAuthn` als optionale Abhängigkeit,
  und Recovery-Codes.

### Policy

Bildet Request und Subject auf eine Liste nötiger Faktoren ab. Deklarativ für den
Normalfall (`step_up => { scope => [faktoren] }`, `max_auth_age => 300`), Coderef für
alles andere. Fehlt dem Subject ein verlangter Faktor, wird nicht bestätigt; das Ergebnis
sagt, was fehlt.

### Issuer

Ein Sub `($grant) → Token-Antwort`. Ohne Angabe stellt Airlock ein opakes Zufallstoken
aus, legt es gehasht im Store ab und bietet `verify_token` zum Prüfen. Das reicht, solange
nur die Host-App selbst das Token akzeptiert. Phase 2 bringt einen fertigen JWT-Issuer mit
`amr`, `auth_time`, `scope`, `sub` und JWKS-Export.

### Code (`Airlock::Code`)

`user_code`: 8 Zeichen aus `BCDFGHJKLMNPQRSTVWXZ` (keine Vokale, nichts Verwechselbares),
Anzeige `XXXX-XXXX`, Eingabe wird normalisiert (Groß/Klein, Trenner, Leerzeichen).
`device_code`: 32 Byte aus dem System-Zufall (`Crypt::URandom`).

### QR (`Airlock::QR`)

Zwei Stellen brauchen QR-Codes, beide über dieselbe kleine API:

1. `verification_uri_complete`: Der Laptop oder das CLI zeigt den QR, das Handy scannt
   und landet mit vorausgefülltem Code auf der Bestätigungsseite.
2. TOTP-Einrichtung: die `otpauth://`-URI für die Authenticator-App.

```perl
Airlock::QR->new(text => $uri)->svg;        # fürs Web, keine Bildbibliothek nötig
Airlock::QR->new(text => $uri)->terminal;   # Unicode-Halbblöcke fürs CLI
Airlock::QR->new(text => $uri)->data_uri;   # direkt ins <img src>
Airlock::QR->new(text => $uri)->matrix;     # rohe Module, für eigene Darstellung
```

Kodiert wird mit `GD::Barcode::QRcode` (reines Perl; die Dist verlangt zur Laufzeit kein
GD). Der Encoder sitzt hinter einer kleinen Naht, damit `Text::QRCode` (libqrencode)
benutzt werden kann, wenn es installiert ist. Der Plan beginnt mit einem Nachweis, dass
die erzeugte Matrix sich mit einem unabhängigen Decoder zurücklesen lässt; fällt der
Nachweis durch, wird der Encoder gewechselt, bevor etwas darauf aufbaut.

### `Airlock::Client`

Die Gegenseite, also das, womit dieses Projekt angefangen hat: ein RFC-8628-Client mit
`HTTP::Tiny`. Findet die Endpunkte per `.well-known/openid-configuration`
(`device_authorization_endpoint`) oder bekommt sie direkt, zeigt Code und Terminal-QR,
pollt und beachtet `slow_down`. Spricht mit Airlock, Keycloak und GitHub gleichermaßen.

## 7. Keycloak: minimal, aber getestet

Zwei Berührungspunkte in v1, beide gegen ein echtes Keycloak geprüft:

**A. Keycloak ist die Login-Quelle der Bestätigungsseite.** Die Host-App loggt per OIDC
ein und reicht Airlock das Subject samt `amr`, `acr` und `auth_time` aus dem ID-Token.
`Airlock::Factor::Upstream` erkennt daran, ob Keycloak schon einen zweiten Faktor geprüft
hat. Fehlt er, liefert Airlock der Host-App die Parameter (`acr_values`, `max_age=0`),
mit denen sie die Person noch einmal zu Keycloak schickt. Wie Keycloak `acr` und `amr`
tatsächlich füllt, wird nicht aus der Doku übernommen, sondern am echten Token
festgestellt und als `Airlock::Upstream::Keycloak` festgehalten.

**B. Der Client spricht direkt mit Keycloak.** Keycloak kann den Device-Grant selbst.
`Airlock::Client` muss gegen dessen Endpunkte durchlaufen.

**Der Live-Test** (`t/90-live-keycloak.t`, nur wenn `TEST_AIRLOCK_KEYCLOAK_URL` gesetzt
ist) braucht ein Keycloak mit einem Realm, einem Client mit eingeschaltetem Device-Flow
und einem Nutzer mit TOTP. Für den Test reicht ein Container mit Realm-Import aus einer
JSON-Datei in `t/keycloak/`; ein Admin-Client ist dafür nicht nötig.

**Nicht in v1:** Zitadel- und Authentik-Abbildungen (dieselbe Naht, kommen bei Bedarf),
Airlock als Fassade vor Keycloaks Device-Endpunkt (unnötig), und von Dritten prüfbare
Airlock-Tokens samt Token Exchange (Phase 2/3; ab dort ist Airlock faktisch ein kleiner
Aussteller, was für Mothership die Zeile „Kein Identity Provider“ berührt).

**Außerhalb dieser Dist:** Auf CPAN gibt es kein Keycloak-Modul (Stand 2026-10-02; die
Suche findet nur generische OIDC- und SAML-Module, die Keycloak erwähnen). Ein
`WWW::Keycloak` nach dem Muster von `WWW::Zitadel` (OIDC plus Admin-API für Realms,
Clients, Nutzer) ist eine eigene Dist und die Grundlage für ein automatisches
Keycloak-Setup. Airlock hängt nicht davon ab.

## 8. Sicherheit

- `user_code` hat rund 2,5 · 10¹⁰ Möglichkeiten und lebt 10 Minuten. Fehlversuche meldet
  der Kern als `code_miss` mit Subject und Herkunft; begrenzen muss die Host-App, weil nur
  sie Sessions und IPs kennt. Die Doku sagt das deutlich, das Beispiel macht es vor.
- `inspect` liefert Client-Namen, Scopes, Herkunft (IP, User-Agent) und Alter der Anfrage,
  damit die Seite sie zeigen kann. Bestätigt wird nur durch einen `approve`-Aufruf mit
  Subject, nie durch bloßes Öffnen von `verification_uri_complete`.
- `device_code` nur gehasht im Store; Vergleiche in konstanter Zeit.
- Einlösen ist atomar und einmalig.
- Faktoren: Replay-Schutz bei TOTP, begrenzte Versuche pro Request, danach ist der Request
  `denied`.
- Fehlerantworten strikt nach RFC 8628 (HTTP 400 mit `error`).
- Keine Codes, Tokens oder Faktor-Geheimnisse in Logs oder Events.

## 9. Tests und Phasen

Tests: Zustandsautomat mit eingebautem Speicher und gestellter Uhr; `Airlock::Test::Store`
gegen den eingebauten Speicher und gegen das DBI-Beispiel auf SQLite; TOTP gegen die
Testvektoren aus RFC 6238; QR durch Zurücklesen; `to_app` mit rohen PSGI-Envs und
`handle` mit `HTTP::Request`; `Airlock::Client` gegen `to_app` auf einem lokalen Port;
Keycloak live hinter der Umgebungsvariable.

| Phase | Inhalt |
|---|---|
| 1 | Kern, Code, Policy, Store-Subs mit eingebautem Speicher, `Airlock::Test::Store`, Factor::Callback/TOTP/Upstream, Issuer-Sub mit Opaque-Standard, QR, `to_app`, `handle`, Client, Keycloak-Abbildung mit Live-Test, Beispiele (Plack, Mojolicious, DBI, DBIO) |
| 2 | JWT-Issuer mit JWKS, Recovery-Codes, Mojolicious-Plugin falls nötig, weitere IdP-Abbildungen |
| 3 | Factor::WebAuthn, „Login auf zweitem Gerät bestätigen“ (Session statt Token), Token Exchange |

Abhängigkeiten in Phase 1: `Moo`, `Crypt::URandom`, `JSON::MaybeXS`, `GD::Barcode`,
`HTTP::Tiny`, `Digest::SHA`. `HTTP::Message` als `recommends`. Kein Plack, kein DBI, kein
Mojolicious zur Laufzeit; die Beispiele und Tests ziehen sie nur als Test- oder
Entwicklungs-Abhängigkeit.

## 10. Entschieden

- Eine Dist `Airlock`, Client darin.
- PSGI und Funktionen in Phase 1, dazu `HTTP::Request`/`HTTP::Response`. Mojolicious
  frühestens Phase 2.
- Keine Templates, keine Oberfläche in Airlock.
- Store als Subs der Host-App, Beispiele für DBI und DBIO, kein Treiber in der Dist.
- Keycloak minimal (Login-Quelle plus Client), live getestet.
- Opakes Token als Standard, JWT in Phase 2.

## 11. Beim Planen geklärt (Revision 3)

Der Umsetzungsplan wurde gegen einen lauffähigen Prototyp geschrieben. Dabei haben sich
mehrere Punkte gegenüber dem Text oben verschoben; wo sie ihm widersprechen, gelten sie.

- **`handle` ist keine Methode von `Airlock`.** Es lebt in `Airlock::HTTPMessage->new(
  airlock => $airlock )->handle( $request, ip => ... )`. Grund: Die Hausregel verbietet
  verzögertes `require`, und `Airlock` selbst soll nicht von `HTTP::Message` abhängen.
  `to_app` und `respond` bleiben Methoden von `Airlock`.
- **Die Store-Zeile** hat die Felder `hash kind user_code client_id scope state created
  expires poll_interval last_poll subject amr acr auth_time approved origin_ip origin_ua
  factor_failures`. `find` sucht nach `hash` oder `user_code`. Das Poll-Intervall heißt
  `poll_interval`, weil `INTERVAL` in manchen SQL-Dialekten reserviert ist.
- **Opake Tokens liegen in derselben Tabelle** wie die Anfragen (`kind` ist `request` oder
  `token`). So bleibt der Store bei vier Subs. Dazu gibt es `revoke_token`.
- **Der `user_code` bleibt an einer bestätigten Anfrage**, bis sie eingelöst, abgelehnt
  oder abgelaufen ist. Nur so meldet ein Doppelklick auf „Bestätigen“ beim zweiten Mal
  ebenfalls Erfolg statt „Code unbekannt“. Für jede andere Person bleibt der Code unbekannt.
- **Der eingebaute Speicher verweigert die Benutzung über einen Fork hinweg.** Unter einem
  Prefork-Server wären Codes sonst zufällig unbekannt.
- **Die Encoder-Naht von `Airlock::QR` ist ein Coderef-Attribut** (`encoder`). Eine
  automatische Umschaltung auf `Text::QRCode` gibt es nicht. Der Nachweis ist erbracht:
  `GD::Barcode::QRcode` 2.02 läuft ohne GD, und ein unabhängiger Decoder (jsQR) liest die
  Matrizen in allen vier Fehlerkorrektur-Stufen zurück.
- **`code_miss` trägt das Subject, nicht die Herkunft.** IP und Session kennt die Host-App
  an der Stelle selbst.

Nach dem unabhängigen Review und dem ersten Live-Lauf gegen Keycloak kamen dazu:

- **Der Store kann addieren.** Ein Wert in den Änderungen von `update`, der eine Referenz
  auf eine Zahl ist (`{ factor_failures => \1 }`), wird zur Spalte addiert. Nur so zählen
  parallele Fehlversuche einzeln; `Airlock::Test::Store` prüft es.
- **Faktoren haben zwei Phasen:** `verify` prüft, `commit` verbraucht. Ein TOTP-Code wird
  erst verbraucht, wenn alle Faktoren einer Bestätigung gehalten haben, und `accept_step`
  kann eine verlorene Wettlauf-Situation durch einen falschen Rückgabewert melden.
- **Ein leerer Nachweis gilt als fehlend,** nicht als Fehlversuch.
- **`auth_time` wird nicht erfunden.** Bringt das Subject keines mit, hat der Grant keines.
- **Keycloak-Befund (26.8.0):** Im Standard-Realm tragen Passwort-Login und Login mit TOTP
  beide `acr=1` und kein `amr`. Mit dem AMR-Protocol-Mapper am Client und Referenzwerten
  an den Schritten der Authentication-Flows (`t/keycloak/setup.pl`) meldet Keycloak
  `amr=pwd` beziehungsweise `amr=pwd,otp`, und `Airlock::Factor::Upstream` unterscheidet
  die Logins. Punkt A und Punkt B aus Abschnitt 7 sind damit live bestätigt: Der Test
  fährt einen vollständigen Device-Flow mit Browser-Login gegen Keycloak. Details in
  `t/keycloak/README.md`.

Die Policy ist eine eigene Klasse `Airlock::Policy`; ein Hash wird beim Konstruieren
umgewandelt. Ergebnisse sind `Airlock::Result`-Objekte mit `ok`, `status`, `data`,
`missing` und `oauth`.
