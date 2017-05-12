/*-*- Mode: C -*-*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <inttypes.h>
/*#include "ppport.h"*/

#ifndef uchar
typedef unsigned char uchar;
#endif

#ifdef U64TYPE
#define ABSV_HAVE_QUAD
#define ABSV_UINT U64TYPE
#define ABSV_PRI  "%" PRIu64
#else
#undef ABSV_HAVE_QUAD
#define ABSV_UINT U32
#define ABSV_PRI  "%" PRIu32
#endif /* U64TYPE */

//const ABSV_UINT KEY_NOT_FOUND = (ABSV_UINT)-1;
const ABSV_UINT KEY_NOT_FOUND = 0xffffffff; /*-- still always just 32-bit --*/

/*==============================================================================
 * Utils
 */

//--------------------------------------------------------------
static inline int absv_cmp(ABSV_UINT a, ABSV_UINT b)
{
  if      (a<b) return -1;
  else if (a>b) return  1;
  return 0;
}

//--------------------------------------------------------------
static inline ABSV_UINT absv_vget(const uchar *v, ABSV_UINT i, ABSV_UINT nbits)
{
  //fprintf(stderr, "DEBUG: absv_vget() called with INDEX=%lu, NBITS=%lu\n", i, nbits);
  switch (nbits) {
  case 1:	return (v[i>>3] >>  (i&7)    ) &  1;
  case 2:	return (v[i>>2] >> ((i&3)<<1)) &  3;
  case 4:	return (v[i>>1] >> ((i&1)<<2)) & 15;
  case 8:	return (v[i]);
  case 16:	i <<= 1; return (v[i]<<8)  | (v[i+1]);
  case 32:	i <<= 2; return (v[i]<<24) | (v[i+1]<<16) | (v[i+2]<<8) | (v[i+3]);
#ifdef ABSV_HAVE_QUAD
  case 64:
    i <<= 3;
    return ((ABSV_UINT)(v[i]  )<<56) | ((ABSV_UINT)(v[i+1])<<48) | ((ABSV_UINT)(v[i+2])<<40) | ((ABSV_UINT)(v[i+3])<<32)
          |((ABSV_UINT)(v[i+4])<<24) | ((ABSV_UINT)(v[i+5])<<16) | ((ABSV_UINT)(v[i+6])<< 8) | ((ABSV_UINT)(v[i+7])    );
#endif
  default: break;
  }
  croak("absv_vget() cannot handle NBITS=" ABSV_PRI " for INDEX=" ABSV_PRI, nbits, i);
  return KEY_NOT_FOUND;
}

//--------------------------------------------------------------
static inline void absv_vset(uchar *v, ABSV_UINT i, ABSV_UINT nbits, ABSV_UINT val)
{
  ABSV_UINT b;
  switch (nbits) {
  case 1:	b=i&7;      i>>=3; v[i] = (v[i]&~( 1<<b)) | ((val& 1)<<b); break;
  case 2:	b=(i&3)<<1; i>>=2; v[i] = (v[i]&~( 3<<b)) | ((val& 3)<<b); break;
  case 4:	b=(i&1)<<2; i>>=1; v[i] = (v[i]&~(15<<b)) | ((val&15)<<b); break;
  case 8:	v[i] = (val & 255); break;
  case 16:	v += (i<<1); *v++=(val>> 8)&0xff; *v=(val&0xff); break;
  case 32:	v += (i<<2); *v++=(val>>24)&0xff; *v++=(val>>16)&0xff; *v++=(val>>8)&0xff; *v=val&0xff; break;
#ifdef ABSV_HAVE_QUAD
  case 64:
    v += (i<<3);
    *v++=(val>>56)&0xff; *v++=(val>>48)&0xff; *v++=(val>>40)&0xff; *v++=(val>>32)&0xff;
    *v++=(val>>24)&0xff; *v++=(val>>16)&0xff; *v++=(val>> 8)&0xff; *v  =val      &0xff;
    break;
#endif
  default:
    croak("absv_vset() cannot handle NBITS=" ABSV_PRI " for INDEX=" ABSV_PRI, nbits, i);
    break;
  }
}

//--------------------------------------------------------------
static ABSV_UINT absv_bsearch(const uchar *v, ABSV_UINT key, ABSV_UINT ilo, ABSV_UINT ihi, ABSV_UINT nbits)
{
  while (ilo < ihi) {
    ABSV_UINT imid = (ilo+ihi) >> 1;
    if (absv_vget(v, imid, nbits) < key)
      ilo = imid + 1;
    else
      ihi = imid;
  }
  if ((ilo == ihi) && (absv_vget(v,ilo,nbits) == key))
    return ilo;
  else
    return KEY_NOT_FOUND;
}

//--------------------------------------------------------------
static ABSV_UINT absv_bsearch_lb(const uchar *v, ABSV_UINT key, ABSV_UINT ilo, ABSV_UINT ihi, ABSV_UINT nbits)
{
 ABSV_UINT imid, imin=ilo, imax=ihi;
 while (ihi-ilo > 1) {
   imid = (ihi+ilo) >> 1;
   if (absv_vget(v, imid, nbits) < key) {
     ilo = imid;
   } else {
     ihi = imid;
   }
 }
 if (               absv_vget(v,ilo,nbits)==key) return ilo;
 if (ihi <  imax && absv_vget(v,ihi,nbits)==key) return ihi;
 //if (ilo > imin || absv_vget(v,ilo,nbits) <key) return ilo; //-- doesn't respect strict imin test!
 if (ilo >= imin && absv_vget(v,ilo,nbits) <key) return ilo;
 return KEY_NOT_FOUND;
}

//--------------------------------------------------------------
static ABSV_UINT absv_bsearch_ub(const uchar *v, ABSV_UINT key, ABSV_UINT ilo, ABSV_UINT ihi, ABSV_UINT nbits)
{
 ABSV_UINT imid, imax=ihi;
 while (ihi-ilo > 1) {
   imid = (ihi+ilo) >> 1;
   if (absv_vget(v, imid, nbits) > key) {
     ihi = imid;
   } else {
     ilo = imid;
   }
 }
 if (ihi<imax && absv_vget(v,ihi,nbits)==key) return ihi;
 if (            absv_vget(v,ilo,nbits)>=key) return ilo;
 return ihi>=imax ? KEY_NOT_FOUND : ihi;
}

/*==============================================================================
 * XS Guts
 */

MODULE = Algorithm::BinarySearch::Vec    PACKAGE = Algorithm::BinarySearch::Vec::XS

PROTOTYPES: ENABLE

##===================================================================
## DEBUG
##=====================================================================

##--------------------------------------------------------------
ABSV_UINT
vget(SV *vec, ABSV_UINT i, ABSV_UINT nbits)
PREINIT:
  uchar *vp;
  STRLEN len;
CODE:
 vp = (uchar *)SvPVbyte(vec, len);
 if (len > i*nbits/8)
   RETVAL = absv_vget(vp, i, nbits);
 else
   RETVAL = 0;
OUTPUT:
  RETVAL

 ##--------------------------------------------------------------
void
vset(SV *vec, ABSV_UINT i, ABSV_UINT nbits, ABSV_UINT val)
PREINIT:
  uchar *vp;
  STRLEN len;
CODE:
 vp = (uchar *)SvPVbyte(vec,len);
 if (len <= i*nbits/8) {
#if 0
   //-- doesn't propagate to perl sv?
   vp = (uchar *)SvGROW(vec, (i+1)*nbits/8);
   SvCUR_set(vec, (i+1)*nbits/8);
#endif //-- re-allocate
   croak("vset(): index " ABSV_PRI " exceeds vector length = " ABSV_PRI " element(s)", i, i*nbits/8);
 }
 absv_vset(vp, i, nbits, val);

##=====================================================================
## CONSTANTS

##--------------------------------------------------------------
ABSV_UINT
HAVE_QUAD()
CODE:
#ifdef ABSV_HAVE_QUAD
 RETVAL = 1;
#else
 RETVAL = 0;
#endif
OUTPUT:
 RETVAL

##--------------------------------------------------------------
ABSV_UINT
KEY_NOT_FOUND()
CODE:
 RETVAL = KEY_NOT_FOUND;
OUTPUT:
 RETVAL

##=====================================================================
## BINARY SEARCH, element-wise

##--------------------------------------------------------------
ABSV_UINT
vbsearch(SV *vec, ABSV_UINT key, ABSV_UINT nbits, ...)
PREINIT:
  const uchar *v;
  STRLEN vlen;
  ABSV_UINT ilo, ihi;
CODE:
 v = SvPV(vec,vlen);
 ilo = items > 3 ? SvUV(ST(3)) : 0;
 ihi = items > 4 ? SvUV(ST(4)) : (vlen*8/nbits);
 RETVAL = absv_bsearch(v,key,ilo,ihi,nbits);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
ABSV_UINT
vbsearch_lb(SV *vec, ABSV_UINT key, ABSV_UINT nbits, ...)
PREINIT:
  const uchar *v;
  STRLEN vlen;
  ABSV_UINT ilo, ihi;
CODE:
 v = SvPV(vec,vlen);
 ilo = items > 3 ? SvUV(ST(3)) : 0;
 ihi = items > 4 ? SvUV(ST(4)) : (vlen*8/nbits);
 RETVAL = absv_bsearch_lb(v,key,ilo,ihi,nbits);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
ABSV_UINT
vbsearch_ub(SV *vec, ABSV_UINT key, ABSV_UINT nbits, ...)
PREINIT:
  const uchar *v;
  STRLEN vlen;
  ABSV_UINT ilo, ihi;
CODE:
 v = SvPV(vec,vlen);
 ilo = items > 3 ? SvUV(ST(3)) : 0;
 ihi = items > 4 ? SvUV(ST(4)) : (vlen*8/nbits);
 RETVAL = absv_bsearch_ub(v,key,ilo,ihi,nbits);
OUTPUT:
 RETVAL


##=====================================================================
## BINARY SEARCH, array-wise

##--------------------------------------------------------------
AV*
vabsearch(SV *vec, AV *keys, ABSV_UINT nbits, ...)
PREINIT:
  const uchar *v;
  STRLEN vlen;
  ABSV_UINT ilo, ihi;
  I32 i,n;
CODE:
 v = SvPV(vec,vlen);
 ilo = items > 3 ? SvUV(ST(3)) : 0;
 ihi = items > 4 ? SvUV(ST(4)) : (vlen*8/nbits);
 n = av_len(keys);
 RETVAL = newAV();
 av_extend(RETVAL, n);
 for (i=0; i<=n; ++i) {
   SV   **key  = av_fetch(keys, i, 0);
   ABSV_UINT   found = absv_bsearch(v,SvUV(*key),ilo,ihi,nbits);
   av_store(RETVAL, i, newSVuv(found));
 }
OUTPUT:
 RETVAL

##--------------------------------------------------------------
AV*
vabsearch_lb(SV *vec, AV *keys, ABSV_UINT nbits, ...)
PREINIT:
  const uchar *v;
  STRLEN vlen;
  ABSV_UINT ilo, ihi;
  I32 i,n;
CODE:
 v = SvPV(vec,vlen);
 ilo = items > 3 ? SvUV(ST(3)) : 0;
 ihi = items > 4 ? SvUV(ST(4)) : (vlen*8/nbits);
 n = av_len(keys);
 RETVAL = newAV();
 av_extend(RETVAL, n);
 for (i=0; i<=n; ++i) {
   SV   **key  = av_fetch(keys, i, 0);
   ABSV_UINT   found = absv_bsearch_lb(v,SvUV(*key),ilo,ihi,nbits);
   av_store(RETVAL, i, newSVuv(found));
 }
OUTPUT:
 RETVAL

##--------------------------------------------------------------
AV*
vabsearch_ub(SV *vec, AV *keys, ABSV_UINT nbits, ...)
PREINIT:
  const uchar *v;
  STRLEN vlen;
  ABSV_UINT ilo, ihi;
  I32 i,n;
CODE:
 v = SvPV(vec,vlen);
 ilo = items > 3 ? SvUV(ST(3)) : 0;
 ihi = items > 4 ? SvUV(ST(4)) : (vlen*8/nbits);
 n = av_len(keys);
 RETVAL = newAV();
 av_extend(RETVAL, n);
 for (i=0; i<=n; ++i) {
   SV   **key  = av_fetch(keys, i, 0);
   ABSV_UINT   found = absv_bsearch_ub(v,SvUV(*key),ilo,ihi,nbits);
   av_store(RETVAL, i, newSVuv(found));
 }
OUTPUT:
 RETVAL

##=====================================================================
## BINARY SEARCH, vec-wise

##--------------------------------------------------------------
SV*
vvbsearch(SV *vec, SV *vkeys, ABSV_UINT nbits, ...)
PREINIT:
  const uchar *v, *k;
  uchar *rv;
  STRLEN vlen, klen;
  ABSV_UINT i,n, ilo, ihi;
CODE:
 v = SvPV(vec,vlen);
 k = SvPV(vkeys,klen);
 ilo = items > 3 ? SvUV(ST(3)) : 0;
 ihi = items > 4 ? SvUV(ST(4)) : (vlen*8/nbits);
 n   = klen*8/nbits;
 RETVAL = newSVpv("",0);
 SvGROW(RETVAL, n*4);	       //-- always use 32-bit keys
 SvCUR_set(RETVAL, n*4);
 rv = SvPV_nolen(RETVAL);
 for (i=0; i<n; ++i) {
   ABSV_UINT key   = absv_vget(k,i,nbits);
   ABSV_UINT found = absv_bsearch(v,key,ilo,ihi,nbits);
   absv_vset(rv,i,32,found);
 }
OUTPUT:
 RETVAL

##--------------------------------------------------------------
SV*
vvbsearch_lb(SV *vec, SV *vkeys, ABSV_UINT nbits, ...)
PREINIT:
  const uchar *v, *k;
  uchar *rv;
  STRLEN vlen, klen;
  ABSV_UINT i,n, ilo, ihi;
CODE:
 v = SvPV(vec,vlen);
 k = SvPV(vkeys,klen);
 ilo = items > 3 ? SvUV(ST(3)) : 0;
 ihi = items > 4 ? SvUV(ST(4)) : (vlen*8/nbits);
 n   = klen*8/nbits;
 RETVAL = newSVpv("",0);
 SvGROW(RETVAL, n*4);	 	//-- always use 32-bit keys
 SvCUR_set(RETVAL, n*4);
 rv = SvPV_nolen(RETVAL);
 for (i=0; i<n; ++i) {
   ABSV_UINT key   = absv_vget(k,i,nbits);
   ABSV_UINT found = absv_bsearch_lb(v,key,ilo,ihi,nbits);
   absv_vset(rv,i,32,found);
 }
OUTPUT:
 RETVAL

##--------------------------------------------------------------
SV*
vvbsearch_ub(SV *vec, SV *vkeys, ABSV_UINT nbits, ...)
PREINIT:
  const uchar *v, *k;
  uchar *rv;
  STRLEN vlen, klen;
  ABSV_UINT i,n, ilo, ihi;
CODE:
 v = SvPV(vec,vlen);
 k = SvPV(vkeys,klen);
 ilo = items > 3 ? SvUV(ST(3)) : 0;
 ihi = items > 4 ? SvUV(ST(4)) : (vlen*8/nbits);
 n   = klen*8/nbits;
 RETVAL = newSVpv("",0);
 SvGROW(RETVAL, n*4);		//-- always use 32-bit keys
 SvCUR_set(RETVAL, n*4);
 rv = SvPV_nolen(RETVAL);
 for (i=0; i<n; ++i) {
   ABSV_UINT key   = absv_vget(k,i,nbits);
   ABSV_UINT found = absv_bsearch_ub(v,key,ilo,ihi,nbits);
   absv_vset(rv,i,32,found);
 }
OUTPUT:
 RETVAL

##=====================================================================
## SET OPERATIONS

##--------------------------------------------------------------
SV*
vunion(SV *avec, SV *bvec, ABSV_UINT nbits)
PREINIT:
  const uchar *a, *b;
  uchar *c;
  STRLEN alen,blen;
  ABSV_UINT na,nb,nc, ai,bi,ci, aval,bval;
CODE:
 if (nbits < 8)
   croak("vunion(): cannot handle nbits < 8, but you requested " ABSV_PRI, nbits);
 a = SvPV(avec,alen);
 b = SvPV(bvec,blen);
 na = alen*8/nbits;
 nb = blen*8/nbits;
 nc = na + nb;
 RETVAL = newSVpv("",0);
 SvGROW(RETVAL, nc*nbits/8);
 c = SvPV_nolen(RETVAL);
 for (ai=0,bi=0,ci=0; ai < na && bi < nb; ++ci) {
   aval = absv_vget(a,ai,nbits);
   bval = absv_vget(b,bi,nbits);
   if (aval <= bval) {
     absv_vset(c,ci,nbits,aval);
     ++ai;
     if (aval == bval) ++bi;
   } else { //-- aval > bval
     absv_vset(c,ci,nbits,bval);
     ++bi;
   }
 }
 for (; ai < na; ++ai, ++ci)
   absv_vset(c,ci,nbits,absv_vget(a,ai,nbits));
 for (; bi < nb; ++bi, ++ci)
   absv_vset(c,ci,nbits,absv_vget(b,bi,nbits));
 SvCUR_set(RETVAL, ci*nbits/8);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
SV*
vintersect(SV *avec, SV *bvec, ABSV_UINT nbits)
PREINIT:
  const uchar *a, *b;
  uchar *c;
  STRLEN alen,blen;
  ABSV_UINT na,nb,nc, ai,blo,bi,ci, aval,bval;
CODE:
 if (nbits < 8)
   croak("vintersect(): cannot handle nbits < 8, but you requested " ABSV_PRI, nbits);
 a = SvPV(avec,alen);
 b = SvPV(bvec,blen);
 if (blen < alen) {
   //-- ensure smaller set is "a"
   const uchar *tmp = b;
   STRLEN tmplen = blen;
   b = a;
   a = tmp;
   blen = alen;
   alen = tmplen;
 }
 na = alen*8/nbits;
 nb = blen*8/nbits;
 nc = na;
 RETVAL = newSVpv("",0);
 SvGROW(RETVAL, nc*nbits/8);
 c = SvPV_nolen(RETVAL);
 for (ai=0,blo=0,ci=0; ai < na; ++ai) {
   aval = absv_vget(a,ai,nbits);
   bi   = absv_bsearch_ub(b,aval,blo,nb,nbits);
   if (bi   == KEY_NOT_FOUND) break;
   if (aval == absv_vget(b,bi,nbits)) {
     absv_vset(c,ci++,nbits,aval);
   }
   blo = bi;
 }
 SvCUR_set(RETVAL, ci*nbits/8);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
SV*
vsetdiff(SV *avec, SV *bvec, ABSV_UINT nbits)
PREINIT:
  const uchar *a, *b;
  uchar *c;
  STRLEN alen,blen;
  ABSV_UINT na,nb,nc, ai,blo,bi,ci, aval,bval;
CODE:
 if (nbits < 8)
   croak("vsetdiff(): cannot handle nbits < 8, but you requested " ABSV_PRI, nbits);
 a = SvPV(avec,alen);
 b = SvPV(bvec,blen);
 na = alen*8/nbits;
 nb = blen*8/nbits;
 nc = na;
 RETVAL = newSVpv("",0);
 SvGROW(RETVAL, nc*nbits/8);
 c = SvPV_nolen(RETVAL);
 for (ai=0,blo=0,ci=0; ai < na; ++ai) {
   aval = absv_vget(a,ai,nbits);
   bi   = absv_bsearch_ub(b,aval,blo,nb,nbits);
   if (bi   == KEY_NOT_FOUND) break;
   if (aval != absv_vget(b,bi,nbits)) {
     absv_vset(c,ci++,nbits,aval);
   }
   blo = bi;
 }
 for ( ; ai < na; ++ai)
   absv_vset(c,ci++,nbits,absv_vget(a,ai,nbits));
 SvCUR_set(RETVAL, ci*nbits/8);
OUTPUT:
 RETVAL
