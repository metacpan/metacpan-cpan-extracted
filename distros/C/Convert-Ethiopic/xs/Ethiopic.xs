/* 
Copyright: (c) 1999 Daniel Yacob, dmulholl@cs.indiana.edu. All rights
	reserved. This library is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.
*/

#include "Ethiopic.h"

void
extractSettings ( HV * in, HV * out, int * sysIn, int * xferIn, int * sysOut, int * xferOut, int * fontOut, enum Languages * langOut, unsigned int * options )
{
SV ** sv;

	if ( in ) {
		//fprintf ( stderr, "IN: fetching sysNum\n" );
		sv      = hv_fetch ( in, "sysNum", 6, 0 );
		*sysIn   = (int)SvIV(*sv);

		//fprintf ( stderr, "IN: fetching xferNum\n" );
		sv      = hv_fetch ( in, "xferNum", 7, 0 );
		*xferIn  = (int)SvIV(*sv);
	}

	if ( out ) {
		//fprintf ( stderr, "OUT: fetching sysNum\n" );
		sv      = hv_fetch ( out, "sysNum", 6, 0 );
		*sysOut   = (int)SvIV(*sv);

		//fprintf ( stderr, "OUT: fetching xferNum\n" );
		sv      = hv_fetch ( out, "xferNum", 7, 0 );
		*xferOut = (int)SvIV(*sv);

		//fprintf ( stderr, "OUT: fetching fontNum\n" );
		sv      = hv_fetch ( out, "fontNum", 7, 0 );
		*fontOut = (int)SvIV(*sv);

		if ( langOut ) {
		// fprintf ( stderr, "OUT: fetching langNum\n" );
			sv      = hv_fetch ( out, "langNum", 7, 0 );
			*langOut = (int)SvIV(*sv);
		}

		if ( options ) {
		// fprintf ( stderr, "OUT: fetching option\n" );
			sv      = hv_fetch ( out, "options", 7, 0 );
			*options = (unsigned int)SvUV(*sv);
		}
	}
		// fprintf ( stderr, "Returning\n" );

}


void
getDatesFromHash ( HV * hv, int * date, int * month, long int * year )
{
SV ** sv;


	if ( date ) {
		sv      = hv_fetch ( hv, "date", 4, 0 );
		*date  = (int)SvIV(*sv);
	}

	if ( month ) {
		sv     = hv_fetch ( hv, "month", 5, 0 );
		*month = (int)SvIV(*sv);
	}

	if ( year ) {
		sv     = hv_fetch ( hv, "year", 4, 0 );
		*year  = (long int)SvIV(*sv);
	}

}



void
getDateArgs ( I32 ax, int items, int * date, int * month, long int * year )
{
dSP;
HV * hv;

	
	if ( items > 1 ) {
		if( SvROK(ST(1)) && (SvTYPE(SvRV(ST(1))) == SVt_PVHV) ) {
			hv = (HV*)SvRV( ST(1) );
			getDatesFromHash ( hv, date, month, year );
		}
		else {
			*date  = (int)SvIV ( ST(1) );
			*month = (int)SvIV ( ST(2) );
			*year  = (int)SvIV ( ST(3) );
		}

	}
	else {
		hv = (HV*)SvRV( ST(0) );
		getDatesFromHash ( hv, date, month, year );
	}


}



HV *
newDate ( enum CalendarSys context, int date, int month, long int year, enum Languages langOut )
{

	HV * hv = newHV();

	hv_store ( hv, "date",    4, newSViv (date), 0 );
	hv_store ( hv, "month",   5, newSViv (month), 0 );
	hv_store ( hv, "year",    4, newSViv (year), 0 );
	hv_store ( hv, "langOut", 7, newSViv (langOut), 0 );
	if ( context == ethio )
		hv_store ( hv, "calsys", 6, newSVpv ("ethio", 5), 0 );
	else	
		hv_store ( hv, "calsys", 6, newSVpv ("euro", 4), 0 );

	/*
	 *  we may want to pass this in the future:
	 */
	hv_store ( hv, "LCInfo", 6, newSViv(0), 0 );

	return ( hv );
}



enum CalendarSys
getContext ( HV * hv )
{
SV ** sv;

	sv  = hv_fetch ( hv, "calsys", 6, 0 );

	return (! strcmp ( "ethio", (char *)SvPV(*sv, PL_na) ) )
	  ? ethio
	  : euro
	;

}



#include "systems/taligent/cvtutf.h"
#include "systems/unicode.h"



FCHAR
xsUTF8ToUnicode ( unsigned char * uchar )
{

FCHAR fch = NIL;
register int i=0, j;
UTF8*  utf8Char;
UTF16* utf16Char;
unsigned char extraBytesToRead;


  utf8Char  = (UTF8  *) calloc ( 4 , sizeof (UTF8) );
  utf16Char = (UTF16 *) calloc ( 2 , sizeof (UTF16) );

  utf8Char[i++] = uchar[0];
  extraBytesToRead = bytesFromUTF8[utf8Char[i-1]];

  for (j = 1; j <= extraBytesToRead; j++)
    utf8Char[i++] = uchar[j];                       /* read next char */

  ConvertUTF8toUTF16 ( &utf8Char, utf8Char+i, &utf16Char, utf16Char+1 );

  fch = (FCHAR) *--utf16Char;
  utf8Char -= i;

  free (utf8Char);
  free (utf16Char);


  return (fch);

}



FCHAR
xs_get_fchar ( I32 ax, int items )
{
dSP;
unsigned char * uchar;


	if ( items == 2 )
		uchar = (unsigned char *)SvPV(ST(2), PL_na);
	else {
		HV * hv;
		SV ** sv;

		hv = (HV*)SvRV( ST(1) );
		sv    = hv_fetch ( hv, "char", 4, 0 );
		uchar = (unsigned char *)SvPV(*sv, PL_na);
	}

	
	return ( xsUTF8ToUnicode ( uchar ) );

}


unsigned char *
FCHARToUTF8 ( FCHAR * fstring )
{
UTF8*  utf8Char, *utf8CharStart;
UTF16*  utf16Char;
char utf8CharLength;
unsigned char* returnCh = NULL;



	utf8CharStart =
  	utf8Char      = (UTF8  *) malloc ( 4 * sizeof (UTF8) );
	utf16Char     = (UTF16 *) fstring;


  	ConvertUTF16toUTF8 ( &utf16Char, utf16Char+1, &utf8Char, utf8Char+3 );

  	utf8CharLength = (utf8Char - utf8CharStart);

  	utf8Char -= utf8CharLength;

  	returnCh = (unsigned char *) malloc ( utf8CharLength * sizeof(unsigned char) );

  	returnCh[0] = (unsigned char) utf8Char[0];

	if ( utf8CharLength > 1 )
		returnCh[1] = (unsigned char) utf8Char[1];
  	if ( utf8CharLength > 2 )
		returnCh[2] = (unsigned char) utf8Char[2];

  	returnCh[(int)utf8CharLength] = '\0';

	Safefree (utf8Char);
  	Safefree (--utf16Char);

	return ( returnCh );
}



/*
#=============================================================================*/

MODULE = Convert::Ethiopic		PACKAGE = Convert::Ethiopic

#===============================================================================

PROTOTYPES: DISABLE


float
LibEthVersion ()



unsigned char *
LibEthVersionName ()



unsigned char *
ArabToEthiopic ( number, out, ... )
	char * number;
	Convert::Ethiopic::System out

	PREINIT:
		int sysOut;
		int xferOut;
		int fontOut;
		char * iPath = NULL;

	CODE:

		if ( items == 3 )
			iPath = (char *)SvPV(ST(1), PL_na);

		extractSettings ( NULL, out, NULL, NULL, &sysOut, &xferOut, &fontOut, NULL, NULL );

		RETVAL = ArabToEthiopic ( number, sysOut, xferOut, fontOut, iPath );

	OUTPUT:
	RETVAL



unsigned char *
ConvertEthiopicString ( string, in, out, ... )
	char * string;
	Convert::Ethiopic::System in
	Convert::Ethiopic::System out

	PREINIT:
		int sysIn;
		int xferIn;
		int sysOut;
		int xferOut;
		int fontOut;
		enum Languages langOut;
		unsigned int options;
		int closing = 0;
		char* iPath = NULL;

	CODE:
		extractSettings ( in, out, &sysIn, &xferIn, &sysOut, &xferOut, &fontOut, &langOut, &options );

		if (items > 3 )
			closing = (int)SvIV(ST(3));

		if (items > 4 )
			iPath   = (char *)SvPV(ST(4), PL_na);

		RETVAL = ConvertEthiopicString ( string, sysIn, xferIn, sysOut, xferOut, fontOut, langOut, iPath, options, closing );

	OUTPUT:
	RETVAL



void
ConvertEthiopicFile ( fileIn, fileOut, in, out, ... )
	FILE * fileIn
	FILE * fileOut
	Convert::Ethiopic::System in
	Convert::Ethiopic::System out

	PREINIT:
		int sysIn;
		int xferIn;
		int sysOut;
		int xferOut;
		int fontOut;
		enum Languages langOut;
		unsigned int options;
		int closing = 0;
		char * iPath = NULL;

	CODE:
		extractSettings ( in, out, &sysIn, &xferIn, &sysOut, &xferOut, &fontOut, &langOut, &options );

		if (items > 3 )
			closing = (int)SvIV(ST(3));

		if (items > 4 )
			iPath   = (char *)SvPV(ST(4), PL_na);

		ConvertEthiopicFile ( fileIn, fileOut, sysIn, xferIn, sysOut, xferOut, fontOut, langOut, iPath, options );



unsigned char *
ConvertEthiopicFileToString ( fileIn, in, out, ... )
	FILE * fileIn
	Convert::Ethiopic::System in
	Convert::Ethiopic::System out

	PREINIT:
		int sysIn;
		int xferIn;
		int sysOut;
		int xferOut;
		int fontOut;
		enum Languages langOut;
		unsigned int options;
		int closing = 0;
		char * iPath = NULL;

	CODE:
		if (items > 3 )
			closing = (int)SvIV(ST(3));

		if (items > 4 )
			iPath   = (char *)SvPV(ST(4), PL_na);

		extractSettings ( in, out, &sysIn, &xferIn, &sysOut, &xferOut, &fontOut, &langOut, &options );

		RETVAL = ConvertEthiopicFileToString ( fileIn, sysIn, xferIn, sysOut, xferOut, fontOut, langOut, iPath, options );

	OUTPUT:
	RETVAL



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



#===============================================================================

MODULE = Convert::Ethiopic		PACKAGE = Convert::Ethiopic::String

#===============================================================================


unsigned char *
_convert ( self, ... )
	Convert::Ethiopic::String self

	PREINIT:
		int sysIn;
		int xferIn;
		int sysOut;
		int xferOut;
		int fontOut;
		enum Languages langOut;
		unsigned int options;
		int closing = 0;
		char* iPath = NULL;
		char * string;
		Convert__Ethiopic__System in;
		Convert__Ethiopic__System out;
		SV ** sv;

	CODE:
		sv     = hv_fetch ( self, "string", 6, 0 );
		string = (char *)SvPV(*sv, PL_na);

		sv = hv_fetch ( self, "sysIn", 5, 0 );
        	if( sv_isobject(*sv) && (SvTYPE(SvRV(*sv)) == SVt_PVHV) )
        		in = (HV*)SvRV( *sv );

		sv  = hv_fetch ( self, "sysOut", 6, 0 );
        	if( sv_isobject(*sv) && (SvTYPE(SvRV(*sv)) == SVt_PVHV) )
        		out = (HV*)SvRV( *sv );

		if (items > 1 )
			closing = (int)SvIV(ST(1));

		if (items > 2 )
			iPath   = (char *)SvPV(ST(2), PL_na);

		extractSettings ( in, out, &sysIn, &xferIn, &sysOut, &xferOut, &fontOut, &langOut, &options );

		RETVAL = ConvertEthiopicString ( string, sysIn, xferIn, sysOut, xferOut, fontOut, langOut, iPath, options, closing );

	OUTPUT:
	RETVAL


#===============================================================================

MODULE = Convert::Ethiopic		PACKAGE = Convert::Ethiopic::File

#===============================================================================



void
_convert ( self, ... )
	Convert::Ethiopic::File self

	PREINIT:
		FILE * fileIn;
		FILE * fileOut;
		Convert__Ethiopic__System in;
		Convert__Ethiopic__System out;

		SV ** sv;

		int sysIn;
		int xferIn;
		int sysOut;
		int xferOut;
		int fontOut;
		enum Languages langOut;
		unsigned int options;
		int closing = 0;
		char* iPath = NULL;

	CODE:
		sv     = hv_fetch ( self, "fileIn", 6, 0 );
		fileIn = IoIFP(sv_2io(*sv));

		sv     = hv_fetch ( self, "fileOut", 7, 0 );
		fileOut = IoIFP(sv_2io(*sv));

		sv = hv_fetch ( self, "sysIn", 5, 0 );
        	if( sv_isobject(*sv) && (SvTYPE(SvRV(*sv)) == SVt_PVHV) )
        		in = (HV*)SvRV( *sv );

		sv  = hv_fetch ( self, "sysOut", 6, 0 );
        	if( sv_isobject(*sv) && (SvTYPE(SvRV(*sv)) == SVt_PVHV) )
        		out = (HV*)SvRV( *sv );

		extractSettings ( in, out, &sysIn, &xferIn, &sysOut, &xferOut, &fontOut, &langOut, &options );

		if (items > 3 )
			closing = (int)SvIV(ST(3));

		if (items > 4 )
			iPath   = (char *)SvPV(ST(4), PL_na);

		ConvertEthiopicFile ( fileIn, fileOut, sysIn, xferIn, sysOut, xferOut, fontOut, langOut, iPath, options );



unsigned char *
_toString ( self, ... )
	Convert::Ethiopic::File self

	PREINIT:
		FILE * fileIn;
		Convert__Ethiopic__System in;
		Convert__Ethiopic__System out;

		SV ** sv;

		int sysIn;
		int xferIn;
		int sysOut;
		int xferOut;
		int fontOut;
		enum Languages langOut;
		unsigned int options;
		int closing = 0;
		char* iPath = NULL;

	CODE:
		sv     = hv_fetch ( self, "fileIn", 6, 0 );
		fileIn = IoIFP(sv_2io(*sv));

		sv = hv_fetch ( self, "sysIn", 5, 0 );
        	if( sv_isobject(*sv) && (SvTYPE(SvRV(*sv)) == SVt_PVHV) )
        		in = (HV*)SvRV( *sv );

		sv  = hv_fetch ( self, "sysOut", 6, 0 );
        	if( sv_isobject(*sv) && (SvTYPE(SvRV(*sv)) == SVt_PVHV) )
        		out = (HV*)SvRV( *sv );

		extractSettings ( in, out, &sysIn, &xferIn, &sysOut, &xferOut, &fontOut, &langOut, &options );

		if (items > 3 )
			closing = (int)SvIV(ST(3));

		if (items > 4 )
			iPath   = (char *)SvPV(ST(4), PL_na);

		RETVAL = ConvertEthiopicFileToString ( fileIn, sysIn, xferIn, sysOut, xferOut, fontOut, langOut, iPath, options );

	OUTPUT:
	RETVAL


#===============================================================================

MODULE = Convert::Ethiopic		PACKAGE = Convert::Ethiopic::Number

#===============================================================================



SV *
_convert ( self, ... )
	Convert::Ethiopic::Number self

	ALIAS:
		Convert::Ethiopic::Number::toArabic   = 1
		Convert::Ethiopic::Number::toEthiopic = 2

	PREINIT:
		int sysOut;
		int xferOut;
		int fontOut;
		char * iPath = NULL;
		unsigned char * number;
		HV * out;
		SV ** sv;

	CODE:
		sv     = hv_fetch ( self, "number", 6, 0 );
		number = (unsigned char *)SvPV(*sv, PL_na);

		sv  = hv_fetch ( self, "sysOut", 6, 0 );
        	if( sv_isobject(*sv) && (SvTYPE(SvRV(*sv)) == SVt_PVHV) )
        		out = (HV*)SvRV( *sv );

		if ( items == 2 )
			iPath = (char *)SvPV(ST(1), PL_na);

		extractSettings ( NULL, out, NULL, NULL, &sysOut, &xferOut, &fontOut, NULL, NULL );

		RETVAL
		= ( number[0] > '9' ) /* utf8 */
		  ? newSViv ( ftoi ( xsUTF8ToUnicode ( number ) ) )
		  : newSVpv ( ArabToEthiopic   ( number, sysOut, xferOut, fontOut, iPath ), 0 )
		;

	OUTPUT:
	RETVAL



unsigned char *
get_ordered_list_item ( self, ... )
	Convert::Ethiopic::Number self

	PREINIT:
		int number;
		SV ** sv;
		FCHAR * fstring;

	CODE:

		if ( items == 2 )
			number = (int)SvIV(ST(1));
		else {
			sv     = hv_fetch ( self, "number", 6, 0 );
			number = (int)SvIV(*sv);
		}

		fstring = get_fidel_oli ( number );
		RETVAL  = FCHARToUTF8 ( fstring );
		Safefree ( fstring );

	OUTPUT:
	RETVAL




#===============================================================================

MODULE = Convert::Ethiopic		PACKAGE = Convert::Ethiopic::Date

#===============================================================================


Convert::Ethiopic::Date
_convert ( self, ... )
	Convert::Ethiopic::Date self

	ALIAS:
		Convert::Ethiopic::Date::_toGregorian = 1
		Convert::Ethiopic::Date::_toEthiopic  = 2

	PREINIT:
		int date;
		int month;
		long int year;
		int test;
		char * CLASS = "Convert::Ethiopic::Date";
		HV * stash;
		HV * hash;
		enum Languages lang;

	CODE:
		ix = ( ix ) ? --ix : getContext ( self ) ;
 
		getDateArgs ( ax,items, &date, &month, &year );

		// fprintf (stderr, "IN :  %i / %i / %i\n", date, month, year );
		// Date values are over written
		test
		= ( ix == ethio )
		  ?  EthiopicToGregorian ( &date, &month, &year )
		  :  GregorianToEthiopic ( &date, &month, &year )
		; 
		// fprintf (stderr, "OUT:  %i / %i / %i\n", date, month, year );

		if ( test == -1 )
			XSRETURN_UNDEF;

		lang = ( ix == ethio ) ? DEFAULTLANG : eng;

		RETVAL = newDate ( !ix, date, month, year, lang );


	OUTPUT:
	RETVAL


long int
toFixed ( self, ... )
	Convert::Ethiopic::Date self

	ALIAS:
		Convert::Ethiopic::Date::ethiopicToFixed  = 1
		Convert::Ethiopic::Date::gregorianToFixed = 2

	PREINIT:
		int date;
		int month;
		long int year;
		int test;

	CODE:
		ix = ( ix ) ? --ix : getContext ( self ) ;

		getDateArgs ( ax,items, &date, &month, &year );

		RETVAL = ( ix == ethio ) ? EthiopicToFixed ( date, month, year ) : GregorianToFixed ( date, month, year ) ;

	OUTPUT:
	RETVAL


Convert::Ethiopic::Date
fromFixed ( self, fixed )
	Convert::Ethiopic::Date self
	long int fixed

	ALIAS:
		Convert::Ethiopic::Date::fixedToEthiopic  = 1
		Convert::Ethiopic::Date::fixedToGregorian = 2

	PREINIT:
		int date;
		int month;
		long int year;
		int test;
		char * CLASS = "Convert::Ethiopic::Date";
		enum Languages lang;

	CODE:

		ix = ( ix ) ? --ix : getContext ( self ) ;

		if ( ix == ethio )
			FixedToEthiopic ( fixed, &date, &month, &year );
		else
			FixedToGregorian ( fixed, &date, &month, &year );

		lang = ( ix == ethio ) ? DEFAULTLANG : eng;

		RETVAL = newDate ( ix, date, month, year, lang );

	OUTPUT:
	RETVAL


unsigned char *
_isEthiopianHoliday ( self )
	Convert::Ethiopic::Date self

	PREINIT:
		int date;
		int month;
		long int year;
		unsigned int LCInfo;
		SV ** sv;

	CODE:
		getDateArgs ( ax,items, &date, &month, &year );

		sv     = hv_fetch ( self, "LCInfo", 6, 0 );
		LCInfo = (unsigned int)SvUV(*sv);

		RETVAL = isEthiopianHoliday ( date, month, year, LCInfo );

	OUTPUT:
	RETVAL


# unsigned char *
# isEritreanHoliday ( date, month, year, LCInfo )
# 	int date;
# 	int month;
# 	long int year;
# 	unsigned int LCInfo;


boolean
isLeapYear ( self, ...  )
	Convert::Ethiopic::Date self

	ALIAS:
		Convert::Ethiopic::Date::isEthiopicLeapYear  = 1
		Convert::Ethiopic::Date::isGregorianLeapYear = 2

	PREINIT:
		long int year;

	CODE:
		ix = ( ix ) ? --ix : getContext ( self ) ;

		getDateArgs ( ax,items, NULL, NULL, &year );

		RETVAL = ( ix == ethio ) ? isEthiopicLeapYear ( year ) : isLeapYear ( year ) ;

	OUTPUT:
	RETVAL



unsigned char *
_getEthiopicYearName ( self )
	Convert::Ethiopic::Date self

	PREINIT:
		long int year;
		unsigned int LCInfo;
		SV ** sv;

	CODE:
		getDateArgs ( ax,items, NULL, NULL, &year );

		sv     = hv_fetch ( self, "LCInfo", 6, 0 );
		LCInfo = (unsigned int)SvUV(*sv);

		RETVAL = getEthiopicYearName ( year, LCInfo );

	OUTPUT:
	RETVAL



unsigned char *
_getEthiopicMonthName ( self )
	Convert::Ethiopic::Date self

	PREINIT:
		int month;
		enum Languages lang;
		unsigned int LCInfo;
		SV ** sv;

	CODE:
		getDateArgs ( ax,items, NULL, &month, NULL );

		sv     = hv_fetch ( self, "langOut", 7, 0 );
		lang   = (enum Languages)SvIV(*sv);

		sv     = hv_fetch ( self, "LCInfo", 6, 0 );
		LCInfo = (unsigned int)SvUV(*sv);

		RETVAL = getEthiopicMonth ( month, lang, LCInfo );

	OUTPUT:
	RETVAL



unsigned char *
_getEthiopicDayOfWeek ( self )
	Convert::Ethiopic::Date self

	PREINIT:
		int date;
		int month;
		long int year;
		enum Languages lang;
		unsigned int LCInfo;
		SV ** sv;

	CODE:
		getDateArgs ( ax,items, &date, &month, &year );

		sv     = hv_fetch ( self, "langOut", 7, 0 );
		lang   = (enum Languages)SvIV(*sv);

		sv     = hv_fetch ( self, "LCInfo", 6, 0 );
		LCInfo = (unsigned int)SvUV(*sv);

		RETVAL = getEthiopicDayOfWeek ( date, month, year, lang, LCInfo );

	OUTPUT:
	RETVAL



unsigned char *
_getEthiopicDayName ( self )
	Convert::Ethiopic::Date self

	PREINIT:
		int date;
		int month;
		unsigned int LCInfo;
		SV ** sv;

	CODE:
		getDateArgs ( ax,items, &date, &month, NULL );

		sv     = hv_fetch ( self, "LCInfo", 6, 0 );
		LCInfo = (unsigned int)SvUV(*sv);

		RETVAL = getEthiopicDayName ( date, month, LCInfo );

	OUTPUT:
	RETVAL



boolean
isBogusDate ( self, ... )
	Convert::Ethiopic::Date self

	ALIAS:
		Convert::Ethiopic::Date::isBogusEthiopicDate  = 1
		Convert::Ethiopic::Date::isBogusGregorianDate = 2

	PREINIT:
		int date;
		int month;
		long int year;
		int test;

	CODE:

		ix = ( ix ) ? --ix : getContext ( self ) ;

		getDateArgs ( ax,items, &date, &month, &year );

		RETVAL = ( ix == ethio ) ? isBogusEthiopicDate ( date, month, year ) : isBogusGregorianDate ( date, month, year ) ;

	OUTPUT:
	RETVAL




#===============================================================================

MODULE = Convert::Ethiopic		PACKAGE = Convert::Ethiopic::Char

#===============================================================================



boolean
isfidel ( self, ... )
	Convert::Ethiopic::Char self

	ALIAS:
		Convert::Ethiopic::Char::isfdigit          = 1
		Convert::Ethiopic::Char::isflnum           = 2
		Convert::Ethiopic::Char::isethiopic        = 3
		Convert::Ethiopic::Char::isethiopicdefined = 4
		Convert::Ethiopic::Char::isfpunct          = 5
		Convert::Ethiopic::Char::isfspace          = 6
		Convert::Ethiopic::Char::isfprint          = 7
		Convert::Ethiopic::Char::isfcntrl          = 8
		Convert::Ethiopic::Char::isfgraph          = 9
		Convert::Ethiopic::Char::isfprivate        = 10

	PREINIT:
		FCHAR fchar;

	CODE:

		fchar = xs_get_fchar ( ax, items );

		switch ( ix )
		  {
		  	case 0 :
		  	default:
				RETVAL = isfidel ( fchar );
				break;
		  	case 1:
				RETVAL = isfdigit ( fchar );
				break;
		  	case 2:
				RETVAL = isflnum ( fchar );
				break;
		  	case 3:
				RETVAL = isethiopic ( fchar );
				break;
		  	case 4:
				RETVAL = isethiopicdefined ( fchar );
				break;
		  	case 5:
				RETVAL = isfpunct ( fchar );
				break;
		  	case 6:
				RETVAL = isfspace ( fchar );
				break;
		  	case 7:
				RETVAL = isfprint ( fchar );
				break;
		  	case 8:
				RETVAL = isfcntrl ( fchar );
				break;
		  	case 9:
				RETVAL = isfgraph ( fchar );
				break;
		  	case 10:
				RETVAL = isprivate ( fchar );
				break;
		  }

	OUTPUT:
	RETVAL


boolean
isfamily ( self, ... )
	Convert::Ethiopic::Char self

	PREINIT:
		FCHAR fchar1;
		FCHAR fchar2;
		unsigned char * uchar;

	CODE:

		fchar1 = xs_get_fchar ( ax, items );

		uchar
		= ( items == 2 )
		  ? (unsigned char *)SvPV ( ST(1), PL_na )
		  : (unsigned char *)SvPV ( ST(2), PL_na )  // assume ix = 3 
		;

		fchar2 = xsUTF8ToUnicode ( uchar );

		RETVAL = isfamily ( fchar1, fchar2 );

	OUTPUT:
	RETVAL



boolean
isEquiv ( self, ... )
	Convert::Ethiopic::Char self

	PREINIT:
		FCHAR fchar1;
		FCHAR fchar2;
		enum Languages lang;
		unsigned char * uchar;
	CODE:

		fchar1 = xs_get_fchar ( ax, items );

		uchar
		= ( items == 2 )
		  ? (unsigned char *)SvPV ( ST(1), PL_na )
		  : (unsigned char *)SvPV ( ST(2), PL_na )  // assume ix = 3 
		;
		lang
		= ( items == 2 )
		  ? (enum Languages)SvIV ( ST(2) )
		  : (enum Languages)SvIV ( ST(3) )          // assume ix = 3 
		;

		fchar2 = xsUTF8ToUnicode ( uchar );

		RETVAL = isfamily ( fchar1, fchar2 );

	OUTPUT:
	RETVAL



int
get_fmodulo ( self, ... )
	Convert::Ethiopic::Char self

	ALIAS:
		Convert::Ethiopic::Char::get_formNumber = 1
		Convert::Ethiopic::Char::get_formOffset = 2

	PREINIT:
		FCHAR fchar;

	CODE:

		fchar = xs_get_fchar ( ax, items );

		RETVAL
		= ( ix )
		  ? ( ix-1 )
		    ? get_formOffset ( fchar )
		    : get_formNumber ( fchar )
		  : get_fmodulo ( fchar )
		;

	OUTPUT:
	RETVAL



unsigned char *
set_formNumber ( self, ... )
	Convert::Ethiopic::Char self

	PREINIT:
		FCHAR fchar;
		int newForm;

	CODE:

		fchar = xs_get_fchar ( ax, items );

		newForm
		= ( items == 2 )
		  ? (int)SvIV ( ST(1) )
		  : (int)SvIV ( ST(2) )  // assume ix = 3 
		;

		fchar = set_formNumber ( fchar, newForm );

		RETVAL = UnicodeToUTF8 ( fchar );

	OUTPUT:
	RETVAL


# int
# get_traditional ( int trad, FCHAR* uni );


# FCHAR
# get_traditional_series ( int trad, int syllable ); 


# unsigned char *
# get_family_name ( self, ... )
# 	Convert::Ethiopic::Char self

# 	PREINIT:
# 		FCHAR * fstring;

# 	CODE:

# 		fstring = get_family_name ( xs_get_fchar ( ax, items ) );
# 		RETVAL  = FCHARToUTF8 ( fstring );
# 		Safefree ( fstring );

# 	OUTPUT:
# 	RETVAL




# char *
# get_entity_name ( self, ... );
# 	Convert::Ethiopic::Char self

# 	CODE:

# 		RETVAL = get_entity_name ( xs_get_fchar ( ax, items ) );

# 	OUTPUT:
# 	RETVAL
