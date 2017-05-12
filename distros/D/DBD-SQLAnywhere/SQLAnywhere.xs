// ***************************************************************************
// Copyright (c) 2015 SAP SE or an SAP affiliate company. All rights reserved.
// ***************************************************************************
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
//   See the License for the specific language governing permissions and
//   limitations under the License.
//
//   While not a requirement of the license, if you do modify this file, we
//   would appreciate hearing about it. Please email
//   sqlany_interfaces@sybase.com
//
//====================================================

#ifdef __cplusplus
extern "C" {
#endif
#include "SQLAnywhere.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/* --- Variables --- */


DBISTATE_DECLARE;

MODULE = DBD::SQLAnywhere	PACKAGE = DBD::SQLAnywhere

I32
constant()
    PROTOTYPE:
    ALIAS:
	ASA_SMALLINT	= 500
	ASA_INT		= 496
	ASA_DECIMAL	= 484
	ASA_FLOAT	= 482
	ASA_DOUBLE	= 480
	ASA_DATE	= 384
	ASA_STRING	= 460
	ASA_FIXCHAR	= 452
	ASA_VARCHAR	= 448
	ASA_LONGVARCHAR	= 456
	ASA_TIME	= 388
	ASA_TIMESTAMP	= 392
	ASA_TIMESTAMP_STRUCT	= 390
	ASA_BINARY	= 524
	ASA_LONGBINARY	= 528
	ASA_VARIABLE	= 600
	ASA_TINYINT	= 604
	ASA_BIGINT	= 608
	ASA_UNSINT	= 612
	ASA_UNSSMALLINT	= 616
	ASA_UNSBIGINT	= 620
	ASA_BIT		= 624
    CODE:
	if( !ix ) {
	    char *what = GvNAME(CvGV(cv));
	    croak( "Unknown DBD::SQLAnywhere constant '%s'", what );
	} else {
	    RETVAL = ix;
	}
    OUTPUT:
	RETVAL

INCLUDE: SQLAnywhere.xsi

MODULE = DBD::SQLAnywhere	PACKAGE = DBD::SQLAnywhere::dr

void
driver_init( drh )
    SV 	     *drh
    CODE:
    ST(0) = (dbd_dr_init( drh ) ? &PL_sv_yes : &PL_sv_no);
    
void
DESTROY( drh )
    SV 	     *drh
    CODE:
    dbd_dr_destroy( drh );
    
int
more_results(sth)
    SV *	sth
    CODE:
{
    D_imp_sth(sth);
    if (dbd_st_more_results(sth, imp_sth))
    {
	RETVAL=1;
    }
    else
    {
	RETVAL=0;
    }
}
    OUTPUT:
	RETVAL

MODULE = DBD::SQLAnywhere    PACKAGE = DBD::SQLAnywhere::st

int
more_results(sth)
    SV *	sth
    CODE:
{
    int results;
    D_imp_sth(sth);
    results = dbd_st_more_results(sth, imp_sth);
    if(results > 0) {
	XSRETURN_YES;
    } else if(results == 0) {
	XSRETURN_NO;
    } else {
	XSRETURN_UNDEF;
    }
}
    OUTPUT:
	RETVAL

# end of SQLAnywhere.xs
