/*
@(#)File:            $RCSfile: ixblob.h,v $
@(#)Version:         $Revision: 50.5 $
@(#)Last changed:    $Date: 2001/01/11 06:25:45 $
@(#)Purpose:         Blob Handling Functions
@(#)Author:          J Leffler
@(#)Copyright:       (C) Jonathan Leffler 1997-98,2001
@(#)Product:         Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
*/

/*TABSTOP=4*/

#ifndef IXBLOB_H
#define IXBLOB_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char ixblob_h[] = "@(#)$Id: ixblob.h,v 50.5 2001/01/11 06:25:45 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include <stdio.h>
#include "esqlc.h"

enum BlobLocn
{
	BLOB_DEFAULT, BLOB_IN_MEMORY, BLOB_IN_ANONFILE, BLOB_IN_NAMEFILE
};
typedef enum BlobLocn BlobLocn;

/*
** If you are using blobs allocated with blob_locate(), the space
** allocated for the blob needs to be released by blob_release().
** Blob files may or may not need to be deleted by blob_release(); if
** dflag is non-zero, then the file is deleted.  Blobs located in a file
** will be located in the directory given by blob_getdirectory().
** NB: if you specify blobs are located in files, you either need to
** rename fetched files between successive fetches, or you need to
** reallocate the blob structure (blob_release/blob_locate).
** -- Use blob_newfilename() to establish a new file name.  The function
**    is also used by blob_locate().
** -- Use blob_setlocmode() to set the default allocation mode for blobs.
** -- Use blob_getlocmode() to find the default allocation mode; it is
**    used when blob_locate() is called with locn set to BLOB_DEFAULT.
** -- Use blob_setdirectory() to set the directory where blob files are
**    to be created.
** -- Use blob_getdirectory() to find the directory set with
**    blob_setdirectory(), or the value returned by sql_dbtemp() if no
**    value has been set.
** -- Use sql_dbtemp() to return the directory specified by
**    ${DBTEMP:-$TMPDIR}, defaulting to /tmp if no directory is
**    specified by the environment variables.
*/
extern BlobLocn blob_getlocmode(void);
extern char *blob_newfilename(void);
extern const char *blob_getdirectory(void);
extern const char *sql_dbtemp(void);
extern int blob_locate(Blob *blob, BlobLocn locn);
extern void blob_release(Blob *blob, int dflag);
extern void blob_setdirectory(const char *dir);
extern void blob_setlocmode(BlobLocn locn);

#endif	/* IXBLOB_H */
