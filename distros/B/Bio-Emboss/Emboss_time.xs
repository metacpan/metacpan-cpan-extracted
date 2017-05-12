#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_time		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajtime.c: automatically generated

void
ajTimeTrace (thys)
       const AjPTime thys

AjBool
ajTimeSetS (thys, timestr)
       AjPTime thys
       const AjPStr timestr
    OUTPUT:
       RETVAL
       thys

AjPTime
ajTimeNew ()
    OUTPUT:
       RETVAL

void
ajTimeDel (Ptime)
       AjPTime& Ptime
    OUTPUT:
       Ptime

void
ajTimeExit ()

AjPTime
ajTimeNewDayFmt (timefmt, mday, mon, year)
       const char* timefmt
       ajint mday
       ajint mon
       ajint year
    OUTPUT:
       RETVAL

AjPTime
ajTimeNewTime (src)
       const AjPTime src
    OUTPUT:
       RETVAL

AjPTime
ajTimeNewToday ()
    OUTPUT:
       RETVAL

AjPTime
ajTimeNewTodayFmt (timefmt)
       const char* timefmt
    OUTPUT:
       RETVAL

time_t
ajTimeGetTimetype (thys)
       const AjPTime thys
    OUTPUT:
       RETVAL

const AjPTime
ajTimeRefToday ()
    OUTPUT:
       RETVAL

const AjPTime
ajTimeRefTodayFmt (timefmt)
       const char* timefmt
    OUTPUT:
       RETVAL

AjBool
ajTimeSetC (thys, timestr)
       AjPTime thys
       const char* timestr
    OUTPUT:
       RETVAL
       thys

AjBool
ajTimeSetLocal (thys, timer)
       AjPTime thys
       const time_t timer
    OUTPUT:
       RETVAL
       thys

