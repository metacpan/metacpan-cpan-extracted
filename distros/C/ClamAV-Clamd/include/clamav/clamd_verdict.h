/* clamd_verdict.h - turning a reply into an answer that cannot be
 * misread by accident.
 *
 * Phase 4 of plan_clamav_clamd.
 *
 * FOUR states, because clamd answers OK for files it declined to scan.
 * A boolean API here reports "clean" for precisely the inputs an
 * attacker constructs - a 2 KB nested zip, a password-protected archive,
 * anything over MaxFileSize - and passes every test anybody writes,
 * because nobody writes the test where the answer is "I did not look".
 */
#ifndef CLAMD_VERDICT_H
#define CLAMD_VERDICT_H

/* stream.h, not conn.h: the local-ceiling and stream-cut codes live
 * there, and both of them are verdicts rather than transport failures. */
#include "clamav/clamd_stream.h"

#define CC_CLEAN        0
#define CC_INFECTED     1
#define CC_UNSCANNABLE  2
#define CC_ERROR        3

/* A signature name is REMOTE INPUT. A file crafted to match a chosen
 * signature chooses the string that comes back, and that string ends up
 * in logs and, in a careless consumer, in an HTTP response. It is
 * length-bounded here and handed onward with its length. */
#define CC_SIGLEN  256
#define CC_REASONLEN 64

typedef struct {
    int   state;
    char  signature[CC_SIGLEN];    /* "" when there is none */
    char  reason[CC_REASONLEN];    /* why unscannable; "" otherwise */
} cc_verdict;

/* The two families that mean "clamd did not see the content".
 *
 * NOT every Heuristics.* name: Heuristics.Phishing.* and
 * Heuristics.OLE2.ContainsMacros are clamd saying it LOOKED and thinks
 * the thing is bad, which is a detection. These two are clamd saying it
 * could not look, which is the opposite and must never read as clean. */
#define CC_PFX_LIMITS    "Heuristics.Limits.Exceeded."
#define CC_PFX_ENCRYPTED "Heuristics.Encrypted."

static int cc_starts_with(const char *s, size_t len, const char *pfx) {
    size_t n = strlen(pfx);
    return len >= n && memcmp(s, pfx, n) == 0;
}

static int cc_ends_with(const char *s, size_t len, const char *suf) {
    size_t n = strlen(suf);
    return len >= n && memcmp(s + len - n, suf, n) == 0;
}

static void cc_copy_bounded(char *dst, size_t cap, const char *src, size_t len) {
    if (len >= cap) len = cap - 1;
    if (len) memcpy(dst, src, len);
    dst[len] = '\0';
}

/* Parse one reply.
 *
 * Shapes, all measured rather than assumed:
 *
 *   fd[11]: OK                                        clean
 *   stream: OK                                        clean
 *   fd[11]: Eicar-Test-Signature FOUND                infected
 *   fd[11]: Heuristics.Limits.Exceeded.MaxFileSize FOUND   unscannable
 *   fd[11]: Heuristics.Encrypted.Zip FOUND            unscannable
 *   INSTREAM size limit exceeded. ERROR               unscannable
 *   /x: File path check failure: ... ERROR            error
 *   UNKNOWN COMMAND                                   error (no ERROR suffix!)
 *   anything unrecognised                             error, NEVER clean
 */
static void cc_parse_reply(const char *reply, size_t len, cc_verdict *v) {
    memset(v, 0, sizeof *v);
    v->state = CC_ERROR;

    if (!reply || len == 0) return;

    /* Trim a trailing newline, which the 'n' framing leaves behind. */
    while (len && (reply[len - 1] == '\n' || reply[len - 1] == '\r')) len--;

    if (cc_ends_with(reply, len, " FOUND")) {
        const char *sig;
        size_t siglen, cut = len - 6;      /* strip " FOUND" */
        size_t i;

        /* The description before the signature is "fd[N]: ", "stream: "
         * or a path - and a path may itself contain ": ". Take the LAST
         * ": " so a colon in a filename cannot eat the signature. */
        sig = reply; siglen = cut;
        for (i = cut; i >= 2; i--) {
            if (reply[i - 2] == ':' && reply[i - 1] == ' ') {
                sig = reply + i;
                siglen = cut - i;
                break;
            }
        }

        cc_copy_bounded(v->signature, sizeof v->signature, sig, siglen);

        if (cc_starts_with(sig, siglen, CC_PFX_LIMITS)) {
            size_t n = strlen(CC_PFX_LIMITS);
            v->state = CC_UNSCANNABLE;
            cc_copy_bounded(v->reason, sizeof v->reason, sig + n, siglen - n);
        } else if (cc_starts_with(sig, siglen, CC_PFX_ENCRYPTED)) {
            v->state = CC_UNSCANNABLE;
            cc_copy_bounded(v->reason, sizeof v->reason, "Encrypted", 9);
        } else {
            v->state = CC_INFECTED;
        }
        return;
    }

    if (cc_ends_with(reply, len, " OK") || (len == 2 && memcmp(reply, "OK", 2) == 0)) {
        v->state = CC_CLEAN;
        return;
    }

    /* The stream ceiling. clamd DOES answer here - phase 0 recorded a
     * silent close, which was its probe's bug, not clamd's behaviour.
     * It is unscannable, not a transport error: nothing was scanned. */
    if (cc_ends_with(reply, len, "size limit exceeded. ERROR")) {
        v->state = CC_UNSCANNABLE;
        cc_copy_bounded(v->reason, sizeof v->reason, "StreamMaxLength", 15);
        return;
    }

    /* Everything else - including "UNKNOWN COMMAND", which carries no
     * ERROR suffix - is an error. The default is error and never clean,
     * which is the single most important line in this file. */
    v->state = CC_ERROR;
}

/* A failure that never reached a reply. Still a verdict, so that
 * is_clean() is safe to call on whatever a scan returned. */
static void cc_verdict_from_error(int code, cc_verdict *v) {
    memset(v, 0, sizeof *v);

    /* Refused locally against max_size, or cut off past clamd's stream
     * ceiling: in both cases nothing was scanned, which is exactly what
     * unscannable means. Reporting these as transport errors would
     * invite a caller to retry rather than to decide. */
    if (code == CC_ERR_TOOBIGLOC) {
        v->state = CC_UNSCANNABLE;
        cc_copy_bounded(v->reason, sizeof v->reason, "max_size", 8);
        return;
    }
    if (code == CC_ERR_STREAMCUT) {
        v->state = CC_UNSCANNABLE;
        cc_copy_bounded(v->reason, sizeof v->reason, "StreamMaxLength", 15);
        return;
    }
    v->state = CC_ERROR;
}

static const char *cc_state_name(int state) {
    switch (state) {
        case CC_CLEAN:       return "clean";
        case CC_INFECTED:    return "infected";
        case CC_UNSCANNABLE: return "unscannable";
        default:             return "error";
    }
}

#endif /* CLAMD_VERDICT_H */
