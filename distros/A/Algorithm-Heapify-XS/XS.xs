#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define iParent(i)      (((i)-1) / 2)
#define iLeftChild(i)   ((2*(i)) + 1)
#define iRightChild(i)  ((2*(i)) + 2)

#define OUT_OF_ORDER(a,tmpsv,child_is_magic,parent_is_magic,child,parent,is_min)                \
    ( ( ( (child_is_magic) || (parent_is_magic) )                                               \
        ? (((tmpsv) = amagic_call((a)[(child)], (a)[(parent)], is_min & 2 ? sgt_amg : gt_amg, 0)) && SvTRUE((tmpsv)))  \
        : ( ((is_min & 2) ? Perl_sv_cmp(aTHX_ (a)[(child)], a[(parent)]) \
                          : Perl_do_ncmp(aTHX_ (a)[(child)], a[(parent)])) > 0) )\
      ? !(is_min & 1) : (is_min & 1) )


I32 sift_up(pTHX_ SV **a, ssize_t start, ssize_t end, I32 is_min) {
     /*start represents the limit of how far up the heap to sift.
       end is the node to sift up. */
    ssize_t child = end;
    SV *tmpsv = NULL;
    I32 child_is_magic;
    I32 swapped = 0;
    SvGETMAGIC(a[child]);
    child_is_magic= SvAMAGIC(a[child]);

    while (child > start) {
        ssize_t parent = iParent(child);
        I32 parent_is_magic;
        SvGETMAGIC(a[parent]);
        parent_is_magic= SvAMAGIC(a[parent]);
        if ( OUT_OF_ORDER(a,tmpsv,child_is_magic,parent_is_magic,child,parent,is_min) ) {
            SV *swap_tmp= a[parent];
            a[parent]= a[child];
            a[child]= swap_tmp;

            child = parent; /* repeat to continue sifting up the parent now */
            child_is_magic= parent_is_magic;
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
    I32 root_is_magic = SvAMAGIC(a[root]);
    I32 swapped = 0;

    while (iLeftChild(root) <= end) {       /* While the root has at least one child */
        ssize_t child = iLeftChild(root);       /* Left child of root */
        I32 child_is_magic = SvAMAGIC(a[child]);
        ssize_t swap = root;                    /* Keeps track of child to swap with */
        I32 swap_is_magic = root_is_magic;
        SV *tmpsv = NULL;

        /* if the root is smaller than the left child
         *      then the swap is with the left child */
        if ( OUT_OF_ORDER(a,tmpsv,child_is_magic,swap_is_magic,child,swap,is_min) ) {
            swap = child;
            swap_is_magic = child_is_magic;
        }
        /* if there is a right child and the right child is larger than the root or the left child
         *      then the swap is with the right child */
        if (child+1 <= end) {
            child_is_magic = SvAMAGIC(a[child+1]);
            if ( OUT_OF_ORDER(a,tmpsv,child_is_magic,swap_is_magic,child+1,swap,is_min) ) {
                swap = child + 1;
                swap_is_magic = child_is_magic;
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
            root_is_magic = swap_is_magic;
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

#define FORCE_SCALAR(fakeop)                    \
STMT_START {                                    \
        SAVEOP();                               \
        Copy(PL_op, &fakeop, 1, OP);            \
        fakeop.op_flags = OPf_WANT_SCALAR;      \
        PL_op = &fakeop;                        \
} STMT_END

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

