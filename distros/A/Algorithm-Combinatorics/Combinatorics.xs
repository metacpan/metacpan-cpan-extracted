/**
 * These subroutines implement the actual iterators.
 *
 * The real combinatorics are done in-place on a private array of indices
 * that is guaranteed to hold integers. We cannot assume they are IVs though,
 * because in a few places in the Perl side there's some simple arithmetic
 * that is enough to give NVs in 5.6.x.
 *
 * Once the next tuple has been computed the corresponding slice of data is
 * copied in the Perl side. I tried to slice data here in C but it was in
 * fact slightly slower. I think we would need to pass aliases to gain
 * some more speed.
 *
 * All the subroutines return -1 when the sequence has been exhausted.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define SETIV(av, i, n) (sv_setiv(*av_fetch(av, i, 0), n))
#define GETIV(av, i)    (SvIV(*av_fetch(av, i, 0)))
#define INCR(av, i)     (SETIV(av, i, 1 + GETIV(av, i)))
#define GETAV(avptr)    ((AV*) SvRV(avptr))


/**
 * Swap the ith and jth elements in av.
 *
 * Assumes av contains IVs.
 */
void __swap(AV* av, int i, int j)
{
    IV tmp = GETIV(av, i);
    SETIV(av, i, GETIV(av, j));
    SETIV(av, j, tmp);
}

/**
 * This implementation emulates what we do by hand. It is faster than
 * Algorithm T from [2], which gives another lexicographic ordering.
 */
int __next_combination(SV* tuple_avptr, int max_n)
{
    AV* tuple = GETAV(tuple_avptr);
    int i, j;
    IV  n;
    I32 offset, len_tuple;
    SV* e;

    len_tuple = av_len(tuple);
    offset = max_n - len_tuple;
    for (i = len_tuple; i >= 0; --i) {
        e = *av_fetch(tuple, i, 0);
        n = SvIV(e);
        if (n < i + offset) {
            sv_setiv(e, ++n);
            for (j = i+1; j <= len_tuple; ++j)
                SETIV(tuple, j, ++n);
            return i;
        }
    }

    return -1;
}


/**
 * This provisional implementation emulates what we do by hand.
 */
int __next_combination_with_repetition(SV* tuple_avptr, int max_n)
{
    AV* tuple = GETAV(tuple_avptr);
    int i, j;
    IV  n;
    I32 len_tuple;

    len_tuple = av_len(tuple);
    for (i = len_tuple; i >= 0; --i) {
        n = GETIV(tuple, i);
        if (n < max_n) {
            ++n;
            for (j = i; j <= len_tuple; ++j)
                SETIV(tuple, j, n);
            return i;
        }
    }

    return -1;
}


/**
 * This provisional implementation emulates what we do by hand, keeping
 * and array of booleans (used) to keep track of the indices in use.
 * That is, used[n] == 1 if and only if tuple[i] == n for some i.
 *
 */
int __next_variation(SV* tuple_avptr, SV* used_avptr, int max_n)
{
    AV* tuple = GETAV(tuple_avptr);
    AV* used  = GETAV(used_avptr);
    int i, j;
    I32 len_tuple;
    SV* e;
    IV  n;

    len_tuple = av_len(tuple);
    for (i = len_tuple; i >= 0; --i) {
        /* from right to left, find the first position that can be incremented */
        e = *av_fetch(tuple, i, 0);
        n = SvIV(e);
        SETIV(used, n, 0);
        while (++n <= max_n) {
            if (!GETIV(used, n)) {
                /* if we get here we nececessarily exit the subrutine, so forget about the outer while and for */
                sv_setiv(e, n);
                SETIV(used, n, 1);
                for (j = i+1; j <= len_tuple; ++j) {
                    /* from there to the right, fill the tuple with the lowest available numbers */
                    n = -1;
                    while (++n <= max_n) {
                         if (!GETIV(used, n)) {
                              SETIV(tuple, j, n);
                              SETIV(used, n, 1);
                              break;
                         }
                    }
                }
                return i;
             }
        }
    }

    return -1;
}

/**
 * This provisional implementation emulates what we do by hand.
 */
int __next_variation_with_repetition(SV* tuple_avptr, int max_n)
{
    AV* tuple = GETAV(tuple_avptr);
    int i;
    I32 len_tuple;
    SV* e;

    len_tuple = av_len(tuple);
    for (i = len_tuple; i >= 0; --i) {
        e = *av_fetch(tuple, i, 0);
        if (SvIV(e) < max_n) {
            sv_setiv(e, 1 + SvIV(e));
            return i;
        }
        sv_setiv(e, 0);
    }

    return -1;
}

/**
 * Algorithm H (Loopless reflected mixed-radix Gray generation), from [1].
 *
 * [Initialize.] and [Visit.] are done in the Perl side.
 */
int __next_variation_with_repetition_gray_code(SV* tuple_avptr, SV* f_avptr, SV* o_avptr, int max_m)
{
    AV* tuple = GETAV(tuple_avptr);
    AV* f     = GETAV(f_avptr);
    AV* o     = GETAV(o_avptr);
    I32 n;
    IV j, aj;

    n = av_len(tuple) + 1;

    /* [Choose j.] */
    j = GETIV(f, 0);
    SETIV(f, 0, 0);

    /* [Change coordinate j.] */
    if (j == n)
        return -1;
    else
        SETIV(tuple, j, GETIV(tuple, j) + GETIV(o, j));

    /* [Reflect?] */
    aj = GETIV(tuple, j);
    if (aj == 0 || aj == max_m) {
        SETIV(o, j, -GETIV(o, j));
        SETIV(f, j, GETIV(f, j+1));
        SETIV(f, j+1, j+1);
    }

    return j;
}


/**
 * Algorithm L (Lexicographic permutation generation), adapted from [1].
 * I used "h" instead of the letter "l" for the sake of readability.
 *
 * This algorithm goes back at least to the 18th century, and has been rediscovered
 * ever since.
 */
int __next_permutation(SV* tuple_avptr)
{
    AV* tuple = GETAV(tuple_avptr);
    I32 max_n, j, h, k;
    IV aj;

    max_n = av_len(tuple);

    /* [Find j.] Find the element a(j) behind the longest decreasing tail. */
    for (j = max_n-1; j >= 0 && GETIV(tuple, j) > GETIV(tuple, j+1); --j)
        ;
    if (j == -1)
        return -1;

    /* [Increase a(j).] Find the rightmost element a(h) greater than a(j) and swap them. */
    aj = GETIV(tuple, j);
    for (h = max_n; aj > GETIV(tuple, h); --h)
        ;
    __swap(tuple, j, h);

    /* [Reverse a(j+1)...a(max_n)] Reverse the tail. */
    for (k = j+1, h = max_n; k < h; ++k, --h)
        __swap(tuple, k, h);

    /* Done. */
    return 1;
}


int __next_permutation_heap(SV* a_avptr, SV* c_avptr)
{
    AV* a = GETAV(a_avptr);
    AV* c = GETAV(c_avptr);
    int k;
    I32 n;
    IV ck;

    n = av_len(a) + 1;

    for (k = 1, ck = GETIV(c, k); ck == k; ++k, ck = GETIV(c, k))
        SETIV(c, k, 0);

    if (k == n)
        return -1;

    ++ck;
    SETIV(c, k, ck);

    k % 2 == 0 ? __swap(a, k, 0) : __swap(a, k, ck-1);

    return k;
}


/**
 * The only algorithms I have found by now are either recursive, or a
 * naive wrapper around permutations() that loops over all of them and
 * discards the ones with fixed-points.
 *
 * We take here a mixed-approach, which consists on starting with the
 * algorithm in __next_permutation() and tweak a couple of places that
 * allow us to skip a significant number of permutations sometimes.
 *
 * Benchmarking shows this subroutine makes derangements() more than
 * two and a half times faster than permutations() for n = 8.
 */
int __next_derangement(SV* tuple_avptr)
{
    AV* tuple = GETAV(tuple_avptr);
    I32 max_n, min_j, j, h, k;
    IV aj;

    max_n = av_len(tuple);
    min_j = max_n;

    THERE_IS_A_FIXED_POINT:
    /* Find the element a(j) behind the longest decreasing tail. */
    for (j = max_n-1; j >= 0 && GETIV(tuple, j) > GETIV(tuple, j+1); --j)
          ;
    if (j == -1)
        return -1;

    if (min_j > j)
        min_j = j;

    /* Find the rightmost element a(h) greater than a(j) and swap them. */
    aj = GETIV(tuple, j);
    for (h = max_n; aj > GETIV(tuple, h); --h)
        ;
    __swap(tuple, j, h);

    /* If a(h) was j leave the tail in decreasing order and try again. */
    if (GETIV(tuple, j) == j)
        goto THERE_IS_A_FIXED_POINT;

    /* I tried an alternative approach that would in theory avoid the
    generation of some permutations with fixed-points: keeping track of
    the leftmost fixed-point, and reversing the elements to its right.
    But benchmarks up to n = 11 showed no difference whatsoever.
    Thus, I left this version, which is simpler.

    That n = 11 does not mean there was a difference for n = 12, it
    means I stopped benchmarking at n = 11. */

    /* Otherwise reverse the tail and return if there's no fixed point. */
    for (k = j+1, h = max_n; k < h; ++k, --h)
        __swap(tuple, k, h);
    for (k = max_n; k > min_j; --k)
        if (GETIV(tuple, k) == k)
            goto THERE_IS_A_FIXED_POINT;

    return 1;
}

/*
 * This is a transcription of algorithm 3 from [3].
 *
 * It is a classical approach based on restricted growth strings, which are
 * introduced in the paper.
 */
int __next_partition(SV* k_avptr, SV* M_avptr)
{
    AV* k = GETAV(k_avptr); /* follows notation in [3] */
    AV* M = GETAV(M_avptr); /* follows notation in [3] */
    int i, j;
    IV mi;
    I32 len_k;

    len_k = av_len(k);
    for (i = len_k; i > 0; --i) {
        if (GETIV(k, i) <= GETIV(M, i-1)) {
            INCR(k, i);

            if (GETIV(k, i) > GETIV(M, i))
                SETIV(M, i, GETIV(k, i));

            mi = GETIV(M, i);
            for (j = i+1; j <= len_k; ++j) {
                SETIV(k, j, 0);
                SETIV(M, j, mi);
            }
            return i;
        }
    }

    return -1;
}

/*
 * This is a transcription of algorithm 8 from [3].
 *
 * It is an adaptation of the previous one.
 */
int __next_partition_of_size_p(SV* k_avptr, SV* M_avptr, int p)
{
    AV* k = GETAV(k_avptr); /* follows notation in [3] */
    AV* M = GETAV(M_avptr); /* follows notation in [3] */
    int i, j;
    IV mi, x;
    I32 len_k, n_minus_p;

    len_k = av_len(k);
    for (i = len_k; i > 0; --i) {
        if (GETIV(k, i) < p-1 && GETIV(k, i) <= GETIV(M, i-1)) {
            INCR(k, i);

            if (GETIV(k, i) > GETIV(M, i))
                SETIV(M, i, GETIV(k, i));

            n_minus_p = len_k + 1 - p;
            mi = GETIV(M, i);
            x = n_minus_p + mi;
            for (j = i+1; j <= x; ++j) {
                SETIV(k, j, 0);
                SETIV(M, j, mi);
            }
            for (j = x+1; j <= len_k; ++j) {
                SETIV(k, j, j - n_minus_p);
                SETIV(M, j, j - n_minus_p);
            }
            return i;
        }
    }

    return -1;
}

/*
 * This subroutine has been copied from List::PowerSet.
 *
 * It uses a vector of bits "odometer" to indicate which elements to include
 * in each iteration. The odometer runs and eventually exhausts all possible
 * combinations of 0s and 1s.
 */
AV* __next_subset(SV* data_avptr, SV* odometer_avptr)
{
    AV* data     = GETAV(data_avptr);
    AV* odometer = GETAV(odometer_avptr);
    I32 len_data = av_len(data);
    AV* subset   = newAV();
    IV adjust    = 1;
    int i;
    IV n;

    for (i = 0; i <= len_data; ++i) {
        n = GETIV(odometer, i);
        if (n) {
            av_push(subset, newSVsv(*av_fetch(data, i, 0)));
        }
        if (adjust) {
            adjust = 1 - n;
            SETIV(odometer, i, adjust);
        }
    }

    return (AV*) sv_2mortal((SV*) subset);
}

/** -------------------------------------------------------------------
 *
 * XS stuff starts here.
 *
 */

MODULE = Algorithm::Combinatorics   PACKAGE = Algorithm::Combinatorics
PROTOTYPES: DISABLE

int
__next_combination(tuple_avptr, max_n)
    SV* tuple_avptr
    int max_n

int
__next_combination_with_repetition(tuple_avptr, max_n)
    SV* tuple_avptr
    int max_n

int
__next_variation(tuple_avptr, used_avptr, max_n)
    SV* tuple_avptr
    SV* used_avptr
    int max_n

int
__next_variation_with_repetition(tuple_avptr, max_n)
    SV* tuple_avptr
    int max_n

int
__next_variation_with_repetition_gray_code(tuple_avptr, f_avptr, o_avptr, max_m)
    SV* tuple_avptr
    SV* f_avptr
    SV* o_avptr
    int max_m

int
__next_permutation(tuple_avptr)
    SV* tuple_avptr

int
__next_permutation_heap(a_avptr, c_avptr)
    SV* a_avptr
    SV* c_avptr

int
__next_derangement(tuple_avptr)
    SV* tuple_avptr

int
__next_partition(k_avptr, M_avptr)
    SV* k_avptr
    SV* M_avptr

int
__next_partition_of_size_p(k_avptr, M_avptr, p)
    SV* k_avptr
    SV* M_avptr
    int p

AV*
__next_subset(data_avptr, odometer_avptr)
    SV* data_avptr
    SV* odometer_avptr
