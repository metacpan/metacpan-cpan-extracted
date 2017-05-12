#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct {
    unsigned char H[16]; /* Hash subkey */
    unsigned char buf[16];
    unsigned char X[16];
    unsigned char Y[16];
    unsigned char Y_0[16];
    unsigned char EY_0[16]; /* E(K,Y_0) encrypted original counter */
    int with_aad;
    int ivmode;
    size_t buflen;
    unsigned long long totlen;
    unsigned long long pttotlen;
} GCM_context;

typedef struct gcm_state {
    GCM_context ctx;
    SV *cipher;
    unsigned char *iv;
    size_t iv_size;
    unsigned char *aad;
    size_t aad_size;
    unsigned char tag[16];
} *Crypt__GCM;

static unsigned char MASK[] = { 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01 };
static unsigned char POLY[] = { 0x00, 0xE1 };


static void _right_shift(unsigned char *a)
{
   int i;
   for (i = 15; i > 0; i--) {
       a[i] = (a[i]>>1) | ((a[i-1]<<7)&0x80);
   }
   a[0] >>= 1;
}


/* 7.2 The Incrementing Function */
static void _inc(GCM_context *ctx)
{
    int i;
    unsigned char *ctr = ctx->Y;
    for (i = 15; i >= 12; i--) {
        if (++ctr[i])
            break;
    }
}

/* 7.3 The Multiplication Operation on Blocks */
/* gcm_gf_mult() */
static void multiplicate_block(unsigned char *c, const unsigned char *a, const unsigned char *b)
{
   unsigned char Z[16], V[16];
   unsigned x, y, z;

   memset(Z, 0, sizeof(Z));
   memmove(V, a, sizeof(V));
   for (x = 0; x < 128; x++) {
       if (b[x>>3] & MASK[x&7]) {
          for (y = 0; y < 16; y++) {
              Z[y] ^= V[y];
          }
       }
       z = V[15] & 0x01;
       _right_shift(V);
       V[0] ^= POLY[z];
   }
   memmove(c, Z, sizeof(Z));
}

/* 7.4 The GHASH Function */
/* gcm_mult_h() */
static void ghash(unsigned char *H, unsigned char *X)
{
    unsigned char T[16];

    multiplicate_block(T, H, X);
    memmove(X, T, sizeof(T));
}


SV *_new_cipher(SV *class, SV *key)
{
    dSP;
    SV *obj;
    int i;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUSHs(class);
    PUSHs(key);
    PUTBACK;
    call_method("new", G_SCALAR);
    SPAGAIN;
    obj = sv_mortalcopy(POPs);
    PUTBACK;
    LEAVE;

    return obj;
}

void _encrypt_block(SV *cipher, unsigned char *in, unsigned char *out)
{
    dSP;
    SV *rv;
    int i;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUSHs(cipher);
    PUSHs(sv_2mortal(newSVpv((char *)in, 16)));
    PUTBACK;
    call_method("encrypt", G_SCALAR);
    SPAGAIN;
    rv = POPs;
    memmove(out, SvPVbyte_nolen(rv), 16);

    PUTBACK;
    LEAVE;
}

void get_tag(GCM_context *ctx, unsigned char *tag)
{
    unsigned long i;

    if (ctx->buflen) {
        ctx->pttotlen += ctx->buflen * 8;
        ghash(ctx->H, ctx->X);
    }

    /* get length */
    ctx->buf[0] = (ctx->totlen >> 56) & 0xff;
    ctx->buf[1] = (ctx->totlen >> 48) & 0xff;
    ctx->buf[2] = (ctx->totlen >> 40) & 0xff;
    ctx->buf[3] = (ctx->totlen >> 32) & 0xff;
    ctx->buf[4] = (ctx->totlen >> 24) & 0xff;
    ctx->buf[5] = (ctx->totlen >> 16) & 0xff;
    ctx->buf[6] = (ctx->totlen >>  8) & 0xff;
    ctx->buf[7] = (ctx->totlen)       & 0xff;
    ctx->buf[8+0] = (ctx->pttotlen >> 56) & 0xff;
    ctx->buf[8+1] = (ctx->pttotlen >> 48) & 0xff;
    ctx->buf[8+2] = (ctx->pttotlen >> 40) & 0xff;
    ctx->buf[8+3] = (ctx->pttotlen >> 32) & 0xff;
    ctx->buf[8+4] = (ctx->pttotlen >> 24) & 0xff;
    ctx->buf[8+5] = (ctx->pttotlen >> 16) & 0xff;
    ctx->buf[8+6] = (ctx->pttotlen >>  8) & 0xff;
    ctx->buf[8+7] = (ctx->pttotlen)       & 0xff;
    for (i = 0; i < 16; i++) {
        ctx->X[i] ^= ctx->buf[i];
    }
    ghash(ctx->H, ctx->X);

    for (i = 0; i < 16; i++) {
        tag[i] = ctx->EY_0[i] ^ ctx->X[i];
    }
}


int _add_aad(struct gcm_state *self)
{
    STRLEN l;
    unsigned char *in;
    unsigned long i;
    GCM_context *ctx;

    l = self->aad_size;
    in = self->aad;

    ctx = &(self->ctx);
    if (ctx->ivmode || ctx->buflen != 12) {
        for (i = 0; i < (unsigned long)ctx->buflen; i++) {
            ctx->X[i] ^= ctx->buf[i];
        }
        if (ctx->buflen) {
            ctx->totlen += ctx->buflen * 8;
            ghash(ctx->H, ctx->X);
        }

        memset(ctx->buf, 0, 8);
        ctx->buf[8+0] = (ctx->totlen >> 56) & 0xff;
        ctx->buf[8+1] = (ctx->totlen >> 48) & 0xff;
        ctx->buf[8+2] = (ctx->totlen >> 40) & 0xff;
        ctx->buf[8+3] = (ctx->totlen >> 32) & 0xff;
        ctx->buf[8+4] = (ctx->totlen >> 24) & 0xff;
        ctx->buf[8+5] = (ctx->totlen >> 16) & 0xff;
        ctx->buf[8+6] = (ctx->totlen >>  8) & 0xff;
        ctx->buf[8+7] = (ctx->totlen)       & 0xff;
        for (i = 0; i < 16; i++) {
            ctx->X[i] ^= ctx->buf[i];
        }
        ghash(ctx->H, ctx->X);

        /* copy counter */
        memmove(ctx->Y, ctx->X, 16);
        memset(ctx->X, 0, 16);
    }
    else {
        memmove(ctx->Y, ctx->buf, 12);
        ctx->Y[12] = 0;
        ctx->Y[13] = 0;
        ctx->Y[14] = 0;
        ctx->Y[15] = 1;
    }
    memmove(ctx->Y_0, ctx->Y, 16);
    memset(ctx->buf, 0, 16);
    ctx->buflen = 0;
    ctx->totlen = 0;
    ctx->with_aad = 1;

    for (i = 0; i < l; i++) {
        ctx->X[ctx->buflen++] ^= *in++;
        if (ctx->buflen != 16)
            continue;
        ghash(ctx->H, ctx->X);
        ctx->buflen = 0;
        ctx->totlen += 128;
    }
    _encrypt_block(self->cipher, ctx->Y_0, ctx->EY_0);
    return l;
}



MODULE = Crypt::GCM		PACKAGE = Crypt::GCM		


Crypt::GCM
new(class, ...)
    SV *class
    CODE:
    {
        STRLEN keysize;
        unsigned char tmp[16];
        char *argkey;
        SV *key;
        SV *cipher;
        int i;

        /* fetch -key => '', -cipher => '' */
        key    = sv_2mortal(newSV(0));
        cipher = sv_2mortal(newSV(0));
        if (items == 1 || (items - 1) % 2 != 0) {
            croak("please provide -key => $value arguments");
        }
        for (i = 1; i < items; i += 2) {
            argkey = (char *)SvPVbyte_nolen((SV *)ST(i));
            if (strcasecmp(argkey, "-key") == 0) {
                SvSetSV(key, ST(i+1));
            }
            else if (strcasecmp(argkey, "-cipher") == 0) {
                SvSetSV(cipher, ST(i+1));
            }
            else {
                warn("unknown parameter, please provide -key/-cipher arguments");
            }
        }

        if (!SvOK(key))
            croak("please provide an encryption/decryption key using -key");
        keysize = SvCUR(key);
        if (keysize == 0)
            croak("please provide an encryption/decryption key using -key");
        if (!SvOK(cipher))
            croak("please provide an Crypt::* module name using -cipher");

        Newz(0, RETVAL, 1, struct gcm_state);


        RETVAL->cipher = _new_cipher(cipher, key);
        sv_newref(RETVAL->cipher);

        RETVAL->aad = NULL;
        RETVAL->aad_size = 0;
        memset(RETVAL->tag, 0, 16);

        /* $ctx->encrypt($tmp); */
        memset(tmp, 0, sizeof(tmp));
        _encrypt_block(RETVAL->cipher, tmp, RETVAL->ctx.H);

        memset(RETVAL->ctx.buf, 0, 16);
        memset(RETVAL->ctx.X, 0, 16);
        RETVAL->ctx.buflen = 0;
        RETVAL->ctx.totlen = 0;
        RETVAL->ctx.pttotlen = 0;
        RETVAL->ctx.with_aad = 0;
        RETVAL->ctx.ivmode = 0;
        RETVAL->iv = NULL;
    }
    OUTPUT:
        RETVAL

SV *
tag(self, ...)
    Crypt::GCM self
    CODE:
    {
        SV *in;

        if (items > 1) {
            in = ST(1);
            if (SvCUR(in) != 16)
                croak("tag is short/long. please set 128bit length tag");

            memmove(self->tag, SvPVbyte_nolen(in), 16);
        }
        RETVAL = newSVpv((char *)self->tag, 16);
    }
    OUTPUT:
        RETVAL

SV *
aad(self, ...)
    Crypt::GCM self
    CODE:
    {
        SV *in;

        if (items > 1) {
            in = ST(1);
            if (self->aad != NULL)
                Safefree(self->aad);
            self->aad_size = SvCUR(in);
            //self->aad = malloc(self->aad_size);
            Newz(0, self->aad, self->aad_size, unsigned char);
            if (self->aad == NULL)
                croak("cannot allocate aad storage buffer");
            memmove(self->aad, SvPVbyte(in, self->aad_size), self->aad_size);
        }
        RETVAL = newSVpv((char *)self->aad, self->aad_size);
    }
    OUTPUT:
        RETVAL

void
set_iv(self, iv)
    Crypt::GCM self
    SV *iv
    CODE:
    {
        STRLEN size;
        unsigned char *raw = (unsigned char *)SvPV(iv, size);
        int i, j;

        if (self->iv != NULL)
            Safefree(self->iv);
        self->iv_size = size;
        self->iv = malloc(sizeof(unsigned char)*self->iv_size);
        if (self->iv == NULL)
            croak("cannot allocate iv storage");
        memmove(self->iv, raw, self->iv_size);

        if (size + self->ctx.buflen > 12) {
            self->ctx.ivmode |= 1;
        }
        for (i = 0; i < size; i++) {
            self->ctx.buf[self->ctx.buflen++] = *raw++;
            if (self->ctx.buflen != 16)
                continue;
            for (j = 0; j < 16; j++) {
                self->ctx.X[j] ^= self->ctx.buf[j];
            }
            ghash(self->ctx.H, self->ctx.X);
            self->ctx.buflen = 0;
            self->ctx.totlen += 128;
        }
    }


SV *
encrypt(self, data)
    Crypt::GCM self
    SV *data
    ALIAS:
        decrypt = 1
    CODE:
    {
        STRLEN l;
        unsigned char *in = (unsigned char *)SvPV(data, l);
        unsigned long i;
        unsigned char b;
        unsigned char *out;
        unsigned char tag[16];

        GCM_context *ctx = &(self->ctx);
        _add_aad(self);

        if (ctx->with_aad) {
            if (ctx->buflen) {
                ctx->totlen += ctx->buflen * 8;
                ghash(ctx->H, ctx->X);
            }
            _inc(ctx);
            _encrypt_block(self->cipher, ctx->Y, ctx->buf);
            ctx->buflen = 0;
            ctx->with_aad = 0;
        }

        out = malloc(sizeof(unsigned char) * l);
        if (out == NULL)
            croak("cannot allocate encrypt buffer");
        for (i = 0; i < l; i++) {
            if (ctx->buflen == 16) {
                ctx->pttotlen += 128;
                ghash(ctx->H, ctx->X);
                _inc(ctx);
                _encrypt_block(self->cipher, ctx->Y, ctx->buf);
                ctx->buflen = 0;
            }

            if (ix) {
                /* decrypt */
                b = in[i];
                out[i] = in[i] ^ ctx->buf[ctx->buflen];
            }
            else {
                /* encrypt */
                b = out[i] = in[i] ^ ctx->buf[ctx->buflen];
            }
            ctx->X[ctx->buflen++] ^= b;
        }

        get_tag(ctx, tag);
        if (!ix) { /* encrypt */
            memmove(self->tag, tag, 16);
            RETVAL = newSVpv((const char *)out, l);
        }
        else {
            if (memcmp(tag, self->tag, sizeof(tag)) != 0) {
                RETVAL = &PL_sv_undef;
            }
            else {
                RETVAL = newSVpv((const char *)out, l);
            }
        }
        Safefree(out);
    }
    OUTPUT:
        RETVAL



void
DESTROY(self)
    Crypt::GCM self
    CODE:
    {
        if (self->iv != NULL) {
            Safefree(self->iv);
            self->iv = NULL;
        }
        if (self->aad != NULL) {
            Safefree(self->aad);
            self->aad = NULL;
            self->aad_size = 0;
        }
        sv_free(self->cipher);
        Safefree(self);
    }
