#ifndef AP_ABI_H
#define AP_ABI_H

/* Apophis's public C ABI - the content-addressing primitives, callable from
 * another XS module without a Perl frame. Everything here is otherwise static
 * inside Apophis's translation unit and reachable only by dispatching a
 * method, which is a Perl call to run a snprintf.
 *
 * Resolved at RUNTIME via Apophis::_abi_ptr - a DBI-style function-pointer
 * table - so there is no link-time symbol coupling and each dist builds and
 * upgrades independently. A consumer reaches this header through
 * ExtUtils::Depends, or vendors a copy pinned at AP_ABI_VERSION, and checks
 * abi_version at boot.
 *
 * The table only ever grows at the end; AP_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version >= the version it was written against,
 * treating a later table as a superset it uses a prefix of.
 *
 * NOT ==. An equality check turns every provider release into a breaking
 * change for every consumer: Reverse::Proxy 0.04 chose equality against
 * Fetch's ABI and stopped loading everywhere the moment Fetch appended one
 * member, croaking "please upgrade" at installations whose Fetch was already
 * newer than required.
 *
 * Perl headers (EXTERN.h / perl.h / XSUB.h) must be included before this file
 * so SV, STRLEN, PerlIO and pTHX are defined. */

#define AP_ABI_VERSION 1

typedef struct ap_abi {
    int abi_version;                     /* == AP_ABI_VERSION */

    /* Unpack a blessed Apophis object into the two things every other call
     * needs. On success fills *ns_out with a pointer to the 16 namespace
     * bytes, and dir_out plus dirlen_out with the store directory, returning 1.
     * Returns 0 for anything that is not an Apophis object, or one built
     * without a store_dir - it NEVER croaks, so a consumer may probe.
     *
     * Both pointers are BORROWED from the object's own SVs and are valid only
     * while the object is alive and unmodified. Copy them if you intend to
     * keep them.
     *
     * This is the only member that touches the object, which is deliberate:
     * there stays exactly one source of truth for what a store is. A consumer
     * caching the namespace bytes beside the object would own a second copy
     * to keep in step. Any of the out-params may be NULL to discard it. */
    int (*store_of)(pTHX_ SV *self, const unsigned char **ns_out,
                    const char **dir_out, STRLEN *dirlen_out);

    /* Derive the 16 namespace bytes from a namespace string - v5(DNS, name),
     * the same derivation Apophis->new performs - for a caller that has the
     * string rather than an object. ns_out needs 16 bytes. */
    void (*derive_ns)(unsigned char *ns_out, const char *name, STRLEN len);

    /* In-memory content -> the 16 id bytes: v5(namespace, content).
     * id_out needs 16 bytes. */
    void (*identify)(unsigned char *id_out, const unsigned char *ns,
                     const char *content, STRLEN len);

    /* The same, streaming an already-open handle in 64KB chunks - O(1) in
     * memory, for content that is on disk rather than in a scalar. Reads from
     * the current position to EOF and leaves the handle there.
     *
     * In the table without a caller in Apophis itself, because it is the one
     * operation a consumer cannot reasonably reimplement: the chunking and
     * the RFC-ordered namespace prefix are easy to get subtly wrong, and
     * wrong here means ids that disagree with every other path. */
    void (*identify_fh)(pTHX_ unsigned char *id_out, const unsigned char *ns,
                        PerlIO *fh);

    /* The 16 id bytes -> the canonical 36-character text form, NUL
     * terminated. buf needs 37 bytes. */
    void (*format_id)(char *buf, const unsigned char *id);

    /* The sharded on-disk path for an id in its text form. Returns the length
     * the path WOULD have, snprintf-style, so a return >= out_size means it
     * was TRUNCATED and the result must not be used - a truncated path is a
     * different file. Apophis's own callers predate this note and do not
     * check; a consumer should.
     *
     * A consumer must never reimplement this. The layout is Apophis's to
     * change, and a second copy of the sharding rule means the day it changes
     * every blob already on disk becomes unreachable through the consumer
     * while staying perfectly findable through Apophis. */
    int (*build_path)(char *out, size_t out_size,
                      const char *dir, STRLEN dirlen,
                      const char *id, STRLEN id_len);

    /* Create the parent directory if needed, then write via temp-and-rename,
     * which is what makes a store idempotent under concurrency. Croaks on an
     * I/O error, the way Apophis's own store does - it is not a probe. */
    void (*write_atomic)(pTHX_ const char *path,
                         const char *content, STRLEN len);
} ap_abi;

#endif /* AP_ABI_H */
