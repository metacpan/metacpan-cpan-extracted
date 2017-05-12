/*******************************************************************************
*
* HEADER: util.h
*
********************************************************************************
*
* DESCRIPTION: C::B::C utilities
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_UTIL_H
#define _CBC_UTIL_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "cbc/cbc.h"


/*===== DEFINES ==============================================================*/


/*===== TYPEDEFS =============================================================*/


/*===== FUNCTION PROTOTYPES ==================================================*/

#define fatal CBC_fatal
void fatal(const char *f, ...) __attribute__((__noreturn__));

#define newHV_indexed CBC_newHV_indexed
HV *newHV_indexed(pTHX_ const CBC *THIS);

#define croak_gti CBC_croak_gti
void croak_gti(pTHX_ ErrorGTI error, const char *name, int warnOnly);

#define get_basic_type_spec_string CBC_get_basic_type_spec_string
void get_basic_type_spec_string(pTHX_ SV **sv, u_32 flags);

#define add_indent CBC_add_indent
void add_indent(pTHX_ SV *s, int level);

#define load_indexed_hash_module CBC_load_indexed_hash_module
int load_indexed_hash_module(pTHX_ CBC *THIS);

#define set_preferred_indexed_hash_module CBC_set_preferred_indexed_hash_module
void set_preferred_indexed_hash_module(const char *module);

#define string_new CBC_string_new
char *string_new(const char *str);

#define string_new_fromSV CBC_string_new_fromSV
char *string_new_fromSV(pTHX_ SV *sv);

#define string_delete CBC_string_delete
void string_delete(char *sv);

#define clone_string_list CBC_clone_string_list
LinkedList clone_string_list(LinkedList list);

#define dump_sv CBC_dump_sv
void dump_sv(pTHX_ SV *buf, int level, SV *sv);

#define identify_sv CBC_identify_sv
const char *identify_sv(SV *sv);

#endif
