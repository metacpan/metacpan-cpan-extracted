#include <stdio.h>
#include "aglib.h"

/* I do not yet know how to deal with returning pointers in perl's
 * extensions, so this is here to convert from integers to pointers and
 * vice versa.
 *
 * Probably I can simply cast pointer to integer and get away with that,
 * but somehow it looks bad to me.
*/

/* Table for conversion. Size is fixed, nothing but plain walk-through
 * is used. I believe appgen has some limitations on number of tables
 * open anyway.
*/
static void *phtable[20];

/* Pointer to integer.
*/
static int
p2h(void *p)
{ unsigned i=0;
  if(!p)
   return 0;
  for(i=1; i!=sizeof(phtable)/sizeof(*phtable); i++)
   { if(! phtable[i])
      { phtable[i]=p;
        return i;
      }
   }

  /* Good place to throw an exception :)
  */
  fprintf(stderr,"Too many open tables\n");
  return 0;
}

/* Handler to pointer
*/
static void *
h2p(unsigned h)
{ if(h>=sizeof(phtable)/sizeof(*phtable))
   { fprintf(stderr,"Corrupted db handler (h=%d",h);
     return NULL;
   }
  return phtable[h];
}

/* Stubs for appgen methods
*/
unsigned ag_db_open(char const *file)
{ return p2h(db_open(file));
}

int ag_db_close(unsigned dbh)
{ int rc=db_close(h2p(dbh));
  phtable[dbh]=NULL;
  return rc;
}

unsigned	ag_db_create(char const *file, long hsize, int trunc)
{ return p2h(db_create(file,hsize,trunc));
}

int		ag_db_rewind(unsigned dbh)
{ return db_rewind(h2p(dbh));
}

int		ag_db_delete(unsigned dbh)
{ return db_delete(h2p(dbh));
}

int		ag_db_lock(unsigned dbh)
{ return db_lock(h2p(dbh));
}

int		ag_db_unlock(unsigned dbh)
{ return db_unlock(h2p(dbh));
}

int		ag_db_read(unsigned dbh, char *key, int lock)
{ return db_read(h2p(dbh),key,lock);
}

int		ag_db_write(unsigned dbh)
{ return db_write(h2p(dbh));
}

int		ag_db_release(unsigned dbh)
{ return db_release(h2p(dbh));
}

int		ag_db_newrec(unsigned dbh, char *key, long size)
{ return db_newrec(h2p(dbh),key,size);
}

int		ag_db_delrec(unsigned dbh)
{ return db_delrec(h2p(dbh));
}

char *		ag_readnext(unsigned dbh, int foo)
{ return readnext(h2p(dbh),foo);
}

int		ag_drop(unsigned dbh, int attr, int val)
{ return delete(h2p(dbh),attr,val);
}

int		ag_extract(unsigned dbh, int attr, int val, char *buf, int maxsz)
{ return extract(h2p(dbh),attr,val,buf,maxsz);
}

int		ag_replace(unsigned dbh, int attr, int val, char *buf)
{ return replace(h2p(dbh),attr,val,buf);
}

int		ag_insert(unsigned dbh, int attr, int val, char *buf)
{ return insert(h2p(dbh),attr,val,buf);
}

int		ag_db_stat(unsigned dbh, int attr, int val)
{ return db_stat(h2p(dbh),attr,val);
}
