/* This is converting library for appgen.
 * Nothing more then just a set of stubs in order to simplify perl
 * interface with appgen.
 *
 * Tell me who designed appgen libraries structure - we'll both laugh at
 * requirement to have curses linked in on order to open database handler :(
 *
 * Copyright (c) 2000 BNW Inc., Andrew Maltsev <am@xao.com>
*/

#ifdef __cplusplus
extern "C" {
#endif

/* New interface
*/
unsigned	ag_db_open(char const *file);
int		ag_db_close(unsigned dbh);
unsigned	ag_db_create(char const *file, long hsize, int trunc);
int		ag_db_rewind(unsigned dbh);
int		ag_db_delete(unsigned dbh);
int		ag_db_lock(unsigned dbh);
int		ag_db_unlock(unsigned dbh);

int		ag_db_read(unsigned dbh, char *key, int lock);
int		ag_db_write(unsigned dbh);
int		ag_db_release(unsigned dbh);
int		ag_db_newrec(unsigned dbh, char *key, long size);
int		ag_db_delrec(unsigned dbh);
char *		ag_readnext(unsigned dbh, int foo);

int		ag_drop(unsigned dbh, int attr, int val);
int		ag_extract(unsigned dbh, int attr, int val, char *buf, int maxsz);
int		ag_replace(unsigned dbh, int attr, int val, char *buf);
int		ag_insert(unsigned dbh, int attr, int val, char *buf);
int		ag_db_stat(unsigned dbh, int attr, int val);

/* APPGEN database library interface.
 *
 * This is probably bad, but I do not want to include standard appgen
 * include files.
*/

/* File level
*/
void *db_open(char const *file);
int db_close(void *db);
void *db_create(char const *file, long hsize, int trunc);
int db_rewind(void *db);
int db_delete(void *db);
int db_lock(void *db);
int db_unlock(void *db);

/* Record level
*/
int db_read(void *db, char *key, int lock);
int db_write(void *db);
int db_release(void *db);
int db_newrec(void *db, char *key, long size);
int db_delrec(void *db);
char *readnext(void *db, int foo);

/* Field level
*/
int delete(void *db, int attr, int val);
int extract(void *db, int attr, int val, char *buf, int maxsz);
int replace(void *db, int attr, int val, char *buf);
int insert(void *db, int attr, int val, char *buf);
int db_stat(void *db, int attr, int val);

#ifdef __cplusplus
}
#endif
