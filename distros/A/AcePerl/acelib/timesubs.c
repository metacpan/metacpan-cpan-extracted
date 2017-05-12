/*  File: timesubs.c
 *  Author: Richard Durbin (rd@mrc-lmb.cam.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1991
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description: functions to handle times/dates

   * mieg, mars 94: timeParse/timeShow
      this pair of functions is to be used in conjunction
      with the _DateType fundamental type which can
      now be used in the same way as _Int _Float in models.wrm

 * HISTORY:
 * Last edited: Nov 27 13:19 1998 (fw)
 * * Jul  9 17:23 1998 (fw): added timeComparison() function for < , = and > operators
 * * Jul  8 15:49 1998 (fw): added timeDiff functions for mins,hours,months,years
                             as required by the new AQL date-functions
 * * Jan 29 22:31 1995 (rd): allow "today"  like "now", for day only
 * * Nov 13 19:04 1994 (rd): allow date abbreviations, and rename 
 	consistently, and removed timeStamp, dateStamp
 * * Jun 21 17:12 1992 (mieg): changed : to _ in time stamped
   : was preventing the file chooser from reading in a dump file
 * * Jan 20 10:46 1992 (mieg): Fixed  timeStamp, dateStamp
    and removed everything else with an ifdef
 * Created: a long time ago
 *-------------------------------------------------------------------
 */

/* $Id: timesubs.c,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#include "regular.h"
#include "mytime.h"
#include <time.h>

/* 
----------------------------------------------------------------------
Time string formats
1994-07-17_20:16:11     -- dumped and read
now                     -- replaced with current date and time
today                   -- replaced with current date only
94-07-17_20:16:11       -- interpreted as 1994-07-17_20:16:11

any left abbreviation of the above, e.g. 94-07-17, or 94-07 is also 
read, and when dumping any trailing 0 fields are ommitted.

the _ is optional, can be one blank

How to deal with timezones:

The internal time is always in GMT (Greenwich Mean Time) (an
alias for GMT is UTC (Coordinated Universal Time)).

For the external format I could not find a notation which shows
the local time and is easly convertable into internal time again on
every computer.

Therefore I left out the timezone information from the external format.
I leave it to the user what he wants:
While working locally or exchanging data within one timezone, there
is no fuss at all.
When transfering data across the ocean with the wish to keep the time
accurate, one can use this scheme:

1. in Montpellier:
   csh                 // opening an extra shell saves the environment
   setenv TZ GMT
   start xace/tace and dump into file.ace
   transfer file
   exit                // back in local timezone
2. in Berkeley:
   csh
   setenv TZ GMT
   use xace/tace to read file.ace
   exit
   start xace          // dates displayed will be correctly converted

What about putting a comment to the dump file giving the value
of the Environment variable TZ at the time the dump was done?

----------------------------------------------------------------------
  written by  D.Wolf@dkfz-heidelberg.de  Thu May  5 17:39:54 MDT 1994 
  tested ok on 
  OSF1  V1.3 111 alpha
  IRIX  4.0.5F 08280217 IP12
  SunOS 5.3 Generic sun4c sparc (Solaris)
  SunOS 4.1.2 2 sun4c with gcc version 2.3.3
  -- does not compile with /usr/ucb/cc on SunOS 4.1.2
*/


static mytime_t aceTime(struct tm *tm, 
			BOOL wantMonth, BOOL wantDay, BOOL wantHours,
			BOOL wantMins, BOOL wantSecs)
{ 
  mytime_t t = 0;

  if (tm->tm_year < 91) /* use timeless format */
    { 
      t |= tm->tm_year << 9;
      if (wantMonth)
	t |= (tm->tm_mon + 1) << 5;
      if (wantDay)
	t |= tm->tm_mday;
    }
  else
    {
      if (wantSecs)
	t |= 1 + tm->tm_sec;

      if (wantMins)
	t |= (tm->tm_min + 1) << 6;

      if (wantHours)
	t |= (tm->tm_hour + 1) << 12;
      
      if (wantDay)
	t |= tm->tm_mday << 17;
      
      if (wantMonth)
	t |= (tm->tm_mon + 1) << 22;
      
      t |= (tm->tm_year - 90) << 26; 
    }
  return t;
}
  
static void timeStruct(struct tm *tm, mytime_t t,
		BOOL *wantMonth, BOOL *wantDay, BOOL *wantHours,
		BOOL *wantMins, BOOL *wantSecs)
{
  unsigned int secs;
  unsigned int mins;
  unsigned int hours;
  unsigned int day;
  unsigned int month;
  unsigned int year;

  if (!t)
    {
      /* fprintf (stderr, "timeStruct() warning: received null t\n"); */
      tm->tm_year = 0;
      tm->tm_mon = 0;
      tm->tm_mday = 0;
      tm->tm_hour = 0;
      tm->tm_min = 0;
      tm->tm_sec = 0;
      tm->tm_wday = 0;
      tm->tm_yday = 0;
      tm->tm_isdst = -1;
      return;
    }

  secs = t & 0x3f;
  mins = (t >> 6) & 0x3f;
  hours = (t >> 12) & 0x1f;
  day = (t >> 17) & 0x1f;
  month = ( t >> 22) & 0xf;
  year = ( t >> 26) &0x3f;
  
  if (year == 0) /* before 1990, use time-less format. */
    { 
      secs = mins = hours = 0;
      day = t & 0x1f;
      month = (t >> 5) & 0x0f;
      year = (t >> 9) & 0x7f;
    }
  else 
    year += 90; 
  
  tm->tm_year = year;
  
  if (month == 0)
    { *wantMonth  = FALSE;
      tm->tm_mon = 0;
    }
  else
    { *wantMonth = TRUE;
      tm->tm_mon = month - 1;
    }
  
  if (day == 0)
    { *wantDay = FALSE;
      tm->tm_mday = 1;
    }
  else
    { *wantDay = TRUE;
      tm->tm_mday = day;
    }
  
  if (hours == 0)
    { *wantHours = FALSE;
      tm->tm_hour = 0;
    }
  else 
    { *wantHours = TRUE;
      tm->tm_hour = hours - 1;
    }

  if (mins == 0)
    { *wantMins = FALSE;
      tm->tm_min = 0;
    }
  else
    { *wantMins = TRUE;
      tm->tm_min = mins - 1;
    } 
  
  if (secs == 0)
    { *wantSecs = FALSE;
      tm->tm_sec = 0;
    }
  else
    { *wantSecs = TRUE;
      tm->tm_sec = secs -1;
    }
  tm->tm_isdst = -1;

  /* 
   * strftime() was crashing under various circumstances.  These
   * lines force tm to be internally consistent - LS 2/17/98 
   */
  tm->tm_wday = tm->tm_yday = 0;
  mktime(tm); /* mhmp 21.10.98 */
}

mytime_t timeNow(void)
{ 
  time_t t = time(0);
  return aceTime(localtime(&t), TRUE, TRUE, TRUE, TRUE, TRUE);
}
  
mytime_t timeParse (char *ace_time) 
{
  struct tm ts ;
  char *cp = ace_time;
  int v, n ;    /* number of chars read so far */
  BOOL wantSecs = FALSE, wantDay = FALSE, wantMonth = FALSE;
  BOOL wantMins = FALSE, wantHours = FALSE;
  if (!cp) 
    return 0 ;

  if (!strcmp (cp, "now"))
    { time_t t = time(0);
      return aceTime(localtime(&t), TRUE, TRUE, TRUE, TRUE, TRUE);
    }

  if (!strcmp (cp, "today"))
    { time_t t = time(0) ;
      return aceTime(localtime (&t), TRUE, TRUE, FALSE, FALSE, FALSE);
    }

  if ((v = sscanf (cp, "%d%n", &ts.tm_year, &n)) != 1)
    return 0;
  if (ts.tm_year > 2053)
    return 0;
  cp += n ;
  if ((v = sscanf (cp, "-%d%n", &ts.tm_mon, &n)) != 1)
    goto done ;
  if (ts.tm_mon > 12 || ts.tm_mon < 1)
    return 0;
  wantMonth = TRUE;
  cp += n ;
  if ((v = sscanf (cp, "-%d%n", &ts.tm_mday, &n)) != 1)
    goto done ;
  if (ts.tm_mday > 31)
    return 0;
  wantDay = TRUE;
  cp += n ;
  if (*cp == 0)
    goto done ;
  if (*cp != '_' && *cp != ' ') /* separator */
    return 0;
  ++cp ;
  if ((v = sscanf (cp, "%d%n", &ts.tm_hour, &n)) != 1)
    goto done ;
  if (ts.tm_hour > 23)
    return 0;
  wantHours = TRUE;
  ts.tm_min = 0;
  ts.tm_sec = 0;
  cp += n ;
  if ((v = sscanf (cp, ":%d%n", &ts.tm_min, &n)) != 1)
    goto done ;
  if (ts.tm_min > 59)
    return 0;
  wantMins = TRUE;
  cp += n ;
  if ((v = sscanf (cp, ":%d%n", &ts.tm_sec, &n)) != 1)
    goto done ;
  if (ts.tm_sec > 59)
    return 0;
  wantSecs = TRUE;
  cp += n ;

 done:
  if (*cp) return 0;	/* incomplete */
   
  if (ts.tm_year < 1900)	/* convert into 4 digit-year */
    { if (ts.tm_year > 50) 
	ts.tm_year += 1900 ;
      else               
	ts.tm_year += 2000 ;
    } 
  
  ts.tm_year -= 1900 ;
  ts.tm_mon-- ;			/* January is 0 */
  
  return aceTime(&ts, wantMonth, wantDay, wantHours, wantMins, wantSecs) ;
}

/**********************************************/

char *timeShowJava (mytime_t t) 
{
  static char ace_time[25] ;
  struct tm ts;
  BOOL wantMonth, wantDay, wantHours, wantMins, wantSecs;


  if (!t)
    {
      /*   fprintf(stderr, "timeShowJava() warning: received NULL value\n"); */
      return "" ;
    }

  timeStruct(&ts, t, &wantMonth, &wantDay, &wantHours, &wantMins, &wantSecs);
  if (!wantMonth)
    strftime (ace_time, 25, "01 JAN %Y 00:00:00", &ts) ;
  else if (!wantDay)
    strftime (ace_time, 25, "01 %b %Y 00:00:00", &ts) ;
  else if (!wantHours)
    strftime (ace_time, 25, "%d %b %Y 00:00:00", &ts) ;
  else if (!wantMins)
    strftime(ace_time, 25, "%d %b %Y %H:00:00", &ts);
  else if (!wantSecs)
    strftime (ace_time, 25, "%d %b %Y %R:00", &ts);
  else
    strftime (ace_time, 25, "%d %b %Y %T", &ts) ;
    
  return ace_time ;
}

/**********************************************/

char *timeShow (mytime_t t) 
{
  static char ace_time[25] ;
  struct tm ts;
  BOOL wantMonth, wantDay, wantHours, wantMins, wantSecs;

  if (!t)
    {
      /*   fprintf(stderr, "timeShow() warning: received NULL value\n"); */
      return "" ;
    }

  timeStruct(&ts, t, &wantMonth, &wantDay, &wantHours, &wantMins, &wantSecs);
  if (!wantMonth)
    strftime (ace_time, 25, "%Y", &ts) ;
  else if (!wantDay)
    strftime (ace_time, 25, "%Y-%m", &ts) ;
  else if (!wantHours)
    strftime (ace_time, 25, "%Y-%m-%d", &ts) ;
  else if (!wantMins)
    strftime(ace_time, 25, "%Y-%m-%d_%H", &ts);
  else if (!wantSecs)
    strftime (ace_time, 25, "%Y-%m-%d_%R", &ts);
  else
    strftime (ace_time, 25, "%Y-%m-%d_%T", &ts) ;
    
  return ace_time ;
}

/**********************************************/

BOOL timeDiffSecs (mytime_t t1, mytime_t t2, int *diff) 
{
  struct tm ts1, ts2;
  BOOL wantMonth1, wantDay1, wantHours1, wantMins1, wantSecs1;
  BOOL wantMonth2, wantDay2, wantHours2, wantMins2, wantSecs2;
  double d ;
  time_t tt1, tt2 ;
  timeStruct (&ts1, t1, &wantMonth1, &wantDay1, &wantHours1, &wantMins1, &wantSecs1) ;
  timeStruct (&ts2, t2, &wantMonth2, &wantDay2, &wantHours2, &wantMins2, &wantSecs2) ;

  if (!wantSecs1 || !wantSecs2)
    return FALSE ;
  tt1 = mktime (&ts1) ;
  tt2 = mktime (&ts2) ;
  d = difftime (tt2, tt1) ;
  /*  d = difftime (mktime (&ts2), mktime (&ts1)) ;*/
  *diff = (int)d ;
  return TRUE ;
}

/**********************************************/

BOOL timeDiffMins (mytime_t t1, mytime_t t2, int *diff) 
{
  struct tm ts1, ts2;
  BOOL wantMonth1, wantDay1, wantHours1, wantMins1, wantSecs1;
  BOOL wantMonth2, wantDay2, wantHours2, wantMins2, wantSecs2;
  double d;

  timeStruct (&ts1, t1, &wantMonth1, &wantDay1, &wantHours1, &wantMins1, &wantSecs1) ;
  timeStruct (&ts2, t2, &wantMonth2, &wantDay2, &wantHours2, &wantMins2, &wantSecs2) ;

  if (!wantMins1 || !wantMins2)
    return FALSE ;

  ts1.tm_sec = ts2.tm_sec = 0 ;

  d = difftime (mktime (&ts2), mktime (&ts1)) ;
  d /= 60;
  *diff = (int)d ;

  return TRUE ;
}

/**********************************************/

BOOL timeDiffHours (mytime_t t1, mytime_t t2, int *diff) 
{
  struct tm ts1, ts2;
  BOOL wantMonth1, wantDay1, wantHours1, wantMins1, wantSecs1;
  BOOL wantMonth2, wantDay2, wantHours2, wantMins2, wantSecs2;
  double d;

  timeStruct (&ts1, t1, &wantMonth1, &wantDay1, &wantHours1, &wantMins1, &wantSecs1) ;
  timeStruct (&ts2, t2, &wantMonth2, &wantDay2, &wantHours2, &wantMins2, &wantSecs2) ;

  if (!wantHours1 || !wantHours2)
    return FALSE ;

  ts1.tm_sec = ts2.tm_sec = 0 ;
  ts1.tm_min = ts2.tm_min = 0 ;

  d = difftime (mktime (&ts2), mktime (&ts1)) ;
  d /= (60 * 60);
  *diff = (int)d ;

  return TRUE ;
}

/**********************************************/

BOOL timeDiffDays (mytime_t t1, mytime_t t2, int *diff) 
{
  struct tm ts1, ts2;
  BOOL wantMonth1, wantDay1, wantHours1, wantMins1, wantSecs1;
  BOOL wantMonth2, wantDay2, wantHours2, wantMins2, wantSecs2;
  double d ;

  timeStruct (&ts1, t1, &wantMonth1, &wantDay1, &wantHours1, &wantMins1, &wantSecs1) ;
  timeStruct (&ts2, t2, &wantMonth2, &wantDay2, &wantHours2, &wantMins2, &wantSecs2) ;

  if (!wantDay1 || !wantDay2)
    return FALSE ;

  ts1.tm_sec = ts2.tm_sec = 0 ;	/* zero hours:mins:secs so get calendar days */
  ts1.tm_min = ts2.tm_min = 0 ;
  ts1.tm_hour = ts2.tm_hour = 0 ;

  d = difftime (mktime (&ts2), mktime (&ts1)) ;

  d /= (24 * 3600) ;
  *diff = (int)d ;

  return TRUE ;
}

/**********************************************/

BOOL timeDiffMonths (mytime_t t1, mytime_t t2, int *diff) 
{
  struct tm ts1, ts2;
  BOOL wantMonth1, wantDay1, wantHours1, wantMins1, wantSecs1;
  BOOL wantMonth2, wantDay2, wantHours2, wantMins2, wantSecs2;
  int mdiff;

  timeStruct (&ts1, t1, &wantMonth1, &wantDay1, &wantHours1, &wantMins1, &wantSecs1) ;
  timeStruct (&ts2, t2, &wantMonth2, &wantDay2, &wantHours2, &wantMins2, &wantSecs2) ;

  if (!wantMonth1 || !wantMonth2)
    return FALSE ;

  mdiff = ts2.tm_mon - ts1.tm_mon ;

  *diff = mdiff ;

  return TRUE ;
}

/**********************************************/

BOOL timeDiffYears (mytime_t t1, mytime_t t2, int *diff) 
/* NOTE: is always true, i.e. every date/time has a year */
{
  struct tm ts1, ts2;
  BOOL wantMonth1, wantDay1, wantHours1, wantMins1, wantSecs1;
  BOOL wantMonth2, wantDay2, wantHours2, wantMins2, wantSecs2;
  int yeardiff;

  timeStruct (&ts1, t1, &wantMonth1, &wantDay1, &wantHours1, &wantMins1, &wantSecs1) ;
  timeStruct (&ts2, t2, &wantMonth2, &wantDay2, &wantHours2, &wantMins2, &wantSecs2) ;

  yeardiff = ts2.tm_year - ts1.tm_year ;

  *diff = yeardiff ;

  return TRUE ;
}

/**********************************************/

/* compare two dates, returns boolean result of comparison depending on operator */
BOOL timeComparison (int      op,
		     mytime_t timeLeft, 
		     mytime_t timeRight)
/* op is the operator and is one of
   -1 = isLessThan
    0 = isEqual
    1 = isGreaterThan

   times can easily be compared, if they both specify the
   same level of detail, e.g.
        1996-03 < 1997-04        -> TRUE
     1998-06-07 = 1998-06-12     -> FALSE

   Complications occur, if the level of detail given varies in both dates :-

        1998-06 < 1998-07-09_09:51:23 -> TRUE
         the "lessthan" fact is decided on the months

           1990 = 1990-05-02   -> TRUE
     in case of equality the comparison asks if the lesser detailed date 
     is completely contained within the other, and the above 
     comparison evaluates TRUE, because May 2nd 1990 is in the year 1990

         1998-07 < 1998-07-09   -> FALSE
     because one date gives a specific day in July 1998, but as the
     first date misses the day, we can't decide whether it is earlier.
      
     Example: the movie City Hall was released on 1996-02-16.
        
       select m->Title, m->Released from m in class Movie where m->Released < `1996-02
       select m->Title, m->Released from m in class Movie where m->Released > `1996-02

     will BOTH EXnclude the movie 'City Hall', whereas
     
       select m->Title, m->Released from m in class Movie where m->Released < `1996-02-17
       select m->Title, m->Released from m in class Movie where m->Released <= `1996-02

     will both INclude 'City Hall'.
*/
/* mhmp 22.10.98
Ici, chaque date,  quel que soit son niveau de detail, est consideree
comme un intervalle.
1996-05  = [1996-05-01_00:00:00 , 1996-05-31_23:59:59] = INTER
date == 1996-05 <==> date appartient a INTER
date < 1996-05  <==> date < inf(INTER)

Appliquer cette regle aux dates "completees" (avec hms) est discutable.
Pour beaucoup,  1998-10-22_11:07 > 1998-10-22_11
surtout quand on vient de louper le train de 11h.
Cela sous-entend qu'il faudrait completer les dates
hms jusqu'a la seconde avec des zeros.
1998-10-22_11 -> 1998-10-22_11:00:00
*/
{
  int yearDiff, monthDiff, dayDiff, hourDiff, minDiff, secDiff;

  /*******************/
  /* year difference */
  timeDiffYears (timeLeft, timeRight, &yearDiff);
  
  if (yearDiff > 0)
    return (op < 0) ;

  if (yearDiff < 0)
    return (op > 0) ;

  /* yearDiff == 0 */
  /********************/
  /* month difference */
  if (!timeDiffMonths (timeLeft, timeRight, &monthDiff))
    /* can't decide on months */
    return (op == 0) ;

  if (monthDiff > 0)
    return (op < 0) ;

  if (monthDiff < 0) 
    return  (op > 0) ;

  /* monthDiff == 0 */
  /******************/
  /* day difference */
  if (!timeDiffDays (timeLeft, timeRight, &dayDiff))
    /* can't decide on days */
    return (op == 0) ;

  if (dayDiff > 0)
    return (op < 0) ;    

  if (dayDiff < 0)
    return  (op > 0) ;
	  
  /* dayDiff == 0 */
  /*******************/
  /* hour difference */
  if (!timeDiffHours (timeLeft, timeRight, &hourDiff))
    /* can't decide on hours */
    return (op == 0) ;

  if (hourDiff > 0)
    return (op < 0) ; 

  if (hourDiff < 0)
    return  (op > 0) ;
	  
  /*  hourDiff == 0 */
  /*********************/
  /* minute difference */
  if (!timeDiffMins (timeLeft, timeRight, &minDiff))
    /* can't decide on minutes */
    return (op == 0) ;

  if (minDiff > 0)
    return (op < 0) ; 

  if (minDiff < 0)
    return  (op > 0) ;
	  
  /* minDiff == 0 */
  /*********************/
  /* second difference */
  if (!timeDiffSecs (timeLeft, timeRight, &secDiff))
    /* can't decide on seconds */
    return (op == 0) ;

  if (secDiff > 0)
    return (op < 0) ; 

  if (secDiff < 0)
    return  (op > 0) ;
	  
  /* secDiff == 0 */
  /*********************/
    /* can't decide on 1/10 of second */
  return (op == 0) ;
} /* timeComparison */

/*************************************************************/

char *timeDiffShow (mytime_t t1, mytime_t t2) 
{
  static char buf[25] ;
  struct tm ts1, ts2;
  BOOL wantMonth1, wantDay1, wantHours1, wantMins1, wantSecs1;
  BOOL wantMonth2, wantDay2, wantHours2, wantMins2, wantSecs2;
  int ydiff, mdiff, ddiff, hdiff, mindiff, sdiff ;

  if (t2 < t1)
    { mytime_t temp = t1 ;
      t1 = t2 ;
      t2 = temp ;
      strcpy (buf, "-") ;
    }
  else
    *buf = 0 ;

  timeStruct(&ts1, t1, &wantMonth1, &wantDay1, &wantHours1, &wantMins1, &wantSecs1);
  timeStruct(&ts2, t2, &wantMonth2, &wantDay2, &wantHours2, &wantMins2, &wantSecs2);

  ydiff = ts2.tm_year - ts1.tm_year ;
  mdiff = ts2.tm_mon - ts1.tm_mon ;
  hdiff = ts2.tm_hour - ts1.tm_hour ;
  mindiff = ts2.tm_min - ts1.tm_min ;
  sdiff = ts2.tm_sec - ts1.tm_sec ;
     
  if (wantSecs1 && wantSecs2)
    { if (sdiff < 0) { sdiff += 60 ; --mindiff ; } }
  else
    ts1.tm_sec = ts2.tm_sec = 0 ;
  if (wantMins1 && wantMins2)
    { if (mindiff < 0) { mindiff += 60 ; --hdiff ; } }
  else
    ts1.tm_min = ts2.tm_min = 0 ;
  if (wantHours1 && wantHours2)
    { if (hdiff < 0) { hdiff += 24 ; } }
  else
    ts1.tm_hour = ts2.tm_hour = 0 ;
  if (wantDay1 && wantDay2)
    {				/* convert months/years to days */
      double d = difftime (mktime (&ts2), mktime (&ts1)) ;
      d /= (24 * 3600) ;
      ddiff = d ;
      if (!wantHours1 || !wantHours2)
	strcat (buf, messprintf ("%d", ddiff)) ;
      else
	{ if (ddiff)
	    strcat (buf, messprintf ("%d_", ddiff)) ;
	  strcat (buf, messprintf ("%02d:%02d", hdiff, mindiff)) ;
	  if (wantSecs1 && wantSecs2)
	    strcat (buf, messprintf (":%02d", sdiff)) ;
	}
    }
  else
    { if (wantMonth1 && wantMonth2 && mdiff < 0) 
	{ mdiff += 12 ; --ydiff ; }
      if (ydiff)
	strcat (buf, messprintf ("%d-%02d-0", ydiff, mdiff)) ;
      else
	strcat (buf, messprintf ("%d-0", mdiff)) ;
    }
    
  return buf ;
}

/***********************************************/

/* suz added a more general version to format data strings */

char* timeShowFormat (mytime_t t, char *format, char *buf, int bufsize)
{ BOOL dummy;
  struct tm ts;
  timeStruct(&ts, t, &dummy, &dummy, &dummy, &dummy, &dummy);
  
  strftime (buf, bufsize, format, &ts) ;
  return buf ;
}

/**********************************/
/**********************************/


