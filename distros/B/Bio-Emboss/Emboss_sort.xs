#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_sort		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajsort.c: automatically generated

void
ajSortFloatDecI (a, p, n)
       const float* a
       ajuint& p
       ajuint n
    OUTPUT:
       p

void
ajSortIntDecI (a, p, n)
       const ajint* a
       ajuint& p
       ajuint n
    OUTPUT:
       p

void
ajSortFloatIncI (a, p, n)
       const float* a
       ajuint& p
       ajuint n
    OUTPUT:
       p

void
ajSortIntIncI (a, p, n)
       const ajint* a
       ajuint& p
       ajuint n
    OUTPUT:
       p

void
ajSortTwoIntIncI (a, p, n)
       ajint& a
       ajuint& p
       ajuint n
    OUTPUT:
       a
       p

void
ajSortFloatDec (a, n)
       float& a
       ajuint n
    OUTPUT:
       a

void
ajSortIntDec (a, n)
       ajint& a
       ajuint n
    OUTPUT:
       a

void
ajSortFloatInc (a, n)
       float& a
       ajuint n
    OUTPUT:
       a

void
ajSortIntInc (a, n)
       ajint& a
       ajuint n
    OUTPUT:
       a

void
ajSortUintDecI (a, p, n)
       const ajuint* a
       ajuint& p
       ajuint n
    OUTPUT:
       p

void
ajSortUintIncI (a, p, n)
       const ajuint* a
       ajuint& p
       ajuint n
    OUTPUT:
       p

void
ajSortTwoUintIncI (a, p, n)
       ajuint& a
       ajuint& p
       ajuint n
    OUTPUT:
       a
       p

void
ajSortUintDec (a, n)
       ajuint& a
       ajuint n
    OUTPUT:
       a

void
ajSortUintInc (a, n)
       ajuint& a
       ajuint n
    OUTPUT:
       a

