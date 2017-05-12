%{
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "parsetime.h"
#include "panic.h"

#define YYDEBUG 1

struct tm exectm;
static int isgmt;
static int yearspec;
static int time_only;

extern int yyerror(char *s);
extern int yylex();

int add_date(int number, int period);
%}

%union {
	char *	  	charval;
	int		intval;
}

%token  <charval> DOTTEDDATE
%token  <charval> HYPHENDATE
%token  <charval> HOURMIN
%token  <charval> INT1DIGIT
%token  <charval> INT2DIGIT
%token  <charval> INT4DIGIT
%token  <charval> INT5_8DIGIT
%token  <charval> INT
%token  NOW
%token  AM PM
%token  NOON MIDNIGHT TEATIME
%token  SUN MON TUE WED THU FRI SAT
%token  TODAY TOMORROW
%token  NEXT
%token  MINUTE HOUR DAY WEEK MONTH YEAR
%token  JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC
%token  UTC

%type <charval> concatenated_date
%type <charval> hr24clock_hr_min
%type <charval> int1_2digit
%type <charval> int2_or_4digit
%type <charval> integer
%type <intval> inc_dec_period
%type <intval> inc_dec_number
%type <intval> day_of_week

%start timespec
%%
timespec        : spec_base
		| spec_base inc_or_dec
                ;

spec_base	: date
		| time
		{
		    time_only = 1;
		}
                | time date
                | NOW
		{
		    yearspec = 1;
		}
		;

time		: time_base
		| time_base timezone_name
                ;

time_base	: hr24clock_hr_min
		    {
			exectm.tm_min = -1;
			exectm.tm_hour = -1;
			sscanf($1, "%2d %2d", &exectm.tm_hour,
			    &exectm.tm_min);
			free($1);

			if (exectm.tm_min > 60 || exectm.tm_min < 0) {
			    yyerror("Problem in minutes specification");
			    YYERROR;
			}
			if (exectm.tm_hour > 24 || exectm.tm_hour < 0) {
			    yyerror("Problem in hours specification");
			    YYERROR;
		        }
		    }
		| time_hour am_pm
		| time_hour_min
		| time_hour_min am_pm
		| NOON
		    {
			exectm.tm_hour = 12;
			exectm.tm_min = 0;
		    }
                | MIDNIGHT
		    {
			exectm.tm_hour = 0;
			exectm.tm_min = 0;
		    }
		| TEATIME
		    {
			exectm.tm_hour = 16;
			exectm.tm_min = 0;
		    }
		;

hr24clock_hr_min: INT4DIGIT
		;

time_hour	: int1_2digit
		    {
			sscanf($1, "%d", &exectm.tm_hour);
			exectm.tm_min = 0;
			free($1);

			if (exectm.tm_hour > 24 || exectm.tm_hour < 0) {
			    yyerror("Problem in hours specification");
			    YYERROR;
		        }
		    }
		;

time_hour_min	: HOURMIN
		    {
			exectm.tm_min = -1;
			exectm.tm_hour = -1;
			sscanf($1, "%d %*c %d", &exectm.tm_hour,
			    &exectm.tm_min);
			free($1);

			if (exectm.tm_min > 60 || exectm.tm_min < 0) {
			    yyerror("Problem in minutes specification");
			    YYERROR;
			}
			if (exectm.tm_hour > 24 || exectm.tm_hour < 0) {
			    yyerror("Problem in hours specification");
			    YYERROR;
		        }
		    }
		;

am_pm		: AM
		    {
			if (exectm.tm_hour > 12) {
			    yyerror("Hour too large for AM");
			    YYERROR;
			}
			else if (exectm.tm_hour == 12) {
			    exectm.tm_hour = 0;
			}
		    }
		| PM
		    {
			if (exectm.tm_hour > 12) {
			    yyerror("Hour too large for PM");
			    YYERROR;
			}
			else if (exectm.tm_hour < 12) {
			    exectm.tm_hour +=12;
			}
		    }
		;

timezone_name	: UTC
		    {
			isgmt = 1;
		    }
		;

date            : month_name day_number
                | month_name day_number year_number
                | month_name day_number ',' year_number
                | day_of_week
		   {
		       add_date ((6 + $1 - exectm.tm_wday) %7 + 1, DAY);
		   }
                | TODAY
                | TOMORROW
		   {
			add_date(1, DAY);
		   }
		| HYPHENDATE
		   {
			int ynum = -1;
			int mnum = -1;
			int dnum = -1;

			yearspec = 1;
			if (sscanf($1, "%d %*c %d %*c %d", &ynum, &mnum, &dnum) != 3) {
			    yyerror("Error in hypenated date");
			    YYERROR;
			}

			if (mnum < 1 || mnum > 12) {
			    yyerror("Error in month number");
			    YYERROR;
			}
			exectm.tm_mon = mnum -1;

			if (ynum < 70) {
			    ynum += 100;
			}
			else if (ynum > 1900) {
			    ynum -= 1900;
			}
			exectm.tm_year = ynum ;

			if (   dnum < 1
			    || ((mnum ==  1 || mnum ==  3 || mnum ==  5 ||
			         mnum ==  7 || mnum ==  8 || mnum == 10 ||
				 mnum == 12) && dnum > 31)
			    || ((mnum ==  4 || mnum ==  6 || mnum ==  9 ||
			         mnum == 11) && dnum > 30)
			    || (mnum ==  2 && dnum > 29 &&  __isleap(ynum+1900))
			    || (mnum ==  2 && dnum > 28 && !__isleap(ynum+1900))
			   )
			{
			    yyerror("Error in day of month");
			    YYERROR; 
			}
			exectm.tm_mday = dnum;

			free($1);
		   }
		| DOTTEDDATE
		   {
			int ynum = -1;
			int mnum = -1;
			int dnum = -1;

			yearspec = 1;

			if (sscanf($1, "%d %*c %d %*c %d", &dnum, &mnum, &ynum) != 3) {
			    yyerror("Error in dotted date");
			    YYERROR;
			}

			if (mnum < 1 || mnum > 12) {
			    yyerror("Error in month number");
			    YYERROR;
			}
			exectm.tm_mon = mnum -1;

			if (ynum < 70) {
			    ynum += 100;
			}
			else if (ynum > 1900) {
			    ynum -= 1900;
			}
			exectm.tm_year = ynum ;

			if (   dnum < 1
			    || ((mnum ==  1 || mnum ==  3 || mnum ==  5 ||
			         mnum ==  7 || mnum ==  8 || mnum == 10 ||
				 mnum == 12) && dnum > 31)
			    || ((mnum ==  4 || mnum ==  6 || mnum ==  9 ||
			         mnum == 11) && dnum > 30)
			    || (mnum ==  2 && dnum > 29 &&  __isleap(ynum+1900))
			    || (mnum ==  2 && dnum > 28 && !__isleap(ynum+1900))
			   )
			{
			    yyerror("Error in day of month");
			    YYERROR; 
			}
			exectm.tm_mday = dnum;

			free($1);
		   }
		| day_number month_name
		| day_number month_name year_number
		| month_number '/' day_number '/' year_number
		| concatenated_date
		    {
			/* Ok, this is a kluge.  I hate design errors...  -Joey */
			char shallot[5];
			char *onion;

			yearspec = 1;
			onion=$1;
			memset (shallot, 0, sizeof (shallot));
			if (strlen($1) == 5 || strlen($1) == 7) {
			    strncpy (shallot,onion,1);
			    onion++;
			} else {
			    strncpy (shallot,onion,2);
			    onion+=2;
			}
			sscanf(shallot, "%d", &exectm.tm_mon);

			if (exectm.tm_mon < 1 || exectm.tm_mon > 12) {
			    yyerror("Error in month number");
			    YYERROR;
			}
			exectm.tm_mon--;

			memset (shallot, 0, sizeof (shallot));
			strncpy (shallot,onion,2);
		    	sscanf(shallot, "%d", &exectm.tm_mday);
			if (exectm.tm_mday < 0 || exectm.tm_mday > 31)
			{
			    yyerror("Error in day of month");
			    YYERROR;
			}

			onion+=2;
			memset (shallot, 0, sizeof (shallot));
			strncpy (shallot,onion,4);
			if ( sscanf(shallot, "%d", &exectm.tm_year) != 1) {
			    yyerror("Error in year");
			    YYERROR;
			}
			if (exectm.tm_year < 70) {
			    exectm.tm_year += 100;
			}
			else if (exectm.tm_year > 1900) {
			    exectm.tm_year -= 1900;
			}

			free ($1);
		    }
                | NEXT inc_dec_period		
		    {
			add_date(1, $2);
		    }
		| NEXT day_of_week
		    {
			add_date ((6 + $2 - exectm.tm_wday) %7 +1, DAY);
		    }
                ;

concatenated_date: INT5_8DIGIT
		;

month_name	: JAN { exectm.tm_mon = 0; }
		| FEB { exectm.tm_mon = 1; }
		| MAR { exectm.tm_mon = 2; }
		| APR { exectm.tm_mon = 3; }
		| MAY { exectm.tm_mon = 4; }
		| JUN { exectm.tm_mon = 5; }
		| JUL { exectm.tm_mon = 6; }
		| AUG { exectm.tm_mon = 7; }
		| SEP { exectm.tm_mon = 8; }
		| OCT { exectm.tm_mon = 9; }
		| NOV { exectm.tm_mon =10; }
		| DEC { exectm.tm_mon =11; }
		;

month_number	: int1_2digit
		    {
			{
			    int mnum = -1;
			    sscanf($1, "%d", &mnum);

			    if (mnum < 1 || mnum > 12) {
				yyerror("Error in month number");
				YYERROR;
			    }
			    exectm.tm_mon = mnum -1;
			    free($1);
			}
		    }
		;

day_number	: int1_2digit
                     {
			exectm.tm_mday = -1;
			sscanf($1, "%d", &exectm.tm_mday);
			if (exectm.tm_mday < 1 || exectm.tm_mday > 31)
			{
			    yyerror("Error in day of month");
			    YYERROR; 
			}
			free($1);
		     }
		;

year_number	: int2_or_4digit
		    { 
			yearspec = 1;
			{
			    int ynum;

			    if ( sscanf($1, "%d", &ynum) != 1) {
				yyerror("Error in year");
				YYERROR;
			    }
			    if (ynum < 70) {
				ynum += 100;
			    }
			    else if (ynum > 1900) {
				ynum -= 1900;
			    }

			    exectm.tm_year = ynum ;
			    free($1);
			}
		    }
		;

day_of_week	: SUN { $$ = 0; }
		| MON { $$ = 1; }
		| TUE { $$ = 2; }
		| WED { $$ = 3; }
		| THU { $$ = 4; }
		| FRI { $$ = 5; }
		| SAT { $$ = 6; }
		;

inc_or_dec	: increment
		| decrement
		;

increment       : '+' inc_dec_number inc_dec_period
		    {
		        add_date($2, $3);
		    }
                ;

decrement	: '-' inc_dec_number inc_dec_period
		    {
			add_date(-$2, $3);
		    }
		;

inc_dec_number	: integer
		    {
			if (sscanf($1, "%d", &$$) != 1) {
			    yyerror("Unknown increment");
			    YYERROR;
		        }
		        free($1);
		    }
		;

inc_dec_period	: MINUTE { $$ = MINUTE ; }
		| HOUR	 { $$ = HOUR   ; }
		| DAY	 { $$ = DAY    ; time_only = 0; }
		| WEEK   { $$ = WEEK   ; time_only = 0; }
		| MONTH  { $$ = MONTH  ; time_only = 0; }
		| YEAR   { $$ = YEAR   ; time_only = 0; }
		;

int1_2digit	: INT1DIGIT
		| INT2DIGIT
		;

int2_or_4digit	: INT2DIGIT
		| INT4DIGIT
		;

integer		: INT
		| INT1DIGIT
		| INT2DIGIT
		| INT4DIGIT
		| INT5_8DIGIT
		;

%%


time_t parsetime(time_t, int, char **);

time_t
parsetime(time_t currtime, int argc, char **argv)
{
    time_t exectime;
    struct tm currtm;

    my_argv = argv;
    exectm = *localtime(&currtime);
    currtime -= exectm.tm_sec;
    exectm.tm_sec = 0;
    exectm.tm_isdst = -1;
    memcpy(&currtm,&exectm,sizeof(currtm));
    time_only = 0;
    yearspec = 0;

    if (yyparse() == 0) {
	if (time_only)
	{
	    if (exectm.tm_mday == currtm.tm_mday &&
		(exectm.tm_hour < currtm.tm_hour ||
		(exectm.tm_hour == currtm.tm_hour &&
		    exectm.tm_min <= currtm.tm_min)))
		exectm.tm_mday++;
	} 
	else if (!yearspec) {
	    if (exectm.tm_year == currtm.tm_year &&
		(exectm.tm_mon < currtm.tm_mon ||
	        (exectm.tm_mon == currtm.tm_mon &&
		     exectm.tm_mday < currtm.tm_mday)))
		exectm.tm_year++;
	}

	exectime = mktime(&exectm);
	if (exectime == (time_t)-1)
	    return 0;
	if (isgmt) {
	    exectime -= timezone;
	    if (currtm.tm_isdst && !exectm.tm_isdst)
		exectime -= 3600;
	}
	if (exectime < currtime)
		panic("refusing to create job destined in the past");
        return exectime;
    }
    else {
	return 0;    
    }
}

#ifdef TEST_PARSER
 
int
main(int argc, char **argv)
{
    int retval = 1;
    time_t res;
    time_t currtime;

    if (argc < 3) {
	fprintf(stderr, "usage: parsetest [now] [timespec] ...\n");
	exit(EXIT_FAILURE);
    }

    currtime = atoll(argv[1]);
    res = parsetime(currtime, argc-2, argv + 2);
    if (res > 0) {
	printf("%s",ctime(&res));
	retval = 0;
    }
    else {
	printf("Ooops...\n");
	retval = 1;
    }
    return retval;
}

void
panic(char *a)
{
    fputs(a, stderr);
    exit(EXIT_FAILURE);
}
#endif

int yyerror(char *s)
{
    if (last_token == NULL)
	last_token = "(empty)";
    fprintf(stderr,"%s. Last token seen: %s\n",s, last_token);
    return 0;
}

void
add_seconds(struct tm *tm, long numsec)
{
    struct tm basetm = *tm;
    time_t timeval;

    timeval = mktime(tm);
    if (timeval == (time_t)-1)
        timeval = (time_t)0;
    timeval += numsec;
    *tm = *localtime(&timeval);

    /*
     * Adjust +-1 hour when moving in or out of DST
     */

    if (daylight > 0)	/* Only check if DST is used here */
    {
	/* Set tm_isdst on &basetm and tm */
	(void) mktime(&basetm);
	(void) mktime(tm);

	if      (basetm.tm_isdst > 0 && tm->tm_isdst < 1)
	{   /* DST to no DST */
	    timeval += 3600l;
	    *tm = *localtime(&timeval);
	}
	else if (basetm.tm_isdst < 1 && tm->tm_isdst > 0)
	{   /* no DST to DST */
	    timeval -= 3600l;
	    *tm = *localtime(&timeval);
	}
    }
}

int
add_date(int number, int period)
{
    switch(period) {
    case MINUTE:
	add_seconds(&exectm , 60l*number);
	break;

    case HOUR:
	add_seconds(&exectm, 3600l * number);
	break;

    case DAY:
	add_seconds(&exectm, 24*3600l * number);
	break;

    case WEEK:
	add_seconds(&exectm, 7*24*3600l*number);
	break;

    case MONTH:
	{
	    int newmonth = exectm.tm_mon + number;
	    number = 0;
	    while (newmonth < 0) {
		newmonth += 12;
		number --;
	    }
	    exectm.tm_mon = newmonth % 12;
	    number += newmonth / 12 ;

	    /* Recalculate tm_isdst so we don't get a +-1 hour creep */
	    exectm.tm_isdst = -1;
	    (void) mktime(&exectm);
	}
	if (number == 0) {
	    break;
	}
	/* fall through */

    case YEAR:
	exectm.tm_year += number;
	/* Recalculate tm_isdst so we don't get a +-1 hour creep */
	exectm.tm_isdst = -1;
	(void) mktime(&exectm);
	break;

    default:
	yyerror("Internal parser error");
	fprintf(stderr,"Unexpected case %d\n", period);
	abort();
    }

    return 0;
}
