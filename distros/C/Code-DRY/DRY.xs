#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <stdlib.h>
#include "salcpis.h"

/* coupling functions to sais-lite-lcp-master
 *
 * TODO:
 * support error reporting through the $! variable
 * support accessor functions in the arrays
 * */

#ifndef min
#define min(a,b) ((a) < (b) ? (a) : (b))
#endif
//#define DEBUG_SET_NOOVERLAPS
//#define DEBUG_FILECLIP
//#define DEBUG_SHADOWS


unsigned int *SA = 0;
unsigned int *ISA = 0;
unsigned int *LCP= 0;
//unsigned int *RANKS= 0;
//unsigned int *LAST_RANK= 0;
//unsigned int *RANKP= 0;
size_t n= 0;

/*AV *
get_ranks()
PREINIT:
  const unsigned int *lcp = LCP+1;
INIT:
  unsigned int *RANKS;
  AV * arr; 
  unsigned c;
CODE:
  // alloc 
  arr = newAV();
  RANKS = 0;//(unsigned int *)malloc((size_t) n * sizeof(int));
  if (!RANKS) {
    goto MYOUTPUT;
  }
  // copy
  //memcpy();
  // sort
  //qsort();
  // copy
  for (c=0; c < n; ++c)
  {
    av_store(arr, c, newSVuv(RANKS[c]));
  }
  // free
  free(RANKS);
MYOUTPUT:
  RETVAL = arr;
OUTPUT:
  RETVAL*/

/*
unsigned int
get_next_ranked_index()
PREINIT:
INIT:
CODE:
  if (RANKP < LAST_RANK) {
    RETVAL = *RANKP++;
  } else {
    RETVAL = ~0U;
  }
OUTPUT:
  RETVAL



void
reset_rank_iterator()
PREINIT:
INIT:
CODE:
  RANKP = RANKS;
*/


MODULE = Code::DRY        PACKAGE = Code::DRY
PROTOTYPES: ENABLE

int
build_suffixarray_and_lcp(in)
    SV * in
INIT:
    size_t size;
    unsigned char * T;
    unsigned int *sa;
    unsigned int *isa;
    unsigned int i;
CODE:
  if (!SA) {
    free(SA);
  }
  if (!LCP) {
    free(LCP);
  }
  if (!ISA) {
    free(ISA);
  }

  size = sv_len(in);
  T = SvPV_nolen(in);
  if(T == NULL) {
    RETVAL = -1;
    goto MYOUTPUT;
  }

  //printf("len %u, >%s<\n",size, T);

  SA  = (unsigned int *)malloc((size_t)(size+1) * sizeof(int)); // +1 for computing LCP
  LCP = (unsigned int *)malloc((size_t) size    * sizeof(int));
  ISA = (unsigned int *)malloc((size_t)(size  ) * sizeof(int));
  if((SA == NULL) || (LCP == NULL) || (ISA == NULL)) {
    RETVAL = -2;
    if (SA) {
      free(SA);
      SA = 0;
    }
    if (LCP) {
      free(LCP);
      LCP = 0;
    }
    if (ISA) {
      free(ISA);
      ISA = 0;
    }
    goto MYOUTPUT;
  }

  n = size;

  if (sais(T, (int *)SA, (int *)LCP, (int)n) != 0) {
    free(SA);
    free(LCP);
    free(ISA);
    SA = LCP = ISA = 0;
    n = 0;

    RETVAL = -3;
    goto MYOUTPUT;
  }
  // generate the inverse suffix array
  sa = SA;
  isa = ISA;
  for (i = 0; i < n; ++i) {
    isa[*sa++] = i;
  }
  LCP[0] = 0;
  RETVAL = 0;
MYOUTPUT:
OUTPUT:
  RETVAL


void 
reduce_lcp_to_nonoverlapping_lengths()
PREINIT:
        unsigned int *lcp = LCP+n-1;
  const unsigned int *sa  = SA +n-1;
INIT:
        unsigned c;
CODE:
  if (n < 2) {
    return;
  }
  for (c = n-1; c; --c) {
    if (*lcp > abs(*(sa-1) - *sa)) {
#ifdef DEBUG_SET_NOOVERLAPS
fprintf(stderr, "at %u: offset (%u) + lcp(%u) -1 >= prevSA(%u) -> set lcp from %u to %u\n", c, *sa, *lcp, *(sa -1), *lcp, abs(*(sa-1) - *sa));
#endif
      *lcp = abs(*(sa-1) - *sa);
    }
    --sa;
    --lcp;
  }


void
clip_lcp_to_fileboundaries(boundaries)
    AV * boundaries;
PREINIT:
        unsigned int *lcp = LCP+1;
  const unsigned int *sa  = SA +1;
INIT:
        int c;
        unsigned lastb;
        unsigned file_limit;
        unsigned lastFilelimit;
CODE:
  {
    const unsigned maxbound = av_len(boundaries);
    if (maxbound < 1) {
#ifdef DEBUG_FILECLIP
fprintf(stderr, "no file limits (%u), abort\n", maxbound);
#endif
      return;
    }
    if (n < 2) {
#ifdef DEBUG_FILECLIP
fprintf(stderr, "size < 2 (%u), abort\n", n);
#endif
      return;
    }

    /* return if offsets are not sorted or contain 'holes' empty slots */
    if (!av_exists(boundaries, maxbound)) {
#ifdef DEBUG_FILECLIP
fprintf(stderr, "last file boundary at (%u) is empty slot, abort\n", maxbound);
#endif
      return;
    }
    lastb = SvIV(*av_fetch(boundaries, maxbound, 0));
    for (c = maxbound-1; c >= 0; --c) {
      unsigned thisb;
      if (!av_exists(boundaries, c)) {
#ifdef DEBUG_FILECLIP
fprintf(stderr, "file boundary at (%u) is empty slot, abort\n", c);
#endif
        return;
      }
      thisb = SvIV(*av_fetch(boundaries, c, 0));
     
      if (thisb >= lastb) {
#ifdef DEBUG_FILECLIP
fprintf(stderr, "file boundary at (%u) is not greater (%u) than previous one: (%u), abort\n", c, thisb, lastb);
#endif
        return;
      }
      lastb = thisb;
    }

    /* now make sure that (*sa + *lcp - 1) does not extend past their file boundary */
    lastFilelimit = ~0;
    for (c = 1; c < n; ++c) {

      const unsigned int offset = *sa;
      unsigned left  = 0;
      unsigned right = maxbound;
      unsigned minlcp;

      if (0 == right) {
        file_limit = 0;
      } else {

        unsigned test = (left + right) / 2;

        file_limit = 0;
        while (left < right) {
          unsigned this_fileend;
          unsigned previous_fileend;
          if (((test > 0 && (previous_fileend = SvIV(*av_fetch(boundaries, test-1, 0))) < offset) || test == 0)
              && offset <= (this_fileend = SvIV(*av_fetch(boundaries, test, 0)))) {
            file_limit = this_fileend;
            break;
          }

          if (test > 0 && previous_fileend >= offset) {
            right = test;
            test  = (left + right    ) / 2;
          } else {
            left  = test;
            test  = (left + right + 1) / 2;
          }
        }
      }

      /* if previous entry is shorter than current lcp -> adjust */
      /* if current entry is shorter than current lcp -> adjust */
      minlcp = min(*lcp, 1+ min(lastFilelimit - *(sa -1), file_limit - *(sa)));
      if (*lcp > minlcp) {
#ifdef DEBUG_FILECLIP
fprintf(stderr, "at %u: offset (%u) + lcp(%u) -1 >= file limit(%u)  or  offset(%u) + lcp(%u) - 1 >= file limit(%u)  -> set lcp from %u to %u\n", 
        c, *(sa - 1), *lcp, lastFilelimit, *sa, *lcp, file_limit, *lcp, minlcp);
#endif
        *lcp = minlcp;
      }
      lastFilelimit = file_limit;
      ++sa;
      ++lcp;
    }
  }



void
set_lcp_to_zero_for_shadowed_substrings()
INIT:
   unsigned int *isa;
   unsigned int c;
   unsigned int entry;
   unsigned int lcp;
   unsigned int offset;
   unsigned int offset2;
   unsigned int offsetprev2;
   unsigned int last_lcp;
CODE:
   isa = ISA;
   last_lcp = ~0;
   for (c = 0; c < n; ++c, last_lcp = lcp) {
      entry  = *isa++;
      lcp    = LCP[entry];
      if (entry > 0 && c > 0 && last_lcp >= lcp) {
         offset  = SA[entry  ];
         offset2 = SA[entry-1];
         offsetprev2 = ISA[c-1];
         if (0 == offsetprev2) {
#ifdef DEBUG_SHADOWS
fprintf(stderr, "at %u: first suffix, cannot go back", c);
#endif
            continue;
         }
         offsetprev2 = SA[offsetprev2-1] + 1;
         if (offsetprev2 == offset2) {
#ifdef DEBUG_SHADOWS
fprintf(stderr, "  at %u: offset (%u) set lcp from %u to 0\n", ISA[offset], offset, LCP[ISA[offset]]);
#endif
            LCP[ISA[offset]] = 0;
         }
      }
   }





AV *
get_sa()
INIT:
  AV * arr; 
  unsigned c;
CODE:
  arr = newAV();
  for (c=0; c < n; ++c)
  {
    av_store(arr, c, newSVuv(SA[c]));
  } 
  RETVAL = arr;
OUTPUT:
  RETVAL



AV *
get_lcp()
INIT:
  AV * arr; 
  unsigned c;
CODE:
  arr = newAV();
  for (c=0; c < n; ++c)
  {
    av_store(arr, c, newSVuv(LCP[c]));
  } 
  RETVAL = arr;
OUTPUT:
  RETVAL

unsigned int
get_offset_at(index)
   unsigned index;
INIT:
CODE:
  if (!n || index >= n) {
    RETVAL = ~0U;
  } else {
    RETVAL = SA[index];
  }
OUTPUT:
  RETVAL

unsigned int
get_isa_at(index)
   unsigned index;
INIT:
CODE:
  if (!n || index >= n) {
    RETVAL = ~0U;
  } else {
    RETVAL = ISA[index];
  }
OUTPUT:
  RETVAL

unsigned int
get_len_at(index)
   unsigned int index;
INIT:
CODE:
  if (!n || index >= n) {
    RETVAL = ~0U;
  } else {
    RETVAL = LCP[index];
  }
OUTPUT:
  RETVAL

int 
get_size()
CODE:
  RETVAL = n;
OUTPUT:
  RETVAL

void
__free_all()
CODE:
  free(SA);
  free(LCP);
  free(ISA);
  n = 0;

