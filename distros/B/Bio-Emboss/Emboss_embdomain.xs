#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embdomain		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embdomain.c: automatically generated

AjPStr
embScopToPdbid (scop, pdb)
       const AjPStr scop
       AjPStr& pdb
    OUTPUT:
       RETVAL
       pdb

AjBool
embScopToSp (scop, spr, list)
       const AjPStr scop
       AjPStr& spr
       const AjPList list
    OUTPUT:
       RETVAL
       spr

AjBool
embScopToAcc (scop, acc, list)
       const AjPStr scop
       AjPStr& acc
       const AjPList list
    OUTPUT:
       RETVAL
       acc

