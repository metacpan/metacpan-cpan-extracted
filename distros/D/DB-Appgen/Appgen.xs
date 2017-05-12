#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "aglib/aglib.h"

MODULE = DB::Appgen		PACKAGE = DB::Appgen		

PROTOTYPES: ENABLE

##
# File level
#

unsigned
ag_db_open(filename)
		char*		filename;

int
ag_db_close(dbh)
		unsigned	dbh;

unsigned
ag_db_create(filename, hsize, trunc)
		char*		filename;
		long		hsize;
		int		trunc;

int
ag_db_rewind(dbh)
		unsigned	dbh;

int
ag_db_delete(dbh)
		unsigned	dbh;

int
ag_db_lock(dbh)
		unsigned	dbh;

int
ag_db_unlock(dbh)
		unsigned	dbh;

##
# Record level
#

int
ag_db_read(dbh,key,lock)
		unsigned	dbh;
		char *		key;
		int		lock;

int
ag_db_release(dbh)
		unsigned	dbh;

int
ag_db_delrec(dbh)
		unsigned	dbh;

char *
ag_readnext(dbh,lock)
		unsigned	dbh;
		int		lock;

int
ag_db_newrec(dbh, key, size)
		unsigned	dbh;
		char*		key;
		long		size;

int
ag_db_write(dbh)
		unsigned	dbh;


##
# Field level
#

int
ag_delete(dbh,attr,val)
		unsigned	dbh;
		int		attr;
		int		val;
	CODE:
		RETVAL = ag_drop(dbh,attr,val);
	RETVAL:
		RETVAL;

int
ag_insert(dbh,attr,val,buf)
		unsigned	dbh;
		int		attr;
		int		val;
		char*		buf;

char *
ag_extract(dbh,attr,val,maxsz)
		unsigned	dbh;
		int		attr;
		int		val;
		int		maxsz;
	INIT:
		char *buf=NULL;
	CODE:
		if(! maxsz)
		 maxsz=ag_db_stat(dbh,attr,val);
		if(maxsz <= 0)
		 RETVAL=NULL;
		else
		 { New('am',buf,maxsz+1,char);
		   if(!buf)
		    RETVAL=NULL;
		   else
		    { int rc=ag_extract(dbh,attr,val,buf,maxsz+1);
		      if(rc == -1)
		       RETVAL=NULL;
		      else
		       RETVAL=buf;
		    }
		 }
	OUTPUT:
		RETVAL
	CLEANUP:
		if(buf)
		 Safefree(buf);

int
ag_replace(dbh,attr,val,buf)
		unsigned	dbh;
		int		attr;
		int		val;
		char*		buf;

int
ag_db_stat(dbh,attr,val)
		unsigned	dbh;
		int		attr;
		int		val;
