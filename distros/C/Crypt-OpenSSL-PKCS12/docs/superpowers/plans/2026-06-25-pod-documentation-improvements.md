# POD Documentation Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all identified issues in the POD documentation of `PKCS12.pm` and ship them as a pull request.

**Architecture:** Primary changes are confined to the `__END__` POD section of `PKCS12.pm`. No XS or Perl logic is touched. The branch is `docs/pod-improvements`.

**Tech Stack:** Perl POD, `perldoc`, `git`, `gh` CLI.

## Global Constraints

- Primary changes are in `PKCS12.pm` (POD section only — nothing above `__END__`); this plan document is also part of the PR
- `$VERSION` on line 7 must remain `1.97` — do not change it
- The version string *inside the POD* (currently `1.95`) must be updated to match `1.97`
- All existing POD headings must be preserved; add content, do not restructure
- Commit messages follow the pattern already in `git log`: short imperative subject line
- PR targets `master`

---

## File Map

| File | Action |
|------|--------|
| `PKCS12.pm` | Modify POD section only (lines 22–398) |

---

### Task 1: Create branch and fix typos + SYNOPSIS

**Files:**
- Modify: `PKCS12.pm` (POD section)

**Interfaces:**
- Produces: clean SYNOPSIS with no syntax errors; zero typos in method entries

- [ ] **Step 1: Create the working branch**

```bash
git checkout -b docs/pod-improvements
```

- [ ] **Step 2: Fix the version string in the POD**

In `PKCS12.pm`, find line 60:
```
This documentation describes version 1.95 of Crypt::OpenSSL::PKCS12
```
Change to:
```
This documentation describes version 1.97 of Crypt::OpenSSL::PKCS12
```

- [ ] **Step 3: Fix the three typos in method entries**

| Location | Wrong | Correct |
|----------|-------|---------|
| `as_string()` entry | `represenation` | `representation` |
| `mac_ok()` entry | `Verifiy` | `Verify` |
| SYNOPSIS | `$pksc12_data` | `$pkcs12_data` |

- [ ] **Step 4: Fix the unclosed `if` block in SYNOPSIS**

Current SYNOPSIS (partial):
```perl
  if ($pkcs12->mac_ok($pass)) {
  ...

  # Creating a file
```
Replace with:
```perl
  if ($pkcs12->mac_ok($pass)) {
    # MAC verification passed
  }

  # Creating a file
```

- [ ] **Step 5: Verify POD parses cleanly**

```bash
perl -c PKCS12.pm
perldoc PKCS12.pm | head -60
```
Expected: no errors; SYNOPSIS renders without broken block.

- [ ] **Step 6: Commit**

```bash
git add PKCS12.pm
git commit -m "docs: fix POD version string, typos, and SYNOPSIS syntax"
```

---

### Task 2: Document thin/empty method stubs

**Files:**
- Modify: `PKCS12.pm` (POD section, `SUBROUTINES/METHODS` list)

**Interfaces:**
- Consumes: clean POD from Task 1
- Produces: `new()`, `new_from_string()`, `new_from_file()`, `legacy_support()` all have meaningful descriptions

- [ ] **Step 1: Expand `new()`**

Find:
```pod
=item * new( )
```
Replace with:
```pod
=item * new( )

Create an empty Crypt::OpenSSL::PKCS12 object. Use C<new_from_string()> or
C<new_from_file()> to load an existing PKCS12 structure.
```

- [ ] **Step 2: Expand `legacy_support()`**

Find:
```pod
=item * legacy_support ( )

Check whether the openssl version installed supports the legacy provider.
```
Replace with:
```pod
=item * legacy_support ( )

Returns true if the installed OpenSSL version supports the legacy provider
(required for older cipher suites such as RC2). Always returns false on
OpenSSL 1.x, where providers do not exist. On OpenSSL 3.x, returns true
only when the legacy provider can be loaded at runtime.
```

- [ ] **Step 3: Expand `new_from_string()` and `new_from_file()`**

Find:
```pod
=item * new_from_string( C<$string> )

=item * new_from_file( C<$filename> )

Create a new Crypt::OpenSSL::PKCS12 instance.
```
Replace with:
```pod
=item * new_from_string( C<$string> )

=item * new_from_file( C<$filename> )

Create a new Crypt::OpenSSL::PKCS12 instance from a binary PKCS12 string or
from a file path respectively. Both forms croak on error (invalid format,
unreadable file, OpenSSL parse failure).
```

- [ ] **Step 4: Verify rendering**

```bash
perldoc PKCS12.pm | grep -A5 "new_from_file"
```
Expected: description paragraph appears after the item.

- [ ] **Step 5: Commit**

```bash
git add PKCS12.pm
git commit -m "docs: expand new(), new_from_string/file(), and legacy_support() POD"
```

---

### Task 3: Document certificate/key methods and `changepass`

**Files:**
- Modify: `PKCS12.pm` (POD section)

**Interfaces:**
- Consumes: POD from Task 2
- Produces: `certificate()`, `ca_certificate()`, `private_key()`, `as_string()`, `mac_ok()`, `changepass()` all document return format, password parameter behaviour, and known caveats

- [ ] **Step 1: Expand `certificate()` and `ca_certificate()`**

Find:
```pod
=item * certificate( [C<$pass>] )

Get the Base64 representation of the certificate.

=item * ca_certificate( [C<$pass>] )

Get the Base64 representation of the CA certificate chain.
```
Replace with:
```pod
=item * certificate( [C<$pass>] )

Returns the end-entity certificate as a PEM-encoded string (Base64 with
C<-----BEGIN CERTIFICATE----->/ C<-----END CERTIFICATE-----> headers).
C<$pass> is required when the PKCS12 file is password-protected. Croaks on
wrong password or missing certificate.

=item * ca_certificate( [C<$pass>] )

Returns any CA certificates in the chain as a concatenated PEM string.
Returns C<undef> if no CA certificates are present. C<$pass> is required
when the PKCS12 file is password-protected.
```

- [ ] **Step 2: Expand `private_key()`**

Find:
```pod
=item * private_key( [C<$pass>] )

Get the Base64 representation of the private key.
```
Replace with:
```pod
=item * private_key( [C<$pass>] )

Returns the private key as a PEM-encoded string. C<$pass> is required when
the PKCS12 file is password-protected. Croaks if no private key is present
or if decryption fails.
```

- [ ] **Step 3: Expand `as_string()`**

Find:
```pod
=item * as_string( [C<$pass>] )

Get the binary represenation as a string.
```
(Note: the typo `represenation` was already fixed in Task 1; this step expands the content.)

Replace the full item with:
```pod
=item * as_string( [C<$pass>] )

Returns the PKCS12 structure as a raw binary DER string. Useful for writing
to a file or transmitting over a network without touching the filesystem.
C<$pass> is required when the structure is password-protected.
```

- [ ] **Step 4: Expand `mac_ok()`**

Find:
```pod
=item * mac_ok( [C<$pass>] )

Verifiy the certificates Message Authentication Code
```
(Note: typo fixed in Task 1.)

Replace with:
```pod
=item * mac_ok( [C<$pass>] )

Verifies the Message Authentication Code (MAC) of the PKCS12 structure using
C<$pass>. Returns true if the MAC is valid, false otherwise. A failed MAC
usually indicates a wrong password or a corrupted file.
```

- [ ] **Step 5: Expand `changepass()`**

Find:
```pod
=item * changepass( C<$old>, C<$new> )

Change a certificate's password.
```
Replace with:
```pod
=item * changepass( C<$old>, C<$new> )

Re-encrypts the PKCS12 structure with a new password. C<$old> is the current
password; C<$new> is the replacement. Croaks on failure.

B<Note:> This method is not supported on OpenSSL 3.x and will croak if
called. Use OpenSSL 1.x or migrate to creating a new PKCS12 structure with
C<create()>.
```

- [ ] **Step 6: Verify rendering**

```bash
perldoc PKCS12.pm | grep -A8 "changepass"
```
Expected: note about OpenSSL 3.x appears.

- [ ] **Step 7: Commit**

```bash
git add PKCS12.pm
git commit -m "docs: document certificate, private_key, mac_ok, changepass methods"
```

---

### Task 4: Document `create`, `create_as_string`, `info`, `info_as_hash`

**Files:**
- Modify: `PKCS12.pm` (POD section)

**Interfaces:**
- Consumes: POD from Task 3
- Produces: all four methods document return values; `info_as_hash()` explains dualvar

- [ ] **Step 1: Expand `create()`**

Find:
```pod
=item * create( C<$cert>, C<$key>, C<$pass>, C<$output_file>, C<$friendly_name> )

Create a new PKCS12 certificate. $cert & $key may either be strings or filenames.

C<$friendly_name> is optional.
```
Replace with:
```pod
=item * create( C<$cert>, C<$key>, C<$pass>, C<$output_file>, C<$friendly_name> )

Creates a new PKCS12 file at C<$output_file>. C<$cert> and C<$key> may each be
either a PEM string (detected by a C<"-----"> prefix) or a filesystem path.
C<$pass> is used to encrypt the private key. C<$friendly_name> is optional and
sets the C<friendlyName> bag attribute. Croaks on any OpenSSL error.
```

- [ ] **Step 2: Expand `create_as_string()`**

Find:
```pod
=item * create_as_string( C<$cert>, C<$key>, C<$pass>, C<$friendly_name> )

Create a new PKCS12 certificate string. $cert & $key may either be strings or filenames.

C<$friendly_name> is optional.

Returns a string holding the PKCS12 certicate.
```
Replace with:
```pod
=item * create_as_string( C<$cert>, C<$key>, C<$pass>, C<$friendly_name> )

Same as C<create()> but returns the PKCS12 structure as a raw binary DER string
instead of writing to a file. C<$cert> and C<$key> may each be a PEM string or
a filesystem path. C<$friendly_name> is optional. Croaks on any OpenSSL error.
```

- [ ] **Step 3: Add dualvar explanation to `info_as_hash()`**

Find the paragraph that begins:
```
                            localKeyID     "..." (dualvar: 54)
```
After the closing `}` of the hash example and before `=back`, add:

```pod
Attributes such as C<localKeyID> are returned as B<dualvars>: in string
context they yield a hex digest (e.g. C<"54">), and in numeric context they
yield the integer value (e.g. C<54>). Use C<Scalar::Util::dualvar> if you
need to construct one yourself.
```

- [ ] **Step 4: Verify rendering**

```bash
perldoc PKCS12.pm | grep -A6 "dualvar"
```
Expected: explanation paragraph visible.

- [ ] **Step 5: Commit**

```bash
git add PKCS12.pm
git commit -m "docs: document create, create_as_string, info_as_hash dualvar"
```

---

### Task 5: Update EXPORTS, DIAGNOSTICS, DEPENDENCIES, SEE ALSO

**Files:**
- Modify: `PKCS12.pm` (POD section)

**Interfaces:**
- Consumes: POD from Task 4
- Produces: all four sections have accurate, non-placeholder content

- [ ] **Step 1: Document the exported constants**

Find the EXPORTS section:
```pod
On request:

=over 4

=item * C<NOKEYS>

=item * C<NOCERTS>

=item * C<INFO>

=item * C<CLCERTS>

=item * C<CACERTS>

=back
```
Replace with:
```pod
On request:

=over 4

=item * C<NOKEYS>

Flag: suppress output of private keys.

=item * C<NOCERTS>

Flag: suppress output of certificates.

=item * C<INFO>

Flag: print info about the PKCS12 file to C<STDOUT>.

=item * C<CLCERTS>

Flag: output only client (end-entity) certificates.

=item * C<CACERTS>

Flag: output only CA certificates.

=back

These flags mirror the corresponding C<-nokeys>, C<-nocerts>, C<-info>,
C<-clcerts>, and C<-cacerts> options of the C<openssl pkcs12> command.
```

- [ ] **Step 2: Populate DIAGNOSTICS**

Find:
```pod
=head1 DIAGNOSTICS

No diagnostics are documented at this time
```
Replace with:
```pod
=head1 DIAGNOSTICS

=over 4

=item * B<"OpenSSL error: ..."> — an OpenSSL call failed. The trailing
message is taken from C<ERR_reason_error_string()> and identifies the
specific failure (e.g. C<"bad decrypt"> for a wrong password).

=item * B<"Error opening ..."> — C<new_from_file()> could not open the
specified file path.

=item * B<"changepass is not supported on OpenSSL 3"> — C<changepass()>
was called on a system running OpenSSL 3.x. Use OpenSSL 1.x or recreate
the PKCS12 structure.

=back
```

- [ ] **Step 3: Update DEPENDENCIES minimum Perl version**

Find:
```pod
=item * Perl 5.8
```
Replace with:
```pod
=item * Perl 5.14
```

- [ ] **Step 4: Update the stale OpenSSL SEE ALSO link**

Find:
```pod
=item * OpenSSL(1) (L<HTTP version with OpenSSL.org|https://www.openssl.org/docs/man1.1.1/man1/openssl.html>)
```
Replace with:
```pod
=item * OpenSSL(1) (L<HTTP version with OpenSSL.org|https://www.openssl.org/docs/manmaster/man1/openssl.html>)
```

- [ ] **Step 5: Verify full POD renders without warnings**

```bash
perl -c PKCS12.pm && perldoc PKCS12.pm | wc -l
```
Expected: no errors; line count > 200.

- [ ] **Step 6: Commit**

```bash
git add PKCS12.pm
git commit -m "docs: update EXPORTS descriptions, DIAGNOSTICS, DEPENDENCIES, SEE ALSO"
```

---

### Task 6: Open the pull request

**Files:**
- No file changes — uses `gh` CLI only.

**Interfaces:**
- Consumes: branch `docs/pod-improvements` with all four prior task commits

- [ ] **Step 1: Push the branch**

```bash
git push -u origin docs/pod-improvements
```

- [ ] **Step 2: Review the full diff one last time**

```bash
git diff master..docs/pod-improvements -- PKCS12.pm
```
Verify: only POD lines changed; no Perl or XS logic touched.

- [ ] **Step 3: Open the PR**

```bash
gh pr create \
  --title "docs: improve POD documentation in PKCS12.pm" \
  --body "$(cat <<'EOF'
## Summary

- Bump version string in POD from 1.95 to 1.97 (matches \`\$VERSION\`)
- Fix three typos: \`represenation\`, \`Verifiy\`, \`\$pksc12_data\`
- Fix unclosed \`if\` block in SYNOPSIS
- Expand empty/thin method stubs: \`new()\`, \`new_from_string/file()\`, \`legacy_support()\`
- Document return formats and error behaviour for all certificate/key methods
- Add OpenSSL 3.x caveat to \`changepass()\`
- Document exported constants (\`NOKEYS\`, \`NOCERTS\`, \`INFO\`, \`CLCERTS\`, \`CACERTS\`)
- Populate DIAGNOSTICS with common error messages
- Update minimum Perl version in DEPENDENCIES to 5.14
- Update stale OpenSSL SEE ALSO link to \`manmaster\`
- Explain dualvar behaviour in \`info_as_hash()\` output

## Test plan

- [ ] \`perl -c PKCS12.pm\` passes with no errors
- [ ] \`perldoc PKCS12.pm\` renders all sections without mangled formatting
- [ ] CI passes (no functional code changed)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 4: Record the PR URL**

```bash
gh pr view --json url -q .url
```

---

## Self-Review

**Spec coverage check:**

| Issue from audit | Task |
|------------------|------|
| Version 1.95 → 1.97 | Task 1 |
| `represenation` typo | Task 1 |
| `Verifiy` typo | Task 1 |
| `$pksc12_data` typo | Task 1 |
| Unclosed `if` in SYNOPSIS | Task 1 |
| `new()` empty | Task 2 |
| `legacy_support()` thin | Task 2 |
| `new_from_string/file()` thin | Task 2 |
| `changepass()` OpenSSL 3.x caveat | Task 3 |
| `certificate()` / `ca_certificate()` format | Task 3 |
| `private_key()` format | Task 3 |
| `as_string()` thin | Task 3 |
| `mac_ok()` thin | Task 3 |
| `create()` return value | Task 4 |
| `create_as_string()` return value | Task 4 |
| dualvar unexplained in `info_as_hash()` | Task 4 |
| Exported constants undocumented | Task 5 |
| DIAGNOSTICS empty | Task 5 |
| DEPENDENCIES Perl 5.8 stale | Task 5 |
| SEE ALSO OpenSSL link stale | Task 5 |
| PR creation | Task 6 |

All 21 issues are covered. No placeholders used. No cross-task type inconsistencies (pure documentation — no function signatures).
