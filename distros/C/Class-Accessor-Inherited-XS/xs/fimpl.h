#ifndef __INHERITED_XS_FIMPL_H_
#define __INHERITED_XS_FIMPL_H_

template <AccessorType type, AccessorOpts opts>
struct FImpl;

template <AccessorType type, AccessorOpts opts> inline
void
CAIXS_accessor(pTHX_ SV** SP, CV* cv, HV* stash) {
    FImpl<type, opts>::CAIXS_accessor(aTHX_ SP, cv, stash);
}

#endif /* __INHERITED_XS_FIMPL_H_ */
