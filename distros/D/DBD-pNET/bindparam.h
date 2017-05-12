/*
 *  DBD::mysql - DBI driver for the mysql database
 *
 *  Copyright (c) 1997  Jochen Wiedmann
 *
 *  Based on DBD::Oracle; DBD::Oracle is
 *
 *  Copyright (c) 1994,1995  Tim Bunce
 *
 *  You may distribute this under the terms of either the GNU General Public
 *  License or the Artistic License, as specified in the Perl README file,
 *  with the exception that it cannot be placed on a CD-ROM or similar media
 *  for commercial distribution without the prior approval of the author.
 *
 *  Author:  Jochen Wiedmann
 *           Am Eisteich 9
 *           72555 Metzingen
 *           Germany
 *
 *           Email: joe@ispsoft.de
 *           Fax: +49 7123 / 14892
 *
 *
 *  $Id: dbdimp.c 1.1 Tue, 30 Sep 1997 01:28:08 +0200 joe $
 */

/*
 *  This file contains the bind_param stuff. It is isolated in a separate
 *  file because I want to use it in both DBD::mysql and DBD::pNET.
 */
static int CountParam(char* statement) {
    char* ptr = statement;
    int numParam = 0;

    while (*ptr) {
        switch (*ptr++) {
	  case '\'':
	    /*
	     *  Skip string
	     */
	    while (*ptr  &&  *ptr != '\'') {
	        if (*ptr == '\\') {
		    ++ptr;
		}
		if (*ptr) {
		    ++ptr;
		}
	    }
	    if (*ptr) {
	        ++ptr;
	    }
	    break;
	  case '?':
	    ++numParam;
	    break;
	  default:
	    break;
	}
    }
    return numParam;
}

static imp_sth_ph_t* AllocParam(int numParam) {
    imp_sth_ph_t * params;

    if (numParam) {
        Newz(908, params, numParam, imp_sth_ph_t);
    } else {
        params = NULL;
    }
    return params;
}

static void FreeParam(imp_sth_ph_t* params, int numParam) {
    if (params) {
        int i;
	for (i = 0;  i < numParam;  i++) {
	  imp_sth_ph_t* ph = params+i;
	    if (ph->value) {
	        (void) SvREFCNT_dec(ph->value);
		ph->value = NULL;
	    }
	}
	Safefree(params);
    }
}


static char* ParseParam(char* statement, STRLEN *slenPtr,
			imp_sth_ph_t* params, int numParams) {
    char* salloc;
    int i, j;
    char* valbuf;
    STRLEN vallen;
    int alen;
    char* ptr;
    imp_sth_ph_t* ph;
    int slen = *slenPtr;

    if (numParams == 0) {
        return NULL;
    }

    while (isspace(*statement)) {
	++statement;
	--slen;
    }


    /*
     *  Calculate the number of bytes being allocated for the statement
     */
    alen = slen;
    for (i = 0, ph = params;  i < numParams;  i++, ph++) {
        if (!ph->value  ||  !SvOK(ph->value)) {
	    alen += 3;  /* Erase '?', insert 'NULL' */
	} else {
	    if (!ph->type) {
	        ph->type = SvNIOK(ph->value) ? SQL_INTEGER : SQL_VARCHAR;
	    }
	    valbuf = SvPV(ph->value, vallen);
	    alen += 2*vallen+1; /* Erase '?', insert (possibly quoted)
				 * string.
				 */
	}
    }

    /*
     *  Allocate memory
     */
    New(908, salloc, alen+1, char);
    ptr = salloc;

    /*
     *  Now create the statement string; compare CountParam above
     */
    i = 0;
    j = 0;
    while (j < slen) {
        switch(statement[j]) {
	  case '\'':
	    /*
	     * Skip string
	     */
	    *ptr++ = statement[j++];
	    while (j < slen  &&  statement[j] != '\'') {
	        if (statement[j] == '\\') {
		    *ptr++ = statement[j++];
		    if (j < slen) {
		        *ptr++ = statement[j++];
		    }
		} else {
		    *ptr++ = statement[j++];
		}
	    }
	    if (j < slen) {
	        *ptr++ = statement[j++];
	    }
	    break;
	  case '?':
	    /*
	     * Insert parameter
	     */
	    j++;
	    if (i >= numParams) {
	        break;
	    }
	    ph = params+i++;
	    if (!ph->value  ||  !SvOK(ph->value)) {
	        *ptr++ = 'N';
		*ptr++ = 'U';
		*ptr++ = 'L';
		*ptr++ = 'L';
	    } else {
	        int isNum = FALSE;
		int c;

		valbuf = SvPV(ph->value, vallen);		    
		if (valbuf) {
		    switch (ph->type) {
		      case SQL_NUMERIC:
		      case SQL_DECIMAL:
		      case SQL_INTEGER:
		      case SQL_SMALLINT:
		      case SQL_FLOAT:
		      case SQL_REAL:
		      case SQL_DOUBLE:
		      /* case SQL_BIGINT:     These are commented out */
		      /* case SQL_TINYINT:    in DBI's dbi_sql.h      */
			isNum = TRUE;
			break;
		      case SQL_CHAR:
		      case SQL_VARCHAR:
		      /* case SQL_DATE:       These are commented out */
		      /* case SQL_TIME:       in DBI's dbi_sql.h      */
		      /* case SQL_TIMESTAMP:                          */
		      /* case LONGVARCHAR:                            */
		      /* case BINARY:                                 */
		      /* case VARBINARY:                              */
		      /* case LONGVARBINARY                           */
			isNum = FALSE;
			break;
		      default:
			isNum = FALSE;
			break;
		    }
		    if (!isNum) {
		        *ptr++ = '\'';
		    }
		    while (vallen--) {
		      switch ((c = *valbuf++)) {
		        case '\0':
			  *ptr++ = '\\';
			  *ptr++ = '0';
			  break;
		        case '\'':
		        case '\\':
			  *ptr++ = '\\';
			  /* No break! */
		        default:
			  *ptr++ = c;
			  break;
		        }
		    }
		    if (!isNum) {
		        *ptr++ = '\'';
		    }
		}
	    }
	    break;
	  default:
	    *ptr++ = statement[j++];
	    break;
	}
    }
    *slenPtr = ptr - salloc;
    *ptr++ = '\0';

    return salloc;
}


int BindParam(imp_sth_ph_t* ph, SV* value, IV sql_type) {
    if (ph->value) {
        (void) SvREFCNT_dec(ph->value);
    }
    (void) SvREFCNT_inc(ph->value = value);
    if (sql_type) {
        ph->type = sql_type;
    }
    return TRUE;
}
