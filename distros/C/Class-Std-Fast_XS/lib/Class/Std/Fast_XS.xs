/*
 * This file is based on Class::XSAccessor
 * by Steffen Müller, Copyright (C) 2008 by Steffen Mueller
 *
 * Copyright (C) 2008 Martin Kutter
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "AutoXS.h"

HV * global_hash_ref;
HV * global_hierarchy_of;
HV * global_attribute_of;

HV* global_do_cache_class_of;
HV* global_cache_of;

autoxs_hashkey global_ref_key;

char * get_class(SV* obj, HV* class_stash) {
    char * class_name;
    class_stash = SvSTASH(SvRV(obj));
    if ((class_stash == NULL) || ((SV*)class_stash == &PL_sv_undef)) {
        croak("No stash found");
    }
    class_name = HvNAME(class_stash);
    if (class_name == NULL) {
        croak("Ooops: Lost object class name");
    }
    return class_name;
}


void init(SV* data_hash_ref, SV* attribute_hash_ref, SV * do_cache_class_ref, SV* cache_ref) {
    global_hash_ref = (HV*)SvRV(data_hash_ref);
    global_attribute_of = (HV*)SvRV(attribute_hash_ref);

    global_ref_key.key = newSVpvn("ref", 3);
    PERL_HASH(global_ref_key.hash, "ref", 3);

    global_hierarchy_of = newHV();

    global_do_cache_class_of = (HV*)SvRV(do_cache_class_ref);
    global_cache_of = (HV*)SvRV(cache_ref);

}

AV * hierarchy_of(char * class_name) {
    AV* retval = newAV();
    dSP;
    int count;
    int i;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(class_name,0)));
    PUTBACK;

    count = call_pv("Class::Std::Fast::_hierarchy_of", G_ARRAY);

    SPAGAIN;

    for (i = 1; i <= count; ++i) {
        av_push(retval, newSVsv(POPs));
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}

void demolish(SV* class_name, unsigned int class_len, SV * object) {
    //char * demolish_c = malloc(SvCUR(class_name) + 11);
    char * demolish_c = malloc(class_len + 11);
    strcpy(demolish_c, SvPV_nolen(class_name));
    strcat(demolish_c, "::DEMOLISH");

    if (get_cv(demolish_c, 0)) {
        // printf("DEMOLISH\n");
        dSP;
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(object);
        PUTBACK;

        call_pv(demolish_c, G_SCALAR|G_DISCARD);

        SPAGAIN;
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    free(demolish_c);
    return;
}

void cache_store (SV* object, char* class_name, unsigned int len, HV* class_stash) {
    SV** pool_ref;
    AV* pool;

    if (pool_ref = hv_fetch(global_cache_of, class_name, len, 0)) {
        pool = (AV*)SvRV(*pool_ref);
    }
    else {
        pool = newAV();
        hv_store(global_cache_of, class_name, len, newRV_inc((SV*)pool), 0);
    }

    sv_bless(object, class_stash);
    SvREFCNT_inc(object);
    av_push(pool, object);
}

// TODO: add safety checks...
void destroy(SV* object) {
    SV* ident = SvRV(object);
    HV* class_stash;

    // class_stash is returned via parameter list
    char * class_name; // = get_class(object, class_stash);
    unsigned int len;
    unsigned int base_class_len;
    I32 i = 0;
    I32 j;

    SV** parent_ref;
    AV * parent_from;
    I32 parent_len;

    SV** attr_ref;
    AV * attr_from;
    I32 attr_len;

    HE* he;

    SV** attr;
    SV** base_class;

    SV** cache_ref;

    class_stash = SvSTASH(SvRV(object));
    if ((class_stash == NULL) || ((SV*)class_stash == &PL_sv_undef)) {
        croak("No stash found");
    }
    class_name = HvNAME(class_stash);
    if (class_name == NULL) {
        croak("Ooops: Lost object class name");
    }
    len = strlen(class_name);

    // if there exists a hierarchy_of entry
    if (parent_ref = hv_fetch(global_hierarchy_of, class_name, len, 0)) {
        parent_from = (AV*)SvRV(*parent_ref);
    }
    else {
        // get hierarchy from perl
        parent_from = hierarchy_of(class_name);
        // store in hierarchy_of hash
        //printf("hierarchy of\n");
        hv_store(global_hierarchy_of, class_name, len, newRV_inc((SV*)parent_from), 0);
    }
    {
        parent_len = av_len(parent_from);

        // for all classes in hierarchy
        for (; i <= parent_len; ) {
            // printf("%d\n", i);
            if (base_class = av_fetch(parent_from, i++,0)) {
                // call DEMOLISH if exists
                base_class_len = SvCUR(*base_class);
                demolish(*base_class, base_class_len, object);

                //if (attr_ref = hv_fetch(global_attribute_of, SvPV_nolen(*base_class), SvCUR(*base_class), 0)) {
                if (attr_ref = hv_fetch(global_attribute_of, SvPV_nolen(*base_class), base_class_len, 0)) {
                    if (! SvROK(*attr_ref))
                        croak("Oops - not a reference");
                    attr_from = (AV*)SvRV(*attr_ref);
                    attr_len = av_len(attr_from);
                    // for all attributes in class
                    for (j = 0; j <= attr_len;) {
                        // printf("attr\n");
                        if (attr = av_fetch(attr_from, j++, 0)) {
                            if (he = hv_fetch_ent((HV*)SvRV(*attr), global_ref_key.key, 0, global_ref_key.hash)) {
                                // TODO: check whether he contains a hash ref
                                if (! SvROK(HeVAL(he)))
                                    croak("Oops - not a reference");
                                hv_delete_ent((HV*)SvRV(HeVAL(he)), ident, G_DISCARD, 0);
                            }
                        }
                    }
                }
            }
        }
        if (hv_exists(global_do_cache_class_of, class_name, len)) {
            cache_store(object, class_name, len, class_stash);
        }
    }
}

MODULE = Class::Std::Fast_XS      PACKAGE = Class::Std::Fast_XS

void destroy(object);
    SV * object;

void init(data_hash_ref, attribute_hash_ref, do_cache_class_ref, cache_ref)
    SV*     data_hash_ref;
    SV*     attribute_hash_ref;
    SV*     do_cache_class_ref;
    SV*     cache_ref;

void
getter(self)
        SV* self;
    ALIAS:
    INIT:
        /* Get the const hash key struct from the global storage */
        /* ix is the magic integer variable that is set by the perl guts for us.
         * We uses it to identify the currently running alias of the accessor. Gollum! */
        const autoxs_hashkey readfrom = AutoXS_hashkeys[ix];
        HE* he;
        HE* value_ent;
        SV* key;
    PPCODE:
        if (he = hv_fetch_ent(global_hash_ref, readfrom.key, 0, readfrom.hash)) {
            if (value_ent = hv_fetch_ent((HV*)SvRV(HeVAL(he)), SvRV(self), 0, 0)) {
                XPUSHs(HeVAL(value_ent));
            }
            else {
                XSRETURN_UNDEF;
            }
        }
        else {
            XSRETURN_UNDEF;
        }



void
setter(self, newvalue)
    SV* self;
    SV* newvalue;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = AutoXS_hashkeys[ix];
    HE* he;
    SV* key;

    PPCODE:
    SvREFCNT_inc(newvalue);
    if (he = hv_fetch_ent(global_hash_ref, readfrom.key, 0, readfrom.hash)) {
        key = SvRV(self);
        if (NULL == hv_store_ent((HV*)SvRV(HeVAL(he)), key, newvalue, 0)) {
          croak("Failed to write new value to hash.");
        }
    }
    XPUSHs(self);


void
newxs_getter(name, key)
  char* name;
  char* key;
  PPCODE:
    char* file = __FILE__;
    const unsigned int functionIndex = get_next_hashkey();
    {
      CV * cv;
      unsigned int len;
      autoxs_hashkey hashkey;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      cv = newXS(name, XS_Class__Std__Fast_XS_getter, file);
      if (cv == NULL)
        croak("ARG! SOMETHING WENT REALLY WRONG!");
      XSANY.any_i32 = functionIndex;

      /* Precompute the hash of the key and store it in the global structure */
      len = strlen(key);
      hashkey.key = newSVpvn(key, len);
      PERL_HASH(hashkey.hash, key, len);
      AutoXS_hashkeys[functionIndex] = hashkey;
    }


void
newxs_setter(name, key)
  char* name;
  char* key;
  PPCODE:
    char* file = __FILE__;
    const unsigned int functionIndex = get_next_hashkey();
    {
      CV * cv;
      unsigned int len;
      autoxs_hashkey hashkey;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      cv = newXS(name, XS_Class__Std__Fast_XS_setter, file);
      if (cv == NULL)
        croak("ARG! SOMETHING WENT REALLY WRONG!");
      XSANY.any_i32 = functionIndex;

      /* Precompute the hash of the key and store it in the global structure */
      len = strlen(key);
      hashkey.key = newSVpvn(key, len);
      PERL_HASH(hashkey.hash, key, len);
      AutoXS_hashkeys[functionIndex] = hashkey;
    }

