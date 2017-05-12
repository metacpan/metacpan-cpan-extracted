#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

#include "ajhist.h"

MODULE = Bio::Emboss_hist_deprecated		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajhist.h: automatically generated

void
ajHistSetBlackandWhite (hist, set)
       AjPHist  hist
       AjBool set

void
ajHistSetColour (hist, index, colour)
       AjPHist  hist
       ajint index
       ajint colour

void
ajHistSetPattern (hist, index, style)
       AjPHist  hist
       ajint index
       ajint style
