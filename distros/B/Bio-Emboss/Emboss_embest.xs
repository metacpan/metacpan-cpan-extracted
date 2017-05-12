#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"
#include "embest.h"

MODULE = Bio::Emboss_embest		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embest.c: automatically generated

void
embEstSetDebug ()

void
embEstSetVerbose ()

void
embEstMatInit (match, mismatch, gap, neutral, pad_char)
       ajint match
       ajint mismatch
       ajint gap
       ajint neutral
       char pad_char

AjPSeq
embEstFindSpliceSites (genome, forward)
       const AjPSeq genome
       ajint forward
    OUTPUT:
       RETVAL

AjPSeq
embEstShuffleSeq (seq, in_place, seed)
       AjPSeq seq
       ajint in_place
       ajint& seed
    OUTPUT:
       RETVAL

void
embEstFreeAlign (ge)
       EmbPEstAlign& ge
    OUTPUT:
       ge

void
embEstPrintAlign (ofile, genome, est, ge, width)
       AjPFile ofile
       const AjPSeq genome
       const AjPSeq est
       const EmbPEstAlign ge
       ajint width

#ifdef HAVE_EMBOSS_4_1_0

EmbPEstAlign
embEstAlignNonRecursive (est, genome, gap_penalty, intron_penalty, splice_penalty, splice_sites, backtrack, needleman, init_path)
       const AjPSeq est
       const AjPSeq genome
       ajint gap_penalty
       ajint intron_penalty
       ajint splice_penalty
       const AjPSeq splice_sites
       ajint backtrack
       ajint needleman
       ajint init_path
    OUTPUT:
       RETVAL

void
embEstOutBlastStyle (blast, genome, est, ge, gap_penalty, intron_penalty, splice_penalty, gapped, reverse)
       AjPFile blast
       const AjPSeq genome
       const AjPSeq est
       const EmbPEstAlign ge
       ajint gap_penalty
       ajint intron_penalty
       ajint splice_penalty
       ajint gapped
       ajint reverse

#else

EmbPEstAlign
embEstAlignNonRecursive (est, genome, match, mismatch, gap_penalty, intron_penalty, splice_penalty, splice_sites, backtrack, needleman, init_path)
       const AjPSeq est
       const AjPSeq genome
       ajint match
       ajint mismatch
       ajint gap_penalty
       ajint intron_penalty
       ajint splice_penalty
       const AjPSeq splice_sites
       ajint backtrack
       ajint needleman
       ajint init_path
    OUTPUT:
       RETVAL

void
embEstOutBlastStyle (blast, genome, est, ge, match, mismatch, gap_penalty, intron_penalty, splice_penalty, gapped, reverse)
       AjPFile blast
       const AjPSeq genome
       const AjPSeq est
       const EmbPEstAlign ge
       ajint match
       ajint mismatch
       ajint gap_penalty
       ajint intron_penalty
       ajint splice_penalty
       ajint gapped
       ajint reverse

#endif

EmbPEstAlign
embEstAlignLinearSpace (est, genome, match, mismatch, gap_penalty, intron_penalty, splice_penalty, splice_sites, megabytes)
       const AjPSeq est
       const AjPSeq genome
       ajint match
       ajint mismatch
       ajint gap_penalty
       ajint intron_penalty
       ajint splice_penalty
       const AjPSeq splice_sites
       float megabytes
    OUTPUT:
       RETVAL

