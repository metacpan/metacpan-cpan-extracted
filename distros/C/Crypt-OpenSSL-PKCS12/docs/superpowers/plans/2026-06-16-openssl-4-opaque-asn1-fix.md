# OpenSSL 4.0 Opaque ASN1 Struct Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix `PKCS12.xs` to compile under OpenSSL 4.0, which made `asn1_string_st` (the backing struct for `ASN1_BMPSTRING`, `ASN1_UTF8STRING`, `ASN1_OCTET_STRING`, `ASN1_BIT_STRING`) opaque, breaking direct `->data` / `->length` member access.

**Architecture:** Replace all direct struct-member dereferences in `print_attribute()` with the public accessor API (`ASN1_STRING_length()`, `ASN1_STRING_get0_data()`). Add a compat macro for `ASN1_STRING_get0_data` in the existing OpenSSL < 1.1.0 guard block so the same code compiles across OpenSSL 1.0, 1.1, 3.x, and 4.0. Also replace the direct `BUF_MEM` member access (`bptr->length`, `bptr->data`) in `print_attribs()` with `BIO_get_mem_data()`, which may become opaque in a future OpenSSL release and is the documented way to query a mem-BIO.

**Tech Stack:** C / Perl XS, OpenSSL (1.0 – 4.0), `ppport.h` (Devel::PPPort), Dist::Zilla, `prove`

---

## Context

- **Issue:** GitHub issue #60 — "Build failure with OpenSSL 4.0" (Debian bug #1138300)
- **Branch to create:** `fix/openssl-4-opaque-asn1`
- **Files to change:** `PKCS12.xs` only
- **No new test files needed:** existing tests (`pkcs12-info-arbitrary-bag-attributes.t`, `pkcs12-info-utf8string-attribute.t`, `pkcs12-info-cve-2026-8507.t`, `pkcs12-info-le_1.1.t`) already exercise every changed code path and act as regression guards.

## File Map

| File | Action | What changes |
|------|--------|--------------|
| `PKCS12.xs` | Modify | Add `ASN1_STRING_get0_data` compat macro; replace 10 direct struct-member dereferences in `print_attribute()` and 2 in `print_attribs()` |

---

## Task 1: Create the working branch

**Files:**
- (git only — no source edits)

- [ ] **Step 1: Create and switch to the fix branch**

```bash
git checkout -b fix/openssl-4-opaque-asn1
```

Expected output: `Switched to a new branch 'fix/openssl-4-opaque-asn1'`

- [ ] **Step 2: Confirm the branch is active**

```bash
git branch --show-current
```

Expected output: `fix/openssl-4-opaque-asn1`

---

## Task 2: Verify the tests pass on the current codebase (baseline)

**Files:**
- (no edits — this is a pre-flight check)

- [ ] **Step 1: Build**

```bash
perl Makefile.PL && make
```

Expected: no errors; `make` produces `blib/`.

- [ ] **Step 2: Run the full test suite**

```bash
prove -lr -l -b -I inc t
```

Expected: all tests pass. Note the count so you can confirm it doesn't shrink after the fix.

---

## Task 3: Add `ASN1_STRING_get0_data` compat macro for OpenSSL < 1.1.0

**Files:**
- Modify: `PKCS12.xs:25-56` (the existing `#if OPENSSL_VERSION_NUMBER < 0x10100000L` compat block)

**Why this is needed:** `ASN1_STRING_get0_data()` was introduced in OpenSSL 1.1.0. On OpenSSL < 1.1.0 the equivalent is `ASN1_STRING_data()` (non-const, but that is fine since the older API predates the const annotation). Adding the macro here keeps every fix in Task 4 unconditionally readable — no per-call `#ifdef`.

- [ ] **Step 1: Open `PKCS12.xs` and locate the compat block**

The block starts at line 25:
```c
#if OPENSSL_VERSION_NUMBER < 0x10100000L
```
It ends around line 44 with:
```c
#define CONST_VOID void
```

- [ ] **Step 2: Add the compat macro inside the `< 0x10100000L` branch**

Find the existing line:
```c
#define CONST_VOID void
```

Add the new macro immediately after it, still inside the `#if` block:
```c
#define CONST_VOID void
#define ASN1_STRING_get0_data(x) ((const unsigned char *)ASN1_STRING_data(x))
```

The cast to `const unsigned char *` makes the return type identical to the 1.1.0+ signature so callers compile cleanly without further casts.

- [ ] **Step 3: Build to confirm the macro addition compiles**

```bash
make clean && perl Makefile.PL && make 2>&1 | grep -iE 'error|warning'
```

Expected: no errors (warnings about unused variables are pre-existing and acceptable; new warnings mean something is wrong).

- [ ] **Step 4: Commit**

```bash
git add PKCS12.xs
git commit -m "compat: add ASN1_STRING_get0_data macro for OpenSSL < 1.1.0"
```

---

## Task 4: Fix `print_attribute()` — replace direct struct member access

**Files:**
- Modify: `PKCS12.xs:659-710` (the `switch (av->type)` block in `print_attribute()`)

There are four `case` branches to fix. All follow the same pattern: replace `->length` with `ASN1_STRING_length()` and `->data` with `ASN1_STRING_get0_data()`.

`get_hex()` and `hex_prin()` both take `unsigned char *` (non-const), so cast the return of `ASN1_STRING_get0_data()` there.

### 4a — `V_ASN1_BMPSTRING`

- [ ] **Step 1: Replace the two dereferences in the BMPSTRING case**

Current code (lines 659-671):
```c
  case V_ASN1_BMPSTRING:
    length = av->value.bmpstring->length;
    if (length < 0 || length > (INT_MAX - 1))
      croak("BMPSTRING attribute length out of range (got %d)", length);
    value = OPENSSL_uni2asc(av->value.bmpstring->data, length);
```

Replace with:
```c
  case V_ASN1_BMPSTRING:
    length = ASN1_STRING_length(av->value.bmpstring);
    if (length < 0 || length > (INT_MAX - 1))
      croak("BMPSTRING attribute length out of range (got %d)", length);
    value = OPENSSL_uni2asc(ASN1_STRING_get0_data(av->value.bmpstring), length);
```

### 4b — `V_ASN1_UTF8STRING`

- [ ] **Step 2: Replace the three dereferences in the UTF8STRING case**

Current code (lines 673-685):
```c
  case V_ASN1_UTF8STRING:
    length = av->value.utf8string->length;
    if(*attribute != NULL) {
      if (length < 0 || length > (INT_MAX - 1))
        croak("UTF8STRING attribute length out of range (got %d)", length);
      Renew(*attribute, (size_t)length + 1, char);
      if (length)
        memcpy(*attribute, av->value.utf8string->data, (size_t)length);
      (*attribute)[length] = '\0';
    } else {
      BIO_printf(out, "%.*s\n", length, av->value.utf8string->data);
    }
    break;
```

Replace with:
```c
  case V_ASN1_UTF8STRING:
    length = ASN1_STRING_length(av->value.utf8string);
    if(*attribute != NULL) {
      if (length < 0 || length > (INT_MAX - 1))
        croak("UTF8STRING attribute length out of range (got %d)", length);
      Renew(*attribute, (size_t)length + 1, char);
      if (length)
        memcpy(*attribute, ASN1_STRING_get0_data(av->value.utf8string), (size_t)length);
      (*attribute)[length] = '\0';
    } else {
      BIO_printf(out, "%.*s\n", length, ASN1_STRING_get0_data(av->value.utf8string));
    }
    break;
```

### 4c — `V_ASN1_OCTET_STRING`

- [ ] **Step 3: Replace the three dereferences in the OCTET_STRING case**

Current code (lines 687-698):
```c
  case V_ASN1_OCTET_STRING:
    length = av->value.octet_string->length;
    if(*attribute != NULL) {
      if (length < 0 || length > INT_MAX / 4)
        croak("OCTET STRING attribute length out of range (got %d)", length);
      Renew(*attribute, (size_t)length * 4, char);
      get_hex(*attribute, av->value.octet_string->data, length);
    } else {
      hex_prin(out, av->value.octet_string->data, length);
      BIO_printf(out, "\n");
    }
    break;
```

Replace with:
```c
  case V_ASN1_OCTET_STRING:
    length = ASN1_STRING_length(av->value.octet_string);
    if(*attribute != NULL) {
      if (length < 0 || length > INT_MAX / 4)
        croak("OCTET STRING attribute length out of range (got %d)", length);
      Renew(*attribute, (size_t)length * 4, char);
      get_hex(*attribute, (unsigned char *)ASN1_STRING_get0_data(av->value.octet_string), length);
    } else {
      hex_prin(out, (unsigned char *)ASN1_STRING_get0_data(av->value.octet_string), length);
      BIO_printf(out, "\n");
    }
    break;
```

### 4d — `V_ASN1_BIT_STRING`

- [ ] **Step 4: Replace the three dereferences in the BIT_STRING case**

Current code (lines 700-711):
```c
  case V_ASN1_BIT_STRING:
    length = av->value.bit_string->length;
    if(*attribute != NULL) {
      if (length < 0 || length > INT_MAX / 4)
        croak("BIT STRING attribute length out of range (got %d)", length);
      Renew(*attribute, (size_t)length * 4, char);
      get_hex(*attribute, av->value.bit_string->data, length);
    } else {
      hex_prin(out, av->value.bit_string->data, length);
      BIO_printf(out, "\n");
    }
    break;
```

Replace with:
```c
  case V_ASN1_BIT_STRING:
    length = ASN1_STRING_length(av->value.bit_string);
    if(*attribute != NULL) {
      if (length < 0 || length > INT_MAX / 4)
        croak("BIT STRING attribute length out of range (got %d)", length);
      Renew(*attribute, (size_t)length * 4, char);
      get_hex(*attribute, (unsigned char *)ASN1_STRING_get0_data(av->value.bit_string), length);
    } else {
      hex_prin(out, (unsigned char *)ASN1_STRING_get0_data(av->value.bit_string), length);
      BIO_printf(out, "\n");
    }
    break;
```

- [ ] **Step 5: Build**

```bash
make clean && perl Makefile.PL && make 2>&1 | grep -iE 'error|warning'
```

Expected: no new errors or warnings.

- [ ] **Step 6: Run the full test suite**

```bash
prove -lr -l -b -I inc t
```

Expected: same pass count as the Task 2 baseline.

- [ ] **Step 7: Commit**

```bash
git add PKCS12.xs
git commit -m "fix: use ASN1_STRING accessor API in print_attribute for OpenSSL 4.0 compat

Direct ->data and ->length member access on ASN1_BMPSTRING, ASN1_UTF8STRING,
ASN1_OCTET_STRING, and ASN1_BIT_STRING fails to compile under OpenSSL 4.0,
which made struct asn1_string_st opaque. Replace with ASN1_STRING_length()
and ASN1_STRING_get0_data() throughout print_attribute(). A compat macro
maps ASN1_STRING_get0_data to ASN1_STRING_data for OpenSSL < 1.1.0.

Fixes: https://github.com/dsully/perl-crypt-openssl-pkcs12/issues/60"
```

---

## Task 5: Fix `print_attribs()` — replace direct `BUF_MEM` member access

**Files:**
- Modify: `PKCS12.xs:808-823` (the `attr_nid == NID_undef` branch in `print_attribs()`)

**Why:** `BUF_MEM->length` and `BUF_MEM->data` are accessed directly after `BIO_get_mem_ptr()`. OpenSSL 4.0 may make `BUF_MEM` opaque in the same fashion. The documented pattern is `BIO_get_mem_data(bio, &ptr)`, which returns the length as a `long` and sets the pointer in one call — no `BUF_MEM*` needed at all.

- [ ] **Step 1: Remove the `BUF_MEM*` variable and replace the access pattern**

Current code (lines 808-823):
```c
            BIO *attr_bio;
            BUF_MEM* bptr;

            CHECK_OPEN_SSL(attr_bio = BIO_new(BIO_s_mem()));
            i2a_ASN1_OBJECT(attr_bio, attr_obj);

            CHECK_OPEN_SSL(BIO_flush(attr_bio) == 1);
            BIO_get_mem_ptr(attr_bio, &bptr);

            if (bptr->length > 0) {
              if((hv_store(bag_hv,  bptr->data, bptr->length, newSVpvn(attribute_value, strlen(attribute_value)), 0)) == NULL)
                croak("unable to add MAC to the hash");
            }

            CHECK_OPEN_SSL(BIO_set_close(attr_bio, BIO_CLOSE) == 1);
            BIO_free(attr_bio);
```

Replace with:
```c
            BIO *attr_bio;
            char *attr_key = NULL;
            long attr_key_len;

            CHECK_OPEN_SSL(attr_bio = BIO_new(BIO_s_mem()));
            i2a_ASN1_OBJECT(attr_bio, attr_obj);

            CHECK_OPEN_SSL(BIO_flush(attr_bio) == 1);
            attr_key_len = BIO_get_mem_data(attr_bio, &attr_key);

            if (attr_key_len > 0) {
              if((hv_store(bag_hv, attr_key, (I32)attr_key_len, newSVpvn(attribute_value, strlen(attribute_value)), 0)) == NULL)
                croak("unable to add MAC to the hash");
            }

            BIO_set_close(attr_bio, BIO_CLOSE);
            BIO_free(attr_bio);
```

Note: `I32` is the Perl XS type for a 32-bit signed int — the `hv_store` key length parameter. The cast from `long` is safe because OID text representations are never more than a few hundred bytes.

- [ ] **Step 2: Build**

```bash
make clean && perl Makefile.PL && make 2>&1 | grep -iE 'error|warning'
```

Expected: no new errors or warnings.

- [ ] **Step 3: Run the full test suite**

```bash
prove -lr -l -b -I inc t
```

Expected: same pass count as the Task 2 baseline. The test `pkcs12-info-arbitrary-bag-attributes.t` exercises the `NID_undef` branch (the custom OID `1.2.3.4.5` attribute stored in secretbag and similar files).

- [ ] **Step 4: Commit**

```bash
git add PKCS12.xs
git commit -m "fix: replace BUF_MEM direct access with BIO_get_mem_data in print_attribs

Avoids BUF_MEM struct member dereference, which may become opaque in future
OpenSSL releases. BIO_get_mem_data() is the documented accessor for memory
BIOs and works across all supported OpenSSL versions."
```

---

## Task 6: Author-mode build check

Run with `-Wall -Werror` enabled (the way CI builds on Linux) to catch any const-discard or implicit-conversion warnings introduced by the casts.

- [ ] **Step 1: Clean and rebuild with author flags**

```bash
make clean && AUTHOR_TESTING=1 perl Makefile.PL && make 2>&1 | grep -iE 'error|warning'
```

Expected: no errors or new warnings. If you see a `discards 'const' qualifier` warning on any `(unsigned char *)ASN1_STRING_get0_data(...)` cast, change it to `(const unsigned char *)` in the corresponding `get_hex`/`hex_prin` call and update the function signature to accept `const unsigned char *` instead of `unsigned char *`.

- [ ] **Step 2: Run the full test suite one final time**

```bash
prove -lr -l -b -I inc t
```

Expected: all tests pass.

---

## Task 7: Open the pull request

- [ ] **Step 1: Push the branch**

```bash
git push -u origin fix/openssl-4-opaque-asn1
```

- [ ] **Step 2: Open the PR**

```bash
gh pr create \
  --title "fix: OpenSSL 4.0 — use ASN1_STRING accessors instead of direct struct member access" \
  --body "$(cat <<'EOF'
## Summary

- OpenSSL 4.0 made `struct asn1_string_st` (backing type for `ASN1_BMPSTRING`, `ASN1_UTF8STRING`, `ASN1_OCTET_STRING`, `ASN1_BIT_STRING`) opaque, breaking direct `->data`/`->length` access in `print_attribute()` (Debian bug #1138300, issue #60).
- Replaced all direct member dereferences with `ASN1_STRING_length()` and `ASN1_STRING_get0_data()`.
- Added a compat macro `ASN1_STRING_get0_data` in the existing `#if OPENSSL_VERSION_NUMBER < 0x10100000L` block so the fix is unconditional — no per-call `#ifdef`.
- Also replaced `BUF_MEM*`/`BIO_get_mem_ptr()` pattern in `print_attribs()` with `BIO_get_mem_data()`, the documented idiom that avoids opaque struct access.

## Test plan

- [ ] All existing tests pass on OpenSSL 3.x (`prove -lr -l -b -I inc t`)
- [ ] Author-mode build (`AUTHOR_TESTING=1`) produces no new errors or warnings
- [ ] CI green on Linux / macOS / Windows (Strawberry Perl) matrix
- [ ] Closes #60 — Debian OpenSSL 4.0 migration build failure

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- ✅ BMPSTRING `->length`/`->data` → `ASN1_STRING_length()`/`ASN1_STRING_get0_data()` (Task 4a)
- ✅ UTF8STRING same (Task 4b)
- ✅ OCTET_STRING same (Task 4c)
- ✅ BIT_STRING same (Task 4d)
- ✅ Compat macro for OpenSSL < 1.1.0 (Task 3)
- ✅ BUF_MEM opaque risk eliminated (Task 5)
- ✅ Author-mode `-Wall -Werror` check (Task 6)
- ✅ PR opened against `master` (Task 7)

**Placeholder scan:** No TBDs or "similar to Task N" references — every step has exact code.

**Type consistency:** `ASN1_STRING_get0_data` returns `const unsigned char *` everywhere; casts to `unsigned char *` are explicit where required by `get_hex`/`hex_prin`. `attr_key_len` is `long` (as returned by `BIO_get_mem_data`) and cast to `I32` only at the `hv_store` call site.
