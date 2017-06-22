#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "IBM390lib.h"
#define SHORTY_SIZE 2048

 /*---- Translation tables ----*/

static unsigned char a2e_table[256] = {
   0x00, 0x01, 0x02, 0x03, 0x37, 0x2d, 0x2e, 0x2f, 0x16, 0x05,
   0x15, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13,
   0x3c, 0x3d, 0x32, 0x26, 0x18, 0x19, 0x3f, 0x27, 0x1c, 0x1d,
   0x1e, 0x1f, 0x40, 0x5a, 0x7f, 0x7b, 0x5b, 0x6c, 0x50, 0x7d,
   0x4d, 0x5d, 0x5c, 0x4e, 0x6b, 0x60, 0x4b, 0x61, 0xf0, 0xf1,
   0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0x7a, 0x5e,
   0x4c, 0x7e, 0x6e, 0x6f, 0x7c, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5,
   0xc6, 0xc7, 0xc8, 0xc9, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6,
   0xd7, 0xd8, 0xd9, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8,
   0xe9, 0xad, 0xe0, 0xbd, 0x5f, 0x6d, 0x79, 0x81, 0x82, 0x83,
   0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x91, 0x92, 0x93, 0x94,
   0x95, 0x96, 0x97, 0x98, 0x99, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6,
   0xa7, 0xa8, 0xa9, 0xc0, 0x4f, 0xd0, 0xa1, 0x07, 0x20, 0x21,
   0x22, 0x23, 0x24, 0x25, 0x06, 0x17, 0x28, 0x29, 0x2a, 0x2b,
   0x2c, 0x09, 0x0a, 0x1b, 0x30, 0x31, 0x1a, 0x33, 0x34, 0x35,
   0x36, 0x08, 0x38, 0x39, 0x3a, 0x3b, 0x04, 0x14, 0x3e, 0xff,
   0x41, 0xaa, 0x4a, 0xb1, 0x9f, 0xb2, 0x6a, 0xb5, 0xbb, 0xb4,
   0x9a, 0x8a, 0xb0, 0xca, 0xaf, 0xbc, 0x90, 0x8f, 0xea, 0xfa,
   0xbe, 0xa0, 0xb6, 0xb3, 0x9d, 0xda, 0x9b, 0x8b, 0xb7, 0xb8,
   0xb9, 0xab, 0x64, 0x65, 0x62, 0x66, 0x63, 0x67, 0x9e, 0x68,
   0x74, 0x71, 0x72, 0x73, 0x78, 0x75, 0x76, 0x77, 0xac, 0x69,
   0xed, 0xee, 0xeb, 0xef, 0xec, 0xbf, 0x80, 0xfd, 0xfe, 0xfb,
   0xfc, 0xba, 0xae, 0x59, 0x44, 0x45, 0x42, 0x46, 0x43, 0x47,
   0x9c, 0x48, 0x54, 0x51, 0x52, 0x53, 0x58, 0x55, 0x56, 0x57,
   0x8c, 0x49, 0xcd, 0xce, 0xcb, 0xcf, 0xcc, 0xe1, 0x70, 0xdd,
   0xde, 0xdb, 0xdc, 0x8d, 0x8e, 0xdf  };

static unsigned char e2a_table[256] = {
   0x00, 0x01, 0x02, 0x03, 0x9c, 0x09, 0x86, 0x7f, 0x97, 0x8d,
   0x8e, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13,
   0x9d, 0x0a, 0x08, 0x87, 0x18, 0x19, 0x92, 0x8f, 0x1c, 0x1d,
   0x1e, 0x1f, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x17, 0x1b,
   0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x05, 0x06, 0x07, 0x90, 0x91,
   0x16, 0x93, 0x94, 0x95, 0x96, 0x04, 0x98, 0x99, 0x9a, 0x9b,
   0x14, 0x15, 0x9e, 0x1a, 0x20, 0xa0, 0xe2, 0xe4, 0xe0, 0xe1,
   0xe3, 0xe5, 0xe7, 0xf1, 0xa2, 0x2e, 0x3c, 0x28, 0x2b, 0x7c,
   0x26, 0xe9, 0xea, 0xeb, 0xe8, 0xed, 0xee, 0xef, 0xec, 0xdf,
   0x21, 0x24, 0x2a, 0x29, 0x3b, 0x5e, 0x2d, 0x2f, 0xc2, 0xc4,
   0xc0, 0xc1, 0xc3, 0xc5, 0xc7, 0xd1, 0xa6, 0x2c, 0x25, 0x5f,
   0x3e, 0x3f, 0xf8, 0xc9, 0xca, 0xcb, 0xc8, 0xcd, 0xce, 0xcf,
   0xcc, 0x60, 0x3a, 0x23, 0x40, 0x27, 0x3d, 0x22, 0xd8, 0x61,
   0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0xab, 0xbb,
   0xf0, 0xfd, 0xfe, 0xb1, 0xb0, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e,
   0x6f, 0x70, 0x71, 0x72, 0xaa, 0xba, 0xe6, 0xb8, 0xc6, 0xa4,
   0xb5, 0x7e, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a,
   0xa1, 0xbf, 0xd0, 0x5b, 0xde, 0xae, 0xac, 0xa3, 0xa5, 0xb7,
   0xa9, 0xa7, 0xb6, 0xbc, 0xbd, 0xbe, 0xdd, 0xa8, 0xaf, 0x5d,
   0xb4, 0xd7, 0x7b, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
   0x48, 0x49, 0xad, 0xf4, 0xf6, 0xf2, 0xf3, 0xf5, 0x7d, 0x4a,
   0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x52, 0xb9, 0xfb,
   0xfc, 0xf9, 0xfa, 0xff, 0x5c, 0xf7, 0x53, 0x54, 0x55, 0x56,
   0x57, 0x58, 0x59, 0x5a, 0xb2, 0xd4, 0xd6, 0xd2, 0xd3, 0xd5,
   0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
   0xb3, 0xdb, 0xdc, 0xd9, 0xda, 0x9f  };

static unsigned char e2ap_table[256] = {
  "                                                                "
  "           .<(+|&         !$*); -/         ,%_>?         `:#@'=\""
  " abcdefghi       jklmnopqr       ~stuvwxyz   [               ]  "
  "{ABCDEFGHI      }JKLMNOPQR      \\ STUVWXYZ      0123456789      "};

 /*---- End of tables ----*/

#ifdef OLD_INTERNAL
   #define UNDEF_PTR &sv_undef
#else
   #define UNDEF_PTR &PL_sv_undef
#endif

 /* 36KB may seem small, but on MVS most records are 32KB or less. */
#define OUTSTRING_MEM 36864
 /* Macro: catenate a string to the end of an existing string
  * and move the pointer up. */
#define memcat(target,offset,source,len) \
	memcpy((target+offset), source, len); \
	offset += len;

#ifndef min
#define min(x,y)            (((x) < (y)) ? (x) : (y))
#endif

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}


MODULE = Convert::IBM390		PACKAGE = Convert::IBM390


void
asc2eb(instring_sv)
	SV *  instring_sv
	PROTOTYPE: $
	PREINIT:
	STRLEN  ilength;
	char *  instring;
	char *  outstring_wk;
	 /* To avoid allocating small amounts of storage: */
	char    shorty[SHORTY_SIZE];

	PPCODE:
	instring = SvPV(instring_sv, ilength);
#ifdef DEBUG390
	fprintf(stderr, "*D* asc2eb: beginning; length %d\n", ilength);
#endif
	if (ilength <= SHORTY_SIZE) {
	   CF_fcs_xlate(shorty, instring, ilength, a2e_table);
	   PUSHs(sv_2mortal(newSVpvn(shorty, ilength)));
	} else {
	   New(0, outstring_wk, ilength, char);
	   CF_fcs_xlate(outstring_wk, instring, ilength, a2e_table);
	   PUSHs(sv_2mortal(newSVpvn(outstring_wk, ilength)));
	   Safefree(outstring_wk);
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* asc2eb: returning\n");
#endif

void
eb2asc(instring_sv)
	SV *  instring_sv
	PROTOTYPE: $
	PREINIT:
	STRLEN  ilength;
	char *  instring;
	char *  outstring_wk;
	 /* To avoid allocating small amounts of storage: */
	char    shorty[SHORTY_SIZE];

	PPCODE:
	instring = SvPV(instring_sv, ilength);
#ifdef DEBUG390
	fprintf(stderr, "*D* eb2asc: beginning; length %d\n", ilength);
#endif
	if (ilength <= SHORTY_SIZE) {
	   CF_fcs_xlate(shorty, instring, ilength, e2a_table);
	   PUSHs(sv_2mortal(newSVpvn(shorty, ilength)));
	} else {
	   New(0, outstring_wk, ilength, char);
	   CF_fcs_xlate(outstring_wk, instring, ilength, e2a_table);
	   PUSHs(sv_2mortal(newSVpvn(outstring_wk, ilength)));
	   Safefree(outstring_wk);
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* eb2asc: returning\n");
#endif

void
eb2ascp(instring_sv)
	SV *  instring_sv
	PROTOTYPE: $
	PREINIT:
	STRLEN  ilength;
	char *  instring;
	char *  outstring_wk;
	 /* To avoid allocating small amounts of storage: */
	char    shorty[SHORTY_SIZE];

	PPCODE:
	instring = SvPV(instring_sv, ilength);
#ifdef DEBUG390
	fprintf(stderr, "*D* eb2ascp: beginning; length %d\n", ilength);
#endif
	if (ilength <= SHORTY_SIZE) {
	   CF_fcs_xlate(shorty, instring, ilength, e2ap_table);
	   PUSHs(sv_2mortal(newSVpvn(shorty, ilength)));
	} else {
	   New(0, outstring_wk, ilength, char);
	   CF_fcs_xlate(outstring_wk, instring, ilength, e2ap_table);
	   PUSHs(sv_2mortal(newSVpvn(outstring_wk, ilength)));
	   Safefree(outstring_wk);
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* eb2ascp: returning\n");
#endif


 # // Much of the following code is shamelessly stolen from Perl's
 # // built-in pack and unpack functions (pp.c).
 # // packeb -- Pack a list of values into an EBCDIC record
void
packeb(pat, ...)
	char *  pat
	PREINIT:
	char    outstring[OUTSTRING_MEM];

	SV *   item;
	STRLEN item_len;
	int    ii;  /* ii = item index */
	int    oi;  /* oi = outstring index */
	char   datumtype;
	register char * patend;
	register int len;
	int    j, ndec, num_ok;

	static char   null10[] = {0,0,0,0,0,0,0,0,0,0};
	 /* space10 = native spaces.  espace10 = EBCDIC spaces. */
	static char  space10[] = "          ";
	static char espace10[] =
	 { 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40 };

	I32 along;
	char *aptr;
	double adouble;
	/* The eb_work area is long, but what the heck?  Memory is cheap. */
	char eb_work[32800];

	PPCODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* packeb: beginning\n");
#endif
	ii = 1;
	oi = 0;
	patend = pat + strlen(pat);

	while (pat < patend) {
	/* Have we gone past the end of the list of values?  If so, stop. */
	   if (ii >= items)
	      break;
	   if (oi >= OUTSTRING_MEM)
	      croak("Output structure too large in packeb");

	   datumtype = *pat++;
	   if (isSPACE(datumtype))
	      continue;
	   if (*pat == '*') {
	      len = strchr("pz", datumtype) ? 8 :
	        (strchr("@x", datumtype) ? 0 : items - ii + 1);
	      pat++;
	   } else if (isDIGIT(*pat)) {
	       len = *pat++ - '0';
	       while (isDIGIT(*pat))
	          len = (len * 10) + (*pat++ - '0');
	       /* Decimal places (this result will be ignored if the
	          datumtype is not packed or zoned). */
	       ndec = 0;
	       if (*pat == '.') {
	          pat++;
	          while (isDIGIT(*pat))
	             ndec = (ndec * 10) + (*pat++ - '0');
	       }
	   } else {
	      len = strchr("pz", datumtype) ? 8 : 1;
	   }

	   if (len > 32767) {
	      croak("Field length too large in packeb: %c%d",
	         datumtype, len);
	   }
#ifdef DEBUG390
	   fprintf(stderr, "*D* packeb: datumtype/len %c%d\n",
	     datumtype, len);
#endif

	   switch(datumtype) {
	     case '@':
	         if (len > OUTSTRING_MEM || len < 0)
	            croak("@ position outside string");
	         oi = len;
	         break;
	     case 'x':
	         while (len >= 10) {
	            memcat(outstring, oi, null10, 10);
	            len -= 10;
	         }
	         memcat(outstring, oi, null10, len);
	         break;

	     /* [Ee]:  EBCDIC character string */
	     case 'E':
	     case 'e':
	         item = ST(ii);
	         ii++;
	         aptr = SvPV(item, item_len);
	         if (pat[-1] == '*') {
	             len = item_len;
	         if (len > sizeof(eb_work))
	             croak("String too long in packeb: %c*", datumtype);
	         }
	         CF_fcs_xlate(eb_work, aptr, min(len, item_len), a2e_table);

	         if (item_len > len) {
	             memcat(outstring, oi, eb_work, len);
	         } else {
	             memcat(outstring, oi, eb_work, item_len);
	             len -= item_len;
	             if (datumtype == 'E') {
	                 while (len >= 10) {
	                     memcat(outstring, oi, espace10, 10);
	                     len -= 10;
	                 }
	                 memcat(outstring, oi, espace10, len);
	             }
	             else {
	                 while (len >= 10) {
	                     memcat(outstring, oi, null10, 10);
	                     len -= 10;
	                 }
	                 memcat(outstring, oi, null10, len);
	             }
	         }
	         break;

	     /* [Cc]: characters without translation.  If space padding
	        is requested, we pad with native spaces, not x'40'. */
	     case 'C':
	     case 'c':
	         item = ST(ii);
	         ii++;
	         aptr = SvPV(item, item_len);
	         if (pat[-1] == '*')
	             len = item_len;
	         if (item_len > len) {
	             memcat(outstring, oi, aptr, len);
	         } else {
	             memcat(outstring, oi, aptr, item_len);
	             len -= item_len;
	             if (datumtype == 'C') {
	                 while (len >= 10) {
	                     memcat(outstring, oi, space10, 10);
	                     len -= 10;
	                 }
	                 memcat(outstring, oi, space10, len);
	             }
	             else {
	                 while (len >= 10) {
	                     memcat(outstring, oi, null10, 10);
	                     len -= 10;
	                 }
	                 memcat(outstring, oi, null10, len);
	             }
	         }
	         break;

	     /* [pP]: S/390 packed decimal.  In this case, the length
	        given in the template is the length of a single field,
	        not a number of repetitions. */
	     case 'p':
	     case 'P':
	         if (len > 16) {
	            croak("Field length too large in packeb: %c%d", datumtype, len);
	         }
	         item = ST(ii);
	         ii++;
	         adouble = SvNV(item);

	         num_ok = CF_num2packed(eb_work, adouble, len, ndec,
	           datumtype=='P');
	         if (! num_ok) {
	            croak("Number %g too long for packed decimal", adouble);
	         }
	         item = ST(ii);
	         memcat(outstring, oi, eb_work, len);
	         break;

	     /* i: S/390 fullword (signed). */
	     case 'i':
	         for (j = 0; j < len; j++) {
	            item = ST(ii);
	            ii++;
	            along = SvIV(item);
	            _to_S390fw(eb_work, along);
	            memcat(outstring, oi, eb_work, 4);
	         }
	         break;

	     /* [sS]: S/390 halfword (signed/unsigned). */
	     case 's':
	     case 'S':
	         for (j = 0; j < len; j++) {
	            item = ST(ii);
	            ii++;
	            along = SvIV(item);
	            if (datumtype == 's') {
	               _to_S390hw(eb_work, along);
	               memcat(outstring, oi, eb_work, 2);
	            } else {
	               _to_S390fw(eb_work, along);
	               memcat(outstring, oi, eb_work+2, 2);
	            }
	         }
	         break;

	     /* [zZ]: S/390 zoned decimal.  In this case, the length given
	        in the template is the length of a single field, not a
	        number of repetitions. */
	     case 'z':
	     case 'Z':
	         if (len > 32) {
	            croak("Field length too large in packeb: z%d", len);
	         }
	         item = ST(ii);
	         ii++;
	         adouble = SvNV(item);

	         num_ok = CF_num2zoned(eb_work, adouble, len, ndec, datumtype=='Z');
	         if (! num_ok) {
	            croak("Number %g too long for zoned decimal", adouble);
	         }
	         memcat(outstring, oi, eb_work, len);
	         break;

	     case 'H':
	     case 'h':
	         {
	             char *hexstring;
	             I32 workbyte, xi; /* xi = index into hexstring */
	             unsigned char hexbyte, final_byte;

	             item = ST(ii);
	             ii++;
	             hexstring = SvPV(item, item_len);
	             if (pat[-1] == '*')
	                 len = item_len;
	             if (len < 2)
	                 len = 2;
	             if (len > item_len)
	                 len = item_len;
	             workbyte = 0;
	             for (xi = 0; xi < len; xi++) {
	                 hexbyte = (unsigned char) hexstring[xi];
	                 if (isALPHA(hexbyte))
	                     workbyte |= ((hexbyte & 15) + 9) & 15;
	                 else
	                     workbyte |= hexbyte & 15;
	                 if (! (xi & 1))
	                     workbyte <<= 4;
	                 else {
	                     final_byte = workbyte & 0xFF;
	                     memcat(outstring, oi, &final_byte, 1);
	                     workbyte = 0;
	                 }
	             }
	             if (xi & 1) {
	                 final_byte = workbyte & 0xFF;
	                 memcat(outstring, oi, &final_byte, 1);
	             }
	         }
	         break;

	     default:
	        croak("Invalid type in packeb: '%c'", datumtype);
	   }
	}

	PUSHs(sv_2mortal(newSVpvn(outstring, oi)));
#ifdef DEBUG390
	fprintf(stderr, "*D* packeb: returning\n");
#endif


 # unpackeb -- Unpack an EBCDIC record into a list
 # Note that the EBCDIC data may contain nulls and other unprintable
 # stuff, so we need an SV*, not just a char*.
void
unpackeb(pat, ebrecord)
	char *  pat
	SV *    ebrecord
	PROTOTYPE: $$
	PREINIT:
	SV *sv;
	STRLEN rlen;

	register char *s;
	char *sbegin;
	char *tail;
	char *strend;
	register char *patend;
	char datumtype;
	register I32 len, outlen;
	register I32 bits = 0;
	int i, j, ndec, fieldlen;
	char hexdigit[16] = "0123456789abcdef";

	/* Work fields */
	I32 along;
	unsigned long aulong;
	/* Some day we may want to support S/390 floats.... */
	/*float afloat;*/
	double adouble;
	/* The eb_work area is long, but what the heck?  Memory is cheap. */
	char eb_work[32800];

	PPCODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* unpackeb: beginning\n");
#endif
	s = sbegin = SvPV(ebrecord, rlen);
	strend = s + rlen;
	patend = pat + strlen(pat);

	while (pat < patend) {
	   datumtype = *pat++;
	   if (isSPACE(datumtype))
	       continue;
	   ndec = 0;
	   if (pat >= patend) {
	       len = 1;
	   }
	   else if (*pat == '*') {
	       len = strend - s;
	       if (datumtype == 'i' || datumtype == 'I')  len = len / 4;
	       if (datumtype == 's' || datumtype == 'S')  len = len / 2;
	       pat++;
	   }
	   else if (isDIGIT(*pat)) {
	       len = *pat++ - '0';
	       while (isDIGIT(*pat))
	          len = (len * 10) + (*pat++ - '0');
	       /* Decimal places (this result will be ignored if the
	          datumtype is not packed or zoned). */
	       ndec = 0;
	       if (*pat == '.') {
	          pat++;
	          while (isDIGIT(*pat))
	             ndec = (ndec * 10) + (*pat++ - '0');
	       }
	   }
	   else {
	       len = 1;
	   }
	   if (len > 32767) {
	      croak("Field length too large in unpackeb: %c%d",
	         datumtype, len);
	   }
#ifdef DEBUG390
	   fprintf(stderr, "*D* unpackeb: datumtype/len %c%d\n",
	     datumtype, len);
#endif
	   switch(datumtype) {
	   /* @: absolute offset  */
	   case '@':
	       if (len >= rlen || len < 0)
	          croak("Absolute offset is outside string: @%d", len);
	       s = sbegin + len;
	       break;

	   /* [eE]: EBCDIC character string.  In this case, the length
	      given in the template is the length of a single field, not
	      a number of repetitions. */
	   case 'e':
	   case 'E':
	       if (len > strend - s)
	          len = strend - s;
	       CF_fcs_xlate(eb_work, s, len, e2a_table);
	       outlen = len;
	       if (len < 1)
	          eb_work[0] = 0x00;  /* Force an empty string. */
	       if (datumtype == 'E') {  /* Strip nulls and spaces */
	          tail = eb_work + len - 1;
	          while (tail >= eb_work && (*tail==' ' || *tail=='\0'))
	              tail--;
	          outlen = tail - eb_work + 1;
	       }

	       XPUSHs(sv_2mortal(newSVpvn(eb_work, outlen)));
	       s += len;
	       break;

	   /* p: S/390 packed decimal.  In this case, the length given
	      in the template is the length of a single field, not a
	      number of repetitions. */
	   case 'p':
	       if (len > strend - s)
	          len = strend - s;
	       if (len > 16) {
	          croak("Field length too large in unpackeb: p%d", len);
	       }
	       adouble = CF_packed2num(s, len, ndec);
	       if ( adouble == INVALID_390NUM ) {
	          sv = UNDEF_PTR;
	       } else {
	          sv = newSVnv(adouble);
	       }

	       XPUSHs(sv_2mortal(sv));
	       s += len;
	       break;

	   /* z: S/390 zoned decimal.  In this case, the length given
	      in the template is the length of a single field, not a
	      number of repetitions. */
	   case 'z':
	       if (len > strend - s)
	          len = strend - s;
	       if (len > 32) {
	          croak("Field length too large in unpackeb: z%d", len);
	       }
	       adouble = CF_zoned2num(s, len, ndec);
	       if ( adouble == INVALID_390NUM ) {
	          sv = UNDEF_PTR;
	       } else {
	          sv = newSVnv(adouble);
	       }

	       XPUSHs(sv_2mortal(sv));
	       s += len;
	       break;

	   /* [Cc]: characters without translation */
	   case 'C':
	   case 'c':
	       if (len > strend - s)
	          len = strend - s;
	       XPUSHs(sv_2mortal(newSVpvn(s, len)));
	       s += len;
	       break;

	   /* i: integer (System/390 fullword) */
	   case 'i':
	       if (len > (strend - s) / 4)
	          len = (strend - s) / 4;
	       for (i=0; i < len; i++) {
	          along = 0;
	          along = (signed char) *s;  s++;
	          for (j=1; j < 4; j++) {
	             along <<= 8;
	             along += (unsigned char) *s;  s++;
	          }

	          XPUSHs(sv_2mortal(newSViv(along)));
	       }
	       break;

	   /* s: short integer (System/390 halfword) */
	   case 's':
	       if (len > (strend - s) / 2)
	          len = (strend - s) / 2;
	       for (i=0; i < len; i++) {
	          along = _halfword(s);

	          XPUSHs(sv_2mortal(newSViv(along)));
	          s += 2;
	       }
	       break;

	   /* [hH]: unpack to printable hex digits.  The length given
	      in the template is the length of a single field, not
	      a number of repetitions. */
	   case 'h':
	   case 'H':
	       if (len > (strend - s) * 2)
	          len = (strend - s) * 2;
	       if (len < 1)
	          eb_work[0] = 0x00;  /* Force an empty string. */
	       i = 0;
	       along = len;
	       for (len = 0; len < along; len++) {
	           if (len & 1)
	               bits <<= 4;
	           else
	               bits = *s++;
	           eb_work[i++] = hexdigit[(bits >> 4) & 15];
	       }
	       eb_work[i] = '\0';
	       XPUSHs(sv_2mortal(newSVpvn(eb_work, len)));
	       break;

	   /* v: varchar EBCDIC character string; i.e., a string of
	      EBCDIC characters preceded by a halfword length field (as
	      in DB2/MVS, for instance).  'len' here is a repeat count,
	      but don't go beyond the end of the record. */
	   case 'v':
	       for (i=0; i < len; i++) {
	           if (s >= strend)
	              break;
	           fieldlen = _halfword(s);
	           s += 2;

	           if (fieldlen > strend - s)
	              fieldlen = strend - s;
	           if (fieldlen > 0) {
	              CF_fcs_xlate(eb_work, s, fieldlen, e2a_table);
	              sv = newSVpvn(eb_work, fieldlen);
	           } else if (fieldlen == 0) {
	              sv = newSVpvn("", 0);
	           } else {
	              sv = UNDEF_PTR;
	           }
	           XPUSHs(sv_2mortal(sv));
	           s += fieldlen;
	       }
	       break;

	   /* V: varchar string with a halfword length but a fixed field
 	      size. 'len' here is the length of the field exclusive of the
	      leading halfword. */
	   case 'V':
	       if (len > strend - s)
	          len = strend - s;
	       fieldlen = _halfword(s);
	       s += 2;

	       if (fieldlen > strend - s)
	          fieldlen = strend - s;
	       if (fieldlen > 0) {
	          CF_fcs_xlate(eb_work, s, fieldlen, e2a_table);
	          sv = newSVpvn(eb_work, fieldlen);
	       } else if (fieldlen == 0) {
	          sv = newSVpvn("", 0);
	       } else {
	          sv = UNDEF_PTR;
	       }
	       XPUSHs(sv_2mortal(sv));
	       s += len;
	       break;

	   /* x: ignore these bytes (do not return an element) */
	   case 'x':
	       if (len > strend - s)
	          len = strend - s;
	       s += len;
	       break;

	   /* I: unsigned integer (fullword) */
	   /* On most systems, integer = long = 32 bits, signed.
	      Therefore, to be safe, we compute this as an unsigned long
	      and then cast it to a double. */
	   case 'I':
	       if (len > (strend - s) / 4)
	          len = (strend - s) / 4;
	       if (sizeof(unsigned long) < 4) {
	          warn("Unsigned integer results may be invalid");
	       }
	       for (i=0; i < len; i++) {
	          aulong = 0;
	          for (j=0; j < 4; j++) {
	             aulong <<= 8;
	             aulong += (unsigned char) *s;  s++;
	          }

	          XPUSHs(sv_2mortal(newSVnv((double) aulong)));
	       }
	       break;

	   /* S: unsigned short integer (halfword) */
	   case 'S':
	       if (len > (strend - s) / 2)
	          len = (strend - s) / 2;
	       for (i=0; i < len; i++) {
	          along = 0;
	          along = ((unsigned char) *s) << 8;  s++;
	          along += (unsigned char) *s;  s++;

	          XPUSHs(sv_2mortal(newSViv(along)));
	       }
	       break;

	   default:
	       croak("Invalid type in unpackeb: '%c'", datumtype);
	   }
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* unpackeb: returning\n");
#endif

void
_set_translation(a2e_sv, e2a_sv, e2ap_sv)
	SV *  a2e_sv
	SV *  e2a_sv
	SV *  e2ap_sv
    PROTOTYPE: DISABLE
	PREINIT:
	STRLEN  ilength;
	char *  a2e_string;
	char *  e2a_string;
	char *  e2ap_string;

	CODE:
	a2e_string = SvPVbyte(a2e_sv, ilength);
	if (ilength != 256) {
	      croak("a2e table must be 256 bytes, not %d", ilength);
	}

	e2a_string = SvPVbyte(e2a_sv, ilength);
	if (ilength != 256) {
	      croak("e2a table must be 256 bytes, not %d", ilength);
	}

	e2ap_string = SvPVbyte(e2ap_sv, ilength);
	if (ilength != 256) {
	      croak("e2ap table must be 256 bytes, not %d", ilength);
	}

    memcpy(a2e_table, a2e_string, 256);
    memcpy(e2a_table, e2a_string, 256);
    memcpy(e2ap_table, e2ap_string, 256);
