#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <dbz.h>

typedef int DBZ_File;

MODULE = DBZ_File	PACKAGE = DBZ_File	PREFIX = dbz_

DBZ_File
dbz_TIEHASH(dbtype, filename, flags = 0, mode = 0)
	char *		dbtype
	char *		filename
	int		flags
	int		mode
	CODE:
	if (dbzdbminit(filename) == 0
	 || (flags && mode && errno == ENOENT
	  && dbzfresh(filename, 0, '\t', '?', 0) == 0))
	    RETVAL = 1;
	else
	    RETVAL = 0;
	OUTPUT:
	RETVAL

void
dbz_DESTROY(db)
	DBZ_File	db
	CODE:
	dbzdbmclose();

long
dbz_FETCH(db, key)
	DBZ_File	db
	datum		key
	PREINIT:
	datum		data;
	CODE:
	ST(0) = sv_newmortal();
	data = dbzfetch(key);
	if (data.dsize)
	    sv_setnv(ST(0), (double)*(long*)data.dptr);

int
dbz_STORE(db, key, value, flags = 0)
	DBZ_File	db
	datum		key
	long		value
	int		flags
	PREINIT:
	datum		data;
	CODE:
	data.dptr = (char*)&value;
	data.dsize = sizeof (long);
	RETVAL = dbzstore(key,data);
	OUTPUT:
	RETVAL
