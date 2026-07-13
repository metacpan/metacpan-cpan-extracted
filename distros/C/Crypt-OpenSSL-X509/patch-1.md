# Patch Review: CVE-2026-58102

**Crypt::OpenSSL::X509 — heap OOB-read in `hv_exts()` (X509.xs)**
Patch source: `issue.patch`
Review date: 2026-07-05

---

## Short verdict

The core fix is correct but the patch has three real bugs — **do not apply as-is.**

---

## What the patch gets right

The two-phase `OBJ_obj2txt` pattern — query length first, then allocate exactly, then format — is the correct approach and fully eliminates the original heap OOB on the normal code path. The `free(key)` after `hv_store` also correctly addresses the `/*FIXME will it leak?*/` note (Perl's `hv_store` copies the key bytes, so the caller may free immediately after).

---

## Bug 1 — Error path re-introduces the OOB (High)

In the `no_name == 0 || no_name == 1` branch as patched:

```c
r = OBJ_obj2txt(NULL, 0, X509_EXTENSION_get_object(ext), no_name);
if (r < 0) r = 0;                        // forces r to 0
key = malloc(sizeof(char) * ((size_t)r + 1));  // malloc(1)
if (key == NULL) croak(...);
r = OBJ_obj2txt(key, r + 1, ...);        // buf_len = 1; writes NUL only
                                          // BUT return value = full OID length
ckey = key;
```

When the first `OBJ_obj2txt` returns `< 0`, `r` is forced to 0 and `key` is 1 byte. The second call with `buf_len = 1` writes only a NUL terminator but **still returns the full required length** (e.g., 15). That value is stored back into `r`. Then:

```c
hv_store(RETVAL, ckey, 15, rv, 0)   // reads 15 bytes from a 1-byte buffer
```

The original OOB is reproduced on this error path.

**Fix:** croak immediately when the first call returns < 0 — do not silently substitute 0.

---

## Bug 2 — `key` leaks when `hv_store` fails (Medium)

```c
if (! hv_store(RETVAL, ckey, r, rv, 0) ) croak("Error storing extension in hash\n");
// croak → longjmp → never reaches the next line:
if (key != NULL) { free(key); key = NULL; }
```

`croak` unwinds via `longjmp`. The `free(key)` placed after the croak is unreachable on that path. The heap block introduced by the patch's own `malloc` leaks permanently on `hv_store` failure.

**Fix:** free `key` before the croak check, not after.

---

## Bug 3 — `rv` SV leaks on any croak after line 283 (Medium)

`sv_make_ref` at line 283 returns a non-mortal SV with refcount 1. The patch adds a new `croak("malloc failed...")` that fires after `rv` is created but before `hv_store` adopts it. The pre-existing `hv_store`-failure croak has the same problem. Neither path puts `rv` on the mortal stack, so Perl's scope unwind never reclaims it.

**Fix:** call `sv_2mortal(rv)` immediately after `sv_make_ref` returns.

---

## Warning — OpenSSL 1.0.x probe behaviour (Low / Correctness)

`OBJ_obj2txt(NULL, 0, obj, no_name)` as a length probe is reliable only on OpenSSL ≥ 1.1.0. On 1.0.x the implementation substitutes an internal ~22-byte stack buffer when `buf == NULL`, and returns the number of characters that fit there — not the full needed length. The patch adds no `#if OPENSSL_VERSION_NUMBER >= 0x10100000L` guard. On 1.0.x the result is not an OOB (the clamped `r` is ≤ 22), but hash keys for long OIDs would be silently truncated.

---

## Dead variable

`size_t len = 128;` (line 262) is now unused. Remove it to keep the compiler warning-clean.

---

## Recommended minimum changes before applying

```c
// 1. Make rv mortal immediately after creation
rv = sv_2mortal(sv_make_ref("Crypt::OpenSSL::X509::Extension", (void*)ext));

// 2. In the no_name == 0/1 branch — croak on probe failure, don't silently zero
r = OBJ_obj2txt(NULL, 0, X509_EXTENSION_get_object(ext), no_name);
if (r < 0) croak("OBJ_obj2txt length query failed for extension %d\n", i);
key = malloc(sizeof(char) * ((size_t)r + 1));
if (key == NULL) croak("malloc failed for extension key\n");
r = OBJ_obj2txt(key, r + 1, X509_EXTENSION_get_object(ext), no_name);
ckey = key;

// 3. Free key BEFORE the hv_store croak
{
    bool stored;
    stored = hv_store(RETVAL, ckey, r, rv, 0);
    if (key != NULL) { free(key); key = NULL; }
    if (!stored) croak("Error storing extension in hash\n");
}

// 4. Remove the now-dead: size_t len = 128;
```

---

## Summary table

| Finding | Severity | In original? | In patch? |
|---------|----------|-------------|-----------|
| Heap OOB on long OID (the CVE) | Critical | Yes | Fixed on happy path |
| Heap OOB reproduced on `OBJ_obj2txt` error path | High | No | Introduced by patch |
| `key` leak on `hv_store` failure | Medium | Yes (different) | Introduced by patch |
| `rv` SV leak on croak paths | Medium | Yes | Not fixed by patch |
| Silent key truncation on OpenSSL 1.0.x | Low | Yes | Not fixed |
| Dead `len` variable | Info | No | Introduced by patch |

The patch is a good-faith fix that correctly diagnoses and addresses the root cause on the normal code path. It needs the three fixes above before it is safe to apply.
