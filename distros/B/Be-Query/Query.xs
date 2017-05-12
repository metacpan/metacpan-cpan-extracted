/* Be::Query */
/* Copyright 1999 Tom Spindler */
/* This file is covered by the Artistic License. */
/* $Id: Query.xs,v 1.3 1999/05/03 19:12:29 dogcow Exp dogcow $ */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <errno.h>
#include <string.h>
#include <dirent.h>
#include <be/storage/Query.h>
#include <be/kernel/fs_info.h>
#include <be/kernel/fs_query.h>

/* See http://www.be.com/documentation/be_book/The%20Storage%20Kit/QueryFuncs.html for more info on how the query stuff works. */

MODULE = Be::Query          PACKAGE = Be::Query

PROTOTYPES: ENABLE

void
Query(volumepath, query)
        char * volumepath;
	char * query;
ALIAS:
	Be::Query::Query = 0
	Be::Query = 1
PREINIT:
        DIR *q;
	dev_t d[256];
	char buf[PATH_MAX];
	dirent *de;
	int justone = 1;
	int i;
	int32 pos;
PPCODE:
	memset(d, 0, sizeof(d));
	if (strcmp("all", volumepath)) { /* nope, it's a pathname */
	  d[0] = dev_for_path(volumepath);
	} else { /* fill up the array with all the device numbers */
	  i = 0;
	  while(0 <= (d[i++] = next_dev(&pos))) {
	 	; /* we filled the array on the previous line */
	  }
	}		  

	i = 0;
	
	while (0 != d[i]) {
	  if (0 != (q = fs_open_query(d[i], query, 0))) {
	    while (0 != (de = fs_read_query(q))) {
	      get_path_for_dirent(de, buf, PATH_MAX);
	      XPUSHs(sv_2mortal(newSVpv(buf, strlen(buf))));
	    }
	  }
	  i++;
	}
          
