#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_pdbio		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajpdbio.c: automatically generated

AjBool
ajPdbWriteDomainRecordRaw (mode, pdb, mod, scop, outf, errf)
       ajint mode
       const AjPPdb pdb
       ajint mod
       const AjPScop scop
       AjPFile outf
       AjPFile errf
    OUTPUT:
       RETVAL
       outf
       errf

AjBool
ajPdbWriteRecordRaw (mode, pdb, mod, chn, outf, errf)
       ajint mode
       const AjPPdb pdb
       ajint mod
       ajint chn
       AjPFile outf
       AjPFile errf
    OUTPUT:
       RETVAL
       outf
       errf

AjBool
ajPdbWriteAllRaw (mode, pdb, outf, errf)
       ajint mode
       const AjPPdb pdb
       AjPFile outf
       AjPFile errf
    OUTPUT:
       RETVAL
       outf
       errf

AjBool
ajPdbWriteDomainRaw (mode, pdb, scop, outf, errf)
       ajint mode
       const AjPPdb pdb
       const AjPScop scop
       AjPFile outf
       AjPFile errf
    OUTPUT:
       RETVAL
       outf
       errf

