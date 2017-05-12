/* $Id$ */

#include <unistd.h>
#include <math.h>

#ifdef __APPLE__
#include <crt_externs.h>
  #ifndef environ
    #define environ  (*_NSGetEnviron())
  #endif
#endif

#include "common.h"
#include "linefile.h"
#include "hash.h"
#include "options.h"
#include "sqlNum.h"
#include "udc.h"
#include "localmem.h"
#include "bigWig.h"
#include "bigBed.h"
#include "udc.h"
#include "asParse.h"

/* Let Perl redefine these */
#undef TRUE
#undef FALSE
#undef warn

#ifdef PERL_CAPI
#define WIN32IO_IS_STDIO
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef FCGI
 #include <fcgi_stdio.h>
#else
 #ifdef USE_SFIO
  #include <config.h>
 #else
  #include <stdio.h>
 #endif
 #include <perlio.h>
#endif

typedef struct bbiFile     *Bio__DB__bbiFile;

typedef struct bbiInterval *Bio__DB__bbiInterval;

typedef struct bbiIntervalList {
    struct lm          *lm;
    struct bbiInterval *head;
  } *Bio__DB__bbiIntervalList;

typedef struct bbiSummaryList {
  int                      size;
  struct bbiSummaryElement *summary;
} *Bio__DB__bbiExtendedSummary;

typedef struct bbiSummaryElement *Bio__DB__bbiExtendedSummaryEl;

typedef struct bbiChromInfoHead  {
  struct bbiChromInfo  *head;
} *Bio__DB__bbiChromInfoHead;

typedef struct bbiChromInfo *Bio__DB__bbiChromInfo;

typedef struct bigBedIntervalList {
  struct lm               *lm;
  struct bigBedInterval   *head;
} *Bio__DB__BigBedIntervalList;

typedef struct bigBedInterval *Bio__DB__BigBedInterval;

typedef struct asObject   *Bio__DB__asObject;
typedef struct asColumn   *Bio__DB__asColumn;
typedef struct asTypeInfo *Bio__DB__asTypeInfo;

MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::BigFile PREFIX=bf_

void
bf_bigWigFileCreate(package="Bio::DB::BigFile",inName,chromSizes,blockSize=1024,itemsPerSlot=512,clipDontDie=TRUE,compress=TRUE,outName)
  char             *package
  char             *inName
  char             *chromSizes
  int               blockSize
  int               itemsPerSlot
  int               clipDontDie
  int               compress
  char             *outName
  CODE:
  bigWigFileCreate(inName,chromSizes,blockSize,itemsPerSlot,clipDontDie,compress,outName);

void
bf_udcSetDefaultDir(packname="Bio::DB::BigFile",path)
  char       *packname
  char       *path
  PREINIT:
  static char udcDir[4096];
  CODE:
  strncpy(udcDir,path,sizeof(udcDir)-1);
  udcSetDefaultDir(udcDir);

char*
bf_udcGetDefaultDir(packname="Bio::DB::BigFile")
  char       *packname
  CODE:
  RETVAL = udcDefaultDir();
  OUTPUT:
  RETVAL

Bio::DB::bbiFile
bf_bigWigFileOpen(packname="Bio::DB::BigFile",filename)
   char* packname
   char* filename
  PROTOTYPE: $$
  CODE:
  RETVAL = bigWigFileOpen(filename);
  OUTPUT:
  RETVAL

Bio::DB::bbiFile
bf_bigBedFileOpen(packname="Bio::DB::BigFile",filename)
   char* packname
   char* filename
  PROTOTYPE: $$
  CODE:
  RETVAL = bigBedFileOpen(filename);
  OUTPUT:
  RETVAL

MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::bbiFile PREFIX=bbi_

int
bbi_bigWigIntervalDump(bwf,chrom,start,end,maxCount=0,out=stdout)
    Bio::DB::bbiFile bwf
    char            *chrom
    unsigned int     start
    unsigned int     end
    int              maxCount
    FILE            *out
    CODE:
      RETVAL = bigWigIntervalDump(bwf,chrom,start,end,maxCount,out);
    OUTPUT:
      RETVAL

void
bbi_close(bbi)
    Bio::DB::bbiFile bbi
    CODE:
      bigWigFileClose(&bbi);

void
bbi_DESTROY(bbi)
    Bio::DB::bbiFile bbi
    CODE:
      bigWigFileClose(&bbi);

# max is here just to normalize call signature with bigBedIntervalQuery
Bio::DB::bbiIntervalList
bbi_bigWigIntervalQuery(bwf,chrom,start,end,max=0)
    Bio::DB::bbiFile bwf
    char            *chrom
    unsigned int     start
    unsigned int     end
    unsigned int     max
    PREINIT:
    struct bbiIntervalList *list;
    CODE:
    list = Newxz(list,1,struct bbiIntervalList);
    list->lm = lmInit(0);
    list->head = bigWigIntervalQuery(bwf,chrom,start,end,list->lm);
    RETVAL = list;
    OUTPUT:
      RETVAL

SV*
bbi_bigWigSummaryArray(bwf,chrom,start,end,summaryType=0,size)
   Bio::DB::bbiFile bwf
   char            *chrom
   unsigned int     start
   unsigned int     end
   unsigned int     summaryType
   unsigned int     size
  PREINIT:
    int     i;
    boolean result;
    double  *values;
    AV      *avref;
  CODE:
    values = Newx(values,size,double);
    for (i=0;i<size;i++) values[i] = NAN;

    result = bigWigSummaryArray(bwf,chrom,start,end,summaryType,size,values);
    if (result != TRUE) {
      Safefree(values);
      XSRETURN_EMPTY;
    } else {
      avref = (AV*) sv_2mortal((SV*)newAV());
      for (i=0;i<size;i++)
	av_push(avref, isnan(values[i]) ? &PL_sv_undef : newSVnv(values[i]));
      Safefree(values);
      RETVAL = (SV*) newRV((SV*)avref);
    }
  OUTPUT:
     RETVAL

unsigned int
bbi_bigBedItemCount(bbf)
   Bio::DB::bbiFile bbf
   CODE:
   RETVAL=bigBedItemCount(bbf);
   OUTPUT:
   RETVAL

SV*
bbi_bigBedAutoSqlText(bbf)
   Bio::DB::bbiFile bbf
   PREINIT:
   char* as;
   CODE:
   as = bigBedAutoSqlText(bbf);
   RETVAL=newSVpv(as,0);
   freeMem(as);
   OUTPUT:
   RETVAL

Bio::DB::asObject
bbi_bigBedAs(bbf)
   Bio::DB::bbiFile bbf
   CODE:
   RETVAL = bigBedAs(bbf);
   OUTPUT:
   RETVAL

SV*
bbi_bigBedSummaryArray(bbf,chrom,start,end,summaryType=0,size)
   Bio::DB::bbiFile bbf
   char            *chrom
   unsigned int     start
   unsigned int     end
   unsigned int     summaryType
   unsigned int     size
  PREINIT:
    int     i;
    boolean result;
    double  *values;
    AV      *avref;
  CODE:
    values = Newx(values,size,double);
    for (i=0;i<size;i++) values[i] = NAN;

    result = bigBedSummaryArray(bbf,chrom,start,end,summaryType,size,values);
    if (result != TRUE) {
      Safefree(values);
      XSRETURN_EMPTY;
    } else {
      avref = (AV*) sv_2mortal((SV*)newAV());
      for (i=0;i<size;i++)
	av_push(avref, isnan(values[i]) ? &PL_sv_undef : newSVnv(values[i]));
      Safefree(values);
      RETVAL = (SV*) newRV((SV*)avref);
    }
  OUTPUT:
     RETVAL

double
bbi_bigWigSingleSummary(bwf,chrom,start,end,summaryType=0,defaultVal)
   Bio::DB::bbiFile bwf
   char            *chrom
   unsigned int     start
   unsigned int     end
   unsigned int     summaryType
   double           defaultVal
  CODE:
    RETVAL = bigWigSingleSummary(bwf,chrom,start,end,summaryType,defaultVal);
  OUTPUT:
     RETVAL

Bio::DB::bbiExtendedSummary
bbi_bigWigSummary(bwf,chrom,start,end,size)
   Bio::DB::bbiFile bwf
   char            *chrom
   unsigned int     start
   unsigned int     end
   unsigned int     size
  PREINIT:
    int     i;
    boolean result;
    struct bbiSummaryElement          *summary;
    Bio__DB__bbiExtendedSummary     summaryList;
    SV     *p;
  CODE:
   summary = Newxz(summary,size,struct bbiSummaryElement);
   result  = bigWigSummaryArrayExtended(bwf,chrom,start,end,size,summary);
   if (result != TRUE) {
     Safefree(summary);
     XSRETURN_EMPTY;
   } else {
      summaryList = Newxz(summaryList,1,struct bbiSummaryList);
      summaryList->size = size;
      summaryList->summary = summary;
      p = newSV(sizeof(summaryList));
      sv_setref_pv(p,"Bio::DB::bbiExtendedSummary",(void*) summaryList);
      RETVAL = summaryList;
   }
  OUTPUT:  
    RETVAL

Bio::DB::bbiExtendedSummary
bbi_bigBedSummary(bbf,chrom,start,end,size)
   Bio::DB::bbiFile bbf
   char            *chrom
   unsigned int     start
   unsigned int     end
   unsigned int     size
  PREINIT:
    int     i;
    boolean result;
    struct bbiSummaryElement          *summary;
    Bio__DB__bbiExtendedSummary        summaryList;
    SV     *p;
  CODE:
   summary = Newxz(summary,size,struct bbiSummaryElement);
   result  = bigBedSummaryArrayExtended(bbf,chrom,start,end,size,summary);
   if (result != TRUE) {
     Safefree(summary);
     XSRETURN_EMPTY;
   } else {
      summaryList = Newxz(summaryList,1,struct bbiSummaryList);
      summaryList->size = size;
      summaryList->summary = summary;
      p = newSV(sizeof(summaryList));
      sv_setref_pv(p,"Bio::DB::bbiExtendedSummary",(void*) summaryList);
      RETVAL = summaryList;
   }
  OUTPUT:  
    RETVAL


SV*
bbi_bigWigSummaryArrayExtended(bwf,chrom,start,end,size)
   Bio::DB::bbiFile bwf
   char            *chrom
   unsigned int     start
   unsigned int     end
   unsigned int     size
  PREINIT:
    int     i;
    boolean result;
    struct bbiSummaryElement          *summary;
    Bio__DB__bbiExtendedSummary        summaryList;
    HV     *h;
    AV     *av;
  CODE:
   summary = Newxz(summary,size,struct bbiSummaryElement);
   result  = bigWigSummaryArrayExtended(bwf,chrom,start,end,size,summary);
   if (result != TRUE) {
     Safefree(summary);
     XSRETURN_EMPTY;
   } else {
     av = newAV();
     for (i=0;i<size;i++) {
       h = newHV();
       hv_store(h,"validCount",10,newSVuv(summary[i].validCount),0);
       hv_store(h,"minVal",     6,newSVnv(summary[i].minVal),0);
       hv_store(h,"maxVal",     6,newSVnv(summary[i].maxVal),0);
       hv_store(h,"sumData",    7,newSVnv(summary[i].sumData),0);
       hv_store(h,"sumSquares",10,newSVnv(summary[i].sumSquares),0);
       av_push(av,newRV_noinc((SV*)h));
     }
     Safefree(summary);
     RETVAL = (SV*) newRV_noinc((SV*)av);
   }
  OUTPUT:  
    RETVAL

SV*
bbi_bigBedSummaryArrayExtended(bbf,chrom,start,end,size)
   Bio::DB::bbiFile bbf
   char            *chrom
   unsigned int     start
   unsigned int     end
   unsigned int     size
  PREINIT:
    int     i;
    boolean result;
    struct bbiSummaryElement          *summary;
    Bio__DB__bbiExtendedSummary        summaryList;
    HV     *h;
    AV     *av;
  CODE:
   summary = Newxz(summary,size,struct bbiSummaryElement);
   result  = bigBedSummaryArrayExtended(bbf,chrom,start,end,size,summary);
   if (result != TRUE) {
     Safefree(summary);
     XSRETURN_EMPTY;
   } else {
     av = newAV();
     for (i=0;i<size;i++) {
       h = newHV();
       hv_store(h,"validCount",10,newSVuv(summary[i].validCount),0);
       hv_store(h,"minVal",     6,newSVnv(summary[i].minVal),0);
       hv_store(h,"maxVal",     6,newSVnv(summary[i].maxVal),0);
       hv_store(h,"sumData",    7,newSVnv(summary[i].sumData),0);
       hv_store(h,"sumSquares",10,newSVnv(summary[i].sumSquares),0);
       av_push(av,newRV_noinc((SV*)h));
     }
     Safefree(summary);
     RETVAL = (SV*) newRV_noinc((SV*)av);
   }
  OUTPUT:  
    RETVAL

Bio::DB::bbiChromInfoHead
bbi_chromList(bbi)
    Bio::DB::bbiFile bbi
    PREINIT:
    struct bbiChromInfo *list;
    CODE:
    list = bbiChromList(bbi);
    RETVAL = Newxz(RETVAL,1,struct bbiChromInfoHead);
    RETVAL->head = list;
    OUTPUT:
      RETVAL

unsigned int
bbi_chromSize(bbi,name)
    Bio::DB::bbiFile bbi
    char            *name
    CODE:
    RETVAL = bbiChromSize(bbi,name);
    OUTPUT:
    RETVAL

MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::bbiFile PREFIX=bb_

Bio::DB::BigBedIntervalList
bb_bigBedIntervalQuery(bbf,chrom,start,end,maxItems=0)
    Bio::DB::bbiFile bbf
    char            *chrom
    unsigned int     start
    unsigned int     end
    int              maxItems
    PREINIT:
    struct bigBedIntervalList *list;
    CODE:
    list = Newxz(list,1,struct bigBedIntervalList);
    list->lm   = lmInit(0);
    list->head = bigBedIntervalQuery(bbf,chrom,start,end,maxItems,list->lm);
    RETVAL = list;
    OUTPUT:
      RETVAL

MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::BigBedIntervalList PREFIX=bbedil_

Bio::DB::BigBedInterval
bbedil_head(bbil)
  Bio::DB::BigBedIntervalList bbil
  CODE:
    RETVAL = bbil->head;
  OUTPUT:
    RETVAL

void
bbedil_DESTROY(bbil)
	Bio::DB::BigBedIntervalList bbil
	CODE:
	if (bbil->lm != NULL) lmCleanup(&bbil->lm);
	bbil->lm = NULL;

MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::BigBedInterval PREFIX=bbedi_

Bio::DB::BigBedInterval
bbedi_next(bbi)
    Bio::DB::BigBedInterval bbi
  CODE:
  RETVAL = bbi->next;
  OUTPUT:
  RETVAL

unsigned int
bbedi_start(bbi)
    Bio::DB::BigBedInterval bbi
  CODE:
    RETVAL = bbi->start;
  OUTPUT:
    RETVAL

unsigned int
bbedi_end(bbi)
    Bio::DB::BigBedInterval bbi
  CODE:
    RETVAL = bbi->end;
  OUTPUT:
    RETVAL

char*
bbedi_rest(bbi)
    Bio::DB::BigBedInterval bbi
  CODE:
    RETVAL = bbi->rest;
  OUTPUT:
    RETVAL

MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::bbiChromInfoHead PREFIX=bbici_

Bio::DB::bbiChromInfo
bbici_head(cih)
	Bio::DB::bbiChromInfoHead cih
	CODE:
	RETVAL = cih->head;
        OUTPUT:
	RETVAL

void
bbici_DESTROY(cih)
	Bio::DB::bbiChromInfoHead cih
	CODE:
	bbiChromInfoFreeList(&cih->head);

MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::bbiChromInfo PREFIX=bbici_

Bio::DB::bbiChromInfo
bbici_next(ci)
	Bio::DB::bbiChromInfo ci
	CODE:
	  RETVAL = ci->next;
        OUTPUT:
	  RETVAL

char*
bbici_name(ci)
	Bio::DB::bbiChromInfo ci
	CODE:
	RETVAL = ci->name;
        OUTPUT:
	  RETVAL

unsigned int
bbici_id(ci)
	Bio::DB::bbiChromInfo ci
	CODE:
	RETVAL = ci->id;
        OUTPUT:
	  RETVAL

unsigned int
bbici_size(ci)
	Bio::DB::bbiChromInfo ci
	CODE:
	RETVAL = ci->size;
        OUTPUT:
	  RETVAL

MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::bbiExtendedSummaryEl PREFIX=bwel_

unsigned long
bwel_validCount(el)
      Bio::DB::bbiExtendedSummaryEl el
      CODE:
        RETVAL = el->validCount;
      OUTPUT:
        RETVAL
    
double
bwel_minVal(el)
      Bio::DB::bbiExtendedSummaryEl el
      CODE:
        RETVAL = el->minVal;
      OUTPUT:
        RETVAL
    
double
bwel_maxVal(el)
      Bio::DB::bbiExtendedSummaryEl el
      CODE:
        RETVAL = el->maxVal;
      OUTPUT:
        RETVAL

double
bwel_sumData(el)
      Bio::DB::bbiExtendedSummaryEl el
      CODE:
        RETVAL = el->sumData;
      OUTPUT:
        RETVAL
    
double
bwel_sumSquares(el)
      Bio::DB::bbiExtendedSummaryEl el
      CODE:
        RETVAL = el->sumSquares;
      OUTPUT:
        RETVAL


MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::bbiExtendedSummary PREFIX=bwes_

int
bwes_size(el);
      Bio::DB::bbiExtendedSummary el
      CODE:
        RETVAL = el->size;
      OUTPUT:
        RETVAL

unsigned long
bwes_validCount(el,i)
      Bio::DB::bbiExtendedSummary el
      int i
      CODE:
        if (i>el->size-1)
	  croak("Attempt to read past end of ExtendedSummary results %d > %d",i,el->size-1);
        RETVAL = el->summary[i].validCount;
      OUTPUT:
        RETVAL
    
double
bwes_minVal(el,i)
      Bio::DB::bbiExtendedSummary el
      int i
      CODE:
        if (i>el->size-1)
	  croak("Attempt to read past end of ExtendedSummary results %d > %d",i,el->size-1);
        RETVAL = el->summary[i].minVal;
      OUTPUT:
        RETVAL
    
double
bwes_maxVal(el,i)
      Bio::DB::bbiExtendedSummary el
      int i
      CODE:
        if (i>el->size-1)
	  croak("Attempt to read past end of ExtendedSummary results %d > %d",i,el->size-1);
        RETVAL = el->summary[i].maxVal;
      OUTPUT:
        RETVAL

double
bwes_sumData(el,i)
      Bio::DB::bbiExtendedSummary el
      int i
      CODE:
        if (i>el->size-1)
	  croak("Attempt to read past end of ExtendedSummary results %d > %d",i,el->size-1);
        RETVAL = el->summary[i].sumData;
      OUTPUT:
        RETVAL
    
double
bwes_sumSquares(el,i)
      Bio::DB::bbiExtendedSummary el
      int i
      CODE:
        if (i>el->size-1)
	  croak("Attempt to read past end of ExtendedSummary results %d > %d",i,el->size-1);
        RETVAL = el->summary[i].sumSquares;
      OUTPUT:
        RETVAL

void
bwes_DESTROY(el)
      Bio::DB::bbiExtendedSummary el
      CODE:
      if (el->summary != NULL) {
	Safefree(el->summary);
      }
      el->summary = NULL;

MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::bbiIntervalList PREFIX=bbil_

Bio::DB::bbiInterval
bbil_head(list)
  Bio::DB::bbiIntervalList list
  CODE:
     RETVAL = list->head;
  OUTPUT:
     RETVAL

void
bbil_DESTROY(list)
  Bio::DB::bbiIntervalList list
  CODE:
  if (list->lm != NULL) lmCleanup(&list->lm);
  list->lm = NULL;

MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::bbiInterval PREFIX=bbii_

Bio::DB::bbiInterval
bbii_next(interval)
      Bio::DB::bbiInterval interval
  CODE:
     RETVAL = interval->next;
  OUTPUT:
     RETVAL

unsigned int
bbii_start(interval)
      Bio::DB::bbiInterval interval
  CODE:
     RETVAL = interval->start;
  OUTPUT:
     RETVAL

unsigned int
bbii_end(interval)
      Bio::DB::bbiInterval interval
  CODE:
     RETVAL = interval->end;
  OUTPUT:
     RETVAL

double
bbii_value(interval)
      Bio::DB::bbiInterval interval
  CODE:
     RETVAL = interval->val;
  OUTPUT:
     RETVAL

MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::asObject PREFIX=as_

Bio::DB::asObject
as_next(as)
   Bio::DB::asObject as
   CODE:
       RETVAL = as->next;
   OUTPUT:
       RETVAL


char*
as_name(as)
   Bio::DB::asObject as
   CODE:
       RETVAL = as->name;
   OUTPUT:
       RETVAL

char*
as_comment(as)
   Bio::DB::asObject as
   CODE:
     RETVAL = as->comment;
   OUTPUT:
     RETVAL

int
as_isTable(as)
   Bio::DB::asObject as
   CODE:
     RETVAL = as->isTable;
   OUTPUT:
     RETVAL

int
as_isSimple(as)
   Bio::DB::asObject as
   CODE:
   RETVAL = as->isSimple;
   OUTPUT:
     RETVAL

Bio::DB::asColumn
as_columnList(as)
   Bio::DB::asObject as
   CODE:
   RETVAL = as->columnList;
   OUTPUT:
   RETVAL

MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::asColumn PREFIX=asc_

Bio::DB::asColumn
asc_next(ac)
  Bio::DB::asColumn ac
  CODE:
  RETVAL = ac->next;
  OUTPUT:
  RETVAL

char*
asc_name(ac)
  Bio::DB::asColumn ac
  CODE:
  RETVAL = ac->name;
  OUTPUT:
  RETVAL

char*
asc_comment(ac)
  Bio::DB::asColumn ac
  CODE:
  RETVAL = ac->comment;
  OUTPUT:
  RETVAL

Bio::DB::asTypeInfo
asc_lowType(ac)
  Bio::DB::asColumn ac
  CODE:
  RETVAL = ac->lowType;
  OUTPUT:
  RETVAL


char*
asc_obName(ac)
  Bio::DB::asColumn ac
  CODE:
  RETVAL = ac->obName;
  OUTPUT:
  RETVAL

char*
asc_linkedSizeName(ac)
  Bio::DB::asColumn ac
  CODE:
  RETVAL = ac->linkedSizeName;
  OUTPUT:
  RETVAL

Bio::DB::asObject
asc_obType(ac)
  Bio::DB::asColumn ac
  CODE:
  RETVAL = ac->obType;
  OUTPUT:
  RETVAL

Bio::DB::asColumn
asc_linkedSize(ac)
  Bio::DB::asColumn ac
  CODE:
  RETVAL = ac->linkedSize;
  OUTPUT:
  RETVAL

int
asc_fixedSize(ac)
  Bio::DB::asColumn ac
  CODE:
    RETVAL = ac->fixedSize;
  OUTPUT:
  RETVAL

int
asc_isSizeLink(ac)
  Bio::DB::asColumn ac
  CODE:
    RETVAL = ac->isSizeLink;
  OUTPUT:
  RETVAL

int
asc_isList(ac)
  Bio::DB::asColumn ac
  CODE:
    RETVAL = ac->isList;
  OUTPUT:
  RETVAL

int
asc_isArray(ac)
  Bio::DB::asColumn ac
  CODE:
    RETVAL = ac->isArray;
  OUTPUT:
  RETVAL

MODULE = Bio::DB::BigFile PACKAGE = Bio::DB::asTypeInfo PREFIX=ast_

int
ast_type(ati)
    Bio::DB::asTypeInfo ati
    CODE:
    RETVAL = ati->type;
    OUTPUT:
    RETVAL

char*
ast_name(ati)
    Bio::DB::asTypeInfo ati
    CODE:
    RETVAL = ati->name;
    OUTPUT:
    RETVAL

int
ast_isUnsigned(ati)
    Bio::DB::asTypeInfo ati
    CODE:
    RETVAL = ati->isUnsigned;
    OUTPUT:
    RETVAL

int
ast_stringy(ati)
    Bio::DB::asTypeInfo ati
    CODE:
    RETVAL = ati->stringy;
    OUTPUT:
    RETVAL

char*
ast_sqlName(ati)
    Bio::DB::asTypeInfo ati
    CODE:
    RETVAL = ati->sqlName;
    OUTPUT:
    RETVAL

char*
ast_cName(ati)
    Bio::DB::asTypeInfo ati
    CODE:
    RETVAL = ati->cName;
    OUTPUT:
    RETVAL

char*
ast_listyName(ati)
    Bio::DB::asTypeInfo ati
    CODE:
    RETVAL = ati->listyName;
    OUTPUT:
    RETVAL

char*
ast_nummyName(ati)
    Bio::DB::asTypeInfo ati
    CODE:
    RETVAL = ati->nummyName;
    OUTPUT:
    RETVAL

char*
ast_outFormat(ati)
    Bio::DB::asTypeInfo ati
    CODE:
    RETVAL = ati->outFormat;
    OUTPUT:
    RETVAL











