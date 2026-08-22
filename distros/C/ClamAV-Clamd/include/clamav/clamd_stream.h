/* clamd_stream.h - the INSTREAM pieces.
 *
 * Phase 3 of plan_clamav_clamd, trimmed by phase 5. The write loop that
 * used to live here is now the state machine in clamd_async.h, which
 * both the blocking and the non-blocking paths run - there is only one
 * implementation of the protocol in this distribution, deliberately.
 *
 * INSTREAM exists for three cases FILDES cannot serve: bytes that were
 * never a file, a clamd reached over TCP, and a platform with no
 * SCM_RIGHTS.
 *
 * It is harder than FILDES for one reason, and the shape of the write
 * loop comes entirely from it: clamd may answer WHILE THE CLIENT IS
 * STILL WRITING. It found a signature in chunk 3 of 400, or the stream
 * hit StreamMaxLength - and it may then close. A client that writes the
 * whole stream before it reads gets EPIPE on a scan that actually
 * succeeded, and reports an error for a file clamd correctly identified
 * as infected.
 *
 * Phase 0 recorded that exceeding StreamMaxLength produced a silent
 * close. That was wrong, and wrong because of this exact bug: the probe
 * wrote the whole stream before reading, so it hit EPIPE and never read
 * the reply already waiting for it. clamd does send
 *
 *   INSTREAM size limit exceeded. ERROR
 *
 * and reading before writing the next chunk is what makes it visible.
 */
#ifndef CLAMD_STREAM_H
#define CLAMD_STREAM_H

#include "clamav/clamd_conn.h"

#ifndef _WIN32
#  include <sys/uio.h>
#endif

#define CC_ERR_STREAMCUT  -9   /* peer closed mid-stream with no verdict */
#define CC_ERR_TOOBIGLOC -10   /* refused locally against max_size */

/* Measured, not picked - see the plan's phase 3 results. Large enough
 * that a big upload is not a syscall storm, small enough that an early
 * reply is noticed promptly, and small enough that one buffer per
 * concurrent scan is not real memory in a prefork pool. */
#define CC_DEF_CHUNK (64 * 1024)

/* Has clamd said something already? A reply arriving mid-write is a
 * VERDICT, not a failure, and this is the check that keeps it from being
 * mistaken for one. Non-blocking: never waits. */
static int cc_reply_pending(int sock) {
    struct pollfd p;
    p.fd = sock; p.events = POLLIN; p.revents = 0;
    return poll(&p, 1, 0) > 0 && (p.revents & (POLLIN | POLLHUP | POLLERR)) ? 1 : 0;
}

/* Source abstraction so memory and a descriptor share one write loop -
 * two copies of that loop would mean the rarely used one rots. */
typedef struct {
    const char *mem;      /* memory source, or NULL */
    size_t      memlen;
    size_t      memoff;
    int         fd;       /* descriptor source, or -1 */
    char       *iobuf;
    size_t      chunk;
} cc_source;

/* Returns bytes available at *p, 0 at end of input, -1 on error.
 *
 * Note this read is blocking even on the async path. The source is a
 * regular file or memory - never a socket - so it does not wait on a
 * peer, and making local file reads incremental would buy nothing but
 * state to get wrong. */
static ssize_t cc_source_next(cc_source *s, const char **p, cc_err *err) {
    if (s->mem) {
        size_t left = s->memlen - s->memoff;
        size_t take = left < s->chunk ? left : s->chunk;
        if (take == 0) return 0;
        *p = s->mem + s->memoff;
        s->memoff += take;
        return (ssize_t)take;
    }
    for (;;) {
        ssize_t n = read(s->fd, s->iobuf, s->chunk);
        if (n >= 0) { *p = s->iobuf; return n; }
        if (errno == EINTR) continue;
        cc_err_set(err, CC_ERR_IO, "read", strerror(errno));
        return -1;
    }
}

#endif /* CLAMD_STREAM_H */
