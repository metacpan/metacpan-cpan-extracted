/*
 *	@(#)$Id: dbdixmap.h,v 58.1 1998/01/06 02:53:23 johnl Exp $ 
 *
 * Copyright (c) 1997-98 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

#ifndef DBDIXMAP_H
#define DBDIXMAP_H

/* Names on LHS are function names from dbd_xsh.h for DBI 0.89 */
/* The functions are called from the code in Sqlflex.xs */
/* The function prototypes are declared in dbd_xsh.h */
/* The functions are defined in dbdattr.ec and dbdimp.ec */

/* Note inconsistent names (no dr_) */
#define dbd_discon_all      dbd_ix_dr_discon_all
#define dbd_init            dbd_ix_dr_init

#define dbd_db_FETCH_attrib dbd_ix_db_FETCH_attrib
#define dbd_db_STORE_attrib dbd_ix_db_STORE_attrib
#define dbd_db_commit       dbd_ix_db_commit
#define dbd_db_destroy      dbd_ix_db_destroy
#define dbd_db_disconnect   dbd_ix_db_disconnect
#define dbd_db_do           dbd_ix_db_do
#define dbd_db_login        dbd_ix_db_login
#define dbd_db_rollback     dbd_ix_db_rollback

/* Note inconsistent name (no st_) for dbd_bind_ph */
#define dbd_bind_ph         dbd_ix_st_bind_ph
#define dbd_st_FETCH_attrib dbd_ix_st_FETCH_attrib
#define dbd_st_STORE_attrib dbd_ix_st_STORE_attrib
#define dbd_st_blob_read    dbd_ix_st_blob_read
#define dbd_st_destroy      dbd_ix_st_destroy
#define dbd_st_execute      dbd_ix_st_execute
#define dbd_st_fetch        dbd_ix_st_fetch
#define dbd_st_finish       dbd_ix_st_finish
#define dbd_st_prepare      dbd_ix_st_prepare
#define dbd_st_rows         dbd_ix_st_rows

/*
** Although dbd_xsh.h declares dbd_describe(), it isn't called anywhere.
** Note inconsistent name (no st_) for dbd_describe
** #define dbd_describe        dbd_ix_describe
*/

#endif /* DBDIXMAP_H */
