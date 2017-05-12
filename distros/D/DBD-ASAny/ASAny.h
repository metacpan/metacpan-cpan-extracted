#define NEED_DBIXS_VERSION 9

#include <DBIXS.h>		/* installed by the DBI module	*/
#include <stdio.h>

#include "sqlca.h"
#include "sqlda.h"
#include "sqldef.h"

/* read in our implementation details */

#include "dbdimp.h"

#define _trace() {printf( "%s: %d\n", __FILE__, __LINE__ ); fflush( stdout );}

void dbd_init _((dbistate_t *dbistate));

int  dbd_db_login _((SV *dbh, imp_dbh_t *imp_dbh, char *dbname, char *uid, char *pwd));
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


/* end of ASAny.h */
