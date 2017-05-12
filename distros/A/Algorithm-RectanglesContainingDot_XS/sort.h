/*    pp_sort.c
 *
 *    Copyright (C) 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999,
 *    2000, 2001, 2002, 2003, 2004, 2005, by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 *   ...they shuffled back towards the rear of the line. 'No, not at the
 *   rear!'  the slave-driver shouted. 'Three files up. And stay there...
 */

/* This file contains pp ("push/pop") functions that
 * execute the opcodes that make up a perl program. A typical pp function
 * expects to find its arguments on the stack, and usually pushes its
 * results onto the stack, hence the 'pp' terminology. Each OP structure
 * contains a pointer to the relevant pp_foo() function.
 *
 * This particular file just contains pp_sort(), which is complex
 * enough to merit its own file! See the other pp*.c files for the rest of
 * the pp_ functions.
 */

#if defined(UNDER_CE)
/* looks like 'small' is reserved word for WINCE (or somesuch)*/
#define	small xsmall
#endif

#ifndef SMALLSORT
#define	SMALLSORT (200)
#endif

/*
 * The mergesort implementation is by Peter M. Mcilroy <pmcilroy@lucent.com>.
 *
 * The original code was written in conjunction with BSD Computer Software
 * Research Group at University of California, Berkeley.
 *
 * See also: "Optimistic Merge Sort" (SODA '92)
 *
 * The integration to Perl is by John P. Linderman <jpl@research.att.com>.
 *
 * The code can be distributed under the same terms as Perl itself.
 *
 */

/* Binary merge internal sort, with a few special mods
** for the special perl environment it now finds itself in.
**
** Things that were once options have been hotwired
** to values suitable for this use.  In particular, we'll always
** initialize looking for natural runs, we'll always produce stable
** output, and we'll always do Peter McIlroy's binary merge.
*/

/* Pointer types for arithmetic and storage and convenience casts */

#define	GPTP(P)	((SV **)(P))
#define GPPP(P) ((SV ***)(P))


/* byte offset from pointer P to (larger) pointer Q */
#define	BYTEOFF(P, Q) (((char *)(Q)) - ((char *)(P)))

#define PSIZE sizeof(SV *)

/* If PSIZE is power of 2, make PSHIFT that power, if that helps */

#ifdef	PSHIFT
#define	PNELEM(P, Q)	(BYTEOFF(P,Q) >> (PSHIFT))
#define	PNBYTE(N)	((N) << (PSHIFT))
#define	PINDEX(P, N)	(GPTP((char *)(P) + PNBYTE(N)))
#else
/* Leave optimization to compiler */
#define	PNELEM(P, Q)	(GPTP(Q) - GPTP(P))
#define	PNBYTE(N)	((N) * (PSIZE))
#define	PINDEX(P, N)	(GPTP(P) + (N))
#endif

/* Pointer into other corresponding to pointer into this */
#define	POTHER(P, THIS, OTHER) GPTP(((char *)(OTHER)) + BYTEOFF(THIS,P))

#define FROMTOUPTO(src, dst, lim) do *dst++ = *src++; while(src<lim)


/* Runs are identified by a pointer in the auxilliary list.
** The pointer is at the start of the list,
** and it points to the start of the next list.
** NEXT is used as an lvalue, too.
*/

#define	NEXT(P)		(*GPPP(P))


/* PTHRESH is the minimum number of pairs with the same sense to justify
** checking for a run and extending it.  Note that PTHRESH counts PAIRS,
** not just elements, so PTHRESH == 8 means a run of 16.
*/

#define	PTHRESH (8)

/* RTHRESH is the number of elements in a run that must compare low
** to the low element from the opposing run before we justify
** doing a binary rampup instead of single stepping.
** In random input, N in a row low should only happen with
** probability 2^(1-N), so we can risk that we are dealing
** with orderly input without paying much when we aren't.
*/

#define RTHRESH (6)


/*
** Overview of algorithm and variables.
** The array of elements at list1 will be organized into runs of length 2,
** or runs of length >= 2 * PTHRESH.  We only try to form long runs when
** PTHRESH adjacent pairs compare in the same way, suggesting overall order.
**
** Unless otherwise specified, pair pointers address the first of two elements.
**
** b and b+1 are a pair that compare with sense ``sense''.
** b is the ``bottom'' of adjacent pairs that might form a longer run.
**
** p2 parallels b in the list2 array, where runs are defined by
** a pointer chain.
**
** t represents the ``top'' of the adjacent pairs that might extend
** the run beginning at b.  Usually, t addresses a pair
** that compares with opposite sense from (b,b+1).
** However, it may also address a singleton element at the end of list1,
** or it may be equal to ``last'', the first element beyond list1.
**
** r addresses the Nth pair following b.  If this would be beyond t,
** we back it off to t.  Only when r is less than t do we consider the
** run long enough to consider checking.
**
** q addresses a pair such that the pairs at b through q already form a run.
** Often, q will equal b, indicating we only are sure of the pair itself.
** However, a search on the previous cycle may have revealed a longer run,
** so q may be greater than b.
**
** p is used to work back from a candidate r, trying to reach q,
** which would mean b through r would be a run.  If we discover such a run,
** we start q at r and try to push it further towards t.
** If b through r is NOT a run, we detect the wrong order at (p-1,p).
** In any event, after the check (if any), we have two main cases.
**
** 1) Short run.  b <= q < p <= r <= t.
**	b through q is a run (perhaps trivial)
**	q through p are uninteresting pairs
**	p through r is a run
**
** 2) Long run.  b < r <= q < t.
**	b through q is a run (of length >= 2 * PTHRESH)
**
** Note that degenerate cases are not only possible, but likely.
** For example, if the pair following b compares with opposite sense,
** then b == q < p == r == t.
*/


static IV
dynprep(pTHX_ SV **list1, SV **list2, size_t nmemb, SVCOMPARE_t cmp)
{
    I32 sense;
    register SV **b, **p, **q, **t, **p2;
    register SV *c, **last, **r;
    SV **savep;
    IV runs = 0;

    b = list1;
    last = PINDEX(b, nmemb);
    sense = (cmp(aTHX_ *b, *(b+1)) > 0);
    for (p2 = list2; b < last; ) {
	/* We just started, or just reversed sense.
	** Set t at end of pairs with the prevailing sense.
	*/
	for (p = b+2, t = p; ++p < last; t = ++p) {
	    if ((cmp(aTHX_ *t, *p) > 0) != sense) break;
	}
	q = b;
	/* Having laid out the playing field, look for long runs */
	do {
	    p = r = b + (2 * PTHRESH);
	    if (r >= t) p = r = t;	/* too short to care about */
	    else {
		while (((cmp(aTHX_ *(p-1), *p) > 0) == sense) &&
		       ((p -= 2) > q));
		if (p <= q) {
		    /* b through r is a (long) run.
		    ** Extend it as far as possible.
		    */
		    p = q = r;
		    while (((p += 2) < t) &&
			   ((cmp(aTHX_ *(p-1), *p) > 0) == sense)) q = p;
		    r = p = q + 2;	/* no simple pairs, no after-run */
		}
	    }
	    if (q > b) {		/* run of greater than 2 at b */
		savep = p;
		p = q += 2;
		/* pick up singleton, if possible */
		if ((p == t) &&
		    ((t + 1) == last) &&
		    ((cmp(aTHX_ *(p-1), *p) > 0) == sense))
		    savep = r = p = q = last;
		p2 = NEXT(p2) = p2 + (p - b); ++runs;
		if (sense) while (b < --p) {
		    c = *b;
		    *b++ = *p;
		    *p = c;
		}
		p = savep;
	    }
	    while (q < p) {		/* simple pairs */
		p2 = NEXT(p2) = p2 + 2; ++runs;
		if (sense) {
		    c = *q++;
		    *(q-1) = *q;
		    *q++ = c;
		} else q += 2;
	    }
	    if (((b = p) == t) && ((t+1) == last)) {
		NEXT(p2) = p2 + 1; ++runs;
		b++;
	    }
	    q = r;
	} while (b < t);
	sense = !sense;
    }
    return runs;
}


/* The original merge sort, in use since 5.7, was as fast as, or faster than,
 * qsort on many platforms, but slower than qsort, conspicuously so,
 * on others.  The most likely explanation was platform-specific
 * differences in cache sizes and relative speeds.
 *
 * The quicksort divide-and-conquer algorithm guarantees that, as the
 * problem is subdivided into smaller and smaller parts, the parts
 * fit into smaller (and faster) caches.  So it doesn't matter how
 * many levels of cache exist, quicksort will "find" them, and,
 * as long as smaller is faster, take advanatge of them.
 *
 * By contrast, consider how the original mergesort algorithm worked.
 * Suppose we have five runs (each typically of length 2 after dynprep).
 * 
 * pass               base                        aux
 *  0              1 2 3 4 5
 *  1                                           12 34 5
 *  2                1234 5
 *  3                                            12345
 *  4                 12345
 *
 * Adjacent pairs are merged in "grand sweeps" through the input.
 * This means, on pass 1, the records in runs 1 and 2 aren't revisited until
 * runs 3 and 4 are merged and the runs from run 5 have been copied.
 * The only cache that matters is one large enough to hold *all* the input.
 * On some platforms, this may be many times slower than smaller caches.
 *
 * The following pseudo-code uses the same basic merge algorithm,
 * but in a divide-and-conquer way.
 *
 * # merge $runs runs at offset $offset of list $list1 into $list2.
 * # all unmerged runs ($runs == 1) originate in list $base.
 * sub mgsort2 {
 *     my ($offset, $runs, $base, $list1, $list2) = @_;
 *
 *     if ($runs == 1) {
 *         if ($list1 is $base) copy run to $list2
 *         return offset of end of list (or copy)
 *     } else {
 *         $off2 = mgsort2($offset, $runs-($runs/2), $base, $list2, $list1)
 *         mgsort2($off2, $runs/2, $base, $list2, $list1)
 *         merge the adjacent runs at $offset of $list1 into $list2
 *         return the offset of the end of the merged runs
 *     }
 * }
 * mgsort2(0, $runs, $base, $aux, $base);
 *
 * For our 5 runs, the tree of calls looks like 
 *
 *           5
 *      3        2
 *   2     1   1   1
 * 1   1
 *
 * 1   2   3   4   5
 *
 * and the corresponding activity looks like
 *
 * copy runs 1 and 2 from base to aux
 * merge runs 1 and 2 from aux to base
 * (run 3 is where it belongs, no copy needed)
 * merge runs 12 and 3 from base to aux
 * (runs 4 and 5 are where they belong, no copy needed)
 * merge runs 4 and 5 from base to aux
 * merge runs 123 and 45 from aux to base
 *
 * Note that we merge runs 1 and 2 immediately after copying them,
 * while they are still likely to be in fast cache.  Similarly,
 * run 3 is merged with run 12 while it still may be lingering in cache.
 * This implementation should therefore enjoy much of the cache-friendly
 * behavior that quicksort does.  In addition, it does less copying
 * than the original mergesort implementation (only runs 1 and 2 are copied)
 * and the "balancing" of merges is better (merged runs comprise more nearly
 * equal numbers of original runs).
 *
 * The actual cache-friendly implementation will use a pseudo-stack
 * to avoid recursion, and will unroll processing of runs of length 2,
 * but it is otherwise similar to the recursive implementation.
 */

typedef struct {
    IV	offset;		/* offset of 1st of 2 runs at this level */
    IV	runs;		/* how many runs must be combined into 1 */
} off_runs;		/* pseudo-stack element */

static void 
sortsv(pTHX_ SV **base, size_t nmemb, SVCOMPARE_t cmp)
{
    IV i, run, runs, offset;
    I32 sense, level;
    int iwhich;
    register SV **f1, **f2, **t, **b, **p, **tp2, **l1, **l2, **q;
    SV **aux, **list1, **list2;
    SV **p1;
    SV * small[SMALLSORT];
    SV **which[3];
    off_runs stack[60], *stackp;
    SVCOMPARE_t savecmp = 0;

    if (nmemb <= 1) return;			/* sorted trivially */

    if (nmemb <= SMALLSORT) aux = small;	/* use stack for aux array */
    else { New(799,aux,nmemb,SV *); }		/* allocate auxilliary array */
    level = 0;
    stackp = stack;
    stackp->runs = dynprep(aTHX_ base, aux, nmemb, cmp);
    stackp->offset = offset = 0;
    which[0] = which[2] = base;
    which[1] = aux;
    for (;;) {
	/* On levels where both runs have be constructed (stackp->runs == 0),
	 * merge them, and note the offset of their end, in case the offset
	 * is needed at the next level up.  Hop up a level, and,
	 * as long as stackp->runs is 0, keep merging.
	 */
	if ((runs = stackp->runs) == 0) {
	    iwhich = level & 1;
	    list1 = which[iwhich];		/* area where runs are now */
	    list2 = which[++iwhich];		/* area for merged runs */
	    do {
		offset = stackp->offset;
		f1 = p1 = list1 + offset;		/* start of first run */
		p = tp2 = list2 + offset;	/* where merged run will go */
		t = NEXT(p);			/* where first run ends */
		f2 = l1 = POTHER(t, list2, list1); /* ... on the other side */
		t = NEXT(t);			/* where second runs ends */
		l2 = POTHER(t, list2, list1);	/* ... on the other side */
		offset = PNELEM(list2, t);
		while (f1 < l1 && f2 < l2) {
		    /* If head 1 is larger than head 2, find ALL the elements
		    ** in list 2 strictly less than head1, write them all,
		    ** then head 1.  Then compare the new heads, and repeat,
		    ** until one or both lists are exhausted.
		    **
		    ** In all comparisons (after establishing
		    ** which head to merge) the item to merge
		    ** (at pointer q) is the first operand of
		    ** the comparison.  When we want to know
		    ** if ``q is strictly less than the other'',
		    ** we can't just do
		    **    cmp(q, other) < 0
		    ** because stability demands that we treat equality
		    ** as high when q comes from l2, and as low when
		    ** q was from l1.  So we ask the question by doing
		    **    cmp(q, other) <= sense
		    ** and make sense == 0 when equality should look low,
		    ** and -1 when equality should look high.
		    */


		    if (cmp(aTHX_ *f1, *f2) <= 0) {
			q = f2; b = f1; t = l1;
			sense = -1;
		    } else {
			q = f1; b = f2; t = l2;
			sense = 0;
		    }


		    /* ramp up
		    **
		    ** Leave t at something strictly
		    ** greater than q (or at the end of the list),
		    ** and b at something strictly less than q.
		    */
		    for (i = 1, run = 0 ;;) {
			if ((p = PINDEX(b, i)) >= t) {
			    /* off the end */
			    if (((p = PINDEX(t, -1)) > b) &&
				(cmp(aTHX_ *q, *p) <= sense))
				 t = p;
			    else b = p;
			    break;
			} else if (cmp(aTHX_ *q, *p) <= sense) {
			    t = p;
			    break;
			} else b = p;
			if (++run >= RTHRESH) i += i;
		    }


		    /* q is known to follow b and must be inserted before t.
		    ** Increment b, so the range of possibilities is [b,t).
		    ** Round binary split down, to favor early appearance.
		    ** Adjust b and t until q belongs just before t.
		    */

		    b++;
		    while (b < t) {
			p = PINDEX(b, (PNELEM(b, t) - 1) / 2);
			if (cmp(aTHX_ *q, *p) <= sense) {
			    t = p;
			} else b = p + 1;
		    }


		    /* Copy all the strictly low elements */

		    if (q == f1) {
			FROMTOUPTO(f2, tp2, t);
			*tp2++ = *f1++;
		    } else {
			FROMTOUPTO(f1, tp2, t);
			*tp2++ = *f2++;
		    }
		}


		/* Run out remaining list */
		if (f1 == l1) {
		       if (f2 < l2) FROMTOUPTO(f2, tp2, l2);
		} else              FROMTOUPTO(f1, tp2, l1);
		p1 = NEXT(p1) = POTHER(tp2, list2, list1);

		if (--level == 0) goto done;
		--stackp;
		t = list1; list1 = list2; list2 = t;	/* swap lists */
	    } while ((runs = stackp->runs) == 0);
	}


	stackp->runs = 0;		/* current run will finish level */
	/* While there are more than 2 runs remaining,
	 * turn them into exactly 2 runs (at the "other" level),
	 * each made up of approximately half the runs.
	 * Stack the second half for later processing,
	 * and set about producing the first half now.
	 */
	while (runs > 2) {
	    ++level;
	    ++stackp;
	    stackp->offset = offset;
	    runs -= stackp->runs = runs / 2;
	}
	/* We must construct a single run from 1 or 2 runs.
	 * All the original runs are in which[0] == base.
	 * The run we construct must end up in which[level&1].
	 */
	iwhich = level & 1;
	if (runs == 1) {
	    /* Constructing a single run from a single run.
	     * If it's where it belongs already, there's nothing to do.
	     * Otherwise, copy it to where it belongs.
	     * A run of 1 is either a singleton at level 0,
	     * or the second half of a split 3.  In neither event
	     * is it necessary to set offset.  It will be set by the merge
	     * that immediately follows.
	     */
	    if (iwhich) {	/* Belongs in aux, currently in base */
		f1 = b = PINDEX(base, offset);	/* where list starts */
		f2 = PINDEX(aux, offset);	/* where list goes */
		t = NEXT(f2);			/* where list will end */
		offset = PNELEM(aux, t);	/* offset thereof */
		t = PINDEX(base, offset);	/* where it currently ends */
		FROMTOUPTO(f1, f2, t);		/* copy */
		NEXT(b) = t;			/* set up parallel pointer */
	    } else if (level == 0) goto done;	/* single run at level 0 */
	} else {
	    /* Constructing a single run from two runs.
	     * The merge code at the top will do that.
	     * We need only make sure the two runs are in the "other" array,
	     * so they'll end up in the correct array after the merge.
	     */
	    ++level;
	    ++stackp;
	    stackp->offset = offset;
	    stackp->runs = 0;	/* take care of both runs, trigger merge */
	    if (!iwhich) {	/* Merged runs belong in aux, copy 1st */
		f1 = b = PINDEX(base, offset);	/* where first run starts */
		f2 = PINDEX(aux, offset);	/* where it will be copied */
		t = NEXT(f2);			/* where first run will end */
		offset = PNELEM(aux, t);	/* offset thereof */
		p = PINDEX(base, offset);	/* end of first run */
		t = NEXT(t);			/* where second run will end */
		t = PINDEX(base, PNELEM(aux, t)); /* where it now ends */
		FROMTOUPTO(f1, f2, t);		/* copy both runs */
		NEXT(b) = p;			/* paralled pointer for 1st */
		NEXT(p) = t;			/* ... and for second */
	    }
	}
    }
done:
    if (aux != small) Safefree(aux);	/* free iff allocated */
    return;
}
