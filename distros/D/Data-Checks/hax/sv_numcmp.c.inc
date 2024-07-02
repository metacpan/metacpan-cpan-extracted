/* vi: set ft=c : */

/* We'd like to call Perl_do_ncmp, except that isn't an exported API function
 * Here's a near-copy of it */

#define sv_numcmp(left, right)  S_sv_numcmp(aTHX_ left, right)
static int S_sv_numcmp(pTHX_ SV *left, SV *right)
{
#ifndef HAVE_BOOL_SvIV_please_nomg
  /* Before perl 5.18, SvIV_please_nomg() was void-returning */
  SvIV_please_nomg(left);
  SvIV_please_nomg(right);
#endif

  if(
#ifdef HAVE_BOOL_SvIV_please_nomg
    SvIV_please_nomg(right) && SvIV_please_nomg(left)
#else
    SvIOK(left) && SvIOK(right)
#endif
  ) {
    /* Compare as integers */
    switch((SvUOK(left) ? 1 : 0) | (SvUOK(right) ? 2 : 0)) {
      case 0: /* IV == IV */
      {
        const IV liv = SvIVX(left), riv = SvIVX(right);
        if     (liv < riv) return -1;
        else if(liv > riv) return  1;
        else               return  0;
      }

      case 1: /* UV == IV */
      {
        const IV riv = SvUVX(right);
        if(riv < 0)
          return 1;
        const IV liv = SvIVX(left);
        if     (liv < riv) return -1;
        else if(liv > riv) return  1;
        else               return  0;
      }

      case 2: /* IV == UV */
      {
        const IV liv = SvUVX(left);
        if(liv < 0)
          return -1;
        const IV riv = SvIVX(right);
        if     (liv < riv) return -1;
        else if(liv > riv) return  1;
        else               return  0;
      }

      case 3: /* UV == UV */
      {
        const UV luv = SvUVX(left), ruv = SvUVX(right);
        if     (luv < ruv) return -1;
        else if(luv > ruv) return  1;
        else               return  0;
      }
    }
  }
  else {
    /* Compare NVs */
    NV const rnv = SvNV_nomg(right);
    NV const lnv = SvNV_nomg(left);

    if     (lnv < rnv) return -1;
    else if(lnv > rnv) return  1;
    else               return  0;
  }
}
