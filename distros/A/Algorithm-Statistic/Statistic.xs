#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#define NO_XSLOCKS 
#include "XSUB.h"

#ifdef __cplusplus
} /* extern "C" */
#endif

#include "ppport.h"

#define NDEBUG
#include <memory>

#include "kth_order_statistic.hpp"
#include "debug.hpp"

/**
 * Default comparator for numerics
 */
class PerlDefaultCompare {
public:
    virtual ~PerlDefaultCompare() {}

    virtual int operator()(SV* const x, SV* const y) const {
        dTHX; 
        SV *z = x;
        if (SvTYPE(x) < SvTYPE(y)) {
            // For comparison betwee flaot and int
            z = y;
        }

        int res = 0;

        switch (SvTYPE(y)) {
            case SVt_PVIV:
            case SVt_IV: {
                int a = SvIV(x),
                    b = SvIV(y);

                res = a < b ? -1 : a > b ? 1 : 0;
                break;
            }
            case SVt_PVNV:
            case SVt_NV:
            default: {
                float a = SvNV(x),
                      b = SvNV(y);
            
                res = a < b ? -1 : a > b ? 1 : 0;
                break;
            }
        }
    
        return res;
    }
};

/**
 * Extended comparator specified from perl
 */
class PerlCompare : public PerlDefaultCompare {
public:
    PerlCompare(SV* compare) : compare_(compare), PerlDefaultCompare() {}

    int operator()(SV* const x, SV* const y) const {
        dTHX;
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(x);
        PUSHs(y);
        PUTBACK;

        call_sv(compare_, G_SCALAR);
        SPAGAIN;
        int const ret = POPi;
        PUTBACK;

        FREETMPS;
        LEAVE;

        return ret;
    }
private:
    SV* compare_;
};


bool is_array_ref(const SV * const  a) {
    return (SvROK(a) && SvTYPE(SvRV(a)) == SVt_PVAV);
}

bool is_sub_ref(const SV * const cv) {
    return (SvROK(cv) && SvTYPE(SvRV(cv)) == SVt_PVCV);
}


MODULE = Algorithm::Statistic      PACKAGE = Algorithm::Statistic



SV *
kth_order_statistic(SV *array_ref, SV *k, ...)
    PROTOTYPE: $$;&
    CODE:
    {
        if (!is_array_ref(array_ref)) {
            warn("Not an array reference passed"); 
            XSRETURN_UNDEF;
        }
       
        std::shared_ptr<PerlDefaultCompare> comparator(new PerlDefaultCompare());
        // compare declared?
        if (items > 2) {
            if (is_sub_ref(ST(2))) {
                SV* compare = ST(2);    
                comparator = std::shared_ptr<PerlCompare>(new PerlCompare(compare));
            }
            else {
                croak("Bad comparison sub passed"); 
            }
        }

        AV * array = (AV*)SvRV(array_ref);
        SV** rawarray = AvARRAY(array);
        
        size_t len = av_len(array) + 1;

        try {
            auto it = algo::KthOrderStatistic<SV**, PerlDefaultCompare>(
                rawarray,
                rawarray+len,
                (size_t)SvUV(k),
                *comparator
            );

            RETVAL = SvREFCNT_inc(*it);
        }
        catch (std::exception &e) {
            warn(e.what()); 
            XSRETURN_UNDEF;
        }
    }

    OUTPUT: RETVAL
   

SV *
median(SV *array_ref, ...)
    PROTOTYPE: $;&
    CODE:
    {
        if (!is_array_ref(array_ref)) {
            warn("Not an array reference passed"); 
            XSRETURN_UNDEF;
        }

        std::shared_ptr<PerlDefaultCompare> comparator(new PerlDefaultCompare());
        // compare declared?
        if (items > 1) {
            if (is_sub_ref(ST(1))) {
                SV* compare = ST(1);    
                comparator = std::shared_ptr<PerlCompare>(new PerlCompare(compare));
            }
            else {
                croak("Bad comparison sub passed"); 
            }
        }

        AV * array = (AV*)SvRV(array_ref);
        SV** rawarray = AvARRAY(array);

        size_t len = av_len(array) + 1;
        size_t k = len/ 2;

        try {
            auto it = algo::KthOrderStatistic<SV**, PerlDefaultCompare>(
                rawarray, 
                rawarray + len, 
                k,
                *comparator
            );

            RETVAL = SvREFCNT_inc(*it);
        }
        catch (std::exception &e) {
            warn(e.what()); 
            XSRETURN_UNDEF;
        }
    }

    OUTPUT: RETVAL
   
