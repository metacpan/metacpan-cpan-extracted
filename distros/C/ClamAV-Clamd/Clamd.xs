/* ClamAV::Clamd
 *
 * The .xs lives at the top level, not under lib/. A single-XS dist with
 * its source under lib/ makes lib/Clamd.def while dlltool goes looking
 * for $(BASEEXT).def, and that is somebody else's three releases of
 * Win32 scar tissue already paid for.
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "clamav/clamd_conn.h"
#include "clamav/clamd_scan.h"
#include "clamav/clamd_verdict.h"
#include "clamav/clamd_abi_impl.h"

#define CC_DEF_PORT             3310
#define CC_DEF_CONNECT_TIMEOUT  5.0
#define CC_DEF_REPLY_TIMEOUT    30.0
#define CC_DEF_REPLY_MAX        (1024 * 1024)

static HV *cc_self_hv(pTHX_ SV *self, const char *who) {
    if (!self || !SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("ClamAV::Clamd::%s: not a ClamAV::Clamd object", who);
    return (HV *)SvRV(self);
}

/* Pull the target out of the object. The defaults live here as well as
 * in the constructor, so the C side stays usable on a hash that did not
 * come through new(). */
static void cc_target_from_hv(pTHX_ HV *self, cc_target *t) {
    SV **sv;

    memset(t, 0, sizeof *t);
    t->connect_timeout = CC_DEF_CONNECT_TIMEOUT;
    t->reply_timeout   = CC_DEF_REPLY_TIMEOUT;
    t->reply_max       = CC_DEF_REPLY_MAX;
    t->frame           = CC_FRAME_Z;
    t->port            = CC_DEF_PORT;

    if ((sv = hv_fetchs(self, "socket", 0)) && *sv && SvOK(*sv))
        t->path = SvPV_nolen(*sv);
    if ((sv = hv_fetchs(self, "host", 0)) && *sv && SvOK(*sv))
        t->host = SvPV_nolen(*sv);
    if ((sv = hv_fetchs(self, "port", 0)) && *sv && SvOK(*sv))
        t->port = (int)SvIV(*sv);
    if ((sv = hv_fetchs(self, "connect_timeout", 0)) && *sv && SvOK(*sv))
        t->connect_timeout = SvNV(*sv);
    if ((sv = hv_fetchs(self, "reply_timeout", 0)) && *sv && SvOK(*sv))
        t->reply_timeout = SvNV(*sv);
    if ((sv = hv_fetchs(self, "reply_max", 0)) && *sv && SvOK(*sv))
        t->reply_max = (size_t)SvUV(*sv);
    if ((sv = hv_fetchs(self, "chunk", 0)) && *sv && SvOK(*sv))
        t->chunk = (size_t)SvUV(*sv);
    if ((sv = hv_fetchs(self, "max_size", 0)) && *sv && SvOK(*sv))
        t->max_size = (size_t)SvUV(*sv);
    if ((sv = hv_fetchs(self, "frame", 0)) && *sv && SvOK(*sv)) {
        const char *f = SvPV_nolen(*sv);
        t->frame = (*f == 'n') ? CC_FRAME_N : CC_FRAME_Z;
    }
}

static void cc_clear_error(pTHX_ HV *self) {
    (void)hv_delete(self, "error", 5, G_DISCARD);
    (void)hv_delete(self, "error_code", 10, G_DISCARD);
}

static void cc_set_error(pTHX_ HV *self, int code, const char *msg) {
    (void)hv_stores(self, "error_code", newSViv(code));
    (void)hv_stores(self, "error", newSVpv(msg ? msg : "unknown error", 0));
}

/* One command, one connection. Returns a mortal SV holding the reply, or
 * NULL with error/error_code set on the object.
 *
 * Nothing operational croaks: a clamd that went away mid-request is a
 * condition the caller handles, not a bug in their program. */
static SV *cc_do_command(pTHX_ SV *self, const char *cmd, const char *who) {
    HV       *hv = cc_self_hv(aTHX_ self, who);
    cc_target t;
    cc_err    err;
    char     *reply = NULL;
    size_t    len   = 0;
    int       rc;
    SV       *out;

    cc_clear_error(aTHX_ hv);
    cc_target_from_hv(aTHX_ hv, &t);

    memset(&err, 0, sizeof err);
    rc = cc_roundtrip(&t, cmd, &reply, &len, &err);

    if (rc != CC_OK) {
        cc_set_error(aTHX_ hv, rc, err.msg[0] ? err.msg : "unknown error");
        if (reply) free(reply);
        return NULL;
    }

    out = sv_2mortal(newSVpvn(reply ? reply : "", len));
    if (reply) free(reply);
    return out;
}

/* A command whose reply must be one exact word. Anything else is a
 * protocol failure and must not read as success. */
static SV *cc_do_exact(pTHX_ SV *self, const char *cmd, const char *want,
                       const char *who) {
    SV *r = cc_do_command(aTHX_ self, cmd, who);
    if (!r) return NULL;
    {
        STRLEN l;
        const char *p = SvPV(r, l);
        if (l == strlen(want) && memcmp(p, want, l) == 0)
            return r;
    }
    {
        HV  *hv = (HV *)SvRV(self);
        SV  *m  = sv_2mortal(newSVpvf("unexpected reply to %s: %" SVf, cmd, SVfARG(r)));
        cc_set_error(aTHX_ hv, CC_ERR_IO, SvPV_nolen(m));
    }
    return NULL;
}

/* Accept either a raw descriptor number or a Perl filehandle, because
 * the caller who has a file open has a filehandle - Punk::Upload's fh
 * among them - and making them dig out fileno() is a papercut with a
 * wrong answer available (calling fileno on the wrong thing). */
static int cc_fileno(pTHX_ SV *sv) {
    if (!sv || !SvOK(sv)) return -1;

    if (SvROK(sv) || SvTYPE(sv) == SVt_PVGV) {
        IO *io = sv_2io(sv);
        if (io && IoIFP(io)) {
            int fd = PerlIO_fileno(IoIFP(io));
            return fd < 0 ? -1 : fd;
        }
        return -1;
    }
    if (SvIOK(sv) || looks_like_number(sv)) {
        IV v = SvIV(sv);
        return (v < 0 || v > 0x7fffffff) ? -1 : (int)v;
    }
    return -1;
}

/* Shared tail for the scan entry points.
 *
 * ALWAYS returns a verdict, including when the scan never reached clamd.
 * Returning undef on a timeout would mean
 *
 *     if ($clamd->scan($x)->is_clean) { ... }
 *
 * dies on the one path where it most matters. The safe reading has to be
 * the short one, so every scan yields something is_clean() can be called
 * on, and is_clean() is true for exactly one of the four states.
 */
static SV *cc_scan_result(pTHX_ HV *hv, int rc, char *reply, size_t len,
                          int transport, cc_err *err) {
    cc_verdict  v;
    HV         *vh;
    SV         *rv;

    (void)hv_stores(hv, "transport", newSViv(transport));

    if (rc == CC_OK) {
        cc_parse_reply(reply ? reply : "", len, &v);
    } else {
        cc_verdict_from_error(rc, &v);
        cc_set_error(aTHX_ hv, rc, err->msg[0] ? err->msg : "unknown error");
    }

    vh = newHV();
    (void)hv_stores(vh, "state", newSVpv(cc_state_name(v.state), 0));
    (void)hv_stores(vh, "signature",
                    v.signature[0] ? newSVpv(v.signature, 0) : newSV(0));
    (void)hv_stores(vh, "reason",
                    v.reason[0] ? newSVpv(v.reason, 0) : newSV(0));
    (void)hv_stores(vh, "transport",
                    transport == CC_TRANSPORT_FILDES   ? newSVpvs("fildes")   :
                    transport == CC_TRANSPORT_INSTREAM ? newSVpvs("instream") : newSV(0));
    (void)hv_stores(vh, "raw",
                    (rc == CC_OK) ? newSVpvn(reply ? reply : "", len) : newSV(0));
    (void)hv_stores(vh, "error",
                    (rc == CC_OK) ? newSV(0)
                                  : newSVpv(err->msg[0] ? err->msg : "unknown error", 0));

    if (reply) free(reply);

    rv = newRV_noinc((SV *)vh);
    (void)sv_bless(rv, gv_stashpvs("ClamAV::Clamd::Verdict", GV_ADD));
    return sv_2mortal(rv);
}

static SV *cc_vfield(pTHX_ SV *self, const char *key, I32 klen) {
    SV **sv;
    if (!self || !SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("ClamAV::Clamd::Verdict: not a verdict");
    sv = hv_fetch((HV *)SvRV(self), key, klen, 0);
    return (sv && *sv && SvOK(*sv)) ? *sv : NULL;
}

static cc_scan *cc_scan_of(pTHX_ SV *self) {
    SV **e;
    if (!self || !SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("ClamAV::Clamd::Scan: not a scan handle");
    e = hv_fetchs((HV *)SvRV(self), "_ptr", 0);
    return (e && *e && SvIOK(*e)) ? INT2PTR(cc_scan *, SvIV(*e)) : NULL;
}

static int cc_vstate_is(pTHX_ SV *self, const char *want) {
    SV *s = cc_vfield(aTHX_ self, "state", 5);
    return s && strEQ(SvPV_nolen(s), want);
}

MODULE = ClamAV::Clamd    PACKAGE = ClamAV::Clamd    PREFIX = cc_

PROTOTYPES: DISABLE

BOOT:
{
    HV *stash = gv_stashpvs("ClamAV::Clamd", GV_ADD);
    newCONSTSUB(stash, "CC_OK",       newSViv(CC_OK));
    newCONSTSUB(stash, "ERR_CONNECT", newSViv(CC_ERR_CONNECT));
    newCONSTSUB(stash, "ERR_TIMEOUT", newSViv(CC_ERR_TIMEOUT));
    newCONSTSUB(stash, "ERR_IO",      newSViv(CC_ERR_IO));
    newCONSTSUB(stash, "ERR_TOOBIG",  newSViv(CC_ERR_TOOBIG));
    newCONSTSUB(stash, "ERR_CONFIG",  newSViv(CC_ERR_CONFIG));
    newCONSTSUB(stash, "ERR_CLOSED",  newSViv(CC_ERR_CLOSED));
    newCONSTSUB(stash, "ERR_NOTREG",   newSViv(CC_ERR_NOTREG));
    newCONSTSUB(stash, "ERR_NOFDPASS", newSViv(CC_ERR_NOFDPASS));
    newCONSTSUB(stash, "ERR_STREAMCUT", newSViv(CC_ERR_STREAMCUT));
    newCONSTSUB(stash, "ERR_TOOBIGLOCAL", newSViv(CC_ERR_TOOBIGLOC));
}

# Validates and stores. Nothing connects here.
#
# Configuration that cannot work croaks - that is a mistake in the
# caller's program and should not be survivable. Operational failure is
# reported through error()/error_code() instead.
SV *
cc_new(class, ...)
    SV *class
  PREINIT:
    HV *self;
    I32 i;
    SV **sv;
    const char *frame;
    STRLEN flen;
    int have_socket, have_host;
  CODE:
    if ((items - 1) % 2)
        croak("ClamAV::Clamd->new: expected a list of key => value pairs");

    self = newHV();
    (void)hv_stores(self, "port",            newSViv(CC_DEF_PORT));
    (void)hv_stores(self, "connect_timeout", newSVnv(CC_DEF_CONNECT_TIMEOUT));
    (void)hv_stores(self, "reply_timeout",   newSVnv(CC_DEF_REPLY_TIMEOUT));
    (void)hv_stores(self, "reply_max",       newSVuv(CC_DEF_REPLY_MAX));
    (void)hv_stores(self, "frame",           newSVpvs("z"));

    for (i = 1; i < items; i += 2) {
        STRLEN klen;
        const char *k = SvPV(ST(i), klen);
        (void)hv_store(self, k, (I32)klen, newSVsv(ST(i + 1)), 0);
    }

    sv = hv_fetchs(self, "socket", 0);
    have_socket = (sv && *sv && SvOK(*sv));
    sv = hv_fetchs(self, "host", 0);
    have_host = (sv && *sv && SvOK(*sv));

    if (!have_socket && !have_host) {
        SvREFCNT_dec((SV *)self);
        croak("ClamAV::Clamd->new: one of 'socket' or 'host' is required");
    }
    if (have_socket && have_host) {
        SvREFCNT_dec((SV *)self);
        croak("ClamAV::Clamd->new: give 'socket' or 'host', not both");
    }

    /* A UNIX socket path that does not fit sockaddr_un is refused here,
     * loudly, rather than truncated by the kernel. A truncated path
     * connects to a DIFFERENT socket - and a scanner that believes an
     * answer from an unidentified peer is worse than one that fails. */
    if (have_socket) {
#ifdef _WIN32
        SvREFCNT_dec((SV *)self);
        croak("ClamAV::Clamd->new: UNIX sockets are not supported on this platform; use host/port");
#else
        STRLEN plen;
        SV **psv = hv_fetchs(self, "socket", 0);
        const char *p = SvPV(*psv, plen);
        if (plen >= CC_SUN_PATH_MAX) {
            SV *msg = sv_2mortal(newSVpvf(
                "ClamAV::Clamd->new: socket path is %" UVuf
                " bytes, this platform allows %" UVuf ": %s",
                (UV)plen, (UV)(CC_SUN_PATH_MAX - 1), p));
            SvREFCNT_dec((SV *)self);
            croak("%s", SvPV_nolen(msg));
        }
#endif
    }

    sv = hv_fetchs(self, "frame", 0);
    frame = (sv && *sv && SvOK(*sv)) ? SvPV(*sv, flen) : "z";
    if (!(flen == 1 && (*frame == 'z' || *frame == 'n'))) {
        SvREFCNT_dec((SV *)self);
        croak("ClamAV::Clamd->new: frame must be 'z' or 'n'");
    }

    {
        const char *keys[2];
        int n;
        keys[0] = "connect_timeout";
        keys[1] = "reply_timeout";
        for (n = 0; n < 2; n++) {
            SV **t = hv_fetch(self, keys[n], (I32)strlen(keys[n]), 0);
            if (!t || !*t || !SvOK(*t) || SvNV(*t) <= 0.0) {
                SV *msg = sv_2mortal(newSVpvf(
                    "ClamAV::Clamd->new: %s must be a positive number", keys[n]));
                SvREFCNT_dec((SV *)self);
                croak("%s", SvPV_nolen(msg));
            }
        }
    }

    RETVAL = sv_bless(newRV_noinc((SV *)self), gv_stashsv(class, GV_ADD));
  OUTPUT:
    RETVAL

# True if clamd answered PONG. Undef on any failure, with error() set.
void
cc_ping(self)
    SV *self
  PPCODE:
    if (!cc_do_exact(aTHX_ self, "PING", "PONG", "ping"))
        XSRETURN_UNDEF;
    XSRETURN_YES;

# clamd's version string, or undef.
void
cc_version(self)
    SV *self
  PREINIT:
    SV *r;
  PPCODE:
    r = cc_do_command(aTHX_ self, "VERSION", "version");
    if (!r) XSRETURN_UNDEF;
    XPUSHs(r);

# The STATS reply, or undef.
void
cc_stats(self)
    SV *self
  PREINIT:
    SV *r;
  PPCODE:
    r = cc_do_command(aTHX_ self, "STATS", "stats");
    if (!r) XSRETURN_UNDEF;
    XPUSHs(r);

# Asks clamd to reload its signature database. True if it accepted.
void
cc_reload(self)
    SV *self
  PPCODE:
    if (!cc_do_exact(aTHX_ self, "RELOAD", "RELOADING", "reload"))
        XSRETURN_UNDEF;
    XSRETURN_YES;

# The failure from the last command, or undef if it succeeded.
void
cc_error(self)
    SV *self
  PREINIT:
    SV **sv;
  PPCODE:
    sv = hv_fetchs(cc_self_hv(aTHX_ self, "error"), "error", 0);
    if (!sv || !*sv || !SvOK(*sv)) XSRETURN_UNDEF;
    XPUSHs(sv_mortalcopy(*sv));

# The code for that failure, so failures can be told apart without
# matching on message text.
void
cc_error_code(self)
    SV *self
  PREINIT:
    SV **sv;
  PPCODE:
    sv = hv_fetchs(cc_self_hv(aTHX_ self, "error_code"), "error_code", 0);
    if (!sv || !*sv || !SvOK(*sv)) XSRETURN_UNDEF;
    XPUSHs(sv_mortalcopy(*sv));

# Scan an open descriptor or filehandle by passing it to clamd.
#
# The descriptor is BORROWED: never closed here, and never seeked -
# clamd scans the whole file wherever the descriptor is positioned, so
# there is nothing to correct and correcting it would mutate the
# caller's state.
void
cc_scan_fd(self, fh)
    SV *self
    SV *fh
  PREINIT:
    HV       *hv;
    cc_target t;
    cc_err    err;
    char     *reply = NULL;
    size_t    len   = 0;
    int       rc, fd, transport = CC_TRANSPORT_NONE;
    SV       *out;
  PPCODE:
    hv = cc_self_hv(aTHX_ self, "scan_fd");
    cc_clear_error(aTHX_ hv);

    fd = cc_fileno(aTHX_ fh);
    if (fd < 0) {
        cc_err bad; memset(&bad, 0, sizeof bad);
        cc_err_set(&bad, CC_ERR_CONFIG,
                   "scan_fd needs an open filehandle or a descriptor number", NULL);
        XPUSHs(cc_scan_result(aTHX_ hv, CC_ERR_CONFIG, NULL, 0, CC_TRANSPORT_NONE, &bad));
        XSRETURN(1);
    }

    cc_target_from_hv(aTHX_ hv, &t);
    memset(&err, 0, sizeof err);
    rc  = cc_scan_fd(&t, fd, &reply, &len, &transport, &err);
    XPUSHs(cc_scan_result(aTHX_ hv, rc, reply, len, transport, &err));

# Scan a path. The file is opened HERE and the descriptor is what
# travels - this is not clamd's SCAN command, and clamd needs no
# permission on the path.
void
cc_scan_path(self, path)
    SV *self
    const char *path
  PREINIT:
    HV       *hv;
    cc_target t;
    cc_err    err;
    char     *reply = NULL;
    size_t    len   = 0;
    int       rc, transport = CC_TRANSPORT_NONE;
    SV       *out;
  PPCODE:
    hv = cc_self_hv(aTHX_ self, "scan_path");
    cc_clear_error(aTHX_ hv);

    cc_target_from_hv(aTHX_ hv, &t);
    memset(&err, 0, sizeof err);
    rc  = cc_scan_path(&t, path, &reply, &len, &transport, &err);
    XPUSHs(cc_scan_result(aTHX_ hv, rc, reply, len, transport, &err));

# Scan bytes that were never a file.
#
# They go out from where they already are - no assembly buffer, no copy -
# because "already in memory" is the whole reason this path exists rather
# than spilling to a file and using scan_fd.
void
cc_scan(self, data)
    SV *self
    SV *data
  PREINIT:
    HV         *hv;
    cc_target   t;
    cc_err      err;
    char       *reply = NULL;
    size_t      len   = 0;
    int         rc;
    STRLEN      dlen;
    const char *dp;
    SV         *out;
  PPCODE:
    hv = cc_self_hv(aTHX_ self, "scan");
    cc_clear_error(aTHX_ hv);

    if (!data || !SvOK(data)) {
        cc_err bad; memset(&bad, 0, sizeof bad);
        cc_err_set(&bad, CC_ERR_CONFIG, "scan needs a defined scalar of bytes", NULL);
        XPUSHs(cc_scan_result(aTHX_ hv, CC_ERR_CONFIG, NULL, 0, CC_TRANSPORT_NONE, &bad));
        XSRETURN(1);
    }
    /* Wide characters are not bytes. Guessing an encoding here would
     * mean scanning something the caller never stored. */
    if (DO_UTF8(data) && !sv_utf8_downgrade(data, 1)) {
        cc_err bad; memset(&bad, 0, sizeof bad);
        cc_err_set(&bad, CC_ERR_CONFIG,
                   "scan needs bytes, not wide characters; encode it first", NULL);
        XPUSHs(cc_scan_result(aTHX_ hv, CC_ERR_CONFIG, NULL, 0, CC_TRANSPORT_NONE, &bad));
        XSRETURN(1);
    }

    dp = SvPV_const(data, dlen);

    cc_target_from_hv(aTHX_ hv, &t);
    memset(&err, 0, sizeof err);
    if (t.max_size && (size_t)dlen > t.max_size) {
        cc_err_set(&err, CC_ERR_TOOBIGLOC,
                   "larger than max_size; refused without scanning", NULL);
        rc = CC_ERR_TOOBIGLOC;
    } else {
        cc_scan sc;
        rc = cc_scan_start(&sc, &t, CC_TRANSPORT_INSTREAM, -1, 0,
                           dp, (size_t)dlen, -1);
        if (rc == CC_OK) rc = cc_scan_run(&sc, &reply, &len, &err);
        else err = sc.err;
        cc_scan_free(&sc);
    }
    XPUSHs(cc_scan_result(aTHX_ hv, rc, reply, len, CC_TRANSPORT_INSTREAM, &err));

# Which transport produced the last scan: 'fildes', 'instream', or undef.
void
cc_transport(self)
    SV *self
  PREINIT:
    SV **sv;
    IV   v;
  PPCODE:
    sv = hv_fetchs(cc_self_hv(aTHX_ self, "transport"), "transport", 0);
    if (!sv || !*sv || !SvOK(*sv)) XSRETURN_UNDEF;
    v = SvIV(*sv);
    if (v == CC_TRANSPORT_FILDES)        XPUSHs(sv_2mortal(newSVpvs("fildes")));
    else if (v == CC_TRANSPORT_INSTREAM) XPUSHs(sv_2mortal(newSVpvs("instream")));
    else XSRETURN_UNDEF;

# Whether this platform can pass descriptors over a socket. False on
# Windows, which has AF_UNIX but no SCM_RIGHTS. Phase 2 needs it, and it
# is a platform fact rather than a runtime guess.
IV
cc_have_fd_passing(...)
  CODE:
    PERL_UNUSED_VAR(items);
    RETVAL = CC_HAVE_FD_PASSING;
  OUTPUT:
    RETVAL

# The platform's sockaddr_un limit, so a refusal can name what it
# refused. Zero where UNIX sockets do not exist.
UV
cc__sun_path_max()
  CODE:
#ifdef _WIN32
    RETVAL = 0;
#else
    RETVAL = (UV)CC_SUN_PATH_MAX;
#endif
  OUTPUT:
    RETVAL

MODULE = ClamAV::Clamd    PACKAGE = ClamAV::Clamd::Verdict    PREFIX = ccv_

PROTOTYPES: DISABLE

# 'clean', 'infected', 'unscannable' or 'error'.
void
ccv_state(self)
    SV *self
  PREINIT:
    SV *s;
  PPCODE:
    s = cc_vfield(aTHX_ self, "state", 5);
    if (!s) XSRETURN_UNDEF;
    XPUSHs(sv_mortalcopy(s));

# TRUE FOR EXACTLY ONE STATE.
#
# Everything else - infected, unscannable, and every failure to reach
# clamd at all - is false here. A caller who wants to accept an upload
# writes one short safe thing; a caller who wants to reject one has more
# to think about, which is the right way round.
void
ccv_is_clean(self)
    SV *self
  PPCODE:
    if (cc_vstate_is(aTHX_ self, "clean")) XSRETURN_YES;
    XSRETURN_NO;

void
ccv_is_infected(self)
    SV *self
  PPCODE:
    if (cc_vstate_is(aTHX_ self, "infected")) XSRETURN_YES;
    XSRETURN_NO;

# NOT scanned, or not scanned completely: over a size ceiling, nested
# past MaxRecursion, an encrypted archive clamd could not open. Never
# the same thing as clean, however much clamd's own reply looks like it.
void
ccv_is_unscannable(self)
    SV *self
  PPCODE:
    if (cc_vstate_is(aTHX_ self, "unscannable")) XSRETURN_YES;
    XSRETURN_NO;

void
ccv_is_error(self)
    SV *self
  PPCODE:
    if (cc_vstate_is(aTHX_ self, "error")) XSRETURN_YES;
    XSRETURN_NO;

# The signature clamd named, or undef.
#
# THIS IS REMOTE INPUT. A file crafted to match a chosen signature
# chooses the string that comes back. It is length-bounded, and it
# belongs in a log, not in a response body.
void
ccv_signature(self)
    SV *self
  PREINIT:
    SV *s;
  PPCODE:
    s = cc_vfield(aTHX_ self, "signature", 9);
    if (!s) XSRETURN_UNDEF;
    XPUSHs(sv_mortalcopy(s));

# Why it could not be scanned: 'MaxFileSize', 'MaxRecursion',
# 'StreamMaxLength', 'Encrypted', 'max_size'. Undef unless unscannable.
void
ccv_reason(self)
    SV *self
  PREINIT:
    SV *s;
  PPCODE:
    s = cc_vfield(aTHX_ self, "reason", 6);
    if (!s) XSRETURN_UNDEF;
    XPUSHs(sv_mortalcopy(s));

# 'fildes' or 'instream'.
void
ccv_transport(self)
    SV *self
  PREINIT:
    SV *s;
  PPCODE:
    s = cc_vfield(aTHX_ self, "transport", 9);
    if (!s) XSRETURN_UNDEF;
    XPUSHs(sv_mortalcopy(s));

# What went wrong, when nothing usable came back.
void
ccv_error(self)
    SV *self
  PREINIT:
    SV *s;
  PPCODE:
    s = cc_vfield(aTHX_ self, "error", 5);
    if (!s) XSRETURN_UNDEF;
    XPUSHs(sv_mortalcopy(s));

# clamd's reply verbatim, for logging something the parser did not
# anticipate.
void
ccv_raw(self)
    SV *self
  PREINIT:
    SV *s;
  PPCODE:
    s = cc_vfield(aTHX_ self, "raw", 3);
    if (!s) XSRETURN_UNDEF;
    XPUSHs(sv_mortalcopy(s));

# --- overloading, registered from XS ---------------------------------
#
# An object is always true, so the most dangerous plausible misuse of
# this API is
#
#     "if (\$clamd->scan(\$file)) { accept() }"
#
# which would accept every infected file there is. Wiring bool to
# is_clean turns that from a silent catastrophe into the correct
# behaviour, and it costs a caller who wanted the object nothing.
#
# Stringification gives the state, so a log line reads "infected" rather
# than an address.

void
_ovl_nil(...)
  PPCODE:
    PERL_UNUSED_VAR(items);
    XSRETURN_UNDEF;

void
_ovl_bool(self, ...)
    SV *self
  PPCODE:
    PERL_UNUSED_VAR(items);
    if (cc_vstate_is(aTHX_ self, "clean")) XSRETURN_YES;
    XSRETURN_NO;

void
_ovl_str(self, ...)
    SV *self
  PREINIT:
    SV *s;
  PPCODE:
    PERL_UNUSED_VAR(items);
    s = cc_vfield(aTHX_ self, "state", 5);
    XPUSHs(s ? sv_mortalcopy(s) : sv_2mortal(newSVpvs("error")));

BOOT:
{
    HV *vst = gv_stashpvs("ClamAV::Clamd::Verdict", GV_ADD);
    newXS("ClamAV::Clamd::Verdict::()",
          XS_ClamAV__Clamd__Verdict__ovl_nil,  __FILE__);
    newXS("ClamAV::Clamd::Verdict::(bool",
          XS_ClamAV__Clamd__Verdict__ovl_bool, __FILE__);
    newXS("ClamAV::Clamd::Verdict::(\"\"",
          XS_ClamAV__Clamd__Verdict__ovl_str,  __FILE__);
    /* the () glob's scalar carries the fallback setting */
    sv_setiv(GvSV(gv_fetchpvs("ClamAV::Clamd::Verdict::()",
                              GV_ADD|GV_ADDMULTI, SVt_PV)), 1);
    mro_method_changed_in(vst);
}

MODULE = ClamAV::Clamd    PACKAGE = ClamAV::Clamd    PREFIX = cca_

PROTOTYPES: DISABLE

# Start a scan without waiting for it.
#
# Returns a ClamAV::Clamd::Scan: a socket to register with whatever loop
# you have, a readiness to wait for, and a step to call. This dist owns
# no loop and depends on none.
#
# The handle keeps a reference to whatever the scan reads from - the byte
# scalar, or the filehandle - because the scan outlives the call that
# started it and a freed PV would be read after free.
SV *
cca_start_scan(self, what, ...)
    SV *self
    SV *what
  PREINIT:
    HV       *hv, *h;
    cc_target t;
    cc_scan  *sc;
    int       rc, mode, fd = -1;
    const char *kind;
    STRLEN    dlen = 0;
    const char *dp = NULL;
    SV       *keep = NULL;
  CODE:
    hv = cc_self_hv(aTHX_ self, "start_scan");
    cc_clear_error(aTHX_ hv);
    cc_target_from_hv(aTHX_ hv, &t);

    kind = (items > 2) ? SvPV_nolen(ST(2)) : "bytes";

    sc = (cc_scan *)malloc(sizeof *sc);
    if (!sc) croak("ClamAV::Clamd->start_scan: out of memory");
    memset(sc, 0, sizeof *sc);
    sc->sock = CC_INVALID_SOCK;

    if (strEQ(kind, "path")) {
        const char *path = SvPV_nolen(what);
        fd = open(path, O_RDONLY);
        if (fd < 0) {
            cc_err_set(&sc->err, CC_ERR_IO, "open", strerror(errno));
            sc->rc = CC_ERR_IO; sc->phase = CC_PH_DONE;
            goto made;
        }
        mode = (CC_HAVE_FD_PASSING && t.path) ? CC_TRANSPORT_FILDES : CC_TRANSPORT_INSTREAM;
        if (mode == CC_TRANSPORT_FILDES)
            rc = cc_scan_start(sc, &t, mode, fd, 1, NULL, 0, -1);
        else
            rc = cc_scan_start(sc, &t, mode, -1, 1, NULL, 0, fd);
        (void)rc;
    }
    else if (strEQ(kind, "fd")) {
        fd = cc_fileno(aTHX_ what);
        if (fd < 0) {
            cc_err_set(&sc->err, CC_ERR_CONFIG,
                       "start_scan needs an open filehandle or descriptor", NULL);
            sc->rc = CC_ERR_CONFIG; sc->phase = CC_PH_DONE;
            goto made;
        }
        keep = what;
        mode = (CC_HAVE_FD_PASSING && t.path) ? CC_TRANSPORT_FILDES : CC_TRANSPORT_INSTREAM;
        if (mode == CC_TRANSPORT_FILDES)
            rc = cc_scan_start(sc, &t, mode, fd, 0, NULL, 0, -1);
        else
            rc = cc_scan_start(sc, &t, mode, -1, 0, NULL, 0, fd);
        (void)rc;
    }
    else {
        if (!SvOK(what)) {
            cc_err_set(&sc->err, CC_ERR_CONFIG, "start_scan needs bytes", NULL);
            sc->rc = CC_ERR_CONFIG; sc->phase = CC_PH_DONE;
            goto made;
        }
        if (DO_UTF8(what) && !sv_utf8_downgrade(what, 1)) {
            cc_err_set(&sc->err, CC_ERR_CONFIG,
                       "start_scan needs bytes, not wide characters", NULL);
            sc->rc = CC_ERR_CONFIG; sc->phase = CC_PH_DONE;
            goto made;
        }
        dp = SvPV_const(what, dlen);
        keep = what;
        if (t.max_size && (size_t)dlen > t.max_size) {
            cc_err_set(&sc->err, CC_ERR_TOOBIGLOC,
                       "larger than max_size; refused without scanning", NULL);
            sc->rc = CC_ERR_TOOBIGLOC; sc->phase = CC_PH_DONE;
            goto made;
        }
        (void)cc_scan_start(sc, &t, CC_TRANSPORT_INSTREAM, -1, 0, dp, (size_t)dlen, -1);
    }

  made:
    h = newHV();
    (void)hv_stores(h, "_ptr", newSViv(PTR2IV(sc)));
    /* Hold the source alive for as long as the scan can read it. */
    if (keep) (void)hv_stores(h, "_keep", newSVsv(keep));
    RETVAL = sv_bless(newRV_noinc((SV *)h),
                      gv_stashpvs("ClamAV::Clamd::Scan", GV_ADD));
  OUTPUT:
    RETVAL

MODULE = ClamAV::Clamd    PACKAGE = ClamAV::Clamd::Scan    PREFIX = ccs_

PROTOTYPES: DISABLE

# The socket to register with a loop. Undef once finished - there is
# nothing left to watch, and watching a closed descriptor is how a loop
# ends up dispatching on somebody else's connection.
void
ccs_fd(self)
    SV *self
  PREINIT:
    cc_scan *sc;
  PPCODE:
    sc = cc_scan_of(aTHX_ self);
    if (!sc || sc->sock == CC_INVALID_SOCK) XSRETURN_UNDEF;
    XPUSHs(sv_2mortal(newSViv(sc->sock)));

# 'read', 'write', or undef when finished.
void
ccs_want(self)
    SV *self
  PREINIT:
    cc_scan *sc;
  PPCODE:
    sc = cc_scan_of(aTHX_ self);
    if (!sc || sc->phase == CC_PH_DONE) XSRETURN_UNDEF;
    if (sc->want == CC_WANT_READ)  XPUSHs(sv_2mortal(newSVpvs("read")));
    else if (sc->want == CC_WANT_WRITE) XPUSHs(sv_2mortal(newSVpvs("write")));
    else XSRETURN_UNDEF;

# Advance as far as possible without blocking. True when finished.
void
ccs_step(self)
    SV *self
  PREINIT:
    cc_scan *sc;
  PPCODE:
    sc = cc_scan_of(aTHX_ self);
    if (!sc) XSRETURN_YES;
    if (cc_scan_step(sc) == CC_STEP_DONE) XSRETURN_YES;
    XSRETURN_NO;

void
ccs_is_done(self)
    SV *self
  PREINIT:
    cc_scan *sc;
  PPCODE:
    sc = cc_scan_of(aTHX_ self);
    if (!sc || sc->phase == CC_PH_DONE) XSRETURN_YES;
    XSRETURN_NO;

# The verdict, once finished. Undef while the scan is still running -
# asking early is a question with no answer, not a clean one.
#
# Built once and kept. cc_scan_result consumes the reply buffer, so
# rebuilding on a second call would parse an empty string and quietly
# return a DIFFERENT verdict from the first - an accessor that changes
# its answer when you ask twice.
void
ccs_verdict(self)
    SV *self
  PREINIT:
    cc_scan *sc;
    HV      *h, *dummy;
    SV     **cached;
    SV      *v;
  PPCODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("ClamAV::Clamd::Scan: not a scan handle");
    h = (HV *)SvRV(self);

    cached = hv_fetchs(h, "_verdict", 0);
    if (cached && *cached && SvOK(*cached)) {
        XPUSHs(sv_mortalcopy(*cached));
        XSRETURN(1);
    }

    sc = cc_scan_of(aTHX_ self);
    if (!sc || sc->phase != CC_PH_DONE) XSRETURN_UNDEF;

    dummy = newHV();
    sv_2mortal(newRV_noinc((SV *)dummy));
    v = cc_scan_result(aTHX_ dummy, sc->rc, sc->reply, sc->replylen,
                       sc->transport, &sc->err);
    sc->reply = NULL;          /* cc_scan_result took it */

    (void)hv_stores(h, "_verdict", newSVsv(v));
    XPUSHs(v);

# Abandon a scan in flight.
#
# The connection is CLOSED, never kept. clamd is still going to answer,
# and a connection carrying an unread verdict would hand that verdict to
# whichever scan picked it up next.
void
ccs_cancel(self)
    SV *self
  PREINIT:
    cc_scan *sc;
  PPCODE:
    sc = cc_scan_of(aTHX_ self);
    if (sc) cc_scan_cancel(sc);
    XSRETURN_EMPTY;

void
ccs_DESTROY(self)
    SV *self
  PREINIT:
    cc_scan *sc;
    HV      *h;
  PPCODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) XSRETURN_EMPTY;
    h  = (HV *)SvRV(self);
    sc = cc_scan_of(aTHX_ self);
    if (sc) { cc_scan_free(sc); free(sc); }
    (void)hv_delete(h, "_ptr", 4, G_DISCARD);

MODULE = ClamAV::Clamd    PACKAGE = ClamAV::Clamd    PREFIX = ccab_

PROTOTYPES: DISABLE

# The ABI table's address. Private - not public API.
#
# UV, not IV. An address is unsigned, and PTR2IV hands back a NEGATIVE
# integer wherever the shared object maps with the top bit set, so a
# consumer's "$ptr > 0" sanity check fails on a perfectly usable pointer.
UV
ccab__abi_ptr()
  CODE:
    RETVAL = PTR2UV(&CLAMD_ABI);
  OUTPUT:
    RETVAL

# Drive the table through its own function pointers, so this dist's own
# suite exercises the ABI the way a consumer does rather than the way the
# XS above happens to.
void
ccab__abi_selftest(socket_path, bytes)
    SV *socket_path
    SV *bytes
  PREINIT:
    const clamd_abi *abi = &CLAMD_ABI;
    void *target, *scan;
    const char *sig;
    size_t siglen = 0;
    STRLEN blen;
    const char *bp;
  PPCODE:
    if (!SvOK(socket_path)) croak("_abi_selftest: need a socket path");
    bp = SvPV(bytes, blen);

    target = abi->target_new(aTHX_ SvPV_nolen(socket_path), NULL, 0);
    if (!target) croak("_abi_selftest: target_new failed");
    abi->target_timeouts(aTHX_ target, 5.0, 30.0);

    scan = abi->scan_mem(aTHX_ target, bp, (size_t)blen);
    if (!scan) { abi->target_free(aTHX_ target); croak("_abi_selftest: scan_mem failed"); }

    sig = abi->verdict_signature(aTHX_ scan, &siglen);

    EXTEND(SP, 4);
    PUSHs(sv_2mortal(newSViv(abi->abi_version)));
    PUSHs(sv_2mortal(newSViv(abi->verdict_state(aTHX_ scan))));
    PUSHs(sig ? sv_2mortal(newSVpvn(sig, siglen)) : &PL_sv_undef);
    PUSHs(sv_2mortal(newSViv(abi->verdict_transport(aTHX_ scan))));

    abi->scan_free(aTHX_ scan);
    abi->target_free(aTHX_ target);
