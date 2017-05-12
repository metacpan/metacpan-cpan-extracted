/*
 * @(#)$Id: dbdixmap.h,v 100.6 2002/12/14 02:10:53 jleffler Exp $
 *
 * @(#)$Product: Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01) $
 *
 * Copyright 1997-98 Jonathan Leffler
 * Copyright 2001-02 IBM
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

#ifndef DBDIXMAP_H
#define DBDIXMAP_H

/* Names on LHS are function names from dbd_xsh.h for DBI 0.89 */
/* The functions are called from the code in Informix.xs */
/* The function prototypes are declared in dbd_xsh.h */
/* The functions are defined in dbdattr.ec and dbdimp.ec */

#define dbd_init            dbd_ix_init

/* Note inconsistent name (no dr_) for dbd_discon_all */
#define dbd_discon_all      dbd_ix_dr_discon_all

/* dbd_dr_data_sources requires DBI v1.33 or later */
#define dbd_dr_data_sources	dbd_ix_dr_data_sources

#define dbd_db_FETCH_attrib dbd_ix_db_FETCH_attrib
#define dbd_db_STORE_attrib dbd_ix_db_STORE_attrib
#define dbd_db_commit       dbd_ix_db_commit
#define dbd_db_destroy      dbd_ix_db_destroy
#define dbd_db_disconnect   dbd_ix_db_disconnect
/*#define dbd_db_do           dbd_ix_db_do*/
#define dbd_db_login6       dbd_ix_db_connect
#define dbd_db_login        dbd_ix_db_version_of_dbi_is_too_old
#define dbd_db_rollback     dbd_ix_db_rollback

/* Note inconsistent name (no st_) for dbd_bind_ph */
#define dbd_bind_ph         dbd_ix_st_bind_ph
#define dbd_st_FETCH_attrib dbd_ix_st_FETCH_attrib
#define dbd_st_STORE_attrib dbd_ix_st_STORE_attrib
#define dbd_st_blob_read    dbd_ix_st_blob_read
#define dbd_st_destroy      dbd_ix_st_destroy
#define dbd_st_execute      dbd_ix_st_execute
#define dbd_st_fetch        dbd_ix_st_fetch
#define dbd_st_finish3      dbd_ix_st_finish
#define dbd_st_prepare      dbd_ix_st_prepare
#define dbd_st_rows         dbd_ix_st_rows

#endif /* DBDIXMAP_H */
