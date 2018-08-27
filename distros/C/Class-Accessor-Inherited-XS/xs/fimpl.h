#ifndef __INHERITED_XS_FIMPL_H_
#define __INHERITED_XS_FIMPL_H_

template <AccessorType type, AccessorOpts opts>
struct FImpl;

template <AccessorType type, AccessorOpts opts> static
void
CAIXS_accessor(pTHX_ SV** SP, CV* cv, HV* stash) {
    FImpl<type, opts>::CAIXS_accessor(aTHX_ SP, cv, stash);
}

template <AccessorType type, AccessorOpts opts>
struct CImpl;

template <AccessorType type> inline
shared_keys*
CAIXS_install_accessor(pTHX_ SV* full_name, AccessorOpts val) {
    return CImpl<type, AccessorOptsBF>::CAIXS_install_accessor(aTHX_ val, full_name);
}

#endif /* __INHERITED_XS_FIMPL_H_ */
