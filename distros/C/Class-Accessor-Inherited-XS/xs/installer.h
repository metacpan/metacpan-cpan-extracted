#ifndef __INHERITED_XS_INSTALLER_H_
#define __INHERITED_XS_INSTALLER_H_

inline void
CAIXS_payload_attach(pTHX_ CV* cv, AV* payload_av) {
#ifndef MULTIPLICITY
    CvXSUBANY(cv).any_ptr = (void*)AvARRAY(payload_av);
#endif

    sv_magicext((SV*)cv, (SV*)payload_av, PERL_MAGIC_ext, &sv_payload_marker, NULL, 0);
    SvREFCNT_dec_NN((SV*)payload_av);
    SvRMAGICAL_off((SV*)cv);
}

template <AccessorType type> static
shared_keys*
CAIXS_payload_init(pTHX_ CV* cv) {
    AV* payload_av = newAV();

    av_extend(payload_av, ALLOC_SIZE[type]);
    AvFILLp(payload_av) = ALLOC_SIZE[type];

    CAIXS_payload_attach(aTHX_ cv, payload_av);
    return (shared_keys*)AvARRAY(payload_av);
}

template <AccessorType type, AccessorOpts opts> static
CV*
CAIXS_install_cv(pTHX_ SV* full_name) {
    STRLEN len;

    const char* full_name_buf = SvPV_const(full_name, len);
#ifdef CAIX_BINARY_UNSAFE
    if (strnlen(full_name_buf, len) < len) {
        croak("Attempted to install binary accessor, but they're not supported on this perl");
    }
#endif

    CV* cv = Perl_newXS_len_flags(aTHX_ full_name_buf, len, (&CAIXS_entersub_wrapper<type, opts>), __FILE__, NULL, NULL, SvUTF8(full_name));
    if (!cv) croak("Can't install XS accessor");

    return cv;
}

template <AccessorType type> static
shared_keys*
CAIXS_install_accessor(pTHX_ SV* full_name, AccessorOpts opts) {
    CV* cv;

    if ((opts & (IsReadonly | IsWeak)) == (IsReadonly | IsWeak)) {
        cv = CAIXS_install_cv<type, (AccessorOpts)(IsReadonly | IsWeak)>(aTHX_ full_name);

    } else if (opts & IsReadonly) {
        cv = CAIXS_install_cv<type, IsReadonly>(aTHX_ full_name);

    } else if (opts & IsWeak) {
        cv = CAIXS_install_cv<type, IsWeak>(aTHX_ full_name);

    } else {
        cv = CAIXS_install_cv<type, None>(aTHX_ full_name);
    }

    return CAIXS_payload_init<type>(aTHX_ cv);
}

#endif /* __INHERITED_XS_INSTALLER_H_ */
