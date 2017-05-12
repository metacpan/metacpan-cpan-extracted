#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embdmx		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embdmx.c: automatically generated

AjBool
embDmxScophitsToHitlist (in, out, iter)
       const AjPList in
       EmbPHitlist& out
       AjIList& iter
    OUTPUT:
       RETVAL
       out

AjBool
embDmxScophitToHit (to, from)
       EmbPHit& to
       const AjPScophit from
    OUTPUT:
       RETVAL
       to

AjBool
embDmxScophitsAccToHitlist (in, out, iter)
       const AjPList in
       EmbPHitlist& out
       AjIList& iter
    OUTPUT:
       RETVAL
       out

AjBool
embDmxHitsWrite (outf, hits, maxhits)
       AjPFile outf
       EmbPHitlist hits
       ajint maxhits
    OUTPUT:
       RETVAL

AjBool
embDmxScopToScophit (source, target)
       const AjPScop source
       AjPScophit& target
    OUTPUT:
       RETVAL
       target

AjBool
embDmxScopalgToScop (align, scop_arr, scop_dim, list)
       const AjPScopalg align
       AjPScop const* scop_arr
       ajint scop_dim
       AjPList& list
    OUTPUT:
       RETVAL
       list

AjBool
embDmxScophitsOverlapAcc (h1, h2, n)
       const AjPScophit h1
       const AjPScophit h2
       ajint n
    OUTPUT:
       RETVAL

AjBool
embDmxScophitsOverlap (h1, h2, n)
       const AjPScophit h1
       const AjPScophit h2
       ajint n
    OUTPUT:
       RETVAL

AjPScophit
embDmxScophitMerge (hit1, hit2)
       const AjPScophit hit1
       const AjPScophit hit2
    OUTPUT:
       RETVAL

AjBool
embDmxScophitMergeInsertOther (list, hit1, hit2)
       AjPList list
       AjPScophit hit1
       AjPScophit hit2
    OUTPUT:
       RETVAL
       hit1
       hit2

AjBool
embDmxScophitMergeInsertOtherTarget (list, hit1, hit2)
       AjPList list
       AjPScophit hit1
       AjPScophit hit2
    OUTPUT:
       RETVAL
       hit1
       hit2

AjBool
embDmxScophitMergeInsertOtherTargetBoth (list, hit1, hit2)
       AjPList list
       AjPScophit hit1
       AjPScophit hit2
    OUTPUT:
       RETVAL
       hit1
       hit2

AjBool
embDmxScophitMergeInsertThis (list, hit1, hit2, iter)
       const AjPList list
       AjPScophit hit1
       AjPScophit hit2
       AjIList iter
    OUTPUT:
       RETVAL
       hit1
       hit2

AjBool
embDmxScophitMergeInsertThisTarget (list, hit1, hit2, iter)
       const AjPList list
       AjPScophit hit1
       AjPScophit hit2
       AjIList iter
    OUTPUT:
       RETVAL
       hit1
       hit2

AjBool
embDmxScophitMergeInsertThisTargetBoth (list, hit1, hit2, iter)
       const AjPList list
       AjPScophit hit1
       AjPScophit hit2
       AjIList iter
    OUTPUT:
       RETVAL
       hit1
       hit2

AjBool
embDmxSeqNR (input, keep, nset, matrix, gapopen, gapextend, thresh, CheckGarbage)
       const AjPList input
       AjPUint& keep
       ajint& nset
       const AjPMatrixf matrix
       float gapopen
       float gapextend
       float thresh
       AjBool CheckGarbage
    OUTPUT:
       RETVAL
       keep
       nset

AjBool
embDmxSeqNRRange (input, keep, nset, matrix, gapopen, gapextend, threshlow, threshup, CheckGarbage)
       const AjPList input
       AjPUint& keep
       ajint& nset
       const AjPMatrixf matrix
       float gapopen
       float gapextend
       float threshlow
       float threshup
       AjBool CheckGarbage
    OUTPUT:
       RETVAL
       keep
       nset

AjBool
embDmxSeqCompall (input, scores, matrix, gapopen, gapextend)
       const AjPList input
       AjPFloat2d& scores
       const AjPMatrixf matrix
       float gapopen
       float gapextend
    OUTPUT:
       RETVAL
       scores

AjPList
embDmxScophitReadAllFasta (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjBool
embDmxHitlistToScophits (in, out)
       const AjPList in
       AjPList out
    OUTPUT:
       RETVAL
       out

