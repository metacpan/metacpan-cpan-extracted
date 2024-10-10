#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <assert.h>

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

/* carry macros for math using AM_BIG_INT */
#define carry_pointer(p) \
  *(p + 1) += high_bits(*(p)); \
  *(p) = low_bits(*(p))

#define carry_replace(var, ind) \
  var[ind + 1] = high_bits(var[ind]); \
  var[ind] = low_bits(var[ind])

#define hash_pointer_from_stack(ind) \
  (HV *) SvRV(ST(ind))

#define array_pointer_from_stack(ind) \
  AvARRAY((AV *)SvRV(ST(ind)))

#define unsigned_int_from_stack(ind) \
  SvUVX(ST(ind))

/* AM_SUPRAs form a linked list; using for(iter_supra(x, supra)) loops over the list members using the temp variable x */
#define iter_supras(loop_var, supra_ptr) \
  loop_var = supra_ptr + supra_ptr->next; loop_var != supra_ptr; loop_var = supra_ptr + loop_var->next

#define sublist_top(supra) \
  supra->data + supra->data[0] + 1

/*
 * structure for the supracontexts
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
   * Let lattice = lattice_list[i] and supralist = supra_list[i]; then lattice and
   * supralist taken together tell us which subcontexts are in a
   * particular supracontext.  If s is the label of a supracontext,
   * then it contains the subcontexts listed in
   * supralist[lattice[s]].data[].
   *
   */

  AM_SHORT *lattice_list[NUM_LATTICES];
  AM_SUPRA *supra_list[NUM_LATTICES];

  /* array ref containing number of active features in
   * each lattice (currently we us four lattices)
   */
  SV **lattice_sizes;
  /* array ref containing class labels for whole data set;
   * array index is data item index in data set.
   */
  SV **classes;
  /* TODO: ??? */
  SV **itemcontextchain;
  /* TODO: ??? */
  HV *itemcontextchainhead;
  /* Maps subcontext binary labels to class indices (or 0 if subcontext is heterogeneous) */
  HV *context_to_class;
  /* Maps subcontext binary labels to the number of training items
   * contained in that subcontext
   */
  HV *context_size;
  /* Maps binary context labels to the number of pointers to each,
   * or to the number of pointers to each class label if heterogenous.
   * The key "grand_total" maps to the total number of pointers.
   */
  HV *pointers;
  /* Maps binary context labels to the size of the gang effect of
   * that subcontext. A gang effect is the number of pointers in
   * the given subcontext multiplied by the number of training items
   * contained in the context.
   */
  HV *raw_gang;
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
 * TODO: explain the necessity
 */

static int AMguts_mgFree(pTHX_ SV *sv, MAGIC *magic) {
  int i;
  AM_GUTS *guts = (AM_GUTS *) SvPVX(magic->mg_obj);
  for (i = 0; i < NUM_LATTICES; ++i) {
    Safefree(guts->lattice_list[i]);
    Safefree(guts->supra_list[i][0].data);
    Safefree(guts->supra_list[i]);
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
 */

AM_LONG tens[16]; /* 10, 10*2, 10*4, ... */
AM_LONG ones[16]; /*  1,  1*2,  1*4, ... */

/*
 * function: normalize(SV *s)
 *
 * s is an SvPV whose PV* is an unsigned long array representing a very
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
const unsigned int ASCII_0 = 0x30;
const unsigned int DIVIDE_SPACE = 10;
const int OUTSPACE_SIZE = 55;
void normalize(pTHX_ SV *s) {
  AM_LONG *p = (AM_LONG *)SvPVX(s);

  AM_LONG dspace[DIVIDE_SPACE];
  AM_LONG qspace[DIVIDE_SPACE];
  AM_LONG *dividend, *quotient, *dptr, *qptr;

  STRLEN length = SvCUR(s) / sizeof(AM_LONG);
  /* length indexes into dspace and qspace */
  assert(length <= DIVIDE_SPACE);

  /*
   * outptr iterates outspace from end to beginning, and an ASCII digit is inserted at each location.
   * No need to 0-terminate, since we track the final string length in outlength and pass it to sv_setpvn.
   */
  char outspace[OUTSPACE_SIZE];
  char *outptr;
  outptr = outspace + (OUTSPACE_SIZE - 1);
  unsigned int outlength = 0;

  /* TODO: is this required to be a certain number of bits? */
  long double nn = 0;

  /* nn will be assigned to the NV */
  for (int j = 8; j; --j) {
    /*   2^16    * nn +           p[j-1] */
    nn = 65536.0 * nn + (double) *(p + j - 1);
  }

  dividend = &dspace[0];
  quotient = &qspace[0];
  Copy(p, dividend, length, AM_LONG);

  while (1) {
    while (length && (*(dividend + length - 1) == 0)) {
      --length;
    }
    if (length == 0) {
      sv_setpvn(s, outptr, outlength);
      break;
    }
    dptr = dividend + length - 1;
    qptr = quotient + length - 1;
    AM_LONG carry = 0;
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
    *outptr = (char)(ASCII_0 + *dividend) & 0x00ff;
    ++outlength;
    AM_LONG *temp = dividend;
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
    AM_SHORT *intersection_list_top, AM_SHORT *subcontext_list_top, AM_SHORT *k){
  while (1) {
    while (*intersection_list_top > *subcontext_list_top) {
      --intersection_list_top;
    }
    if (*intersection_list_top == 0) {
      break;
    }
    if (*intersection_list_top < *subcontext_list_top) {
      AM_SHORT *temp = intersection_list_top;
      intersection_list_top = subcontext_list_top;
      subcontext_list_top = temp;
      continue;
    }
    *k = *intersection_list_top;
    --intersection_list_top;
    --subcontext_list_top;
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
    AM_SHORT *intersection_list_top, AM_SHORT *subcontext_list_top,
    AM_SHORT *intersect, AM_SHORT *subcontext_class){
  AM_SHORT class = 0;
  AM_SHORT length = 0;
  while (1) {
    while (*intersection_list_top > *subcontext_list_top) {
      --intersection_list_top;
    }
    if (*intersection_list_top == 0) {
      break;
    }
    if (*intersection_list_top < *subcontext_list_top) {
      AM_SHORT *temp = intersection_list_top;
      intersection_list_top = subcontext_list_top;
      subcontext_list_top = temp;
      continue;
    }
    *intersect = *intersection_list_top;
    ++intersect;
    ++length;

     /* is it heterogeneous? */
    if (class == 0) {
      /* is it not deterministic? */
      if (length > 1) {
        length = 0;
        break;
      } else {
        class = subcontext_class[*intersection_list_top];
      }
    } else {
      /* Do the classes not match? */
      if (class != subcontext_class[*intersection_list_top]) {
        length = 0;
        break;
      }
    }
    --intersection_list_top;
    --subcontext_list_top;
  }
  return length;
}

/* clear out the supracontexts */
void clear_supras(AM_SUPRA **supra_list, int supras_length)
{
  AM_SUPRA *p;
  for (int i = 0; i < supras_length; i++)
  {
    for (iter_supras(p, supra_list[i]))
    {
      Safefree(p->data);
    }
  }
}

MODULE = Algorithm::AM PACKAGE = Algorithm::AM

PROTOTYPES: DISABLE

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
  * part of the reference.
  *
  */

void
_xs_initialize(...)
 PPCODE:
  /* NOT A POINTER THIS TIME! (let memory allocate automatically) */
  AM_GUTS guts;
  /* 9 arguments are passed to the _xs_initialize method: */
  /* $self, the AM object */
  HV *self = hash_pointer_from_stack(0);
  /* For explanations on these, see the comments on AM_guts */
  SV **lattice_sizes = array_pointer_from_stack(1);
  guts.classes = array_pointer_from_stack(2);
  guts.itemcontextchain = array_pointer_from_stack(3);
  guts.itemcontextchainhead = hash_pointer_from_stack(4);
  guts.context_to_class = hash_pointer_from_stack(5);
  guts.context_size = hash_pointer_from_stack(6);
  guts.pointers = hash_pointer_from_stack(7);
  guts.raw_gang = hash_pointer_from_stack(8);
  guts.sum = array_pointer_from_stack(9);
  /* Length of guts.sum */
  guts.num_classes = av_len((AV *) SvRV(ST(9)));

  /*
   * Since the sublattices are small, we just take a chunk of memory
   * here that will be large enough for our purposes and do the actual
   * memory allocation within the code; this reduces the overhead of
   * repeated system calls.
   *
   */

  for (int i = 0; i < NUM_LATTICES; ++i) {
    UV v = SvUVX(lattice_sizes[i]);
    Newxz(guts.lattice_list[i], 1 << v, AM_SHORT);
    Newxz(guts.supra_list[i], 1 << (v + 1), AM_SUPRA); /* CHANGED */ /* TODO: what changed? */
    Newxz(guts.supra_list[i][0].data, 2, AM_SHORT);
  }

  /* Perl magic invoked here */

  SV *svguts = newSVpv((char *)&guts, sizeof(AM_GUTS));
  sv_magic((SV *) self, svguts, PERL_MAGIC_ext, NULL, 0);
  SvRMAGICAL_off((SV *) self);
  MAGIC *magic = mg_find((SV *)self, PERL_MAGIC_ext);
  magic->mg_virtual = &AMguts_vtab;
  mg_magical((SV *) self);

void
_fillandcount(...)
 PPCODE:
  /* Input args are the AM object ($self), number of features in each
   * lattice, and a flag to indicate whether to count occurrences
   * (true) or pointers (false), also known as linear/quadratic.
   */
  HV *self = hash_pointer_from_stack(0);
  SV **lattice_sizes_input = array_pointer_from_stack(1);
  UV linear_flag = unsigned_int_from_stack(2);
  MAGIC *magic = mg_find((SV *)self, PERL_MAGIC_ext);
  AM_GUTS *guts = (AM_GUTS *)SvPVX(magic->mg_obj);

  /*
   * We initialize the memory for the sublattices, including setting up the
   * linked lists.
   */

  AM_SHORT **lattice_list = guts->lattice_list;
  AM_SUPRA **supra_list = guts->supra_list;
  /* this helps us manage the free list in supra_list[i] */
  AM_SHORT nptr[NUM_LATTICES];
  AM_SHORT lattice_sizes[NUM_LATTICES];
  for (int sublattice_index = 0; sublattice_index < NUM_LATTICES; ++sublattice_index) {
    /* Extract numeric values for the specified lattice_sizes */
    lattice_sizes[sublattice_index] = (AM_SHORT) SvUVX(lattice_sizes_input[sublattice_index]);
    /* TODO: explain the lines below */
    Zero(lattice_list[sublattice_index], 1 << lattice_sizes[sublattice_index], AM_SHORT);
    supra_list[sublattice_index][0].next = 0;
    nptr[sublattice_index] = 1;
    for (int i = 1; i < 1 << (lattice_sizes[sublattice_index] + 1); ++i) {/* CHANGED (TODO: changed what?) */
      supra_list[sublattice_index][i].next = (AM_SHORT) i + 1;
    }
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

  HV *context_to_class = guts->context_to_class;
  AM_SHORT subcontextnumber = (AM_SHORT)HvUSEDKEYS(context_to_class);
  AM_SHORT *subcontext;
  Newxz(subcontext, NUM_LATTICES *(subcontextnumber + 1), AM_SHORT);
  subcontext += NUM_LATTICES * subcontextnumber;
  AM_SHORT *subcontext_class;
  Newxz(subcontext_class, subcontextnumber + 1, AM_SHORT);
  subcontext_class += subcontextnumber;

  AM_SHORT *intersectlist, *intersectlist2, *intersectlist3;
  AM_SHORT *ilist2top, *ilist3top;
  Newxz(intersectlist, subcontextnumber + 1, AM_SHORT);
  Newxz(intersectlist2, subcontextnumber + 1, AM_SHORT);
  ilist2top = intersectlist2 + subcontextnumber;
  Newxz(intersectlist3, subcontextnumber + 1, AM_SHORT);
  ilist3top = intersectlist3 + subcontextnumber;

  hv_iterinit(context_to_class);
  HE *context_to_class_entry;
  while ((context_to_class_entry = hv_iternext(context_to_class))) {
    AM_SHORT *contextptr = (AM_SHORT *) HeKEY(context_to_class_entry);
    AM_SHORT class = (AM_SHORT) SvUVX(HeVAL(context_to_class_entry));
    for (int sublattice_index = 0; sublattice_index < NUM_LATTICES; ++sublattice_index, ++contextptr) {
      AM_SHORT active = lattice_sizes[sublattice_index];
      AM_SHORT *lattice = lattice_list[sublattice_index];
      AM_SUPRA *supralist = supra_list[sublattice_index];
      AM_SHORT nextsupra = nptr[sublattice_index];
      AM_SHORT context = *contextptr;

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

      subcontext[sublattice_index] = context;
      AM_SHORT gaps[16];
      if (context == 0) {
        AM_SUPRA *p;
        for (iter_supras(p, supralist)) {
          AM_SHORT *data;
          Newxz(data, p->data[0] + 3, AM_SHORT);
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
          AM_SHORT ci = nptr[sublattice_index];
          nptr[sublattice_index] = supralist[ci].next;
          AM_SUPRA *c = supralist + ci;
          c->next = supralist->next;
          supralist->next = ci;
          Newxz(c->data, 3, AM_SHORT);
          c->data[2] = subcontextnumber;
          c->data[0] = 1;
          for (int i = 0; i < (1 << active); ++i) {
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
      AM_SHORT d = context;
      AM_SHORT numgaps = 0;
      for (int i = 1 << (active - 1); i; i >>= 1) {
        if (!(i & context)) {
          gaps[numgaps++] = i;
        }
      }
      AM_SHORT t = 1 << numgaps;

      AM_SHORT pi = lattice[context];
      AM_SUPRA *p = supralist + pi;
      if (pi) {
        --(p->count);
      }
      AM_SHORT ci = nextsupra;
      nextsupra = supralist[ci].next;
      p->touched = 1;
      AM_SUPRA *c = supralist + ci;
      c->touched = 0;
      c->next = p->next;
      p->next = ci;
      c->count = 1;
      Newxz(c->data, p->data[0] + 3, AM_SHORT);
      Copy(p->data + 2, c->data + 3, p->data[0], AM_SHORT);
      c->data[2] = subcontextnumber;
      c->data[0] = p->data[0] + 1;
      lattice[context] = ci;

      /* traverse */
      while (--t) {
        AM_SHORT tt;
        int i;
        /* find the rightmost 1 in t; from HAKMEM, I believe */
        for (i = 0, tt = ~t & (t - 1); tt; tt >>= 1, ++i) {
          ;
        }
        d ^= gaps[i];

        p = supralist + (pi = lattice[d]);
        if (pi) {
          --(p->count);
        }
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
            Newxz(c->data, p->data[0] + 3, AM_SHORT);
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
      int i;
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
      nptr[sublattice_index] = nextsupra;
    } /*end for(sublattice_index = 0...*/
    subcontext -= NUM_LATTICES;
    *subcontext_class = class;
    --subcontext_class;
    --subcontextnumber;
  } /*end while (context_to_class_entry = hv_iternext(...*/

  HV *context_size = guts->context_size;
  HV *pointers = guts->pointers;

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
    /* find intersections */
    AM_SUPRA * p0;
    for (iter_supras(p0, supra_list[0])) {
      AM_SUPRA *p1;
      for (iter_supras(p1, supra_list[1])) {
        /* Find intersection between p0 and p1 */
        AM_SHORT *k = intersect_supras(
          sublist_top(p0),
          sublist_top(p1),
          ilist2top
        );
        /* If k has not been increased then intersection was empty */
        if (k == ilist2top) {
          continue;
        }
        *k = 0;

        AM_SUPRA *p2;
        for (iter_supras(p2, supra_list[2])) {

          /*Find intersection between previous intersection and p2*/
          k = intersect_supras(
            ilist2top,
            sublist_top(p2),
            ilist3top
          );
          /* If k has not been increased then intersection was empty */
          if (k == ilist3top) {
            continue;
          }
          *k = 0;

          AM_SUPRA *p3;
          for (iter_supras(p3, supra_list[3])) {

            /* Find intersection between previous intersection and p3;
             * check for disqualified supras this time.
             */
            AM_SHORT length = intersect_supras_final(
              ilist3top,
              sublist_top(p3),
              intersectlist,
              subcontext_class
            );

            /* count occurrences */
            if (length) {
              AM_BIG_INT count = {0, 0, 0, 0, 0, 0, 0, 0};

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
                for (int i = 0; i < length; ++i) {
                  pointercount += (AM_LONG) SvUV(*hv_fetch(context_size,
                      (char *) (subcontext + (NUM_LATTICES * intersectlist[i])), 8, 0));
                }
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
              for (int i = 0; i < length; ++i) {
                SV *final_pointers_sv = *hv_fetch(pointers,
                    (char *) (subcontext + (NUM_LATTICES * intersectlist[i])), 8, 1);
                if (!SvPOK(final_pointers_sv)) {
                  SvUPGRADE(final_pointers_sv, SVt_PVNV);
                  SvGROW(final_pointers_sv, 8 * sizeof(AM_LONG) + 1);
                  Zero(SvPVX(final_pointers_sv), 8, AM_LONG);
                  SvCUR_set(final_pointers_sv, 8 * sizeof(AM_LONG));
                  SvPOK_on(final_pointers_sv);
                }
                AM_LONG *final_pointers = (AM_LONG *) SvPVX(final_pointers_sv);
                for (int j = 0; j < 7; ++j) {
                  *(final_pointers + j) += count[j];
                  carry_pointer(final_pointers + j);
                }
              } /* end for (i = 0;... */
            } /* end if (length) */
          } /* end for (iter_supras(p3... */
        } /* end  for (iter_supras(p2... */
      } /* end  for (iter_supras(p1... */
    } /* end  for (iter_supras(p0... */

    clear_supras(supra_list, 4);

    /*
     * compute analogical set and raw gang effects
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

    HV *raw_gang = guts->raw_gang;
    SV **classes = guts->classes;
    SV **itemcontextchain = guts->itemcontextchain;
    HV *itemcontextchainhead = guts->itemcontextchainhead;
    SV **sum = guts->sum;
    IV num_classes = guts->num_classes;
    AM_BIG_INT grand_total = {0, 0, 0, 0, 0, 0, 0, 0};
    hv_iterinit(pointers);
    HE * pointers_entry;
    while ((pointers_entry = hv_iternext(pointers))) {
      AM_BIG_INT p;
      Copy(SvPVX(HeVAL(pointers_entry)), p, 8, AM_LONG);

      SV *num_examplars = *hv_fetch(context_size, HeKEY(pointers_entry), NUM_LATTICES * sizeof(AM_SHORT), 0);
      AM_LONG count = (AM_LONG)SvUVX(num_examplars);
      AM_SHORT counthi = (AM_SHORT)(high_bits(count));
      AM_SHORT countlo = (AM_SHORT)(low_bits(count));

      /* initialize 0 because it won't be overwritten */
      /*
       * TODO: multiply through p[7] into gangcount[7]
       * and warn if there's potential overflow
       */
      AM_BIG_INT gangcount;
      gangcount[0] = 0;
      for (int i = 0; i < 7; ++i) {
        gangcount[i] += countlo * p[i];
        carry_replace(gangcount, i);
      }
      gangcount[7] += countlo * p[7];

      /* TODO: why is element 0 not considered here? */
      if (counthi) {
        for (int i = 0; i < 6; ++i) {
          gangcount[i + 1] += counthi * p[i];
          carry(gangcount, i + 1);
        }
      }
      for (int i = 0; i < 7; ++i) {
        grand_total[i] += gangcount[i];
        carry(grand_total, i);
      }
      grand_total[7] += gangcount[7];

      normalize(aTHX_ HeVAL(pointers_entry));

      SV* gang_pointers = *hv_fetch(raw_gang, HeKEY(pointers_entry), NUM_LATTICES * sizeof(AM_SHORT), 1);
      SvUPGRADE(gang_pointers, SVt_PVNV);
      sv_setpvn(gang_pointers, (char *) gangcount, 8 * sizeof(AM_LONG));
      normalize(aTHX_ gang_pointers);

      SV* this_class_sv = *hv_fetch(context_to_class, HeKEY(pointers_entry), NUM_LATTICES * sizeof(AM_SHORT), 0);
      AM_SHORT this_class = (AM_SHORT) SvUVX(this_class_sv);
      if (this_class) {
        SV_CHECK_THINKFIRST(sum[this_class]);
        AM_LONG *s = (AM_LONG *) SvPVX(sum[this_class]);
        for (int i = 0; i < 7; ++i) {
          *(s + i) += gangcount[i];
          carry_pointer(s + i);
        }
      } else {
      SV *exemplar = *hv_fetch(itemcontextchainhead, HeKEY(pointers_entry), NUM_LATTICES * sizeof(AM_SHORT), 0);
        while (SvIOK(exemplar)) {
          IV datanum = SvIVX(exemplar);
          IV ocnum = SvIVX(classes[datanum]);
          SV_CHECK_THINKFIRST(sum[ocnum]);
          AM_LONG *s = (AM_LONG *) SvPVX(sum[ocnum]);
          for (int i = 0; i < 7; ++i) {
            *(s + i) += p[i];
            carry_pointer(s + i);
            exemplar = itemcontextchain[datanum];
          }
        }
      }
    }
    for (int i = 1; i <= num_classes; ++i) {
      normalize(aTHX_ sum[i]);
    }

    SV *grand_total_entry = *hv_fetch(pointers, "grand_total", 11, 1);
    SvUPGRADE(grand_total_entry, SVt_PVNV);
    sv_setpvn(grand_total_entry, (char *) grand_total, 8 * sizeof(AM_LONG));
    normalize(aTHX_ grand_total_entry);

    Safefree(subcontext);
    Safefree(subcontext_class);
    Safefree(intersectlist);
    Safefree(intersectlist2);
    Safefree(intersectlist3);
  }
