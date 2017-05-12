#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_math		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajmath.c: automatically generated

ajint
ajRound (i, round)
       ajint i
       ajint round
    OUTPUT:
       RETVAL

float
ajRoundF (a, nbits)
       float a
       ajint nbits
    OUTPUT:
       RETVAL

void
ajRecToPol (x, y, radius, angle)
       float x
       float y
       float& radius
       float& angle
    OUTPUT:
       radius
       angle

void
ajPolToRec (radius, angle, x, y)
       float radius
       float angle
       float& x
       float& y
    OUTPUT:
       x
       y

float
ajDegToRad (degrees)
       float degrees
    OUTPUT:
       RETVAL

float
ajRadToDeg (radians)
       float radians
    OUTPUT:
       RETVAL

double
ajGaussProb (mean, sd, score)
       float mean
       float sd
       float score
    OUTPUT:
       RETVAL

float
ajGeoMean (s, n)
       const float* s
       ajint n
    OUTPUT:
       RETVAL

ajint
ajPosMod (a, b)
       ajint a
       ajint b
    OUTPUT:
       RETVAL

void
ajRandomSeed ()

ajint
ajRandomNumber ()
    OUTPUT:
       RETVAL

double
ajRandomNumberD ()
    OUTPUT:
       RETVAL

unsigned long long
ajSp64Crc (thys)
       const AjPStr thys
    OUTPUT:
       RETVAL

ajuint
ajMathPos (len, ipos)
       ajuint len
       ajint ipos
    OUTPUT:
       RETVAL

ajuint
ajMathPosI (len, imin, ipos)
       ajuint len
       ajuint imin
       ajint ipos
    OUTPUT:
       RETVAL

ajuint
ajSp32Crc (seq)
       const AjPStr seq
    OUTPUT:
       RETVAL

ajuint
ajNumLengthDouble (dnumber)
       double dnumber
    OUTPUT:
       RETVAL

ajuint
ajNumLengthFloat (fnumber)
       float fnumber
    OUTPUT:
       RETVAL

ajuint
ajNumLengthInt (inumber)
       ajlong inumber
    OUTPUT:
       RETVAL

ajuint
ajNumLengthUint (inumber)
       ajulong inumber
    OUTPUT:
       RETVAL

