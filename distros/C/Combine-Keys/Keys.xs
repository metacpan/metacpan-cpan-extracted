#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"

AV* ckeys (AV* hashes) {
    int num_to_merge, i;
    HE *hash_entry;
    SV *sv_key, *hash_ref, *merge_ref;
    HV *merger, *hash;
    AV* hkeys = newAV();
    
    merger = newHV();
    num_to_merge = av_len(hashes) + 1;

    for (i = 0; i < num_to_merge; i++) {
	hash_ref = av_shift(hashes);        
        if (SvTYPE(SvRV(hash_ref)) != SVt_PVHV) croak("Index is not a hash reference %d", i); 
	hash = (HV*)SvRV(hash_ref);
        (void) hv_iterinit(hash);
        while ((hash_entry = hv_iternext(hash))) {
            sv_key = hv_iterkeysv(hash_entry);
            hv_store_ent(merger, sv_key, newSViv(1), 0);
        }
    }
     
    (void) hv_iterinit(merger);
    while ((hash_entry = hv_iternext(merger))) {
        sv_key = hv_iterkeysv(hash_entry);
        av_push(hkeys, newSVpvf("%s", SvPV(sv_key, PL_na)));
    }

    sortsv(AvARRAY(hkeys), av_len(hkeys)+1, Perl_sv_cmp_locale);
    return hkeys;
}


MODULE = Combine::Keys  PACKAGE = Combine::Keys 

PROTOTYPES: DISABLE


AV *
ckeys (hashes)
	AV *	hashes

