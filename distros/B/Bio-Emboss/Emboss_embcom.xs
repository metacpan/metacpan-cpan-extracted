#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embcom		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embcom.c: automatically generated

#ifdef HAVE_EMBOSS_4_1_0

void
embComComplexity (seq, name, len, jmin, jmax, l, step, sim, freq, omnia, fp, pf, print, MedValue)
       const char * seq
       const char * name
       ajint len
       ajint jmin
       ajint jmax
       ajint l
       ajint step
       ajint sim
       ajint freq
       ajint omnia
       AjPFile fp
       AjPFile pf
       ajint print
       float & MedValue
    OUTPUT:
       MedValue

#else

void
embComComplexity (seq, name, len, jmin, jmax, l, step, sim, freq, omnia, fp, pf, print, num_seq, MedValue)
       const char * seq
       const char * name
       ajint len
       ajint jmin
       ajint jmax
       ajint l
       ajint step
       ajint sim
       ajint freq
       ajint omnia
       AjPFile fp
       AjPFile pf
       ajint print
       ajint num_seq
       float & MedValue
    OUTPUT:
       MedValue

#endif

void
embComWriteFile (fp, jmin, jmax, lwin, step, sim)
       AjPFile fp
       ajint jmin
       ajint jmax
       ajint lwin
       ajint step
       ajint sim

void
embComWriteValueOfSeq (fp, n, name, len, MedValue)
       AjPFile fp
       ajint n
       const char * name
       ajint len
       float MedValue

void
embComUnused ()

