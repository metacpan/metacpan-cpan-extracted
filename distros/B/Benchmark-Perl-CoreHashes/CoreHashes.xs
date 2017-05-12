#define PERL_NO_GET_CONTEXT
#define PERL_SEEN_HV_FUNC_H
//below causes memory overrun on most perls, IDC
#define PERL_HASH_SEED_BYTES 16
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_HASH
#undef PERL_HASH
#undef PERL_SEEN_HV_FUNC_H
#define HAS_QUAD
#ifdef _MSC_VER
  #define U64TYPE unsigned __int64
#else
  #define U64TYPE uint64_t
#endif
//_rotl64 is only on 64 bit MS CRTs
#if defined(_MSC_VER) && !defined(WIN64)
#  define _rotl64(x,r) (((U64TYPE)x << r) | ((U64TYPE)x >> (64 - r)))
#endif
#include "hv_func.h"

#define XMM(x) #x,
static const char * arr [] = {
#include "wordlist.xmacro"
    };
#undef XMM

#define XMM(x) sizeof(#x)-1,
static const char arrlen [] = {
#include "wordlist.xmacro"
    };
#undef XMM

#undef PERL_HASH_FUNC_SIPHASH
#undef PERL_HASH_FUNC_SDBM
#undef PERL_HASH_FUNC_DJB2
#undef PERL_HASH_FUNC_SUPERFAST
#undef PERL_HASH_FUNC_MURMUR3
#undef PERL_HASH_FUNC_ONE_AT_A_TIME
#undef PERL_HASH_FUNC_ONE_AT_A_TIME_HARD
#undef PERL_HASH_FUNC_ONE_AT_A_TIME_OLD

#undef PERL_HASH_SEED
#define PERL_HASH_SEED "PeRlHaShhAcKpErl"

MODULE = Benchmark::Perl::CoreHashes		PACKAGE = Benchmark::Perl::CoreHashes		

U32
run_PERL_HASH_FUNC_SIPHASH()
PREINIT:
    int i;
    int iarr;
CODE:
#undef PERL_HASH_FUNC
#undef PERL_HASH_SEED_BYTES
#undef PERL_HASH
#define PERL_HASH_FUNC "SIPHASH_2_4"
#define PERL_HASH_SEED_BYTES 16
#define PERL_HASH(hash,str,len) (hash)= S_perl_hash_siphash_2_4(PERL_HASH_SEED,(U8*)(str),(len))
    RETVAL = 0;
    for(i=0; i < 1000000; i++){
        for(iarr=0; iarr < sizeof(arrlen); iarr++){
            U32 hash;
            PERL_HASH(hash, arr[iarr], arrlen[iarr]);
            RETVAL += hash;
        }
    }
OUTPUT:
    RETVAL

U32
run_PERL_HASH_FUNC_SDBM()
PREINIT:
    int i;
    int iarr;
CODE:
#undef PERL_HASH_FUNC
#undef PERL_HASH_SEED_BYTES
#undef PERL_HASH
#define PERL_HASH_FUNC "SDBM"
#define PERL_HASH_SEED_BYTES 4
#define PERL_HASH(hash,str,len) (hash)= S_perl_hash_sdbm(PERL_HASH_SEED,(U8*)(str),(len))
    RETVAL = 0;
    for(i=0; i < 1000000; i++){
        for(iarr=0; iarr < sizeof(arrlen); iarr++){
            U32 hash;
            PERL_HASH(hash, arr[iarr], arrlen[iarr]);
            RETVAL += hash;
        }
    }
OUTPUT:
    RETVAL

U32
run_PERL_HASH_FUNC_DJB2()
PREINIT:
    int i;
    int iarr;
CODE:
#undef PERL_HASH_FUNC
#undef PERL_HASH_SEED_BYTES
#undef PERL_HASH
#define PERL_HASH_FUNC "DJB2"
#define PERL_HASH_SEED_BYTES 4
#define PERL_HASH(hash,str,len) (hash)= S_perl_hash_djb2(PERL_HASH_SEED,(U8*)(str),(len))
    RETVAL = 0;
    for(i=0; i < 1000000; i++){
        for(iarr=0; iarr < sizeof(arrlen); iarr++){
            U32 hash;
            PERL_HASH(hash, arr[iarr], arrlen[iarr]);
            RETVAL += hash;
        }
    }
OUTPUT:
    RETVAL

U32
run_PERL_HASH_FUNC_SUPERFAST()
PREINIT:
    int i;
    int iarr;
CODE:
#undef PERL_HASH_FUNC
#undef PERL_HASH_SEED_BYTES
#undef PERL_HASH
#define PERL_HASH_FUNC "SUPERFAST"
#define PERL_HASH_SEED_BYTES 4
#define PERL_HASH(hash,str,len) (hash)= S_perl_hash_superfast(PERL_HASH_SEED,(U8*)(str),(len))
    RETVAL = 0;
    for(i=0; i < 1000000; i++){
        for(iarr=0; iarr < sizeof(arrlen); iarr++){
            U32 hash;
            PERL_HASH(hash, arr[iarr], arrlen[iarr]);
            RETVAL += hash;
        }
    }
OUTPUT:
    RETVAL

U32
run_PERL_HASH_FUNC_MURMUR3()
PREINIT:
    int i;
    int iarr;
CODE:
#undef PERL_HASH_FUNC
#undef PERL_HASH_SEED_BYTES
#undef PERL_HASH
#define PERL_HASH_FUNC "MURMUR3"
#define PERL_HASH_SEED_BYTES 4
#define PERL_HASH(hash,str,len) (hash)= S_perl_hash_murmur3(PERL_HASH_SEED,(U8*)(str),(len))
    RETVAL = 0;
    for(i=0; i < 1000000; i++){
        for(iarr=0; iarr < sizeof(arrlen); iarr++){
            U32 hash;
            PERL_HASH(hash, arr[iarr], arrlen[iarr]);
            RETVAL += hash;
        }
    }
OUTPUT:
    RETVAL

U32
run_PERL_HASH_FUNC_ONE_AT_A_TIME()
PREINIT:
    int i;
    int iarr;
CODE:
#undef PERL_HASH_FUNC
#undef PERL_HASH_SEED_BYTES
#undef PERL_HASH
#define PERL_HASH_FUNC "ONE_AT_A_TIME"
#define PERL_HASH_SEED_BYTES 4
#define PERL_HASH(hash,str,len) (hash)= S_perl_hash_one_at_a_time(PERL_HASH_SEED,(U8*)(str),(len))
    RETVAL = 0;
    for(i=0; i < 1000000; i++){
        for(iarr=0; iarr < sizeof(arrlen); iarr++){
            U32 hash;
            PERL_HASH(hash, arr[iarr], arrlen[iarr]);
            RETVAL += hash;
        }
    }
OUTPUT:
    RETVAL

U32
run_PERL_HASH_FUNC_ONE_AT_A_TIME_HARD()
PREINIT:
    int i;
    int iarr;
CODE:
#undef PERL_HASH_FUNC
#undef PERL_HASH_SEED_BYTES
#undef PERL_HASH
#define PERL_HASH_FUNC "ONE_AT_A_TIME_HARD"
#define PERL_HASH_SEED_BYTES 8
#define PERL_HASH(hash,str,len) (hash)= S_perl_hash_one_at_a_time_hard(PERL_HASH_SEED,(U8*)(str),(len))
    RETVAL = 0;
    for(i=0; i < 1000000; i++){
        for(iarr=0; iarr < sizeof(arrlen); iarr++){
            U32 hash;
            PERL_HASH(hash, arr[iarr], arrlen[iarr]);
            RETVAL += hash;
        }
    }
OUTPUT:
    RETVAL

U32
run_PERL_HASH_FUNC_ONE_AT_A_TIME_OLD()
PREINIT:
    int i;
    int iarr;
CODE:
#undef PERL_HASH_FUNC
#undef PERL_HASH_SEED_BYTES
#undef PERL_HASH
#define PERL_HASH_FUNC "ONE_AT_A_TIME_OLD"
#define PERL_HASH_SEED_BYTES 4
#define PERL_HASH(hash,str,len) (hash)= S_perl_hash_old_one_at_a_time(PERL_HASH_SEED,(U8*)(str),(len))
    RETVAL = 0;
    for(i=0; i < 1000000; i++){
        for(iarr=0; iarr < sizeof(arrlen); iarr++){
            U32 hash;
            PERL_HASH(hash, arr[iarr], arrlen[iarr]);
            RETVAL += hash;
        }
    }
OUTPUT:
    RETVAL
