#ifndef __INHERITED_XS_UTIL_H_
#define __INHERITED_XS_UTIL_H_

inline MAGIC*
CAIXS_mg_findext(SV* sv, int type, MGVTBL* vtbl) {
    MAGIC* mg;

    if (sv) {
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
            if (mg->mg_type == type && mg->mg_virtual == vtbl) {
                return mg;
            }
        }
    }

    return NULL;
}

inline shared_keys*
CAIXS_find_payload(CV* cv) {
    shared_keys* payload;

#ifndef MULTIPLICITY
    /* Blessed are ye and get a fastpath */
    payload = (shared_keys*)(CvXSUBANY(cv).any_ptr);
    if (UNLIKELY(!payload)) croak("Can't find hash key information");
#else
    /*
        We can't look into CvXSUBANY under threads, as it could have been written in the parent thread
        and had gone away at any time without prior notice. So, instead, we have to scan our magical
        refcnt storage - there's always a proper thread-local SV*, cloned for us by perl itself.
    */
    MAGIC* mg = CAIXS_mg_findext((SV*)cv, PERL_MAGIC_ext, &sv_payload_marker);
    if (UNLIKELY(!mg)) croak("Can't find hash key information");

    payload = (shared_keys*)AvARRAY((AV*)(mg->mg_obj));
#endif

    return payload;
}

inline HV*
CAIXS_find_stash(pTHX_ SV* self, CV* cv) {
    HV* stash;

    if (SvROK(self)) {
        stash = SvSTASH(SvRV(self));

    } else {
        GV* acc_gv = CvGV(cv);
        if (UNLIKELY(!acc_gv)) croak("Can't have package accessor in anon sub");
        stash = GvSTASH(acc_gv);

        const char* stash_name = HvENAME(stash);
        const char* self_name = SvPV_nolen(self);
        if (strcmp(stash_name, self_name) != 0) {
            stash = gv_stashsv(self, GV_ADD);
            if (UNLIKELY(!stash)) croak("Couldn't get required stash");
        }
    }

    return stash;
}

static GV*
CAIXS_fetch_glob(pTHX_ HV* stash, SV* pkg_key) {
    HE* hent = hv_fetch_ent(stash, pkg_key, 0, 0);
    GV* glob = hent ? (GV*)HeVAL(hent) : NULL;

    if (UNLIKELY(!glob || !isGV(glob) || SvFAKE(glob))) {
        if (!glob) glob = (GV*)newSV(0);

        gv_init_sv(glob, stash, pkg_key, 0);

        if (hent) {
            /* There was just a stub instead of the full glob */
            SvREFCNT_inc_simple_void_NN((SV*)glob);
            SvREFCNT_dec_NN(HeVAL(hent));
            HeVAL(hent) = (SV*)glob;

        } else {
            if (!hv_store_ent(stash, pkg_key, (SV*)glob, 0)) {
                SvREFCNT_dec_NN(glob);
                croak("Couldn't add a glob to package");
            }
        }
    }

    return glob;
}

#endif /* __INHERITED_XS_UTIL_H_ */
