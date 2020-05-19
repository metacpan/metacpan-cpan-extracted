/*******************************************************************************
*
* HEADER: pack.h
*
********************************************************************************
*
* DESCRIPTION: C::B::C pack/unpack routines
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_PACK_H
#define _CBC_PACK_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "ctlib/cttype.h"

#include "cbc/cbc.h"


/*===== DEFINES ==============================================================*/

/* values passed between all packing/unpacking routines */
#define pPACKARGS   pTHX_ PackHandle PACK
#define aPACKARGS   aTHX_ PACK


/*===== TYPEDEFS =============================================================*/

typedef struct PackInfo * PackHandle;


/*===== FUNCTION PROTOTYPES ==================================================*/

#define pk_create CBC_pk_create
PackHandle pk_create(const CBC *THIS, SV *self);

#define pk_set_type CBC_pk_set_type
void pk_set_type(PackHandle hdl, const char *type);

#define pk_set_buffer CBC_pk_set_buffer
void pk_set_buffer(PackHandle hdl, SV *bufsv, char *buffer, unsigned long buflen);

#define pk_set_buffer_pos CBC_pk_set_buffer_pos
void pk_set_buffer_pos(PackHandle hdl, unsigned long pos);

#define pk_delete CBC_pk_delete
void pk_delete(PackHandle hdl);

#define pk_pack CBC_pk_pack
void pk_pack(pPACKARGS, const TypeSpec *pTS, const Declarator *pDecl, int dimension, SV *sv);

#define pk_unpack CBC_pk_unpack
SV *pk_unpack(pPACKARGS, const TypeSpec *pTS, const Declarator *pDecl, int dimension);

#endif
