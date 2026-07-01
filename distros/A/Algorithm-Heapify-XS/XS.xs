#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifndef NOT_REACHED
#  define NOT_REACHED assert(0)
#endif

#define iParent(i)      (((i)-1) / 2)
#define iLeftChild(i)   ((2*(i)) + 1)
#define iRightChild(i)  ((2*(i)) + 2)

#define HAVE_PERL_SV_NUMCMP \
    (PERL_REVISION > 5 || (PERL_REVISION == 5 && (PERL_VERSION > 43 || (PERL_VERSION == 43 && PERL_SUBVERSION >= 8))))

#define OUT_OF_ORDER(a,child,parent,is_min)                                    \
    ( ( (is_min & 2)                                                           \
        ? my_sv_string_gt(aTHX_ (a)[(child)], (a)[(parent)])                   \
        : my_sv_num_gt(aTHX_ (a)[(child)], (a)[(parent)]))                     \
      ? !(is_min & 1) : (is_min & 1) )

#define FORCE_SCALAR(fakeop)                    \
STMT_START {                                    \
        SAVEOP();                               \
        Copy(PL_op, &fakeop, 1, OP);            \
        fakeop.op_flags = OPf_WANT_SCALAR;      \
        PL_op = &fakeop;                        \
} STMT_END


#ifdef Perl_do_ncmp
#define my_Perl_do_ncmp Perl_do_ncmp
#else
/* compare left and right SVs. Returns:
 * -1: <
 *  0: ==
 *  1: >
 *  2: left or right was a NaN
 */
I32
my_Perl_do_ncmp(pTHX_ SV* const left, SV * const right)
{
    PERL_ARGS_ASSERT_DO_NCMP;
    /* Fortunately it seems NaN isn't IOK */
    if (SvIV_please_nomg(right) && SvIV_please_nomg(left)) {
            if (!SvIsUV(left)) {
                const IV leftiv = SvIVX(left);
                if (!SvIsUV(right)) {
                    /* ## IV <=> IV ## */
                    const IV rightiv = SvIVX(right);
                    return (leftiv > rightiv) - (leftiv < rightiv);
                }
                /* ## IV <=> UV ## */
                if (leftiv < 0)
                    /* As (b) is a UV, it's >=0, so it must be < */
                    return -1;
                {
                    const UV rightuv = SvUVX(right);
                    return ((UV)leftiv > rightuv) - ((UV)leftiv < rightuv);
                }
            }

            if (SvIsUV(right)) {
                /* ## UV <=> UV ## */
                const UV leftuv = SvUVX(left);
                const UV rightuv = SvUVX(right);
                return (leftuv > rightuv) - (leftuv < rightuv);
            }
            /* ## UV <=> IV ## */
            {
                const IV rightiv = SvIVX(right);
                if (rightiv < 0)
                    /* As (a) is a UV, it's >=0, so it cannot be < */
                    return 1;
                {
                    const UV leftuv = SvUVX(left);
                    return (leftuv > (UV)rightiv) - (leftuv < (UV)rightiv);
                }
            }
            NOT_REACHED; /* NOTREACHED */
    }
    {
      NV const lnv = SvNV_nomg(left);
      NV const rnv = SvNV_nomg(right);

#if defined(NAN_COMPARE_BROKEN) && defined(Perl_isnan)
      if (Perl_isnan(lnv) || Perl_isnan(rnv)) {
          return 2;
       }
      return (lnv > rnv) - (lnv < rnv);
#else
      if (lnv < rnv)
        return -1;
      if (lnv > rnv)
        return 1;
      if (lnv == rnv)
        return 0;
      return 2;
#endif
    }
}
#endif

static bool
my_has_real_overload_method(pTHX_ SV *sv, const char *name, STRLEN len)
{
    GV *gv;
    CV *cv;
    GV *cvgv;
    HV *stash;
    const HEK *gvhek;
    const HEK *stashek;

    if (!SvAMAGIC(sv) || !SvROK(sv)) {
        return FALSE;
    }

    stash = SvSTASH(SvRV(sv));
    if (!stash) {
        return FALSE;
    }

    gv = gv_fetchmeth_pvn(stash, name, len, -1, 0);
    if (!gv) {
        return FALSE;
    }

    cv = GvCV(gv);
    if (!cv) {
        return FALSE;
    }

    cvgv = CvGV(cv);
    if (!cvgv) {
        return TRUE;
    }

    gvhek = GvNAME_HEK(cvgv);
    stashek = HvNAME_HEK(GvSTASH(cvgv));
    if (!gvhek || !stashek) {
        return TRUE;
    }

    return !(stashek
        && memEQs(HEK_KEY(gvhek), HEK_LEN(gvhek), "nil")
        && memEQs(HEK_KEY(stashek), HEK_LEN(stashek), "overload"));
}

static SV *
my_sv_2num(pTHX_ SV *sv)
{
    if (!SvROK(sv)) {
        return sv;
    }

    if (SvAMAGIC(sv)) {
        SV *tmpsv = AMG_CALLunary(sv, numer_amg);
        if (tmpsv && (!SvROK(tmpsv) || SvRV(tmpsv) != SvRV(sv))) {
            return my_sv_2num(aTHX_ tmpsv);
        }
    }

    return sv_2mortal(newSVuv(PTR2UV(SvRV(sv))));
}

static bool
my_sv_string_gt(pTHX_ SV *left, SV *right)
{
    SV *tmpsv = NULL;

    if (SvAMAGIC(left) || SvAMAGIC(right)) {
        if (my_has_real_overload_method(aTHX_ left, "(gt", 3)
            || my_has_real_overload_method(aTHX_ right, "(gt", 3)) {
            tmpsv = amagic_call(left, right, sgt_amg, 0);
            if (tmpsv) {
                return SvTRUE(tmpsv);
            }
        }
        if (my_has_real_overload_method(aTHX_ left, "(cmp", 4)
            || my_has_real_overload_method(aTHX_ right, "(cmp", 4)) {
            tmpsv = amagic_call(left, right, scmp_amg, 0);
            if (tmpsv) {
                return SvIV(tmpsv) > 0;
            }
        }
    }

    return Perl_sv_cmp(aTHX_ left, right) > 0;
}

static bool
my_sv_num_gt(pTHX_ SV *left, SV *right)
{
#if HAVE_PERL_SV_NUMCMP
    return sv_numcmp(left, right) > 0;
#else
    if (SvAMAGIC(left) || SvAMAGIC(right)) {
        SV *tmpsv = NULL;

        if (my_has_real_overload_method(aTHX_ left, "(>", 2)
            || my_has_real_overload_method(aTHX_ right, "(>", 2)) {
            tmpsv = amagic_call(left, right, gt_amg, 0);
            if (tmpsv) {
                return SvTRUE(tmpsv);
            }
        }

        if (my_has_real_overload_method(aTHX_ left, "(<=>", 4)
            || my_has_real_overload_method(aTHX_ right, "(<=>", 4)) {
            tmpsv = amagic_call(left, right, ncmp_amg, 0);
            if (tmpsv) {
                return SvIV(tmpsv) > 0;
            }
        }

    }

    left = my_sv_2num(aTHX_ left);
    right = my_sv_2num(aTHX_ right);

    return my_Perl_do_ncmp(aTHX_ left, right) > 0;
#endif
}


I32 sift_up(pTHX_ SV **a, ssize_t start, ssize_t end, I32 is_min) {
     /*start represents the limit of how far up the heap to sift.
       end is the node to sift up. */
    ssize_t child = end;
    I32 swapped = 0;
    SvGETMAGIC(a[child]);

    while (child > start) {
        ssize_t parent = iParent(child);
        SvGETMAGIC(a[parent]);
        if ( OUT_OF_ORDER(a,child,parent,is_min) ) {
            SV *swap_tmp= a[parent];
            a[parent]= a[child];
            a[child]= swap_tmp;

            child = parent; /* repeat to continue sifting up the parent now */
            swapped++;
        }
        else {
            return swapped;
        }
    }
    return swapped;
}

/*Repair the heap whose root element is at index 'start', assuming the heaps rooted at its children are valid*/
I32 sift_down(pTHX_ SV **a, ssize_t start, ssize_t end, I32 is_min) {
    ssize_t root = start;
    I32 swapped = 0;

    while (iLeftChild(root) <= end) {       /* While the root has at least one child */
        ssize_t child = iLeftChild(root);       /* Left child of root */
        ssize_t swap = root;                    /* Keeps track of child to swap with */

        /* if the root is smaller than the left child
         *      then the swap is with the left child */
        if ( OUT_OF_ORDER(a,child,swap,is_min) ) {
            swap = child;
        }
        /* if there is a right child and the right child is larger than the root or the left child
         *      then the swap is with the right child */
        if (child+1 <= end) {
            if ( OUT_OF_ORDER(a,child+1,swap,is_min) ) {
                swap = child + 1;
            }
        }
        /* check if we need to swap or if this tree is in heap-order */
        if (swap == root) {
            /* The root is larger than both children, and as we assume the heaps rooted at the children are valid
             * then we know we can stop. */
            return swapped;
        } else {
            /* swap the root with the largest child */
            SV *tmp= a[root];
            a[root]= a[swap];
            a[swap]= tmp;
            /* continue sifting down the child by setting the root to the chosen child
             * effectively we sink down the tree towards the leafs */
            root = swap;
            swapped++;
        }
    }
    return swapped;
}

/* this is O(N log N) */
void heapify_with_sift_up(pTHX_ SV **a, ssize_t count, I32 is_min) {
    ssize_t end = 1; /* end is assigned the index of the first (left) child of the root */

    while (end < count) {
        /*sift up the node at index end to the proper place such that all nodes above
          the end index are in heap order */
        (void)sift_up(aTHX_ a, 0, end, is_min);
        end++;
    }
    /* after sifting up the last node all nodes are in heap order */
}

/* this is O(N) */
void heapify_with_sift_down(pTHX_ SV **a, ssize_t count, I32 is_min) {
    /*start is assigned the index in 'a' of the last parent node
      the last element in a 0-based array is at index count-1; find the parent of that element */
    ssize_t start = iParent(count-1);

    while (start >= 0) {
        /* sift down the node at index 'start' to the proper place such that all nodes below
         the start index are in heap order */
        (void)sift_down(aTHX_ a, start, count - 1, is_min);
        /* go to the next parent node */
        start--;
    }
    /* after sifting down the root all nodes/elements are in heap order */
}


MODULE = Algorithm::Heapify::XS		PACKAGE = Algorithm::Heapify::XS		

void
max_heapify(av)
    AV *av
PROTOTYPE: \@
ALIAS:
   max_heapify = 0
   min_heapify = 1
   maxstr_heapify = 2
   minstr_heapify = 3
PREINIT:
    OP fakeop;
    I32 count;
PPCODE:
    FORCE_SCALAR(fakeop);
    count = av_top_index(av)+1;
    if ( count ) {
        heapify_with_sift_down(aTHX_ AvARRAY(av),count,ix);
        ST(0)= AvARRAY(av)[0];
        XSRETURN(1);
    }
    else {
        XSRETURN(0);
    }

void
max_heap_shift(av)
    AV *av
PROTOTYPE: \@
ALIAS:
   max_heap_shift = 0
   min_heap_shift = 1
   maxstr_heap_shift = 2
   minstr_heap_shift = 3
PREINIT:
    OP fakeop;
    I32 top;
    I32 count;
PPCODE:
    FORCE_SCALAR(fakeop);
    top= av_top_index(av);
    count= top+1;
    if (count) {
        SV *tmp= AvARRAY(av)[0];
        AvARRAY(av)[0]= AvARRAY(av)[top];
        AvARRAY(av)[top]= tmp;
        ST(0)= av_pop(av);
        if (count > 2)
            sift_down(aTHX_ AvARRAY(av),0,top-1,ix);
        XSRETURN(1);
    }
    else {
        XSRETURN(0);
    }

void
max_heap_push(av,sv)
    AV *av
    SV *sv
PROTOTYPE: \@$
ALIAS:
   max_heap_push = 0
   min_heap_push = 1
   maxstr_heap_push = 2
   minstr_heap_push = 3
PREINIT:
    OP fakeop;
    I32 top;
    I32 count;
PPCODE:
    FORCE_SCALAR(fakeop);
    av_push(av,newSVsv(sv));
    top= av_top_index(av);
    count= top+1;
    sift_up(aTHX_ AvARRAY(av),0,top,ix);
    ST(0)= AvARRAY(av)[0];
    XSRETURN(1);

void
max_heap_adjust_top(av)
    AV *av
PROTOTYPE: \@
ALIAS:
   max_heap_adjust_top = 0
   min_heap_adjust_top = 1
   maxstr_heap_adjust_top = 2
   minstr_heap_adjust_top = 3
PREINIT:
    OP fakeop;
    I32 top;
    I32 count;
PPCODE:
    FORCE_SCALAR(fakeop);
    top= av_top_index(av);
    count= top+1;
    if ( count ) {
        (void)sift_down(aTHX_ AvARRAY(av),0,top,ix);
        ST(0)= AvARRAY(av)[0];
        XSRETURN(1);
    } else {
        XSRETURN(0);
    }

void
max_heap_adjust_item(av,idx=0)
    AV *av
    I32 idx;
PROTOTYPE: \@;$
ALIAS:
   max_heap_adjust_item = 0
   min_heap_adjust_item = 1
   maxstr_heap_adjust_item = 2
   minstr_heap_adjust_item = 3
PREINIT:
    OP fakeop;
    I32 top;
    I32 count;
PPCODE:
    FORCE_SCALAR(fakeop);
    top= av_top_index(av);
    count= top+1;
    if ( idx < count ) {
        if (!idx || !sift_up(aTHX_ AvARRAY(av),0,idx,ix))
            (void)sift_down(aTHX_ AvARRAY(av),idx,top,ix);
        ST(0)= AvARRAY(av)[0];
        XSRETURN(1);
    } else {
        XSRETURN(0);
    }
