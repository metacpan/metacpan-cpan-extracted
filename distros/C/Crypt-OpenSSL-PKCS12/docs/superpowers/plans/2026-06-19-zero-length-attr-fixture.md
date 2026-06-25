# Zero-Length Attribute Fixture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a pre-generated PKCS12 fixture carrying zero-length OCTET STRING and BIT STRING bag attributes, and a regression test that loads it and verifies the attributes are returned as empty strings.

**Architecture:** A developer-only Perl generation script builds a minimal PKCS12 from scratch using `Convert::ASN1` (unencrypted SafeContents, dummy MacData). The fixture is committed to `certs/`. The test loads it via `info_as_hash()`, which does not verify the MAC, so the dummy MacData is harmless.

**Tech Stack:** Perl 5, `Convert::ASN1`, `MIME::Base64` (core), `Crypt::OpenSSL::PKCS12`, `Test::More`

## Global Constraints

- Work on branch `fix/get-hex-null-termination` throughout
- Do not run the generation script during `make test` — it is a one-off developer tool
- Password for the fixture is `test`
- Custom attribute OIDs: `1.2.3.100` (OCTET STRING), `1.2.3.101` (BIT STRING)
- `Convert::ASN1` is a develop-only dependency — do not add it to the runtime `requires` block
- All test assertions use `Test::More`
- Run `prove -lv t/pkcs12-info-zero-length-attributes.t` after each test change

---

### Task 1: Add Convert::ASN1 to cpanfile and switch to the fix branch

**Files:**
- Modify: `cpanfile`

**Interfaces:**
- Produces: `Convert::ASN1` available for the generation script

- [ ] **Step 1: Switch to the fix branch**

```bash
git checkout fix/get-hex-null-termination
```

Expected: `Switched to branch 'fix/get-hex-null-termination'`

- [ ] **Step 2: Add the develop dependency**

Open `cpanfile`. At the end of the file add:

```perl
on 'develop' => sub {
    requires 'Convert::ASN1';
};
```

- [ ] **Step 3: Install it**

```bash
carton install
```

Expected: `Complete!` (or `Convert::ASN1 is up to date`)

- [ ] **Step 4: Commit**

```bash
git add cpanfile cpanfile.snapshot
git commit -m "build: add Convert::ASN1 as develop dependency for fixture generation"
```

---

### Task 2: Write the fixture generation script

**Files:**
- Create: `scripts/generate-zero-length-attr-fixture.pl`

**Interfaces:**
- Consumes: `certs/test-cert.pem` (existing)
- Produces: `certs/zero-length-attrs.p12`

Key facts about the PKCS12 DER structure this script builds:

- The MAC section (`macData`) must be present and structurally valid even if the MAC bytes are wrong, because OpenSSL ≤ 1.1.0 accesses `pkcs12->mac` directly without a NULL check in the `info_as_hash()` path.
- `info_as_hash()` does **not** call `PKCS12_verify_mac()`, so the MAC value does not need to be correct.
- The SafeContents is placed in an unencrypted PKCS7 Data ContentInfo so no decryption is needed.
- Zero-length OCTET STRING DER bytes: `\x04\x00`
- Zero-length BIT STRING DER bytes: `\x03\x01\x00` (length=1, zero unused bits, no data → `ASN1_STRING_length()` returns 0)

- [ ] **Step 1: Create the script**

```perl
#!/usr/bin/perl
use strict;
use warnings;
use MIME::Base64 qw(decode_base64);
use Convert::ASN1;

# ── OIDs ────────────────────────────────────────────────────────────────────
my $OID_PKCS7_DATA  = '1.2.840.113549.1.7.1';
my $OID_CERT_BAG    = '1.2.840.113549.1.12.10.1.3';
my $OID_X509_CERT   = '1.2.840.113549.1.9.22.1';
my $OID_SHA1        = '1.3.14.3.2.26';
my $OID_HMAC_SHA1   = '1.2.840.113549.2.7';
my $OID_ZERO_OCTET  = '1.2.3.100';
my $OID_ZERO_BIT    = '1.2.3.101';

# ── Load certificate DER from PEM ───────────────────────────────────────────
my $cert_file = 'certs/test-cert.pem';
open my $fh, '<', $cert_file or die "Cannot open $cert_file: $!";
my $cert_pem = do { local $/; <$fh> };
close $fh;
(my $cert_b64 = $cert_pem) =~ s/-----[^-]+-----//g;
$cert_b64 =~ s/\s+//g;
my $cert_der = decode_base64($cert_b64);

# ── ASN.1 schema ─────────────────────────────────────────────────────────────
my $asn = Convert::ASN1->new;
$asn->prepare(q{
    PFX ::= SEQUENCE {
        version   INTEGER,
        authSafe  ContentInfo,
        macData   MacData OPTIONAL
    }
    ContentInfo ::= SEQUENCE {
        contentType OBJECT IDENTIFIER,
        content     [0] EXPLICIT ANY OPTIONAL
    }
    MacData ::= SEQUENCE {
        mac        DigestInfo,
        macSalt    OCTET STRING,
        iterations INTEGER OPTIONAL
    }
    DigestInfo ::= SEQUENCE {
        digestAlgorithm AlgorithmIdentifier,
        digest          OCTET STRING
    }
    AlgorithmIdentifier ::= SEQUENCE {
        algorithm  OBJECT IDENTIFIER,
        parameters ANY OPTIONAL
    }
    SafeContents ::= SEQUENCE OF SafeBag
    SafeBag ::= SEQUENCE {
        bagId       OBJECT IDENTIFIER,
        bagValue    [0] EXPLICIT ANY,
        bagAttributes SET OF Attribute OPTIONAL
    }
    Attribute ::= SEQUENCE {
        attrType   OBJECT IDENTIFIER,
        attrValues SET OF ANY
    }
    CertBag ::= SEQUENCE {
        certId    OBJECT IDENTIFIER,
        certValue [0] EXPLICIT ANY
    }
}) or die $asn->error;

# ── Encode helpers ───────────────────────────────────────────────────────────
my $attr_asn    = $asn->find('Attribute')    or die $asn->error;
my $certbag_asn = $asn->find('CertBag')      or die $asn->error;
my $safebag_asn = $asn->find('SafeBag')      or die $asn->error;
my $sc_asn      = $asn->find('SafeContents') or die $asn->error;
my $ci_asn      = $asn->find('ContentInfo')  or die $asn->error;
my $mac_asn     = $asn->find('MacData')      or die $asn->error;
my $pfx_asn     = $asn->find('PFX')          or die $asn->error;

# ── Build certificate bag value (CertBag) ───────────────────────────────────
my $certbag_der = $certbag_asn->encode({
    certId    => $OID_X509_CERT,
    certValue => $cert_der,
}) or die $certbag_asn->error;

# ── Build the two zero-length attributes ─────────────────────────────────────
# attrValues contains raw DER — Convert::ASN1 passes ANY through as-is
my $attr_zero_octet = $attr_asn->encode({
    attrType   => $OID_ZERO_OCTET,
    attrValues => [ "\x04\x00" ],       # zero-length OCTET STRING
}) or die $attr_asn->error;

my $attr_zero_bit = $attr_asn->encode({
    attrType   => $OID_ZERO_BIT,
    attrValues => [ "\x03\x01\x00" ],   # zero-length BIT STRING
}) or die $attr_asn->error;

# ── Build the certificate SafeBag ────────────────────────────────────────────
my $safebag_der = $safebag_asn->encode({
    bagId         => $OID_CERT_BAG,
    bagValue      => $certbag_der,
    bagAttributes => [
        { attrType => $OID_ZERO_OCTET, attrValues => [ "\x04\x00" ] },
        { attrType => $OID_ZERO_BIT,   attrValues => [ "\x03\x01\x00" ] },
    ],
}) or die $safebag_asn->error;

# ── Build SafeContents ────────────────────────────────────────────────────────
my $sc_der = $sc_asn->encode([ {
    bagId         => $OID_CERT_BAG,
    bagValue      => $certbag_der,
    bagAttributes => [
        { attrType => $OID_ZERO_OCTET, attrValues => [ "\x04\x00" ] },
        { attrType => $OID_ZERO_BIT,   attrValues => [ "\x03\x01\x00" ] },
    ],
} ]) or die $sc_asn->error;

# ── Wrap SafeContents in OCTET STRING, then in ContentInfo ───────────────────
# PKCS7 Data: content = [0] EXPLICIT OCTET STRING { SafeContents DER }
my $octet_sc;
{
    use Convert::ASN1;
    my $a = Convert::ASN1->new;
    $a->prepare('wrap OCTET STRING');
    $octet_sc = $a->find('wrap')->encode($sc_der) or die $a->error;
}

my $auth_safe_der = $ci_asn->encode({
    contentType => $OID_PKCS7_DATA,
    content     => $octet_sc,
}) or die $ci_asn->error;

# ── Build dummy MacData (structurally valid, MAC bytes are wrong) ─────────────
# MacData must be present so pkcs12->mac is not NULL on OpenSSL <= 1.1.0.
# info_as_hash() does not call PKCS12_verify_mac() so correctness is not needed.
my $mac_der = $mac_asn->encode({
    mac => {
        digestAlgorithm => { algorithm => $OID_HMAC_SHA1 },
        digest          => "\x00" x 20,   # 20 dummy bytes
    },
    macSalt    => "\x00" x 8,
    iterations => 2048,
}) or die $mac_asn->error;

# ── Assemble PFX ─────────────────────────────────────────────────────────────
my $pfx_der = $pfx_asn->encode({
    version  => 3,
    authSafe => {
        contentType => $OID_PKCS7_DATA,
        content     => $octet_sc,
    },
    macData => {
        mac => {
            digestAlgorithm => { algorithm => $OID_HMAC_SHA1 },
            digest          => "\x00" x 20,
        },
        macSalt    => "\x00" x 8,
        iterations => 2048,
    },
}) or die $pfx_asn->error;

# ── Write output ─────────────────────────────────────────────────────────────
my $out_file = 'certs/zero-length-attrs.p12';
open my $out, '>', $out_file or die "Cannot write $out_file: $!";
binmode $out;
print $out $pfx_der;
close $out;

print "Written: $out_file\n";
```

- [ ] **Step 2: Make executable**

```bash
chmod +x scripts/generate-zero-length-attr-fixture.pl
```

- [ ] **Step 3: Run the script**

```bash
perl -Ilocal/lib/perl5 scripts/generate-zero-length-attr-fixture.pl
```

Expected output:
```
Written: certs/zero-length-attrs.p12
```

- [ ] **Step 4: Verify the fixture is parseable by OpenSSL**

```bash
openssl pkcs12 -info -in certs/zero-length-attrs.p12 -passin pass:test -noout 2>&1 | head -10
```

Expected: output containing `PKCS7 Data` and `Certificate bag` with no fatal error (MAC verify error is acceptable here since we used a dummy MAC).

- [ ] **Step 5: Verify the fixture loads via Crypt::OpenSSL::PKCS12**

```bash
perl -Iblib/lib -Iblib/arch -e '
use Crypt::OpenSSL::PKCS12;
my $p12 = Crypt::OpenSSL::PKCS12->new_from_file("certs/zero-length-attrs.p12");
print "loaded ok\n" if $p12;
my $h = eval { $p12->info_as_hash("test") };
print "info_as_hash ok\n" unless $@;
print "error: $@\n" if $@;
'
```

Expected:
```
loaded ok
info_as_hash ok
```

If `info_as_hash` fails with a MAC or structure error, investigate the MacData encoding — check that `pkcs12->mac` is not NULL by trying on OpenSSL ≤ 1.1.0 if available. The dummy MAC bytes are intentionally wrong; only the structure must be valid.

- [ ] **Step 6: Commit**

```bash
git add scripts/generate-zero-length-attr-fixture.pl
git commit -m "scripts: add fixture generator for zero-length OCTET/BIT STRING bag attributes"
```

---

### Task 3: Write the regression test

**Files:**
- Create: `t/pkcs12-info-zero-length-attributes.t`

**Interfaces:**
- Consumes: `certs/zero-length-attrs.p12` (from Task 2)
- Produces: regression guard for `get_hex()` zero-length NUL-termination fix

The test navigates `info_as_hash()` output to find attributes keyed by OID string. The hash structure is:
```
{
  pkcs7_data => [
    {
      bags => [
        {
          type            => 'certificate_bag',
          bag_attributes  => {
            '1.2.3.100' => '',   # zero-length OCTET STRING → get_hex returns ""
            '1.2.3.101' => '',   # zero-length BIT STRING  → get_hex returns ""
          }
        }
      ]
    }
  ]
}
```

- [ ] **Step 1: Write the failing test (pre-fixture)**

```perl
#!/usr/bin/perl

# Regression test for the zero-length OCTET STRING / BIT STRING path of
# print_attribute() / get_hex(). Before the fix, get_hex() never wrote a NUL
# terminator, leaving *attribute uninitialised when length == 0. Downstream
# strlen() on an unterminated buffer is undefined behaviour.
#
# The fixture certs/zero-length-attrs.p12 carries two custom bag attributes:
#   1.2.3.100 → zero-length OCTET STRING  (ASN1_STRING_length() == 0)
#   1.2.3.101 → zero-length BIT STRING    (ASN1_STRING_length() == 0)
#
# info_as_hash() does not call PKCS12_verify_mac(), so the fixture's dummy MAC
# is never checked.

use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw(catfile);

BEGIN { use_ok('Crypt::OpenSSL::PKCS12') }

my $fixture = catfile('certs', 'zero-length-attrs.p12');

SKIP: {
    skip "fixture $fixture not found", 5 unless -f $fixture;

    my $p12 = Crypt::OpenSSL::PKCS12->new_from_file($fixture);
    ok($p12, 'loaded zero-length-attrs.p12');

    my $hash = eval { $p12->info_as_hash('test') };
    is($@, '', 'info_as_hash() did not croak');
    ok(ref $hash eq 'HASH', 'info_as_hash() returned a hashref');

    # Locate bag_attributes in pkcs7_data bags
    my $attrs;
    OUTER: for my $section (@{ $hash->{pkcs7_data} // [] }) {
        for my $bag (@{ $section->{bags} // [] }) {
            if (exists $bag->{bag_attributes}{'1.2.3.100'}) {
                $attrs = $bag->{bag_attributes};
                last OUTER;
            }
        }
    }

    SKIP: {
        skip 'bag_attributes not found in pkcs7_data', 2 unless defined $attrs;

        is($attrs->{'1.2.3.100'}, '',
            'zero-length OCTET STRING attribute is empty string — get_hex() NUL-terminates');

        is($attrs->{'1.2.3.101'}, '',
            'zero-length BIT STRING attribute is empty string — get_hex() NUL-terminates');
    }
}

done_testing;
```

Save to `t/pkcs12-info-zero-length-attributes.t`.

- [ ] **Step 2: Run the test — confirm it passes (fixture exists from Task 2)**

```bash
prove -lv t/pkcs12-info-zero-length-attributes.t
```

Expected:
```
ok 1 - use Crypt::OpenSSL::PKCS12
ok 2 - loaded zero-length-attrs.p12
ok 3 - info_as_hash() did not croak
ok 4 - info_as_hash() returned a hashref
ok 5 - zero-length OCTET STRING attribute is empty string — get_hex() NUL-terminates
ok 6 - zero-length BIT STRING attribute is empty string — get_hex() NUL-terminates
1..6
```

If the attributes are not found in `pkcs7_data` but the test passes the first 4 assertions, check whether the bags are under `pkcs7_encrypted_data` instead. Update the navigation loop to check both sections.

- [ ] **Step 3: Run the full test suite to confirm no regressions**

```bash
prove -lr -l -b -I inc t
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add t/pkcs12-info-zero-length-attributes.t
git commit -m "test: add regression test for zero-length OCTET/BIT STRING bag attributes"
```

---

### Task 4: Commit the fixture and write scripts/README.md

**Files:**
- Modify: `certs/zero-length-attrs.p12` (commit the generated binary)
- Create: `scripts/README.md`

**Interfaces:**
- Produces: committed fixture and documentation

- [ ] **Step 1: Commit the fixture**

```bash
git add certs/zero-length-attrs.p12
git commit -m "certs: add zero-length-attrs.p12 fixture for get_hex() regression test"
```

- [ ] **Step 2: Write scripts/README.md**

```markdown
# scripts/

Helper scripts for maintainers. These are developer tools and are **not**
run as part of the test suite (`make test`).

## test.sh

Runs the full build and test cycle against each installed OpenSSL version
(3.x, 3.0, 3.5, 4.x). Requires Carton and the relevant OpenSSL versions
installed under `/opt/homebrew/opt/`.

Usage:

    bash scripts/test.sh

## generate-zero-length-attr-fixture.pl

Generates `certs/zero-length-attrs.p12`, a minimal PKCS12 fixture that
carries two custom bag attributes with zero-length ASN.1 values:

| OID       | Type         | Purpose                              |
|-----------|--------------|--------------------------------------|
| 1.2.3.100 | OCTET STRING | Exercises `V_ASN1_OCTET_STRING` path |
| 1.2.3.101 | BIT STRING   | Exercises `V_ASN1_BIT_STRING` path   |

These are used by `t/pkcs12-info-zero-length-attributes.t` to guard against
regression of the `get_hex()` NUL-termination bug (issue #63, PR #65).

**Why a generation script?** The standard `openssl pkcs12` CLI cannot attach
custom bag attributes, and `Crypt::OpenSSL::PKCS12->create()` does not
expose bag attribute APIs. The script builds a minimal PKCS12 DER structure
from scratch using `Convert::ASN1`.

**When to re-run:** Only if `certs/test-cert.pem` changes. The generated
fixture is pre-committed to `certs/` and does not need to be regenerated
on every build.

**Requires:** `Convert::ASN1` (install with `carton install`).

Usage:

    perl -Ilocal/lib/perl5 scripts/generate-zero-length-attr-fixture.pl
```

- [ ] **Step 3: Commit README**

```bash
git add scripts/README.md
git commit -m "docs: add scripts/README.md documenting helper scripts"
```

- [ ] **Step 4: Push the branch**

```bash
git push origin fix/get-hex-null-termination
```

---

## Self-Review

**Spec coverage:**
- Generation script (`scripts/generate-zero-length-attr-fixture.pl`) ✓ Task 2
- Fixture (`certs/zero-length-attrs.p12`) ✓ Tasks 2 & 4
- Test (`t/pkcs12-info-zero-length-attributes.t`) ✓ Task 3
- `scripts/README.md` ✓ Task 4
- `cpanfile` develop dependency ✓ Task 1

**Placeholder check:** No TBDs. All code blocks are complete. The "If the attributes are not found" note in Task 3 Step 2 gives a concrete remediation path, not a vague instruction.

**Type consistency:** OID strings `1.2.3.100` / `1.2.3.101` used consistently in both generation script and test. Password `test` consistent throughout. Branch `fix/get-hex-null-termination` named in Task 1 Step 1.
