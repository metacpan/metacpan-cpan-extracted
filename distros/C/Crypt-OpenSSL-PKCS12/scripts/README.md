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
