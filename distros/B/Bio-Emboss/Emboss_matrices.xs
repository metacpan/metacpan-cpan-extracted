#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_matrices		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajmatrices.c: automatically generated

AjPMatrix
ajMatrixNew (codes, n, filename)
       AjPPStr codes
       ajint n
       const AjPStr filename
    OUTPUT:
       RETVAL

AjPMatrix
ajMatrixNewAsym (codes, n, rcodes, rn, filename)
       AjPPStr codes
       ajint n
       AjPPStr rcodes
       ajint rn
       const AjPStr filename
    OUTPUT:
       RETVAL

AjPMatrixf
ajMatrixfNew (codes, n, filename)
       AjPPStr codes
       ajint n
       const AjPStr filename
    OUTPUT:
       RETVAL

AjPMatrixf
ajMatrixfNewAsym (codes, n, rcodes, rn, filename)
       AjPPStr codes
       ajint n
       AjPPStr rcodes
       ajint rn
       const AjPStr filename
    OUTPUT:
       RETVAL

void
ajMatrixfDel (thys)
       AjPMatrixf& thys
    OUTPUT:
       thys

void
ajMatrixDel (thys)
       AjPMatrix& thys
    OUTPUT:
       thys

AjIntArray*
ajMatrixArray (thys)
       const AjPMatrix thys
    OUTPUT:
       RETVAL

AjFloatArray*
ajMatrixfArray (thys)
       const AjPMatrixf thys
    OUTPUT:
       RETVAL

ajint
ajMatrixSize (thys)
       const AjPMatrix thys
    OUTPUT:
       RETVAL

ajint
ajMatrixfSize (thys)
       const AjPMatrixf thys
    OUTPUT:
       RETVAL

AjPSeqCvt
ajMatrixCvt (thys)
       const AjPMatrix thys
    OUTPUT:
       RETVAL

AjPSeqCvt
ajMatrixfCvt (thys)
       const AjPMatrixf thys
    OUTPUT:
       RETVAL

void
ajMatrixChar (thys, i, label)
       const AjPMatrix thys
       ajint i
       AjPStr & label
    OUTPUT:
       label

void
ajMatrixfChar (thys, i, label)
       const AjPMatrixf thys
       ajint i
       AjPStr & label
    OUTPUT:
       label

const AjPStr
ajMatrixName (thys)
       const AjPMatrix thys
    OUTPUT:
       RETVAL

const AjPStr
ajMatrixfName (thys)
       const AjPMatrixf thys
    OUTPUT:
       RETVAL

AjBool
ajMatrixRead (pthis, filename)
       AjPMatrix& pthis
       const AjPStr filename
    OUTPUT:
       RETVAL
       pthis

AjBool
ajMatrixfRead (pthis, filename)
       AjPMatrixf& pthis
       const AjPStr filename
    OUTPUT:
       RETVAL
       pthis

AjBool
ajMatrixSeqNum (thys, seq, numseq)
       const AjPMatrix thys
       const AjPSeq seq
       AjPStr& numseq
    OUTPUT:
       RETVAL
       numseq

AjBool
ajMatrixfSeqNum (thys, seq, numseq)
       const AjPMatrixf thys
       const AjPSeq seq
       AjPStr& numseq
    OUTPUT:
       RETVAL
       numseq

AjPStr
ajMatrixGetCodes (thys)
       const AjPMatrix thys
    OUTPUT:
       RETVAL

AjPStr
ajMatrixfGetCodes (thys)
       const AjPMatrixf thys
    OUTPUT:
       RETVAL

