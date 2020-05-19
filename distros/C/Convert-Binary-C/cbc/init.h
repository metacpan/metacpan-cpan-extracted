/*******************************************************************************
*
* HEADER: init.h
*
********************************************************************************
*
* DESCRIPTION: C::B::C initializer
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_INIT_H
#define _CBC_INIT_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "cbc/cbc.h"
#include "cbc/member.h"


/*===== DEFINES ==============================================================*/


/*===== TYPEDEFS =============================================================*/


/*===== FUNCTION PROTOTYPES ==================================================*/

#define get_initializer_string CBC_get_initializer_string
SV *get_initializer_string(pTHX_ CBC *THIS, MemberInfo *pMI, SV *init, const char *name);

#endif
