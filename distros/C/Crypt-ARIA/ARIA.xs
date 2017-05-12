#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "aria.inc"


MODULE = Crypt::ARIA		PACKAGE = Crypt::ARIA		

PROTOTYPES: ENABLE

SV *
_crypt( data, round, roundkey )
        SV *           data
        int            round
        const Byte *   roundkey
    PREINIT:
        unsigned char buf[16];
        STRLEN len = 0;
        char * pdata;
    CODE:
        pdata = (char *)SvPV(data, len);
        if ( len != 16 ) {
            XSRETURN_UNDEF;
        }
        Crypt( (const Byte *)pdata, round, roundkey, (Byte *)buf );
        RETVAL = newSVpvn((const char*)buf, 16);
    OUTPUT:
        RETVAL


void
_setup_enc_key( mk, keybits )
        const Byte * mk
        int keybits
    PREINIT:
        int round;
        Byte rkey[16*17];
    PPCODE:
        round = EncKeySetup(mk, rkey, keybits);
        XPUSHs( sv_2mortal(newSVnv(round)) );
        XPUSHs( sv_2mortal(newSVpvn((const char *)rkey, 16*17*sizeof(Byte))) );

void
_setup_dec_key( mk, keybits )
        const Byte * mk
        int keybits
    PREINIT:
        int round;
        Byte rkey[16*17];
    PPCODE:
        round = DecKeySetup(mk, rkey, keybits);
        XPUSHs( sv_2mortal(newSVnv(round)) );
        XPUSHs( sv_2mortal(newSVpvn((const char *)rkey, 16*17*sizeof(Byte))) );

