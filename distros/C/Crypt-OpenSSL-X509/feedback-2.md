Hi Jonas:

Re: security review of the extension-helper NULL-deref fix

Thanks for the review. I went through it (with Claude) against the 2.1.2 source and ran a
couple of the cases on an unpatched build. The verdict on the four functions
in the original report is solid; one part of the extended scope doesn't hold
up, and there's a more useful change hiding in one of the extras.

Agreed and confirmed:

- basicC, ia5string, auth_att, keyid_data — the fixes are correct. croaking in
  basicC (it feeds a CA / pathLen decision, so a malformed extension should be
  rejected, not read as ca=0), guard-and-return-empty for the string
  accessors, and the auth_att change also picking up the AUTHORITY_KEYID_free
  that the original code omitted — all good. These four are the complete set
  of crash sites (see below), so the original patch fully remediates the DoS.

One correction — bit_string and extendedKeyUsage are NOT crash sites:

- bit_string
  (https://metacpan.org/release/JONASBN/Crypt-OpenSSL-X509-2.1.2/source/X509.xs#L1191)
  passes the possibly-NULL result to ASN1_BIT_STRING_get_bit(), which is
  NULL-tolerant — it returns 0 for a NULL string rather than dereferencing.
- extendedKeyUsage
  (https://metacpan.org/release/JONASBN/Crypt-OpenSSL-X509-2.1.2/source/X509.xs#L1226)
  gates its loop on sk_ASN1_OBJECT_num(extku), and OPENSSL_sk_num(NULL) returns
  -1, so the loop body never runs.

I checked this empirically on unpatched 2.1.2: a cert carrying a malformed
keyUsage / extKeyUsage extension (so X509V3_EXT_d2i returns NULL) makes basicC
SIGSEGV as expected, but bit_string returns "000000000" and extendedKeyUsage
returns "" — neither crashes. So the NULL guards you added there are harmless
defense-in-depth, but they aren't fixing a vulnerability, and the remediation
was already complete with the original four. I enumerated every
X509V3_EXT_d2i call in the file (basicC, ia5string, bit_string,
extendedKeyUsage, auth_att, and both branches of keyid_data) — the four that
actually dereference the result without a NULL-safe accessor are exactly the
four in the original patch.

The change worth making in extendedKeyUsage is the other thing your review
flagged: the loop pops every element with sk_ASN1_OBJECT_pop() but nothing
frees the popped ASN1_OBJECTs or the stack container, so each call leaks. That
leak (not a NULL guard) is the useful fix for that function if you're touching
it anyway. The bs->pathlen ? 1 : 0 pointer-vs-value note and the croak "\n"
line-annotation note are both fair and both pre-existing; neither is a safety
issue.

Net: ship the original four-function fix as-is; the bit_string /
extendedKeyUsage NULL guards are optional; and extendedKeyUsage's real
outstanding issue is the object/stack leak.

Tim
