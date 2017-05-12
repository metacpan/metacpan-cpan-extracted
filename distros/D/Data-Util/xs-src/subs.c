/*
    Data-Util/subs.c

    XS code templates for curry() and modify_subroutine()
*/
#include "data-util.h"

MGVTBL curried_vtbl;
MGVTBL modified_vtbl;

MAGIC*
my_mg_find_by_vtbl(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;
    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            break;
        }
    }
    return mg;
}

XS(XS_Data__Util_curried){
    dVAR; dXSARGS;
    MAGIC* const mg = (MAGIC*)XSANY.any_ptr; // mg_find_by_vtbl((SV*)cv, &curried_vtbl);
    assert(mg);

    SP -= items;
    /*
      NOTE:
      Curried subroutines have two properties, "params" and "phs"(placeholders).
      Geven a curried subr created by "curry(\&f, $x, *_, $y, \0)":
        params: [   $x, undef,    $y, undef]
        phs:    [undef,    *_, undef,     0]

      Here the curried subr is called with arguments.
      Firstly, the arguments are set to params, expanding subscriptive placeholders,
      but the placeholder "*_" is set to the end of params.
          params: [   $x,      undef,    $y, $_[0], @_ ]
      Then, params are pushed into SP, expanding "*_".
        SP:     [   $x, @_[1..$#_],    $y, $_[0] ]
      Finally, params are cleand up.
          params: [   $x,      undef,    $y, undef ]
    */
    {
        AV* const params       = (AV*)mg->mg_obj;
        SV**      params_ary   = AvARRAY(params);
        I32 const len          = AvFILLp(params) + 1;

        AV* const phs          = (AV*)mg->mg_ptr; /* placeholders */
        SV**const phs_ary      = AvARRAY(phs);

        I32 max_ph             = -1;      /* max placeholder index */
        I32 min_ph             = items;   /* min placeholder index */

        SV** sph               = NULL; // indicates *_

        U16 const is_method    = mg->mg_private; /* G_METHOD */
        I32 push_size          = len - 1; /* -1: proc */
        register I32 i;
        SV* proc;

        /* fill in params */
        for(i = 0; i < len; i++){
            SV* const ph = phs_ary[i];
            if (!ph){
                continue;
            }

            if(isGV(ph)){ /* symbolic placeholder *_ */
                if(!sph){
                    I32 j;

                    if(AvMAX(params) < (len + items)){
                        av_extend(params, len + items);
                        params_ary = AvARRAY(params); /* maybe realloc()-ed */
                    }

                    /* 
                       All the arguments @_ is pushed into the end of params,
                       not calling SvREFCNT_inc().
                    */

                    sph = &params_ary[len];
                    for(j = 0; j < items; j++){
                        /* NOTE: no need to SvREFCNT_inc(ST(j)),
                        *  bacause AvFILLp(params) remains len-1.
                        *  That's okey.
                        */
                        sph[j] = ST(j);
                    }
                }
                push_size += items;
            }
            else if(SvIOKp(ph)){ /* subscriptive placeholders */
                IV p = SvIVX(ph);

                if(p >= 0){
                    if(p > max_ph) max_ph = p;
                }
                else{ /* negative index */
                    p += items;

                    if(p < 0){
                        Perl_croak(aTHX_ PL_no_aelem, (int)p);
                    }

                    if(p < min_ph) min_ph = p;
                }


                if(p <= items){
                    /* NOTE: no need to SvREFCNT_inc(params_ary[i]),
                     *       because it removed from params_ary before call_sv()
                     */
                    params_ary[i] = ST(p);
                }
            }
        }

        PUSHMARK(SP);
        EXTEND(SP, push_size);

        if(is_method){
            PUSHs( params_ary[0] ); /* invocant */
            proc = params_ary[1];   /* method */
            i = 2;
        }
        else{
            proc = params_ary[0];  /* code ref */
            i = 1;
        }

        for(/* i is initialized above */; i < len; i++){
            if(phs_ary[i] && isGV(phs_ary[i])){
                /* warn("#sph %d - %d", (int)max_ph+1, (int)min_ph); //*/
                PUSHary(sph, max_ph + 1, min_ph);
            }
            else{
                PUSHs(params_ary[i]);
            }
        }
        PUTBACK;

        /* NOTE: need to clean up params before call_sv(), because call_sv() might die */
        for(i = 0; i < len; i++){
            if(phs_ary[i] && SvIOKp(phs_ary[i])){
                /* NOTE: no need to SvREFCNT_dec(params_ary[i]) */
                params_ary[i] = &PL_sv_undef;
            }
        }

        /* G_EVAL to workaround RT #69939 */
        call_sv(proc, GIMME_V | is_method | G_EVAL);
        if(SvTRUEx(ERRSV)){
            croak(NULL); /* rethrow */
        }
    }
}

/* call an av of cv with args_ary */
static void
my_call_av(pTHX_ AV* const subs, SV** const args_ary, I32 const args_len){
    I32 const subs_len = AvFILLp(subs) + 1;
    I32 i;

    for(i = 0; i < subs_len; i++){
        dSP;

        PUSHMARK(SP);
        XPUSHary(args_ary, 0, args_len);
        PUTBACK;

        /* G_EVAL to workaround RT #69939 */
        call_sv(AvARRAY(subs)[i], G_VOID | G_DISCARD | G_EVAL);
        if(SvTRUEx(ERRSV)){
            croak(NULL);
        }
    }
}

XS(XS_Data__Util_modified){
    dVAR; dXSARGS;
    MAGIC* const mg = (MAGIC*)XSANY.any_ptr; // mg_find_by_vtbl((SV*)cv, &modified_vtbl);
    assert(mg);

    SP -= items;
    {
        AV* const subs_av = (AV*)mg->mg_obj;
        AV* const before  = (AV*)AvARRAY(subs_av)[M_BEFORE];
        SV* const current = (SV*)AvARRAY(subs_av)[M_CURRENT];
        AV* const after   = (AV*)AvARRAY(subs_av)[M_AFTER];
        I32 i;
        dXSTARG;
        AV* const args = (AV*)TARG;
        SV** args_ary;
        (void)SvUPGRADE(TARG, SVt_PVAV);

        if(AvMAX(args) < items){
            av_extend(args, items);
        }
        args_ary = AvARRAY(args);

        for(i = 0; i < items; i++){
            args_ary[i] = ST(i); /* no need to SvREFCNT_inc() */
        }

        PUTBACK;
        my_call_av(aTHX_ before, args_ary, items);
        SPAGAIN;

        PUSHMARK(SP);
        XPUSHary(args_ary, 0, items);
        PUTBACK;
        call_sv(current, GIMME_V);

        my_call_av(aTHX_ after, args_ary, items);
    }
    /* no need to XSRETURN(n) */
}
