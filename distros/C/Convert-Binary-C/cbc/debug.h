/*******************************************************************************
*
* HEADER: debug.h
*
********************************************************************************
*
* DESCRIPTION: C::B::C debugging stuff
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_DEBUG_H
#define _CBC_DEBUG_H

#ifdef CBC_DEBUGGING

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/


/*===== DEFINES ==============================================================*/


/*===== TYPEDEFS =============================================================*/


/*===== FUNCTION PROTOTYPES ==================================================*/

#define set_debug_options CBC_set_debug_options
void set_debug_options(pTHX_ const char *dbopts);

#define set_debug_file CBC_set_debug_file
void set_debug_file(pTHX_ const char *dbfile);

#define init_debugging CBC_init_debugging
void init_debugging(pTHX);

#endif

#endif
