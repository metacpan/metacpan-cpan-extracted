/*******************************************************************************
*
* HEADER: basic.h
*
********************************************************************************
*
* DESCRIPTION: C::B::C basic types
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_BASIC_H
#define _CBC_BASIC_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "ctlib/cttype.h"


/*===== DEFINES ==============================================================*/


/*===== TYPEDEFS =============================================================*/

typedef struct _basic_types *BasicTypes;


/*===== FUNCTION PROTOTYPES ==================================================*/

#define basic_types_new CBC_basic_types_new
BasicTypes basic_types_new(void);

#define basic_types_delete CBC_basic_types_delete
void basic_types_delete(BasicTypes bt);

#define basic_types_clone CBC_basic_types_clone
BasicTypes basic_types_clone(const BasicTypes src);

#define basic_types_reset CBC_basic_types_reset
void basic_types_reset(BasicTypes bt);

#define basic_types_get_declarator CBC_basic_types_get_declarator
Declarator *basic_types_get_declarator(BasicTypes bt, unsigned tflags);

#define get_basic_type_spec CBC_get_basic_type_spec
int get_basic_type_spec(const char *name, TypeSpec *pTS);

#endif
