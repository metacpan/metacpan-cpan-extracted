#/*-*- Mode: C -*- */

MODULE = DDC::XS		PACKAGE = DDC::XS

##=====================================================================
## Constants
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## ddcConfig.h
const char *
library_version()

const char *
build_library_version()

##--------------------------------------------------------------
## ConcCommon.h: HitSortEnum
int
NoSort()
 CODE:
  RETVAL = NoSort;
 OUTPUT:
  RETVAL

int
LessByDate()
 CODE:
  RETVAL = LessByDate;
 OUTPUT:
  RETVAL

int
GreaterByDate()
 CODE:
  RETVAL = GreaterByDate;
 OUTPUT:
  RETVAL

int
LessBySize()
 CODE:
  RETVAL = LessBySize;
 OUTPUT:
  RETVAL

int
GreaterBySize()
 CODE:
  RETVAL = GreaterBySize;
 OUTPUT:
  RETVAL

int
LessByFreeBiblField()
 CODE:
  RETVAL = LessByFreeBiblField;
 OUTPUT:
  RETVAL

int
GreaterByFreeBiblField()
 CODE:
  RETVAL = GreaterByFreeBiblField;
 OUTPUT:
  RETVAL

int
LessByRank()
 CODE:
  RETVAL = LessByRank;
 OUTPUT:
  RETVAL

int
GreaterByRank()
 CODE:
  RETVAL = GreaterByRank;
 OUTPUT:
  RETVAL

int
LessByMiddleContext()
 CODE:
  RETVAL = LessByMiddleContext;
 OUTPUT:
  RETVAL

int
GreaterByMiddleContext()
 CODE:
  RETVAL = GreaterByMiddleContext;
 OUTPUT:
  RETVAL

int
LessByLeftContext()
 CODE:
  RETVAL = LessByLeftContext;
 OUTPUT:
  RETVAL

int
GreaterByLeftContext()
 CODE:
  RETVAL = GreaterByLeftContext;
 OUTPUT:
  RETVAL

int
LessByRightContext()
 CODE:
  RETVAL = LessByRightContext;
 OUTPUT:
  RETVAL

int
GreaterByRightContext()
 CODE:
  RETVAL = GreaterByRightContext;
 OUTPUT:
  RETVAL

int
RandomSort()
 CODE:
  RETVAL = RandomSort;
 OUTPUT:
  RETVAL

int
LessByCountKey()
 CODE:
  RETVAL = LessByCountKey;
 OUTPUT:
  RETVAL

int
GreaterByCountKey()
 CODE:
  RETVAL = GreaterByCountKey;
 OUTPUT:
  RETVAL

int
LessByCountValue()
 CODE:
  RETVAL = LessByCountValue;
 OUTPUT:
  RETVAL

int
GreaterByCountValue()
 CODE:
  RETVAL = GreaterByCountValue;
 OUTPUT:
  RETVAL

int
HitSortsCount()
 CODE:
  RETVAL = HitSortsCount;
 OUTPUT:
  RETVAL

char*
HitSortEnumName(HitSortEnum e)
 CODE:
  if (e >= HitSortsCount) { XSRETURN_UNDEF; }
  RETVAL = (char*)HitSortEnumNames[e];
 OUTPUT:
  RETVAL

char*
HitSortEnumString(HitSortEnum e)
 CODE:
  if (e >= HitSortsCount) { XSRETURN_UNDEF; }
  RETVAL = (char*)HitSortEnumStrings[e];
 OUTPUT:
  RETVAL

