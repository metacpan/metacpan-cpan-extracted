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

#define PERL_NO_GET_CONTEXT

#define NEED_DBIXS_VERSION 9

#include <DBIXS.h>		/* installed by the DBI module	*/
#include <stdio.h>

#define _SACAPI_VERSION 2
#include "sacapidll.h"
#include "sacapi.h"
#include "dbdimp.h"
#include "sqlerr.h"

#define _trace() {printf( "%s: %d\n", __FILE__, __LINE__ ); fflush( stdout );}

void dbd_init _((dbistate_t *dbistate));

int  dbd_db_login _((SV *dbh, imp_dbh_t *imp_dbh, char *dbname, char *uid, char *pwd));
int  dbd_db_login6 _((SV *dbh, imp_dbh_t *imp_dbh, char *dbname, char *uid, char *pwd, SV *attr));
int  dbd_db_commit _(( SV *dbh, imp_dbh_t *imp_dbh));
int  dbd_db_rollback _((SV *dbh, imp_dbh_t *imp_dbh));
int  dbd_db_disconnect _((SV *dbh, imp_dbh_t *imp_dbh));
void dbd_db_destroy _((SV *dbh, imp_dbh_t *imp_dbh));
int  dbd_db_STORE_attrib _((SV *dbh, imp_dbh_t *imp_dbh, SV *keysv, SV *valuesv));
SV  *dbd_db_FETCH_attrib _((SV *dbh, imp_dbh_t *imp_dbh, SV *keysv));

void dbd_preparse( imp_sth_t *imp_sth, char *statement );

int dbd_st_blob_read _(( SV *sth, imp_sth_t *imp_sth,
		      int field, long offset, long len, SV *destrv, long destoffset ));
int  dbd_st_prepare _((SV *sth, imp_sth_t *imp_sth, char *statement, SV *attribs));
int  dbd_st_rows _((SV *sv, imp_sth_t *imp_sth));
int  dbd_bind_ph _(( SV		*sth,
	     imp_sth_t *imp_sth,
	     SV 	*ph_namesv,
	     SV 	*newvalue, 
	     IV 	sql_type,
	     SV 	*attribs,
	     int 	is_inout,
	     IV 	maxlen ));
int  dbd_st_execute _((SV *sv, imp_sth_t *imp_sth));
AV  *dbd_st_fetch _((SV *sv, imp_sth_t *imp_sth));
int  dbd_st_finish _((SV *sth, imp_sth_t *imp_sth));
void dbd_st_destroy _((SV *sth, imp_sth_t *imp_sth));
int  dbd_st_readblob _((SV *sth, imp_sth_t *imp_sth, int field, long offset, long len,
			SV *destrv, long destoffset));
int  dbd_st_STORE_attrib _((SV *sth, imp_sth_t *imp_sth, SV *keysv, SV *valuesv));
SV  *dbd_st_FETCH_attrib _((SV *sth, imp_sth_t *imp_sth, SV *keysv));
int dbd_st_more_results _(( SV *sth, imp_sth_t *imp_sth ));


/* end of SQLAnywhere.h */
