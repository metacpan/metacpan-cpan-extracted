/* A consumer of ClamAV::Clamd's C ABI, exactly as an outside dist is
 * meant to write one: vendor the header, fetch the table once through
 * _abi_ptr, gate on >=, then call clamd without touching Perl again.
 *
 * It lives in the provider's own suite so the ABI is exercised HERE and
 * not only downstream, where a break is somebody else's failing smoker.
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* clamd_abi.h pulls in no system headers of its own - it needs only the
 * Perl ones. A consumer that drives a scan on a loop supplies its own. */
#ifndef _WIN32
#  include <poll.h>
#endif

#include "clamav/clamd_abi.h"

static const clamd_abi *ABI = NULL;

/* A real consumer bakes the version it was built against into the
 * binary. This one can be told a different number at runtime, purely so
 * the provider's suite can prove what happens on skew without building
 * a second copy of it. */
static int abi_required(void) {
    const char *e = getenv("CLAMD_ABI_REQUIRE");
    return (e && *e) ? atoi(e) : CLAMD_ABI_VERSION;
}

static const clamd_abi *abi_get(pTHX) {
    UV p = 0;
    int need = abi_required();

    if (ABI) {
        if (ABI->abi_version < need)
            croak("TestConsumer: ClamAV::Clamd ABI version %d, need >= %d",
                  ABI->abi_version, need);
        return ABI;
    }

    {
        dSP;
        int n;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        n = call_pv("ClamAV::Clamd::_abi_ptr", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (n == 1) {
            /* POPs ONCE into a variable, then convert. SvUV/SvIV wrapped
             * directly around POPs evaluates its argument more than once
             * and corrupts the stack before perl 5.30. */
            SV *res = POPs;
            p = SvUV(res);
        }
        PUTBACK; FREETMPS; LEAVE;
    }

    if (!p) croak("TestConsumer: ClamAV::Clamd::_abi_ptr gave nothing");

    ABI = INT2PTR(const clamd_abi *, p);

    /* GREATER-OR-EQUAL, never equality. The table is append-only, so a
     * later version is a superset whose prefix stays valid; == turns
     * every provider release into a breaking change for its consumers. */
    if (ABI->abi_version < need)
        croak("TestConsumer: ClamAV::Clamd ABI version %d, need >= %d",
              ABI->abi_version, need);

    return ABI;
}

MODULE = TestConsumer   PACKAGE = TestConsumer

PROTOTYPES: DISABLE

UV
abi_version()
  CODE:
    RETVAL = (UV)abi_get(aTHX)->abi_version;
  OUTPUT:
    RETVAL

# Scan bytes entirely in C: no Perl object, no verdict hashref, nothing
# crossing back over except the answer.
void
scan(sockpath, bytes)
    const char *sockpath
    SV *bytes
  PREINIT:
    const clamd_abi *abi;
    void *target, *scan;
    const char *sig, *reason;
    size_t siglen = 0, rlen = 0;
    STRLEN blen;
    const char *bp;
  PPCODE:
    abi = abi_get(aTHX);
    bp  = SvPV(bytes, blen);

    target = abi->target_new(aTHX_ sockpath, NULL, 0);
    if (!target) croak("TestConsumer: target_new failed");

    scan = abi->scan_mem(aTHX_ target, bp, (size_t)blen);
    if (!scan) { abi->target_free(aTHX_ target); croak("TestConsumer: scan_mem failed"); }

    sig    = abi->verdict_signature(aTHX_ scan, &siglen);
    reason = abi->verdict_reason(aTHX_ scan, &rlen);

    EXTEND(SP, 3);
    PUSHs(sv_2mortal(newSViv(abi->verdict_state(aTHX_ scan))));
    PUSHs(sig    ? sv_2mortal(newSVpvn(sig, siglen))  : &PL_sv_undef);
    PUSHs(reason ? sv_2mortal(newSVpvn(reason, rlen)) : &PL_sv_undef);

    abi->scan_free(aTHX_ scan);
    abi->target_free(aTHX_ target);

# Drive a scan on a loop, from C, the way Punk's upload path would.
void
scan_driven(sockpath, bytes)
    const char *sockpath
    SV *bytes
  PREINIT:
    const clamd_abi *abi;
    void *target, *scan;
    int steps = 0;
    STRLEN blen;
    const char *bp;
    const char *sig;
    size_t siglen = 0;
  PPCODE:
    abi = abi_get(aTHX);
    bp  = SvPV(bytes, blen);

    target = abi->target_new(aTHX_ sockpath, NULL, 0);
    if (!target) croak("TestConsumer: target_new failed");
    scan = abi->scan_start_mem(aTHX_ target, bp, (size_t)blen);
    if (!scan) { abi->target_free(aTHX_ target); croak("TestConsumer: scan_start_mem failed"); }

    while (abi->scan_step(aTHX_ scan) == CLAMD_ABI_STEP_MORE) {
        struct pollfd pfd;
        int fd = abi->scan_socket(aTHX_ scan);
        if (fd < 0) break;
        pfd.fd = fd;
        pfd.events = (abi->scan_want(aTHX_ scan) == CLAMD_ABI_WANT_WRITE) ? POLLOUT : POLLIN;
        pfd.revents = 0;
        poll(&pfd, 1, 5000);
        if (++steps > 100000) break;
    }

    sig = abi->verdict_signature(aTHX_ scan, &siglen);

    EXTEND(SP, 3);
    PUSHs(sv_2mortal(newSViv(abi->verdict_state(aTHX_ scan))));
    PUSHs(sig ? sv_2mortal(newSVpvn(sig, siglen)) : &PL_sv_undef);
    PUSHs(sv_2mortal(newSViv(steps)));

    abi->scan_free(aTHX_ scan);
    abi->target_free(aTHX_ target);
