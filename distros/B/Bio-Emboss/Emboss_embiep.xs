#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embiep		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embiep.c: automatically generated

double
embIepPhToHconc (pH)
       double pH
    OUTPUT:
       RETVAL

double
embIepPhFromHconc (H)
       double H
    OUTPUT:
       RETVAL

double
embIepPkToK (pK)
       double pK
    OUTPUT:
       RETVAL

double
embIepPkFromK (K)
       double K
    OUTPUT:
       RETVAL

void
embIepPkRead ()

void
embIepCompC (s, amino, sscount, modlysine, c)
       const char * s
       ajint amino
       ajint sscount
       ajint modlysine
       ajint & c
    OUTPUT:
       c

void
embIepCompS (str, amino, sscount, modlysine, c)
       const AjPStr str
       ajint amino
       ajint sscount
       ajint modlysine
       ajint & c
    OUTPUT:
       c

void
embIepCalcK (K)
       double & K
    OUTPUT:
       K

void
embIepGetProto (K, c, op, H, pro)
       const double * K
       const ajint * c
       ajint & op
       double H
       double & pro
    OUTPUT:
       op
       pro

double
embIepGetCharge (c, pro, total)
       const ajint * c
       const double * pro
       double & total
    OUTPUT:
       RETVAL
       total

double
embIepPhConverge (c, K, op, pro)
       const ajint * c
       const double * K
       ajint & op
       double & pro
    OUTPUT:
       RETVAL
       op
       pro

AjBool
embIepIepC (s, amino, sscount, modlysine, iep, termini)
       const char * s
       ajint amino
       ajint sscount
       ajint modlysine
       double & iep
       AjBool termini
    OUTPUT:
       RETVAL
       iep

AjBool
embIepIepS (str, amino, sscount, modlysine, iep, termini)
       const AjPStr str
       ajint amino
       ajint sscount
       ajint modlysine
       double & iep
       AjBool termini
    OUTPUT:
       RETVAL
       iep

