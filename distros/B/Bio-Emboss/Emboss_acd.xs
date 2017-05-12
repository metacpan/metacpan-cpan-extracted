#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_acd		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajacd.c: automatically generated

AjPAlign
ajAcdGetAlign (token)
       const char* token
    OUTPUT:
       RETVAL

AjPFloat
ajAcdGetArray (token)
       const char* token
    OUTPUT:
       RETVAL

AjBool
ajAcdGetBool (token)
       const char* token
    OUTPUT:
       RETVAL

AjPCod
ajAcdGetCodon (token)
       const char* token
    OUTPUT:
       RETVAL

AjPFile
ajAcdGetCpdb (token)
       const char* token
    OUTPUT:
       RETVAL

AjPFile
ajAcdGetDatafile (token)
       const char* token
    OUTPUT:
       RETVAL

AjPDir
ajAcdGetDirectory (token)
       const char* token
    OUTPUT:
       RETVAL

AjPStr
ajAcdGetDirectoryName (token)
       const char* token
    OUTPUT:
       RETVAL

AjPList
ajAcdGetDirlist (token)
       const char* token
    OUTPUT:
       RETVAL

AjPPhyloState*
ajAcdGetDiscretestates (token)
       const char* token
    OUTPUT:
       RETVAL

AjPPhyloState
ajAcdGetDiscretestatesSingle (token)
       const char* token
    OUTPUT:
       RETVAL

AjPPhyloDist*
ajAcdGetDistances (token)
       const char* token
    OUTPUT:
       RETVAL

AjPFeattable
ajAcdGetFeat (token)
       const char* token
    OUTPUT:
       RETVAL

AjPFeattabOut
ajAcdGetFeatout (token)
       const char* token
    OUTPUT:
       RETVAL

AjPList
ajAcdGetFilelist (token)
       const char* token
    OUTPUT:
       RETVAL

float
ajAcdGetFloat (token)
       const char* token
    OUTPUT:
       RETVAL

AjPPhyloFreq
ajAcdGetFrequencies (token)
       const char* token
    OUTPUT:
       RETVAL

AjPGraph
ajAcdGetGraph (token)
       const char* token
    OUTPUT:
       RETVAL

AjPGraph
ajAcdGetGraphxy (token)
       const char* token
    OUTPUT:
       RETVAL

AjPFile
ajAcdGetInfile (token)
       const char* token
    OUTPUT:
       RETVAL

ajint
ajAcdGetInt (token)
       const char* token
    OUTPUT:
       RETVAL

AjPStr*
ajAcdGetList (token)
       const char* token
    OUTPUT:
       RETVAL

AjPStr
ajAcdGetListSingle (token)
       const char* token
    OUTPUT:
       RETVAL

AjPMatrix
ajAcdGetMatrix (token)
       const char* token
    OUTPUT:
       RETVAL

AjPMatrixf
ajAcdGetMatrixf (token)
       const char* token
    OUTPUT:
       RETVAL

AjPOutfile
ajAcdGetOutcodon (token)
       const char* token
    OUTPUT:
       RETVAL

AjPOutfile
ajAcdGetOutcpdb (token)
       const char* token
    OUTPUT:
       RETVAL

AjPOutfile
ajAcdGetOutdata (token)
       const char* token
    OUTPUT:
       RETVAL

AjPDir
ajAcdGetOutdir (token)
       const char* token
    OUTPUT:
       RETVAL

AjPStr
ajAcdGetOutdirName (token)
       const char* token
    OUTPUT:
       RETVAL

AjPOutfile
ajAcdGetOutdiscrete (token)
       const char* token
    OUTPUT:
       RETVAL

AjPOutfile
ajAcdGetOutdistance (token)
       const char* token
    OUTPUT:
       RETVAL

AjPFile
ajAcdGetOutfile (token)
       const char* token
    OUTPUT:
       RETVAL

AjPFile
ajAcdGetOutfileall (token)
       const char* token
    OUTPUT:
       RETVAL

AjPOutfile
ajAcdGetOutfreq (token)
       const char* token
    OUTPUT:
       RETVAL

AjPOutfile
ajAcdGetOutmatrix (token)
       const char* token
    OUTPUT:
       RETVAL

AjPOutfile
ajAcdGetOutmatrixf (token)
       const char* token
    OUTPUT:
       RETVAL

AjPOutfile
ajAcdGetOutproperties (token)
       const char* token
    OUTPUT:
       RETVAL

AjPOutfile
ajAcdGetOutscop (token)
       const char* token
    OUTPUT:
       RETVAL

AjPOutfile
ajAcdGetOuttree (token)
       const char* token
    OUTPUT:
       RETVAL

AjPPatlistSeq
ajAcdGetPattern (token)
       const char* token
    OUTPUT:
       RETVAL

AjPPhyloProp
ajAcdGetProperties (token)
       const char* token
    OUTPUT:
       RETVAL

AjPRange
ajAcdGetRange (token)
       const char* token
    OUTPUT:
       RETVAL

AjPPatlistRegex
ajAcdGetRegexp (token)
       const char* token
    OUTPUT:
       RETVAL

AjPRegexp
ajAcdGetRegexpSingle (token)
       const char* token
    OUTPUT:
       RETVAL

AjPReport
ajAcdGetReport (token)
       const char* token
    OUTPUT:
       RETVAL

AjPFile
ajAcdGetScop (token)
       const char* token
    OUTPUT:
       RETVAL

AjPStr*
ajAcdGetSelect (token)
       const char* token
    OUTPUT:
       RETVAL

AjPStr
ajAcdGetSelectSingle (token)
       const char* token
    OUTPUT:
       RETVAL

AjPSeq
ajAcdGetSeq (token)
       const char* token
    OUTPUT:
       RETVAL

AjPSeqall
ajAcdGetSeqall (token)
       const char* token
    OUTPUT:
       RETVAL

AjPSeqout
ajAcdGetSeqout (token)
       const char* token
    OUTPUT:
       RETVAL

AjPSeqout
ajAcdGetSeqoutall (token)
       const char* token
    OUTPUT:
       RETVAL

AjPSeqout
ajAcdGetSeqoutset (token)
       const char* token
    OUTPUT:
       RETVAL

AjPSeqset
ajAcdGetSeqset (token)
       const char* token
    OUTPUT:
       RETVAL

AjPSeqset*
ajAcdGetSeqsetall (token)
       const char* token
    OUTPUT:
       RETVAL

AjPSeqset
ajAcdGetSeqsetallSingle (token)
       const char* token
    OUTPUT:
       RETVAL

AjPStr
ajAcdGetString (token)
       const char* token
    OUTPUT:
       RETVAL

AjBool
ajAcdGetToggle (token)
       const char* token
    OUTPUT:
       RETVAL

AjPPhyloTree*
ajAcdGetTree (token)
       const char* token
    OUTPUT:
       RETVAL

AjPPhyloTree
ajAcdGetTreeSingle (token)
       const char* token
    OUTPUT:
       RETVAL

const AjPStr
ajAcdGetValue (token)
       const char* token
    OUTPUT:
       RETVAL

AjBool
ajAcdSetControl (optionName)
       const char* optionName
    OUTPUT:
       RETVAL

const AjPStr
ajAcdGetCmdline ()
    OUTPUT:
       RETVAL

const AjPStr
ajAcdGetInputs ()
    OUTPUT:
       RETVAL

const AjPStr
ajAcdGetProgram ()
    OUTPUT:
       RETVAL

void
ajAcdPrintAppl (outf, full)
       AjPFile outf
       AjBool full

void
ajAcdPrintQual (outf, full)
       AjPFile outf
       AjBool full

void
ajAcdPrintType (outf, full)
       AjPFile outf
       AjBool full

void
ajAcdExit (silent)
       AjBool silent

void
ajAcdUnused ()

AjPPhyloDist
ajAcdGetDistancesSingle (token)
       const char* token
    OUTPUT:
       RETVAL

