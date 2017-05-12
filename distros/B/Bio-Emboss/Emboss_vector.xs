#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_vector		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajvector.c: automatically generated

AjP3dVector
aj3dVectorNew ()
    OUTPUT:
       RETVAL

AjP3dVector
aj3dVectorCreate (fX, fY, fZ)
       float fX
       float fY
       float fZ
    OUTPUT:
       RETVAL

void
aj3dVectorDel (pthis)
       AjP3dVector& pthis
    OUTPUT:
       pthis

void
aj3dVectorCrossProduct (first, second, crossProduct)
       const AjP3dVector first
       const AjP3dVector second
       AjP3dVector crossProduct
    OUTPUT:
       crossProduct

void
aj3dVectorBetweenPoints (betweenPoints, fStartX, fStartY, fStartZ, fEndX, fEndY, fEndZ)
       AjP3dVector betweenPoints
       float fStartX
       float fStartY
       float fStartZ
       float fEndX
       float fEndY
       float fEndZ

float
aj3dVectorLength (thys)
       const AjP3dVector thys
    OUTPUT:
       RETVAL

float
aj3dVectorAngle (first, second)
       const AjP3dVector first
       const AjP3dVector second
    OUTPUT:
       RETVAL

float
aj3dVectorDihedralAngle (veca, vecb, vecc)
       const AjP3dVector veca
       const AjP3dVector vecb
       const AjP3dVector vecc
    OUTPUT:
       RETVAL

float
aj3dVectorDotProduct (first, second)
       const AjP3dVector first
       const AjP3dVector second
    OUTPUT:
       RETVAL

void
aj3dVectorSum (first, second, sum)
       const AjP3dVector first
       const AjP3dVector second
       AjP3dVector sum
    OUTPUT:
       sum

