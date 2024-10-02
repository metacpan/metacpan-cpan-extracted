/*******************************************************************************
*
* HEADER: fileinfo.h
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

#ifndef _CTLIB_FILEINFO_H
#define _CTLIB_FILEINFO_H

/*===== GLOBAL INCLUDES ======================================================*/

#include <stdio.h>
#include <time.h>


/*===== LOCAL INCLUDES =======================================================*/

/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

typedef struct {
  int    valid;
  size_t size;
  time_t access_time;
  time_t modify_time;
  time_t change_time;
  char   name[1];
} FileInfo;


/*===== FUNCTION PROTOTYPES ==================================================*/

#define fileinfo_new CTlib_fileinfo_new
FileInfo *fileinfo_new( FILE *file, char *name, size_t name_len );

#define fileinfo_delete CTlib_fileinfo_delete
void      fileinfo_delete( FileInfo *pFileInfo );

#define fileinfo_clone CTlib_fileinfo_clone
FileInfo *fileinfo_clone( const FileInfo *pSrc );

#endif
