#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* try to be compatible with older perls */
/* SvPV_nolen() macro first defined in 5.005_55 */
/* this is slow, not threadsafe, but works */
#include "patchlevel.h"
#if (PATCHLEVEL == 4) || ((PATCHLEVEL == 5) && (SUBVERSION < 55))
static STRLEN nolen_na;
# define SvPV_nolen(sv) SvPV ((sv), nolen_na)
#endif

#include "lzv1/lzv1.c"

MODULE = Compress::LZV1   PACKAGE = Compress::LZV1

SV *
compress(data)
        SV *	data
        PROTOTYPE: $
        CODE:
        {
          STRLEN usize, csize;
          void *src = SvPV(data, usize);
          unsigned char *dst;
          unsigned short heap[HSIZ]; /* need not be initialized */

          if (usize)
            {
              RETVAL = NEWSV (0, usize + 1);
              SvPOK_only (RETVAL);
              dst = (unsigned char *)SvPV_nolen (RETVAL);

              /* compress  */
              csize = wLZV1 ((uch *)src, (uch *)(dst + 4), heap, usize, usize - 5);
              if (csize)
                {
                  dst[0] = 'L'; /* compressed flag */
                  dst[1] = usize >> 16;
                  dst[2] = usize >>  8;
                  dst[3] = usize >>  0;

                  SvCUR_set (RETVAL, csize + 4);
                }
              else
                {
                  dst[0] = 'U';
                  Move ((void *)src, (void *)(dst + 1), usize, unsigned char);
                  SvCUR_set (RETVAL, usize + 1);
                }
            }
          else
            RETVAL = newSVpv ("", 0);
        }
	OUTPUT:
        RETVAL

SV *
decompress(data)
        SV *	data
        PROTOTYPE: $
        CODE:
        {
          STRLEN usize, csize;
          unsigned char *src = (unsigned char *)SvPV(data, csize);
          void *dst;

          if (csize)
            {
              switch (src[0]) {
                case 'U':
                  usize = csize - 1;
                  RETVAL = NEWSV (0, usize);
                  SvPOK_only (RETVAL);
                  dst = SvPV_nolen (RETVAL);

                  Move ((void *)(src + 1), (void *)dst, usize, unsigned char);
                  break;
                case 'L':
                  usize = (src[1] << 16)
                        | (src[2] <<  8)
                        | (src[3] <<  0);
                  RETVAL = NEWSV (0, usize);
                  SvPOK_only (RETVAL);
                  dst = SvPV_nolen (RETVAL);

                  if (rLZV1 ((uch *)(src + 4), (uch *)dst, csize - 4, usize) != usize)
                    croak ("LZV1: compressed data corrupted (2)");
                  break;
                default:
                  croak ("LZV1: compressed data corrupted (1)");
              }

              SvCUR_set (RETVAL, usize);
            }
          else
            RETVAL = newSVpv ("", 0);
        }
	OUTPUT:
        RETVAL

