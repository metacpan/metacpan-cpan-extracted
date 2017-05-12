#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_phylo		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajphylo.c: automatically generated

AjPPhyloDist
ajPhyloDistNew ()
    OUTPUT:
       RETVAL

AjPPhyloFreq
ajPhyloFreqNew ()
    OUTPUT:
       RETVAL

AjPPhyloProp
ajPhyloPropNew ()
    OUTPUT:
       RETVAL

AjPPhyloState
ajPhyloStateNew ()
    OUTPUT:
       RETVAL

AjPPhyloTree
ajPhyloTreeNew ()
    OUTPUT:
       RETVAL

void
ajPhyloDistDel (pthis)
       AjPPhyloDist& pthis
    OUTPUT:
       pthis

void
ajPhyloFreqDel (pthis)
       AjPPhyloFreq& pthis
    OUTPUT:
       pthis

void
ajPhyloPropDel (pthis)
       AjPPhyloProp& pthis
    OUTPUT:
       pthis

void
ajPhyloStateDel (pthis)
       AjPPhyloState& pthis
    OUTPUT:
       pthis

void
ajPhyloTreeDel (pthis)
       AjPPhyloTree& pthis
    OUTPUT:
       pthis

AjPPhyloDist*
ajPhyloDistRead (filename, size, missing)
       const AjPStr filename
       ajint size
       AjBool missing
    OUTPUT:
       RETVAL

void
ajPhyloDistTrace (thys)
       const AjPPhyloDist thys

AjPPhyloFreq
ajPhyloFreqRead (filename, contchar, genedata, indiv)
       const AjPStr filename
       AjBool contchar
       AjBool genedata
       AjBool indiv
    OUTPUT:
       RETVAL

void
ajPhyloFreqTrace (thys)
       const AjPPhyloFreq thys

AjPPhyloProp
ajPhyloPropRead (filename, propchars, len, size)
       const AjPStr filename
       const AjPStr propchars
       ajint len
       ajint size
    OUTPUT:
       RETVAL

ajint
ajPhyloPropGetSize (thys)
       const AjPPhyloProp thys
    OUTPUT:
       RETVAL

void
ajPhyloPropTrace (thys)
       const AjPPhyloProp thys

AjPPhyloState*
ajPhyloStateRead (filename, statechars)
       const AjPStr filename
       const AjPStr statechars
    OUTPUT:
       RETVAL

void
ajPhyloStateTrace (thys)
       const AjPPhyloState thys

AjPPhyloTree*
ajPhyloTreeRead (filename, size)
       const AjPStr filename
       ajint size
    OUTPUT:
       RETVAL

void
ajPhyloTreeTrace (thys)
       const AjPPhyloTree thys

void
ajPhyloStateDelarray (pthis)
       AjPPhyloState*& pthis
    OUTPUT:
       pthis

void
ajPhyloTreeDelarray (pthis)
       AjPPhyloTree*& pthis
    OUTPUT:
       pthis

void
ajPhyloExit ()

