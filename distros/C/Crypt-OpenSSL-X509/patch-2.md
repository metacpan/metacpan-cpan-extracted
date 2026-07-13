# Security Review: CVE-2026-58101 — NULL-deref in X509V3_EXT_d2i extension helpers

**Module:** Crypt::OpenSSL::X509  
**CVE:** CVE-2026-58101  
**Reporter:** Timothy Legge  
**Branch:** fix/CVE-2026-58101-null-deref-extension-helpers  
**Review date:** 2026-07-05  

---

## Vulnerability Summary

`X509V3_EXT_d2i()` returns `NULL` when an extension's DER value fails to parse. For Authority Key Identifier (AKI), even a well-formed extension may legitimately have a NULL `keyid` field (the field is optional per RFC 5280). Six helper functions in `X509.xs` dereferenced these values unconditionally, producing a guaranteed `SIGSEGV` on attacker-supplied certificates — a reliable denial-of-service.

**Affected functions (original CVE report):**

| Function | X509.xs line | NULL-deref path |
|---|---|---|
| `basicC` | ~1133 | `bs->ca` / `bs->pathlen` with `bs == NULL` |
| `ia5string` | ~1161 | `str->data` / `ASN1_STRING_get0_data(str)` with `str == NULL` |
| `auth_att` | ~1249 | `akid->keyid` with `akid == NULL` or `akid->keyid == NULL` |
| `keyid_data` | ~1275 | `akid->keyid->data` with either pointer NULL; `skid->data` with `skid == NULL` |

**Additional functions identified during review (same vulnerability class):**

| Function | X509.xs line | NULL-deref path |
|---|---|---|
| `bit_string` | ~1201 | `ASN1_BIT_STRING_get_bit(bit_str, i)` with `bit_str == NULL` |
| `extendedKeyUsage` | ~1236 | `sk_ASN1_OBJECT_num(extku)` with `extku == NULL` |

---

## Impact

- **Type:** Null-pointer dereference → `SIGSEGV`
- **Impact:** Denial of service — the Perl process crashes; no code execution, no data exposure
- **Trigger:** Caller invokes an affected helper on a certificate extension whose DER fails to parse, or an AKI extension with no `keyid` field
- **Real-world path (example):** A WebAuthn/attestation flow calling `extensions_by_oid->{"2.5.29.19"}->basicC("ca")` on an attacker-controlled attestation certificate during registration hits the `basicC` leg and crashes

---

## Patch Review: Original Submission (issue2.patch)

The submitted patch correctly fixes the four functions named in the CVE report.

### `basicC` — CORRECT
```c
if (bs == NULL) croak("Error parsing basicConstraints extension\n");
```
Croaks rather than returning `ca=0` / `pathlen=0` — the right choice because this value drives a security decision. `BASIC_CONSTRAINTS_free(bs)` at line ~1148 is only reached on the non-NULL path; no leak.

### `ia5string` — CORRECT
```c
if (str != NULL) {
    BIO_write(...);
    ASN1_IA5STRING_free(str);
}
```
Returns empty string on NULL. The BIO is always finalised by `sv_bio_final()`. OpenSSL 4.x version guard correctly preserved inside the new block.

### `auth_att` — CORRECT + BONUS FIX
```c
RETVAL = (akid != NULL && akid->keyid != NULL) ? 1 : 0;
if (akid != NULL) AUTHORITY_KEYID_free(akid);
```
Short-circuit evaluation prevents `akid->keyid` access when `akid` is NULL. Also fixes a pre-existing `AUTHORITY_KEYID_free` leak (the original code never freed `akid`).

### `keyid_data` — CORRECT
Both the AKI and SKID paths are now guarded. `AUTHORITY_KEYID_free(akid)` is placed outside the inner `akid->keyid` guard but inside the outer `akid` guard — correct: frees the struct even when the optional `keyid` field is absent.

---

## Additional Fixes Applied (extended scope)

Two functions not in the original report carry the same NULL-deref class. They were fixed in the same commit to complete the remediation.

### `bit_string` — ADDED FIX
```c
if (bit_str != NULL) {
    if (nid == NID_key_usage) { ... }
    else if (nid == NID_netscape_cert_type) { ... }
}
```
Returns empty string on NULL `bit_str`.

### `extendedKeyUsage` — ADDED FIX
```c
if (extku != NULL) {
    while(sk_ASN1_OBJECT_num(extku) > 0) { ... }
}
```
Returns empty string on NULL `extku`.

---

## Minor Observations (not blocking)

1. **`basicC` croak message ends with `\n`** — suppresses Perl's `at file line N` annotation in the exception message. Cosmetic; not a safety issue.
2. **`basicC` pathlen branch** (pre-existing, not introduced by patch) — `bs->pathlen ? 1 : 0` tests pointer presence, not the integer value. Surprising semantics but not unsafe.
3. **`extendedKeyUsage` stack leak** (pre-existing) — `sk_ASN1_OBJECT_pop` drains elements but the stack container is never freed with `sk_ASN1_OBJECT_free()`. Out of scope for this CVE; recommend a follow-up.

---

## Verdict

The original patch is **correct and safe to apply**. The extended commit on branch `fix/CVE-2026-58101-null-deref-extension-helpers` additionally covers `bit_string` and `extendedKeyUsage`, completing the remediation of this vulnerability class across all six affected helpers.

No new security vulnerabilities are introduced by either the original patch or the extended fixes.
