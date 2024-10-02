/*******************************************************************************
*
* HEADER: macros.h
*
********************************************************************************
*
* DESCRIPTION: Handle macro lists
*
********************************************************************************
*
* Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_MACROS_H
#define _CBC_MACROS_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "util/list.h"
#include "ctlib/ctparse.h"


/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

/*===== FUNCTION PROTOTYPES ==================================================*/

#define macros_get_names CBC_macros_get_names
LinkedList macros_get_names(pTHX_ CParseInfo *pCPI, size_t *count);

#define macros_get_definitions CBC_macros_get_definitions
LinkedList macros_get_definitions(pTHX_ CParseInfo *pCPI);

#endif
