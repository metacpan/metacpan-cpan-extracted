/* 
Copyright: (c) 1999 Daniel Yacob, dmulholl@cs.indiana.edu. All rights
	reserved. This library is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <libeth/langxs.h>
#include <libeth/ettime.h>
#include <libeth/etstdlib.h>

MODULE = Convert::Ethiopic		PACKAGE = Convert::Ethiopic


float
LibEthVersion ()


unsigned char *
LibEthVersionName ()


unsigned char *
ConvertEthiopicString (string, sysIn, xferIn, sysOut, xferOut, fontOut, langOut, iPath, options, closing)
	char* string;
	int sysIn;
	int xferIn;
	int sysOut;
	int xferOut;
	int fontOut;
	enum Languages langOut;
	char* iPath;
	unsigned int options;
	int closing;


unsigned char *
ArabToEthiopic (Enumber, system, xfer, font, iPath)
	char* Enumber;
	int system;
	int xfer;
	int font;
	char* iPath;


long int
EthiopicToFixed ( date, month, year )
	int date;
	int month;
	long int year;


long int
GregorianToFixed ( date, month, year )
	int date;
	int month;
	long int year;


void
FixedToEthiopic ( fixed, date, month, year )
	long int fixed;
	int date;
	int month;
	long int year;
	CODE:
		FixedToEthiopic ( fixed, &date, &month, &year );
		OUTPUT:
		date
		month
		year


void
FixedToGregorian ( fixed, date, month, year )
	long int fixed;
	int date;
	int month;
	long int year;
	CODE:
		FixedToGregorian ( fixed, &date, &month, &year );
		OUTPUT:
		date
		month
		year


unsigned char *
isEthiopianHoliday ( date, month, year, LCInfo )
	int date;
	int month;
	long int year;
	unsigned int LCInfo;


boolean
isEthiopicLeapYear ( year )
	long int year;


boolean
isLeapYear ( year )
	long int year;


unsigned char *
getEthiopicMonth ( month, lang, LCInfo )
  int month;
  enum Languages lang;
  unsigned int LCInfo;


unsigned char *
getEthiopicDayOfWeek ( date, month, year, langOut, LCInfo )
	int date;
	int month;
	long int year;
	enum Languages langOut;
	unsigned int LCInfo;


unsigned char *
getEthiopicDayName ( date, month, LCInfo )
  int date;
  int month;
  unsigned int LCInfo;


boolean
isBogusEthiopicDate ( date, month, year )
	int date;
	int month;
	long int year;


boolean
isBogusGregorianDate ( date, month, year )
	int date;
	int month;
	long int year;


void
GregorianToEthiopic ( date, month, year )
	int date;
	int month;
	long int year;
	CODE:
		GregorianToEthiopic (&date, &month, &year);
		OUTPUT:
		date
		month
		year


void
EthiopicToGregorian ( date, month, year )
	int date;
	int month;
	long int year;
	CODE:
		EthiopicToGregorian (&date, &month, &year);
		OUTPUT:
		date
		month
		year


void
ConvertEthiopicFile (fileIn, fileOut, sysIn, xferIn, sysOut, xferOut, fontOut, langOut, iPath, options)
	FILE* fileIn;
	FILE* fileOut;
	int sysIn;
	int xferIn;
	int sysOut;
	int xferOut;
	int fontOut;
	enum Languages langOut;
	char* iPath;
	unsigned int options;


unsigned char *
ConvertEthiopicFileToString (fileP, sysIn, xferIn, sysOut, xferOut, fontOut, langOut, iPath, options)
	FILE* fileP;
	int sysIn;
	int xferIn;
	int sysOut;
	int xferOut;
	int fontOut;
	enum Languages langOut;
	char* iPath;
	unsigned int options;


unsigned char *
easctime ( t0, t1, t2, t3, t4, t5, t6, t7, t8, langIn, langOut, LCInfo )
	int t0;
	int t1;
	int t2;
	int t3;
	int t4;
	int t5;
	int t6;
	int t7;
	int t8;
	enum Languages langIn;
	enum Languages langOut;
	unsigned int LCInfo;
	CODE:
		struct tm* time = (struct tm* ) malloc ( sizeof(struct tm) );
		time->tm_sec   = t0;
		time->tm_min   = t1;
		time->tm_hour  = t2;
		time->tm_mday  = t3;
		time->tm_mon   = t4;
		time->tm_year  = t5;
		time->tm_wday  = t6;
		time->tm_yday  = t7;
		time->tm_isdst = t8;

		RETVAL = easctime ( time, langIn, langOut, LCInfo );

	OUTPUT:
	RETVAL
