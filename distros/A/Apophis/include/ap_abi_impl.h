#ifndef AP_ABI_IMPL_H
#define AP_ABI_IMPL_H

/* Apophis-side implementation of the shared C ABI (ap_abi.h). Included by
 * lib/Apophis.xs AFTER the static core it wraps - apophis_derive_namespace,
 * apophis_identify_content, apophis_identify_stream, apophis_build_path,
 * apophis_ensure_parent_dir and apophis_atomic_write - and after horus.h, so
 * horus_format_uuid and HORUS_FMT_STR are in scope.
 *
 * Everything here is private to Apophis's translation unit; consumers reach
 * it only through the AP_ABI table returned by Apophis::_abi_ptr. */

#include "ap_abi.h"

/* Unlike apophis_get_ns / apophis_get_store_dir, this must not croak: the
 * whole point is that a consumer can hand it any SV and find out. */
static int ap_abi_store_of(pTHX_ SV *self, const unsigned char **ns_out,
                           const char **dir_out, STRLEN *dirlen_out) {
    HV  *hv;
    SV **svp;
    STRLEN nslen;

    if (!self || !sv_isobject(self)) return 0;
    hv = (HV *)SvRV(self);
    if (SvTYPE((SV *)hv) != SVt_PVHV) return 0;

    svp = hv_fetchs(hv, "_ns_bytes", 0);
    if (!svp || !SvOK(*svp)) return 0;
    if (ns_out) {
        *ns_out = (const unsigned char *)SvPV(*svp, nslen);
        if (nslen != 16) return 0;
    }

    svp = hv_fetchs(hv, "store_dir", 0);
    if (!svp || !SvOK(*svp)) return 0;
    if (dir_out) {
        STRLEN dl;
        *dir_out = SvPV(*svp, dl);
        if (dirlen_out) *dirlen_out = dl;
    }
    else if (dirlen_out) {
        (void)SvPV(*svp, *dirlen_out);
    }

    return 1;
}

static void ap_abi_derive_ns(unsigned char *ns_out,
                             const char *name, STRLEN len) {
    apophis_derive_namespace(ns_out, name, len);
}

static void ap_abi_identify(unsigned char *id_out, const unsigned char *ns,
                            const char *content, STRLEN len) {
    apophis_identify_content(id_out, ns, content, len);
}

static void ap_abi_identify_fh(pTHX_ unsigned char *id_out,
                               const unsigned char *ns, PerlIO *fh) {
    apophis_identify_stream(aTHX_ id_out, ns, fh);
}

static void ap_abi_format_id(char *buf, const unsigned char *id) {
    horus_format_uuid(buf, id, HORUS_FMT_STR);
    buf[HORUS_FMT_STR_LEN] = '\0';
}

static int ap_abi_build_path(char *out, size_t out_size,
                             const char *dir, STRLEN dirlen,
                             const char *id, STRLEN id_len) {
    if (id_len < 5) return -1;     /* the XSUB croaks; the ABI reports */
    return apophis_build_path(out, out_size, dir, dirlen, id, id_len);
}

static void ap_abi_write_atomic(pTHX_ const char *path,
                                const char *content, STRLEN len) {
    apophis_ensure_parent_dir(path);
    apophis_atomic_write(aTHX_ path, content, len);
}

static const ap_abi AP_ABI = {
    AP_ABI_VERSION,
    ap_abi_store_of,
    ap_abi_derive_ns,
    ap_abi_identify,
    ap_abi_identify_fh,
    ap_abi_format_id,
    ap_abi_build_path,
    ap_abi_write_atomic
};

#endif /* AP_ABI_IMPL_H */
