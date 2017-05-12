#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


typedef struct arcfour_t {
    unsigned char sbox[256];
    int x;
    int y;
} *Crypt__RC4__XS;


static void setup_key(struct arcfour_t *ctx, unsigned char *key, size_t key_len)
{
    int x;
    int y = 0;
    int tmp;
    unsigned char *sbox = ctx->sbox;

    ctx->x = 0;
    ctx->y = 0;
    for (x = 0; x < 256; x++)
        sbox[x] = x;
    for (x = 0; x < 256; x++) {
        y = (y + sbox[x] + key[x % key_len]) % 256;

        tmp = sbox[x];
        sbox[x] = sbox[y];
        sbox[y] = tmp;
    }
}


static void arcfour_encrypt(struct arcfour_t *ctx,
                            const unsigned char *src, unsigned char *dist,
                            size_t l)
{
    int x = ctx->x;
    int y = ctx->y;
    int tmp;
    unsigned char *sbox = ctx->sbox;

    for (; l > 0; l--) {
        x++;
        if (x > 255)
            x = 0;
        y += sbox[x];
        if (y > 255)
            y -= 256;

        tmp = sbox[x];
        sbox[x] = sbox[y];
        sbox[y] = tmp;
        *dist++ = (*src++ ^ sbox[(sbox[x] + sbox[y]) % 256]);
    }
    ctx->x = x;
    ctx->y = y;
}



MODULE = Crypt::RC4::XS		PACKAGE = Crypt::RC4::XS		

Crypt::RC4::XS
new(class, key)
    SV *class
    SV *key
    CODE:
    {
        STRLEN l;
        struct arcfour_t *self;
        unsigned char *k;

        class = class; /* dummy code */
        Newz(0, self, 1, struct arcfour_t);
        k = (unsigned char *)SvPV(key, l);
        setup_key(self, k, l);
        RETVAL = self;
    }
    OUTPUT:
        RETVAL


SV *
RC4(obj_or_key, msg)
    SV *obj_or_key
    SV *msg
    CODE:
    {
        STRLEN l;
        struct arcfour_t ctx;
        struct arcfour_t *obj;
        unsigned char *key, *dist;
        const unsigned char *m; 

        if (sv_isobject(obj_or_key) && sv_derived_from(obj_or_key, "Crypt::RC4::XS")) {
            obj = INT2PTR(Crypt__RC4__XS, SvIV((SV*)SvRV(obj_or_key)));

            m = (unsigned char *)SvPV(msg, l);
            RETVAL = newSVsv(msg);
            dist = (unsigned char *)SvPV(RETVAL, l);
            arcfour_encrypt(obj, m, dist, l);
        }
        else {
            key = (unsigned char *)SvPV(obj_or_key, l);
            setup_key(&ctx, key, l);

            m = (const unsigned char *)SvPV(msg, l);
            RETVAL = newSVsv(msg);
            dist = (unsigned char *)SvPV(RETVAL, l);
            arcfour_encrypt(&ctx, m, dist, l);
        }
    }
    OUTPUT:
        RETVAL

