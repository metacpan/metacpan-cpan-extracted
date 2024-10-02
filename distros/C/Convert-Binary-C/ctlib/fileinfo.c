/*******************************************************************************
*
* MODULE: fileinfo.c
*
********************************************************************************
*
* DESCRIPTION: Retrieving information about files
*
********************************************************************************
*
* Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

/*===== GLOBAL INCLUDES ======================================================*/

#include <stdio.h>
#include <string.h>
#include <stddef.h>

#include <sys/stat.h>


/*===== LOCAL INCLUDES =======================================================*/

#include "fileinfo.h"
#include "util/memalloc.h"


/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: fileinfo_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: FileInfo object constructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

FileInfo *fileinfo_new( FILE *file, char *name, size_t name_len )
{
  FileInfo *pFileInfo;
  struct stat buf;

  if( name != NULL && name_len == 0 )
    name_len = strlen( name );

  AllocF( FileInfo *, pFileInfo, offsetof( FileInfo, name ) + name_len + 1 );

  if( name != NULL ) {
    strncpy( pFileInfo->name, name, name_len );
    pFileInfo->name[name_len] = '\0';
  }
  else
    pFileInfo->name[0] = '\0';

  if( file != NULL && fstat( fileno( file ), &buf ) == 0 ) {
    pFileInfo->valid       = 1;
    pFileInfo->size        = buf.st_size;
    pFileInfo->access_time = buf.st_atime;
    pFileInfo->modify_time = buf.st_mtime;
    pFileInfo->change_time = buf.st_ctime;
  }
  else {
    pFileInfo->valid       = 0;
    pFileInfo->size        = 0;
    pFileInfo->access_time = 0;
    pFileInfo->modify_time = 0;
    pFileInfo->change_time = 0;
  }

  return pFileInfo;
}

/*******************************************************************************
*
*   ROUTINE: fileinfo_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: FileInfo object destructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void fileinfo_delete( FileInfo *pFileInfo )
{
  if( pFileInfo )
    Free( pFileInfo );
}

/*******************************************************************************
*
*   ROUTINE: fileinfo_clone
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Clone FileInfo object.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

FileInfo *fileinfo_clone( const FileInfo *pSrc )
{
  FileInfo *pDest;
  size_t size;

  if( pSrc == NULL )
    return NULL;

  size = offsetof( FileInfo, name ) + 1;
  if( pSrc->name[0] != '\0' )
    size += strlen( pSrc->name );

  AllocF( FileInfo *, pDest, size );
  memcpy( pDest, pSrc, size );

  return pDest;
}

