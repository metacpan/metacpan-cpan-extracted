#ifndef PLCB_UTIL_H_
#define PLCB_UTIL_H_

/* This file contains various conversion functions and macros */

/*this stuff converts from SVs to int64_t (signed and unsigned) depending
 on the perl*/

/*XXX:
12:54 < LeoNerd> mordy: Namely,   my ( $hi, $lo ) = unpack "L> L>", $packed_64bit;
                 my $num = Math::BigInt->new( $hi ); $num >>= 32; $num |= $lo;
                 return $num;
12:55 < mordy> what about vice versa? or would i change my C interface to accept 2
               32 bit integers and piece them back together there?
12:55 < LeoNerd> mordy: That might be simplest.
*/

#ifdef PLCB_PERL64
#define plcb_sv_to_u64(sv) SvUV(sv)
#define plcb_sv_to_64(sv) (int64_t)(plcb_sv_to_u64(sv))
#define plcb_sv_from_u64(sv, num) (sv_setuv(sv, num))
#define plcb_sv_from_u64_new(nump) newSVuv( (*nump) )

#define plcb_sv2cas(sv) (\
        (SvIOK(sv)) \
            ? (uint64_t)(SvIVX(sv)) \
            : (die("Expected valid (UV) cas. IOK not true"),-1) \
        )

#else

static PERL_UNUSED_DECL uint64_t plcb_sv_to_u64(SV *in)
{
    char *sv_blob;
    STRLEN blob_len;
    uint64_t ret;
    
    if (SvIOK(in)) {
        /*Numeric*/
        return SvUV(in);
    }

    sv_blob = SvPV(in, blob_len);

    if (blob_len != 8) {
        die("expected 8-byte data string. Got %d", (int)blob_len);
    }

    ret = *(uint64_t*)sv_blob;
    return ret;
}

#define plcb_sv_to_64(sv) ((int64_t)(plcb_sv_to_u64(sv)))

#define plcb_sv_from_u64(sv, num) \
    (sv_setpvn(sv, (const char const*)&(num), 8))

#define plcb_sv_from_u64_new(nump) \
    newSVpv((const char* const)(nump), 8)

/*Extract a packed 8 byte blob from an SV into a CAS value*/
#define plcb_sv2cas plcb_sv_to_u64
    
#endif /*PLCB_PERL64*/

/*assertively extract a non-null key from an SV, together with its length*/

#define plcb_get_str_or_die(ksv, charvar, lenvar, diespec) \
    (void)(((charvar = SvPV(ksv, lenvar))) \
        ? ( (lenvar) ? charvar : (void*)die("Got zero-length %s", diespec) ) \
        : (void*)die("Got NULL %s", diespec))


#define PLCB_TIME_ABS_OFFSET

#ifdef PLCB_TIME_ABS_OFFSET
#define PLCB_UEXP2EXP(cbexp, uexp, now) \
    cbexp = ((uexp) \
        ? ((now) \
            ? (now + uexp) \
            : (time(NULL)) + uexp) \
        : 0)

#else

/*Memcached protocol states that a time offset greater than 30 days is taken
 to be an epoch time. We hide this from perl by simply generating our own
 epoch time based on the user's time*/

#define PLCB_UEXP2EXP(cbexp, uexp, now) \
    cbexp = ((uexp) \
        ? ((uexp > (30*24*60*60)) \
            ? ((now) \
                ? (now + uexp) \
                : (time(NULL) + uexp)) \
            : uexp) \
        : 0)
#endif

/**
 * Extract the expiry value from an SV
 */

static PERL_UNUSED_DECL UV plcb_exp_from_sv(SV *exp)
{

    UV ret = 0;

    if (SvTYPE(exp) == SVt_NULL) {
        return 0;
    }

    if (SvIOK(exp)) {
        IV expiv = SvIVX(exp);
        if (expiv < 0) {
            die("Expiry cannot be negative");
        }

        ret = expiv;

    } else if (SvPOK(exp)) {
        UV exptype = grok_number(SvPVX(exp), SvCUR(exp), &ret);

        if (!exptype) {
            die("Bad expiry value");
        }

        if (exptype == IS_NUMBER_NEG) {
            die("Expiry cannot be negative");
        }

    } else {
        die("Bad type for expiry");
    }

    return ret;
}

#define plcb_is_arrayref(sv) (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV)
#define plcb_is_simple_string(sv) ( SvPOK(sv) != 0 && SvROK(sv) == 0 )

/* Handy types for XS */
/* for easy passing */
typedef struct {
    struct PLCB_st *ptr;
    SV *sv;
} PLCB_XS_OBJPAIR_t;

typedef struct {
    SV *origsv;
    char *base;
    STRLEN len;
} PLCB_XS_STRING_t;

typedef PLCB_XS_STRING_t PLCB_XS_STRING_NONULL_t;


#endif /* PLCB_UTIL_H_ */
