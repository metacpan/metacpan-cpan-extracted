#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "murmur3.h"

#define MAGIC 1
#define HLL_HASH_SEED 313

typedef struct HyperLogLog {
    uint32_t m;         /// register num
    uint8_t k;          /// register bit width 
    uint8_t* registers;
    double alphaMM;     /// alpha * m^2
}*HLL;

#define GET_HLLPTR(x) get_hll(aTHX_ x, "$self")

static const double two_32 = 4294967296.0;
static const double neg_two_32 = -4294967296.0;

/**
 * Extract pointer of struct HyperLogLog from SV.
 * 
 * @param[in]   object  Perl object
 * @param[in]   context
 */
static HLL get_hll(pTHX_ SV* object, const char* context) {
    SV *sv;
    IV address;

    if (MAGIC) SvGETMAGIC(object);
    if (!SvROK(object)) {
        if (SvOK(object)) croak("%s is not a reference", context);
        croak("%s is undefined", context);
    }
    sv = SvRV(object);
    if (!SvOBJECT(sv)) croak("%s is not an object reference", context);
    if(!sv_derived_from(object,"Algorithm::HyperLogLog")) {
        croak("%s is not a Algorithm::HyperLogLog", context);
    }
    address = SvIV(sv);
    if (!address)
    croak("Algorithm::HyperLogLog object %s has a NULL pointer", context);
    return INT2PTR(HLL, address);
}

/**
 *  Initialize struct HyperLogLog
 *  
 *  @param[in]  k   paramater for determining register size
 *  @return     pointer of the intialized HLL
 */
static inline HLL initialize_hll(pTHX_ uint32_t k){
    HLL hll = NULL;
    double alpha = 0.0;
    New(__LINE__, hll, 1, struct HyperLogLog);
    if( k < 4 || k > 16 ) {
        croak("Number of ragisters must be in the range [4,16]");
    }
    hll->k = k;
    hll->m = 1 << hll->k;
    Newxz(hll->registers, hll->m, uint8_t);
    switch (hll->m) {
        case 16:
        alpha = 0.673;
        break;
        case 32:
        alpha = 0.697;
        break;
        case 64:
        alpha = 0.709;
        break;
        default:
        alpha = 0.7213/(1.0 + (1.079/(double) hll->m));
        break;
    }
    hll->alphaMM = alpha * hll->m * hll->m;
    return hll;
}


/**
 * Returns position of the leftmost 1-bit of x.
 * 
 * @param[in]   x   target of search 1-bit
 * @param[in]   b   bit width
 * @return      position of the leftmost 1-bit of x
 */
static inline uint8_t rho(uint32_t x, uint8_t b) {
    uint8_t v = 1;
    while (v <= b && !(x & 0x80000000)) {
        v++;
        x <<= 1;
    }
    return v;
}

MODULE = Algorithm::HyperLogLog PACKAGE = Algorithm::HyperLogLog

PROTOTYPES: DISABLE

# Constructor
HLL
new(const char *klass, uint32_t k)
CODE:
{
    RETVAL = initialize_hll(aTHX_ k);
}
OUTPUT:
    RETVAL

# Constructor(From dumped data)
HLL
_new_from_dump(const char *klass, uint32_t k, AV* data)
PREINIT:
uint32_t i;
uint32_t len = 0;
CODE:
{
    RETVAL = initialize_hll(aTHX_ k);
    len = av_len(data);
    for(i = 0;i <= len;++i){
        RETVAL->registers[i] = (uint8_t)SvUV(*av_fetch(data, i, 0));
    }
}
OUTPUT:
    RETVAL

# dump registers
AV*
_dump_register(HLL self)
CODE:
{
    RETVAL = (AV*)sv_2mortal((SV*)newAV());
    uint32_t i;
    for(i = 0;i < self->m; i++){
        av_push(RETVAL, newSVuv(self->registers[i]));
    }
}
OUTPUT:
    RETVAL

# Return number of registers.
uint32_t
register_size(HLL self)
CODE:
    RETVAL = self->m;
OUTPUT:
    RETVAL

# Add element to the estimator
void
add(HLL self, ...)
PREINIT:
    uint32_t hash;
    uint32_t index;
    uint8_t rank;
    I32 arg_index;
    STRLEN n_a;
CODE:
{
    if(items > 1){
        for(arg_index = 1; arg_index < items; ++arg_index){
            char* str = SvPV(ST(arg_index), n_a);
            MurmurHash3_32((void *) str, strlen(str), HLL_HASH_SEED, (void *) &hash);
            index = (hash >> (32 - self->k));
            rank = rho( (hash << self->k), 32 - self->k );
            if( rank > self->registers[index] ) {
                self->registers[index] = rank;
            }
        }
    }
}


# Estimate cardinality
double
estimate(HLL self)
CODE:
{
    double estimate;
    uint32_t m = self->m;
    uint32_t i = 0;
    double sum = 0.0;
    // Calculate hermonic mean
    for (i = 0; i < m; i++) {
        sum += 1.0/pow(2.0, self->registers[i]);
    }
    estimate = self->alphaMM/sum; // E in the original paper
    if( estimate <= 2.5 * m ) {
        uint32_t zeros = 0;// V in the original paper
        uint32_t i = 0;
        for (i = 0; i < m; i++) {
            if (self->registers[i] == 0) {
                zeros++;
            }
        }
        if( zeros != 0 ) {
            estimate = m * log((double)m/zeros);
        }
    } else if (estimate > (1.0/30.0) * two_32) {
        estimate = neg_two_32 * log(1.0 - ( estimate/two_32 ) );
    }

    RETVAL = estimate;
}
OUTPUT:
    RETVAL


# Merge two HLLs
double
merge(HLL self, HLL other)
CODE:
{
    uint32_t m = self->m;
    uint32_t i = 0;

    if (m != other->m) {
        croak("hll size mismatch: %d != %d\n", m, other->m);
    }

    for (i = 0; i < m; i++) {
        if (self->registers[i] < other->registers[i]) {
            self->registers[i] = other->registers[i];
        }
    }
    XSRETURN_UNDEF;
}
OUTPUT:
    RETVAL

# Destructor
void
DESTROY(HLL self)
CODE:
{
    Safefree(self->registers);
    Safefree (self);
}

