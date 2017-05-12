#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


/* 
 *  This is the C Part
 */

#ifndef DTFHDR_H
#include "dtfhdr.h"
#endif

#ifndef DTFMAC_H
#include "dtfmac.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif
#ifndef DTFCLNT_H
#include "dtfclnt.h"
#endif
#ifdef __cplusplus
}
#endif

#include "stddef.h"
#include "ctype.h"

#ifndef DTFENV_H
#include "dtfenv.h"
#endif

#include <stddef.h>
#include <ctype.h>

#ifndef DTFENV_H
#include <dtfenv.h>
#endif


#define is_STRING	 1
#define is_INTEGER 	 2
#define is_DOUBLE 	 3
#define is_ULONG	 4
#define is_DECIMAL   5

/* 	Decimal Datatype
 *
 *	typedef struct
 *	{
 *	  unsigned char val[9];
 *	} DTFDECIMAL;
 */


/*
 *   Help routine
 */


unsigned long _define_Attribut(int a3, int a2, int a1, int a0)
{
	return (   (((long)a3)<<24) | (((long)a2)<<16) | (((long)a1)<< 8) | ((long)a0)   );
}


/*
 *
 *
 *
 *  And now the XS Part
 *
 *
 *
 */

MODULE = Mac::DtfSQL		PACKAGE = Mac::DtfSQL

PROTOTYPES: DISABLE


DTFDECIMAL *
new_decimal(CLASS)
		char *CLASS
	PREINIT:
		short i;
    CODE:
		New(0, RETVAL, 1, DTFDECIMAL);
		if( RETVAL == NULL ) {
			warn("unable to allocate DTFDECIMAL");
			XSRETURN_UNDEF;
		}
		for (i=0; i<9; i++) { /* init */
			RETVAL->val[i] = 0;
		}
    OUTPUT:
		RETVAL



void
DESTROY(self)
		DTFDECIMAL *self
    CODE:
		Safefree(self);



unsigned short
from_string(pDEC, strDEC)
		DTFDECIMAL *pDEC
		char *	strDEC
	PREINIT:
		unsigned short err;
    CODE:
		err = DtfDecCreateFromString(strDEC, pDEC);
		RETVAL = (! err) ? 1 : 0; /* in Perl, a valid result (DTF_ERR_OK = 0) will be indicated by 1 */
    OUTPUT:
		RETVAL



unsigned short
from_long(pDEC, longVal)
		DTFDECIMAL *pDEC
		long	longVal
	PREINIT:
		unsigned short err;
    CODE:
		err = dtFlongToDecimal(0, longVal, pDEC);
		RETVAL = (! err) ? 1 : 0; /* in Perl, a valid result (DTF_ERR_OK = 0) will be indicated by 1 */
    OUTPUT:
		RETVAL



char *
as_string(pDEC)
		DTFDECIMAL *pDEC
	PREINIT:
		char	buf[80];
		unsigned short err;
    CODE:
		err = DtfDecToString(*pDEC, buf, sizeof(buf));
		RETVAL = (! err) ?  buf : "";
    OUTPUT:
		RETVAL



double 
to_double(pDEC)
		DTFDECIMAL *pDEC
    CODE:
		RETVAL = DtfDecToDouble(*pDEC);
    OUTPUT:
		RETVAL



unsigned short
is_valid(pDEC)
		DTFDECIMAL *pDEC
	CODE:
		RETVAL = DtfDecIsValid(*pDEC);
    OUTPUT:
		RETVAL



unsigned short
assign(pDEC, copyfromDEC)
		DTFDECIMAL *pDEC
		DTFDECIMAL *copyfromDEC
	PREINIT:
		short i;
	CODE:
		for (i=0; i<9; i++) { /* copy */
			pDEC->val[i] = copyfromDEC->val[i];
		}
		RETVAL = 1; /* in Perl, a valid result will be indicated by 1 */
    OUTPUT:
		RETVAL



unsigned short
abs(pDEC)
		DTFDECIMAL *pDEC
	PREINIT:
		unsigned short err;
	CODE:
		err = DtfDecAbs(*pDEC, pDEC);
		RETVAL = (! err) ? 1 : 0; /* in Perl, a valid result (DTF_ERR_OK = 0) will be indicated by 1 */
    OUTPUT:
		RETVAL



unsigned short
add(pDEC, addDEC)
		DTFDECIMAL *pDEC
		DTFDECIMAL *addDEC
	PREINIT:
		unsigned short err;
		unsigned scale;
	CODE:
		scale = DtfDecScale(*pDEC); /* object determines the scale */
		err = DtfDecAdd(scale, *pDEC, *addDEC, pDEC);/* pDEC = pDEC + addDEC */
		RETVAL = (! err) ? 1 : 0; /* in Perl, a valid result (DTF_ERR_OK = 0) will be indicated by 1 */
    OUTPUT:
		RETVAL
		

unsigned short
sub(pDEC, subDEC)
		DTFDECIMAL *pDEC
		DTFDECIMAL *subDEC
	PREINIT:
		unsigned short err;
		unsigned scale;
	CODE:
		scale = DtfDecScale(*pDEC); /* object determines the scale */
		err = DtfDecSub(scale, *pDEC, *subDEC, pDEC);/* pDEC = pDEC - subDEC */
		RETVAL = (! err) ? 1 : 0; /* in Perl, a valid result (DTF_ERR_OK = 0) will be indicated by 1 */
    OUTPUT:
		RETVAL
		



unsigned short
div(pDEC, divDEC)
		DTFDECIMAL *pDEC
		DTFDECIMAL *divDEC
	PREINIT:
		unsigned short err;
		unsigned scale;
	CODE:
		scale = DtfDecScale(*pDEC); /* object determines the scale */
		err = DtfDecDiv(scale, *pDEC, *divDEC, pDEC); /* pDEC = pDEC / divDEC */
		RETVAL = (! err) ? 1 : 0; /* in Perl, a valid result (DTF_ERR_OK = 0) will be indicated by 1 */
    OUTPUT:
		RETVAL



unsigned short
mul(pDEC, mulDEC)
		DTFDECIMAL *pDEC
		DTFDECIMAL *mulDEC
	PREINIT:
		unsigned short err;
		unsigned scale;
	CODE:
		scale = DtfDecScale(*pDEC); /* object determines the scale */		
		err = DtfDecMult(scale, *pDEC, *mulDEC, pDEC); /* pDEC = pDEC * mulDEC */
		RETVAL = (! err) ? 1 : 0; /* in Perl, a valid result (DTF_ERR_OK = 0) will be indicated by 1 */
    OUTPUT:
		RETVAL



unsigned 
get_scale(pDEC)
		DTFDECIMAL *pDEC
	CODE:
		RETVAL = DtfDecScale(*pDEC);
    OUTPUT:
		RETVAL



unsigned short
set_scale(pDEC, scale)
		DTFDECIMAL 	*pDEC
		unsigned 	scale
	PREINIT:
		unsigned short err;
	CODE:
		err = DtfDecNormalize(scale, *pDEC);
		RETVAL = (! err) ? 1 : 0; /* in Perl, a valid result (DTF_ERR_OK = 0) will be indicated by 1 */
    OUTPUT:
		RETVAL



unsigned char
equal(pDEC, compDEC)
		DTFDECIMAL 	*pDEC
		DTFDECIMAL 	*compDEC
	CODE:
		RETVAL = DtfDecEqual(*pDEC, *compDEC); /* pDEC == compDEC ? */
    OUTPUT:
		RETVAL



unsigned char
greater(pDEC, compDEC)
		DTFDECIMAL 	*pDEC
		DTFDECIMAL 	*compDEC
	CODE:
		RETVAL = DtfDecGreater(*pDEC, *compDEC); /* pDEC > compDEC ? */
    OUTPUT:
		RETVAL



unsigned char
greater_equal(pDEC, compDEC)
		DTFDECIMAL 	*pDEC
		DTFDECIMAL 	*compDEC
	CODE:
		RETVAL = DtfDecGreaterOrEqual(*pDEC, *compDEC); /* pDEC >= compDEC ? */
    OUTPUT:
		RETVAL



unsigned char
less(pDEC, compDEC)
		DTFDECIMAL 	*pDEC
		DTFDECIMAL 	*compDEC
	CODE:
		RETVAL = DtfDecLess(*pDEC, *compDEC); /* pDEC < compDEC ? */
    OUTPUT:
		RETVAL



unsigned char
less_equal(pDEC, compDEC)
		DTFDECIMAL 	*pDEC
		DTFDECIMAL 	*compDEC
	CODE:
		RETVAL = DtfDecLessOrEqual(*pDEC, *compDEC); /* pDEC <= compDEC ? */
    OUTPUT:
		RETVAL		








unsigned short
DtfTraExecute (htra, sqlString, reqClass, nrAffectedRecords, hres)
		int		      	htra		
		const char *    sqlString 
		unsigned long 	reqClass = NO_INIT	
		unsigned long 	nrAffectedRecords  = NO_INIT
		int    			hres = 0; /* on input, hres should really be set to DTFHANDLE_NULL (= 0) */	
	CODE:
		RETVAL = DtfTraExecute (htra, sqlString, &reqClass, &nrAffectedRecords, &hres);
	OUTPUT:
		reqClass
		nrAffectedRecords
		hres 
		RETVAL



unsigned short 
DtfTraExecuteUpdate (htra, sqlString, nrAffectedRecords)
		int		      	htra		
		const char *    sqlString
		unsigned long 	nrAffectedRecords = NO_INIT	 
	CODE:
		RETVAL = DtfTraExecuteUpdate (htra, sqlString, &nrAffectedRecords);
	OUTPUT:
		nrAffectedRecords 
		RETVAL



unsigned short 
DtfTraExecuteQuery (htra, sqlString, restype, hres)
		int		      	htra		
		const char *    sqlString
		unsigned long 	restype 	 
		int    			hres = 0; /* on input, hres should really be set to DTFHANDLE_NULL (= 0) */	
	CODE:
		RETVAL = DtfTraExecuteQuery (htra, sqlString, restype, &hres);
	OUTPUT:
		hres 
		RETVAL



unsigned short 
DtfEnvCreate (henv)
		int	henv = NO_INIT			
	CODE:
		RETVAL = DtfEnvCreate (&henv);
	OUTPUT:
		henv
		RETVAL



unsigned short 
DtfConCreate (henv, connectSpec, flags, hcon)
		int 			henv
		const void *	connectSpec
		unsigned long 	flags 
		int 			hcon = NO_INIT	
	CODE:
		RETVAL = DtfConCreate (henv, connectSpec, flags, &hcon);
	OUTPUT:
		hcon 
		RETVAL



unsigned short 
DtfConQueryStatus (hcon, connected, dbExists, dbConsistent)
		int hcon 
		unsigned char	connected
		unsigned char 	dbExists 
		unsigned char 	dbConsistent
	PREINIT:
		unsigned char	want_connected = connected;
		unsigned char 	want_dbExists = dbExists;
		unsigned char 	want_dbConsistent = dbConsistent;	
	CODE:
		RETVAL = DtfConQueryStatus (hcon, &connected, &dbExists, &dbConsistent);
	OUTPUT:
		connected		if (want_connected)		{sv_setiv(ST(1), (IV)connected);}
		dbExists		if (want_dbExists)		{sv_setiv(ST(2), (IV)dbExists);}
		dbConsistent	if (want_dbConsistent)	{sv_setiv(ST(3), (IV)dbConsistent);}
		RETVAL



unsigned short 
DtfConCreateDatabase (hcon, admUserName, admPassWord, ratioIndRel, maxSize, indexSize, relationSize)
		int hcon
		const char *	admUserName
		const char *	admPassWord 
		unsigned long 	ratioIndRel
		unsigned long 	maxSize
		unsigned long	indexSize = NO_INIT
		unsigned long	relationSize = NO_INIT
	CODE:
		RETVAL = DtfConCreateDatabase (hcon, admUserName, admPassWord, ratioIndRel, maxSize, &indexSize, &relationSize);
	OUTPUT:
		indexSize
		relationSize
		RETVAL



unsigned short 
DtfConDeleteDatabase (hcon)
		int hcon
	CODE:
		RETVAL = DtfConDeleteDatabase (hcon);
	OUTPUT:
		RETVAL



unsigned short 
DtfConRecoverDatabase (hcon)
		int hcon	
	CODE:
		RETVAL = DtfConRecoverDatabase (hcon);
	OUTPUT:
		RETVAL



unsigned short 
DtfConConnect (hcon, userName, passWord)
		int		      	hcon		
		const char *    userName
		const char *    passWord
	CODE:
		RETVAL = DtfConConnect (hcon, userName, passWord);
	OUTPUT:
		RETVAL

int
DtfConQueryEnvHandle (hcon)
		int hcon
	CODE:
		RETVAL = DtfConQueryEnvHandle (hcon);
	OUTPUT:
		RETVAL



unsigned long 
DtfConDataLocationCount (hcon)
		int hcon
	CODE:
		RETVAL = DtfConDataLocationCount (hcon);
	OUTPUT:
		RETVAL



const char * 
DtfConDataLocation (hcon, fileIndex, maxSize, size)
		int hcon
		unsigned long 	fileIndex
		unsigned long 	maxSize
		unsigned long 	size
	CODE:
		RETVAL = DtfConDataLocation (hcon, fileIndex, &maxSize, &size);
	OUTPUT:
		maxSize
		size
		RETVAL



unsigned short 
DtfConChangeDataLocation (hcon, fileIndex, newFileName)
		int hcon
		unsigned long 	fileIndex
		const char * 	newFileName
	CODE:
		RETVAL = DtfConChangeDataLocation (hcon, fileIndex, newFileName);
	OUTPUT:
		RETVAL



unsigned short 
DtfConAddDataLocation (hcon, fileName, maxSize, fileIndex)
		int hcon
		const char *	fileName
		unsigned long 	maxSize
		unsigned long 	fileIndex
	CODE:
		RETVAL = DtfConAddDataLocation (hcon, fileName, maxSize, &fileIndex);
	OUTPUT:
		fileIndex
		RETVAL



unsigned short
DtfConRemoveDataLocation (hcon, fileIndex)
		int hcon
		unsigned long fileIndex
	CODE:
		RETVAL = DtfConRemoveDataLocation (hcon, fileIndex);
	OUTPUT:
		RETVAL		



unsigned short 
DtfTraCreate (hcon, htra)
		int hcon 
		int htra = NO_INIT
	CODE:
		RETVAL = DtfTraCreate (hcon, &htra);
	OUTPUT:
		htra 
		RETVAL



unsigned short 
DtfHdlGetError ( hdl, code, msg, group, errpos)
		int hdl 
		unsigned short code = NO_INIT
		char * msg = NO_INIT
		char * group = NO_INIT
		unsigned short errpos = NO_INIT
	PREINIT:
		char msgbuf[128];
		char groupbuf[32];	
	CODE:
		RETVAL = DtfHdlGetError(hdl, &code, msgbuf, sizeof(msgbuf), groupbuf, sizeof(groupbuf), &errpos);
		msg = msgbuf;
		group = groupbuf;
	OUTPUT:
		code
		msg
		group
		errpos
		RETVAL



unsigned long 
DtfResColumnCount (hres)
		int hres
	CODE:
		RETVAL = DtfResColumnCount (hres);
	OUTPUT:
		RETVAL



unsigned long 
DtfResRowCount (hres)
		int hres
	CODE:
		RETVAL = DtfResRowCount (hres);
	OUTPUT:
		RETVAL



unsigned short 
DtfColCreate (hres, colIndex, hcol) 
		int hres
		unsigned long colIndex
		int hcol = 0; /* on input, hcol should really be set to DTFHANDLE_NULL (= 0) */
	CODE:
		RETVAL = DtfColCreate (hres, colIndex, &hcol);
	OUTPUT:
		hcol
		RETVAL



unsigned long
DtfColCType (hcol)
		int hcol
	CODE:
		RETVAL = DtfColCType (hcol);
	OUTPUT:
		RETVAL



unsigned short 
DtfHdlSetUserData (hdl, userData)
		int hdl
		char * userData
	CODE:
		RETVAL = DtfHdlSetUserData (hdl, userData);
	OUTPUT:
		RETVAL



unsigned short 
DtfHdlQueryUserData (hdl, userData)
		int hdl
		char * userData = NO_INIT
	CODE:
		RETVAL = DtfHdlQueryUserData (hdl, (void **) &userData);
	OUTPUT:
		userData
		RETVAL



unsigned short 
DtfHdlSetAttribute (hdl, attr, pValue)
		int hdl
		unsigned long attr
		char * pValue
	CODE:
		RETVAL = DtfHdlSetAttribute (hdl, attr, pValue);
	OUTPUT:
		RETVAL



unsigned short
DtfHdlEnumAttribute (hdl, index, pAttr)
		int hdl
		unsigned long index
		unsigned long pAttr = NO_INIT
	CODE:
		RETVAL = DtfHdlEnumAttribute (hdl, index, &pAttr);
	OUTPUT:
		pAttr
		RETVAL



unsigned short 
DtfHdlQueryAttribute (hdl, attr, pvalue)
		int hdl
		unsigned long attr
		void * pvalue = NO_INIT
	PREINIT:
		char			currVal[256];
		unsigned long	type;
		char			defaultVal[256];
        const char *	matchSpec;
		unsigned short	err1;
		unsigned short	err2;
		unsigned short	islongType;
		long			longValue;
	CODE:
		err1 = DtfHdlQueryAttribute (hdl, attr, currVal, sizeof(currVal));
		err2 = DtfAttrQueryInfo(attr, &type, defaultVal, sizeof(defaultVal), &matchSpec);		
		RETVAL = (! err1) ? err2 : err1;	  
		switch (type)
            {
              case DTF_ATY_LONG: /* 0 */
                longValue = *( (long *)currVal ); /* I love C */
				islongType = 1;
                break;
              case DTF_ATY_STRING: /* 1 */
              case DTF_ATY_ENUM: /* 2 */
                pvalue = currVal;
				islongType = 0;
				break;
			}
	OUTPUT:
		pvalue	if (islongType) {sv_setiv(ST(2), (IV) longValue);} else {sv_setpv((SV*)ST(2), pvalue);} /* on one line, or xsubpp will complain */
		RETVAL



unsigned short 
DtfAttrQueryInfo (attr, type, defaultVal, rangeSpec)
		unsigned long	attr
		unsigned long 	type
		void *			defaultVal
		const char *	rangeSpec
	PREINIT:
		char			defaultValBuf[256];
		unsigned short	islongType;
		long			longValue;
		unsigned long	want_type = type;
		unsigned long	want_defaultVal = (unsigned long)defaultVal;
		unsigned long	want_rangeSpec = (unsigned long)rangeSpec;
	CODE:
		RETVAL = DtfAttrQueryInfo(attr, &type, defaultValBuf, sizeof(defaultValBuf), &rangeSpec);		  
		switch (type)
            {
              case DTF_ATY_LONG: /* 0 */
                longValue = *( (long *)defaultValBuf );
				islongType = 1;
               	break;
              case DTF_ATY_STRING: /* 1 */
              case DTF_ATY_ENUM: /* 2 */
                defaultVal = defaultValBuf;
				islongType = 0;
				break;
		} /* switch */			
	OUTPUT:
		type		if (want_type)			{sv_setiv(ST(1), (IV)type);}
		defaultVal	if (want_defaultVal)	{if (islongType) {sv_setiv(ST(2), (IV)longValue);} else {sv_setpv((SV*)ST(2), defaultVal);} } /* on one line, or xsubpp will complain */
		rangeSpec	if (want_rangeSpec)		{sv_setpv((SV*)ST(3), rangeSpec);}
		RETVAL



const char * 
DtfColTableName (hcol)
		int hcol
	CODE:
		RETVAL = DtfColTableName (hcol);
	OUTPUT:
		RETVAL



const char * 
DtfColName (hcol)
		int hcol
	CODE:
		RETVAL = DtfColName (hcol);
	OUTPUT:
		RETVAL



unsigned short 
DtfColDestroy (hcol)
		int hcol
	CODE:
		RETVAL = DtfColDestroy (&hcol);
	OUTPUT:
		hcol
		RETVAL



unsigned short 
DtfResMoveToFirstRow (hres)
		int hres
	CODE:
		RETVAL = DtfResMoveToFirstRow (hres);
	OUTPUT:
		RETVAL



unsigned short 
DtfResMoveToNextRow (hres)
		int hres
	CODE:
		RETVAL = DtfResMoveToNextRow (hres);
	OUTPUT:
		RETVAL



unsigned short 
DtfResMoveToRow (hres, rowIndex)
		int hres
		unsigned long rowIndex
	CODE:
		RETVAL = DtfResMoveToRow (hres, rowIndex);
	OUTPUT:
		RETVAL



unsigned short
DtfResQueryFieldInfo (hres, colIndex , fieldSize, isNull)
		int hres
		unsigned long colIndex
		size_t fieldSize = NO_INIT
		unsigned char isNull = NO_INIT
	CODE:
		RETVAL = DtfResQueryFieldInfo (hres, colIndex , &fieldSize, &isNull);
	OUTPUT:
		fieldSize
		isNull
		RETVAL



unsigned short 
DtfResGetField (hres, colIndex, requestType, fieldVal, isNull, fieldCType)
		int hres
		unsigned long colIndex
		unsigned long requestType
		char * fieldVal = NO_INIT
		unsigned char isNull = NO_INIT
		long fieldCType 	
	PREINIT:
		char			intern_buf[4096];
		short			returnType;
		unsigned long	ulongValue;
		long			longValue;
		double			doubleValue;
		DTFDECIMAL *	decimalValue;
		char *			CLASS = "Mac::DtfSQL"; /* The Perl object is blessed into 'CLASS',i.e. this package */
		short			i;
	CODE:
		switch (requestType) {
			case DTF_CT_CSTRING: /* retrieve as string */
			case DTF_CT_SQLSTRING: /* retrieve as single quoted string */			  
			  	RETVAL = DtfResGetField (hres, colIndex, requestType, intern_buf, sizeof(intern_buf), &isNull);
				fieldVal = intern_buf;
				returnType = is_STRING;
                break;
			case DTF_CT_DEFAULT: /* retrieve the actual datatype, we need fieldCType to decide the type */
              	switch (fieldCType) {
					case DTF_CT_ULONG: /* return as unsigned long */
						RETVAL = DtfResGetField (hres, colIndex, requestType, intern_buf, sizeof(intern_buf), &isNull);
						ulongValue = *( (unsigned long *)intern_buf );
						returnType = is_ULONG;
						break;

					case DTF_CT_BOOL:	/* return as (long) int */
					case DTF_CT_CHAR:
					case DTF_CT_UCHAR:
					case DTF_CT_SHORT:
					case DTF_CT_USHORT:
					case DTF_CT_LONG:
						RETVAL = DtfResGetField (hres, colIndex, requestType, intern_buf, sizeof(intern_buf), &isNull);
						longValue = *( (long *)intern_buf );
						returnType = is_INTEGER;
						break;
					
					case DTF_CT_DOUBLE:		/* return as double */
						RETVAL = DtfResGetField (hres, colIndex, requestType, intern_buf, sizeof(intern_buf), &isNull);					
						doubleValue = *( (double *)intern_buf );
						returnType = is_DOUBLE;
						break;
					
					case DTF_CT_DECIMAL: /* return a DTFDECIMAL object */	
						RETVAL = DtfResGetField (hres, colIndex, requestType, intern_buf, sizeof(intern_buf), &isNull);
						New(0, decimalValue, 1, DTFDECIMAL);
						for (i = 0; i < 9; i++) {
							decimalValue->val[i] = (unsigned char) intern_buf[i];
						}
						returnType = is_DECIMAL;
						break;
					
					case DTF_CT_TIMESTAMP: /* return as string */
					case DTF_CT_TIME:
					case DTF_CT_DATE:
					case DTF_CT_SQLSTRING:
					case DTF_CT_CSTRING:
						RETVAL = DtfResGetField (hres, colIndex, requestType, intern_buf, sizeof(intern_buf), &isNull);
						fieldVal = intern_buf;
						returnType = is_STRING;
						break;
					default: /* everything else is an error */
						RETVAL =  DTF_ERR_USER;
                		fieldVal = "The specified field data type is not supported";
						returnType = is_STRING;
						break;  
			  	} /* switch */
			  	break;
			case DTF_CT_BLOB: /* not supported */
				RETVAL =  DTF_ERR_USER;
                fieldVal = "The blob data type is not supported";
				returnType = is_STRING;
				break;
		} /*switch*/

	OUTPUT:
		fieldVal 	switch (returnType) {											\
						case is_STRING: /* return string */							\
							sv_setpv((SV*)ST(3), fieldVal);							\
							break;													\
						case is_INTEGER: /* return integer */						\
							sv_setiv(ST(3), (IV)longValue);							\
							break;													\
						case is_DECIMAL: /* return DECIMAL object */				\
							sv_setref_pv(ST(3), CLASS, (void*)decimalValue );		\
							break;													\
						case is_DOUBLE: /* return double */							\
							sv_setnv(ST(3), (double)doubleValue);					\
							break;													\
						case is_ULONG: /* return long */							\
							sv_setuv(ST(3), (UV)ulongValue);						\
							break;													\
					} /* switch */
		isNull
		RETVAL



unsigned short 
DtfResDestroy (hres)
		int hres
	CODE:
		RETVAL = DtfResDestroy (&hres);
	OUTPUT:
		hres
		RETVAL	



unsigned short 
DtfTraDestroy (htra)
		int htra
	CODE:
		RETVAL = DtfTraDestroy (&htra);
	OUTPUT:
		htra
		RETVAL



int
DtfTraQueryConHandle (htra)
		int htra
	CODE:
		RETVAL = DtfTraQueryConHandle (htra);
	OUTPUT:
		RETVAL



unsigned short 
DtfConDestroy (hcon)
		int hcon
	CODE:
		RETVAL = DtfConDestroy (&hcon);
	OUTPUT:
		hcon
		RETVAL



unsigned short 
DtfConDisconnect (hcon)
		int hcon
	CODE:
		RETVAL = DtfConDisconnect (hcon);
	OUTPUT:
		RETVAL



unsigned short 
DtfEnvDestroy (henv)
		int henv
	CODE:
		RETVAL = DtfEnvDestroy (&henv);
	OUTPUT:
		henv
		RETVAL



unsigned long 
_define_Attribut(a3, a2, a1, a0)
		int a3
		int a2 
		int a1 
		int a0
	CODE:
		RETVAL = _define_Attribut(a3, a2, a1, a0);
	OUTPUT:
		RETVAL



void
dtf_connect (dsn, user, pass)
  		const char *	dsn
  		const char *	user
		const char *	pass
	PREINIT:
		int 			henv = 0;			/* environment handle 	*/
		int 			hcon = 0;			/* connection handle 	*/
		int 			htra = 0;			/* transaction handle 	*/
		unsigned short 	err  = 0;			/* error code 			*/
		char * 			errstr = "";		/* error message 		*/
		unsigned char 	connected = 0; 		/* connected flag 		*/
		unsigned char 	dbExists = 0;  		/* dbExists flag 		*/
		unsigned char	dbConsistent = 0; 	/* dbConsistent flag 	*/
		unsigned char	network = 0; 		/* indicates a network connection */		
	PPCODE: 
		{
  		//  First, we always need an environment handle before
  		//  we are able to do anything else.
  
  		// NOTE
  		// Currently, the number of environment handles which may exist at a time is restricted to one.
 
  		if ( (err = DtfEnvCreate(&henv) ) != DTF_ERR_OK) {
  			errstr = "ERROR(dtf_connect): Can't create environment";
			henv = 0;
			EXTEND(SP, 5); /* extend Perl stack for 5 SVs (return values) */
          	PUSHs(sv_2mortal(newSViv(henv))); /* henv == 0 */
          	PUSHs(sv_2mortal(newSViv(hcon))); /* hcon == 0 */
			PUSHs(sv_2mortal(newSViv(htra))); /* htra == 0 */
			PUSHs(sv_2mortal(newSViv(err)));  /* error code */
			PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
			XSRETURN(5); /* return from XSUB */

    		// return ( $henv, $hcon, $htra, $err, $errstr );
  		}

  		//  When the environment handle (henv) was created successfully,  a connection handle
  		//  can be created as the environment handle's *dependent* handle.
  		// 
  		//  The parameter dsn (DSN = data source name) contains for the single-user version   
  		//  of dtF/SQL the database's partial or fully qualified path (flags = DTF_CF_FILENAME),
  		//  for example "MacHD:path:to:DB:TESTDB.dtF", for the multi-user verion it contains
  		//  a server specification, for example "tcp:host/port" (flags = DTF_CF_NETWORK).

  		// NOTE
  		// Currently, only a single connection can be created on every environment handle.
  
  
  		if ( strncmp ( dsn, "tcp:", 4 ) == 0) { // network, please
    		network = 1;
  			err = DtfConCreate(henv, dsn, DTF_CF_NETWORK, &hcon);
  		} else { // local
  			err = DtfConCreate(henv, dsn, DTF_CF_FILENAME, &hcon);
  		}

  		if (err != DTF_ERR_OK) {
    		errstr = strcat ("ERROR(dtf_connect): Can't create connection to ", dsn);
			// clear up things
			// at this point, henv has successfully been created, thus dispose this handle
			DtfEnvDestroy (&henv);
			henv = 0;
			hcon = 0;
			EXTEND(SP, 5); /* extend Perl stack for 5 SVs (return values) */
          	PUSHs(sv_2mortal(newSViv(henv))); /* henv == 0 */
          	PUSHs(sv_2mortal(newSViv(hcon))); /* hcon == 0 */
			PUSHs(sv_2mortal(newSViv(htra))); /* htra == 0 */
			PUSHs(sv_2mortal(newSViv(err)));  /* error code */
			PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
    		XSRETURN(5); /* return from XSUB */

			//return ( $henv, $hcon, $htra, $err, $errstr );
  		}

  		//  This function queries some information about the just established connection

  		if ( (err = DtfConQueryStatus(hcon, NULL, &dbExists, &dbConsistent) ) != DTF_ERR_OK) {
    		errstr = "ERROR(dtf_connect): Can't query connection status"; 
			// clear up things
			// at this point, henv and hcon have successfully been created, thus dispose these handles
			DtfConDestroy (&hcon);
			DtfEnvDestroy (&henv);
			henv = 0;
			hcon = 0;
			EXTEND(SP, 5); /* extend Perl stack for 5 SVs (return values) */
          	PUSHs(sv_2mortal(newSViv(henv))); /* henv == 0 */
          	PUSHs(sv_2mortal(newSViv(hcon))); /* hcon == 0 */
			PUSHs(sv_2mortal(newSViv(htra))); /* htra == 0 */
			PUSHs(sv_2mortal(newSViv(err)));  /* error code */
			PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
    		XSRETURN(5); /* return from XSUB */
			
			//return ( $henv, $hcon, $htra, $err, $errstr );
  		}

  		// Please note: connected doesn't work as one might expect. It only says, whether a *connection handle*  
  		// hcon is in connected state or not, but it doesn't inform you, whether the *database* you want to 
  		// connect to is already in connected state (or not) -- this is a bit odd, isn't it?

  		if (! dbExists) {
  			err = DTF_ERR_DOES_NOT_EXIST;
    		sprintf(errstr, "ERROR(dtf_connect): Database %s does not exist", dsn);
			// clear up things
			// at this point, henv and hcon have successfully been created, thus dispose these handles
			DtfConDestroy (&hcon);
			DtfEnvDestroy (&henv);
			henv = 0;
			hcon = 0;
			EXTEND(SP, 5); /* extend Perl stack for 5 SVs (return values) */
          	PUSHs(sv_2mortal(newSViv(henv))); /* henv == 0 */
          	PUSHs(sv_2mortal(newSViv(hcon))); /* hcon == 0 */
			PUSHs(sv_2mortal(newSViv(htra))); /* htra == 0 */
			PUSHs(sv_2mortal(newSViv(err)));  /* error code */
			PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
    		XSRETURN(5); /* return from XSUB */
			
			//return ( $henv, $hcon, $htra, $err, $errstr );
  		}

  		// NOTE
  		// 	The following has only been tested locally (single-user), since the dtf/SQL server doesn't work
  		//  as expected and a network connection currently isn't possible.

  		// If the database you want to connect to is already in connected state by another program, dbConsistent
  		// will be set to false (not consistent). dbConsistent is also false if the database needs recovery. The
  		// best thing we can do, is trying to recover the database. If this fails, either the database can't be
  		// recovered (because its badly damaged), or the database is already in connected state (but not 
  		// inconsistent). Because we cannot distinguish between these cases, the error message mentions both.

  		if (! dbConsistent) {
			if (! network) {
    			//  In single-user version we try to recover the database
    			//  if it was detected to be inconsistent.
    	
    			if ( (err = DtfConRecoverDatabase(hcon) ) != DTF_ERR_OK) {
					sprintf(errstr, "ERROR(dtf_connect): The database %s \nis either already in connected state or is inconsistent and can not be recovered", dsn);
					// clear up things
					// at this point, henv and hcon have successfully been created, thus dispose these handles
					DtfConDestroy (&hcon);
					DtfEnvDestroy (&henv);
					henv = 0;
					hcon = 0;
					EXTEND(SP, 5); /* extend Perl stack for 5 SVs (return values) */
          			PUSHs(sv_2mortal(newSViv(henv))); /* henv == 0 */
          			PUSHs(sv_2mortal(newSViv(hcon))); /* hcon == 0 */
					PUSHs(sv_2mortal(newSViv(htra))); /* htra == 0 */
					PUSHs(sv_2mortal(newSViv(err)));  /* error code */
					PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
     	 			XSRETURN(5); /* return from XSUB */
					
					//return ( $henv, $hcon, $htra, $err, $errstr );
    			} 
    	
		
  			} else { // can't recover in a network, so give back an error
  				err = DTF_ERR_FATAL;
  				sprintf(errstr, "ERROR(dtf_connect): The database %s \nis either already in connected state or is inconsistent and can not be recovered", dsn);
				// clear up things
				// at this point, henv and hcon have successfully been created, thus dispose these handles
				DtfConDestroy (&hcon);
				DtfEnvDestroy (&henv);
				henv = 0;
				hcon = 0;
				EXTEND(SP, 5); /* extend Perl stack for 5 SVs (return values) */
        		PUSHs(sv_2mortal(newSViv(henv))); /* henv == 0 */
       		 	PUSHs(sv_2mortal(newSViv(hcon))); /* hcon == 0 */
				PUSHs(sv_2mortal(newSViv(htra))); /* htra == 0 */
				PUSHs(sv_2mortal(newSViv(err)));  /* error code */
				PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
  				XSRETURN(5); /* return from XSUB */
				
				//return ( $henv, $hcon, $htra, $err, $errstr );
  	
  			} // if network
  		} // if dbConsistent

  		//
  		//  Since at this point of execution the database exists
  		//  and is in consistent state, we are able to establish
  		//  the connection.
  		//
  
  
  		if ( (err = DtfConConnect(hcon, user, pass) ) != DTF_ERR_OK) {
    		errstr = strcat ("ERROR(dtf_connect): Can't connect as " , user);
			// clear up things
			// at this point, henv and hcon have successfully been created, thus dispose these handles
			DtfConDestroy (&hcon);
			DtfEnvDestroy (&henv);
			henv = 0;
			hcon = 0;
			EXTEND(SP, 5); /* extend Perl stack for 5 SVs (return values) */
        	PUSHs(sv_2mortal(newSViv(henv))); /* henv == 0 */
       		PUSHs(sv_2mortal(newSViv(hcon))); /* hcon == 0 */
			PUSHs(sv_2mortal(newSViv(htra))); /* htra == 0 */
			PUSHs(sv_2mortal(newSViv(err)));  /* error code */
			PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
			XSRETURN(5); /* return from XSUB */
			
  			//return ( $henv, $hcon, $htra, $err, $errstr );
  		}

  		//  We are connected, now create a transaction we are able
  		//  to execute SQL statements with.

  		// NOTE
  		// 	The maximum number of concurrent transactions may be modified by
  		// 	setting the connection handle attribute DTF_CAT_TRANSACTIONS. The
  		// 	default value of this attribute is 1.
  
  		if (err = DtfTraCreate( hcon, &htra ) != DTF_ERR_OK) {
    		errstr = "ERROR(dtf_connect): Can't create transaction";	
			// clear up things
			DtfConDisconnect (hcon); // first, disconnect the handle
			// at this point, henv and hcon have successfully been created, thus dispose these handles
			DtfConDestroy (&hcon);
			DtfEnvDestroy (&henv);
			henv = 0;
			hcon = 0;
			htra = 0;
			EXTEND(SP, 5); /* extend Perl stack for 5 SVs (return values) */
        	PUSHs(sv_2mortal(newSViv(henv))); /* henv == 0 */
       		PUSHs(sv_2mortal(newSViv(hcon))); /* hcon == 0 */
			PUSHs(sv_2mortal(newSViv(htra))); /* htra == 0 */
			PUSHs(sv_2mortal(newSViv(err)));  /* error code */
			PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
  			XSRETURN(5); /* return from XSUB */
			
			//return ( $henv, $hcon, $htra, $err, $errstr );
  		}
  
 		// everything is fine here
		
		EXTEND(SP, 5); /* extend Perl stack for 5 SVs (return values) */
        PUSHs(sv_2mortal(newSViv(henv))); /* henv ok */
       	PUSHs(sv_2mortal(newSViv(hcon))); /* hcon ok */
		PUSHs(sv_2mortal(newSViv(htra))); /* htra ok */
		PUSHs(sv_2mortal(newSViv(err)));  /* error code == 0 */
		PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message == '', let Perl determine the length */
 		XSRETURN(5); /* return from XSUB */
		
 		//return ( $henv, $hcon, $htra, $err, $errstr );
  
		} // end PPCODE



void
dtf_disconnect (henv, hcon, htra)
  		int				henv
  		int 			hcon
		int 			htra
	PREINIT:
		unsigned short 	err  = 0;			/* error code 			*/
		char * 			errstr = "";		/* error message 		*/		
		unsigned char 	connected = 0; 		/* connected flag 		*/	
	PPCODE: 
		{

  		if (htra != DTFHANDLE_NULL) {
    		if ( (err = DtfTraDestroy(&htra) ) != DTF_ERR_OK) {
				errstr = "ERROR(dtf_disconnect): Can't destroy transaction handle";
				EXTEND(SP, 2); /* extend Perl stack for 2 SVs (return values) */
          		PUSHs(sv_2mortal(newSViv(err)));  /* error code */
				PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
				XSRETURN(2); /* return from XSUB */
				
				// return ($err, $errstr);
			}
  		} //if htra

  		if (hcon != DTFHANDLE_NULL) {

    		if ( (err = DtfConQueryStatus(hcon, &connected, NULL, NULL) ) != DTF_ERR_OK) {
				errstr = "ERROR(dtf_disconnect): Can't query connection status";
				EXTEND(SP, 2); /* extend Perl stack for 2 SVs (return values) */
          		PUSHs(sv_2mortal(newSViv(err)));  /* error code */
				PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
				XSRETURN(2); /* return from XSUB */
				
				// return ($err, $errstr);
			}

    		if (connected) { // connected as user X (aka login)
	  		
				if ( (err = DtfConDisconnect(hcon) ) != DTF_ERR_OK) {
					errstr = "ERROR(dtf_disconnect): User can't disconnect (logout)";
					EXTEND(SP, 2); /* extend Perl stack for 2 SVs (return values) */
          			PUSHs(sv_2mortal(newSViv(err)));  /* error code */
					PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
					XSRETURN(2); /* return from XSUB */
				
					// return ($err, $errstr);
    			}
				
			} //connected

    		if ( (err = DtfConDestroy(&hcon) ) != DTF_ERR_OK) {
				errstr = "ERROR(dtf_disconnect): Can't destroy connection handle";
				EXTEND(SP, 2); /* extend Perl stack for 2 SVs (return values) */
          		PUSHs(sv_2mortal(newSViv(err)));  /* error code */
				PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
				XSRETURN(2); /* return from XSUB */
				
				//return ($err, $errstr);
  			}
  		} //if hcon

  		if (henv != DTFHANDLE_NULL) {
    		if ( (err = DtfEnvDestroy(&henv) ) != DTF_ERR_OK) {
				errstr = "ERROR(dtf_disconnect): Can't destroy environment handle";
				EXTEND(SP, 2); /* extend Perl stack for 2 SVs (return values) */
          		PUSHs(sv_2mortal(newSViv(err)));  /* error code */
				PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
				XSRETURN(2); /* return from XSUB */
				
				// return ($err, $errstr);
  			}
  		} //if henv
  
  		// everything is fine here
		EXTEND(SP, 2); /* extend Perl stack for 2 SVs (return values) */
        PUSHs(sv_2mortal(newSViv(err)));  /* error code */
		PUSHs(sv_2mortal(newSVpv(errstr, 0))); /* error message, let Perl determine the length */
		XSRETURN(2); /* return from XSUB */
  		
		//return ($err, $errstr);

		}// end PPCODE

