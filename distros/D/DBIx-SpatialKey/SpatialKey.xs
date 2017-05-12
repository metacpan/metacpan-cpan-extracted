#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef unsigned int UI;
typedef unsigned char u8;

typedef struct {
  UI dims;
  UI bitlen,len;
  UI maxmask;
  U32 *dim;
  U32 *mask;
  U32 *shift;
} keydef;

typedef struct {
  U32 mask;
  U32 *val;
} genindex;

/* could be optimized */
static UI
bits (U32 val)
{
  UI bits = 0;

  while (val > 0)
    {
      val >>= 1;
      bits++;
    }
  
  return bits;
}

static SV *
neuSV (STRLEN len)
{
  SV *r = newSVpv ("", 0);

  SvGROW (r, len);
  SvCUR_set (r, len);
  Zero (SvPV (r, len), len, char);

  return r;
}

#if 0
static void gen_ranges (const keydef *kd, U32 *min, U32 *max, AV *av, I32 r, U32 d, U32 mask, I32 out, u8 out_mask)
{
  printf ("gen_ranges (r=%d, d=%d, mask=%08lx, out=%d, out_mask=%02x)\n", r,d,mask,out,out_mask);/*D*/
  /* advance one bit */
  d++;
  if (d >= kd->dims)
    d = 0;

  if (d == 0)
    {
      mask >>= 1;
      if (!mask)
        return;
    }

  out_mask >>= 1;
  if (!out_mask)
    {
      out++;
      out_mask = 128;
    }
  
  printf (" gen_ranges (r=%d, d=%d, mask=%08lx, out=%d, out_mask=%02x)\n", r,d,mask,out,out_mask);/*D*/

  /* check the bit. bucket? */
  //gen_ranges (kd, av, 0, min, max, out, out_mask);
  if (kd->dim[d] >= mask)
    {
          printf (" init\n");
      if ((min[d] ^ max[d]) & mask)
        {
          /* uh-oh, we must split the range */
          I32 s;
          SV *sv;
          printf (" cloning\n");

          /* get high range */
          sv = SvREFCNT_inc (*av_fetch (av, r+1, 0));

          /* set low range */
          av_store (av, r+1, newSVsv (*av_fetch (av, r, 0)));

          printf (" cloning4\n");

          min[d] = ~0; gen_ranges (kd, min, max, av, r, d, mask, out, out_mask);

          SvPV(sv,PL_na)[out] |= out_mask;
          av_push (av,          sv );
          r = av_len (av);
          av_push (av, newSVsv (sv));

          min[d] =  0;
        }
      else if (min[d] & mask)
        {
          SvPV(*av_fetch(av,r  ,0),PL_na)[out] |= out_mask;
          SvPV(*av_fetch(av,r+1,0),PL_na)[out] |= out_mask;
        }
    }

  gen_ranges (kd, min, max, av, r, d, mask, out, out_mask);
}
#endif

MODULE = DBIx::SpatialKey		PACKAGE = DBIx::SpatialKey::BinaryMorton

PROTOTYPES: ENABLE

SV *
new(class,...)
	char *	class
	CODE:
        keydef *kd;
        int i;
        New (0, kd, 1, keydef);
        kd->dims = items-1;
        New (0, kd->dim  , items-1, U32);
        New (0, kd->shift, items-1, U32);
        New (0, kd->mask , items-1, U32);

        kd->bitlen = 0;
        kd->maxmask = 1;
        for (i = 1; i < items; i++)
          {
            UI b;
            kd->dim[i-1] = SvIV(ST(i));
            b = bits (kd->dim[i-1]);
            if (b == 0)
              croak ("dimension must be > 0");
            if (b > 31)
              croak ("dimension too large (max. 31 bits supported in this version)");
            kd->bitlen += b;
            kd->mask[i-1] = b;
            if (b > kd->maxmask)
              kd->maxmask = b;
          }

        kd->len = (kd->bitlen+7) >> 3;

        for (i = 0; i < items-1; i++)
          {
            kd->shift[i] = kd->maxmask - kd->mask[i];
            kd->mask[i] = ((1 << kd->mask[i])-1) << kd->shift[i];
          }

        kd->maxmask = 1 << (kd->maxmask-1);

        RETVAL = newSV (0);
        sv_setref_pv (RETVAL, class, kd);
        OUTPUT:
        RETVAL

void
DESTROY(obj)
	SV *	obj
        CODE:
        keydef *kd = (keydef*)SvIV(SvRV(obj));
        Safefree (kd->mask);
        Safefree (kd->shift);
        Safefree (kd->dim);
        Safefree (kd);

SV *
index(obj,...)
	SV *	obj
        CODE:
        keydef *kd = (keydef*)SvIV(SvRV(obj));
        U32 *val;
        U32 mask;
        u8 *out;
        u8 out_mask;
        UI i;
        if (items-1 != kd->dims)
	  croak ("expected %d values, not %d", kd->dims, items-1);

        RETVAL = neuSV (kd->len);

        out = SvPV (RETVAL, PL_na);
        out_mask = 0; out--;

        mask = kd->maxmask;
        New (0, val, kd->dims, U32);

        for (i = 1; i < items; i++)
          val[i-1] = (SvIV(ST(i))) << kd->shift[i-1];

        do
          {
            for (i = 0; i < kd->dims; i++)
              if (kd->mask[i] & mask)
                {
                  if (!out_mask)
                    {
                      out++;
                      out_mask = 128;
                    }
                  if (val[i] & mask)
                    *out |= out_mask;
                  out_mask >>= 1;
                }

            mask >>= 1;
          }
        while (mask);

        Safefree (val);
	OUTPUT:
        RETVAL

void
unpack(obj,key)
	SV *	obj
        SV *	key
        PPCODE:
        keydef *kd = (keydef*)SvIV(SvRV(obj));
        U32 *val;
        U32 mask;
        u8 *out;
        u8 out_mask;
        UI i;

        out = SvPV (key, PL_na);
        out_mask = 0; out--;

        mask = kd->maxmask;
        Newz (0, val, kd->dims, U32);

        do
          {
            for (i = 0; i < kd->dims; i++)
              if (kd->mask[i] & mask)
                {
                  if (!out_mask)
                    {
                      out++;
                      out_mask = 128;
                    }
                  if (*out & out_mask)
                    val[i] |= mask;
                  out_mask >>= 1;
                }

            mask >>= 1;
          }
        while (mask);

        EXTEND(SP,kd->dims);
        for (i = 0; i < kd->dims; i++)
          PUSHs (sv_2mortal (newSViv (val[i] >> kd->shift[i])));

        Safefree (val);

void
ranges(obj,...)
	SV *	obj
        PPCODE:
        keydef *kd = (keydef*)SvIV(SvRV(obj));
#if 1
        croak ("ranges not supported in this version");
#else
        U32 *min, *max;
        U32 mask;
        I32 out;
        u8 out_mask;
        AV *av = newAV ();
        UI i;
        if (items-1 != 2*kd->dims)
	  croak ("expected %d values, not %d", 2*kd->dims, items-1);

        New (0, min, kd->dims, U32);
        New (0, max, kd->dims, U32);

        for (i = 0; i < kd->dims; i++)
          {
            min[i] = SvIV(ST(i*2+1));
            max[i] = SvIV(ST(i*2+2));
          }

        av_push (av, neuSV (kd->len));
        av_push (av, neuSV (kd->len));

        out = -1;
        out_mask = 0;

        mask = kd->maxmask << 1;

        //gen_indices (kd, min, max, av, 0, kd->dims, mask, out, out_mask);

        Safefree (min);
        Safefree (max);

        for (i = 0; i <= av_len (av); i++)
          PUSHs (sv_2mortal (SvREFCNT_inc (*av_fetch (av, i, 0))));
        
        av_undef (av);
#endif
        
