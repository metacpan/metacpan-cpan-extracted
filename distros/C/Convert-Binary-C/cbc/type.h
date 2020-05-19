/*******************************************************************************
*
* HEADER: type.h
*
********************************************************************************
*
* DESCRIPTION: C::B::C type names
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_TYPE_H
#define _CBC_TYPE_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "ctlib/cttype.h"
#include "cbc/cbc.h"
#include "cbc/member.h"

/*===== DEFINES ==============================================================*/

#define ALLOW_UNIONS       0x00000001
#define ALLOW_STRUCTS      0x00000002
#define ALLOW_ENUMS        0x00000004
#define ALLOW_POINTERS     0x00000008
#define ALLOW_ARRAYS       0x00000010
#define ALLOW_BASIC_TYPES  0x00000020

#define CBC_GMI_NO_CALC    0x1


/*===== TYPEDEFS =============================================================*/


/*===== FUNCTION PROTOTYPES ==================================================*/

#define get_member_info CBC_get_member_info
int get_member_info(pTHX_ CBC *THIS, const char *name, MemberInfo *pMI, unsigned gmi_flags);

#define get_type_spec CBC_get_type_spec
int get_type_spec(CBC *THIS, const char *name, const char **pEOS, TypeSpec *pTS);

#define get_type_name_string CBC_get_type_name_string
SV *get_type_name_string(pTHX_ const MemberInfo *pMI);

#define is_typedef_defined CBC_is_typedef_defined
int is_typedef_defined(Typedef *pTypedef);

#define check_allowed_types_string CBC_check_allowed_types_string
const char *check_allowed_types_string(const MemberInfo *pMI, U32 allowed_types);

#define check_allowed_types CBC_check_allowed_types
void check_allowed_types(pTHX_ const MemberInfo *pMI, const char *method, U32 allowed_types);

#endif
