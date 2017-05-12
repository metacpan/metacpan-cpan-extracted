#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_domain		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajdomain.c: automatically generated

AjPList
ajCathReadAllNew (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjPList
ajCathReadAllRawNew (cathf, domf, namesf, logf)
       AjPFile cathf
       AjPFile domf
       AjPFile namesf
       AjPFile logf
    OUTPUT:
       RETVAL

AjPCath
ajCathReadCNew (inf, entry)
       AjPFile inf
       const char* entry
    OUTPUT:
       RETVAL

AjPCath
ajCathReadNew (inf, entry)
       AjPFile inf
       const AjPStr entry
    OUTPUT:
       RETVAL

AjPList
ajDomainReadAllNew (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjPList
ajScopReadAllNew (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjPList
ajScopReadAllRawNew (claf, desf, omit)
       AjPFile claf
       AjPFile desf
       AjBool omit
    OUTPUT:
       RETVAL

AjPCath
ajCathNew (n)
       ajint n
    OUTPUT:
       RETVAL

AjPDomain
ajDomainNew (n, type)
       ajint n
       ajint type
    OUTPUT:
       RETVAL

AjPScop
ajScopNew (chains)
       ajint chains
    OUTPUT:
       RETVAL

AjPDomain
ajDomainReadNew (inf, entry)
       AjPFile inf
       const AjPStr entry
    OUTPUT:
       RETVAL

AjPScop
ajScopReadNew (inf, entry)
       AjPFile inf
       const AjPStr entry
    OUTPUT:
       RETVAL

AjPDomain
ajDomainReadCNew (inf, entry, dtype)
       AjPFile inf
       const char* entry
       ajint dtype
    OUTPUT:
       RETVAL

AjPScop
ajScopReadCNew (inf, entry)
       AjPFile inf
       const char* entry
    OUTPUT:
       RETVAL

void
ajDomainDel (ptr)
       AjPDomain& ptr
    OUTPUT:
       ptr

void
ajScopDel (ptr)
       AjPScop& ptr
    OUTPUT:
       ptr

void
ajCathDel (ptr)
       AjPCath & ptr
    OUTPUT:
       ptr

AjBool
ajDomainCopy (to, from)
       AjPDomain& to
       const AjPDomain from
    OUTPUT:
       RETVAL
       to

AjBool
ajCathCopy (to, from)
       AjPCath& to
       const AjPCath from
    OUTPUT:
       RETVAL
       to

AjBool
ajScopCopy (to, from)
       AjPScop& to
       const AjPScop from
    OUTPUT:
       RETVAL
       to

ajint
ajScopMatchSunid (entry1, entry2)
       const char* entry1
       const char* entry2
    OUTPUT:
       RETVAL

ajint
ajScopMatchScopid (hit1, hit2)
       const char* hit1
       const char* hit2
    OUTPUT:
       RETVAL

ajint
ajScopMatchPdbId (hit1, hit2)
       const char* hit1
       const char* hit2
    OUTPUT:
       RETVAL

ajint
ajCathMatchPdbId (hit1, hit2)
       const char* hit1
       const char* hit2
    OUTPUT:
       RETVAL

AjPStr
ajDomainGetId (obj)
       const AjPDomain obj
    OUTPUT:
       RETVAL

AjPStr
ajDomainGetSeqPdb (obj)
       const AjPDomain obj
    OUTPUT:
       RETVAL

AjPStr
ajDomainGetSeqSpr (obj)
       const AjPDomain obj
    OUTPUT:
       RETVAL

AjPStr
ajDomainGetPdb (obj)
       const AjPDomain obj
    OUTPUT:
       RETVAL

AjPStr
ajDomainGetAcc (obj)
       const AjPDomain obj
    OUTPUT:
       RETVAL

AjPStr
ajDomainGetSpr (obj)
       const AjPDomain obj
    OUTPUT:
       RETVAL

ajint
ajDomainGetN (obj)
       const AjPDomain obj
    OUTPUT:
       RETVAL

ajint
ajScopArrFindScopid (arr, siz, id)
       AjPScop const * arr
       ajint siz
       const AjPStr id
    OUTPUT:
       RETVAL

ajint
ajScopArrFindSunid (arr, siz, id)
       AjPScop const * arr
       ajint siz
       ajint id
    OUTPUT:
       RETVAL

ajint
ajScopArrFindPdbid (arr, siz, id)
       AjPScop const* arr
       ajint siz
       const AjPStr id
    OUTPUT:
       RETVAL

ajint
ajCathArrFindPdbid (arr, siz, id)
       AjPCath const* arr
       ajint siz
       const AjPStr id
    OUTPUT:
       RETVAL

AjBool
ajPdbWriteDomain (outf, pdb, scop, errf)
       AjPFile outf
       const AjPPdb pdb
       const AjPScop scop
       AjPFile errf
    OUTPUT:
       RETVAL

AjBool
ajCathWrite (outf, obj)
       AjPFile outf
       const AjPCath obj
    OUTPUT:
       RETVAL

AjBool
ajDomainWrite (outf, obj)
       AjPFile outf
       const AjPDomain obj
    OUTPUT:
       RETVAL

AjBool
ajScopWrite (outf, obj)
       AjPFile outf
       const AjPScop obj
    OUTPUT:
       RETVAL

ajint
ajDomainDCFType (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

void
ajDomainDummyFunction ()

