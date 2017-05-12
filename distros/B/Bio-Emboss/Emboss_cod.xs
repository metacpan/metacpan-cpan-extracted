#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_cod		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajcod.c: automatically generated

AjPCod
ajCodNew ()
    OUTPUT:
       RETVAL

AjPCod
ajCodNewCode (code)
       ajint code
    OUTPUT:
       RETVAL

AjPCod
ajCodDup (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

void
ajCodDel (pthys)
       AjPCod & pthys
    OUTPUT:
       pthys

void
ajCodBacktranslate (b, a, thys)
       AjPStr & b
       const AjPStr a
       const AjPCod thys
    OUTPUT:
       b

void
ajCodBacktranslateAmbig (b, a, thys)
       AjPStr & b
       const AjPStr a
       const AjPCod thys
    OUTPUT:
       b

ajint
ajCodBase (c)
       ajint c
    OUTPUT:
       RETVAL

void
ajCodCalcGribskov (thys, s)
       AjPCod thys
       const AjPStr s

double
ajCodCalcNc (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

void
ajCodCalculateUsage (thys, c)
       AjPCod thys
       ajint c

void
ajCodClear (thys)
       AjPCod thys
    OUTPUT:
       thys

void
ajCodClearData (thys)
       AjPCod thys
    OUTPUT:
       thys

void
ajCodCountTriplets (thys, s, c)
       AjPCod thys
       const AjPStr s
       ajint & c
    OUTPUT:
       thys
       c

ajint
ajCodIndex (s)
       const AjPStr s
    OUTPUT:
       RETVAL

ajint
ajCodIndexC (codon)
       const char * codon
    OUTPUT:
       RETVAL

AjBool
ajCodRead (thys, fn, format)
       AjPCod thys
       const AjPStr fn
       const AjPStr format
    OUTPUT:
       RETVAL
       thys

void
ajCodSetBacktranslate (thys)
       AjPCod & thys
    OUTPUT:
       thys

char*
ajCodTriplet (idx)
       ajint idx
    OUTPUT:
       RETVAL

void
ajCodWriteOut (thys, outf)
       const AjPCod thys
       AjPOutfile outf

void
ajCodWrite (thys, outf)
       AjPCod thys
       AjPFile outf

void
ajCodComp (NA, NC, NG, NT, str)
       ajint & NA
       ajint & NC
       ajint & NG
       ajint & NT
       const char * str
    OUTPUT:
       NA
       NC
       NG
       NT

double
ajCodCalcCai (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

double*
ajCodCaiW (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

double
ajCodCai (thys, str)
       const AjPCod thys
       const AjPStr str
    OUTPUT:
       RETVAL

const AjPStr
ajCodGetName (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

const char*
ajCodGetNameC (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

const AjPStr
ajCodGetDesc (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

const char*
ajCodGetDescC (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

const AjPStr
ajCodGetSpecies (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

const char*
ajCodGetSpeciesC (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

const AjPStr
ajCodGetDivision (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

const char*
ajCodGetDivisionC (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

const AjPStr
ajCodGetRelease (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

const char*
ajCodGetReleaseC (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

ajint
ajCodGetNumcodon (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

ajint
ajCodGetNumcds (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

ajint
ajCodGetCode (thys)
       const AjPCod thys
    OUTPUT:
       RETVAL

void
ajCodAssName (thys, name)
       AjPCod thys
       const AjPStr name

void
ajCodAssNameC (thys, name)
       AjPCod thys
       const char* name

void
ajCodAssDesc (thys, desc)
       AjPCod thys
       const AjPStr desc

void
ajCodAssDescC (thys, desc)
       AjPCod thys
       const char* desc

void
ajCodAssSpecies (thys, species)
       AjPCod thys
       const AjPStr species

void
ajCodAssSpeciesC (thys, species)
       AjPCod thys
       const char* species

void
ajCodAssRelease (thys, release)
       AjPCod thys
       const AjPStr release

void
ajCodAssReleaseC (thys, release)
       AjPCod thys
       const char* release

void
ajCodAssDivision (thys, division)
       AjPCod thys
       const AjPStr division

void
ajCodAssDivisionC (thys, division)
       AjPCod thys
       const char* division

void
ajCodAssNumcodon (thys, numcodon)
       AjPCod thys
       ajint numcodon

void
ajCodAssNumcds (thys, numcds)
       AjPCod thys
       ajint numcds

void
ajCodAssCode (thys, geneticcode)
       AjPCod thys
       ajint geneticcode

ajint
ajCodOutFormat (name)
       const AjPStr name
    OUTPUT:
       RETVAL

void
ajCodPrintFormat (outf, full)
       AjPFile outf
       AjBool full

void
ajCodGetCodonlist (cod, list)
       const AjPCod cod
       AjPList list
    OUTPUT:
       list

void
ajCodExit ()

