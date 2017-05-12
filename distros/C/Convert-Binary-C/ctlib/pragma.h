/*******************************************************************************
*
* HEADER: parser.h
*
********************************************************************************
*
* DESCRIPTION: Pragma parser
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CTLIB_PRAGMA_H
#define _CTLIB_PRAGMA_H

/*===== GLOBAL INCLUDES ======================================================*/

/*===== LOCAL INCLUDES =======================================================*/

#include "ctlib/ctparse.h"
#include "util/list.h"


/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

typedef struct _pragmaState PragmaState;


/*===== FUNCTION PROTOTYPES ==================================================*/

#define pragma_parser_new CTlib_pragma_parser_new
PragmaState *pragma_parser_new(CParseInfo *pCPI);

#define pragma_parser_delete CTlib_pragma_parser_delete
void pragma_parser_delete(PragmaState *pPragma);

#define pragma_parser_parse CTlib_pragma_parser_parse
int pragma_parser_parse(PragmaState *pPragma);

#define pragma_parser_set_context CTlib_pragma_parser_set_context
void pragma_parser_set_context(PragmaState *pPragma, const char *file, long int line, const char *code);

#define pragma_parser_get_pack CTlib_pragma_parser_get_pack
unsigned pragma_parser_get_pack(PragmaState *pPragma);

#endif
