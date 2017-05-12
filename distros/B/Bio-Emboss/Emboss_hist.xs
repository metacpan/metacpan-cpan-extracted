#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"
#include "ajhist.h"

MODULE = Bio::Emboss_hist		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajhist.c: automatically generated

void
ajHistDisplay (hist)
       const AjPHist hist

void
ajHistClose ()

void
ajHistDelete (phist)
       AjPHist& phist
    OUTPUT:
       phist

AjPHist
ajHistNew (numofsets, numofpoints)
       ajint numofsets
       ajint numofpoints
    OUTPUT:
       RETVAL

AjPHist
ajHistNewG (numofsets, numofpoints, graph)
       ajint numofsets
       ajint numofpoints
       AjPGraph graph
    OUTPUT:
       RETVAL

void
ajHistSetMultiTitle (hist, indexnum, title)
       AjPHist hist
       ajint indexnum
       const AjPStr title

void
ajHistSetMultiTitleC (hist, indexnum, title)
       AjPHist hist
       ajint indexnum
       const char * title

void
ajHistSetMultiXTitle (hist, indexnum, title)
       AjPHist hist
       ajint indexnum
       const AjPStr title

void
ajHistSetMultiXTitleC (hist, indexnum, title)
       AjPHist hist
       ajint indexnum
       const char * title

void
ajHistSetMultiYTitle (hist, indexnum, title)
       AjPHist hist
       ajint indexnum
       const AjPStr title

void
ajHistSetMultiYTitleC (hist, indexnum, title)
       AjPHist hist
       ajint indexnum
       const char * title

void
ajHistSetPtrToData (hist, indexnum, data)
       AjPHist hist
       ajint indexnum
       PLFLT& data
    OUTPUT:
       data

void
ajHistCopyData (hist, indexnum, data)
       AjPHist hist
       ajint indexnum
       const PLFLT* data

void
ajHistSetTitleC (hist, strng)
       AjPHist hist
       const char* strng

void
ajHistSetXAxisC (hist, strng)
       AjPHist hist
       const char* strng

void
ajHistSetYAxisLeftC (hist, strng)
       AjPHist hist
       const char* strng

void
ajHistSetYAxisRightC (hist, strng)
       AjPHist hist
       const char* strng

