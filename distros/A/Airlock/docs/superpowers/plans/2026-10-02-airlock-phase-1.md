# Airlock Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Airlock Phase 1 bauen: den einbettbaren Kern für den OAuth-2.0-Device-Grant (RFC 8628, Server-Seite) mit Step-up-Faktoren, QR-Codes, den zwei Maschinen-Endpunkten als PSGI und für `HTTP::Request`, einem Device-Flow-Client, Beispielen und einer minimalen, live getesteten Keycloak-Anbindung.

**Architecture:** `Airlock` ist eine Moo-Klasse ohne Web-Framework. Sie bekommt Werte herein und gibt `Airlock::Result`-Objekte heraus. Alles Austauschbare kommt von außen: der Store als vier Coderefs, Faktoren als Objekte mit der Rolle `Airlock::Factor`, der Issuer als Coderef. Die HTTP-Schicht ist eine einzige Methode `respond`, um die `to_app` (PSGI) und `Airlock::HTTPMessage` dünne Hüllen legen.

**Tech Stack:** Perl 5.20+, Moo, Types::Standard, namespace::autoclean, Crypt::URandom, Digest::SHA, JSON::MaybeXS, GD::Barcode (nur der reine-Perl-QR-Encoder), HTTP::Tiny. Dist::Zilla mit `[@Author::GETTY]`.

**Spec:** `docs/superpowers/specs/2026-10-02-airlock-design.md` (Revision 3). Der Plan setzt die Spec um; wer eine Aufgabe ausführt, liest den zugehörigen Spec-Abschnitt mit.

## Ausführung

Ausgeführt am 2026-10-02: Aufgaben 1 bis 8 und die Schritte 1 bis 7 von Aufgabe 9, ein
Commit pro Aufgabe (`e83b806` bis `9e506b9`). Danach hat ein unabhängiger Review Mängel
gefunden, die in einem eigenen Commit behoben sind; der Code im Repo weicht deshalb an
diesen Stellen von den Listings unten ab (Store-Inkrement, `verify`/`commit` bei Faktoren,
Client-Grenzen, Beispiele nur per POST). Maßgeblich ist das Repo, nicht dieses Dokument.
Der Keycloak-Live-Test lief gegen Keycloak 26.8.0; Befund in `t/keycloak/README.md`.

## Stand des Codes in diesem Plan

Der gesamte Code dieses Plans ist am 2026-10-02 als Prototyp außerhalb des Repos gelaufen: `prove -lr t` mit 133 Tests grün, `dzil test` im Endzustand grün (inklusive POD-Syntax nach dem Weaving). Zwei Dinge sind dabei **nicht** gelaufen und deshalb die Stellen, an denen mit Abweichungen zu rechnen ist:

- `t/11-qr-readback.t` braucht `zbarimg`, das auf der Entwicklungsmaschine fehlt. Dieselben Matrizen aus `Airlock::QR` wurden ersatzweise mit jsQR zurückgelesen (20 von 20 Fälle, alle vier Fehlerkorrektur-Stufen). Der Test selbst ist ungelaufen.
- Aufgabe 9 (Keycloak): `t/90-live-keycloak.t` und `t/keycloak/realm.json` sind ohne laufendes Keycloak geschrieben. Die Realm-Datei und die Standardwerte von `Airlock::Upstream::Keycloak` sind Annahmen, bis der Live-Test sie bestätigt.

## Global Constraints

- Keine Oberfläche: kein HTML, keine Templates, kein CSS unter `lib/`. HTML gibt es nur in `examples/`.
- Laufzeit-Abhängigkeiten sind genau die im `cpanfile` aus Aufgabe 1. Kein DBI, kein Plack, kein Mojolicious unter `requires`. `HTTP::Message` ist `recommends` und wird nur von `Airlock::HTTPMessage` geladen.
- Kein `require` zum verzögerten Laden unter `lib/`. Jede Abhängigkeit steht als `use` am Dateianfang. (In Tests ist `require` in einem `BEGIN`-Block als Skip-Wächter für optionale Beispiel-Abhängigkeiten erlaubt.)
- Ein Paket pro Datei, jede Datei unter `lib/` mit `# ABSTRACT:` und `our $VERSION = '0.001';`.
- `croak` statt `die`, Meldung beginnt mit `__PACKAGE__`. Gewöhnliche Fehlschläge sind keine Exceptions, sondern ein `Airlock::Result` mit `ok => 0`.
- Zeit kommt ausschließlich über das injizierte `now`. Kein `time()` außerhalb der `now`-Defaults, kein `sleep` in Tests.
- `device_code` und Tokens erreichen den Store nur als SHA-256. Vergleiche von Geheimnissen laufen über `Airlock::Code->equals`.
- Nichts Geheimes in Events: keine Codes, keine Tokens, keine Faktor-Eingaben.
- Fehlerantworten der Endpunkte nach RFC 8628: HTTP 400 mit `error`.
- `update` im Store ist die einzige Operation, die atomar sein muss, und trägt immer den erwarteten alten Zustand.
- Jede `.t`-Datei beginnt mit `#!/usr/bin/env perl`, `use strict; use warnings; use Test::More;` und endet mit `done_testing;`.
- Tests laufen mit `prove -lr t`, immer rekursiv.
- **Niemand außer `airlock-release-manager` committet.** Jede Aufgabe endet mit einem commit-fertigen Baum und einer Übergabe; der dort genannte Commit-Betreff und die `Changes`-Zeile sind Vorschläge für den Release-Manager.

## Review Focus

Fünf Eingaben, die die Spec nicht ausbuchstabiert und die jemanden im Betrieb treffen würden. Jede ist durch einen Test in der genannten Aufgabe festgenagelt.

1. **Zwei Polls rennen um dieselbe Bestätigung.** Der zweite hat die Zeile gelesen, bevor der erste eingelöst hat. Erwartet: genau ein Token. Test `two polls racing for one approval get one token` in `t/50-core.t` (Aufgabe 5).
2. **Doppelklick auf „Bestätigen“.** Erwartet: beide Anfragen melden Erfolg, es gibt eine Bestätigung und ein Event, und eine dritte Person erfährt über den Code nichts. Test `a double click on approve is not an error` in `t/50-core.t` (Aufgabe 5).
3. **Der eingebaute Speicher unter einem Prefork-Server.** Ohne Schutz wären Codes zufällig unbekannt. Erwartet: lauter Abbruch mit Hinweis auf einen gemeinsamen Store. Test `refuses to be used across a fork` in `t/30-store-memory.t` (Aufgabe 3).
4. **Ein Server schickt dem Client Unsinn als `interval` oder `expires_in`** (0, negativ, Text, Referenz). Erwartet: Standardwerte statt einer Endlosschleife ohne Pause. Test `poll: nonsense from the server does not become a busy loop` in `t/70-client.t` (Aufgabe 7).
5. **Was Menschen und Programme wirklich eintippen und übergeben:** Nicht-ASCII-Buchstaben, ein Megabyte Text, NUL-Bytes als Code; eine Subject-ID, die nicht in die Spalte passt. Erwartet: „kein gültiger Code“ beziehungsweise ein klarer `croak` vor dem Schreiben. Tests `normalize: what people and programs really send` in `t/20-code.t` (Aufgabe 2) und `a subject id that does not fit` in `t/50-core.t` (Aufgabe 5).

## Dateien

| Datei | Verantwortung | Aufgabe |
|---|---|---|
| `cpanfile`, `.github/workflows/ci.yml` | Abhängigkeiten, `zbar-tools` in der CI | 1 |
| `lib/Airlock/QR.pm` | QR-Matrix, SVG, Terminal, Data-URI | 1 |
| `lib/Airlock/Code.pm` | Codes erzeugen, normalisieren, hashen, vergleichen | 2 |
| `lib/Airlock/Store/Memory.pm` | eingebauter Speicher, Referenz für den Store-Vertrag | 3 |
| `lib/Airlock/Test/Store.pm` | Vertrags-Suite für eigene Store-Subs | 3 |
| `lib/Airlock/Factor.pm` | Rolle für zweite Faktoren | 4 |
| `lib/Airlock/Factor/Callback.pm`, `TOTP.pm`, `Upstream.pm` | die drei Faktoren | 4 |
| `lib/Airlock/Policy.pm` | welche Faktoren eine Bestätigung braucht | 4 |
| `lib/Airlock/Result.pm` | Ergebnis einer Operation, RFC-Form | 5 |
| `lib/Airlock.pm` | Kern: `open`, `inspect`, `requirements`, `approve`, `deny`, `redeem`, Tokens | 5 |
| `t/lib/AirlockTest.pm` | Test-Fixture mit stellbarer Uhr | 5 |
| `lib/Airlock/Role/Endpoints.pm` | `respond`, `parse_form`, `to_app` | 6 |
| `lib/Airlock/HTTPMessage.pm` | `HTTP::Request` → `HTTP::Response` | 6 |
| `lib/Airlock/Client.pm` | Device-Flow-Client | 7 |
| `examples/` | Plack- und Mojolicious-App, Store mit DBI und DBIO, CLI | 8 |
| `README.md` | Einstieg | 8 |
| `lib/Airlock/Upstream/Keycloak.pm`, `t/keycloak/` | Keycloak-Abbildung, Realm, Live-Test | 9 |

Reihenfolge und Abhängigkeiten: 1, 2 und 3 sind voneinander unabhängig. 4 braucht 2. 5 braucht 2, 3 und 4. 6 braucht 5. 7 braucht 1 und 6. 8 braucht 6 und 7. 9 braucht 4 und 7 und zusätzlich ein laufendes Keycloak.

Zuordnung zu den karr-Karten des Boards: Aufgabe 1 → Karte 1, Aufgabe 2 → Karte 9, Aufgabe 3 → Karte 3, Aufgabe 4 → Karte 4, Aufgabe 5 → Karte 2, Aufgabe 6 → Karte 5, Aufgabe 7 → Karte 6, Aufgabe 8 → Karte 8, Aufgabe 9 → Karte 7.

---

### Task 1: Abhängigkeiten und `Airlock::QR`

Spec: Abschnitt 6 (QR). Der Nachweis, dass der Encoder echte QR-Codes liefert, steht am Anfang, weil Client und Beispiele darauf aufbauen.

**Files:**
- Modify: `cpanfile` (ganz ersetzen)
- Modify: `.github/workflows/ci.yml` (ein Schritt dazu)
- Create: `lib/Airlock/QR.pm`
- Test: `t/10-qr.t`, `t/11-qr-readback.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Consumes: nichts.
- Produces: `Airlock::QR->new( text => $str, ecc => 'L'|'M'|'Q'|'H', quiet => $int, encoder => $coderef )`; `->matrix` (ArrayRef von ArrayRefs aus 0/1, ohne Rand); `->size`; `->svg`; `->data_uri`; `->terminal( ansi => 0|1 )` (liefert Zeichen, nicht Bytes); `->max_bytes` (1000).

- [ ] **Step 1: `cpanfile` ersetzen**

`cpanfile`:

```perl
requires 'perl', '5.020';
requires 'Crypt::URandom';
requires 'Digest::SHA';
requires 'GD::Barcode';
requires 'HTTP::Tiny';
requires 'JSON::MaybeXS';
requires 'MIME::Base64', '3.11';
requires 'Moo';
requires 'Test::More', '0.96';
requires 'Type::Tiny';
requires 'namespace::autoclean', '0.16';

recommends 'HTTP::Message';
recommends 'IO::Socket::SSL';

on test => sub {
    requires 'HTTP::Message';
    requires 'Path::Tiny';
    requires 'Plack';
    requires 'Test::TCP';
};
```

- [ ] **Step 2: Abhängigkeiten installieren**

Run: `cpanm --installdeps .`
Expected: endet ohne Fehler; `perl -MGD::Barcode::QRcode -e 1` gibt nichts aus. `GD` selbst wird nicht installiert und nicht gebraucht.

- [ ] **Step 3: `zbar-tools` in die CI**

In `.github/workflows/ci.yml` direkt vor dem Schritt `- uses: Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test@main` einfügen:

```yaml
      - name: Install zbar-tools (QR read-back test)
        run: apt-get update && apt-get install -y --no-install-recommends zbar-tools
```

- [ ] **Step 4: Die Tests schreiben**

`t/10-qr.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;

use MIME::Base64 qw( decode_base64 );
use Airlock::QR;

my $uri = 'https://my.example.org/airlock?user_code=BCDF-GHJK';

# finder pattern: 7x7 dark ring, light ring, 3x3 dark core
my @finder = qw( 1111111 1000001 1011101 1011101 1011101 1000001 1111111 );

sub corner {
  my ( $matrix, $top, $left ) = @_;
  return [ map { join '', @{ $matrix->[ $top + $_ ] }[ $left .. $left + 6 ] } 0 .. 6 ];
}

subtest 'matrix' => sub {
  my $qr     = Airlock::QR->new( text => $uri );
  my $matrix = $qr->matrix;
  my $size   = $qr->size;
  is( scalar @$matrix, $size, 'size is the number of rows' );
  is( ( $size - 17 ) % 4, 0, 'a valid QR size (21, 25, 29, ...)' );
  ok( !grep( { @$_ != $size } @$matrix ), 'square' );
  ok( !grep( { grep { $_ != 0 && $_ != 1 } @$_ } @$matrix ), 'only 0 and 1' );
  is_deeply( corner( $matrix, 0, 0 ), \@finder, 'finder pattern top left: the border is stripped' );
  is_deeply( corner( $matrix, 0, $size - 7 ), \@finder, 'finder pattern top right' );
  is_deeply( corner( $matrix, $size - 7, 0 ), \@finder, 'finder pattern bottom left' );
  is( Airlock::QR->new( text => 'A' )->size, 21, 'a short text gives the smallest code' );
  cmp_ok( Airlock::QR->new( text => 'x' x 300 )->size, '>', $size, 'a longer text gives a bigger one' );
};

subtest 'error correction' => sub {
  my %size = map { $_ => Airlock::QR->new( text => 'x' x 60, ecc => $_ )->size } qw( L H );
  cmp_ok( $size{H}, '>', $size{L}, 'H needs more modules than L' );
  ok( !eval { Airlock::QR->new( text => 'x', ecc => 'X' ); 1 }, 'an unknown level is refused' );
};

subtest 'text guards' => sub {
  ok( !eval { Airlock::QR->new( text => '' )->matrix; 1 }, 'empty text croaks' );
  like( $@, qr/needs a text/, 'and says why' );
  ok( !eval { Airlock::QR->new( text => 'x' x 1001 )->matrix; 1 }, 'text over the limit croaks' );
  like( $@, qr/longer than 1000 bytes/, 'and says why' );
  ok( Airlock::QR->new( text => 'x' x 1000 )->matrix, 'text at the limit encodes' );
  ok( !eval { Airlock::QR->new( text => 'é' x 501 )->matrix; 1 }, 'the limit counts bytes, not characters' );
  ok( Airlock::QR->new( text => 'Grüße ✓' )->matrix, 'non-ASCII text encodes' );
  ok( !eval { Airlock::QR->new; 1 }, 'text is required' );
};

subtest 'svg' => sub {
  my $qr   = Airlock::QR->new( text => $uri );
  my $svg  = $qr->svg;
  my $side = $qr->size + 8;
  like( $svg, qr{\A<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $side $side" shape-rendering="crispEdges">}, 'root element with border in the viewBox' );
  like( $svg, qr{<rect width="$side" height="$side" fill="#fff"/>}, 'white background' );
  like( $svg, qr{<path fill="#000" d="M4 4h7v1h-7z}, 'the first run is the top edge of the finder pattern, after the border' );
  like( $svg, qr{</svg>\z}, 'closed' );
  my ( $d ) = $svg =~ /d="([^"]+)"/;
  my $dark = 0;
  $dark += $1 while $d =~ /h(\d+)v1/g;
  my $want = grep { $_ } map { @$_ } @{ $qr->matrix };
  is( $dark, $want, 'the path covers exactly the dark modules' );
  is( Airlock::QR->new( text => $uri, quiet => 0 )->svg =~ /viewBox="0 0 (\d+)/ ? $1 : 0, $qr->size, 'quiet => 0 leaves the border out' );
};

subtest 'data_uri' => sub {
  my $qr = Airlock::QR->new( text => $uri );
  my ( $payload ) = $qr->data_uri =~ m{\Adata:image/svg\+xml;base64,([A-Za-z0-9+/=]+)\z};
  ok( $payload, 'a base64 data URI without line breaks' );
  is( decode_base64($payload), $qr->svg, 'that carries the SVG' );
};

subtest 'terminal' => sub {
  my $qr    = Airlock::QR->new( text => $uri, quiet => 2 );
  my $side  = $qr->size + 4;
  my @lines = split /\n/, $qr->terminal;
  is( scalar @lines, int( ( $side + 1 ) / 2 ), 'two modules per line of text' );
  ok( !grep( { !/\A\e\[30;47m[ \x{2580}\x{2584}\x{2588}]{$side}\e\[0m\z/ } @lines ), 'every line is black on white half blocks, full width' );

  my @plain = split /\n/, $qr->terminal( ansi => 0 );
  ok( !grep( { !/\A[ \x{2580}\x{2584}\x{2588}]{$side}\z/ } @plain ), 'without ansi: only half blocks' );
  is( $plain[0], "\x{2588}" x $side, 'without ansi the border is drawn as full blocks' );
  like( $lines[0], qr/\A\e\[30;47m {$side}\e/, 'with ansi the border is blank on white' );

  my $glyphs = join '', map { /m(.+)\e/ } @lines;
  my $dark   = () = $glyphs =~ /[\x{2580}\x{2584}]/g;
  $dark += 2 * ( () = $glyphs =~ /\x{2588}/g );
  my $want = grep { $_ } map { @$_ } @{ $qr->matrix };
  is( $dark, $want, 'the blocks cover exactly the dark modules' );
};

subtest 'custom encoder' => sub {
  my @seen;
  my $ring = join "\n", ( ( '0' x 27 ) x 3 ), ( map { '000'.( '1' x 21 ).'000' } 1 .. 21 ), ( ( '0' x 27 ) x 3 );
  my $qr   = Airlock::QR->new( text => 'ü', ecc => 'Q', encoder => sub { push @seen, [@_]; $ring } );
  is( $qr->size, 21, 'an all-light border is stripped down to the code' );
  is_deeply( $seen[0], [ "\xc3\xbc", 'Q' ], 'the encoder gets bytes and the level' );
  for my $bad ( '', "101\n10", "10\n12", undef ) {
    ok( !eval { Airlock::QR->new( text => 'x', encoder => sub { $bad } )->matrix; 1 }, 'a broken pattern croaks' );
  }
};

done_testing;
```

`t/11-qr-readback.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;

use File::Temp qw( tempdir );
use Airlock::QR;

# Proof that what Airlock::QR draws is a real QR code: an independent decoder
# (zbarimg from zbar-tools) has to read the text back.

my ( $zbarimg ) = grep { -x } map { $_.'/zbarimg' } split /:/, $ENV{PATH} // '';
plan skip_all => 'zbarimg not found in PATH (apt install zbar-tools)' unless $zbarimg;

my $dir = tempdir( CLEANUP => 1 );

sub read_back {
  my ( $qr ) = @_;
  my $scale = 6;
  my @rows  = map { [ (0) x 4, @$_, (0) x 4 ] } @{ $qr->matrix };
  my $side  = @{ $rows[0] };
  @rows = ( ( [ (0) x $side ] ) x 4, @rows, ( [ (0) x $side ] ) x 4 );
  my $file = $dir.'/qr.pbm';
  CORE::open( my $out, '>', $file ) or die $!;
  print {$out} 'P1'."\n".( $side * $scale ).' '.( $side * $scale )."\n";
  for my $row (@rows) {
    my $line = join( ' ', map { ($_) x $scale } @$row )."\n";
    print {$out} $line x $scale;
  }
  close $out;
  CORE::open( my $in, '-|', $zbarimg, '--quiet', '--raw', $file ) or die $!;
  binmode $in, ':encoding(UTF-8)';
  my $text = do { local $/; <$in> } // '';
  close $in;
  chomp $text;
  return $text;
}

my %case = (
  'verification URI' => 'https://my.example.org/airlock?user_code=BCDF-GHJK',
  'otpauth URI'      => 'otpauth://totp/Mothership:getty%40example.org?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Mothership&algorithm=SHA1&digits=6&period=30',
  'short text'       => 'HELLO',
  'non-ASCII text'   => 'Grüße aus dem Mutterschiff ✓',
  'long text'        => 'https://example.org/'.( 'x' x 900 )
);

for my $name ( sort keys %case ) {
  for my $ecc (qw( L M Q H )) {
    next if $ecc ne 'M' && $name ne 'verification URI';
    is( read_back( Airlock::QR->new( text => $case{$name}, ecc => $ecc ) ), $case{$name}, $name.' reads back at level '.$ecc );
  }
}

done_testing;
```

- [ ] **Step 5: Tests laufen lassen, sie müssen scheitern**

Run: `prove -lr t/10-qr.t t/11-qr-readback.t`
Expected: FAIL mit `Can't locate Airlock/QR.pm in @INC`.

- [ ] **Step 6: `lib/Airlock/QR.pm` schreiben**

`lib/Airlock/QR.pm`:

```perl
package Airlock::QR;

# ABSTRACT: QR codes as SVG, terminal blocks or data URI, in pure Perl

use Moo;
use Carp qw( croak );
use GD::Barcode::QRcode;
use MIME::Base64 qw( encode_base64 );
use Types::Standard qw( ArrayRef CodeRef Enum Int Str );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $qr = Airlock::QR->new( text => $verification_uri_complete );

    print $qr->svg;                                  # for the web
    print '<img src="'.$qr->data_uri.'">';           # inline
    binmode STDOUT, ':encoding(UTF-8)';
    print $qr->terminal;                             # for a CLI

=description

Two places in a device flow want a QR code: the link to the approval page, so
a phone can scan what a laptop or a CLI shows, and the C<otpauth://> URI when
someone enrols a TOTP secret. This class renders both without an image
library.

Encoding is done by L<GD::Barcode::QRcode>, which is pure Perl and needs no GD
for the matrix.

=cut

has text => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

=attr text

Required. What the code says. Characters outside ASCII are encoded as UTF-8.

=cut

has ecc => (
  is      => 'ro',
  isa     => Enum[qw( L M Q H )],
  default => 'M'
);

=attr ecc

Error correction level: C<L>, C<M>, C<Q> or C<H>. Default C<M>.

=cut

has quiet => (
  is      => 'ro',
  isa     => Int,
  default => 4
);

=attr quiet

Width of the empty border, in modules. Default 4, which is what the standard
asks for.

=cut

has encoder => (
  is        => 'ro',
  isa       => CodeRef,
  predicate => 'has_encoder'
);

=attr encoder

Optional. Coderef called with the bytes and the error correction level,
returning the code as lines of C<0> and C<1>. Replaces the built-in encoder.

=cut

has matrix => (
  is       => 'lazy',
  isa      => ArrayRef[ArrayRef],
  init_arg => undef
);

=attr matrix

The code as rows of 0 and 1, without border. For own renderings.

=cut

sub max_bytes { 1000 }

=method max_bytes

Longest text, in bytes, this class encodes. 1000.

=cut

sub _build_matrix {
  my ( $self ) = @_;
  my $bytes = $self->text;
  utf8::encode($bytes) if utf8::is_utf8($bytes);
  croak __PACKAGE__.'->matrix needs a text' unless length $bytes;
  croak __PACKAGE__.'->matrix text is longer than '.$self->max_bytes.' bytes'
    if length $bytes > $self->max_bytes;
  my $pattern = $self->has_encoder ? $self->encoder->( $bytes, $self->ecc ) : $self->_encode($bytes);
  my @rows    = map { [ split // ] } grep { length } split /\n/, $pattern // '';
  croak __PACKAGE__.'->matrix encoder returned no square pattern of 0 and 1'
    if !@rows || grep { @$_ != @rows || grep { $_ ne '0' && $_ ne '1' } @$_ } @rows;
  while ( @rows > 21 && !grep { $_ } @{ $rows[0] }, @{ $rows[-1] }, map { $_->[0], $_->[-1] } @rows ) {
    @rows = map { [ @{$_}[ 1 .. $#$_ - 1 ] ] } @rows[ 1 .. $#rows - 1 ];
  }
  return [ map { [ map { $_ + 0 } @$_ ] } @rows ];
}

sub _encode {
  my ( $self, $bytes ) = @_;
  my $qr = GD::Barcode::QRcode->new( $bytes, { Ecc => $self->ecc, ModuleSize => 1 } )
    or croak __PACKAGE__.'->matrix cannot encode: '.( $GD::Barcode::errStr // 'unknown error' );
  return $qr->barcode;
}

sub size { scalar @{ $_[0]->matrix } }

=method size

Modules per side, without border.

=cut

sub svg {
  my ( $self ) = @_;
  my $quiet = $self->quiet;
  my $side  = $self->size + 2 * $quiet;
  my @path;
  my $y = $quiet;
  for my $row ( @{ $self->matrix } ) {
    my $line = join '', @$row;
    push @path, 'M'.( $-[0] + $quiet ).' '.$y.'h'.( $+[0] - $-[0] ).'v1h-'.( $+[0] - $-[0] ).'z' while $line =~ /1+/g;
    $y++;
  }
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 '.$side.' '.$side.'" shape-rendering="crispEdges">'
    .'<rect width="'.$side.'" height="'.$side.'" fill="#fff"/>'
    .'<path fill="#000" d="'.join( '', @path ).'"/></svg>';
}

=method svg

    my $svg = $qr->svg;

The code as a standalone SVG element, black on white, one unit per module.
Scale it with CSS.

=cut

sub data_uri {
  my ( $self ) = @_;
  return 'data:image/svg+xml;base64,'.encode_base64( $self->svg, '' );
}

=method data_uri

    my $src = $qr->data_uri;

The SVG as a C<data:> URI for an C<img> element.

=cut

sub terminal {
  my ( $self, %arg ) = @_;
  my $ansi  = exists $arg{ansi} ? $arg{ansi} : 1;
  my $quiet = $self->quiet;
  my $side  = $self->size + 2 * $quiet;
  my @rows  = (
    ( [ (0) x $side ] ) x $quiet,
    ( map { [ (0) x $quiet, @$_, (0) x $quiet ] } @{ $self->matrix } ),
    ( [ (0) x $side ] ) x $quiet
  );
  push @rows, [ (0) x $side ] if @rows % 2;
  my @glyph = $ansi ? ( ' ', "\x{2584}", "\x{2580}", "\x{2588}" ) : ( "\x{2588}", "\x{2580}", "\x{2584}", ' ' );
  my $out   = '';
  while ( my ( $top, $bottom ) = splice @rows, 0, 2 ) {
    my $line = join '', map { $glyph[ $top->[$_] * 2 + $bottom->[$_] ] } 0 .. $side - 1;
    $out .= $ansi ? "\e[30;47m".$line."\e[0m\n" : $line."\n";
  }
  return $out;
}

=method terminal

    binmode STDOUT, ':encoding(UTF-8)';
    print $qr->terminal;
    print $qr->terminal( ansi => 0 );

The code as Unicode half blocks, two modules per line of text. Returns
characters, so the output handle needs an encoding layer. With ANSI colours,
the default, it is black on white whatever the terminal theme; C<< ansi => 0 >>
leaves the colours out and assumes light text on a dark background.

=cut

1;
```

- [ ] **Step 7: Tests laufen lassen**

Run: `prove -lr t/10-qr.t t/11-qr-readback.t`
Expected: `t/10-qr.t` PASS (7 Subtests). `t/11-qr-readback.t` PASS mit 8 Tests, wenn `zbarimg` installiert ist, sonst `skipped: zbarimg not found in PATH`.

Wenn `zbarimg` vorhanden ist und ein Fall scheitert: nicht den Test abschwächen. Dann ist der Encoder für diesen Fall untauglich; als Notiz auf die Karte, der Koordinator entscheidet über einen anderen Encoder über das `encoder`-Attribut.

- [ ] **Step 8: Modul in den Load-Test**

In `t/00-load.t` die Zeile `  Airlock::QR` in die `qw( ... )`-Liste aufnehmen (alphabetisch). Run: `prove -lr t` — Expected: PASS.

- [ ] **Step 9: Übergabe**

Baum commit-fertig lassen, nicht committen. Karte nach `review`. Vorschlag für den Release-Manager — Betreff: `Add Airlock::QR and declare runtime dependencies`; `Changes`: `- Airlock::QR: QR codes as SVG, terminal blocks and data URI, in pure Perl`.

---

### Task 2: `Airlock::Code`

Spec: Abschnitt 6 (Code).

**Files:**
- Create: `lib/Airlock/Code.pm`
- Test: `t/20-code.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Consumes: nichts.
- Produces: `Airlock::Code->new( alphabet => $str, user_code_length => $int, secret_bytes => $int )`; `->user_code` (8 Zeichen ohne Trenner); `->secret` (64 Hex-Zeichen); `->hash($value)` (SHA-256 hex); `->normalize($input)` (Code oder leere Liste); `->display($code)` (`XXXX-XXXX`); `->equals($a, $b)` (1/0, konstante Zeit, auch als Klassenmethode aufrufbar).

- [ ] **Step 1: Den Test schreiben**

`t/20-code.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Airlock::Code;

my $code = Airlock::Code->new;

subtest 'user_code' => sub {
  my %seen;
  for ( 1 .. 500 ) {
    my $user_code = $code->user_code;
    like( $user_code, qr/\A[BCDFGHJKLMNPQRSTVWXZ]{8}\z/, 'shape' ) or last;
    $seen{$user_code}++;
  }
  is( scalar keys %seen, 500, 'no repeats in 500 draws' );
  my %letters = map { $_ => 1 } map { split // } keys %seen;
  is( scalar keys %letters, 20, 'every letter of the alphabet is drawn' );
};

subtest 'custom alphabet and length' => sub {
  my $short = Airlock::Code->new( alphabet => 'AB', user_code_length => 3 );
  like( $short->user_code, qr/\A[AB]{3}\z/, 'honours alphabet and length' );
  is( $short->normalize('a-b-a'), 'ABA', 'normalizes against its own alphabet' );
  is( $short->normalize('abc'), undef, 'rejects a foreign letter' );
};

subtest 'secret and hash' => sub {
  my $secret = $code->secret;
  like( $secret, qr/\A[0-9a-f]{64}\z/, '32 bytes as hex' );
  isnt( $code->secret, $secret, 'secrets differ' );
  is(
    $code->hash('abc'),
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    'SHA-256 of abc'
  );
};

subtest 'normalize' => sub {
  is( $code->normalize('BCDF-GHJK'),     'BCDFGHJK', 'dash removed' );
  is( $code->normalize(' bcdf ghjk '),   'BCDFGHJK', 'case and spaces' );
  is( $code->normalize('BCDF_GHJK'),     'BCDFGHJK', 'underscore' );
  is( $code->normalize('BCDF.GHJK'),     'BCDFGHJK', 'dot' );
  is( $code->normalize('BCDFGHJ'),       undef,      'too short' );
  is( $code->normalize('BCDFGHJKL'),     undef,      'too long' );
  is( $code->normalize('BCDFGHJA'),      undef,      'vowel is not in the alphabet' );
  is( $code->normalize('BCDF1HJK'),      undef,      'digit' );
  is( $code->normalize(''),              undef,      'empty' );
  is( $code->normalize(undef),           undef,      'undef' );
  is( $code->normalize("BCDFGHJK\n"),    'BCDFGHJK', 'trailing newline from a pasted code' );
};

subtest 'display' => sub {
  is( $code->display('BCDFGHJK'), 'BCDF-GHJK', 'groups of four' );
  is( $code->normalize( $code->display( $code->user_code ) ) =~ /\A\w{8}\z/ ? 1 : 0, 1, 'display round-trips through normalize' );
};

subtest 'equals' => sub {
  is( $code->equals( 'abc', 'abc' ), 1, 'equal' );
  is( $code->equals( 'abc', 'abd' ), 0, 'differs' );
  is( $code->equals( 'abc', 'abcd' ), 0, 'different length' );
  is( $code->equals( undef, 'abc' ), 0, 'undef left' );
  is( $code->equals( 'abc', undef ), 0, 'undef right' );
  is( $code->equals( '', '' ), 1, 'two empty strings' );
};

subtest 'normalize: what people and programs really send' => sub {
  is( $code->normalize("\x{c4}\x{d6}\x{dc}\x{df}BCDF"), undef, 'non-ASCII letters' );
  is( $code->normalize("\x{ff22}\x{ff23}\x{ff24}\x{ff26}\x{ff27}\x{ff28}\x{ff2a}\x{ff2b}"), undef, 'fullwidth letters are not the alphabet' );
  is( $code->normalize( 'B' x 1_000_000 ), undef, 'a megabyte of input' );
  is( $code->normalize( { a => 1 } ), undef, 'a reference' );
  is( $code->normalize("BCDF\0GHJK"), undef, 'a NUL byte' );
};

done_testing;
```

- [ ] **Step 2: Test laufen lassen, er muss scheitern**

Run: `prove -lr t/20-code.t`
Expected: FAIL mit `Can't locate Airlock/Code.pm in @INC`.

- [ ] **Step 3: `lib/Airlock/Code.pm` schreiben**

`lib/Airlock/Code.pm`:

```perl
package Airlock::Code;

# ABSTRACT: Generate, normalize, hash and compare Airlock codes

use Moo;
use Crypt::URandom qw( urandom );
use Digest::SHA qw( sha256_hex );
use Types::Standard qw( Int Str );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $code = Airlock::Code->new;

    my $user_code = $code->user_code;              # 'BCDFGHJK'
    print $code->display($user_code);              # 'BCDF-GHJK'
    my $clean = $code->normalize('bcdf ghjk');     # 'BCDFGHJK', or nothing

    my $device_code = $code->secret;               # 64 hex characters
    my $stored      = $code->hash($device_code);   # SHA-256, hex

=description

Everything Airlock does with codes: the short code a person types, the long
secret a device holds, the hash that reaches the store, and a comparison that
takes the same time whether or not the strings match.

=cut

has alphabet => (
  is      => 'ro',
  isa     => Str,
  default => 'BCDFGHJKLMNPQRSTVWXZ'
);

=attr alphabet

Characters a user code is drawn from. The default has no vowels, so no words
appear, and nothing that is easily confused when typed.

=cut

has user_code_length => (
  is      => 'ro',
  isa     => Int,
  default => 8
);

=attr user_code_length

Length of a user code. Default 8.

=cut

has secret_bytes => (
  is      => 'ro',
  isa     => Int,
  default => 32
);

=attr secret_bytes

Random bytes in a secret. Default 32.

=cut

sub user_code {
  my ( $self ) = @_;
  my @chars = split //, $self->alphabet;
  my $limit = 256 - ( 256 % @chars );
  my $code  = '';
  while ( length $code < $self->user_code_length ) {
    for my $byte ( unpack 'C*', urandom(16) ) {
      next if $byte >= $limit;
      $code .= $chars[ $byte % @chars ];
      last if length $code == $self->user_code_length;
    }
  }
  return $code;
}

=method user_code

    my $user_code = $code->user_code;

A new random user code without separator, drawn without modulo bias.

=cut

sub secret { unpack 'H*', urandom( $_[0]->secret_bytes ) }

=method secret

    my $device_code = $code->secret;

A new random secret as hex. Used for device codes and opaque tokens.

=cut

sub hash {
  my ( $self, $value ) = @_;
  return sha256_hex($value);
}

=method hash

    my $stored = $code->hash($device_code);

SHA-256 of a value as hex. Secrets reach the store only in this form.

=cut

sub normalize {
  my ( $self, $input ) = @_;
  return unless defined $input;
  my $code = uc $input;
  $code =~ s/[\s\-_.]//g;
  my $alphabet = $self->alphabet;
  return unless length $code == $self->user_code_length;
  return unless $code =~ /\A[\Q$alphabet\E]+\z/;
  return $code;
}

=method normalize

    my $clean = $code->normalize($typed) or return;

Turns what a person typed into the stored form: upper case, separators and
whitespace removed. Returns nothing unless the result is a well-formed code.

=cut

sub display {
  my ( $self, $code ) = @_;
  return join '-', $code =~ /(.{1,4})/g;
}

=method display

    print $code->display('BCDFGHJK');   # BCDF-GHJK

A code in groups of four, joined by a dash.

=cut

sub equals {
  my ( $self, $left, $right ) = @_;
  return 0 unless defined $left && defined $right;
  return 0 unless length $left == length $right;
  my $diff = 0;
  $diff |= ord( substr $left, $_, 1 ) ^ ord( substr $right, $_, 1 ) for 0 .. length($left) - 1;
  return $diff == 0 ? 1 : 0;
}

=method equals

    $code->equals( $expected, $given ) or return;

Compares two strings in constant time. Returns 1 or 0.

=cut

1;
```

- [ ] **Step 4: Test laufen lassen**

Run: `prove -lr t/20-code.t`
Expected: PASS (7 Subtests).

- [ ] **Step 5: Modul in den Load-Test**

`  Airlock::Code` in die Liste in `t/00-load.t`. Run: `prove -lr t` — Expected: PASS.

- [ ] **Step 6: Übergabe**

Commit-fertig lassen, Karte nach `review`. Betreff: `Add Airlock::Code`; `Changes`: `- Airlock::Code: user codes, secrets, hashing and constant-time comparison`.

---

### Task 3: Store-Vertrag: `Airlock::Store::Memory` und `Airlock::Test::Store`

Spec: Abschnitt 6 (Store). Der Store ist kein Objekt mit Rolle, sondern ein Hash aus vier Coderefs. `Airlock::Store::Memory` ist der eingebaute Speicher und zugleich die Referenz-Implementierung; `Airlock::Test::Store` ist die Suite, mit der jede andere Anbindung geprüft wird.

Die Zeile ist ein flacher Hash mit genau diesen Schlüsseln: `hash kind user_code client_id scope state created expires poll_interval last_poll subject amr acr auth_time approved origin_ip origin_ua factor_failures`. `hash` ist der Primärschlüssel (SHA-256 des Device-Codes oder Tokens). `kind` ist `request` oder `token`; Tokens liegen in derselben Tabelle. Das Feld heißt `poll_interval`, weil `INTERVAL` in manchen SQL-Dialekten reserviert ist.

**Files:**
- Create: `lib/Airlock/Store/Memory.pm`, `lib/Airlock/Test/Store.pm`
- Test: `t/30-store-memory.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Consumes: nichts.
- Produces: der Store-Vertrag — `insert->(\%row)` (stirbt bei doppeltem `hash` oder doppeltem definiertem `user_code`), `find->($field, $value)` mit `$field` gleich `hash` oder `user_code` (Kopie der Zeile oder nichts), `update->($hash, $from_state, \%changes)` (wahr genau dann, wenn die Zeile im Zustand `$from_state` war und geändert wurde), `purge->($before)` (Anzahl entfernter Zeilen mit `expires < $before`). `Airlock::Store::Memory->new->as_subs` liefert diesen Hash. `Airlock::Test::Store->new( store => $subs )->run`; `->row(%override)` liefert eine vollständige Beispielzeile.

- [ ] **Step 1: Den Test schreiben**

`t/30-store-memory.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Airlock::Store::Memory;
use Airlock::Test::Store;

my $memory = Airlock::Store::Memory->new;

Airlock::Test::Store->new( store => $memory->as_subs )->run;

subtest 'rows are copied in and out' => sub {
  my $fresh = Airlock::Store::Memory->new;
  my $row   = Airlock::Test::Store->new( store => $fresh->as_subs )->row;
  $fresh->insert($row);
  $row->{state} = 'tampered';
  is( $fresh->find( 'hash', 'airlock-test-1' )->{state}, 'pending', 'changing the inserted hash does not reach the store' );
  my $found = $fresh->find( 'hash', 'airlock-test-1' );
  $found->{state} = 'tampered';
  is( $fresh->find( 'hash', 'airlock-test-1' )->{state}, 'pending', 'changing a found row does not reach the store' );
};

subtest 'find refuses unknown fields' => sub {
  ok( !eval { $memory->find( 'client_id', 'client' ); 1 }, 'croaks' );
  like( $@, qr/find by client_id is not supported/, 'and says why' );
};

subtest 'refuses to be used across a fork' => sub {
  my $shared = Airlock::Store::Memory->new;
  my $pid    = fork;
  die 'fork failed: '.$! unless defined $pid;
  if ( !$pid ) {
    my $croaked = eval { $shared->find( 'hash', 'x' ); 1 } ? 0 : $@ =~ /used in another process/ ? 1 : 0;
    exit( $croaked ? 0 : 1 );
  }
  waitpid $pid, 0;
  is( $? >> 8, 0, 'the child croaks instead of looking into its own copy' );
  is( $shared->find( 'hash', 'x' ), undef, 'the parent keeps working' );
};

done_testing;
```

- [ ] **Step 2: Test laufen lassen, er muss scheitern**

Run: `prove -lr t/30-store-memory.t`
Expected: FAIL mit `Can't locate Airlock/Store/Memory.pm in @INC`.

- [ ] **Step 3: `lib/Airlock/Store/Memory.pm` schreiben**

`lib/Airlock/Store/Memory.pm`:

```perl
package Airlock::Store::Memory;

# ABSTRACT: In-process Airlock store for tests and single-process apps

use Moo;
use Carp qw( croak );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $memory  = Airlock::Store::Memory->new;
    my $airlock = Airlock->new( store => $memory->as_subs, ... );

=description

The store L<Airlock> uses when it is given none. Rows live in a hash inside the
process, so it is right for tests and for an app with exactly one process, and
wrong for anything that forks workers: used from another process than the one
that created it, it croaks.

It is also the reference for the store contract: four operations, of which
only L</update> has to be atomic.

=cut

has _rows => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { {} }
);

has _pid => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { $$ }
);

# Rows written in one process are invisible to its siblings. Under a
# preforking server that shows up as codes that are randomly unknown, so it is
# refused outright.
sub _same_process {
  my ( $self ) = @_;
  croak __PACKAGE__.' is used in another process than the one that created it;'
    .' give Airlock a store that all processes share'
    unless $$ == $self->_pid;
  return;
}

sub insert {
  my ( $self, $row ) = @_;
  $self->_same_process;
  my $rows = $self->_rows;
  croak __PACKAGE__.'->insert needs a hash' unless defined $row->{hash};
  croak __PACKAGE__.'->insert duplicate hash' if exists $rows->{ $row->{hash} };
  croak __PACKAGE__.'->insert duplicate user_code'
    if defined $row->{user_code} && $self->find( 'user_code', $row->{user_code} );
  $rows->{ $row->{hash} } = { %$row };
  return 1;
}

=method insert

    $memory->insert( \%row );

Stores a copy of the row. Croaks when the C<hash> or a defined C<user_code> is
already taken.

=cut

sub find {
  my ( $self, $field, $value ) = @_;
  $self->_same_process;
  croak __PACKAGE__.'->find by '.$field.' is not supported'
    unless $field eq 'hash' || $field eq 'user_code';
  return unless defined $value;
  for my $row ( values %{ $self->_rows } ) {
    return { %$row } if defined $row->{$field} && $row->{$field} eq $value;
  }
  return;
}

=method find

    my $row = $memory->find( hash => $hash );
    my $row = $memory->find( user_code => 'BCDFGHJK' );

A copy of the matching row, or nothing.

=cut

sub update {
  my ( $self, $hash, $from_state, $changes ) = @_;
  $self->_same_process;
  my $row = $self->_rows->{$hash} or return 0;
  return 0 unless $row->{state} eq $from_state;
  $row->{$_} = $changes->{$_} for keys %$changes;
  return 1;
}

=method update

    $memory->update( $hash, 'pending', { state => 'approved' } ) or return;

Applies the changes only if the row is still in C<$from_state>. Returns true
when it did. This condition is what makes redeeming a request happen once.

=cut

sub purge {
  my ( $self, $before ) = @_;
  $self->_same_process;
  my $rows  = $self->_rows;
  my @stale = grep { $rows->{$_}{expires} < $before } keys %$rows;
  delete @{$rows}{@stale};
  return scalar @stale;
}

=method purge

    my $removed = $memory->purge( time );

Removes every row whose C<expires> is before the given time.

=cut

sub as_subs {
  my ( $self ) = @_;
  return {
    insert => sub { $self->insert(@_) },
    find   => sub { $self->find(@_) },
    update => sub { $self->update(@_) },
    purge  => sub { $self->purge(@_) }
  };
}

=method as_subs

    my $store = $memory->as_subs;

The four operations as the hash of coderefs L<Airlock> takes as C<store>.

=cut

1;
```

- [ ] **Step 4: `lib/Airlock/Test/Store.pm` schreiben**

`lib/Airlock/Test/Store.pm`:

```perl
package Airlock::Test::Store;

# ABSTRACT: Contract tests for an Airlock store

use Moo;
use Test::More;
use Types::Standard qw( CodeRef HashRef );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    use Test::More;
    use Airlock::Test::Store;

    Airlock::Test::Store->new( store => {
      insert => sub { ... },
      find   => sub { ... },
      update => sub { ... },
      purge  => sub { ... },
    } )->run;

    done_testing;

=description

Whoever writes the four store subs for L<Airlock> runs this suite against them.
It checks what Airlock relies on: rows come back as they went in, a secret or a
user code is unique, C<update> only fires from the expected state, and C<purge>
removes what has expired and nothing else.

The suite inserts rows whose C<hash> starts with C<airlock-test->. Run it against
an empty table.

=cut

has store => (
  is       => 'ro',
  isa      => HashRef[CodeRef],
  required => 1
);

=attr store

Required. The hash of coderefs under test: C<insert>, C<find>, C<update> and,
if the store has one, C<purge>.

=cut

sub row {
  my ( $self, %override ) = @_;
  return {
    hash            => 'airlock-test-1',
    kind            => 'request',
    user_code       => 'BCDFGHJK',
    client_id       => 'client',
    scope           => 'read write',
    state           => 'pending',
    created         => 1000,
    expires         => 1600,
    poll_interval   => 5,
    last_poll       => undef,
    subject         => undef,
    amr             => undef,
    acr             => undef,
    auth_time       => undef,
    approved        => undef,
    origin_ip       => '192.0.2.1',
    origin_ua       => 'test/1.0',
    factor_failures => 0,
    %override
  };
}

=method row

    my $row = $suite->row( hash => 'airlock-test-2', user_code => undef );

A complete row with every field Airlock writes, for use in own tests.

=cut

sub run {
  my ( $self ) = @_;
  my $store = $self->store;

  subtest 'store has the required subs' => sub {
    ok( ref $store->{$_} eq 'CODE', $_.' is a coderef' ) for qw( insert find update );
  };

  subtest 'insert and find' => sub {
    $store->{insert}->( $self->row );
    my $by_hash = $store->{find}->( 'hash', 'airlock-test-1' );
    ok( $by_hash, 'found by hash' ) or return;
    my $want = $self->row;
    is( $by_hash->{$_}, $want->{$_}, 'field '.$_.' round-trips' ) for sort keys %$want;
    my $by_code = $store->{find}->( 'user_code', 'BCDFGHJK' );
    is( $by_code && $by_code->{hash}, 'airlock-test-1', 'found by user_code' );
    ok( !$store->{find}->( 'hash', 'airlock-test-nope' ), 'unknown hash finds nothing' );
    ok( !$store->{find}->( 'user_code', 'ZZZZZZZZ' ), 'unknown user_code finds nothing' );
    ok( !$store->{find}->( 'user_code', undef ), 'undef finds nothing' );
  };

  subtest 'uniqueness' => sub {
    ok( !eval { $store->{insert}->( $self->row ); 1 }, 'duplicate hash is refused' );
    ok(
      !eval { $store->{insert}->( $self->row( hash => 'airlock-test-2' ) ); 1 },
      'duplicate user_code is refused'
    );
    ok( !$store->{find}->( 'hash', 'airlock-test-2' ), 'the refused row is not there' );
    ok(
      eval { $store->{insert}->( $self->row( hash => 'airlock-test-3', user_code => undef, kind => 'token', state => 'active' ) ); 1 },
      'a row without user_code goes in'
    ) or diag $@;
    ok(
      eval { $store->{insert}->( $self->row( hash => 'airlock-test-4', user_code => undef, kind => 'token', state => 'active' ) ); 1 },
      'a second row without user_code goes in too'
    ) or diag $@;
  };

  subtest 'update is conditional on the old state' => sub {
    ok( !$store->{update}->( 'airlock-test-1', 'approved', { state => 'redeemed' } ), 'wrong old state: refused' );
    is( $store->{find}->( 'hash', 'airlock-test-1' )->{state}, 'pending', 'and nothing changed' );
    ok( !$store->{update}->( 'airlock-test-nope', 'pending', { state => 'approved' } ), 'unknown hash: refused' );
    ok(
      $store->{update}->( 'airlock-test-1', 'pending', { last_poll => 1010, poll_interval => 10 } ),
      'right old state, state itself untouched: applied'
    );
    my $polled = $store->{find}->( 'hash', 'airlock-test-1' );
    is( $polled->{last_poll}, 1010, 'last_poll written' );
    is( $polled->{poll_interval}, 10, 'poll_interval written' );
    is( $polled->{state}, 'pending', 'state still pending' );
    ok(
      $store->{update}->( 'airlock-test-1', 'pending', {
        state => 'approved', user_code => undef, subject => 'alice', amr => 'pwd otp', auth_time => 1005, approved => 1020
      } ),
      'approve: applied'
    );
    my $approved = $store->{find}->( 'hash', 'airlock-test-1' );
    is( $approved->{state},   'approved', 'state written' );
    is( $approved->{subject}, 'alice',    'subject written' );
    is( $approved->{amr},     'pwd otp',  'amr written' );
    is( $approved->{user_code}, undef,    'user_code cleared' );
    ok( !$store->{find}->( 'user_code', 'BCDFGHJK' ), 'the cleared user_code no longer finds the row' );
    ok(
      eval { $store->{insert}->( $self->row( hash => 'airlock-test-5' ) ); 1 },
      'and the user_code is free for a new row'
    ) or diag $@;
    ok( $store->{update}->( 'airlock-test-1', 'approved', { state => 'redeemed' } ), 'first redeem: applied' );
    ok( !$store->{update}->( 'airlock-test-1', 'approved', { state => 'redeemed' } ), 'second redeem: refused' );
  };

  subtest 'purge' => sub {
    plan skip_all => 'store has no purge' unless ref $store->{purge} eq 'CODE';
    $store->{insert}->( $self->row( hash => 'airlock-test-6', user_code => 'CCCCDDDD', expires => 5000 ) );
    my $removed = $store->{purge}->(1601);
    is( $removed, 4, 'purge reports how many rows it removed' );
    ok( !$store->{find}->( 'hash', 'airlock-test-'.$_ ), 'row '.$_.' is gone' ) for 1, 3, 4, 5;
    ok( $store->{find}->( 'hash', 'airlock-test-6' ), 'the row that has not expired stays' );
    is( $store->{purge}->(1601), 0, 'a second purge removes nothing' );
    is( $store->{purge}->(5001), 1, 'and the last row goes once it has expired' );
  };

  return;
}

=method run

    $suite->run;

Runs the contract as subtests of the calling test file.

=cut

1;
```

- [ ] **Step 5: Test laufen lassen**

Run: `prove -lr t/30-store-memory.t`
Expected: PASS (8 Subtests: fünf aus der Vertrags-Suite, drei eigene).

- [ ] **Step 6: Module in den Load-Test**

`  Airlock::Store::Memory` und `  Airlock::Test::Store` in die Liste in `t/00-load.t`. Run: `prove -lr t` — Expected: PASS.

- [ ] **Step 7: Übergabe**

Commit-fertig lassen, Karte nach `review`. Betreff: `Add in-process store and store contract suite`; `Changes`: `- Airlock::Store::Memory and Airlock::Test::Store: the four-sub store contract and its test suite`.

---

### Task 4: Faktoren und Policy

Spec: Abschnitt 6 (Factor, Policy).

**Files:**
- Create: `lib/Airlock/Factor.pm`, `lib/Airlock/Factor/Callback.pm`, `lib/Airlock/Factor/TOTP.pm`, `lib/Airlock/Factor/Upstream.pm`, `lib/Airlock/Policy.pm`
- Test: `t/40-factor-totp.t`, `t/41-factor-callback-upstream.t`, `t/42-policy.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Consumes: `Airlock::Code->equals($a, $b)` aus Aufgabe 2 (nur `Airlock::Factor::TOTP`). Wird Aufgabe 4 vor Aufgabe 2 ausgeführt, zuerst Aufgabe 2 erledigen.
- Produces:
  - Rolle `Airlock::Factor`: verlangt `verify($subject, $proof)`; Attribute `name`, `amr` (beide Pflicht); `needs_proof` (Standard 1); `available_for($subject)` (Standard 1).
  - `Airlock::Factor::Callback->new( name =>, amr =>, verify => sub ($subject, $proof), available => sub ($subject) )`.
  - `Airlock::Factor::TOTP->new( secret => sub ($subject), last_step => sub ($subject), accept_step => sub ($subject, $step), digits => 6, period => 30, window => 1, now => sub )`; `->code_at($secret_bytes, $step)`, `->generate_secret`, `->base32($bytes)`, `->otpauth_uri( secret =>, account =>, issuer => )`. `name` ist `totp`, `amr` ist `otp`.
  - `Airlock::Factor::Upstream->new( accept_amr => [...], accept_acr => [...], max_age => $int, now => sub )`; `needs_proof` ist 0; `->reauth_params`. `name` ist `upstream`, `amr` ist `mfa`.
  - `Airlock::Policy->new( always => [...], step_up => { scope => [...] }, max_auth_age => $int, decide => sub ($request, $subject, \@names) )`; `->required( { scopes => [...] }, $subject )` (ArrayRef von Faktor-Namen); `->fresh($subject, $now)` (1/0).
  - Ein Subject ist ein Hash mit `id` und optional `amr` (ArrayRef), `acr`, `auth_time`.

- [ ] **Step 1: Die Tests schreiben**

`t/40-factor-totp.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Airlock::Factor::TOTP;

# RFC 6238 appendix B, SHA-1 rows: 8 digits, secret "12345678901234567890"
my $rfc_secret = '12345678901234567890';
my %vector     = (
  59          => '94287082',
  1111111109  => '07081804',
  1111111111  => '14050471',
  1234567890  => '89005924',
  2000000000  => '69279037',
  20000000000 => '65353130'
);

my $clock = 0;
my %step;

sub totp {
  my ( %arg ) = @_;
  return Airlock::Factor::TOTP->new(
    secret      => sub { $_[0]{id} eq 'nobody' ? undef : $rfc_secret },
    last_step   => sub { $step{ $_[0]{id} } },
    accept_step => sub { $step{ $_[0]{id} } = $_[1] },
    now         => sub { $clock },
    %arg
  );
}

subtest 'RFC 6238 test vectors' => sub {
  my $totp = totp( digits => 8 );
  is( $totp->code_at( $rfc_secret, int( $_ / 30 ) ), $vector{$_}, 'time '.$_ ) for sort { $a <=> $b } keys %vector;
};

subtest 'defaults' => sub {
  my $totp = totp();
  is( $totp->name, 'totp', 'name' );
  is( $totp->amr,  'otp',  'amr' );
  is( $totp->needs_proof, 1, 'needs a proof' );
  is( length $totp->code_at( $rfc_secret, 1 ), 6, 'six digits' );
};

subtest 'verify' => sub {
  my $totp  = totp();
  my $alice = { id => 'alice' };
  $clock = 1_700_000_000;
  my $now_step = int( $clock / 30 );
  my $good     = $totp->code_at( $rfc_secret, $now_step );

  is( $totp->verify( $alice, 'abcdef' ),  0, 'letters' );
  is( $totp->verify( $alice, '12345' ),   0, 'too short' );
  is( $totp->verify( $alice, '1234567' ), 0, 'too long' );
  is( $totp->verify( $alice, undef ),     0, 'undef' );
  is( $totp->verify( $alice, '' ),        0, 'empty' );
  my $wrong = sprintf '%06d', ( $good + 1 ) % 1_000_000;
  is( $totp->verify( $alice, $wrong ), 0, 'wrong code' );
  is( $step{alice}, undef, 'a wrong code records no step' );

  is( $totp->verify( $alice, substr( $good, 0, 3 ).' '.substr( $good, 3 ) ), 1, 'right code, typed with a space' );
  is( $step{alice}, $now_step, 'the accepted step is recorded' );
  is( $totp->verify( $alice, $good ), 0, 'the same code a second time is refused' );
};

subtest 'window and replay' => sub {
  my $totp = totp();
  my $bob  = { id => 'bob' };
  $clock = 1_700_000_000;
  my $now_step = int( $clock / 30 );

  is( $totp->verify( $bob, $totp->code_at( $rfc_secret, $now_step - 2 ) ), 0, 'two steps back is outside the window' );
  is( $totp->verify( $bob, $totp->code_at( $rfc_secret, $now_step + 2 ) ), 0, 'two steps ahead is outside the window' );
  is( $totp->verify( $bob, $totp->code_at( $rfc_secret, $now_step + 1 ) ), 1, 'one step ahead is accepted' );
  is( $totp->verify( $bob, $totp->code_at( $rfc_secret, $now_step ) ),     0, 'an older step than the accepted one is refused' );
  is( $totp->verify( $bob, $totp->code_at( $rfc_secret, $now_step - 1 ) ), 0, 'and so is the one before' );

  my $strict = totp( window => 0 );
  my $carol  = { id => 'carol' };
  is( $strict->verify( $carol, $strict->code_at( $rfc_secret, $now_step - 1 ) ), 0, 'window 0 refuses the previous step' );
  is( $strict->verify( $carol, $strict->code_at( $rfc_secret, $now_step ) ),     1, 'window 0 accepts the current step' );
};

subtest 'not enrolled' => sub {
  my $totp = totp();
  is( $totp->available_for( { id => 'nobody' } ), 0, 'not available' );
  is( $totp->available_for( { id => 'alice' } ),  1, 'available' );
  is( $totp->verify( { id => 'nobody' }, '123456' ), 0, 'verify is false, not an exception' );
};

subtest 'enrolment helpers' => sub {
  my $totp = totp();
  is( length $totp->generate_secret, 20, 'twenty bytes' );
  isnt( $totp->generate_secret, $totp->generate_secret, 'random' );
  is( $totp->base32(''),       '',                 'RFC 4648: empty' );
  is( $totp->base32('f'),      'MY',               'RFC 4648: f' );
  is( $totp->base32('fo'),     'MZXQ',             'RFC 4648: fo' );
  is( $totp->base32('foo'),    'MZXW6',            'RFC 4648: foo' );
  is( $totp->base32('foob'),   'MZXW6YQ',          'RFC 4648: foob' );
  is( $totp->base32('fooba'),  'MZXW6YTB',         'RFC 4648: fooba' );
  is( $totp->base32('foobar'), 'MZXW6YTBOI',       'RFC 4648: foobar' );
  is(
    $totp->otpauth_uri( secret => $rfc_secret, account => 'getty@example.org', issuer => 'Mother Ship' ),
    'otpauth://totp/Mother%20Ship:getty%40example.org?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Mother%20Ship&algorithm=SHA1&digits=6&period=30',
    'otpauth URI'
  );
  ok( !eval { $totp->otpauth_uri( secret => $rfc_secret, account => 'a' ); 1 }, 'missing issuer croaks' );
  like( $@, qr/otpauth_uri needs issuer/, 'and says what is missing' );
};

subtest 'construction' => sub {
  ok( !eval { Airlock::Factor::TOTP->new( secret => sub { }, last_step => sub { } ); 1 }, 'accept_step is required' );
  ok( !eval { Airlock::Factor::TOTP->new( secret => sub { }, accept_step => sub { } ); 1 }, 'last_step is required' );
};

done_testing;
```

`t/41-factor-callback-upstream.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Airlock::Factor::Callback;
use Airlock::Factor::Upstream;

subtest 'callback' => sub {
  my @seen;
  my $factor = Airlock::Factor::Callback->new(
    name   => 'pin',
    amr    => 'pin',
    verify => sub { push @seen, [@_]; $_[1] eq '4711' }
  );
  is( $factor->name, 'pin', 'name' );
  is( $factor->amr,  'pin', 'amr' );
  is( $factor->needs_proof, 1, 'needs a proof' );
  is( $factor->available_for( { id => 'alice' } ), 1, 'available to everyone without an available sub' );
  is( $factor->verify( { id => 'alice' }, '4711' ), 1, 'right proof' );
  is( $factor->verify( { id => 'alice' }, '0000' ), 0, 'wrong proof' );
  is_deeply( $seen[0], [ { id => 'alice' }, '4711' ], 'the sub gets subject and proof' );

  my $limited = Airlock::Factor::Callback->new(
    name      => 'pin',
    amr       => 'pin',
    verify    => sub { 1 },
    available => sub { $_[0]{id} eq 'alice' }
  );
  is( $limited->available_for( { id => 'alice' } ), 1, 'available sub: yes' );
  is( $limited->available_for( { id => 'bob' } ),   0, 'available sub: no' );

  ok( !eval { Airlock::Factor::Callback->new( name => 'pin', amr => 'pin' ); 1 }, 'verify is required' );
  ok( !eval { Airlock::Factor::Callback->new( amr => 'pin', verify => sub { 1 } ); 1 }, 'name is required' );
};

subtest 'upstream' => sub {
  my $clock  = 10_000;
  my $factor = Airlock::Factor::Upstream->new( now => sub { $clock } );
  is( $factor->name, 'upstream', 'name' );
  is( $factor->amr,  'mfa',      'amr' );
  is( $factor->needs_proof, 0, 'needs no proof' );

  is( $factor->verify( { id => 'a', amr => [qw( pwd otp )] } ), 1, 'otp in amr' );
  is( $factor->verify( { id => 'a', amr => [qw( pwd mfa )] } ), 1, 'mfa in amr' );
  is( $factor->verify( { id => 'a', amr => [qw( hwk )] } ),     1, 'hwk in amr' );
  is( $factor->verify( { id => 'a', amr => [qw( pwd )] } ),     0, 'password only' );
  is( $factor->verify( { id => 'a', amr => [] } ),              0, 'empty amr' );
  is( $factor->verify( { id => 'a' } ),                         0, 'no amr at all' );
  is( $factor->verify( { id => 'a', acr => 'gold' } ),          0, 'an acr nobody configured means nothing' );

  my $acr = Airlock::Factor::Upstream->new( accept_amr => [], accept_acr => [qw( gold silver )], now => sub { $clock } );
  is( $acr->verify( { id => 'a', acr => 'gold' } ),   1, 'configured acr' );
  is( $acr->verify( { id => 'a', acr => 'bronze' } ), 0, 'other acr' );
  is( $acr->verify( { id => 'a', amr => ['otp'] } ),  0, 'amr is not accepted when the list is empty' );
  is_deeply( $acr->reauth_params, { max_age => 0, acr_values => 'gold silver' }, 'reauth params carry the acr values' );
  is_deeply( $factor->reauth_params, { max_age => 0 }, 'reauth params without acr values' );

  my $fresh = Airlock::Factor::Upstream->new( max_age => 300, now => sub { $clock } );
  is( $fresh->verify( { id => 'a', amr => ['otp'], auth_time => 9_700 } ), 1, 'exactly max_age old' );
  is( $fresh->verify( { id => 'a', amr => ['otp'], auth_time => 9_699 } ), 0, 'one second too old' );
  is( $fresh->verify( { id => 'a', amr => ['otp'] } ),                     0, 'no auth_time counts as too old' );
  is( $fresh->verify( { id => 'a', amr => ['pwd'], auth_time => 9_999 } ), 0, 'fresh but weak' );
};

done_testing;
```

`t/42-policy.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Airlock::Policy;

subtest 'empty policy' => sub {
  my $policy = Airlock::Policy->new;
  is_deeply( $policy->required( { scopes => [qw( read admin )] }, { id => 'a' } ), [], 'nothing required' );
  is( $policy->fresh( { id => 'a' }, 1000 ), 1, 'always fresh' );
};

subtest 'always and step_up' => sub {
  my $policy = Airlock::Policy->new(
    always  => ['upstream'],
    step_up => { admin => ['totp'], delete => [qw( totp pin )] }
  );
  is_deeply( $policy->required( { scopes => ['read'] }, {} ), ['upstream'], 'plain scope' );
  is_deeply( $policy->required( { scopes => [qw( read admin )] }, {} ), [qw( upstream totp )], 'step-up scope' );
  is_deeply( $policy->required( { scopes => [qw( admin delete )] }, {} ), [qw( upstream totp pin )], 'no duplicates, stable order' );
  is_deeply( $policy->required( { scopes => [] }, {} ), ['upstream'], 'no scopes' );
  is_deeply( $policy->required( {}, {} ), ['upstream'], 'request without scopes key' );
};

subtest 'decide' => sub {
  my @seen;
  my $policy = Airlock::Policy->new(
    step_up => { admin => ['totp'] },
    decide  => sub {
      my ( $request, $subject, $names ) = @_;
      push @seen, [ $request, $subject, [@$names] ];
      return $subject->{id} eq 'root' ? [ @$names, 'pin' ] : $names;
    }
  );
  is_deeply( $policy->required( { scopes => ['admin'] }, { id => 'root' } ), [qw( totp pin )], 'coderef extends the list' );
  is_deeply( $policy->required( { scopes => ['admin'] }, { id => 'alice' } ), ['totp'], 'coderef passes it through' );
  is_deeply( $seen[0], [ { scopes => ['admin'] }, { id => 'root' }, ['totp'] ], 'coderef gets request, subject, declarative list' );
};

subtest 'max_auth_age' => sub {
  my $policy = Airlock::Policy->new( max_auth_age => 300 );
  is( $policy->fresh( { auth_time => 700 }, 1000 ), 1, 'exactly at the limit' );
  is( $policy->fresh( { auth_time => 699 }, 1000 ), 0, 'one second over' );
  is( $policy->fresh( {}, 1000 ),                   0, 'no auth_time counts as too old' );
};

done_testing;
```

- [ ] **Step 2: Tests laufen lassen, sie müssen scheitern**

Run: `prove -lr t/40-factor-totp.t t/41-factor-callback-upstream.t t/42-policy.t`
Expected: alle drei FAIL mit `Can't locate Airlock/Factor/TOTP.pm`, `.../Factor/Callback.pm`, `.../Policy.pm`.

- [ ] **Step 3: Die Rolle `lib/Airlock/Factor.pm` schreiben**

Die Importe stehen vor `use Moo::Role`, damit sie nicht als Methoden in die konsumierenden Klassen wandern.

`lib/Airlock/Factor.pm`:

```perl
package Airlock::Factor;

# ABSTRACT: Role for a second factor that secures an Airlock approval

use Types::Standard qw( Str );
use Moo::Role;

our $VERSION = '0.001';

=synopsis

    package My::Factor;
    use Moo;
    with 'Airlock::Factor';

    sub verify {
      my ( $self, $subject, $proof ) = @_;
      return $proof eq 'open sesame' ? 1 : 0;
    }

=description

A factor answers one question: does this proof, from this subject, hold?
L<Airlock::Policy> decides which factors an approval needs; L<Airlock> asks
each of them and only then lets the request through.

=cut

requires 'verify';

=method verify

    $factor->verify( $subject, $proof )

Required of the consumer. Returns true when the proof holds. Must not throw
for a wrong proof.

=cut

has name => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

=attr name

Required. The name a policy refers to, and the key under which the proof
arrives in C<< approve( proofs => { ... } ) >>.

=cut

has amr => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

=attr amr

Required. The Authentication Method Reference (RFC 8176) this factor adds to
the grant once it has verified, for example C<otp>.

=cut

sub needs_proof { 1 }

=method needs_proof

True when the person has to supply something. A factor that only looks at the
subject returns false and is checked without a proof.

=cut

sub available_for { 1 }

=method available_for

    $factor->available_for($subject)

True when the subject can use this factor at all, for example has enrolled.

=cut

1;
```

- [ ] **Step 4: `lib/Airlock/Factor/Callback.pm` schreiben**

`lib/Airlock/Factor/Callback.pm`:

```perl
package Airlock::Factor::Callback;

# ABSTRACT: Second factor checked by the host application

use Moo;
with 'Airlock::Factor';
use Types::Standard qw( CodeRef );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $factor = Airlock::Factor::Callback->new(
      name   => 'totp',
      amr    => 'otp',
      verify => sub {
        my ( $subject, $proof ) = @_;
        return $directory->check_totp( $subject->{id}, $proof );
      },
    );

=description

For a host application that already has a second factor somewhere else, for
example in its directory server. Airlock hands over subject and proof and
takes the answer.

=cut

has _verify => (
  is       => 'ro',
  isa      => CodeRef,
  init_arg => 'verify',
  required => 1
);

=attr verify

Required. Coderef called with the subject and the proof; returns true when the
proof holds.

=cut

has _available => (
  is        => 'ro',
  isa       => CodeRef,
  init_arg  => 'available',
  predicate => '_has_available'
);

=attr available

Optional. Coderef called with the subject; returns true when the subject can
use this factor. Without it the factor is available to everyone.

=cut

sub verify {
  my ( $self, $subject, $proof ) = @_;
  return $self->_verify->( $subject, $proof ) ? 1 : 0;
}

sub available_for {
  my ( $self, $subject ) = @_;
  return 1 unless $self->_has_available;
  return $self->_available->($subject) ? 1 : 0;
}

1;
```

- [ ] **Step 5: `lib/Airlock/Factor/TOTP.pm` schreiben**

`lib/Airlock/Factor/TOTP.pm`:

```perl
package Airlock::Factor::TOTP;

# ABSTRACT: Time-based one-time password (RFC 6238) as an Airlock factor

use Moo;
with 'Airlock::Factor';
use Airlock::Code;
use Carp qw( croak );
use Crypt::URandom qw( urandom );
use Digest::SHA qw( hmac_sha1 );
use Types::Standard qw( CodeRef Int );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $totp = Airlock::Factor::TOTP->new(
      secret      => sub { my ( $subject ) = @_; $db->totp_secret( $subject->{id} ) },
      last_step   => sub { my ( $subject ) = @_; $db->totp_step( $subject->{id} ) },
      accept_step => sub { my ( $subject, $step ) = @_; $db->set_totp_step( $subject->{id}, $step ) },
    );

    # enrolment
    my $secret = $totp->generate_secret;
    my $uri    = $totp->otpauth_uri( secret => $secret, account => 'getty@example.org', issuer => 'Mothership' );

=description

TOTP with HMAC-SHA1, which is what authenticator apps implement. Airlock stores
nothing itself: the secret and the last accepted time step come from the host
application through three coderefs.

A code is accepted once. C<last_step> and C<accept_step> are what make that
true, which is why both are required.

=cut

has '+name' => ( default => 'totp' );
has '+amr'  => ( default => 'otp' );

has _secret => (
  is       => 'ro',
  isa      => CodeRef,
  init_arg => 'secret',
  required => 1
);

=attr secret

Required. Coderef called with the subject; returns the raw secret bytes, or
nothing when the subject has not enrolled.

=cut

has _last_step => (
  is       => 'ro',
  isa      => CodeRef,
  init_arg => 'last_step',
  required => 1
);

=attr last_step

Required. Coderef called with the subject; returns the last accepted time
step, or nothing when there is none yet.

=cut

has _accept_step => (
  is       => 'ro',
  isa      => CodeRef,
  init_arg => 'accept_step',
  required => 1
);

=attr accept_step

Required. Coderef called with the subject and the time step that was just
accepted; stores it so the same code cannot be used again.

=cut

has digits => (
  is      => 'ro',
  isa     => Int,
  default => 6
);

=attr digits

Length of a code. Default 6.

=cut

has period => (
  is      => 'ro',
  isa     => Int,
  default => 30
);

=attr period

Seconds per time step. Default 30.

=cut

has window => (
  is      => 'ro',
  isa     => Int,
  default => 1
);

=attr window

Time steps accepted before and after the current one, for clock drift.
Default 1.

=cut

has now => (
  is      => 'ro',
  isa     => CodeRef,
  default => sub { sub { time } }
);

=attr now

Coderef returning the current epoch. For tests.

=cut

sub code_class { 'Airlock::Code' }

sub code_at {
  my ( $self, $secret, $step ) = @_;
  my $counter = pack 'NN', int( $step / 4294967296 ), $step % 4294967296;
  my $mac     = hmac_sha1( $counter, $secret );
  my $offset  = ord( substr $mac, -1 ) & 0x0f;
  my $number  = unpack( 'N', substr $mac, $offset, 4 ) & 0x7fffffff;
  return sprintf '%0'.$self->digits.'d', $number % ( 10**$self->digits );
}

=method code_at

    my $code = $totp->code_at( $secret, int( time / 30 ) );

The code for a secret at a time step.

=cut

sub available_for {
  my ( $self, $subject ) = @_;
  return defined $self->_secret->($subject) ? 1 : 0;
}

sub verify {
  my ( $self, $subject, $proof ) = @_;
  return 0 unless defined $proof;
  $proof =~ s/\s//g;
  return 0 unless $proof =~ /\A[0-9]+\z/ && length $proof == $self->digits;
  my $secret = $self->_secret->($subject);
  return 0 unless defined $secret;
  my $current = int( $self->now->() / $self->period );
  my $hit;
  for my $step ( $current - $self->window .. $current + $self->window ) {
    next unless $self->code_class->equals( $self->code_at( $secret, $step ), $proof );
    $hit = $step;
  }
  return 0 unless defined $hit;
  my $last = $self->_last_step->($subject);
  return 0 if defined $last && $hit <= $last;
  $self->_accept_step->( $subject, $hit );
  return 1;
}

sub generate_secret { urandom(20) }

=method generate_secret

    my $secret = $totp->generate_secret;

Twenty random bytes for a new enrolment.

=cut

sub base32 {
  my ( $self, $bytes ) = @_;
  my @alphabet = ( 'A' .. 'Z', '2' .. '7' );
  my $bits     = unpack 'B*', $bytes;
  $bits .= '0' x ( ( 5 - length($bits) % 5 ) % 5 );
  return join '', map { $alphabet[ oct '0b'.$_ ] } $bits =~ /(.{5})/g;
}

=method base32

    my $text = $totp->base32($secret);

RFC 4648 base32 without padding, the form authenticator apps take.

=cut

sub otpauth_uri {
  my ( $self, %arg ) = @_;
  for (qw( secret account issuer )) {
    croak __PACKAGE__.'->otpauth_uri needs '.$_ unless defined $arg{$_} && length $arg{$_};
  }
  return 'otpauth://totp/'.$self->_escape( $arg{issuer} ).':'.$self->_escape( $arg{account} )
    .'?secret='.$self->base32( $arg{secret} )
    .'&issuer='.$self->_escape( $arg{issuer} )
    .'&algorithm=SHA1&digits='.$self->digits.'&period='.$self->period;
}

=method otpauth_uri

    my $uri = $totp->otpauth_uri( secret => $secret, account => 'getty@example.org', issuer => 'Mothership' );

The C<otpauth://> URI for enrolment. Feed it to L<Airlock::QR>.

=cut

sub _escape {
  my ( $self, $text ) = @_;
  utf8::encode($text) if utf8::is_utf8($text);
  $text =~ s/([^A-Za-z0-9\-._~])/sprintf '%%%02X', ord $1/ge;
  return $text;
}

1;
```

- [ ] **Step 6: `lib/Airlock/Factor/Upstream.pm` schreiben**

`lib/Airlock/Factor/Upstream.pm`:

```perl
package Airlock::Factor::Upstream;

# ABSTRACT: Accept a second factor the identity provider has already checked

use Moo;
with 'Airlock::Factor';
use Types::Standard qw( ArrayRef CodeRef Int Str );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $upstream = Airlock::Factor::Upstream->new( max_age => 300 );

    # the host app passes what the ID token said
    $airlock->approve( $user_code, subject => {
      id        => $claims->{sub},
      amr       => $claims->{amr},
      acr       => $claims->{acr},
      auth_time => $claims->{auth_time},
    } );

=description

When the host application logs people in through an identity provider that
already does multi-factor authentication, asking again would be noise. This
factor holds when the subject carries the right C<amr> or C<acr> and, if
C<max_age> is set, authenticated recently enough.

It needs no proof from the person. When it does not hold, the host application
sends the person back to the identity provider with L</reauth_params>.

=cut

has '+name' => ( default => 'upstream' );
has '+amr'  => ( default => 'mfa' );

has accept_amr => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [qw( mfa otp hwk )] }
);

=attr accept_amr

C<amr> values of which one is enough. Default C<mfa>, C<otp>, C<hwk>.

=cut

has accept_acr => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [] }
);

=attr accept_acr

C<acr> values of which one is enough. Empty by default, because what an C<acr>
value means is defined by each identity provider.

=cut

has max_age => (
  is        => 'ro',
  isa       => Int,
  predicate => 'has_max_age'
);

=attr max_age

Optional. Seconds since C<auth_time> after which the authentication is too old.

=cut

has now => (
  is      => 'ro',
  isa     => CodeRef,
  default => sub { sub { time } }
);

=attr now

Coderef returning the current epoch. For tests.

=cut

sub needs_proof { 0 }

sub verify {
  my ( $self, $subject ) = @_;
  my %amr    = map { $_ => 1 } @{ $subject->{amr} || [] };
  my $strong = grep { $amr{$_} } @{ $self->accept_amr };
  $strong ||= grep { defined $subject->{acr} && $_ eq $subject->{acr} } @{ $self->accept_acr };
  return 0 unless $strong;
  return 1 unless $self->has_max_age;
  return 0 unless defined $subject->{auth_time};
  return $self->now->() - $subject->{auth_time} <= $self->max_age ? 1 : 0;
}

sub reauth_params {
  my ( $self ) = @_;
  return {
    max_age => 0,
    @{ $self->accept_acr } ? ( acr_values => join ' ', @{ $self->accept_acr } ) : ()
  };
}

=method reauth_params

    my $params = $upstream->reauth_params;   # { max_age => 0, acr_values => '...' }

Parameters to add to the OIDC authorization request that sends the person back
to the identity provider for a fresh, strong authentication.

=cut

1;
```

- [ ] **Step 7: `lib/Airlock/Policy.pm` schreiben**

`lib/Airlock/Policy.pm`:

```perl
package Airlock::Policy;

# ABSTRACT: Decide which factors an Airlock approval needs

use Moo;
use Types::Standard qw( ArrayRef CodeRef HashRef Int Str );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $policy = Airlock::Policy->new(
      always       => ['upstream'],
      step_up      => { admin => ['totp'] },
      max_auth_age => 300,
    );

=description

Maps a request and the approving subject to the names of the factors that have
to verify before the approval counts. Declarative for the usual case, a coderef
for everything else.

=cut

has always => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [] }
);

=attr always

Factor names required for every approval.

=cut

has step_up => (
  is      => 'ro',
  isa     => HashRef[ArrayRef[Str]],
  default => sub { {} }
);

=attr step_up

Hash of scope to factor names. A request asking for that scope needs those
factors.

=cut

has max_auth_age => (
  is        => 'ro',
  isa       => Int,
  predicate => 'has_max_auth_age'
);

=attr max_auth_age

Optional. Seconds since the subject's C<auth_time> after which no approval is
accepted at all. A subject without C<auth_time> then counts as too old.

=cut

has decide => (
  is        => 'ro',
  isa       => CodeRef,
  predicate => 'has_decide'
);

=attr decide

Optional. Coderef called with the request view, the subject and the list the
declarative rules produced; returns the list to use.

=cut

sub required {
  my ( $self, $request, $subject ) = @_;
  my %seen;
  my @names = grep { !$seen{$_}++ } @{ $self->always },
    map { @{ $self->step_up->{$_} || [] } } @{ $request->{scopes} || [] };
  return $self->has_decide ? $self->decide->( $request, $subject, \@names ) : \@names;
}

=method required

    my $names = $policy->required( $view, $subject );

The factor names this approval needs, without duplicates, in a stable order.

=cut

sub fresh {
  my ( $self, $subject, $now ) = @_;
  return 1 unless $self->has_max_auth_age;
  return 0 unless defined $subject->{auth_time};
  return $now - $subject->{auth_time} <= $self->max_auth_age ? 1 : 0;
}

=method fresh

    $policy->fresh( $subject, time ) or return;

True when the subject's authentication is recent enough to approve anything.

=cut

1;
```

- [ ] **Step 8: Tests laufen lassen**

Run: `prove -lr t/40-factor-totp.t t/41-factor-callback-upstream.t t/42-policy.t`
Expected: PASS (7, 2 und 4 Subtests). Die sechs Testvektoren aus RFC 6238 Anhang B müssen stimmen; wenn nicht, ist `code_at` falsch, nicht der Test.

- [ ] **Step 9: Module in den Load-Test**

`  Airlock::Factor`, `  Airlock::Factor::Callback`, `  Airlock::Factor::TOTP`, `  Airlock::Factor::Upstream`, `  Airlock::Policy` in die Liste in `t/00-load.t`. Run: `prove -lr t` — Expected: PASS.

- [ ] **Step 10: Übergabe**

Commit-fertig lassen, Karte nach `review`. Betreff: `Add factors and policy`; `Changes`: `- Airlock::Factor role with Callback, TOTP (RFC 6238) and Upstream; Airlock::Policy for step-up rules`.

---

### Task 5: Der Kern `Airlock`

Spec: Abschnitte 2, 4, 6 (Issuer) und 8.

Zustände: `pending → approved | denied | expired`, `approved → redeemed` genau einmal. Der `user_code` bleibt an einer bestätigten Zeile hängen, bis sie eingelöst, abgelaufen oder abgelehnt ist; nur so kann ein zweiter Klick derselben Person als Erfolg erkannt werden.

**Files:**
- Create: `lib/Airlock/Result.pm`
- Modify: `lib/Airlock.pm` (der Stub wird ganz ersetzt)
- Create: `t/lib/AirlockTest.pm`
- Test: `t/50-core.t`, `t/51-core-factors.t`, `t/52-core-token.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Consumes: `Airlock::Code` (Aufgabe 2); `Airlock::Store::Memory->new->as_subs` und der Store-Vertrag (Aufgabe 3); `Airlock::Policy->required`/`->fresh` und die Rolle `Airlock::Factor` mit `name`, `amr`, `needs_proof`, `available_for`, `verify` (Aufgabe 4).
- Produces:
  - `Airlock::Result`: `ok`, `status`, `data` (HashRef), `missing` (ArrayRef), `->oauth` → `[ 200, \%data ]` oder `[ 400, { error => $status } ]`.
  - `Airlock->new( clients => \%h | $coderef, verification_uri => $str, store => \%subs, policy => $obj | \%h, factors => [...], issuer => sub ($grant), on_event => sub (\%event), now => sub, expires_in => 600, interval => 5, token_ttl => 3600, max_factor_failures => 5, code => $obj )`.
  - `->open( client_id =>, scope =>, origin => { ip =>, ua => } )` → Result; `data` hat `device_code`, `user_code`, `verification_uri`, `verification_uri_complete`, `expires_in`, `interval`.
  - `->inspect( $input, subject => $subject )` → View-Hash (`user_code`, `client_id`, `client_name`, `scopes`, `origin`, `created`, `age`, `expires_in`) oder leere Liste.
  - `->requirements( $view, $subject )` → ArrayRef von Faktor-Namen.
  - `->approve( $input, subject => $subject, proofs => { name => $proof } )` → Result mit Status `approved`, `unknown_code`, `reauth_required`, `factor_unavailable`, `factor_required`, `factor_failed`, `too_many_failures`.
  - `->deny( $input, subject => $subject )` → Result `denied` oder `unknown_code`.
  - `->redeem( device_code =>, client_id => )` → Result `granted` (Token-Antwort in `data`), `authorization_pending`, `slow_down`, `access_denied`, `expired_token`, `invalid_grant`, `invalid_request`.
  - `->verify_token($token)` → Grant-Hash oder leere Liste; `->revoke_token($token)` → 1/0; `->purge` → Anzahl; `->client($id)`; `->factor($name)`; `Airlock->row_fields`.
  - Test-Fixture `AirlockTest->new(%airlock_args)`: `->airlock`, `->memory`, `->events`, `->event_names`, `->clock`, `->advance($seconds)`, `->start(%open_args)` (liefert `data` von `open` für Client `cli`), `->row($device_code)`. Clients der Fixture: `cli` (Scopes `read write admin`) und `open` (ohne Scope-Liste).

- [ ] **Step 1: Die Test-Fixture schreiben**

`t/lib/AirlockTest.pm`:

```perl
package AirlockTest;

# Shared fixture: an Airlock with a settable clock, a recorded event log and
# direct access to the in-process store.

use strict;
use warnings;
use Airlock;
use Airlock::Store::Memory;

sub new {
  my ( $class, %arg ) = @_;
  my $self = bless { clock => 1_000_000, events => [], memory => Airlock::Store::Memory->new }, $class;
  $self->{airlock} = Airlock->new(
    clients => {
      cli  => { name => 'Test CLI', scopes => [qw( read write admin )] },
      open => {}
    },
    verification_uri => 'https://example.org/airlock',
    store            => $self->{memory}->as_subs,
    now              => sub { $self->{clock} },
    on_event         => sub { push @{ $self->{events} }, $_[0] },
    %arg
  );
  return $self;
}

sub airlock { $_[0]{airlock} }
sub memory  { $_[0]{memory} }
sub events  { $_[0]{events} }
sub clock   { $_[0]{clock} }

sub advance {
  my ( $self, $seconds ) = @_;
  return $self->{clock} += $seconds;
}

sub event_names { [ map { $_->{event} } @{ $_[0]{events} } ] }

sub start {
  my ( $self, %arg ) = @_;
  return $self->airlock->open( client_id => 'cli', scope => 'read', %arg )->data;
}

sub row {
  my ( $self, $device_code ) = @_;
  return $self->memory->find( 'hash', $self->airlock->code->hash($device_code) );
}

1;
```

- [ ] **Step 2: Die Tests schreiben**

`t/50-core.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Airlock;
use AirlockTest;

my $alice = { id => 'alice' };

{
  package FixedCode;
  use Moo;
  extends 'Airlock::Code';
  our @QUEUE;
  sub user_code { shift @QUEUE }
}

subtest 'open' => sub {
  my $t      = AirlockTest->new;
  my $result = $t->airlock->open( client_id => 'cli', scope => ' read  write ', origin => { ip => '192.0.2.7', ua => 'curl/8' } );
  ok( $result->ok, 'ok' );
  my $data = $result->data;
  like( $data->{device_code}, qr/\A[0-9a-f]{64}\z/, 'device_code' );
  like( $data->{user_code}, qr/\A[B-DF-HJ-NP-TV-XZ]{4}-[B-DF-HJ-NP-TV-XZ]{4}\z/, 'user_code in display form' );
  is( $data->{verification_uri}, 'https://example.org/airlock', 'verification_uri' );
  is( $data->{verification_uri_complete}, 'https://example.org/airlock?user_code='.$data->{user_code}, 'verification_uri_complete' );
  is( $data->{expires_in}, 600, 'expires_in' );
  is( $data->{interval},   5,   'interval' );
  is_deeply( [ sort keys %$data ], [qw( device_code expires_in interval user_code verification_uri verification_uri_complete )], 'nothing else in the response' );

  my $row = $t->row( $data->{device_code} );
  ok( $row, 'the row is stored under the hash of the device code' );
  is( $t->memory->find( 'hash', $data->{device_code} ), undef, 'and not under the device code itself' );
  is_deeply( [ sort keys %$row ], [ sort Airlock->row_fields ], 'the row has exactly the documented fields' );
  is( $row->{scope}, 'read write', 'scope is normalized' );
  is( $row->{state}, 'pending', 'state' );
  is( $row->{origin_ip}, '192.0.2.7', 'origin ip' );
  is( $row->{origin_ua}, 'curl/8', 'origin ua' );
  is_deeply( $t->event_names, ['opened'], 'event' );
};

subtest 'open: verification_uri that already has a query' => sub {
  my $t    = AirlockTest->new( verification_uri => 'https://example.org/page?view=airlock' );
  my $data = $t->start;
  is( $data->{verification_uri_complete}, 'https://example.org/page?view=airlock&user_code='.$data->{user_code}, 'joined with &' );
};

subtest 'open: refusals' => sub {
  my $t = AirlockTest->new;
  is( $t->airlock->open( client_id => 'nope' )->status,                    'invalid_client', 'unknown client' );
  is( $t->airlock->open( client_id => undef )->status,                     'invalid_client', 'no client' );
  is( $t->airlock->open( client_id => '' )->status,                        'invalid_client', 'empty client' );
  is( $t->airlock->open( client_id => 'cli', scope => 'read root' )->status, 'invalid_scope', 'scope the client may not ask for' );
  is( $t->airlock->open( client_id => 'cli', scope => 're"ad' )->status,     'invalid_scope', 'scope with a forbidden character' );
  ok( $t->airlock->open( client_id => 'cli' )->ok,                         'no scope at all is fine' );
  ok( $t->airlock->open( client_id => 'open', scope => 'anything' )->ok,   'a client without a scope list may ask for any scope' );
  is_deeply( $t->airlock->open( client_id => 'nope' )->oauth, [ 400, { error => 'invalid_client' } ], 'oauth form of a refusal' );
};

subtest 'open: long origin values are clipped' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start( origin => { ip => '1' x 200, ua => 'u' x 1000 } );
  my $row  = $t->row( $data->{device_code} );
  is( length $row->{origin_ip}, 64,  'ip clipped' );
  is( length $row->{origin_ua}, 255, 'ua clipped' );

  my $bare = $t->row( $t->airlock->open( client_id => 'cli' )->data->{device_code} );
  is_deeply( [ sort keys %$bare ], [ sort Airlock->row_fields ], 'without an origin the row still has every field' );
  is( $bare->{origin_ip}, undef, 'and the origin is undef' );
};

subtest 'clients as a coderef' => sub {
  my $t = AirlockTest->new( clients => sub { $_[0] eq 'dyn' ? { name => 'Dynamic' } : undef } );
  ok( $t->airlock->open( client_id => 'dyn' )->ok, 'known to the coderef' );
  is( $t->airlock->open( client_id => 'cli' )->status, 'invalid_client', 'unknown to the coderef' );
  is( $t->airlock->client('dyn')->{name}, 'Dynamic', 'client() goes through the coderef' );
};

subtest 'inspect' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start( scope => 'read admin', origin => { ip => '192.0.2.7', ua => 'curl/8' } );
  $t->advance(42);
  my $view = $t->airlock->inspect( lc $data->{user_code} );
  is_deeply( $view, {
    user_code   => $data->{user_code},
    client_id   => 'cli',
    client_name => 'Test CLI',
    scopes      => [qw( read admin )],
    origin      => { ip => '192.0.2.7', ua => 'curl/8' },
    created     => 1_000_000,
    age         => 42,
    expires_in  => 558
  }, 'the view' );
  ok( !exists $view->{hash} && !exists $view->{device_code}, 'no secret in the view' );
  is( $t->row( $data->{device_code} )->{state}, 'pending', 'looking does not approve' );

  my @none = $t->airlock->inspect( 'ZZZZ-ZZZZ', subject => $alice );
  is( scalar @none, 0, 'unknown code: nothing, also in list context' );
  is( $t->airlock->inspect('not a code'), undef, 'malformed code' );
  is( $t->airlock->inspect(undef),        undef, 'undef' );
  is_deeply( $t->event_names, [qw( opened code_miss code_miss code_miss )], 'misses are reported' );
  is( $t->events->[1]{subject}, 'alice', 'with the subject when there is one' );
};

subtest 'approve, then redeem exactly once' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start( scope => 'read write' );

  my $pending = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' );
  is( $pending->status, 'authorization_pending', 'pending before approval' );
  is_deeply( $pending->oauth, [ 400, { error => 'authorization_pending' } ], 'oauth form' );

  $t->advance(10);
  my $approved = $t->airlock->approve( $data->{user_code}, subject => { id => 'alice', amr => ['pwd'], acr => '1', auth_time => 999_000 } );
  ok( $approved->ok, 'approved' );
  is( $approved->status, 'approved', 'status' );
  my $row = $t->row( $data->{device_code} );
  is( $row->{state}, 'approved', 'row state' );
  is( $t->airlock->inspect( $data->{user_code} ), undef, 'the code no longer inspects' );

  $t->advance(10);
  my $granted = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' );
  ok( $granted->ok, 'granted' );
  is( $granted->status, 'granted', 'status' );
  my $token = $granted->data;
  like( $token->{access_token}, qr/\A[0-9a-f]{64}\z/, 'opaque access token' );
  is( $token->{token_type}, 'Bearer', 'token type' );
  is( $token->{expires_in}, 3600, 'expires_in' );
  is( $token->{scope}, 'read write', 'scope' );
  is( $granted->oauth->[0], 200, 'oauth status' );

  $t->advance(10);
  is( $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->status, 'invalid_grant', 'second redeem is refused' );
  is_deeply( $t->event_names, [qw( opened approved code_miss redeemed )], 'events' );

  my $grant = $t->airlock->verify_token( $token->{access_token} );
  is_deeply( $grant, {
    subject   => 'alice',
    client_id => 'cli',
    scope     => 'read write',
    scopes    => [qw( read write )],
    amr       => ['pwd'],
    acr       => '1',
    auth_time => 999_000,
    expires   => 1_000_020 + 3600
  }, 'the token carries the grant' );
};

subtest 'deny' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  my $done = $t->airlock->deny( $data->{user_code}, subject => $alice );
  ok( $done->ok, 'denied' );
  is( $done->status, 'denied', 'status' );
  is( $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->status, 'access_denied', 'the client learns it' );
  is( $t->airlock->approve( $data->{user_code}, subject => $alice )->status, 'unknown_code', 'a denied request cannot be approved' );
  is( $t->airlock->deny( 'ZZZZ-ZZZZ', subject => $alice )->status, 'unknown_code', 'unknown code' );
};

subtest 'approve and deny need a subject' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  for my $bad ( undef, {}, { id => '' }, 'alice' ) {
    ok( !eval { $t->airlock->approve( $data->{user_code}, subject => $bad ); 1 }, 'approve croaks' );
    like( $@, qr/approve needs a subject with an id/, 'and says why' );
  }
  ok( !eval { $t->airlock->deny( $data->{user_code} ); 1 }, 'deny croaks' );
  is( $t->row( $data->{device_code} )->{state}, 'pending', 'and the request is untouched' );
};

subtest 'expiry' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  $t->advance(599);
  ok( $t->airlock->inspect( $data->{user_code} ), 'one second before expiry it still inspects' );
  $t->advance(1);
  is( $t->airlock->inspect( $data->{user_code} ), undef, 'at expiry it does not' );
  is( $t->airlock->approve( $data->{user_code}, subject => $alice )->status, 'unknown_code', 'nor approve' );
  is( $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->status, 'expired_token', 'the client gets expired_token' );
  is( $t->row( $data->{device_code} )->{state}, 'expired', 'row state' );

  my $late = $t->start;
  $t->airlock->approve( $late->{user_code}, subject => $alice );
  $t->advance(600);
  is( $t->airlock->redeem( device_code => $late->{device_code}, client_id => 'cli' )->status, 'expired_token', 'an approved request expires too' );
};

subtest 'slow_down' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  my $poll = sub { $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->status };
  is( $poll->(), 'authorization_pending', 'first poll' );
  $t->advance(4);
  is( $poll->(), 'slow_down', 'four seconds later is too fast' );
  is( $t->row( $data->{device_code} )->{poll_interval}, 10, 'the interval grew by five' );
  $t->advance(9);
  is( $poll->(), 'slow_down', 'nine seconds later is too fast for the new interval' );
  is( $t->row( $data->{device_code} )->{poll_interval}, 15, 'and it grew again' );
  $t->advance(15);
  is( $poll->(), 'authorization_pending', 'waiting the full interval is fine' );

  $t->airlock->approve( $data->{user_code}, subject => $alice );
  $t->advance(1);
  is( $poll->(), 'slow_down', 'polling too fast after approval still slows down' );
  is( $t->row( $data->{device_code} )->{state}, 'approved', 'and does not burn the approval' );
  $t->advance(20);
  is( $poll->(), 'granted', 'the next patient poll gets the token' );
};

subtest 'redeem: refusals' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  is( $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'open' )->status, 'invalid_grant', 'another client' );
  is( $t->airlock->redeem( device_code => 'f' x 64, client_id => 'cli' )->status, 'invalid_grant', 'unknown device code' );
  is( $t->airlock->redeem( client_id => 'cli' )->status, 'invalid_request', 'no device code' );
  is( $t->airlock->redeem( device_code => $data->{device_code} )->status, 'invalid_request', 'no client' );
  is( $t->airlock->redeem( device_code => '', client_id => 'cli' )->status, 'invalid_request', 'empty device code' );
  is( $t->row( $data->{device_code} )->{last_poll}, undef, 'a poll by the wrong client does not count as a poll' );
};

subtest 'user codes are reused only after they are released' => sub {
  @FixedCode::QUEUE = qw( BBBBBBBB BBBBBBBB CCCCCCCC BBBBBBBB );
  my $t     = AirlockTest->new( code => FixedCode->new );
  my $first = $t->start;
  is( $first->{user_code}, 'BBBB-BBBB', 'first request' );
  my $second = $t->start;
  is( $second->{user_code}, 'CCCC-CCCC', 'a taken code is skipped' );
  $t->advance(600);
  my $third = $t->start;
  is( $third->{user_code}, 'BBBB-BBBB', 'an expired code is taken over' );
  is( $t->row( $first->{device_code} )->{state}, 'expired', 'and its old request is marked expired' );
  is( $t->airlock->inspect('BBBB-BBBB')->{age}, 0, 'the code now belongs to the new request' );
};

subtest 'custom issuer' => sub {
  my @grants;
  my $t    = AirlockTest->new( issuer => sub { push @grants, $_[0]; { access_token => 'custom', token_type => 'Bearer' } } );
  my $data = $t->start( scope => 'read admin' );
  $t->airlock->approve( $data->{user_code}, subject => { id => 'alice', amr => [qw( pwd otp )], auth_time => 5 } );
  my $granted = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' );
  is_deeply( $granted->data, { access_token => 'custom', token_type => 'Bearer' }, 'the issuer decides the response' );
  is_deeply( $grants[0], {
    subject   => 'alice',
    client_id => 'cli',
    scope     => 'read admin',
    scopes    => [qw( read admin )],
    amr       => [qw( pwd otp )],
    acr       => undef,
    auth_time => 5
  }, 'and gets the grant' );
  is( $t->airlock->verify_token('custom'), undef, 'verify_token knows only opaque tokens' );

  my $broken = AirlockTest->new( issuer => sub { 'not a hash' } );
  my $start  = $broken->start;
  $broken->airlock->approve( $start->{user_code}, subject => $alice );
  ok( !eval { $broken->airlock->redeem( device_code => $start->{device_code}, client_id => 'cli' ); 1 }, 'an issuer returning no hash croaks' );
  like( $@, qr/issuer must return a hash/, 'and says why' );
  is( $broken->row( $start->{device_code} )->{state}, 'redeemed', 'the request is used up, not handed out twice' );
};

subtest 'events carry no secrets' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  $t->airlock->inspect('ZZZZ-ZZZZ');
  $t->airlock->approve( $data->{user_code}, subject => $alice );
  my $token = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->data->{access_token};
  my $plain = $data->{user_code} =~ s/-//r;
  for my $event ( @{ $t->events } ) {
    my $dump = join ' ', map { ref $_ ? %$_ : $_ // '' } %$event;
    unlike( $dump, qr/\Q$data->{device_code}\E|\Q$data->{user_code}\E|\Q$plain\E|\Q$token\E|ZZZZ/, $event->{event}.' is clean' );
  }
};

subtest 'construction' => sub {
  ok( !eval { Airlock->new( verification_uri => 'https://x' ); 1 }, 'clients is required' );
  ok( !eval { Airlock->new( clients => {} ); 1 }, 'verification_uri is required' );
  ok( !eval { Airlock->new( clients => {}, verification_uri => 'https://x', store => { insert => sub { }, find => sub { } } ); 1 }, 'a store without update is refused' );
  like( $@, qr/store needs a update sub/, 'and says what is missing' );
  ok( Airlock->new( clients => {}, verification_uri => 'https://x' ), 'the store has a default' );
};

subtest 'a double click on approve is not an error' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  ok( $t->airlock->approve( $data->{user_code}, subject => $alice )->ok, 'first click' );
  my $again = $t->airlock->approve( $data->{user_code}, subject => $alice );
  ok( $again->ok, 'second click by the same person succeeds too' );
  is( $again->status, 'approved', 'with the same status' );
  is( $t->airlock->approve( $data->{user_code}, subject => { id => 'mallory' } )->status, 'unknown_code', 'another person learns nothing' );
  is( $t->airlock->deny( $data->{user_code}, subject => $alice )->status, 'unknown_code', 'an approval cannot be turned into a denial' );
  is( $t->airlock->inspect( $data->{user_code} ), undef, 'and the code no longer inspects' );
  is( scalar( grep { $_ eq 'approved' } @{ $t->event_names } ), 1, 'one approved event, not two' );
  $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' );
  is( $t->airlock->approve( $data->{user_code}, subject => $alice )->status, 'unknown_code', 'after the token is out the code is gone for good' );
  is( $t->row( $data->{device_code} )->{user_code}, undef, 'and released' );
};

subtest 'two polls racing for one approval get one token' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  $t->airlock->approve( $data->{user_code}, subject => $alice );
  my $stale = $t->row( $data->{device_code} );

  # the second poller read the row before the first one redeemed it
  my $late = Airlock->new(
    clients          => { cli => {} },
    verification_uri => 'https://example.org/airlock',
    now              => sub { $t->clock },
    store            => { %{ $t->memory->as_subs }, find => sub { $_[0] eq 'hash' ? { %$stale } : $t->memory->find(@_) } }
  );
  ok( $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->ok, 'the first poll gets the token' );
  is( $late->redeem( device_code => $data->{device_code}, client_id => 'cli' )->status, 'invalid_grant', 'the second, working on what it read earlier, gets none' );
  is( scalar( grep { $_->{kind} eq 'token' } values %{ $t->memory->_rows } ), 1, 'exactly one token exists' );
};

subtest 'a subject id that does not fit' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  ok( !eval { $t->airlock->approve( $data->{user_code}, subject => { id => 'x' x 256 } ); 1 }, 'croaks' );
  like( $@, qr/subject id is longer than 255 characters/, 'and says why' );
  ok( $t->airlock->approve( $data->{user_code}, subject => { id => 'x' x 255 } )->ok, '255 characters fit' );
};

done_testing;
```

`t/51-core-factors.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Airlock::Factor::Callback;
use Airlock::Factor::Upstream;
use AirlockTest;

my @pin_calls;

sub fixture {
  my ( %arg ) = @_;
  @pin_calls = ();
  my $t;
  $t = AirlockTest->new(
    policy  => { step_up => { admin => ['pin'] } },
    factors => [
      Airlock::Factor::Callback->new(
        name      => 'pin',
        amr       => 'pin',
        verify    => sub { push @pin_calls, $_[1]; $_[1] eq '4711' },
        available => sub { $_[0]{id} ne 'nopin' }
      ),
      Airlock::Factor::Upstream->new( max_age => 300, now => sub { $t->clock } )
    ],
    %arg
  );
  return $t;
}

my $alice = { id => 'alice', amr => ['pwd'] };

subtest 'a scope without step-up needs no factor' => sub {
  my $t    = fixture();
  my $data = $t->start( scope => 'read' );
  is_deeply( $t->airlock->requirements( $t->airlock->inspect( $data->{user_code} ), $alice ), [], 'requirements' );
  ok( $t->airlock->approve( $data->{user_code}, subject => $alice )->ok, 'approved without proof' );
  is( scalar @pin_calls, 0, 'the factor was never asked' );
};

subtest 'a step-up scope asks for the factor' => sub {
  my $t    = fixture();
  my $data = $t->start( scope => 'read admin' );
  is_deeply( $t->airlock->requirements( $t->airlock->inspect( $data->{user_code} ), $alice ), ['pin'], 'requirements' );

  my $asked = $t->airlock->approve( $data->{user_code}, subject => $alice );
  is( $asked->status, 'factor_required', 'without proof: factor_required' );
  is_deeply( $asked->missing, ['pin'], 'and names the factor' );
  is( scalar @pin_calls, 0, 'a missing proof is not a verification' );
  is( $t->row( $data->{device_code} )->{factor_failures}, 0, 'nor a failure' );

  my $wrong = $t->airlock->approve( $data->{user_code}, subject => $alice, proofs => { pin => '1234' } );
  is( $wrong->status, 'factor_failed', 'wrong proof: factor_failed' );
  is_deeply( $wrong->missing, ['pin'], 'names the factor' );
  is( $t->row( $data->{device_code} )->{factor_failures}, 1, 'counted' );
  is( $t->row( $data->{device_code} )->{state}, 'pending', 'still pending' );

  my $right = $t->airlock->approve( $data->{user_code}, subject => $alice, proofs => { pin => '4711' } );
  ok( $right->ok, 'right proof: approved' );
  my $token = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->data->{access_token};
  is_deeply( $t->airlock->verify_token($token)->{amr}, [qw( pwd pin )], 'the grant carries the factor amr after the subject amr' );
  is_deeply( $t->event_names, [qw( opened factor_failed approved redeemed )], 'events' );
  is( $t->events->[1]{factor}, 'pin', 'the failure event names the factor' );
  ok( !grep( { /4711|1234/ } map { values %$_ } @{ $t->events } ), 'and no event carries a proof' );
};

subtest 'too many failures deny the request' => sub {
  my $t    = fixture( max_factor_failures => 3 );
  my $data = $t->start( scope => 'admin' );
  my $try  = sub { $t->airlock->approve( $data->{user_code}, subject => $alice, proofs => { pin => $_[0] } )->status };
  is( $try->('0001'), 'factor_failed',     'first' );
  is( $try->('0002'), 'factor_failed',     'second' );
  is( $try->('0003'), 'too_many_failures', 'third is final' );
  is( $t->row( $data->{device_code} )->{state}, 'denied', 'the request is denied' );
  is( $try->('4711'), 'unknown_code', 'the right proof comes too late' );
  is( $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->status, 'access_denied', 'the client is told' );
};

subtest 'a factor the subject does not have' => sub {
  my $t      = fixture();
  my $data   = $t->start( scope => 'admin' );
  my $result = $t->airlock->approve( $data->{user_code}, subject => { id => 'nopin' }, proofs => { pin => '4711' } );
  is( $result->status, 'factor_unavailable', 'factor_unavailable' );
  is_deeply( $result->missing, ['pin'], 'names the factor' );
  is( scalar @pin_calls, 0, 'and it is not verified' );
  is( $t->row( $data->{device_code} )->{factor_failures}, 0, 'nor counted as a failure' );
};

subtest 'upstream factor: no proof, no failure count' => sub {
  my $t    = fixture( policy => { always => ['upstream'] } );
  my $data = $t->start;
  is( $t->airlock->approve( $data->{user_code}, subject => { id => 'a', amr => ['pwd'], auth_time => $t->clock } )->status,
    'reauth_required', 'weak login: reauth_required' );
  is( $t->airlock->approve( $data->{user_code}, subject => { id => 'a', amr => ['otp'], auth_time => $t->clock - 301 } )->status,
    'reauth_required', 'old login: reauth_required' );
  is( $t->row( $data->{device_code} )->{factor_failures}, 0, 'neither counts as a failure' );
  ok( $t->airlock->approve( $data->{user_code}, subject => { id => 'a', amr => [qw( pwd otp )], auth_time => $t->clock - 10 } )->ok, 'strong, fresh login: approved' );
  my $token = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->data->{access_token};
  is_deeply( $t->airlock->verify_token($token)->{amr}, [qw( pwd otp mfa )], 'amr without duplicates' );
};

subtest 'two factors: upstream and pin' => sub {
  my $t      = fixture( policy => { always => ['upstream'], step_up => { admin => ['pin'] } } );
  my $data   = $t->start( scope => 'admin' );
  my $strong = { id => 'a', amr => ['otp'], auth_time => $t->clock };
  is_deeply( $t->airlock->requirements( $t->airlock->inspect( $data->{user_code} ), $strong ), [qw( upstream pin )], 'requirements' );
  my $asked = $t->airlock->approve( $data->{user_code}, subject => $strong );
  is( $asked->status, 'factor_required', 'upstream holds, pin is still missing' );
  is_deeply( $asked->missing, ['pin'], 'only the pin is asked for' );
  ok( $t->airlock->approve( $data->{user_code}, subject => $strong, proofs => { pin => '4711' } )->ok, 'both: approved' );
};

subtest 'max_auth_age refuses any approval from an old login' => sub {
  my $t    = fixture( policy => { max_auth_age => 60 } );
  my $data = $t->start;
  is( $t->airlock->approve( $data->{user_code}, subject => { id => 'a', auth_time => $t->clock - 61 } )->status, 'reauth_required', 'too old' );
  is( $t->airlock->approve( $data->{user_code}, subject => { id => 'a' } )->status, 'reauth_required', 'no auth_time' );
  ok( $t->airlock->approve( $data->{user_code}, subject => { id => 'a', auth_time => $t->clock - 60 } )->ok, 'fresh enough' );
};

subtest 'a policy naming an unknown factor is a programming error' => sub {
  my $t    = fixture( policy => { always => ['fingerprint'] } );
  my $data = $t->start;
  ok( !eval { $t->airlock->approve( $data->{user_code}, subject => $alice ); 1 }, 'croaks' );
  like( $@, qr/unknown factor fingerprint/, 'and names it' );
};

done_testing;
```

`t/52-core-token.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use AirlockTest;

sub token {
  my ( $t ) = @_;
  my $data = $t->start;
  $t->airlock->approve( $data->{user_code}, subject => { id => 'alice' } );
  return $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->data->{access_token};
}

subtest 'verify_token' => sub {
  my $t     = AirlockTest->new;
  my $token = token($t);
  ok( $t->airlock->verify_token($token), 'a fresh token verifies' );
  is( $t->memory->find( 'hash', $token ), undef, 'the store does not hold the token itself' );
  is( $t->airlock->verify_token( 'f' x 64 ), undef, 'unknown token' );
  is( $t->airlock->verify_token(''),         undef, 'empty' );
  is( $t->airlock->verify_token(undef),      undef, 'undef' );
  $t->advance(3599);
  ok( $t->airlock->verify_token($token), 'one second before expiry' );
  $t->advance(1);
  is( $t->airlock->verify_token($token), undef, 'at expiry' );
};

subtest 'a device code is not a token and a token is not a device code' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  is( $t->airlock->verify_token( $data->{device_code} ), undef, 'device code as token' );
  my $token = token($t);
  is( $t->airlock->redeem( device_code => $token, client_id => 'cli' )->status, 'invalid_grant', 'token as device code' );
};

subtest 'revoke_token' => sub {
  my $t     = AirlockTest->new;
  my $token = token($t);
  is( $t->airlock->revoke_token($token), 1, 'revoked' );
  is( $t->airlock->verify_token($token), undef, 'no longer verifies' );
  is( $t->airlock->revoke_token($token), 0, 'revoking twice reports nothing to revoke' );
  is( $t->airlock->revoke_token('nope'), 0, 'unknown token' );
  is( $t->airlock->revoke_token(undef),  0, 'undef' );
};

subtest 'token_ttl' => sub {
  my $t = AirlockTest->new( token_ttl => 60 );
  my $data = $t->start;
  $t->airlock->approve( $data->{user_code}, subject => { id => 'alice' } );
  my $response = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->data;
  is( $response->{expires_in}, 60, 'expires_in follows token_ttl' );
  $t->advance(60);
  is( $t->airlock->verify_token( $response->{access_token} ), undef, 'and so does expiry' );
};

subtest 'purge' => sub {
  my $t     = AirlockTest->new;
  my $token = token($t);
  my $open  = $t->start;
  is( $t->airlock->purge, 0, 'nothing has expired yet' );
  $t->advance(601);
  is( $t->airlock->purge, 2, 'the redeemed and the abandoned request go' );
  ok( $t->airlock->verify_token($token), 'the token stays' );
  $t->advance(3600);
  is( $t->airlock->purge, 1, 'until it has expired too' );

  my $bare = AirlockTest->new;
  delete $bare->airlock->store->{purge};
  is( $bare->airlock->purge, 0, 'a store without purge is fine' );
};

done_testing;
```

- [ ] **Step 3: Tests laufen lassen, sie müssen scheitern**

Run: `prove -lr t/50-core.t t/51-core-factors.t t/52-core-token.t`
Expected: FAIL. Der Stub `Airlock` hat kein `new` mit diesen Attributen; die erste Meldung ist `Can't locate object method "new" via package "Airlock"`.

- [ ] **Step 4: `lib/Airlock/Result.pm` schreiben**

`lib/Airlock/Result.pm`:

```perl
package Airlock::Result;

# ABSTRACT: Outcome of an Airlock operation

use Moo;
use Types::Standard qw( ArrayRef Bool HashRef Str );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $result = $airlock->redeem( device_code => $device_code, client_id => $client_id );

    if ( $result->ok ) { my $token = $result->data->{access_token} }
    else               { warn $result->status }

    my ( $http_status, $json ) = @{ $result->oauth };

=description

Every L<Airlock> operation that can fail for an ordinary reason returns one of
these instead of throwing. Exceptions are kept for programming errors.

=cut

has ok => (
  is       => 'ro',
  isa      => Bool,
  required => 1
);

=attr ok

True when the operation did what was asked.

=cut

has status => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

=attr status

What happened, as one word. On failure this is the OAuth error code where one
exists (C<authorization_pending>, C<slow_down>, C<access_denied>,
C<expired_token>, C<invalid_grant>, C<invalid_client>, C<invalid_scope>,
C<invalid_request>) or an Airlock reason (C<unknown_code>, C<factor_required>,
C<factor_unavailable>, C<factor_failed>, C<too_many_failures>,
C<reauth_required>).

=cut

has data => (
  is      => 'ro',
  isa     => HashRef,
  default => sub { {} }
);

=attr data

The payload of a success: the device authorization response after C<open>, the
token response after C<redeem>.

=cut

has missing => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [] }
);

=attr missing

Names of the factors an approval still needs or that did not hold.

=cut

sub oauth {
  my ( $self ) = @_;
  return $self->ok ? [ 200, { %{ $self->data } } ] : [ 400, { error => $self->status } ];
}

=method oauth

    my ( $http_status, $json ) = @{ $result->oauth };

The result as RFC 8628 wants it on the wire: 200 with the payload, or 400 with
C<error>.

=cut

1;
```

- [ ] **Step 5: `lib/Airlock.pm` ersetzen**

Die Methode heißt `open`, wie in der Spec. Innerhalb des Pakets wird das eingebaute `open` nirgends aufgerufen; wer es je braucht, schreibt `CORE::open`.

`lib/Airlock.pm`:

```perl
package Airlock;

# ABSTRACT: Embeddable device authorization (RFC 8628) with step-up second factors

use Moo;
use Airlock::Code;
use Airlock::Policy;
use Airlock::Result;
use Airlock::Store::Memory;
use Carp qw( croak );
use Types::Standard qw( ArrayRef CodeRef ConsumerOf HashRef InstanceOf Int Str );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $airlock = Airlock->new(
      clients          => { 'my-cli' => { name => 'My CLI', scopes => [qw( read admin )] } },
      verification_uri => 'https://my.example.org/airlock',
      store            => { insert => sub {...}, find => sub {...}, update => sub {...}, purge => sub {...} },
      policy           => { step_up => { admin => ['totp'] } },
      factors          => [ Airlock::Factor::Callback->new( name => 'totp', amr => 'otp', verify => sub {...} ) ],
    );

    # human side: the host application renders its own page
    my $view  = $airlock->inspect( $typed_code, subject => $subject ) or return not_found();
    my $needs = $airlock->requirements( $view, $subject );            # ['totp']
    my $done  = $airlock->approve( $typed_code, subject => $subject, proofs => { totp => $typed_totp } );

=description

Airlock approves a waiting request from an already trusted session: the server
side of the OAuth 2.0 Device Authorization Grant (RFC 8628), with an optional
second factor before the approval counts.

It is a core to embed. The host application supplies who is logged in, the
approval page and where rows are kept. Airlock supplies codes, the state
machine, poll rules, one-time redemption, step-up policy, second factors and
the two machine endpoints.

A request moves C<pending> to C<approved>, C<denied> or C<expired>, and
C<approved> to C<redeemed> exactly once.

=cut

has clients => (
  is       => 'ro',
  isa      => HashRef | CodeRef,
  required => 1
);

=attr clients

Required. Who may ask. A hash of client id to C<< { name => ..., scopes => [...] } >>,
or a coderef called with a client id that returns such a hash or nothing. A
client without C<scopes> may ask for any scope.

=cut

has verification_uri => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

=attr verification_uri

Required. Where the host application serves its approval page.

=cut

has store => (
  is  => 'lazy',
  isa => HashRef[CodeRef]
);

sub _build_store { Airlock::Store::Memory->new->as_subs }

=attr store

Hash of four coderefs: C<insert>, C<find>, C<update> and optionally C<purge>.
The contract is documented in L<Airlock::Store::Memory> and checked by
L<Airlock::Test::Store>. Default: an in-process store.

=cut

has policy => (
  is     => 'lazy',
  isa    => InstanceOf['Airlock::Policy'],
  coerce => sub { ref $_[0] eq 'HASH' ? Airlock::Policy->new( $_[0] ) : $_[0] }
);

sub _build_policy { Airlock::Policy->new }

=attr policy

An L<Airlock::Policy> or the hash to build one from. Default: no factors.

=cut

has factors => (
  is      => 'ro',
  isa     => ArrayRef[ConsumerOf['Airlock::Factor']],
  default => sub { [] }
);

=attr factors

The L<Airlock::Factor> objects a policy may name.

=cut

has issuer => (
  is        => 'ro',
  isa       => CodeRef,
  predicate => 'has_issuer'
);

=attr issuer

Optional. Coderef called with the grant, returning the token response as a
hash. Without it Airlock issues an opaque random token, keeps its hash in the
store and checks it with L</verify_token>.

=cut

has on_event => (
  is        => 'ro',
  isa       => CodeRef,
  predicate => 'has_on_event'
);

=attr on_event

Optional. Coderef called with a hash for C<opened>, C<approved>, C<denied>,
C<redeemed>, C<factor_failed> and C<code_miss>. Hang the audit log and rate
limits here. Events never carry codes, tokens or proofs.

=cut

has now => (
  is      => 'ro',
  isa     => CodeRef,
  default => sub { sub { time } }
);

=attr now

Coderef returning the current epoch. For tests.

=cut

has expires_in => (
  is      => 'ro',
  isa     => Int,
  default => 600
);

=attr expires_in

Seconds a request lives. Default 600.

=cut

has interval => (
  is      => 'ro',
  isa     => Int,
  default => 5
);

=attr interval

Seconds a client has to wait between polls. Default 5.

=cut

has token_ttl => (
  is      => 'ro',
  isa     => Int,
  default => 3600
);

=attr token_ttl

Seconds an opaque token lives. Default 3600.

=cut

has max_factor_failures => (
  is      => 'ro',
  isa     => Int,
  default => 5
);

=attr max_factor_failures

Wrong proofs after which a request is denied. Default 5.

=cut

has code => (
  is  => 'lazy',
  isa => InstanceOf['Airlock::Code']
);

sub _build_code { Airlock::Code->new }

=attr code

The L<Airlock::Code> that generates and normalizes codes.

=cut

has _factor_index => (
  is       => 'lazy',
  init_arg => undef
);

sub _build__factor_index {
  my ( $self ) = @_;
  return { map { $_->name => $_ } @{ $self->factors } };
}

sub BUILD {
  my ( $self ) = @_;
  for (qw( insert find update )) {
    croak __PACKAGE__.'->new store needs a '.$_.' sub' unless ref $self->store->{$_} eq 'CODE';
  }
  return;
}

sub row_fields {
  return qw(
    hash kind user_code client_id scope state created expires poll_interval last_poll
    subject amr acr auth_time approved origin_ip origin_ua factor_failures
  );
}

=method row_fields

    my @columns = Airlock->row_fields;

Every key of a row the store sees. All values are plain scalars or undef.

=cut

sub client {
  my ( $self, $id ) = @_;
  return unless defined $id && length $id;
  my $clients = $self->clients;
  my $client  = ref $clients eq 'CODE' ? $clients->($id) : $clients->{$id};
  return unless ref $client eq 'HASH';
  return { name => $id, %$client, id => $id };
}

=method client

    my $client = $airlock->client('my-cli');   # { id => ..., name => ..., scopes => [...] }

The registered client, or nothing.

=cut

sub factor {
  my ( $self, $name ) = @_;
  return $self->_factor_index->{$name} // croak __PACKAGE__.'->factor unknown factor '.$name;
}

=method factor

    my $upstream = $airlock->factor('upstream');

The factor of that name. Croaks when a policy names a factor that was never
configured.

=cut

sub open {
  my ( $self, %arg ) = @_;
  my $client = $self->client( $arg{client_id} ) or return $self->_fail('invalid_client');
  my @scopes = grep { length } split /\s+/, $arg{scope} // '';
  my %allowed = map { $_ => 1 } @{ $client->{scopes} || [] };
  for my $scope (@scopes) {
    return $self->_fail('invalid_scope') unless $scope =~ /\A[\x21\x23-\x5B\x5D-\x7E]+\z/;
    return $self->_fail('invalid_scope') if $client->{scopes} && !$allowed{$scope};
  }
  my $now         = $self->_time;
  my $device_code = $self->code->secret;
  my $user_code   = $self->_free_user_code($now);
  my $origin      = $arg{origin} || {};
  $self->store->{insert}->( {
    hash            => $self->code->hash($device_code),
    kind            => 'request',
    user_code       => $user_code,
    client_id       => $client->{id},
    scope           => join( ' ', @scopes ),
    state           => 'pending',
    created         => $now,
    expires         => $now + $self->expires_in,
    poll_interval   => $self->interval,
    last_poll       => undef,
    subject         => undef,
    amr             => undef,
    acr             => undef,
    auth_time       => undef,
    approved        => undef,
    origin_ip       => $self->_clip( $origin->{ip}, 64 ),
    origin_ua       => $self->_clip( $origin->{ua}, 255 ),
    factor_failures => 0
  } );
  $self->_emit( 'opened', client_id => $client->{id}, origin => $origin );
  my $shown = $self->code->display($user_code);
  my $uri   = $self->verification_uri;
  return $self->_ok( 'opened', data => {
    device_code               => $device_code,
    user_code                 => $shown,
    verification_uri          => $uri,
    verification_uri_complete => $uri.( $uri =~ /\?/ ? '&' : '?' ).'user_code='.$shown,
    expires_in                => $self->expires_in,
    interval                  => $self->interval
  } );
}

=method open

    my $result = $airlock->open( client_id => 'my-cli', scope => 'read admin', origin => { ip => $ip, ua => $ua } );

Starts a request. On success C<data> is the device authorization response of
RFC 8628 section 3.2. Fails with C<invalid_client> or C<invalid_scope>.

=cut

sub inspect {
  my ( $self, $input, %arg ) = @_;
  my $row = $self->_pending($input);
  return $self->_view($row) if $row;
  $self->_miss( $arg{subject} );
  return;
}

=method inspect

    my $view = $airlock->inspect( $typed_code, subject => $subject ) or return not_found();

What an approval page has to show: C<user_code>, C<client_id>, C<client_name>,
C<scopes>, C<origin> (C<ip>, C<ua>), C<created>, C<age> and C<expires_in>.
Returns nothing when the code is unknown, used up or expired. Looking never
approves anything.

=cut

sub requirements {
  my ( $self, $view, $subject ) = @_;
  return $self->policy->required( $view, $subject );
}

=method requirements

    my $names = $airlock->requirements( $view, $subject );   # ['totp']

The factor names this approval needs, so the page can ask for them.

=cut

sub approve {
  my ( $self, $input, %arg ) = @_;
  my $subject = $self->_subject( 'approve', $arg{subject} );
  my $row     = $self->_pending($input);
  return $self->_ok('approved') if !$row && $self->_approved_by( $input, $subject );
  return $self->_miss($subject) unless $row;
  my $now     = $self->_time;
  return $self->_fail('reauth_required') unless $self->policy->fresh( $subject, $now );
  my $proofs  = $arg{proofs} || {};
  my @factors = map { $self->factor($_) } @{ $self->policy->required( $self->_view($row), $subject ) };
  my @amr     = @{ $subject->{amr} || [] };
  my @missing;
  for my $factor (@factors) {
    return $self->_fail( 'factor_unavailable', missing => [ $factor->name ] )
      unless $factor->available_for($subject);
    if ( $factor->needs_proof ) {
      push @missing, $factor->name unless defined $proofs->{ $factor->name };
      next;
    }
    return $self->_fail( 'reauth_required', missing => [ $factor->name ] ) unless $factor->verify($subject);
    push @amr, $factor->amr;
  }
  return $self->_fail( 'factor_required', missing => \@missing ) if @missing;
  for my $factor ( grep { $_->needs_proof } @factors ) {
    return $self->_factor_failed( $row, $subject, $factor )
      unless $factor->verify( $subject, $proofs->{ $factor->name } );
    push @amr, $factor->amr;
  }
  my %seen;
  my $approved = $self->store->{update}->( $row->{hash}, 'pending', {
    state     => 'approved',
    subject   => $subject->{id},
    amr       => join( ' ', grep { !$seen{$_}++ } @amr ),
    acr       => $subject->{acr},
    auth_time => $subject->{auth_time} // $now,
    approved  => $now
  } );
  return $self->_miss($subject) unless $approved;
  $self->_emit( 'approved', client_id => $row->{client_id}, subject => $subject->{id} );
  return $self->_ok('approved');
}

=method approve

    my $result = $airlock->approve( $typed_code, subject => $subject, proofs => { totp => '123456' } );

Approves a pending request on behalf of the subject, a hash with at least
C<id> and optionally C<amr>, C<acr> and C<auth_time>. Approving a second time
with the same subject, as a double click does, succeeds again. Fails with
C<unknown_code>, C<reauth_required>, C<factor_unavailable>, C<factor_required>
(C<missing> names what to ask for), C<factor_failed> or C<too_many_failures>.
Croaks without a subject id.

=cut

sub deny {
  my ( $self, $input, %arg ) = @_;
  my $subject = $self->_subject( 'deny', $arg{subject} );
  my $row     = $self->_pending($input) or return $self->_miss($subject);
  my $denied  = $self->store->{update}->( $row->{hash}, 'pending', {
    state     => 'denied',
    user_code => undef,
    subject   => $subject->{id}
  } );
  return $self->_miss($subject) unless $denied;
  $self->_emit( 'denied', client_id => $row->{client_id}, subject => $subject->{id} );
  return $self->_ok('denied');
}

=method deny

    my $result = $airlock->deny( $typed_code, subject => $subject );

Refuses a pending request. The client's next poll gets C<access_denied>.

=cut

sub redeem {
  my ( $self, %arg ) = @_;
  for (qw( device_code client_id )) {
    return $self->_fail('invalid_request') unless defined $arg{$_} && length $arg{$_};
  }
  my $store = $self->store;
  my $hash  = $self->code->hash( $arg{device_code} );
  my $row   = $store->{find}->( 'hash', $hash );
  return $self->_fail('invalid_grant')
    unless $row && $row->{kind} eq 'request' && $row->{client_id} eq $arg{client_id};
  my $now   = $self->_time;
  my $state = $row->{state};
  if ( ( $state eq 'pending' || $state eq 'approved' ) && $row->{expires} <= $now ) {
    $store->{update}->( $hash, $state, { state => 'expired', user_code => undef } );
    $state = 'expired';
  }
  return $self->_fail('expired_token') if $state eq 'expired';
  return $self->_fail('access_denied') if $state eq 'denied';
  return $self->_fail('invalid_grant') unless $state eq 'pending' || $state eq 'approved';
  if ( defined $row->{last_poll} && $now - $row->{last_poll} < $row->{poll_interval} ) {
    $store->{update}->( $hash, $state, { poll_interval => $row->{poll_interval} + 5, last_poll => $now } );
    return $self->_fail('slow_down');
  }
  if ( $state eq 'pending' ) {
    $store->{update}->( $hash, 'pending', { last_poll => $now } );
    return $self->_fail('authorization_pending');
  }
  return $self->_fail('invalid_grant')
    unless $store->{update}->( $hash, 'approved', { state => 'redeemed', user_code => undef, last_poll => $now } );
  my $grant = {
    subject   => $row->{subject},
    client_id => $row->{client_id},
    scope     => $row->{scope},
    scopes    => [ split / /, $row->{scope} ],
    amr       => [ split / /, $row->{amr} // '' ],
    acr       => $row->{acr},
    auth_time => $row->{auth_time}
  };
  my $token = $self->has_issuer ? $self->issuer->($grant) : $self->_issue_opaque( $grant, $now );
  croak __PACKAGE__.'->redeem issuer must return a hash' unless ref $token eq 'HASH';
  $self->_emit( 'redeemed', client_id => $row->{client_id}, subject => $row->{subject} );
  return $self->_ok( 'granted', data => $token );
}

=method redeem

    my $result = $airlock->redeem( device_code => $device_code, client_id => 'my-cli' );

One poll of the client. Succeeds exactly once per approved request, with the
token response in C<data>. Otherwise fails with C<authorization_pending>,
C<slow_down>, C<access_denied>, C<expired_token>, C<invalid_grant> or
C<invalid_request>. An exception from the issuer propagates; the request is
used up by then.

=cut

sub verify_token {
  my ( $self, $token ) = @_;
  return unless defined $token && length $token;
  my $row = $self->store->{find}->( 'hash', $self->code->hash($token) ) or return;
  return unless $row->{kind} eq 'token' && $row->{state} eq 'active';
  return unless $row->{expires} > $self->_time;
  return {
    subject   => $row->{subject},
    client_id => $row->{client_id},
    scope     => $row->{scope},
    scopes    => [ split / /, $row->{scope} ],
    amr       => [ split / /, $row->{amr} // '' ],
    acr       => $row->{acr},
    auth_time => $row->{auth_time},
    expires   => $row->{expires}
  };
}

=method verify_token

    my $grant = $airlock->verify_token($bearer) or return unauthorized();

For opaque tokens: the grant behind a token that is known, active and not
expired, or nothing.

=cut

sub revoke_token {
  my ( $self, $token ) = @_;
  return 0 unless defined $token && length $token;
  return $self->store->{update}->( $self->code->hash($token), 'active', { state => 'revoked' } ) ? 1 : 0;
}

=method revoke_token

    $airlock->revoke_token($bearer);

Ends an opaque token. Returns 1 when there was an active one.

=cut

sub purge {
  my ( $self ) = @_;
  my $purge = $self->store->{purge} or return 0;
  return $purge->( $self->_time );
}

=method purge

    my $removed = $airlock->purge;

Removes expired requests and tokens through the store's C<purge> sub. Call it
from a timer or a cron job.

=cut

sub _time { $_[0]->now->() }

sub _ok {
  my ( $self, $status, %arg ) = @_;
  return Airlock::Result->new( ok => 1, status => $status, %arg );
}

sub _fail {
  my ( $self, $status, %arg ) = @_;
  return Airlock::Result->new( ok => 0, status => $status, %arg );
}

sub _miss {
  my ( $self, $subject ) = @_;
  $self->_emit( 'code_miss', subject => $subject ? $subject->{id} : undef );
  return $self->_fail('unknown_code');
}

sub _emit {
  my ( $self, $event, %data ) = @_;
  return unless $self->has_on_event;
  $self->on_event->( { event => $event, time => $self->_time, %data } );
  return;
}

sub _clip {
  my ( $self, $text, $max ) = @_;
  return defined $text ? substr( $text, 0, $max ) : undef;
}

sub _subject {
  my ( $self, $method, $subject ) = @_;
  croak __PACKAGE__.'->'.$method.' needs a subject with an id'
    unless ref $subject eq 'HASH' && defined $subject->{id} && length $subject->{id};
  croak __PACKAGE__.'->'.$method.' subject id is longer than 255 characters' if length $subject->{id} > 255;
  return $subject;
}

sub _free_user_code {
  my ( $self, $now ) = @_;
  for ( 1 .. 10 ) {
    my $code = $self->code->user_code;
    my $row  = $self->store->{find}->( 'user_code', $code ) or return $code;
    next if $row->{expires} > $now;
    $self->store->{update}->( $row->{hash}, $row->{state}, { state => 'expired', user_code => undef } );
    return $code;
  }
  croak __PACKAGE__.'->open found no free user code';
}

sub _pending {
  my ( $self, $input ) = @_;
  my $code = $self->code->normalize($input) or return;
  my $row  = $self->store->{find}->( 'user_code', $code ) or return;
  return unless $row->{kind} eq 'request' && $row->{state} eq 'pending';
  return $row if $row->{expires} > $self->_time;
  $self->store->{update}->( $row->{hash}, 'pending', { state => 'expired', user_code => undef } );
  return;
}

sub _approved_by {
  my ( $self, $input, $subject ) = @_;
  my $code = $self->code->normalize($input) or return 0;
  my $row  = $self->store->{find}->( 'user_code', $code ) or return 0;
  return 0 unless $row->{kind} eq 'request' && $row->{state} eq 'approved';
  return 0 unless $row->{expires} > $self->_time;
  return $row->{subject} eq $subject->{id} ? 1 : 0;
}

sub _view {
  my ( $self, $row ) = @_;
  my $client = $self->client( $row->{client_id} ) || { name => $row->{client_id} };
  my $now    = $self->_time;
  return {
    user_code   => $self->code->display( $row->{user_code} ),
    client_id   => $row->{client_id},
    client_name => $client->{name},
    scopes      => [ split / /, $row->{scope} ],
    origin      => { ip => $row->{origin_ip}, ua => $row->{origin_ua} },
    created     => $row->{created},
    age         => $now - $row->{created},
    expires_in  => $row->{expires} - $now
  };
}

sub _factor_failed {
  my ( $self, $row, $subject, $factor ) = @_;
  my $failures = ( $row->{factor_failures} || 0 ) + 1;
  my $final    = $failures >= $self->max_factor_failures;
  $self->store->{update}->( $row->{hash}, 'pending', {
    factor_failures => $failures,
    $final ? ( state => 'denied', user_code => undef ) : ()
  } );
  $self->_emit( 'factor_failed', client_id => $row->{client_id}, subject => $subject->{id}, factor => $factor->name );
  return $self->_fail( $final ? 'too_many_failures' : 'factor_failed', missing => [ $factor->name ] );
}

sub _issue_opaque {
  my ( $self, $grant, $now ) = @_;
  my $token = $self->code->secret;
  $self->store->{insert}->( {
    hash            => $self->code->hash($token),
    kind            => 'token',
    user_code       => undef,
    client_id       => $grant->{client_id},
    scope           => $grant->{scope},
    state           => 'active',
    created         => $now,
    expires         => $now + $self->token_ttl,
    poll_interval   => undef,
    last_poll       => undef,
    subject         => $grant->{subject},
    amr             => join( ' ', @{ $grant->{amr} } ),
    acr             => $grant->{acr},
    auth_time       => $grant->{auth_time},
    approved        => undef,
    origin_ip       => undef,
    origin_ua       => undef,
    factor_failures => 0
  } );
  return {
    access_token => $token,
    token_type   => 'Bearer',
    expires_in   => $self->token_ttl,
    scope        => $grant->{scope}
  };
}

1;
```

- [ ] **Step 6: Tests laufen lassen**

Run: `prove -lr t/50-core.t t/51-core-factors.t t/52-core-token.t`
Expected: PASS (19, 8 und 5 Subtests), ohne Warnungen auf STDERR.

- [ ] **Step 7: Modul in den Load-Test**

`  Airlock::Result` in die Liste in `t/00-load.t` (`Airlock` steht schon drin). Run: `prove -lr t` — Expected: PASS.

- [ ] **Step 8: Übergabe**

Commit-fertig lassen, Karte nach `review`. Betreff: `Implement the Airlock core`; `Changes`: `- Airlock: open, inspect, requirements, approve, deny, redeem; opaque tokens with verify_token and revoke_token; events`.

---

### Task 6: Maschinen-Endpunkte: `respond`, `to_app`, `Airlock::HTTPMessage`

Spec: Abschnitte 3 und 5. Abweichung von Revision 2 der Spec, in Revision 3 nachgezogen: `handle` ist keine Methode von `Airlock`, sondern lebt in `Airlock::HTTPMessage`, weil die Hausregel verzögertes `require` verbietet und `Airlock` selbst nicht von `HTTP::Message` abhängen soll.

**Files:**
- Create: `lib/Airlock/Role/Endpoints.pm`, `lib/Airlock/HTTPMessage.pm`
- Modify: `lib/Airlock.pm` (Rolle einbinden, Synopsis ergänzen)
- Test: `t/60-endpoints.t`, `t/61-httpmessage.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Consumes: `Airlock->open`, `Airlock->redeem`, `Airlock::Result->oauth` (Aufgabe 5); Fixture `AirlockTest` (Aufgabe 5).
- Produces: auf `Airlock`: `->respond( $method, $path, \%params, \%origin )` → `[ $status, \%headers, \%json ]`; `->parse_form($body)` → HashRef oder leere Liste (im Listenkontext immer mit `scalar` aufrufen); `->encode_body(\%json)` → JSON-Bytes; `->to_app` → PSGI-Coderef; `->max_body` (16384); `->device_grant_type`. `Airlock::HTTPMessage->new( airlock => $airlock )->handle( $http_request, ip => $addr )` → `HTTP::Response`.

- [ ] **Step 1: Die Tests schreiben**

`t/60-endpoints.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use JSON::MaybeXS;
use AirlockTest;

my $grant = 'urn:ietf:params:oauth:grant-type:device_code';

sub psgi {
  my ( $app, %arg ) = @_;
  my $body = $arg{body} // '';
  CORE::open( my $input, '<', \$body ) or die $!;
  my $response = $app->( {
    REQUEST_METHOD    => $arg{method} // 'POST',
    PATH_INFO         => $arg{path},
    CONTENT_TYPE      => exists $arg{type} ? $arg{type} : 'application/x-www-form-urlencoded',
    CONTENT_LENGTH    => exists $arg{length} ? $arg{length} : length $body,
    REMOTE_ADDR       => '192.0.2.9',
    HTTP_USER_AGENT   => 'test-agent/1.0',
    'psgi.input'      => $input
  } );
  my %header = @{ $response->[1] };
  return ( $response->[0], \%header, decode_json( join '', @{ $response->[2] } ) );
}

subtest 'respond: routes' => sub {
  my $t = AirlockTest->new;
  my ( $status, $headers, $json ) = @{ $t->airlock->respond( 'POST', '/device', { client_id => 'cli', scope => 'read' }, { ip => '192.0.2.9' } ) };
  is( $status, 200, 'device: 200' );
  is( $headers->{'Content-Type'}, 'application/json', 'content type' );
  is( $headers->{'Cache-Control'}, 'no-store', 'no-store' );
  ok( $json->{device_code} && $json->{user_code}, 'device authorization response' );

  for my $path ( '/airlock/device', 'device', '/device/', '/a/b/c/device' ) {
    is( $t->airlock->respond( 'POST', $path, { client_id => 'cli' }, {} )->[0], 200, 'mounted at '.$path );
  }
  is_deeply( [ @{ $t->airlock->respond( 'POST', '/nope', {}, {} ) }[ 0, 2 ] ], [ 404, { error => 'not_found' } ], 'unknown route' );
  is( $t->airlock->respond( 'POST', '/devices', {}, {} )->[0], 404, 'a longer segment is not the route' );
  is( $t->airlock->respond( 'POST', '', {}, {} )->[0],    404, 'empty path' );
  is( $t->airlock->respond( 'POST', undef, {}, {} )->[0], 404, 'undef path' );

  my $get = $t->airlock->respond( 'GET', '/device', { client_id => 'cli' }, {} );
  is( $get->[0], 405, 'GET is refused' );
  is( $get->[1]{Allow}, 'POST', 'with an Allow header' );
  is( $t->airlock->respond( 'post', '/device', { client_id => 'cli' }, {} )->[0], 200, 'method is case-insensitive' );
  is_deeply( [ @{ $t->airlock->respond( 'POST', '/device', undef, {} ) }[ 0, 2 ] ], [ 400, { error => 'invalid_request' } ], 'unparseable parameters' );
};

subtest 'respond: token' => sub {
  my $t     = AirlockTest->new;
  my $start = $t->airlock->respond( 'POST', '/device', { client_id => 'cli' }, {} )->[2];
  my $poll  = sub { [ @{ $t->airlock->respond( 'POST', '/token', { grant_type => $grant, client_id => 'cli', device_code => $start->{device_code}, @_ }, {} ) }[ 0, 2 ] ] };

  is_deeply( $poll->(), [ 400, { error => 'authorization_pending' } ], 'pending' );
  is_deeply( $poll->( grant_type => 'password' ), [ 400, { error => 'unsupported_grant_type' } ], 'another grant type' );
  is_deeply( $poll->( grant_type => undef ),      [ 400, { error => 'unsupported_grant_type' } ], 'no grant type' );
  is_deeply( $poll->( device_code => undef ),     [ 400, { error => 'invalid_request' } ],        'no device code' );
  is_deeply( $poll->( client_id => 'open' ),      [ 400, { error => 'invalid_grant' } ],          'another client' );

  $t->airlock->approve( $start->{user_code}, subject => { id => 'alice' } );
  $t->advance(5);
  my $granted = $poll->();
  is( $granted->[0], 200, 'granted' );
  is( $granted->[1]{token_type}, 'Bearer', 'token response' );
  ok( $t->airlock->verify_token( $granted->[1]{access_token} ), 'the token verifies' );
};

subtest 'parse_form' => sub {
  my $airlock = AirlockTest->new->airlock;
  is_deeply( $airlock->parse_form('a=1&b=two'), { a => 1, b => 'two' }, 'pairs' );
  is_deeply( $airlock->parse_form('scope=read+write&x=%41%2fb%3D'), { scope => 'read write', x => 'A/b=' }, 'plus and percent' );
  is_deeply( $airlock->parse_form('a=1=2'), { a => '1=2' }, 'only the first = splits' );
  is_deeply( $airlock->parse_form('flag&b='), { flag => '', b => '' }, 'no value and empty value' );
  is_deeply( $airlock->parse_form(''),    {}, 'empty' );
  is_deeply( $airlock->parse_form(undef), {}, 'undef' );
  is_deeply( $airlock->parse_form('&&a=1&'), { a => 1 }, 'empty pairs are skipped' );
  is( $airlock->parse_form('a=1&a=2'), undef, 'a repeated parameter is refused' );
  is_deeply( $airlock->parse_form('a=%zz'), { a => '%zz' }, 'a broken escape stays as it is' );
};

subtest 'to_app' => sub {
  my $t   = AirlockTest->new;
  my $app = $t->airlock->to_app;

  my ( $status, $headers, $json ) = psgi( $app, path => '/device', body => 'client_id=cli&scope=read+write' );
  is( $status, 200, 'device: 200' );
  is( $headers->{'Content-Type'}, 'application/json', 'content type' );
  is( $headers->{'Cache-Control'}, 'no-store', 'no-store' );
  my $row = $t->row( $json->{device_code} );
  is( $row->{scope}, 'read write', 'the form body was decoded' );
  is( $row->{origin_ip}, '192.0.2.9', 'origin ip from REMOTE_ADDR' );
  is( $row->{origin_ua}, 'test-agent/1.0', 'origin ua from the header' );

  my $token_body = 'grant_type='.$grant =~ s/:/%3A/gr.'&client_id=cli&device_code='.$json->{device_code};
  is_deeply( [ ( psgi( $app, path => '/token', body => $token_body ) )[ 0, 2 ] ], [ 400, { error => 'authorization_pending' } ], 'token: pending' );

  is( ( psgi( $app, path => '/device', method => 'GET' ) )[0], 405, 'GET' );
  is( ( psgi( $app, path => '/other', body => 'client_id=cli' ) )[0], 404, 'unknown route' );
  is_deeply( [ ( psgi( $app, path => '/device', body => 'client_id=cli&client_id=open' ) )[ 0, 2 ] ], [ 400, { error => 'invalid_request' } ], 'repeated parameter' );
  is_deeply( [ ( psgi( $app, path => '/device', body => '{"client_id":"cli"}', type => 'application/json' ) )[ 0, 2 ] ], [ 400, { error => 'invalid_client' } ], 'a JSON body is not read' );
  is( ( psgi( $app, path => '/device', body => 'client_id=cli', type => 'application/x-www-form-urlencoded; charset=UTF-8' ) )[0], 200, 'content type with a charset' );
  is( ( psgi( $app, path => '/device', body => 'client_id=cli', type => undef ) )[0], 400, 'no content type' );
  is( ( psgi( $app, path => '/device', body => 'client_id=cli&pad='.( 'x' x 20000 ) ) )[0], 413, 'a body over the limit is refused unread' );
  is( ( psgi( $app, path => '/device', body => 'client_id=cli', length => 100 ) )[0], 200, 'a body shorter than its Content-Length does not hang' );
  is( ( psgi( $app, path => '/device', body => '', length => 0 ) )[0], 400, 'an empty body' );
};

done_testing;
```

`t/61-httpmessage.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use HTTP::Request;
use JSON::MaybeXS;
use Airlock::HTTPMessage;
use AirlockTest;

my $t    = AirlockTest->new;
my $http = Airlock::HTTPMessage->new( airlock => $t->airlock );

sub request {
  my ( $method, $uri, $body, @header ) = @_;
  return HTTP::Request->new( $method, $uri, [ 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'lwp-test/1.0', @header ], $body );
}

subtest 'device' => sub {
  my $response = $http->handle( request( POST => 'https://example.org/airlock/device', 'client_id=cli&scope=read' ), ip => '192.0.2.4' );
  isa_ok( $response, 'HTTP::Response' );
  is( $response->code, 200, 'status' );
  is( $response->message, 'OK', 'status message' );
  is( $response->header('Content-Type'), 'application/json', 'content type' );
  is( $response->header('Cache-Control'), 'no-store', 'no-store' );
  my $json = decode_json( $response->content );
  my $row  = $t->row( $json->{device_code} );
  is( $row->{origin_ip}, '192.0.2.4', 'origin ip from the caller' );
  is( $row->{origin_ua}, 'lwp-test/1.0', 'origin ua from the request' );

  my $poll = $http->handle( request( POST => '/airlock/token', 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Adevice_code&client_id=cli&device_code='.$json->{device_code} ) );
  is( $poll->code, 400, 'token: status' );
  is( $poll->message, 'Bad Request', 'token: status message' );
  is_deeply( decode_json( $poll->content ), { error => 'authorization_pending' }, 'token: body' );
};

subtest 'refusals' => sub {
  is( $http->handle( request( GET => '/airlock/device' ) )->code, 405, 'GET' );
  is( $http->handle( request( GET => '/airlock/device' ) )->header('Allow'), 'POST', 'Allow header' );
  is( $http->handle( request( POST => '/airlock/nope', 'client_id=cli' ) )->code, 404, 'unknown route' );
  is( $http->handle( HTTP::Request->new( POST => '/airlock/device', [ 'Content-Type' => 'application/json' ], '{"client_id":"cli"}' ) )->code, 400, 'a JSON body is not read' );
  is( $http->handle( HTTP::Request->new( POST => '/airlock/device' ) )->code, 400, 'no body, no headers' );
  is( $http->handle( request( POST => '/airlock/device', 'client_id=cli&pad='.( 'x' x 20000 ) ) )->code, 413, 'a body over the limit' );
};

ok( !eval { Airlock::HTTPMessage->new; 1 }, 'airlock is required' );

done_testing;
```

- [ ] **Step 2: Tests laufen lassen, sie müssen scheitern**

Run: `prove -lr t/60-endpoints.t t/61-httpmessage.t`
Expected: FAIL mit `Can't locate object method "respond" via package "Airlock"` und `Can't locate Airlock/HTTPMessage.pm in @INC`.

- [ ] **Step 3: `lib/Airlock/Role/Endpoints.pm` schreiben**

`lib/Airlock/Role/Endpoints.pm`:

```perl
package Airlock::Role::Endpoints;

# ABSTRACT: The two machine endpoints of Airlock, framework-neutral and as PSGI

use JSON::MaybeXS;
use Moo::Role;

our $VERSION = '0.001';

=synopsis

    # PSGI
    builder { mount '/airlock' => $airlock->to_app; mount '/' => $app };

    # anything else
    my ( $status, $headers, $json ) = @{ $airlock->respond( 'POST', '/device', \%params, { ip => $ip, ua => $ua } ) };

=description

The device authorization endpoint and the token endpoint of RFC 8628, answered
in one place: L</respond>. L</to_app> is a thin PSGI skin over it that needs
neither Plack nor any other framework. L<Airlock::HTTPMessage> is the same for
L<HTTP::Request> and L<HTTP::Response>.

Routes are matched on the last path segment, so the endpoints can be mounted
anywhere: C<POST .../device> and C<POST .../token>.

=cut

requires qw( open redeem );

sub device_grant_type { 'urn:ietf:params:oauth:grant-type:device_code' }

sub max_body { 16384 }

=method max_body

Largest request body, in bytes, the endpoints read. 16384.

=cut

has _json => (
  is       => 'lazy',
  init_arg => undef
);

sub _build__json { JSON::MaybeXS->new( utf8 => 1, canonical => 1, convert_blessed => 1 ) }

sub respond {
  my ( $self, $method, $path, $param, $origin ) = @_;
  my ( $route ) = ( $path // '' ) =~ m{([^/]*)/?\z};
  return $self->_reply( 404, { error => 'not_found' } )
    unless $route eq 'device' || $route eq 'token';
  return $self->_reply( 405, { error => 'invalid_request' }, Allow => 'POST' )
    unless uc( $method // '' ) eq 'POST';
  return $self->_reply( 400, { error => 'invalid_request' } ) unless ref $param eq 'HASH';
  return $self->_reply( 400, { error => 'unsupported_grant_type' } )
    if $route eq 'token' && ( $param->{grant_type} // '' ) ne $self->device_grant_type;
  my $result = $route eq 'device'
    ? $self->open( client_id => $param->{client_id}, scope => $param->{scope}, origin => $origin )
    : $self->redeem( device_code => $param->{device_code}, client_id => $param->{client_id} );
  return $self->_reply( @{ $result->oauth } );
}

=method respond

    my ( $status, $headers, $json ) = @{ $airlock->respond( $method, $path, \%params, \%origin ) };

Answers one request. C<%params> are the decoded form parameters, or anything
that is not a hash when the body could not be parsed. Returns the HTTP status,
a hash of headers and the response body as a data structure.

=cut

sub encode_body {
  my ( $self, $json ) = @_;
  return $self->_json->encode($json);
}

=method encode_body

    my $bytes = $airlock->encode_body($json);

The response body as JSON bytes.

=cut

sub parse_form {
  my ( $self, $body ) = @_;
  my %param;
  for my $pair ( split /&/, $body // '' ) {
    next unless length $pair;
    my ( $key, $value ) = map { $self->_unescape($_) } split /=/, $pair, 2;
    return if exists $param{$key};
    $param{$key} = $value // '';
  }
  return \%param;
}

=method parse_form

    my $params = $airlock->parse_form($body);

Decodes an C<application/x-www-form-urlencoded> body. Returns nothing when a
parameter appears twice, which RFC 6749 forbids.

=cut

sub to_app {
  my ( $self ) = @_;
  return sub {
    my ( $env ) = @_;
    my $length = $env->{CONTENT_LENGTH} || 0;
    return $self->_psgi( $self->_reply( 413, { error => 'invalid_request' } ) ) if $length > $self->max_body;
    my $body = '';
    if ( $length && ( $env->{CONTENT_TYPE} // '' ) =~ m{\Aapplication/x-www-form-urlencoded\b}i ) {
      while ( length $body < $length ) {
        my $read = $env->{'psgi.input'}->read( my $chunk, $length - length $body );
        last unless $read;
        $body .= $chunk;
      }
    }
    return $self->_psgi( $self->respond(
      $env->{REQUEST_METHOD}, $env->{PATH_INFO}, scalar $self->parse_form($body),
      { ip => $env->{REMOTE_ADDR}, ua => $env->{HTTP_USER_AGENT} }
    ) );
  };
}

=method to_app

    my $app = $airlock->to_app;

The two endpoints as a PSGI application.

=cut

sub _reply {
  my ( $self, $status, $json, %header ) = @_;
  return [
    $status,
    { 'Content-Type' => 'application/json', 'Cache-Control' => 'no-store', 'Pragma' => 'no-cache', %header },
    $json
  ];
}

sub _psgi {
  my ( $self, $reply ) = @_;
  my ( $status, $headers, $json ) = @$reply;
  return [ $status, [ map { $_ => $headers->{$_} } sort keys %$headers ], [ $self->encode_body($json) ] ];
}

sub _unescape {
  my ( $self, $text ) = @_;
  return unless defined $text;
  $text =~ tr/+/ /;
  $text =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
  return $text;
}

1;
```

- [ ] **Step 4: Die Rolle in `lib/Airlock.pm` einbinden**

Direkt unter `use Moo;` einfügen:

```perl
with 'Airlock::Role::Endpoints';
```

Und in der Synopsis nach dem schließenden `);` des Konstruktors einfügen:

```perl

    # machine side: mount the two JSON endpoints
    my $app = $airlock->to_app;
```

- [ ] **Step 5: `lib/Airlock/HTTPMessage.pm` schreiben**

`lib/Airlock/HTTPMessage.pm`:

```perl
package Airlock::HTTPMessage;

# ABSTRACT: Airlock's machine endpoints for HTTP::Request and HTTP::Response

use Moo;
use HTTP::Response;
use HTTP::Status qw( status_message );
use Types::Standard qw( InstanceOf );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $http     = Airlock::HTTPMessage->new( airlock => $airlock );
    my $response = $http->handle( $request, ip => $remote_address );

=description

For a host application that is neither PSGI nor anything Airlock knows about,
but can produce an L<HTTP::Request> and send an L<HTTP::Response>. This is a
separate class so that L<Airlock> itself does not depend on L<HTTP::Message>.

=cut

has airlock => (
  is       => 'ro',
  isa      => InstanceOf['Airlock'],
  required => 1
);

=attr airlock

Required. The L<Airlock> to answer for.

=cut

sub handle {
  my ( $self, $request, %origin ) = @_;
  my $airlock = $self->airlock;
  my $content = $request->content // '';
  my $form    = ( $request->header('Content-Type') // '' ) =~ m{\Aapplication/x-www-form-urlencoded\b}i;
  my ( $status, $headers, $json ) = @{
    length $content > $airlock->max_body
      ? [ 413, { 'Content-Type' => 'application/json' }, { error => 'invalid_request' } ]
      : $airlock->respond(
        $request->method, $request->uri->path, scalar $airlock->parse_form( $form ? $content : '' ),
        { ua => scalar $request->header('User-Agent'), %origin }
      )
  };
  return HTTP::Response->new(
    $status, status_message($status), [ map { $_ => $headers->{$_} } sort keys %$headers ],
    $airlock->encode_body($json)
  );
}

=method handle

    my $response = $http->handle( $request, ip => $remote_address );

Answers an L<HTTP::Request> for C<POST .../device> or C<POST .../token> with an
L<HTTP::Response>. Pass the remote address, which a request object does not
carry.

=cut

1;
```

- [ ] **Step 6: Tests laufen lassen**

Run: `prove -lr t/60-endpoints.t t/61-httpmessage.t`
Expected: PASS (4 Subtests und 3 Tests), ohne Warnungen auf STDERR. Eine Warnung `Odd number of elements` heißt, dass `parse_form` irgendwo ohne `scalar` in einer Argumentliste steht.

- [ ] **Step 7: Module in den Load-Test**

`  Airlock::HTTPMessage` und `  Airlock::Role::Endpoints` in die Liste in `t/00-load.t`. Run: `prove -lr t` — Expected: PASS.

- [ ] **Step 8: Übergabe**

Commit-fertig lassen, Karte nach `review`. Betreff: `Add machine endpoints: respond, to_app, Airlock::HTTPMessage`; `Changes`: `- Device and token endpoint as PSGI (to_app), for HTTP::Request (Airlock::HTTPMessage) and framework-neutral (respond)`.

---

### Task 7: `Airlock::Client`

Spec: Abschnitt 6 (Client).

**Files:**
- Create: `lib/Airlock/Client.pm`
- Test: `t/70-client.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Consumes: `Airlock::QR->new( text =>, quiet => )->terminal(%opt)` (Aufgabe 1); `Airlock->to_app` (Aufgabe 6) und `AirlockTest` (Aufgabe 5) nur im Test.
- Produces: `Airlock::Client->new( client_id =>, scope =>, issuer => | device_endpoint => + token_endpoint =>, ua => $http_tiny, on_prompt => sub ($start), sleep => sub ($seconds), now => sub )`; `->start` → HashRef der Device-Antwort; `->poll($start)` → HashRef der Token-Antwort; `->login`; `->prompt_text( $start, %qr_terminal_opts )`.

- [ ] **Step 1: Den Test schreiben**

Der Test ersetzt `HTTP::Tiny` durch eine Unterklasse, die eine PSGI-App im selben Prozess aufruft; so teilen Test und Server Uhr und Speicher. Ein Subtest geht zusätzlich über einen echten Socket. Dort baut der Server-Prozess sein eigenes `Airlock`, weil der eingebaute Speicher einen Fork verweigert.

`t/70-client.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib';

use HTTP::Server::PSGI;
use Test::TCP;
use JSON::MaybeXS;
use Airlock::Client;
use AirlockTest;

# A stand-in for HTTP::Tiny that talks to a PSGI app in-process: no socket, no
# second process, so the test and the server share one clock and one store.
{
  package LocalUA;
  use Moo;
  extends 'HTTP::Tiny';
  has app  => ( is => 'ro', required => 1 );
  has seen => ( is => 'ro', default => sub { [] } );

  sub request {
    my ( $self, $method, $url, $args ) = @_;
    my $body = $args->{content} // '';
    my ( $path ) = $url =~ m{\Ahttps?://[^/]+(/[^?]*)};
    push @{ $self->seen }, { method => $method, url => $url, body => $body, headers => $args->{headers} };
    CORE::open( my $input, '<', \$body ) or die $!;
    my $psgi = $self->app->( {
      REQUEST_METHOD  => $method,
      PATH_INFO       => $path,
      CONTENT_TYPE    => $args->{headers}{'content-type'},
      CONTENT_LENGTH  => length $body,
      REMOTE_ADDR     => '127.0.0.1',
      HTTP_USER_AGENT => 'local-ua',
      'psgi.input'    => $input
    } );
    return {
      success => $psgi->[0] < 400 ? 1 : '',
      status  => $psgi->[0],
      reason  => 'local',
      content => join( '', @{ $psgi->[2] } ),
      headers => { @{ $psgi->[1] } }
    };
  }
}

sub fixture {
  my ( %arg ) = @_;
  my $t   = AirlockTest->new;
  my $app = delete $arg{app} || $t->airlock->to_app;
  my @slept;
  my $after_sleep = delete $arg{after_sleep} || sub { };
  my $ua     = LocalUA->new( app => $app );
  my $client = Airlock::Client->new(
    client_id       => 'cli',
    scope           => 'read write',
    device_endpoint => 'http://airlock.test/airlock/device',
    token_endpoint  => 'http://airlock.test/airlock/token',
    ua              => $ua,
    now             => sub { $t->clock },
    sleep           => sub { push @slept, $_[0]; $t->advance( $_[0] ); $after_sleep->( $t, scalar @slept ) },
    on_prompt       => sub { },
    %arg
  );
  return ( $t, $client, \@slept, $ua );
}

subtest 'start' => sub {
  my ( $t, $client, undef, $ua ) = fixture();
  my $start = $client->start;
  like( $start->{device_code}, qr/\A[0-9a-f]{64}\z/, 'device_code' );
  like( $start->{user_code}, qr/\A\w{4}-\w{4}\z/, 'user_code' );
  is( $t->row( $start->{device_code} )->{scope}, 'read write', 'the scope arrived' );
  is( $ua->seen->[0]{headers}{accept}, 'application/json', 'asks for JSON' );
  like( $ua->seen->[0]{headers}{'content-type'}, qr{\Aapplication/x-www-form-urlencoded}, 'sends a form' );

  my ( undef, $unknown ) = fixture( client_id => 'nope' );
  ok( !eval { $unknown->start; 1 }, 'an unknown client croaks' );
  like( $@, qr/start failed: invalid_client/, 'with the server error' );
};

subtest 'login: approved while polling' => sub {
  my ( $t, $client, $slept ) = fixture(
    after_sleep => sub {
      my ( $t, $polls ) = @_;
      return unless $polls == 2;
      my ( $row ) = grep { ( $_->{state} // '' ) eq 'pending' } values %{ $t->memory->_rows };
      $t->airlock->approve( $row->{user_code}, subject => { id => 'alice' } );
    }
  );
  my $token = $client->login;
  is( $token->{token_type}, 'Bearer', 'token response' );
  is( $t->airlock->verify_token( $token->{access_token} )->{subject}, 'alice', 'the token belongs to who approved' );
  is_deeply( $slept, [ 5, 5 ], 'waited the server interval before every poll, never polled without waiting' );
};

subtest 'poll: slow_down adds five seconds' => sub {
  my $calls = 0;
  my @reply = ( 'slow_down', 'authorization_pending', 'slow_down' );
  my $app   = sub {
    my $error = $reply[ $calls++ ];
    return [ 400, [ 'Content-Type' => 'application/json' ], [ encode_json( { error => $error } ) ] ] if $error;
    return [ 200, [ 'Content-Type' => 'application/json' ], [ encode_json( { access_token => 'tok', token_type => 'Bearer' } ) ] ];
  };
  my ( undef, $client, $slept ) = fixture( app => $app );
  my $token = $client->poll( { device_code => 'd', interval => 2, expires_in => 600 } );
  is( $token->{access_token}, 'tok', 'token' );
  is_deeply( $slept, [ 2, 7, 7, 12 ], 'the interval grows by five on each slow_down and stays grown' );
};

subtest 'poll: errors' => sub {
  for my $error (qw( access_denied expired_token invalid_grant )) {
    my $app = sub { [ 400, [], [ encode_json( { error => $error } ) ] ] };
    my ( undef, $client ) = fixture( app => $app );
    ok( !eval { $client->poll( { device_code => 'd', interval => 1, expires_in => 60 } ); 1 }, $error.' croaks' );
    like( $@, qr/poll failed: $error/, 'with the error' );
  }
  my ( undef, $described ) = fixture( app => sub { [ 400, [], [ encode_json( { error => 'access_denied', error_description => 'no thanks' } ) ] ] } );
  eval { $described->poll( { device_code => 'd', interval => 1, expires_in => 60 } ) };
  like( $@, qr/access_denied \(no thanks\)/, 'error_description is included' );

  my ( undef, $html ) = fixture( app => sub { [ 502, [], ['<html>Bad Gateway</html>'] ] } );
  ok( !eval { $html->poll( { device_code => 'd', interval => 1, expires_in => 60 } ); 1 }, 'a non-JSON error croaks' );
  like( $@, qr/poll failed: 502/, 'with the status' );

  my ( undef, $odd ) = fixture( app => sub { [ 200, [], ['[1,2,3]'] ] } );
  ok( !eval { $odd->poll( { device_code => 'd', interval => 1, expires_in => 60 } ); 1 }, 'JSON that is not an object croaks' );
};

subtest 'poll: errors reported with status 200' => sub {
  my @reply = ( { error => 'authorization_pending' }, { access_token => 'tok' } );
  my ( undef, $client, $slept ) = fixture( app => sub { [ 200, [], [ encode_json( shift @reply ) ] ] } );
  is( $client->poll( { device_code => 'd', interval => 3, expires_in => 60 } )->{access_token}, 'tok', 'pending with 200 keeps polling' );
  is( scalar @$slept, 2, 'two polls' );
};

subtest 'poll: gives up when the code has expired' => sub {
  my ( undef, $client, $slept ) = fixture( app => sub { [ 400, [], [ encode_json( { error => 'authorization_pending' } ) ] ] } );
  ok( !eval { $client->poll( { device_code => 'd', interval => 5, expires_in => 12 } ); 1 }, 'croaks' );
  like( $@, qr/the code expired before anyone approved it/, 'and says why' );
  is( scalar @$slept, 3, 'after the polls that fit into the lifetime' );
};

subtest 'poll: defaults for a sparse response' => sub {
  my ( undef, $client, $slept ) = fixture( app => sub { [ 200, [], [ encode_json( { access_token => 'tok' } ) ] ] } );
  $client->poll( { device_code => 'd' } );
  is_deeply( $slept, [5], 'interval defaults to five seconds' );
};

subtest 'discovery' => sub {
  my $config = { device_authorization_endpoint => 'http://id.test/device', token_endpoint => 'http://id.test/token' };
  my $app    = sub { [ 200, [], [ encode_json($config) ] ] };
  my $ua     = LocalUA->new( app => $app );
  my $client = Airlock::Client->new( client_id => 'cli', issuer => 'http://id.test/realms/main/', ua => $ua );
  is( $client->device_endpoint, 'http://id.test/device', 'device endpoint' );
  is( $client->token_endpoint,  'http://id.test/token',  'token endpoint' );
  is( scalar @{ $ua->seen }, 1, 'one discovery request for both' );
  is( $ua->seen->[0]{url}, 'http://id.test/realms/main/.well-known/openid-configuration', 'at the well-known URL, without a double slash' );

  my $partial = Airlock::Client->new( client_id => 'cli', issuer => 'http://id.test', ua => LocalUA->new( app => sub { [ 200, [], ['{"token_endpoint":"http://id.test/token"}'] ] } ) );
  ok( !eval { $partial->device_endpoint; 1 }, 'a server without device endpoint croaks' );
  like( $@, qr/discovery has no device_authorization_endpoint/, 'and says what is missing' );

  my $down = Airlock::Client->new( client_id => 'cli', issuer => 'http://id.test', ua => LocalUA->new( app => sub { [ 503, [], ['down'] ] } ) );
  ok( !eval { $down->token_endpoint; 1 }, 'a failed discovery croaks' );
  like( $@, qr/discovery failed: 503/, 'with the status' );

  ok( !eval { Airlock::Client->new( client_id => 'cli' )->device_endpoint; 1 }, 'neither issuer nor endpoints croaks' );
  like( $@, qr/needs issuer, or device_endpoint and token_endpoint/, 'and says what to give' );
};

subtest 'prompt_text' => sub {
  my ( undef, $client ) = fixture();
  my $start = { verification_uri => 'https://example.org/airlock', user_code => 'BCDF-GHJK', verification_uri_complete => 'https://example.org/airlock?user_code=BCDF-GHJK' };
  my $text  = $client->prompt_text( $start, ansi => 0 );
  like( $text, qr{\AOpen https://example.org/airlock and enter the code BCDF-GHJK\nOr scan:\n}, 'where to go and the code' );
  like( $text, qr/[\x{2580}\x{2584}\x{2588}]{10}/, 'followed by the QR code' );
  is( $client->prompt_text( { verification_uri => 'https://x', user_code => 'ABCD' } ), "Open https://x and enter the code ABCD\n", 'no QR code without verification_uri_complete' );
};

subtest 'against a real socket' => sub {
  # the server is a process of its own, so it builds its own Airlock: the
  # in-process store refuses to be carried across a fork
  my $server = Test::TCP->new(
    code => sub {
      my ( $port ) = @_;
      HTTP::Server::PSGI->new( host => '127.0.0.1', port => $port )->run( AirlockTest->new->airlock->to_app );
    }
  );
  my $base   = 'http://127.0.0.1:'.$server->port.'/airlock';
  my $client = Airlock::Client->new( client_id => 'cli', device_endpoint => $base.'/device', token_endpoint => $base.'/token', sleep => sub { }, on_prompt => sub { } );
  my $start  = $client->start;
  like( $start->{user_code}, qr/\A\w{4}-\w{4}\z/, 'start over HTTP' );
  is( $start->{verification_uri}, 'https://example.org/airlock', 'the response is what the server sent' );
  ok( !eval { Airlock::Client->new( client_id => 'nope', device_endpoint => $base.'/device', token_endpoint => $base.'/token' )->start; 1 }, 'a refusal over HTTP croaks' );
  like( $@, qr/invalid_client/, 'with the server error' );
};

subtest 'poll: nonsense from the server does not become a busy loop' => sub {
  for my $bad ( 0, -5, 'soon', '1e9', 2.5, [], undef, '' ) {
    my ( undef, $client, $slept ) = fixture( app => sub { [ 200, [], [ encode_json( { access_token => 'tok' } ) ] ] } );
    $client->poll( { device_code => 'd', interval => $bad, expires_in => 60 } );
    is_deeply( $slept, [5], 'interval '.( defined $bad ? ref $bad ? 'reference' : '"'.$bad.'"' : 'undef' ).' falls back to five seconds' );
  }
  for my $bad ( 0, -1, 'never', undef ) {
    my $polls = 0;
    my ( undef, $client, $slept ) = fixture( app => sub { $polls++; [ 400, [], [ encode_json( { error => 'authorization_pending' } ) ] ] } );
    ok( !eval { $client->poll( { device_code => 'd', interval => 100, expires_in => $bad } ); 1 }, 'gives up' );
    is( $polls, 6, 'expires_in '.( defined $bad ? '"'.$bad.'"' : 'undef' ).' falls back to ten minutes' );
  }
};

done_testing;
```

- [ ] **Step 2: Test laufen lassen, er muss scheitern**

Run: `prove -lr t/70-client.t`
Expected: FAIL mit `Can't locate Airlock/Client.pm in @INC`.

- [ ] **Step 3: `lib/Airlock/Client.pm` schreiben**

`lib/Airlock/Client.pm`:

```perl
package Airlock::Client;

# ABSTRACT: OAuth 2.0 device flow client (RFC 8628)

use Moo;
use Airlock::QR;
use Carp qw( croak );
use HTTP::Tiny;
use JSON::MaybeXS;
use Types::Standard qw( CodeRef InstanceOf Str );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $client = Airlock::Client->new(
      issuer    => 'https://id.example.org/realms/main',
      client_id => 'my-cli',
      scope     => 'openid profile',
    );

    my $token = $client->login;      # prints code and QR to STDERR, then waits
    print $token->{access_token};

=description

The other side of the device flow: what a command line tool runs to get a
token. It starts the flow, shows the person where to go, polls the token
endpoint at the pace the server sets, and returns the token response.

It speaks plain RFC 8628 and so works against L<Airlock>, Keycloak, and
anything else that implements the grant, including servers that report errors
with status 200.

=cut

has client_id => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

=attr client_id

Required. The client identifier registered with the server.

=cut

has scope => (
  is      => 'ro',
  isa     => Str,
  default => ''
);

=attr scope

Scopes to ask for, separated by spaces. Default: none.

=cut

has issuer => (
  is        => 'ro',
  isa       => Str,
  predicate => 'has_issuer'
);

=attr issuer

The issuer URL. When given, the endpoints are read from
C<< <issuer>/.well-known/openid-configuration >>.

=cut

has device_endpoint => (
  is  => 'lazy',
  isa => Str
);

sub _build_device_endpoint { $_[0]->_discovered('device_authorization_endpoint') }

=attr device_endpoint

The device authorization endpoint. Discovered from C<issuer> unless given.

=cut

has token_endpoint => (
  is  => 'lazy',
  isa => Str
);

sub _build_token_endpoint { $_[0]->_discovered('token_endpoint') }

=attr token_endpoint

The token endpoint. Discovered from C<issuer> unless given.

=cut

has ua => (
  is  => 'lazy',
  isa => InstanceOf['HTTP::Tiny']
);

sub _build_ua { HTTP::Tiny->new( agent => 'Airlock-Client/'.$VERSION, timeout => 30 ) }

=attr ua

The L<HTTP::Tiny> to use. HTTPS needs L<IO::Socket::SSL>.

=cut

has on_prompt => (
  is  => 'lazy',
  isa => CodeRef
);

sub _build_on_prompt {
  my ( $self ) = @_;
  return sub {
    my ( $start ) = @_;
    binmode STDERR, ':encoding(UTF-8)';
    print STDERR $self->prompt_text($start);
  };
}

=attr on_prompt

Coderef called with the device authorization response once the flow has
started. The default prints L</prompt_text> to STDERR.

=cut

has sleep => (
  is      => 'ro',
  isa     => CodeRef,
  default => sub { sub { sleep $_[0] } }
);

=attr sleep

Coderef called with the seconds to wait between polls. For tests.

=cut

has now => (
  is      => 'ro',
  isa     => CodeRef,
  default => sub { sub { time } }
);

=attr now

Coderef returning the current epoch. For tests.

=cut

has _discovery => (
  is       => 'lazy',
  init_arg => undef
);

sub _build__discovery {
  my ( $self ) = @_;
  croak __PACKAGE__.'->new needs issuer, or device_endpoint and token_endpoint' unless $self->has_issuer;
  my $url      = $self->issuer =~ s{/+\z}{}r.'/.well-known/openid-configuration';
  my $response = $self->ua->get( $url, { headers => { Accept => 'application/json' } } );
  croak __PACKAGE__.' discovery failed: '.$response->{status}.' '.$response->{reason}.' for '.$url
    unless $response->{success};
  my $data = $self->_decode($response);
  croak __PACKAGE__.' discovery returned no JSON object for '.$url unless %$data;
  return $data;
}

sub _discovered {
  my ( $self, $key ) = @_;
  return $self->_discovery->{$key} // croak __PACKAGE__.' discovery has no '.$key;
}

sub device_grant_type { 'urn:ietf:params:oauth:grant-type:device_code' }

sub start {
  my ( $self ) = @_;
  my $response = $self->_post( $self->device_endpoint, {
    client_id => $self->client_id,
    length $self->scope ? ( scope => $self->scope ) : ()
  } );
  my $data = $self->_decode($response);
  croak __PACKAGE__.'->start failed: '.$self->_reason( $response, $data )
    unless $response->{success} && defined $data->{device_code} && defined $data->{user_code};
  return $data;
}

=method start

    my $start = $client->start;

Begins the flow. Returns the device authorization response: C<device_code>,
C<user_code>, C<verification_uri>, optionally C<verification_uri_complete>,
C<expires_in> and C<interval>. Croaks when the server refuses.

=cut

sub poll {
  my ( $self, $start ) = @_;
  my $interval = $self->_seconds( $start->{interval}, 5 );
  my $deadline = $self->now->() + $self->_seconds( $start->{expires_in}, 600 );
  while ( $self->now->() < $deadline ) {
    $self->sleep->($interval);
    my $response = $self->_post( $self->token_endpoint, {
      grant_type  => $self->device_grant_type,
      device_code => $start->{device_code},
      client_id   => $self->client_id
    } );
    my $data = $self->_decode($response);
    return $data if $response->{success} && defined $data->{access_token};
    my $error = $data->{error} // '';
    next if $error eq 'authorization_pending';
    if ( $error eq 'slow_down' ) {
      $interval += 5;
      next;
    }
    croak __PACKAGE__.'->poll failed: '.$self->_reason( $response, $data );
  }
  croak __PACKAGE__.'->poll gave up: the code expired before anyone approved it';
}

=method poll

    my $token = $client->poll($start);

Waits for the approval. Sleeps the interval the server asked for, adds five
seconds on every C<slow_down>, and returns the token response. Croaks on
C<access_denied>, C<expired_token>, any other error, and when the code's
lifetime runs out.

=cut

sub login {
  my ( $self ) = @_;
  my $start = $self->start;
  $self->on_prompt->($start);
  return $self->poll($start);
}

=method login

    my $token = $client->login;

L</start>, the prompt, then L</poll>.

=cut

sub prompt_text {
  my ( $self, $start, %arg ) = @_;
  my $text = 'Open '.$start->{verification_uri}.' and enter the code '.$start->{user_code}."\n";
  return $text unless defined $start->{verification_uri_complete};
  return $text.'Or scan:'."\n".Airlock::QR->new( text => $start->{verification_uri_complete}, quiet => 2 )->terminal(%arg);
}

=method prompt_text

    print STDERR $client->prompt_text($start);

What to show the person: where to go, the code, and a QR code of
C<verification_uri_complete> when the server sent one. Takes the options of
L<Airlock::QR/terminal>.

=cut

# A server can send anything. Only a positive whole number of seconds is
# taken; everything else falls back, so a bad value cannot turn the poll loop
# into a busy loop.
sub _seconds {
  my ( $self, $value, $default ) = @_;
  return $default unless defined $value && !ref $value && $value =~ /\A[0-9]{1,9}\z/ && $value > 0;
  return $value + 0;
}

sub _post {
  my ( $self, $url, $form ) = @_;
  return $self->ua->post_form( $url, $form, { headers => { Accept => 'application/json' } } );
}

sub _decode {
  my ( $self, $response ) = @_;
  my $data = eval { decode_json( $response->{content} // '' ) };
  return ref $data eq 'HASH' ? $data : {};
}

sub _reason {
  my ( $self, $response, $data ) = @_;
  return $data->{error}.( defined $data->{error_description} ? ' ('.$data->{error_description}.')' : '' )
    if defined $data->{error} && !ref $data->{error};
  return $response->{status}.' '.( $response->{reason} // '' );
}

1;
```

- [ ] **Step 4: Test laufen lassen**

Run: `prove -lr t/70-client.t`
Expected: PASS (11 Subtests).

- [ ] **Step 5: Modul in den Load-Test**

`  Airlock::Client` in die Liste in `t/00-load.t`. Run: `prove -lr t` — Expected: PASS.

- [ ] **Step 6: Übergabe**

Commit-fertig lassen, Karte nach `review`. Betreff: `Add Airlock::Client`; `Changes`: `- Airlock::Client: RFC 8628 device flow client with discovery and terminal QR code`.

---

### Task 8: Beispiele und README

Spec: Abschnitt 5 (Menschen-Seite, Beispiele). Die Beispiele sind der Beleg, dass der Einbau ohne Plugin wenige Zeilen ist, und die Store-Beispiele laufen gegen dieselbe Vertrags-Suite wie der eingebaute Speicher.

**Files:**
- Create: `examples/schema.sql`
- Create: `examples/lib/AirlockExample/StoreDBI.pm`, `examples/lib/AirlockExample/Schema.pm`, `examples/lib/AirlockExample/Schema/Result/Airlock.pm`, `examples/lib/AirlockExample/StoreDBIO.pm`, `examples/lib/AirlockExample/Demo.pm`
- Create: `examples/app.psgi`, `examples/mojo.pl`, `examples/login.pl`
- Test: `t/80-example-store-dbi.t`, `t/81-example-store-dbio.t`, `t/82-example-psgi.t`, `t/83-example-mojo.t`
- Modify: `README.md` (ganz ersetzen)

**Interfaces:**
- Consumes: alles aus den Aufgaben 1 bis 7; insbesondere `Airlock->row_fields`, `Airlock::Test::Store`, `->to_app`, `->respond`, `->parse_form`, `->inspect`, `->requirements`, `->approve`, `->deny`, `Airlock::QR->svg`, `Airlock::Client->login`.
- Produces: nichts, worauf andere Aufgaben bauen.

Die vier Tests überspringen sich selbst, wenn ihre optionale Abhängigkeit fehlt (`DBD::SQLite`, `DBIO`, `Plack`, `Mojolicious`). Zum Ausführen dieser Aufgabe müssen alle vier installiert sein, sonst ist nichts bewiesen: `cpanm DBD::SQLite Plack Mojolicious` und DBIO aus `~/dev/dbio-dev/dbio`.

- [ ] **Step 1: Die Tests schreiben**

`t/80-example-store-dbi.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'examples/lib';

BEGIN {
  plan skip_all => 'DBI and DBD::SQLite are needed for this example'
    unless eval { require DBI; require DBD::SQLite; 1 };
}

use Path::Tiny qw( path );
use Airlock;
use Airlock::Test::Store;
use AirlockExample::StoreDBI;

sub database {
  my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1, PrintError => 0 } );
  $dbh->do($_) for grep { /\S/ } split /;/, path('examples/schema.sql')->slurp_utf8 =~ s/^--.*$//mgr;
  return $dbh;
}

subtest 'store contract' => sub {
  Airlock::Test::Store->new( store => AirlockExample::StoreDBI->new( dbh => database() )->as_subs )->run;
};

subtest 'a whole flow on the database' => sub {
  my $dbh     = database();
  my $clock   = 1_000_000;
  my $airlock = Airlock->new(
    clients          => { cli => {} },
    verification_uri => 'https://example.org/airlock',
    store            => AirlockExample::StoreDBI->new( dbh => sub { $dbh } )->as_subs,
    now              => sub { $clock }
  );
  my $start = $airlock->open( client_id => 'cli', scope => 'read' )->data;
  is( $airlock->redeem( device_code => $start->{device_code}, client_id => 'cli' )->status, 'authorization_pending', 'pending' );
  ok( $airlock->approve( $start->{user_code}, subject => { id => 'alice', amr => [qw( pwd otp )] } )->ok, 'approved' );
  $clock += 5;
  my $token = $airlock->redeem( device_code => $start->{device_code}, client_id => 'cli' )->data->{access_token};
  is_deeply( $airlock->verify_token($token)->{amr}, [qw( pwd otp )], 'the token verifies from the database' );
  is( $airlock->redeem( device_code => $start->{device_code}, client_id => 'cli' )->status, 'invalid_grant', 'redeemed once' );
  my ( $secrets ) = $dbh->selectrow_array( 'SELECT COUNT(*) FROM airlock WHERE hash IN (?, ?)', undef, $start->{device_code}, $token );
  is( $secrets, 0, 'neither the device code nor the token is in the table' );
  $clock += 4000;
  is( $airlock->purge, 2, 'purge removes request and token' );
};

done_testing;
```

`t/81-example-store-dbio.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'examples/lib';

BEGIN {
  plan skip_all => 'DBIO and DBD::SQLite are needed for this example'
    unless eval { require DBIO; require DBD::SQLite; 1 };
}

use Path::Tiny qw( path );
use Airlock;
use Airlock::Test::Store;
use AirlockExample::Schema;
use AirlockExample::StoreDBIO;

sub schema {
  my $schema = AirlockExample::Schema->connect( 'dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1, PrintError => 0 } );
  my @ddl    = grep { /\S/ } split /;/, path('examples/schema.sql')->slurp_utf8 =~ s/^--.*$//mgr;
  $schema->storage->dbh_do( sub { $_[1]->do($_) for @ddl } );
  return $schema;
}

subtest 'store contract' => sub {
  Airlock::Test::Store->new( store => AirlockExample::StoreDBIO->new( schema => schema() )->as_subs )->run;
};

subtest 'a whole flow on the schema' => sub {
  my $schema  = schema();
  my $clock   = 1_000_000;
  my $airlock = Airlock->new(
    clients          => { cli => {} },
    verification_uri => 'https://example.org/airlock',
    store            => AirlockExample::StoreDBIO->new( schema => $schema )->as_subs,
    now              => sub { $clock }
  );
  my $start = $airlock->open( client_id => 'cli', scope => 'read' )->data;
  ok( $airlock->approve( $start->{user_code}, subject => { id => 'alice' } )->ok, 'approved' );
  my $token = $airlock->redeem( device_code => $start->{device_code}, client_id => 'cli' )->data->{access_token};
  is( $airlock->verify_token($token)->{subject}, 'alice', 'the token verifies from the schema' );
  is( $airlock->redeem( device_code => $start->{device_code}, client_id => 'cli' )->status, 'invalid_grant', 'redeemed once' );
  is( $schema->resultset('Airlock')->search( { hash => [ $start->{device_code}, $token ] } )->count, 0, 'no secret in the table' );
};

done_testing;
```

`t/82-example-psgi.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'examples/lib';

BEGIN {
  plan skip_all => 'Plack is needed for this example'
    unless eval { require Plack::Test; require Plack::Util; require HTTP::Request::Common; 1 };
}

use JSON::MaybeXS;
use HTTP::Request::Common qw( GET POST );

my $app   = Plack::Util::load_psgi('examples/app.psgi');
my $test  = Plack::Test->create($app);
my $grant = 'urn:ietf:params:oauth:grant-type:device_code';

sub start {
  my ( $scope ) = @_;
  my $response = $test->request( POST '/airlock/device', [ client_id => 'demo-cli', scope => $scope ] );
  is( $response->code, 200, 'device endpoint' );
  return decode_json( $response->content );
}

sub poll {
  my ( $start ) = @_;
  my $response = $test->request( POST '/airlock/token', [ grant_type => $grant, client_id => 'demo-cli', device_code => $start->{device_code} ] );
  return decode_json( $response->content );
}

subtest 'plain scope: look, approve, token' => sub {
  my $start = start('read');
  is( poll($start)->{error}, 'authorization_pending', 'pending' );

  my $form = $test->request( GET '/approve' );
  like( $form->content, qr/name="user_code"/, 'without a code the page asks for one' );

  my $look = $test->request( GET '/approve?user_code='.$start->{user_code} );
  is( $look->code, 200, 'approval page' );
  like( $look->content, qr/<b>Demo CLI<\/b> wants access: read/, 'shows client and scopes' );
  unlike( $look->content, qr/name="pin"/, 'no PIN for a plain scope' );
  is( poll($start)->{error}, 'slow_down', 'looking approved nothing (and the second poll came too fast)' );

  my $done = $test->request( POST '/approve', [ user_code => $start->{user_code}, action => 'approve' ] );
  like( $done->content, qr/Approved/, 'approved' );
  is( $test->request( GET '/approve?user_code='.$start->{user_code} )->code, 404, 'the code is used up' );
};

subtest 'step-up scope: PIN' => sub {
  my $start = start('read admin');
  like( $test->request( GET '/approve?user_code='.$start->{user_code} )->content, qr/name="pin"/, 'the page asks for the PIN' );
  my $wrong = $test->request( POST '/approve', [ user_code => $start->{user_code}, action => 'approve', pin => '0000' ] );
  is( $wrong->code, 403, 'wrong PIN' );
  like( $wrong->content, qr/Wrong PIN/, 'says so' );
  my $right = $test->request( POST '/approve', [ user_code => $start->{user_code}, action => 'approve', pin => '4711' ] );
  like( $right->content, qr/Approved/, 'right PIN' );
};

subtest 'deny' => sub {
  my $start = start('read');
  like( $test->request( POST '/approve', [ user_code => $start->{user_code}, action => 'deny' ] )->content, qr/Denied/, 'denied' );
  is( poll($start)->{error}, 'access_denied', 'the device learns it' );
};

subtest 'unknown code and escaping' => sub {
  my $response = $test->request( GET '/approve?user_code=%3Cscript%3E' );
  is( $response->code, 404, 'unknown code' );
  unlike( $response->content, qr/<script>/, 'nothing typed is echoed' );
};

subtest 'qr' => sub {
  my $start = start('read');
  my $qr    = $test->request( GET '/qr.svg?user_code='.$start->{user_code} );
  is( $qr->code, 200, 'QR code' );
  is( $qr->header('Content-Type'), 'image/svg+xml', 'as SVG' );
  like( $qr->content, qr/\A<svg /, 'SVG body' );
  is( $test->request( GET '/qr.svg?user_code=ZZZZ-ZZZZ' )->code, 404, 'no QR code for an unknown code' );
};

done_testing;
```

`t/83-example-mojo.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'examples/lib';

BEGIN {
  plan skip_all => 'Mojolicious is needed for this example'
    unless eval { require Test::Mojo; require Mojo::File; 1 };
}

my $t     = Test::Mojo->new( Mojo::File->new('examples/mojo.pl') );
my $grant = 'urn:ietf:params:oauth:grant-type:device_code';

$t->post_ok( '/airlock/device' => form => { client_id => 'demo-cli', scope => 'read admin' } )
  ->status_is(200)->header_is( 'Cache-Control' => 'no-store' )->json_has('/device_code')->json_like( '/user_code' => qr/\A\w{4}-\w{4}\z/ );
my $start = $t->tx->res->json;

$t->post_ok( '/airlock/token' => form => { grant_type => $grant, client_id => 'demo-cli', device_code => $start->{device_code} } )
  ->status_is(400)->json_is( '/error' => 'authorization_pending' );

$t->post_ok( '/airlock/device' => { 'Content-Type' => 'application/x-www-form-urlencoded' } => 'client_id=demo-cli&client_id=other' )
  ->status_is(400)->json_is( '/error' => 'invalid_request', 'a repeated parameter is refused, as with to_app' );

$t->get_ok( '/approve' => form => { user_code => $start->{user_code} } )
  ->status_is(200)->content_like(qr/Demo CLI/)->content_like(qr/name="pin"/);

$t->post_ok( '/approve' => form => { user_code => $start->{user_code}, action => 'approve', pin => '4711' } )
  ->status_is(200)->content_like(qr/Approved/);

$t->get_ok( '/qr' => form => { user_code => 'ZZZZ-ZZZZ' } )->status_is(404);

$t->post_ok( '/airlock/nope' => form => {} )->status_is(404);

done_testing;
```

- [ ] **Step 2: Tests laufen lassen, sie müssen scheitern**

Run: `prove -lr t/80-example-store-dbi.t t/81-example-store-dbio.t t/82-example-psgi.t t/83-example-mojo.t`
Expected: FAIL mit `Can't locate AirlockExample/StoreDBI.pm`, `Can't locate AirlockExample/Schema.pm`, einem Ladefehler für `examples/app.psgi` und einem für `examples/mojo.pl`. Steht dort stattdessen `skipped`, fehlt eine der optionalen Abhängigkeiten: erst installieren.

- [ ] **Step 3: `examples/schema.sql` schreiben**

`examples/schema.sql`:

```sql
-- One table holds waiting requests and opaque tokens. `hash` is the SHA-256 of
-- the device code or of the token; neither secret is ever stored.
-- Works as written on SQLite and PostgreSQL.
CREATE TABLE airlock (
  hash            VARCHAR(64)  NOT NULL PRIMARY KEY,
  kind            VARCHAR(16)  NOT NULL,
  user_code       VARCHAR(16)  UNIQUE,
  client_id       VARCHAR(255) NOT NULL,
  scope           TEXT         NOT NULL,
  state           VARCHAR(16)  NOT NULL,
  created         BIGINT       NOT NULL,
  expires         BIGINT       NOT NULL,
  poll_interval   INTEGER,
  last_poll       BIGINT,
  subject         VARCHAR(255),
  amr             VARCHAR(255),
  acr             VARCHAR(255),
  auth_time       BIGINT,
  approved        BIGINT,
  origin_ip       VARCHAR(64),
  origin_ua       VARCHAR(255),
  factor_failures INTEGER      NOT NULL DEFAULT 0
);

CREATE INDEX airlock_expires ON airlock (expires);
```

- [ ] **Step 4: Den DBI-Store schreiben**

`examples/lib/AirlockExample/StoreDBI.pm`:

```perl
package AirlockExample::StoreDBI;

# The four Airlock store subs on plain DBI. Table: examples/schema.sql.
#
#   my $store   = AirlockExample::StoreDBI->new( dbh => $dbh );
#   my $airlock = Airlock->new( store => $store->as_subs, ... );
#
# The handle must have RaiseError set: insert relies on the database refusing
# a duplicate hash or user code.

use Moo;
use Airlock;
use Carp qw( croak );
use namespace::autoclean;

# a DBI handle, or a coderef returning one (for connection pools and forks)
has dbh => ( is => 'ro', required => 1 );

has table => ( is => 'ro', default => 'airlock' );

sub _dbh {
  my ( $self ) = @_;
  return ref $self->dbh eq 'CODE' ? $self->dbh->() : $self->dbh;
}

sub _fields { Airlock->row_fields }

sub insert {
  my ( $self, $row ) = @_;
  my @fields = $self->_fields;
  $self->_dbh->do(
    'INSERT INTO '.$self->table.' ('.join( ', ', @fields ).') VALUES ('.join( ', ', ('?') x @fields ).')',
    undef, @{$row}{@fields}
  );
  return 1;
}

sub find {
  my ( $self, $field, $value ) = @_;
  croak __PACKAGE__.'->find by '.$field.' is not supported' unless $field eq 'hash' || $field eq 'user_code';
  return unless defined $value;
  return $self->_dbh->selectrow_hashref(
    'SELECT '.join( ', ', $self->_fields ).' FROM '.$self->table.' WHERE '.$field.' = ?', undef, $value
  );
}

# The WHERE on the old state is the whole point: of two concurrent redeems
# only one statement changes a row.
sub update {
  my ( $self, $hash, $from_state, $changes ) = @_;
  my %known  = map { $_ => 1 } $self->_fields;
  my @fields = sort keys %$changes;
  croak __PACKAGE__.'->update unknown field' if grep { !$known{$_} } @fields;
  my $changed = $self->_dbh->do(
    'UPDATE '.$self->table.' SET '.join( ', ', map { $_.' = ?' } @fields ).' WHERE hash = ? AND state = ?',
    undef, @{$changes}{@fields}, $hash, $from_state
  );
  return $changed > 0 ? 1 : 0;
}

sub purge {
  my ( $self, $before ) = @_;
  return $self->_dbh->do( 'DELETE FROM '.$self->table.' WHERE expires < ?', undef, $before ) + 0;
}

sub as_subs {
  my ( $self ) = @_;
  return {
    insert => sub { $self->insert(@_) },
    find   => sub { $self->find(@_) },
    update => sub { $self->update(@_) },
    purge  => sub { $self->purge(@_) }
  };
}

1;
```

- [ ] **Step 5: Den DBIO-Store schreiben**

`examples/lib/AirlockExample/Schema.pm`:

```perl
package AirlockExample::Schema;

# DBIO schema for the Airlock table. Used by AirlockExample::StoreDBIO.

use DBIO 'Schema';

__PACKAGE__->load_namespaces;

1;
```

`examples/lib/AirlockExample/Schema/Result/Airlock.pm`:

```perl
package AirlockExample::Schema::Result::Airlock;

# The Airlock table as a DBIO result class. Same columns as examples/schema.sql.

use DBIO::Candy;

table 'airlock';

primary_column hash => { data_type => 'varchar', size => 64 };

column kind            => { data_type => 'varchar', size => 16 };
column user_code       => { data_type => 'varchar', size => 16, is_nullable => 1 };
column client_id       => { data_type => 'varchar', size => 255 };
column scope           => { data_type => 'text' };
column state           => { data_type => 'varchar', size => 16 };
column created         => { data_type => 'bigint' };
column expires         => { data_type => 'bigint' };
column poll_interval   => { data_type => 'integer', is_nullable => 1 };
column last_poll       => { data_type => 'bigint', is_nullable => 1 };
column subject         => { data_type => 'varchar', size => 255, is_nullable => 1 };
column amr             => { data_type => 'varchar', size => 255, is_nullable => 1 };
column acr             => { data_type => 'varchar', size => 255, is_nullable => 1 };
column auth_time       => { data_type => 'bigint', is_nullable => 1 };
column approved        => { data_type => 'bigint', is_nullable => 1 };
column origin_ip       => { data_type => 'varchar', size => 64, is_nullable => 1 };
column origin_ua       => { data_type => 'varchar', size => 255, is_nullable => 1 };
column factor_failures => { data_type => 'integer', default_value => 0 };

unique_constraint airlock_user_code => ['user_code'];

1;
```

`examples/lib/AirlockExample/StoreDBIO.pm`:

```perl
package AirlockExample::StoreDBIO;

# The four Airlock store subs on a DBIO schema.
#
#   my $schema  = AirlockExample::Schema->connect( $dsn, $user, $password );
#   my $store   = AirlockExample::StoreDBIO->new( schema => $schema );
#   my $airlock = Airlock->new( store => $store->as_subs, ... );

use Moo;
use Carp qw( croak );
use namespace::autoclean;

has schema => ( is => 'ro', required => 1 );

has source => ( is => 'ro', default => 'Airlock' );

sub _rs { $_[0]->schema->resultset( $_[0]->source ) }

sub insert {
  my ( $self, $row ) = @_;
  $self->_rs->create( { %$row } );
  return 1;
}

sub find {
  my ( $self, $field, $value ) = @_;
  croak __PACKAGE__.'->find by '.$field.' is not supported' unless $field eq 'hash' || $field eq 'user_code';
  return unless defined $value;
  my $row = $self->_rs->search( { $field => $value } )->single or return;
  return { $row->get_columns };
}

# One UPDATE ... WHERE hash = ? AND state = ?. A resultset update returns the
# number of rows it changed, as '0E0' when there were none.
sub update {
  my ( $self, $hash, $from_state, $changes ) = @_;
  return $self->_rs->search( { hash => $hash, state => $from_state } )->update( { %$changes } ) > 0 ? 1 : 0;
}

sub purge {
  my ( $self, $before ) = @_;
  return $self->_rs->search( { expires => { '<' => $before } } )->delete + 0;
}

sub as_subs {
  my ( $self ) = @_;
  return {
    insert => sub { $self->insert(@_) },
    find   => sub { $self->find(@_) },
    update => sub { $self->update(@_) },
    purge  => sub { $self->purge(@_) }
  };
}

1;
```

- [ ] **Step 6: Store-Tests laufen lassen**

Run: `prove -lr t/80-example-store-dbi.t t/81-example-store-dbio.t`
Expected: PASS (je 2 Subtests).

- [ ] **Step 7: Die gemeinsame Demo-Logik schreiben**

Login und CSRF-Schutz gehören der Host-App. Das Beispiel markiert beide Stellen mit einem Kommentar in Großbuchstaben, statt sie vorzutäuschen.

`examples/lib/AirlockExample/Demo.pm`:

```perl
package AirlockExample::Demo;

# What both example apps share: the Airlock itself and the approval page as
# plain data plus a tiny HTML renderer. In a real application the Airlock is
# built from your configuration and the page is one of your own templates.

use Moo;
use Airlock;
use Airlock::Factor::Callback;
use namespace::autoclean;

has base_url => ( is => 'ro', default => 'http://localhost:5000' );

has airlock => ( is => 'lazy' );

sub _build_airlock {
  my ( $self ) = @_;
  return Airlock->new(
    clients          => { 'demo-cli' => { name => 'Demo CLI', scopes => [qw( read admin )] } },
    verification_uri => $self->base_url.'/approve',
    # asking for the scope "admin" needs the PIN on top of being logged in
    policy  => { step_up => { admin => ['pin'] } },
    factors => [
      Airlock::Factor::Callback->new( name => 'pin', amr => 'pin', verify => sub { $_[1] eq '4711' } )
    ]
  );
}

# YOUR LOGIN GOES HERE. The demo has exactly one person and she is always
# logged in. A real application returns its session's user, or nothing, and
# sends anyone who is not logged in to its login page first.
sub subject { { id => 'demo-user' } }

sub escape {
  my ( $self, $text ) = @_;
  $text //= '';
  $text =~ s/&/&amp;/g;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;
  $text =~ s/"/&quot;/g;
  return $text;
}

# Everything the approval page does, as status and HTML, so that the Plack and
# the Mojolicious example differ only in how they read a request.
sub page {
  my ( $self, %param ) = @_;
  my $airlock = $self->airlock;
  my $subject = $self->subject;
  my $code    = $param{user_code} // '';
  return ( 200, $self->_form('') ) unless length $code;

  if ( ( $param{action} // '' ) eq 'deny' ) {
    my $denied = $airlock->deny( $code, subject => $subject );
    return $denied->ok ? ( 200, '<p>Denied. You can close this window.</p>' ) : ( 404, $self->_form('That code is unknown or has expired.') );
  }

  my $view = $airlock->inspect( $code, subject => $subject )
    or return ( 404, $self->_form('That code is unknown or has expired.') );
  my $needs = $airlock->requirements( $view, $subject );
  return ( 200, $self->_confirm( $view, $needs, '' ) ) unless ( $param{action} // '' ) eq 'approve';

  my $result = $airlock->approve( $code, subject => $subject, proofs => { pin => $param{pin} } );
  return ( 200, '<p>Approved. You can close this window.</p>' ) if $result->ok;
  return ( 403, '<p>Too many wrong attempts. Start again on the device.</p>' ) if $result->status eq 'too_many_failures';
  return ( 404, $self->_form('That code is unknown or has expired.') ) if $result->status eq 'unknown_code';
  return ( $result->status eq 'factor_required' ? 200 : 403,
    $self->_confirm( $view, $needs, $result->status eq 'factor_failed' ? 'Wrong PIN.' : '' ) );
}

sub _form {
  my ( $self, $message ) = @_;
  return '<p>'.$self->escape($message).'</p>'
    .'<form method="get" action="/approve"><label>Code <input name="user_code" autofocus></label>'
    .'<button>Continue</button></form>';
}

sub _confirm {
  my ( $self, $view, $needs, $message ) = @_;
  my $pin = grep( { $_ eq 'pin' } @$needs ) ? '<label>PIN <input name="pin" inputmode="numeric" autocomplete="off"></label>' : '';
  # YOUR CSRF TOKEN GOES INTO THIS FORM. Approving is a state change made with
  # the person's session; check the token before calling approve or deny.
  return '<p>'.$self->escape($message).'</p>'
    .'<p><b>'.$self->escape( $view->{client_name} ).'</b> wants access: '
    .$self->escape( join ', ', @{ $view->{scopes} } ).'</p>'
    .'<p>Asked '.$view->{age}.' seconds ago from '.$self->escape( $view->{origin}{ip} )
    .' ('.$self->escape( $view->{origin}{ua} ).')</p>'
    .'<form method="post" action="/approve">'
    .'<input type="hidden" name="user_code" value="'.$self->escape( $view->{user_code} ).'">'
    .$pin
    .'<button name="action" value="approve">Approve</button>'
    .'<button name="action" value="deny">Deny</button></form>';
}

1;
```

- [ ] **Step 8: Die Plack-App, die Mojolicious-App und das CLI schreiben**

`examples/app.psgi`:

```perl
#!/usr/bin/env perl

# Airlock in a Plack application.
#
#   plackup -Ilib -Iexamples/lib examples/app.psgi
#   perl -Ilib examples/login.pl          # in a second terminal
#
# The machine endpoints are mounted with to_app. The approval page is this
# application's own: it reads the request, asks Airlock, renders HTML.

use strict;
use warnings;
use Airlock::QR;
use AirlockExample::Demo;
use Plack::Builder;
use Plack::Request;

my $demo = AirlockExample::Demo->new;

my $approve = sub {
  my ( $env ) = @_;
  my $request = Plack::Request->new($env);
  my $param   = $request->method eq 'POST' ? $request->body_parameters : $request->query_parameters;
  my ( $status, $html ) = $demo->page( map { $_ => scalar $param->get($_) } qw( user_code action pin ) );
  return [ $status, [ 'Content-Type' => 'text/html; charset=utf-8', 'Cache-Control' => 'no-store' ], [$html] ];
};

# The QR code a device without a terminal would show: it leads the phone to
# the approval page with the code filled in.
my $qr = sub {
  my ( $env ) = @_;
  my $view = $demo->airlock->inspect( Plack::Request->new($env)->query_parameters->get('user_code') )
    or return [ 404, [ 'Content-Type' => 'text/plain' ], ['unknown code'] ];
  my $uri = $demo->airlock->verification_uri.'?user_code='.$view->{user_code};
  return [ 200, [ 'Content-Type' => 'image/svg+xml', 'Cache-Control' => 'no-store' ], [ Airlock::QR->new( text => $uri )->svg ] ];
};

builder {
  mount '/airlock' => $demo->airlock->to_app;
  mount '/approve' => $approve;
  mount '/qr.svg'  => $qr;
};
```

`examples/mojo.pl`:

```perl
#!/usr/bin/env perl

# Airlock in a Mojolicious application.
#
#   perl -Ilib -Iexamples/lib examples/mojo.pl daemon -l http://*:5000
#   perl -Ilib examples/login.pl          # in a second terminal
#
# There is no plugin: the two machine endpoints are one route that hands the
# request to respond, and the approval page is an ordinary action.

use Mojolicious::Lite;
use Airlock::QR;
use AirlockExample::Demo;

my $demo = AirlockExample::Demo->new;

post '/airlock/:route' => [ route => [qw( device token )] ] => sub {
  my ( $c ) = @_;
  my ( $status, $headers, $json ) = @{ $demo->airlock->respond(
    'POST', $c->req->url->path->to_string, scalar $demo->airlock->parse_form( $c->req->body ),
    { ip => $c->tx->remote_address, ua => $c->req->headers->user_agent }
  ) };
  $c->res->headers->header( $_ => $headers->{$_} ) for keys %$headers;
  $c->render( json => $json, status => $status );
};

any [qw( GET POST )] => '/approve' => sub {
  my ( $c ) = @_;
  my ( $status, $html ) = $demo->page( map { $_ => scalar $c->param($_) } qw( user_code action pin ) );
  $c->res->headers->cache_control('no-store');
  $c->render( data => $html, format => 'html', status => $status );
};

get '/qr' => sub {
  my ( $c ) = @_;
  my $view = $demo->airlock->inspect( $c->param('user_code') ) or return $c->render( text => 'unknown code', status => 404 );
  my $uri = $demo->airlock->verification_uri.'?user_code='.$view->{user_code};
  $c->render( data => Airlock::QR->new( text => $uri )->svg, format => 'svg' );
};

app->start;
```

`examples/login.pl`:

```perl
#!/usr/bin/env perl

# The device side: get a token from one of the example apps.
#
#   perl -Ilib examples/login.pl [scope ...]
#
# Against an OpenID Connect provider, pass issuer => 'https://.../realms/x'
# instead of the two endpoints and let the client discover them.

use strict;
use warnings;
use Airlock::Client;

my $base   = $ENV{AIRLOCK_EXAMPLE_URL} // 'http://localhost:5000';
my $client = Airlock::Client->new(
  client_id       => 'demo-cli',
  scope           => join( ' ', @ARGV ),
  device_endpoint => $base.'/airlock/device',
  token_endpoint  => $base.'/airlock/token'
);

my $token = $client->login;

print 'access_token: '.$token->{access_token}."\n";
print 'scope:        '.( $token->{scope} // '' )."\n";
```

- [ ] **Step 9: App-Tests laufen lassen**

Run: `prove -lr t/82-example-psgi.t t/83-example-mojo.t`
Expected: PASS (5 Subtests und 22 Tests).

- [ ] **Step 10: Von Hand ausprobieren**

Terminal 1: `plackup -Ilib -Iexamples/lib examples/app.psgi`
Terminal 2: `perl -Ilib examples/login.pl read admin`
Expected: Terminal 2 zeigt URL, Code und QR-Code. Im Browser `http://localhost:5000/approve` öffnen, Code eingeben, PIN `4711`, bestätigen. Terminal 2 gibt innerhalb von fünf Sekunden `access_token:` und `scope:        read admin` aus.

- [ ] **Step 11: `README.md` ersetzen**

`README.md`:

````markdown
# Airlock

Embeddable device authorization (RFC 8628) with step-up second factors.

A device or CLI shows a short code. A logged-in person enters or scans it
somewhere else, sees who wants what, approves — if the policy says so, only
after a second factor — and the device gets its token.

Airlock is a core to embed, not an application. The host application supplies
who is logged in, the approval page and four storage subs. Airlock supplies
codes, the state machine, poll rules, one-time redemption, step-up policy,
second factors, QR codes, the two machine endpoints, and a device-flow client.

It has no HTML, no database driver and no web framework at runtime.

## Installation

```bash
cpanm Airlock
```

## Embedding

```perl
use Airlock;
use Airlock::Factor::Callback;

my $airlock = Airlock->new(
  clients          => { 'my-cli' => { name => 'My CLI', scopes => [qw( read admin )] } },
  verification_uri => 'https://my.example.org/approve',
  store            => { insert => sub {...}, find => sub {...}, update => sub {...}, purge => sub {...} },
  policy           => { step_up => { admin => ['totp'] } },
  factors          => [ Airlock::Factor::Callback->new( name => 'totp', amr => 'otp', verify => sub {...} ) ],
);
```

### Machine side

```perl
# PSGI, no Plack needed
builder { mount '/airlock' => $airlock->to_app; mount '/' => $app };

# HTTP::Request in, HTTP::Response out
my $response = Airlock::HTTPMessage->new( airlock => $airlock )->handle( $request, ip => $remote_address );

# anything else
my ( $status, $headers, $json ) = @{ $airlock->respond( 'POST', $path, \%form, { ip => $ip, ua => $ua } ) };
```

Two routes, matched on the last path segment: `POST .../device` and
`POST .../token`.

### Human side

The approval page is yours. Airlock gives it data and takes its decision:

```perl
my $view  = $airlock->inspect( $typed_code, subject => $subject ) or return not_found();
my $needs = $airlock->requirements( $view, $subject );     # ['totp']
my $done  = $airlock->approve( $typed_code, subject => $subject, proofs => { totp => $typed } );
my $done  = $airlock->deny( $typed_code, subject => $subject );
```

`$subject` is who is logged in: `{ id => ... }`, optionally with `amr`, `acr`
and `auth_time` from your identity provider. Login, CSRF protection and rate
limits are yours too; `on_event` reports every `code_miss` and
`factor_failed` to hang a limit on.

## Store

Four subs against whatever database you have:

| Sub | Does |
|---|---|
| `insert(\%row)` | stores a row; dies on a duplicate `hash` or `user_code` |
| `find($field, $value)` | row by `hash` or `user_code`, or nothing |
| `update($hash, $from_state, \%changes)` | applies the changes only if `state` is still `$from_state`; returns true if it did |
| `purge($before)` | removes rows with `expires < $before`; optional |

`update` is the only one that has to be atomic. `Airlock->row_fields` lists
the columns, `examples/schema.sql` is a table for them, and
`Airlock::Test::Store` checks your four subs against the contract:

```perl
use Airlock::Test::Store;
Airlock::Test::Store->new( store => $my_subs )->run;
```

Without a store Airlock keeps rows in the process, which is right for tests
and wrong under a preforking server; it croaks when used across a fork.

## Second factors

| Class | Use |
|---|---|
| `Airlock::Factor::Callback` | your application checks the proof |
| `Airlock::Factor::TOTP` | RFC 6238, secrets supplied by your application |
| `Airlock::Factor::Upstream` | the identity provider already checked one (`amr`, `acr`, `auth_time`) |

`Airlock::Upstream::Keycloak` turns Keycloak token claims into a subject.

## QR codes

```perl
my $qr = Airlock::QR->new( text => $verification_uri_complete );
$qr->svg;        # for the web
$qr->data_uri;   # for an <img>
$qr->terminal;   # for a CLI
```

## Client

```perl
my $token = Airlock::Client->new(
  issuer    => 'https://id.example.org/realms/main',
  client_id => 'my-cli',
)->login;
```

Works against Airlock, Keycloak and any other RFC 8628 server.

## Examples

`examples/` has the whole thing running: `app.psgi` (Plack) and `mojo.pl`
(Mojolicious) with a minimal approval page, `login.pl` as the device, and the
store on DBI and on DBIO.

## License

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
````

- [ ] **Step 12: Alles laufen lassen**

Run: `prove -lr t && dzil test`
Expected: beide PASS. `dzil test` prüft zusätzlich die POD-Syntax nach dem Weaving.

- [ ] **Step 13: Übergabe**

Commit-fertig lassen, Karte nach `review`. Betreff: `Add examples and README`; `Changes`: `- Examples: Plack and Mojolicious host apps, store on DBI and DBIO, device CLI`.

---

### Task 9: Keycloak: Abbildung und Live-Test

Spec: Abschnitt 7. **Diese Aufgabe braucht ein laufendes Keycloak und ist die einzige, deren Inhalt ungeprüft ist.** Wo dieses Keycloak läuft, entscheidet der Maintainer; nicht auf einer Maschine mit knappem Speicher starten. Schritte 1 bis 5 gehen ohne Keycloak, ab Schritt 6 nicht mehr.

Was hier als Annahme steht und vom Live-Test bestätigt oder widerlegt wird:

- der Aufbau von `t/keycloak/realm.json`, besonders das OTP-Credential des Nutzers `otp` und das Client-Attribut für den Device-Grant;
- dass Keycloaks Direct Grant den Parameter `totp` annimmt;
- dass ein Login mit TOTP im Token an `amr` oder `acr` erkennbar ist und die Standardwerte `mfa_amr => [qw( mfa otp hwk )]`, `mfa_acr => []` dafür passen.

**Files:**
- Create: `lib/Airlock/Upstream/Keycloak.pm`
- Create: `t/keycloak/realm.json`, `t/keycloak/README.md`
- Test: `t/45-upstream-keycloak.t`, `t/90-live-keycloak.t`
- Modify: `t/00-load.t`

**Interfaces:**
- Consumes: `Airlock::Factor::Upstream->new( accept_amr =>, accept_acr =>, max_age =>, now => )` und `Airlock::Factor::TOTP->code_at` (Aufgabe 4); `Airlock::Client` mit `issuer`, `->device_endpoint`, `->token_endpoint`, `->start`, `->poll` (Aufgabe 7).
- Produces: `Airlock::Upstream::Keycloak->new( mfa_amr => [...], mfa_acr => [...] )`; `->subject(\%claims)` → `{ id, amr, acr, auth_time }`; `->factor(%upstream_opts)` → `Airlock::Factor::Upstream`.

- [ ] **Step 1: Den Unit-Test schreiben**

`t/45-upstream-keycloak.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Airlock::Upstream::Keycloak;

my $keycloak = Airlock::Upstream::Keycloak->new;

subtest 'subject' => sub {
  is_deeply(
    $keycloak->subject( { sub => 'f:1234:alice', amr => [qw( pwd otp )], acr => '1', auth_time => 1700000000, email => 'a@example.org' } ),
    { id => 'f:1234:alice', amr => [qw( pwd otp )], acr => '1', auth_time => 1700000000 },
    'sub, amr, acr and auth_time are taken, nothing else'
  );
  is_deeply( $keycloak->subject( { sub => 'x' } ), { id => 'x', amr => [], acr => undef, auth_time => undef }, 'a token without the optional claims' );
  is_deeply( $keycloak->subject( { sub => 'x', amr => 'pwd otp' } )->{amr}, [qw( pwd otp )], 'amr as a string is split' );
  my $claims = { sub => 'x', amr => ['pwd'] };
  push @{ $keycloak->subject($claims)->{amr} }, 'otp';
  is_deeply( $claims->{amr}, ['pwd'], 'the claims are not modified through the subject' );
  for my $bad ( undef, {}, { sub => '' }, 'x' ) {
    ok( !eval { $keycloak->subject($bad); 1 }, 'claims without sub croak' );
  }
};

subtest 'factor' => sub {
  my $factor = $keycloak->factor( max_age => 300, now => sub { 1000 } );
  isa_ok( $factor, 'Airlock::Factor::Upstream' );
  is( $factor->name, 'upstream', 'name' );
  is( $factor->max_age, 300, 'options are passed on' );
  is( $factor->verify( $keycloak->subject( { sub => 'x', amr => ['otp'], auth_time => 900 } ) ), 1, 'holds for a login with a second factor' );
  is( $factor->verify( $keycloak->subject( { sub => 'x', amr => ['pwd'], auth_time => 900 } ) ), 0, 'not for a password login' );

  my $by_acr = Airlock::Upstream::Keycloak->new( mfa_amr => [], mfa_acr => ['2'] )->factor;
  is( $by_acr->verify( { id => 'x', acr => '2' } ), 1, 'mfa_acr configures the factor' );
  is( $by_acr->verify( { id => 'x', acr => '1', amr => ['otp'] } ), 0, 'and mfa_amr can be emptied' );
};

done_testing;
```

- [ ] **Step 2: Test laufen lassen, er muss scheitern**

Run: `prove -lr t/45-upstream-keycloak.t`
Expected: FAIL mit `Can't locate Airlock/Upstream/Keycloak.pm in @INC`.

- [ ] **Step 3: `lib/Airlock/Upstream/Keycloak.pm` schreiben**

`lib/Airlock/Upstream/Keycloak.pm`:

```perl
package Airlock::Upstream::Keycloak;

# ABSTRACT: Use a Keycloak login as the subject of an Airlock approval

use Moo;
use Airlock::Factor::Upstream;
use Carp qw( croak );
use Types::Standard qw( ArrayRef Str );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $keycloak = Airlock::Upstream::Keycloak->new;

    my $airlock = Airlock->new(
      policy  => { always => ['upstream'] },
      factors => [ $keycloak->factor( max_age => 300 ) ],
      ...
    );

    # in the approval action, with the claims of the person's ID token
    my $result = $airlock->approve( $code, subject => $keycloak->subject($claims) );

=description

When the host application logs people in through Keycloak, this class turns
the token claims into the subject L<Airlock> wants, and builds the
L<Airlock::Factor::Upstream> that recognises a Keycloak login with a second
factor.

=cut

has mfa_amr => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [qw( mfa otp hwk )] }
);

=attr mfa_amr

C<amr> values that mean a second factor was used.

=cut

has mfa_acr => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [] }
);

=attr mfa_acr

C<acr> values that mean a second factor was used.

=cut

sub factor_class { 'Airlock::Factor::Upstream' }

sub subject {
  my ( $self, $claims ) = @_;
  croak __PACKAGE__.'->subject needs claims with a sub'
    unless ref $claims eq 'HASH' && defined $claims->{sub} && length $claims->{sub};
  my $amr = $claims->{amr};
  return {
    id        => $claims->{sub},
    amr       => ref $amr eq 'ARRAY' ? [@$amr] : defined $amr ? [ split ' ', $amr ] : [],
    acr       => $claims->{acr},
    auth_time => $claims->{auth_time}
  };
}

=method subject

    my $subject = $keycloak->subject($claims);

The Airlock subject for a set of token claims: C<id> from C<sub>, and C<amr>,
C<acr> and C<auth_time> as Keycloak sent them. Croaks without C<sub>.

=cut

sub factor {
  my ( $self, %arg ) = @_;
  return $self->factor_class->new( accept_amr => $self->mfa_amr, accept_acr => $self->mfa_acr, %arg );
}

=method factor

    my $factor = $keycloak->factor( max_age => 300 );

An L<Airlock::Factor::Upstream> that holds for a Keycloak login with a second
factor. Takes its options.

=cut

1;
```

- [ ] **Step 4: Unit-Test laufen lassen, Modul in den Load-Test**

Run: `prove -lr t/45-upstream-keycloak.t` — Expected: PASS (2 Subtests). Dann `  Airlock::Upstream::Keycloak` in die Liste in `t/00-load.t` und `prove -lr t` — Expected: PASS.

- [ ] **Step 5: Realm, Anleitung und Live-Test schreiben**

`t/keycloak/realm.json`:

```json
{
  "realm": "airlock-test",
  "enabled": true,
  "clients": [
    {
      "clientId": "airlock-test-cli",
      "publicClient": true,
      "standardFlowEnabled": false,
      "directAccessGrantsEnabled": true,
      "attributes": {
        "oauth2.device.authorization.grant.enabled": "true"
      }
    }
  ],
  "users": [
    {
      "username": "plain",
      "enabled": true,
      "email": "plain@example.org",
      "emailVerified": true,
      "firstName": "Plain",
      "lastName": "User",
      "credentials": [
        { "type": "password", "value": "plain-password", "temporary": false }
      ]
    },
    {
      "username": "otp",
      "enabled": true,
      "email": "otp@example.org",
      "emailVerified": true,
      "firstName": "Otp",
      "lastName": "User",
      "credentials": [
        { "type": "password", "value": "otp-password", "temporary": false },
        {
          "type": "otp",
          "secretData": "{\"value\":\"12345678901234567890\"}",
          "credentialData": "{\"subType\":\"totp\",\"digits\":6,\"counter\":0,\"period\":30,\"algorithm\":\"HmacSHA1\"}"
        }
      ]
    }
  ]
}
```

`t/keycloak/README.md`:

````markdown
# Keycloak live test

`t/90-live-keycloak.t` runs only when `TEST_AIRLOCK_KEYCLOAK_URL` is set. It
needs a Keycloak with the realm `airlock-test` from `realm.json` in this
directory: a public client `airlock-test-cli` with the device authorization
grant and direct access grants enabled, a user `plain` with a password, and a
user `otp` with a password and a TOTP credential whose secret is the RFC 6238
test secret `12345678901234567890`.

## Start a throwaway Keycloak

```bash
docker run --rm --name airlock-keycloak -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  -v "$PWD/t/keycloak/realm.json:/opt/keycloak/data/import/realm.json:ro" \
  quay.io/keycloak/keycloak:latest start-dev --import-realm
```

Keycloak needs about 1 GB of memory. Do not start it on a machine that is
already short of it.

## Run

```bash
TEST_AIRLOCK_KEYCLOAK_URL=http://localhost:8080 prove -lv t/90-live-keycloak.t
```

## Findings

Recorded by whoever ran the test last. The `diag` lines of the test print
what to copy here.

| Keycloak version | Login | acr | amr | auth_time |
|---|---|---|---|---|
````

`t/90-live-keycloak.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Live test against a real Keycloak. Off unless TEST_AIRLOCK_KEYCLOAK_URL is
# set to its base URL (for example http://localhost:8080) and the realm from
# t/keycloak/realm.json is imported. See t/keycloak/README.md.

BEGIN {
  plan skip_all => 'set TEST_AIRLOCK_KEYCLOAK_URL to run the Keycloak live test'
    unless $ENV{TEST_AIRLOCK_KEYCLOAK_URL};
}

use HTTP::Tiny;
use JSON::MaybeXS;
use MIME::Base64 qw( decode_base64url );
use Airlock::Client;
use Airlock::Factor::TOTP;
use Airlock::Upstream::Keycloak;

my $issuer = $ENV{TEST_AIRLOCK_KEYCLOAK_URL} =~ s{/+\z}{}r.'/realms/airlock-test';
my $http   = HTTP::Tiny->new( timeout => 20 );

sub claims {
  my ( $jwt ) = @_;
  return decode_json( decode_base64url( ( split /\./, $jwt )[1] ) );
}

sub password_login {
  my ( $token_endpoint, %form ) = @_;
  my $response = $http->post_form( $token_endpoint, { grant_type => 'password', client_id => 'airlock-test-cli', scope => 'openid', %form } );
  ok( $response->{success}, 'direct grant for '.$form{username} ) or diag $response->{content};
  return decode_json( $response->{content} );
}

my $client = Airlock::Client->new(
  issuer    => $issuer,
  client_id => 'airlock-test-cli',
  scope     => 'openid',
  sleep     => sub { sleep 1 },
  on_prompt => sub { }
);

subtest 'the client runs against Keycloak\'s device endpoint' => sub {
  like( $client->device_endpoint, qr{\Ahttp}, 'discovery finds the device authorization endpoint' );
  my $start = $client->start;
  ok( length $start->{device_code}, 'device_code' );
  ok( length $start->{user_code},   'user_code' );
  like( $start->{verification_uri}, qr{\Ahttp}, 'verification_uri' );
  diag 'Keycloak device response keys: '.join( ', ', sort keys %$start );

  # Nobody approves in this test. A poll that outlives a short deadline proves
  # Keycloak answered authorization_pending (and slow_down, if it did) the way
  # the client expects; any other answer would croak with "poll failed".
  ok( !eval { $client->poll( { %$start, interval => 1, expires_in => 3 } ); 1 }, 'polling without approval ends' );
  like( $@, qr/the code expired before anyone approved it/, 'because the code ran out, not because of an unexpected answer' );
};

subtest 'what Keycloak says about a login with and without a second factor' => sub {
  my $keycloak = Airlock::Upstream::Keycloak->new;
  my $factor   = $keycloak->factor;
  my $totp     = Airlock::Factor::TOTP->new( secret => sub { }, last_step => sub { }, accept_step => sub { } );

  my $plain = password_login( $client->token_endpoint, username => 'plain', password => 'plain-password' );
  my $otp   = password_login(
    $client->token_endpoint,
    username => 'otp',
    password => 'otp-password',
    totp     => $totp->code_at( '12345678901234567890', int( time / 30 ) )
  );

  for my $case ( [ plain => $plain ], [ otp => $otp ] ) {
    my ( $name, $tokens ) = @$case;
    for my $kind (qw( id_token access_token )) {
      next unless $tokens->{$kind};
      my $claims = claims( $tokens->{$kind} );
      diag $name.' '.$kind.': acr='.( $claims->{acr} // '(none)' ).' amr='.( ref $claims->{amr} ? join( ',', @{ $claims->{amr} } ) : $claims->{amr} // '(none)' ).' auth_time='.( $claims->{auth_time} // '(none)' );
    }
  }

  my $plain_subject = $keycloak->subject( claims( $plain->{id_token} ) );
  my $otp_subject   = $keycloak->subject( claims( $otp->{id_token} ) );
  ok( length $plain_subject->{id}, 'the subject has an id' );
  isnt( $plain_subject->{id}, $otp_subject->{id}, 'two users, two ids' );
  is( $factor->verify($plain_subject), 0, 'a password login does not satisfy the upstream factor' );
  is( $factor->verify($otp_subject),   1, 'a login with TOTP does' );
};

done_testing;
```

Run: `prove -lr t/90-live-keycloak.t` — Expected: `skipped: set TEST_AIRLOCK_KEYCLOAK_URL to run the Keycloak live test`.

- [ ] **Step 6: Keycloak starten und den Realm importieren**

Nach `t/keycloak/README.md`, mit einer festen Versions-Markierung statt `latest`; die Version in die Findings-Tabelle eintragen.
Expected: Das Log meldet den Import des Realms `airlock-test` ohne Fehler, und `curl -s $URL/realms/airlock-test/.well-known/openid-configuration` liefert JSON mit `device_authorization_endpoint`.

Wenn der Import scheitert: `realm.json` gegen die Dokumentation genau dieser Keycloak-Version korrigieren (Abschnitt „Importing a realm“ und das Export-Format eines von Hand angelegten Realms sind die Referenz). Am sichersten: Client und Nutzer in der Admin-Konsole anlegen, Realm exportieren, die Datei darauf zurechtschneiden.

- [ ] **Step 7: Live-Test laufen lassen und lesen**

Run: `TEST_AIRLOCK_KEYCLOAK_URL=http://localhost:8080 prove -lv t/90-live-keycloak.t`
Expected: Der erste Subtest ist PASS; das ist der Nachweis, dass `Airlock::Client` gegen Keycloaks Device-Endpunkt läuft. Im zweiten Subtest drucken die `diag`-Zeilen `acr`, `amr` und `auth_time` für beide Nutzer, je aus ID- und Access-Token.

- [ ] **Step 8: Die Abbildung an den Befund anpassen**

Die `diag`-Zeilen in die Findings-Tabelle in `t/keycloak/README.md` übertragen. Dann drei Fälle:

1. Der OTP-Login trägt ein `amr` aus `mfa`/`otp`/`hwk`, der Passwort-Login nicht: die Standardwerte stimmen, nichts ändern.
2. Der Unterschied liegt in `acr` (oder in anderen `amr`-Werten): die Standardwerte von `mfa_acr` beziehungsweise `mfa_amr` in `lib/Airlock/Upstream/Keycloak.pm` auf die beobachteten Werte setzen, in der POD der beiden Attribute Keycloak-Version und beobachtete Werte nennen, und den Subtest `factor` in `t/45-upstream-keycloak.t` um einen Fall mit genau diesen Claims ergänzen.
3. Die Tokens beider Logins sind an `acr` und `amr` nicht zu unterscheiden: Keycloak liefert die Information in der Standardkonfiguration nicht. Dann nichts raten. Als Notiz auf die Karte, was beobachtet wurde; der Maintainer entscheidet, ob der Test-Realm einen Mapper oder Step-up-Flow bekommt. Die beiden letzten Assertions des Live-Tests bleiben rot, bis das geklärt ist.

- [ ] **Step 9: Alles laufen lassen**

Run: `prove -lr t && TEST_AIRLOCK_KEYCLOAK_URL=http://localhost:8080 prove -lv t/90-live-keycloak.t && dzil test`
Expected: alles PASS (in Fall 3 des vorigen Schritts mit den zwei bekannten roten Assertions im Live-Test, auf der Karte vermerkt).

- [ ] **Step 10: Übergabe**

Commit-fertig lassen, Karte nach `review`, mit Keycloak-Version und Befund in der Notiz. Betreff: `Add Keycloak subject mapping and live test`; `Changes`: `- Airlock::Upstream::Keycloak: Keycloak token claims as Airlock subject; live test behind TEST_AIRLOCK_KEYCLOAK_URL`.
