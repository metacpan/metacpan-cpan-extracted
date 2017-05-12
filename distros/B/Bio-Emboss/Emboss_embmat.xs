#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embmat		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embmat.c: automatically generated

void
embMatMatchDel (s)
       EmbPMatMatch & s
    OUTPUT:
       s

void
embMatPrintsInit (fp)
       AjPFile & fp
    OUTPUT:
       fp

EmbPMatPrints
embMatProtReadInt (fp)
       AjPFile fp
    OUTPUT:
       RETVAL

void
embMatProtDelInt (s)
       EmbPMatPrints & s
    OUTPUT:
       s

ajint
embMatProtScanInt (s, n, m, l, all, ordered, overlap)
       const AjPStr s
       const AjPStr n
       const EmbPMatPrints m
       AjPList & l
       AjBool & all
       AjBool & ordered
       AjBool overlap
    OUTPUT:
       RETVAL
       l
       all
       ordered

