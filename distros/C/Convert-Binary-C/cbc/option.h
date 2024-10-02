/*******************************************************************************
*
* HEADER: option.h
*
********************************************************************************
*
* DESCRIPTION: C::B::C options
*
********************************************************************************
*
* Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_OPTION_H
#define _CBC_OPTION_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "util/list.h"
#include "cbc/cbc.h"


/*===== DEFINES ==============================================================*/


/*===== TYPEDEFS =============================================================*/

typedef struct {
  unsigned option_modified : 1;
  unsigned impacts_layout  : 1;
  unsigned impacts_preproc : 1;
} HandleOptionResult;


/*===== FUNCTION PROTOTYPES ==================================================*/

#define handle_string_list CBC_handle_string_list
void handle_string_list(pTHX_ const char *option, LinkedList list, SV *sv, SV **rval);

#define handle_option CBC_handle_option
void handle_option(pTHX_ CBC *THIS, SV *opt, SV *sv_val, SV **rval, HandleOptionResult *p_res);

#define get_configuration CBC_get_configuration
SV *get_configuration(pTHX_ CBC *THIS);

#define get_native_property CBC_get_native_property
SV *get_native_property(pTHX_ const char *property);

#endif
