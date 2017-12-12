#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/err.h>
#include <openssl/bn.h>

#define checkOpenSslCall( result ) if( ! ( result ) ) \
  croak( "OpenSSL error: %s", ERR_reason_error_string( ERR_get_error() ) );

typedef BIGNUM *Crypt__OpenSSL__Bignum;
typedef BN_CTX *Crypt__OpenSSL__Bignum__CTX;

SV* new_obj( void* obj )
{
    SV * tmp = sv_newmortal();
    sv_setref_pv(tmp, "Crypt::OpenSSL::Bignum", (void*)obj);
    return tmp;
}

BIGNUM* sv2bn( SV* sv )
{
    if (SvROK(sv) && sv_derived_from(sv, "Crypt::OpenSSL::Bignum")) {
        return INT2PTR(Crypt__OpenSSL__Bignum, SvIV((SV*)SvRV(sv)));
    }
    else Perl_croak(aTHX_ "argument is not a Crypt::OpenSSL::Bignum object");
}

MODULE = Crypt::OpenSSL::Bignum      PACKAGE = Crypt::OpenSSL::Bignum   PREFIX = BN_

BOOT:
#if OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER)
    OPENSSL_init_crypto(0, NULL);
#else
    ERR_load_crypto_strings();
#endif

void
DESTROY(Crypt::OpenSSL::Bignum self)
    CODE:
        BN_clear_free( self );

Crypt::OpenSSL::Bignum
new_from_word(CLASS, p_word)
    unsigned long p_word;
  PREINIT:
    BIGNUM* bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_set_word( bn, p_word ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
new_from_decimal(CLASS, p_dec_string)
    char* p_dec_string;
  PREINIT:
    BIGNUM* bn;
  CODE:
    bn = NULL;
    checkOpenSslCall( BN_dec2bn( &bn, p_dec_string ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
new_from_hex(CLASS, p_hex_string)
    char* p_hex_string;
  PREINIT:
    BIGNUM* bn;
  CODE:
    bn = NULL;
    checkOpenSslCall( BN_hex2bn( &bn, p_hex_string ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
new_from_bin(CLASS, p_bin_string_SV)
    SV* p_bin_string_SV;
  PREINIT:
    BIGNUM* bn;
    unsigned char* bin;
    STRLEN bin_length;
  CODE:
    bin = (unsigned char*) SvPV( p_bin_string_SV, bin_length );
    checkOpenSslCall( bn = BN_bin2bn( bin, bin_length, NULL ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
BN_new(CLASS)
  PREINIT:
    BIGNUM* bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_set_word( bn, 0 ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
BN_zero(CLASS)
  PREINIT:
    BIGNUM *bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_set_word( bn, 0 ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
BN_one(CLASS)
  PREINIT:
    BIGNUM *bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_one( bn ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
BN_rand(CLASS, int bits, int top, int bottom)
  PREINIT:
    BIGNUM* bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_rand( bn, bits, top, bottom) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
BN_pseudo_rand(CLASS, int bits, int top, int bottom)
  PREINIT:
    BIGNUM* bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_pseudo_rand( bn, bits, top, bottom) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
BN_rand_range(CLASS, Crypt::OpenSSL::Bignum r)
  PREINIT:
    BIGNUM* bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_rand_range( bn, r) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

void
BN_bless_pointer(CLASS, void *pointer)
  PPCODE:
    ST(0) = new_obj(pointer);
    XSRETURN(1);

char*
BN_to_decimal(Crypt::OpenSSL::Bignum self)
  CODE:
    checkOpenSslCall( RETVAL = BN_bn2dec( self ) );
  OUTPUT:
    RETVAL
  CLEANUP:
    OPENSSL_free( RETVAL );

char*
BN_to_hex(Crypt::OpenSSL::Bignum self)
  CODE:
    checkOpenSslCall( RETVAL = BN_bn2hex( self ) );
  OUTPUT:
    RETVAL
  CLEANUP:
    OPENSSL_free( RETVAL );

SV*
BN_to_bin(Crypt::OpenSSL::Bignum self)
  PREINIT:
    unsigned char* bin;
    int length;
  CODE:
    length = BN_num_bytes( self );
    if (length>0) {
      RETVAL = NEWSV(0, length);
      SvPOK_only(RETVAL);
      SvCUR_set(RETVAL, length);
      bin = (unsigned char *)SvPV_nolen(RETVAL);
      BN_bn2bin( self, bin );
    }
    else {
      RETVAL = newSVpvn("", 0);
    }
  OUTPUT:
    RETVAL

unsigned long
BN_get_word(Crypt::OpenSSL::Bignum self)

int
BN_is_zero(Crypt::OpenSSL::Bignum self)

int
BN_is_one(Crypt::OpenSSL::Bignum self)

int
BN_is_odd(Crypt::OpenSSL::Bignum self)

void
BN_add(Crypt::OpenSSL::Bignum self, Crypt::OpenSSL::Bignum b, ...)
  PREINIT:
    BIGNUM *bn;
  PPCODE:
    if( items > 3 )
      croak( "usage: $bn->add( $bn2[, $target] )" );
    bn = ( items < 3 ) ? BN_new() : sv2bn( ST(2) );
    checkOpenSslCall( BN_add( bn, self, b ) );
    ST(0) = ( (items < 3 ) ? new_obj( bn ) : ST(2) );
    XSRETURN(1);

void
BN_sub(Crypt::OpenSSL::Bignum self, Crypt::OpenSSL::Bignum b, ...)
  PREINIT:
    BIGNUM *bn;
  PPCODE:
    if( items > 3 )
      croak( "usage: $bn->sub( $bn2[, $target] )" );
    bn = ( items < 3 ) ? BN_new() : sv2bn( ST(2) );
    checkOpenSslCall( BN_sub( bn, self, b ) );
    ST(0) = ( (items < 3 ) ? new_obj( bn ) : ST(2) );
    XSRETURN(1);

void
BN_mul(self, b, ctx, ...)
    Crypt::OpenSSL::Bignum self;
    Crypt::OpenSSL::Bignum b;
    Crypt::OpenSSL::Bignum::CTX ctx;
  PREINIT:
    BIGNUM* bn;
  PPCODE:
    if( items > 4 )
      croak( "usage: $bn->mul( $bn2, $ctx, [, $target] )" );
    bn = ( items < 4 ) ? BN_new() : sv2bn( ST(3) );
    checkOpenSslCall( BN_mul( bn, self, b, ctx ) );
    ST(0) = ( (items < 4 ) ? new_obj( bn ) : ST(3) );
    XSRETURN(1);

void
BN_div(self, b, ctx, ...)
    Crypt::OpenSSL::Bignum self;
    Crypt::OpenSSL::Bignum b;
    Crypt::OpenSSL::Bignum::CTX ctx;
  PREINIT:
    BIGNUM* quotient;
    BIGNUM* remainder;
  PPCODE:
    if( items > 5 )
      croak( "usage: $bn->div( $bn2, $ctx, [, $quotient [, $remainder ] ] )" );
    quotient = ( items < 4 ) ? BN_new() : sv2bn( ST(3) );
    remainder = ( items < 5 ) ? BN_new() : sv2bn( ST(4) );
    checkOpenSslCall( BN_div( quotient, remainder, self, b, ctx ) );
    ST(0) = ( (items < 4 ) ? new_obj( quotient ) : ST(3) );
    ST(1) = ( (items < 5 ) ? new_obj( remainder ) : ST(4) );
    XSRETURN(2);

Crypt::OpenSSL::Bignum
BN_sqr(Crypt::OpenSSL::Bignum self, Crypt::OpenSSL::Bignum::CTX ctx)
  PREINIT:
    BIGNUM* bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_sqr( bn, self, ctx ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

void
BN_mod(self, b, ctx, ...)
    Crypt::OpenSSL::Bignum self;
    Crypt::OpenSSL::Bignum b;
    Crypt::OpenSSL::Bignum::CTX ctx;
  PREINIT:
    BIGNUM* bn;
  PPCODE:
    if( items > 4 )
      croak( "usage: $bn->mod( $bn2, $ctx, [, $target] )" );
    bn = ( items < 4 ) ? BN_new() : sv2bn( ST(3) );
    checkOpenSslCall( BN_mod( bn, self, b, ctx ) );
    ST(0) = ( (items < 4 ) ? new_obj( bn ) : ST(3) );
    XSRETURN(1);

Crypt::OpenSSL::Bignum
BN_mod_mul(self, b, m, ctx)
    Crypt::OpenSSL::Bignum self;
    Crypt::OpenSSL::Bignum b;
    Crypt::OpenSSL::Bignum m;
    Crypt::OpenSSL::Bignum::CTX ctx;
  PREINIT:
    BIGNUM* bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_mod_mul( bn, self, b, m, ctx ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
BN_exp(self, exp, ctx)
    Crypt::OpenSSL::Bignum self;
    Crypt::OpenSSL::Bignum exp;
    Crypt::OpenSSL::Bignum::CTX ctx;
  PREINIT:
    BIGNUM* bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_exp( bn, self, exp, ctx ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
BN_mod_exp(self, exp, mod, ctx)
    Crypt::OpenSSL::Bignum self;
    Crypt::OpenSSL::Bignum exp;
    Crypt::OpenSSL::Bignum mod;
    Crypt::OpenSSL::Bignum::CTX ctx;
  PREINIT:
    BIGNUM* bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_mod_exp( bn, self, exp, mod, ctx ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
BN_mod_inverse(self, n, ctx)
    Crypt::OpenSSL::Bignum self;
    Crypt::OpenSSL::Bignum n;
    Crypt::OpenSSL::Bignum::CTX ctx;
  PREINIT:
    BIGNUM* bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_mod_inverse( bn, self, n, ctx ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
BN_gcd(self, b, ctx)
    Crypt::OpenSSL::Bignum self;
    Crypt::OpenSSL::Bignum b;
    Crypt::OpenSSL::Bignum::CTX ctx;
  PREINIT:
    BIGNUM* bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_gcd( bn, self, b, ctx ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

int
BN_equals(Crypt::OpenSSL::Bignum self, Crypt::OpenSSL::Bignum b)
  CODE:
    RETVAL = BN_cmp(self, b) == 0 ? 1 : 0;
  OUTPUT:
    RETVAL

int
BN_cmp(Crypt::OpenSSL::Bignum self, Crypt::OpenSSL::Bignum b)

int
BN_num_bits(Crypt::OpenSSL::Bignum self)

int
BN_num_bytes(Crypt::OpenSSL::Bignum self)

Crypt::OpenSSL::Bignum
BN_rshift(Crypt::OpenSSL::Bignum self, int n)
  PREINIT:
    BIGNUM* bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_rshift( bn, self, n ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

Crypt::OpenSSL::Bignum
BN_lshift(Crypt::OpenSSL::Bignum self, int n)
  PREINIT:
    BIGNUM* bn;
  CODE:
    checkOpenSslCall( bn = BN_new() );
    checkOpenSslCall( BN_lshift( bn, self, n ) );
    RETVAL = bn;
  OUTPUT:
    RETVAL

int
BN_ucmp(Crypt::OpenSSL::Bignum self, Crypt::OpenSSL::Bignum b)

void
BN_swap(Crypt::OpenSSL::Bignum self, Crypt::OpenSSL::Bignum b)

Crypt::OpenSSL::Bignum
BN_copy(Crypt::OpenSSL::Bignum self)
  CODE:
    checkOpenSslCall( RETVAL = BN_dup(self) );
  OUTPUT:
    RETVAL

IV
BN_pointer_copy(Crypt::OpenSSL::Bignum self)
  CODE:
    checkOpenSslCall( RETVAL = PTR2IV(BN_dup(self)) );
  OUTPUT:
    RETVAL

MODULE = Crypt::OpenSSL::Bignum  PACKAGE = Crypt::OpenSSL::Bignum::CTX

Crypt::OpenSSL::Bignum::CTX
new(CLASS)
    CODE:
        RETVAL = BN_CTX_new();
    OUTPUT:
        RETVAL

void
DESTROY(Crypt::OpenSSL::Bignum::CTX self)
    CODE:
        BN_CTX_free(self);
