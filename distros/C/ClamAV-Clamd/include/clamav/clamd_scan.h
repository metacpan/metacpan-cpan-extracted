/* clamd_scan.h - scanning by descriptor.
 *
 * Phase 2 of plan_clamav_clamd. FILDES only; INSTREAM is phase 3.
 */
#ifndef CLAMD_SCAN_H
#define CLAMD_SCAN_H

#include "clamav/clamd_conn.h"
#include "clamav/clamd_stream.h"
#include "clamav/clamd_async.h"

#ifndef _WIN32
#  include <sys/stat.h>
#endif

#define CC_ERR_NOTREG    -7   /* not a regular file */
#define CC_ERR_NOFDPASS  -8   /* this transport or platform cannot pass one */

#if CC_HAVE_FD_PASSING

/* THE HANDSHAKE, captured from clamdscan --fdpass against a listener
 * that dumps what it receives:
 *
 *   write   "zFILDES\0"   the command, ALONE, with no ancillary data
 *   sendmsg "\0" + fd     one NUL byte carrying SCM_RIGHTS
 *
 * Attaching the descriptor to the command itself - the obvious reading,
 * and what every first attempt does - is rejected with
 *
 *   PROTOCOL ERROR: ancillary data sent without FILDES. ERROR
 *
 * because clamd sees the control message on a read where FILDES has not
 * been dispatched yet. Two messages, in this order. No document says so.
 *
 * Every control-message offset goes through the CMSG_* macros. The
 * alignment rules are the sort of thing that works by accident on the
 * platform you developed on and not on the next one.
 */
/* A descriptor that is not a regular file cannot mean what the caller
 * thinks it means: a pipe has no length and can be read exactly once, a
 * directory is not a document, and a socket is somebody else's stream.
 * Refuse rather than hand clamd something it will answer about
 * meaninglessly. */
static int cc_check_regular(int fd, cc_err *err) {
    struct stat st;
    if (fstat(fd, &st) < 0) {
        cc_err_set(err, CC_ERR_IO, "fstat", strerror(errno));
        return CC_ERR_IO;
    }
    if (!S_ISREG(st.st_mode)) {
        cc_err_set(err, CC_ERR_NOTREG, "not a regular file", NULL);
        return CC_ERR_NOTREG;
    }
    return CC_OK;
}

#endif /* CC_HAVE_FD_PASSING */

/* Scan an open descriptor.
 *
 * The descriptor is BORROWED. This never closes it, and it never seeks
 * it either: clamd scans the whole file regardless of where the
 * descriptor happens to be positioned - measured at offsets 0, 10 and
 * past EOF, all of which detected a signature at byte 0 - so there is
 * nothing to correct, and correcting it would mutate something the
 * caller owns.
 */
static int cc_scan_fd(const cc_target *t, int fd,
                      char **out, size_t *outlen, int *transport, cc_err *err) {
    cc_scan sc;
    int rc, mode;

    err->code = CC_OK; err->msg[0] = '\0';
    *out = NULL; *outlen = 0;
    if (transport) *transport = CC_TRANSPORT_NONE;

    /* FILDES over TCP is not an error at clamd's end - it is a HANG.
     * Phase 0: the command produces no reply, no diagnostic, and the
     * connection stays open forever. clamd will never tell a client it
     * asked for something impossible, so the client has to know.
     *
     * Same on any platform without SCM_RIGHTS. Both fall back to
     * INSTREAM, which is correct but expensive: the file now crosses the
     * socket in full. That is why the transport is reported. */
    mode = (CC_HAVE_FD_PASSING && t->path) ? CC_TRANSPORT_FILDES
                                           : CC_TRANSPORT_INSTREAM;

    {
        struct stat st;
        if (fstat(fd, &st) < 0) {
            cc_err_set(err, CC_ERR_IO, "fstat", strerror(errno));
            return CC_ERR_IO;
        }
        if (!S_ISREG(st.st_mode)) {
            cc_err_set(err, CC_ERR_NOTREG, "not a regular file", NULL);
            return CC_ERR_NOTREG;
        }
        if (t->max_size && (size_t)st.st_size > t->max_size) {
            cc_err_set(err, CC_ERR_TOOBIGLOC,
                       "larger than max_size; refused without scanning", NULL);
            return CC_ERR_TOOBIGLOC;
        }
    }

    if (mode == CC_TRANSPORT_FILDES)
        rc = cc_scan_start(&sc, t, mode, fd, 0, NULL, 0, -1);
    else
        rc = cc_scan_start(&sc, t, mode, -1, 0, NULL, 0, fd);

    if (rc == CC_OK) rc = cc_scan_run(&sc, out, outlen, err);
    else *err = sc.err;

    if (transport) *transport = sc.transport;
    cc_scan_free(&sc);
    return rc;
}

/* Scan a path.
 *
 * The path is opened HERE and the descriptor is what travels. This is
 * NOT clamd's SCAN command, which hands clamd a path for clamd to
 * resolve - and which therefore needs clamd to have permission on it.
 * The whole point of FILDES is that it does not.
 */
static int cc_scan_path(const cc_target *t, const char *path,
                        char **out, size_t *outlen, int *transport, cc_err *err) {
    int fd, rc;

    err->code = CC_OK; err->msg[0] = '\0';
    *out = NULL; *outlen = 0;
    if (transport) *transport = CC_TRANSPORT_NONE;

    fd = open(path, O_RDONLY);
    if (fd < 0) {
        cc_err_set(err, CC_ERR_IO, "open", strerror(errno));
        return CC_ERR_IO;
    }
    rc = cc_scan_fd(t, fd, out, outlen, transport, err);
    close(fd);                 /* ours, so ours to close - on every path */
    return rc;
}

#endif /* CLAMD_SCAN_H */
