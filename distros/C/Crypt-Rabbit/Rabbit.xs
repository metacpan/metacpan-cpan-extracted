#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "_rabbit.c"

typedef struct rabbit {
    t_instance state;
}* Crypt__Rabbit;

MODULE = Crypt::Rabbit    PACKAGE = Crypt::Rabbit
PROTOTYPES: DISABLE

Crypt::Rabbit
new(class, rawkey)
    SV* rawkey
    CODE:
    {
        STRLEN keyLength;
        if (! SvPOK(rawkey))
            croak("Key setup error: Key must be a string scalar!");

        keyLength = SvCUR(rawkey);
        if (keyLength != 16)
            croak("Key setup error: Key must be 16 bytes long!");

        Newz(0, RETVAL, 1, struct rabbit);
        key_setup(&RETVAL->state, SvPV_nolen(rawkey));
    }

    OUTPUT:
        RETVAL

SV*
rabbit_enc(self, input)
    Crypt::Rabbit self
    SV* input
    CODE:
    {
        STRLEN bufsize;
        unsigned char* intext = SvPV(input, bufsize);
        RETVAL = newSVpv("", bufsize);
        cipher(&self->state, intext, SvPV_nolen(RETVAL), bufsize);
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Crypt::Rabbit self
    CODE:
        Safefree(self);

