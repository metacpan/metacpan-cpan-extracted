Thanks — the review is right on the substance, and I've revised the patch.
Summary of what I took, plus one important caveat where following the
review verbatim would introduce a new bug.

Adjudication of the six items:

- Bug 1 (error path re-introduces the OOB) — VALID, fixed. Confirmed:
  forcing `r = 0`, `malloc(1)`, then a second `OBJ_obj2txt(key, 1, ...)`
  still returns the full OID length, which then reached `hv_store` as the
  key length — an over-read of the 1-byte buffer.

- Bug 2 (`key` leaks when `hv_store` fails) — VALID, fixed. The `free(key)`
  now runs before the failure `croak`, so it is not skipped by the longjmp.

- Bug 3 (`rv` SV leaks on croak paths) — the observation is VALID, but
  please DO NOT apply the recommended `sv_2mortal(rv)` fix. `hv_store()`
  takes ownership of `rv` without incrementing its refcount (that is why
  the original code passes it non-mortal). If `rv` is also mortalised, the
  mortal stack and the hash both own the single reference, and the
  scope-end mortal decref frees an SV the hash still holds — a
  use-after-free / double-free on the *success* path. I confirmed this the
  hard way: the corrected patch below (which does NOT mortalise) passes the
  full 96/96 suite; mortalising would crash the extension-enumeration
  tests. The correct leak fix is `SvREFCNT_dec(rv)` only on the error paths
  that croak before `hv_store` adopts it — included below.

- OpenSSL 1.0.x length-probe note — handled without a version macro. The
  patch stores `strlen(key)` (bytes actually written, always <= the
  allocation) as the `hv_store` length rather than any `OBJ_obj2txt` return
  value. That one change removes the over-read on every path at once — the
  original CVE, the Bug 1 error path, and the 1.0.x under-report you noted
  (worst case there is a truncated key, never an over-read).

- Dead `size_t len = 128;` — removed.

Corrected patch (against 2.1.2 X509.xs), which builds clean, passes
`make test` 96/96, and flips the long-OID reproduction from leaking heap
bytes to round-tripping the full OID exactly:

```diff
--- a/X509.xs
+++ b/X509.xs
@@ -259,7 +259,6 @@
 static HV* hv_exts(X509* x509, int no_name) {
   X509_EXTENSION *ext;
   int i, c, r;
-  size_t len = 128;
   char* key = NULL;
   const char* ckey = NULL;
   SV* rv;
@@ -284,9 +283,22 @@
 
     if (no_name == 0 || no_name == 1) {
 
-       key = malloc(sizeof(char) * (len + 1)); /*FIXME will it leak?*/
-       r = OBJ_obj2txt(key, len, X509_EXTENSION_get_object(ext), no_name);
+       /* OBJ_obj2txt() returns the FULL textual length the OID needs, not
+          the number of bytes written into the buffer. The original code
+          passed a fixed 128-byte buffer and handed that return value to
+          hv_store() as the key length, so an OID longer than 128 bytes made
+          hv_store() read past the allocation (heap OOB read). Size the
+          buffer to the required length first, then format, and store the
+          number of bytes actually written (strlen) -- never the return
+          value -- so no over-read is possible on any code path or any
+          OBJ_obj2txt() version. */
+       r = OBJ_obj2txt(NULL, 0, X509_EXTENSION_get_object(ext), no_name);
+       if (r < 0) { SvREFCNT_dec(rv); croak("OBJ_obj2txt length query failed for extension %d\n", i); }
+       key = malloc(sizeof(char) * ((size_t)r + 1));
+       if (key == NULL) { SvREFCNT_dec(rv); croak("malloc failed for extension key\n"); }
+       OBJ_obj2txt(key, r + 1, X509_EXTENSION_get_object(ext), no_name);
        ckey = key;
+       r = (int)strlen(key);
 
     } else if (no_name == 2) {
 
@@ -294,7 +306,15 @@
        r = strlen(ckey);
     }
 
-    if (! hv_store(RETVAL, ckey, r, rv, 0) ) croak("Error storing extension in hash\n");
+    /* hv_store() copies the key bytes, so the per-iteration key buffer can be
+       freed immediately (addresses the FIXME leak note above). Free it BEFORE
+       the failure croak so it is not leaked on longjmp; on hv_store() failure
+       the hash did not adopt rv, so drop our reference too. */
+    {
+        SV** stored = hv_store(RETVAL, ckey, r, rv, 0);
+        if (key != NULL) { free(key); key = NULL; }
+        if (stored == NULL) { SvREFCNT_dec(rv); croak("Error storing extension in hash\n"); }
+    }
   }
 
   return RETVAL;
```

Note this is the same `hv_exts` loop touched by the separate malformed-
extension NULL-deref fix; the two changes are in different statements and
do not conflict.

