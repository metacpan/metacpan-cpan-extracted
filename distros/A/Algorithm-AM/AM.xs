#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define NUM_LATTICES 4

/*
 * This program must deal with integers that are too big to be
 * represented by 32 bits.
 *
 * They are represented by AM_BIG_INT, which is typedef'd to
 *
 * unsigned long a[8]
 *
 * where each a[i] < 2*16.  Such an array represents the integer
 *
 * a[0] + a[1] * 2^16 + ... + a[7] * 2^(7*16).
 *
 * We only use 16 bits of the unsigned long instead of 32, so that
 * when we add or multiply two large integers, we have room for overflow.
 * After any addition or multiplication, the result is carried so that
 * each element of the array is again < 2*16.
 *
 * Someday I may rewrite this in assembler.
 *
 */
typedef unsigned short AM_SHORT;
typedef unsigned long AM_LONG;
typedef AM_LONG AM_BIG_INT[8];

#define high_bits(x) x >> 16
#define low_bits(x) x & 0xffff

#define carry(var, ind) \
  var[ind + 1] += high_bits(var[ind]); \
  var[ind] = low_bits(var[ind])

/* carry macro for AM_BIG_INT pointers */
#define carry_pointer(p) \
  *(p + 1) += high_bits(*(p)); \
  *(p) = low_bits(*(p))

#define carry_replace(var, ind) \
  var[ind + 1] = high_bits(var[ind]); \
  var[ind] = low_bits(var[ind])

/*
 * structure for the supracontexts
 *
 */

typedef struct AM_supra {
  /* list of subcontexts in this supracontext
   *
   * data[0] is the number of subcontexts in
   * the array;
   *
   * data[1] is always 0 (useful for finding
   * intersections; see below)
   *
   * data[i] is not an actually subcontext
   * label; instead, all the subcontext labels
   * are kept in an array called subcontext
   * (bad choice of name?)  created in
   * function _fillandcount().  Thus, the
   * actual subcontexts in the supracontext
   * are subcontext[data[2]], ...
   *
   * data[i] < data[i+1] if i > 1 and
   * i < data[0].
   *
   * Using an array of increasing positive
   * integers makes it easy to take
   * intersections (see lattice.pod).
   */
  AM_SHORT *data;

  /* number of supracontexts that contain
   * precisely these subcontexts;
   *
   * According to the AM algorithm, we're
   * supposed to look at all the homogeneous
   * supracontexts to compute the analogical
   * set.  Instead of traversing the
   * supracontextual lattice to find them, we
   * can instead traverse the list of AM_SUPRA
   * with count > 0 and use the value of count
   * to do our computing.
   *
   * Since we're actually traversing four
   * small lattices and taking intersections,
   * we'll be multiplying the four values of
   * count to get what we want.
   *
   */
  AM_SHORT count;

  /*
   * used to implement two linked lists
   *
   * One linked list contains all the nonempty
   * supracontexts (i.e., data[0] is not 0).
   * This linked list is in fact circular.
   *
   * One linked list contains all the unused
   * memory that can be used for new
   * supracontexts.
   */
  AM_SHORT next;

  /*
   * used during the filling of the
   * supracontextual lattice (see below)
   */
  unsigned char touched;
} AM_SUPRA;

/*
 * There is quite a bit of data that must pass between AM.pm and
 * AM.xs.  Instead of repeatedly passing it back and forth on
 * the argument stack, AM.pm sends references to the variables
 * holding this shared data, by calling _xs_initialize() (defined later
 * on).  These pointers are then stored in the following structure,
 * which is put into the magic part of $self (since $self is an HV,
 * it is perforce an SvPVMG as well).
 *
 * Note that for arrays, we store a pointer to the array data itself,
 * not the AV*.  That means that in AM.pm, we have to be careful
 * how we make assignments to array variables; a reassignment such as
 *
 * @sum = (pack "L!8", 0, 0, 0, 0, 0, 0, 0, 0) x @sum;
 *
 * breaks everything because the pointer stored here then won't point
 * to the actual data anymore.  That's why the appropriate line in
 * AM.pm is
 *
 * foreach (@sum) {
 *   $_ = pack "L!8", 0, 0, 0, 0, 0, 0, 0, 0;
 * }
 *
 * Most of the identifiers in the struct have the same names as the
 * variables created in AM.pm and are documented there.  Those
 * that don't are documented below.
 *
 * This trick of storing pointers like this is borrowed from the
 * source code of Perl/Tk.  Thanks, Nick!
 *
 */

typedef struct AM_guts {

  /*
   * Let i be an integer from 0 to 3; this represents which of the
   * four sublattices we are considering.
   *
   * Let lattice = lptr[i] and supralist = sptr[i]; then lattice and
   * supralist taken together tell us which subcontexts are in a
   * particular supracontext.  If s is the label of a supracontext,
   * then it contains the subcontexts listed in
   * supralist[lattice[s]].data[].
   *
   */

  AM_SHORT *lptr[NUM_LATTICES];
  AM_SUPRA *sptr[NUM_LATTICES];

  /* array ref containing number of active features in
   * each lattice (currently we us four lattices)
   */
  SV **lattice_sizes;
  /* array ref containing class labels for whole data set;
   * array index is data item index in data set.
   */
  SV **classes;
  /* ??? */
  SV **itemcontextchain;
  /* ??? */
  HV *itemcontextchainhead;
  /* Maps subcontext binary labels to class indices */
  HV *context_to_class;
  /* Maps binary context labels to the number of training items
   * contained in that subcontext
   */
  HV *contextsize;
  /* Maps binary context labels to the number of pointers to each,
   * or to the number of pointers to class label if heterogenous.
   * The key 'grandtotal' maps to the total number of pointers.
   */
  HV *pointers;
  /* Maps binary context labels to the size of the gang effect of
   * that context. A gang effect is the number of pointers in
   * the given context multiplied by the number training items
   * contained in the context.
   */
  HV *gang;
  /* number of pointers to each class label;
   * keys are class indices and values are numbers
   * of pointers (AM_BIG_INT).
   */
  SV **sum;
  /*
   * contains the total number of possible class labels;
   * used for computing gang effects.
   */
  IV num_classes;
} AM_GUTS;

/*
 * A function and a vtable necessary for the use of Perl magic
 */

static int AMguts_mgFree(pTHX_ SV *sv, MAGIC *mg) {
  int i;
  AM_GUTS *guts = (AM_GUTS *) SvPVX(mg->mg_obj);
  for (i = 0; i < NUM_LATTICES; ++i) {
    Safefree(guts->lptr[i]);
    Safefree(guts->sptr[i][0].data);
    Safefree(guts->sptr[i]);
  }
  return 0;
}

MGVTBL AMguts_vtab = {
  NULL,
  NULL,
  NULL,
  NULL,
  AMguts_mgFree
};

/*
 * arrays used in the change-of-base portion of normalize(SV *s)
 * they are initialized in BOOT
 *
 */

AM_LONG tens[16]; /* 10, 10*2, 10*4, ... */
AM_LONG ones[16]; /*  1,  1*2,  1*4, ... */

/*
 * function: normalize(SV *s)
 *
 * s is an SvPV whose PV* is a unsigned long array representing a very
 * large integer
 *
 * this function modifies s so that its NV is the floating point
 * representation of the very large integer value, while its PV* is
 * the decimal representation of the very large integer value in ASCII
 * (cool, a double-valued scalar)
 *
 * computing the NV is straightforward
 *
 * computing the PV is done using the old change-of-base algorithm:
 * repeatedly divide by 10, and use the remainders to construct the
 * ASCII digits from least to most significant
 *
 */

normalize(pTHX_ SV *s) {
  AM_LONG dspace[10];
  AM_LONG qspace[10];
  char outspace[55];
  AM_LONG *dividend, *quotient, *dptr, *qptr;
  char *outptr;
  unsigned int outlength = 0;
  AM_LONG *p = (AM_LONG *) SvPVX(s);
  STRLEN length = SvCUR(s) / sizeof(AM_LONG);
  /* TODO: is this required to be a certain number of bits?*/
  long double nn = 0;
  int j;

  /* you can't put the for block in {}, or it doesn't work
   * ask me for details some time
   * TODO: is this still necessary? (Nate)
   */
  for (j = 8; j; --j){
    /*   2^16    * nn +           p[j-1] */
    nn = 65536.0 * nn + (double) *(p + j - 1);
  }

  dividend = &dspace[0];
  quotient = &qspace[0];
  Copy(p, dividend, length, sizeof(AM_LONG));
  /* Magic number here... */
  outptr = outspace + 54;

  while (1) {
    AM_LONG *temp, carry = 0;
    while (length && (*(dividend + length - 1) == 0)) --length;
    if (length == 0) {
      sv_setpvn(s, outptr, outlength);
      break;
    }
    dptr = dividend + length - 1;
    qptr = quotient + length - 1;
    while (dptr >= dividend) {
      unsigned int i;
      *dptr += carry << 16;
      *qptr = 0;
      for (i = 16; i; ) {
        --i;
        if (tens[i] <= *dptr) {
          *dptr -= tens[i];
          *qptr += ones[i];
        }
      }
      carry = *dptr;
      --dptr;
      --qptr;
    }
    --outptr;
    *outptr = (char) (0x30 + *dividend) & 0x00ff;
    ++outlength;
    temp = dividend;
    dividend = quotient;
    quotient = temp;
  }

  SvNVX(s) = nn;
  SvNOK_on(s);
}

 /* Given 2 lists of training item indices sorted in descending order,
  * fill a third list with the intersection of items in these lists.
  * This is a simple intersection, and no check for heterogeneity is
  * performed.
  * Return the next empty (available) index address in the third list.
  * If the two lists have no intersection, then the return value is
  * just the same as the third input.
  */
unsigned short *intersect_supras(
    AM_SHORT *i, AM_SHORT *j, AM_SHORT *k){
  AM_SHORT *temp;
  while (1) {
    while (*i > *j)
      --i;
    if (*i == 0) break;
    if (*i < *j) {
      temp = i;
      i = j;
      j = temp;
      continue;
    }
    *k = *i;
    --i;
    --j;
    --k;
  }
  return k;
}
 /* The first three inputs are the same as for intersect_supra above,
  * and the fourth paramater should be a list containing the class
  * index for all of the training items. In addition to combining
  * the first two lists into the third via intersection, the final
  * list is checked for heterogeneity and the non-deterministic
  * heterogeneous supracontexts are removed.
  * The return value is the number of items contained in the resulting
  * list.
  */
AM_SHORT intersect_supras_final(
    AM_SHORT *i, AM_SHORT *j,
    AM_SHORT *intersect, AM_SHORT *subcontext_class){
  AM_SHORT class = 0;
  AM_SHORT length = 0;
  AM_SHORT *temp;
  while (1) {
    while (*i > *j)
      --i;
    if (*i == 0)
      break;
    if (*i < *j) {
      temp = i;
      i = j;
      j = temp;
      continue;
    }
    *intersect = *i;
    ++intersect;
    ++length;

     /* is it heterogeneous? */
    if (class == 0) {
      /* is it not deterministic? */
      if (length > 1) {
        length = 0;
        break;
      } else {
        class = subcontext_class[*i];
      }
    } else {
      /* Do the classes not match? */
      if (class != subcontext_class[*i]) {
        length = 0;
        break;
      }
    }
    --i;
    --j;
  }
  return length;
}

MODULE = Algorithm::AM		PACKAGE = Algorithm::AM

BOOT:
  {
    AM_LONG ten = 10;
    AM_LONG one = 1;
    AM_LONG *tensptr = &tens[0];
    AM_LONG *onesptr = &ones[0];
    unsigned int i;
    for (i = 16; i; i--) {
      *tensptr = ten;
      *onesptr = one;
      ++tensptr;
      ++onesptr;
      ten <<= 1;
      one <<= 1;
    }
  }

 /*
  * This function is called by from AM.pm right after creating
  * a blessed reference to Algorithm::AM. It stores the necessary
  * pointers in the AM_GUTS structure and attaches it to the magic
  * part of thre reference.
  *
  */

void
_xs_initialize(...)
 PREINIT:
  HV *project;
  AM_GUTS guts; /* NOT A POINTER THIS TIME! (let memory allocate automatically) */
  SV **lattice_sizes;
  SV *svguts;
  MAGIC *mg;
  int i;
 PPCODE:
  /* 9 arguments are passed to the _xs_initialize method: */
  /* $self, the AM object */
  project = (HV *) SvRV(ST(0));
  /* For explanations on these, see the comments on AM_guts */
  lattice_sizes = AvARRAY((AV *) SvRV(ST(1)));
  guts.classes = AvARRAY((AV *) SvRV(ST(2)));
  guts.itemcontextchain = AvARRAY((AV *) SvRV(ST(3)));
  guts.itemcontextchainhead = (HV *) SvRV(ST(4));
  guts.context_to_class = (HV *) SvRV(ST(5));
  guts.contextsize = (HV *) SvRV(ST(6));
  guts.pointers = (HV *) SvRV(ST(7));
  guts.gang = (HV *) SvRV(ST(8));
  guts.sum = AvARRAY((AV *) SvRV(ST(9)));
  guts.num_classes = av_len((AV *) SvRV(ST(9)));

  /*
   * Since the sublattices are small, we just take a chunk of memory
   * here that will be large enough for our purposes and do the actual
   * memory allocation within the code; this reduces the overhead of
   * repeated system calls.
   *
   */

  for (i = 0; i < NUM_LATTICES; ++i) {
    UV v = SvUVX(lattice_sizes[i]);
    Newz(0, guts.lptr[i], 1 << v, AM_SHORT);
    Newz(0, guts.sptr[i], 1 << (v + 1), AM_SUPRA); /* CHANGED */
    Newz(0, guts.sptr[i][0].data, 2, AM_SHORT);
  }

  /* Perl magic invoked here */

  svguts = newSVpv((char *) &guts, sizeof(AM_GUTS));
  sv_magic((SV *) project, svguts, PERL_MAGIC_ext, NULL, 0);
  SvRMAGICAL_off((SV *) project);
  mg = mg_find((SV *) project, PERL_MAGIC_ext);
  mg->mg_virtual = &AMguts_vtab;
  mg_magical((SV *) project);

void
_fillandcount(...)
 PREINIT:
  HV *project;
  UV linear_flag;
  AM_GUTS *guts;
  MAGIC *mg;
  SV **lattice_sizes_input;
  AM_SHORT lattice_sizes[NUM_LATTICES];
  AM_SHORT **lptr;
  AM_SUPRA **sptr;
  AM_SHORT nptr[NUM_LATTICES];/* this helps us manage the free list in sptr[i] */
  AM_SHORT subcontextnumber;
  AM_SHORT *subcontext;
  AM_SHORT *subcontext_class;
  SV **classes, **itemcontextchain, **sum;
  HV *itemcontextchainhead, *context_to_class, *contextsize, *pointers, *gang;
  IV num_classes;
  HE *he;
  AM_BIG_INT grandtotal = {0, 0, 0, 0, 0, 0, 0, 0};
  SV *tempsv;
  int chunk, i;
  AM_SHORT gaps[16];
  AM_SHORT *intersect, *intersectlist;
  AM_SHORT *intersectlist2, *intersectlist3, *ilist2top, *ilist3top;
 PPCODE:
  /* Input args are the AM object ($self), number of features
   * perl lattice, and a flag to indicate whether to count occurrences
   * (true) or pointers (false), also known as linear/quadratic.
   */
  project = (HV *) SvRV(ST(0));
  lattice_sizes_input = AvARRAY((AV *) SvRV(ST(1)));
  linear_flag = SvUVX(ST(2));
  mg = mg_find((SV *) project, PERL_MAGIC_ext);
  guts = (AM_GUTS *) SvPVX(mg->mg_obj);

  /*
   * We initialize the memory for the sublattices, including setting up the
   * linked lists.
   *
   */

  lptr = guts->lptr;
  sptr = guts->sptr;
  for (chunk = 0; chunk < NUM_LATTICES; ++chunk) {
    /* Extract numeric values for the specified lattice_sizes */
    lattice_sizes[chunk] = (AM_SHORT) SvUVX(lattice_sizes_input[chunk]);
    /* TODO: explain the lines below */
    Zero(lptr[chunk], 1 << lattice_sizes[chunk], AM_SHORT);
    sptr[chunk][0].next = 0;
    nptr[chunk] = 1;
    for (i = 1; i < 1 << (lattice_sizes[chunk] + 1); ++i) /* CHANGED */
      sptr[chunk][i].next = (AM_SHORT) i + 1;
  }

  /*
   * Instead of adding subcontext labels directly to the supracontexts,
   * we store all of these labels in an array called subcontext.  We
   * then store the array indices of the subcontext labels in the
   * supracontexts.  That means the list of subcontexts in the
   * supracontexts is an increasing sequence of positive integers, handy
   * for taking intersections (see lattice.pod).
   *
   * The index into the array is called subcontextnumber.
   *
   * The array of matching classes is called subcontext_class.
   *
   */

  context_to_class = guts->context_to_class;
  subcontextnumber = (AM_SHORT) HvUSEDKEYS(context_to_class);
  Newz(0, subcontext, NUM_LATTICES * (subcontextnumber + 1), AM_SHORT);
  subcontext += NUM_LATTICES * subcontextnumber;
  Newz(0, subcontext_class, subcontextnumber + 1, AM_SHORT);
  subcontext_class += subcontextnumber;
  Newz(0, intersectlist, subcontextnumber + 1, AM_SHORT);
  Newz(0, intersectlist2, subcontextnumber + 1, AM_SHORT);
  ilist2top = intersectlist2 + subcontextnumber;
  Newz(0, intersectlist3, subcontextnumber + 1, AM_SHORT);
  ilist3top = intersectlist3 + subcontextnumber;

  hv_iterinit(context_to_class);
  while (he = hv_iternext(context_to_class)) {
    AM_SHORT *contextptr = (AM_SHORT *) HeKEY(he);
    AM_SHORT class = (AM_SHORT) SvUVX(HeVAL(he));
    for (chunk = 0; chunk < NUM_LATTICES; ++chunk, ++contextptr) {
      AM_SHORT active = lattice_sizes[chunk];
      AM_SHORT *lattice = lptr[chunk];
      AM_SUPRA *supralist = sptr[chunk];
      AM_SHORT nextsupra = nptr[chunk];
      AM_SHORT context = *contextptr;
      AM_SUPRA *p, *c;
      AM_SHORT pi, ci;
      AM_SHORT d, t, tt, numgaps = 0;

      /* We want to add subcontextnumber to the appropriate
       * supracontexts in the four smaller lattices.
       *
       * Suppose we want to add subcontextnumber to the supracontext
       * labeled by d.  supralist[lattice[d]] is an AM_SUPRA which
       * reflects the current state of the supracontext.  Suppose this
       * state is
       *
       * data:    2 0 x y (i.e., currently contains two subcontexts)
       * count:   5
       * next:    7
       * touched: 0
       *
       * Then we pluck an unused AM_SUPRA off of the free list;
       * suppose that it's located at supralist[9] (the variable
       * nextsupra tells us where).  Then supralist[lattice[d]] will
       * change to
       *
       * data:    2 0 x y
       * count:   4 (decrease by 1)
       * next:    9
       * touched: 1
       *
       * and supralist[9] will become
       *
       * data:    3 0 subcontextnumber x y (now has three subcontexts)
       * count:   1
       * next:    7
       * touched: 0
       *
       * (note: the entries in data[] are added in decreasing order)
       *
       *
       * If, on the other hand, if supralist[lattice[d]] looks like
       *
       * data:    2 0 x y
       * count:   8
       * next:    11
       * touched: 1
       *
       * that means that supralist[11] must look something like
       *
       * data:    3 0 subcontextnumber x y
       * count:   4
       * next:    2
       * touched: 0
       *
       * There already exists a supracontext with subcontextnumber
       * added in!  So we change supralist[lattice[d]] to
       *
       * data:    2 0 x y
       * count:   7 (decrease by 1)
       * next:    11
       * touched: 1
       *
       * change supralist[11] to
       *
       * data:    3 0 subcontextnumber x y
       * count:   5 (increase by 1)
       * next:    2
       * touched: 0
       *
       * and set lattice[d] = 11.
       */

      subcontext[chunk] = context;

      if (context == 0) {
      	for (p = supralist + supralist->next;
      	     p != supralist; p = supralist + p->next) {
      	  AM_SHORT *data;
      	  Newz(0, data, p->data[0] + 3, AM_SHORT);
      	  Copy(p->data + 2, data + 3, p->data[0], AM_SHORT);
      	  data[2] = subcontextnumber;
      	  data[0] = p->data[0] + 1;
      	  Safefree(p->data);
      	  p->data = data;
      	}
	      if (lattice[context] == 0) {

          /* in this case, the subcontext will be
           * added to all supracontexts, so there's
           * no need to hassle with a Gray code and
           * move pointers
           */

       	  AM_SHORT count = 0;
      	  ci = nptr[chunk];
      	  nptr[chunk] = supralist[ci].next;
      	  c = supralist + ci;
      	  c->next = supralist->next;
      	  supralist->next = ci;
      	  Newz(0, c->data, 3, AM_SHORT);
      	  c->data[2] = subcontextnumber;
      	  c->data[0] = 1;
      	  for (i = 0; i < (1 << active); ++i) {
      	    if (lattice[i] == 0) {
      	      lattice[i] = ci;
      	      ++count;
      	    }
      	  }
      	  c->count = count;
	      }
	      continue;
      }

      /* set up traversal using Gray code */
      d = context;
      for (i = 1 << (active - 1); i; i >>= 1)
        if (!(i & context))
	        gaps[numgaps++] = i;
      t = 1 << numgaps;

      p = supralist + (pi = lattice[context]);
      if (pi)
        --(p->count);
      ci = nextsupra;
      nextsupra = supralist[ci].next;
      p->touched = 1;
      c = supralist + ci;
      c->touched = 0;
      c->next = p->next;
      p->next = ci;
      c->count = 1;
      Newz(0, c->data, p->data[0] + 3, AM_SHORT);
      Copy(p->data + 2, c->data + 3, p->data[0], AM_SHORT);
      c->data[2] = subcontextnumber;
      c->data[0] = p->data[0] + 1;
      lattice[context] = ci;

      /* traverse */
      while (--t) {
        /* find the rightmost 1 in t; from HAKMEM, I believe */
      	for (i = 0, tt = ~t & (t - 1); tt; tt >>= 1, ++i)
          ;
      	d ^= gaps[i];

	      p = supralist + (pi = lattice[d]);
  	    if (pi)
          --(p->count);
      	switch (p->touched) {
      	case 1:
      	  ++supralist[lattice[d] = p->next].count;
      	  break;
      	case 0:
      	  ci = nextsupra;
      	  nextsupra = supralist[ci].next;
      	  p->touched = 1;
      	  c = supralist + ci;
      	  c->touched = 0;
      	  c->next = p->next;
      	  p->next = ci;
      	  c->count = 1;
      	  Newz(0, c->data, p->data[0] + 3, AM_SHORT);
      	  Copy(p->data + 2, c->data + 3, p->data[0], AM_SHORT);
      	  c->data[2] = subcontextnumber;
      	  c->data[0] = p->data[0] + 1;
      	  lattice[d] = ci;
      	}
      }

      /* Here we return all AM_SUPRA with count 0 back to the free
       * list and set touched = 0 for all remaining.
       */

      p = supralist;
      p->touched = 0;
      do {
        if (supralist[i = p->next].count == 0) {
    	    Safefree(supralist[i].data);
      	  p->next = supralist[i].next;
      	  supralist[i].next = nextsupra;
      	  nextsupra = (AM_SHORT) i;
      	} else {
      	  p = supralist + p->next;
      	  p->touched = 0;
      	}
      } while (p->next);
      nptr[chunk] = nextsupra;
    }/*end for(chunk = 0...*/
    subcontext -= NUM_LATTICES;
    *subcontext_class = class;
    --subcontext_class;
    --subcontextnumber;
  }/*end while (he = hv_iternext(...*/

  contextsize = guts->contextsize;
  pointers = guts->pointers;

  /*
   * The code is in three parts:
   *
   * 1. We successively take one nonempty supracontext from each of the
   *    four small lattices and take their intersection to find a
   *    supracontext of the big lattice.  If at any point we get the
   *    empty set, we move on.
   *
   * 2. We determine if the supracontext so found is heterogeneous; if
   *    so, we skip it.
   *
   * 3. Otherwise, we count the pointers or occurrences.
   *
   */
  {
    AM_SUPRA *p0, *p1, *p2, *p3;
    AM_SHORT length;
    AM_SHORT *k;

    /* find intersections */
    for (p0 = sptr[0] + sptr[0]->next; p0 != sptr[0]; p0 = sptr[0] + p0->next) {
      for (p1 = sptr[1] + sptr[1]->next; p1 != sptr[1]; p1 = sptr[1] + p1->next) {
      /*Find intersection between p0 and p2*/
        k = intersect_supras(
          p0->data + p0->data[0] + 1,
          p1->data + p1->data[0] + 1,
          ilist2top
        );
        /* If k has not been increased then intersection was empty */
        if (k == ilist2top)
          continue;
        *k = 0;

        for (p2 = sptr[2] + sptr[2]->next; p2 != sptr[2]; p2 = sptr[2] + p2->next) {

          /*Find intersection between previous intersection and p2*/
          k = intersect_supras(
            ilist2top,
            p2->data + p2->data[0] + 1,
            ilist3top
          );
          /* If k has not been increased then intersection was empty */
          if (k == ilist3top)
            continue;
          *k = 0;

          for (p3 = sptr[3] + sptr[3]->next; p3 != sptr[3]; p3 = sptr[3] + p3->next) {

            /* Find intersection between previous intersection and p3;
             * check for disqualified supras this time.
             */
            length = intersect_supras_final(
              ilist3top,
              p3->data + p3->data[0] + 1,
              intersectlist,
              subcontext_class
            );

            /* count occurrences */
            if (length) {
              AM_SHORT i;
              AM_BIG_INT count = {0, 0, 0, 0, 0, 0, 0, 0};
              AM_LONG mask = 0xffff;

              count[0]  = p0->count;

              count[0] *= p1->count;
              carry(count, 0);

              count[0] *= p2->count;
              count[1] *= p2->count;
              carry(count, 0);
              carry(count, 1);

              count[0] *= p3->count;
              count[1] *= p3->count;
              count[2] *= p3->count;
              carry(count, 0);
              carry(count, 1);
              carry(count, 2);
              if(!linear_flag){
                /* If scoring is pointers (quadratic) instead of linear*/
                AM_LONG pointercount = 0;
                for (i = 0; i < length; ++i)
                  pointercount += (AM_LONG) SvUV(*hv_fetch(contextsize,
                      (char *) (subcontext + (NUM_LATTICES * intersectlist[i])), 8, 0));
                if (pointercount & 0xffff0000) {
                  AM_SHORT pchi = (AM_SHORT) (high_bits(pointercount));
                  AM_SHORT pclo = (AM_SHORT) (low_bits(pointercount));
                  AM_LONG hiprod[6];
                  hiprod[1] = pchi * count[0];
                  hiprod[2] = pchi * count[1];
                  hiprod[3] = pchi * count[2];
                  hiprod[4] = pchi * count[3];
                  count[0] *= pclo;
                  count[1] *= pclo;
                  count[2] *= pclo;
                  count[3] *= pclo;
                  carry(count, 0);
                  carry(count, 1);
                  carry(count, 2);
                  carry(count, 3);

                  count[1] += hiprod[1];
                  count[2] += hiprod[2];
                  count[3] += hiprod[3];
                  count[4] += hiprod[4];
                  carry(count, 1);
                  carry(count, 2);
                  carry(count, 3);
                  carry(count, 4);
                  } else {
                    count[0] *= pointercount;
                    count[1] *= pointercount;
                    count[2] *= pointercount;
                    count[3] *= pointercount;
                    carry(count, 0);
                    carry(count, 1);
                    carry(count, 2);
                    carry(count, 3);
                }
              }
              for (i = 0; i < length; ++i) {
                int j;
                SV *tempsv;
                AM_LONG *p;
                tempsv = *hv_fetch(pointers,
                    (char *) (subcontext + (NUM_LATTICES * intersectlist[i])), 8, 1);
                if (!SvPOK(tempsv)) {
                  SvUPGRADE(tempsv, SVt_PVNV);
                  SvGROW(tempsv, 8 * sizeof(AM_LONG) + 1);
                  Zero(SvPVX(tempsv), 8, AM_LONG);
                  SvCUR_set(tempsv, 8 * sizeof(AM_LONG));
                  SvPOK_on(tempsv);
                }
                p = (AM_LONG *) SvPVX(tempsv);
                for (j = 0; j < 7; ++j) {
                  *(p + j) += count[j];
                  carry_pointer(p + j);
                }
              }/* end for (i = 0;... */
            }/* end if (length) */
          }/* end for (p3 = sptr[3]... */
        }/* end  for (p2 = sptr[2]... */
      }/* end  for (p1 = sptr[1]... */
    }/* end  for (p0 = sptr[0]... */
    /* clear out the supracontexts */
    for (p0 = sptr[0] + sptr[0]->next; p0 != sptr[0]; p0 = sptr[0] + p0->next)
      Safefree(p0->data);
    for (p1 = sptr[1] + sptr[1]->next; p1 != sptr[1]; p1 = sptr[1] + p1->next)
      Safefree(p1->data);
    for (p2 = sptr[2] + sptr[2]->next; p2 != sptr[2]; p2 = sptr[2] + p2->next)
      Safefree(p2->data);
    for (p3 = sptr[3] + sptr[3]->next; p3 != sptr[3]; p3 = sptr[3] + p3->next)
      Safefree(p3->data);

    /*
     * compute analogical set and gang effects
     *
     * Technically, we don't compute the analogical set; instead, we
     * compute how many pointers/occurrences there are for each of the
     * data items in a particular subcontext, and associate that number
     * with the subcontext label, not directly with the data item.  We can
     * do this because if two data items are in the same subcontext, they
     * will have the same number of pointers/occurrences.
     *
     * If the user wants the detailed analogical set, it will be created
     * in Result.pm.
     *
     */

    gang = guts->gang;
    classes = guts->classes;
    itemcontextchain = guts->itemcontextchain;
    itemcontextchainhead = guts->itemcontextchainhead;
    sum = guts->sum;
    num_classes = guts->num_classes;
    hv_iterinit(pointers);
    while (he = hv_iternext(pointers)) {
      AM_LONG count;
      AM_SHORT counthi, countlo;
      AM_BIG_INT p;
      AM_BIG_INT gangcount;
      AM_SHORT this_class;
      SV *dataitem;
      Copy(SvPVX(HeVAL(he)), p, 8, AM_LONG);

      tempsv = *hv_fetch(contextsize, HeKEY(he), NUM_LATTICES * sizeof(AM_SHORT), 0);
      count = (AM_LONG) SvUVX(tempsv);
      counthi = (AM_SHORT) (high_bits(count));
      countlo = (AM_SHORT) (low_bits(count));

      /* initialize 0 because it won't be overwritten */
      /*
       * TODO: multiply through p[7] into gangcount[7]
       * and warn if there's potential overflow
       */
      gangcount[0] = 0;
      for (i = 0; i < 7; ++i) {
        gangcount[i] += countlo * p[i];
        carry_replace(gangcount, i);
      }
      gangcount[7] += countlo * p[7];

      /* TODO: why is element 0 not considered here? */
      if (counthi) {
        for (i = 0; i < 6; ++i) {
          gangcount[i + 1] += counthi * p[i];
          carry(gangcount, i + 1);
        }
      }
      for (i = 0; i < 7; ++i) {
        grandtotal[i] += gangcount[i];
        carry(grandtotal, i);
      }
      grandtotal[7] += gangcount[7];

      tempsv = *hv_fetch(gang, HeKEY(he), NUM_LATTICES * sizeof(AM_SHORT), 1);
      SvUPGRADE(tempsv, SVt_PVNV);
      sv_setpvn(tempsv, (char *) gangcount, 8 * sizeof(AM_LONG));
      normalize(aTHX_ tempsv);
      normalize(aTHX_ HeVAL(he));

      tempsv = *hv_fetch(context_to_class, HeKEY(he), NUM_LATTICES * sizeof(AM_SHORT), 0);
      this_class = (AM_SHORT) SvUVX(tempsv);
      if (this_class) {
        AM_LONG *s = (AM_LONG *) SvPVX(sum[this_class]);
        for (i = 0; i < 7; ++i) {
        	*(s + i) += gangcount[i];
          carry_pointer(s + i);
        }
      } else {
        dataitem = *hv_fetch(itemcontextchainhead, HeKEY(he), NUM_LATTICES * sizeof(AM_SHORT), 0);
        while (SvIOK(dataitem)) {
        	IV datanum = SvIVX(dataitem);
        	IV ocnum = SvIVX(classes[datanum]);
        	AM_LONG *s = (AM_LONG *) SvPVX(sum[ocnum]);
        	for (i = 0; i < 7; ++i) {
        	  *(s + i) += p[i];
            carry_pointer(s + i);
        	  dataitem = itemcontextchain[datanum];
        	}
        }
      }
    }
    for (i = 1; i <= num_classes; ++i) normalize(aTHX_ sum[i])
      ;
    tempsv = *hv_fetch(pointers, "grandtotal", 10, 1);
    SvUPGRADE(tempsv, SVt_PVNV);
    sv_setpvn(tempsv, (char *) grandtotal, 8 * sizeof(AM_LONG));
    normalize(aTHX_ tempsv);

    Safefree(subcontext);
    Safefree(subcontext_class);
    Safefree(intersectlist);
    Safefree(intersectlist2);
    Safefree(intersectlist3);
  }