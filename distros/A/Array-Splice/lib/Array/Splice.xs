#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


MODULE = Array::Splice		PACKAGE = Array::Splice		

void
_splice(array,offset,length,...)
   SV* array;
   I32 offset;
   I32 length;
INIT:
    AV* ary;
    I32 i;
    I32 newlen;
    I32 after;
    I32 diff;
    SV **tmparyval = 0;
    MAGIC *mg;
    register SV **src;
    register SV **dst;
PPCODE:
   if ( !SvROK(array) || SvTYPE(SvRV(array)) != SVt_PVAV ) {
	croak("first argument to Array::Splice::_splice() not an array");
   }
   ary = (AV*) SvRV(array);

   if ((mg = SvTIED_mg((SV*)ary, 'P'))) {
	croak("Array::Splice::_splice() not implemented for tied arrays");
   }

   i = offset;
   if (offset < 0)
      offset += AvFILLp(ary) + 1;
   if (offset < 0)
      croak(PL_no_aelem, i);
   if (length < 0) {
      length += AvFILLp(ary) - offset + 1;
	if (length < 0)
          length = 0;
   }
   if (offset > AvFILLp(ary) + 1) {
      if (ckWARN(WARN_MISC))
	 warn("Array::Splice::_splice() offset past end of array" );
      offset = AvFILLp(ary) + 1;
    }
    after = AvFILLp(ary) + 1 - (offset + length);

    if (after < 0) {				/* not that much array */
	length += after;			/* offset+length now in array */
	after = 0;
	if (!AvALLOC(ary))
	    av_extend(ary, 0);
    }

    newlen = items - 3;
    diff = newlen - length;

    /* inc refcounts now: avoid problems if they're from the array */
    for (src = &ST(3), i = newlen; i; i--) {
      SvREFCNT_inc(*src++);
    }	 

    if (diff < 0) {				/* shrinking the area */
	if (newlen) {
	    New(451, tmparyval, newlen, SV*);	/* so remember insertion */
	    Copy(&ST(3), tmparyval, newlen, SV*);
	}

	if (GIMME == G_ARRAY) {			/* copy return vals to stack */
	    MEXTEND(SP, length);
   	    src = AvARRAY(ary)+offset;
            i = length;
	    if (AvREAL(ary)) {
		for ( ; i; i--) {
		    PUSHs(sv_2mortal(*src++));	/* free them eventualy */
		}
	    } else {
		for ( ; i; i--) {
		    PUSHs(*src++);	/* don't free them eventualy */
		}
	    }
	}
	else {
	    PUSHs(sv_2mortal(AvARRAY(ary)[offset+length-1]));
	    if (AvREAL(ary)) {
		for (i = length - 1, dst = &AvARRAY(ary)[offset]; i > 0; i--)
		    SvREFCNT_dec(*dst++);	/* free them now */
	    }
	}

	AvFILLp(ary) += diff;

	/* pull up or down? */

	if (offset < after) {			/* easier to pull up */
	    if (offset) {			/* esp. if nothing to pull */
		src = &AvARRAY(ary)[offset-1];
		dst = src - diff;		/* diff is negative */
		for (i = offset; i > 0; i--)	/* can't trust Copy */
		    *dst-- = *src--;
	    }
	    dst = AvARRAY(ary);
	    SvPVX(ary) = (char*)(AvARRAY(ary) - diff); /* diff is negative */
	    AvMAX(ary) += diff;
	}
	else {
	    if (after) {			/* anything to pull down? */
		src = AvARRAY(ary) + offset + length;
		dst = src + diff;		/* diff is negative */
		Move(src, dst, after, SV*);
	    }
	    dst = &AvARRAY(ary)[AvFILLp(ary)+1];
						/* avoid later double free */
	}
	i = -diff;
	while (i)
	    dst[--i] = &PL_sv_undef;
	
	if (newlen) {
	    for (src = tmparyval, dst = AvARRAY(ary) + offset;
	      newlen; newlen--) {
		*dst++ = *src++;
	    }
	    Safefree(tmparyval);
	}
    }

    else {					/* no, expanding (or same) */
	if (length) {
	    New(452, tmparyval, length, SV*);	/* so remember deletion */
	    Copy(AvARRAY(ary)+offset, tmparyval, length, SV*);
	}

	if (diff > 0) {				/* expanding */

	    /* push up or down? */

	    if (offset < after && diff <= AvARRAY(ary) - AvALLOC(ary)) {
		if (offset) {
		    src = AvARRAY(ary);
		    dst = src - diff;
		    Move(src, dst, offset, SV*);
		}
		SvPVX(ary) = (char*)(AvARRAY(ary) - diff);/* diff is positive */
		AvMAX(ary) += diff;
		AvFILLp(ary) += diff;
	    }
	    else {
		if (AvFILLp(ary) + diff >= AvMAX(ary))	/* oh, well */
		    av_extend(ary, AvFILLp(ary) + diff);
		AvFILLp(ary) += diff;

		if (after) {
		    dst = AvARRAY(ary) + AvFILLp(ary);
		    src = dst - diff;
		    for (i = after; i; i--) {
			*dst-- = *src--;
		    }
		}
	    }
	}

	for (src = &ST(3), dst = AvARRAY(ary) + offset; newlen; newlen--) {
	    *dst++ = *src++;
	}
	if (GIMME == G_ARRAY) {			/* copy return vals to stack */
	    if (length) {
		src = tmparyval;
		if (AvREAL(ary)) {
		    for (i = length; i; i--) {
			PUSHs(sv_2mortal(*src++));	/* free them eventualy */
		    }
		} else {
		    for (i = length; i; i--) {
			PUSHs(*src++);	/* don't free them eventualy */
		    }
                }
		Safefree(tmparyval);
	    }
	}
	else if (length--) {
	    PUSHs(sv_2mortal(tmparyval[length]));
	    if (AvREAL(ary)) {
		while (length-- > 0)
		    SvREFCNT_dec(tmparyval[length]);
	    }
	    Safefree(tmparyval);
	}
    }

