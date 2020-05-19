/*******************************************************************************
*
* HEADER: typeinfo.h
*
********************************************************************************
*
* DESCRIPTION: C::B::C type information
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_TYPEINFO_H
#define _CBC_TYPEINFO_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "ctlib/ctparse.h"
#include "ctlib/cttype.h"


/*===== DEFINES ==============================================================*/


/*===== TYPEDEFS =============================================================*/


/*===== FUNCTION PROTOTYPES ==================================================*/

#define get_typedef_def CBC_get_typedef_def
SV *get_typedef_def(pTHX_ const CParseConfig *pCfg, const Typedef *pTypedef);

#define get_enum_spec_def CBC_get_enum_spec_def
SV *get_enum_spec_def(pTHX_ const CParseConfig *pCfg, const EnumSpecifier *pEnumSpec);

#define get_struct_spec_def CBC_get_struct_spec_def
SV *get_struct_spec_def(pTHX_ const CParseConfig *pCfg, const Struct *pStruct);

#endif
