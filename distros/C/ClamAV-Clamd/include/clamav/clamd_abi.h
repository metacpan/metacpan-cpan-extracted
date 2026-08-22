/* clamd_abi.h - the C entry points ClamAV::Clamd exports.
 *
 * Vendor this header into a consumer, fetch the table once through
 * ClamAV::Clamd::_abi_ptr, and call clamd without crossing into Perl.
 *
 * WHAT THIS IS NOT FOR. It is not a speed optimisation, and the numbers
 * say so plainly - see the plan's phase 6 results. A scan is a socket
 * round trip to a daemon holding 1.6 GB of signatures: 637 us for a
 * small file, and the entire Perl-side cost of driving one to completion
 * is about 0.1 us. Even a 90 MiB stream, the case built to generate the
 * most readiness events, takes 142 step() calls - five microseconds of
 * Perl against a 0.64 second scan, or 0.0007%.
 *
 * This exists so a C consumer that is ALREADY in C - Punk's upload path,
 * which is C the whole way - can stay there, and for consistency with
 * how every other provider on this shelf is consumed. Anyone reaching
 * for it expecting it to be faster should use the Perl API instead: it
 * is simpler, and it is not measurably slower.
 *
 * VERSIONING. The table is APPEND-ONLY. New members go at the tail and
 * CLAMD_ABI_VERSION is bumped; nothing is ever reordered or resized,
 * because consumers carry vendored copies of this header whose field
 * offsets must stay valid.
 *
 * A consumer MUST gate on
 *
 *     abi->abi_version >= CLAMD_ABI_VERSION
 *
 * with GREATER-OR-EQUAL and never equality. A later table is a superset
 * whose prefix stays valid, so an equality check turns every provider
 * release into a breaking change for every consumer. That is not
 * hypothetical: Reverse::Proxy 0.04 used == against Fetch's table, Fetch
 * 0.14 appended one member, and seven CPAN Testers reports came back
 * refusing to load against a provider that was NEWER than required.
 *
 * Requires the Perl headers to have been included already.
 */
#ifndef CLAMD_ABI_H
#define CLAMD_ABI_H

#define CLAMD_ABI_VERSION 1

/* Verdict states. Mirrors the Perl side exactly. */
#define CLAMD_ABI_CLEAN        0
#define CLAMD_ABI_INFECTED     1
#define CLAMD_ABI_UNSCANNABLE  2
#define CLAMD_ABI_ERROR        3

/* Readiness, for driving a scan on a loop. */
#define CLAMD_ABI_WANT_NONE    0
#define CLAMD_ABI_WANT_READ    1
#define CLAMD_ABI_WANT_WRITE   2

/* Step results. */
#define CLAMD_ABI_STEP_MORE    0
#define CLAMD_ABI_STEP_DONE    1

/* Transports, so a consumer can see a fallback rather than infer it. */
#define CLAMD_ABI_TRANSPORT_NONE     0
#define CLAMD_ABI_TRANSPORT_FILDES   1
#define CLAMD_ABI_TRANSPORT_INSTREAM 2

typedef struct clamd_abi {
    int abi_version;

    /* --- target: where clamd is, and the limits to hold it to ------
     *
     * socket_path OR host/port, never both. Returns an opaque target, or
     * NULL if the configuration cannot work (no address, or a socket
     * path too long for this platform's sockaddr_un - which is refused
     * rather than truncated, because a truncated path connects to a
     * DIFFERENT socket).
     */
    void *(*target_new)(pTHX_ const char *socket_path,
                        const char *host, int port);
    void  (*target_timeouts)(pTHX_ void *target,
                             double connect_timeout, double reply_timeout);
    void  (*target_limits)(pTHX_ void *target,
                           size_t reply_max, size_t chunk, size_t max_size);
    void  (*target_free)(pTHX_ void *target);

    /* --- scanning --------------------------------------------------
     *
     * All four return an opaque scan handle the caller must free with
     * scan_free. The blocking pair return a handle that is already
     * finished; the start pair return one in flight.
     *
     * scan_fd/scan_start_fd BORROW the descriptor: it is neither closed
     * nor seeked. buf for the mem variants must stay valid until the
     * scan finishes - it is not copied.
     *
     * A handle is always returned, even when nothing reached clamd, so
     * verdict_state is always answerable. NULL only on allocation
     * failure.
     */
    void *(*scan_fd)(pTHX_ void *target, int fd);
    void *(*scan_mem)(pTHX_ void *target, const char *buf, size_t len);
    void *(*scan_start_fd)(pTHX_ void *target, int fd);
    void *(*scan_start_mem)(pTHX_ void *target, const char *buf, size_t len);

    /* --- driving one on a loop -------------------------------------
     *
     * socket() is the descriptor to watch, or -1 when finished. Watching
     * it after that is how a loop ends up dispatching on an unrelated
     * connection.
     */
    int   (*scan_socket)(pTHX_ void *scan);
    int   (*scan_want)(pTHX_ void *scan);     /* CLAMD_ABI_WANT_* */
    int   (*scan_step)(pTHX_ void *scan);     /* CLAMD_ABI_STEP_* */
    int   (*scan_done)(pTHX_ void *scan);

    /* Abandon a scan in flight. The connection is CLOSED, never kept:
     * clamd is still going to answer, and a connection carrying an
     * unread verdict would hand it to whichever scan took that
     * connection next. */
    void  (*scan_cancel)(pTHX_ void *scan);
    void  (*scan_free)(pTHX_ void *scan);

    /* --- the verdict -----------------------------------------------
     *
     * CLAMD_ABI_UNSCANNABLE means NOT SCANNED - over a size ceiling,
     * nested past MaxRecursion, an encrypted archive clamd could not
     * open. It must never be treated as clean. Neither must
     * CLAMD_ABI_ERROR.
     *
     * signature() and reason() return a pointer AND a length. The
     * signature is remote input - a file crafted to match a chosen
     * signature decides that string - so it is length-bounded here and
     * must not be assumed NUL-terminated by anything downstream.
     * The pointers are owned by the scan and die with it.
     */
    int         (*verdict_state)(pTHX_ void *scan);
    const char *(*verdict_signature)(pTHX_ void *scan, size_t *len);
    const char *(*verdict_reason)(pTHX_ void *scan, size_t *len);
    const char *(*verdict_error)(pTHX_ void *scan, size_t *len);
    int         (*verdict_transport)(pTHX_ void *scan);

} clamd_abi;

#endif /* CLAMD_ABI_H */
