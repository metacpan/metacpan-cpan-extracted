/*******************************************************************************
*
* MODULE: cttype.c
*
********************************************************************************
*
* DESCRIPTION: ANSI C data type objects
*
********************************************************************************
*
* Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

/*===== GLOBAL INCLUDES ======================================================*/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stddef.h>


/*===== LOCAL INCLUDES =======================================================*/

#include "cttype.h"
#include "ctdebug.h"
#include "cterror.h"
#include "util/memalloc.h"


/*===== DEFINES ==============================================================*/

#define CTLIB_STRINGIFY(x) #x

#if defined(__GNUC__) && !defined(__clang__)
#  define CTLIB_DIAG_PUSH _Pragma("GCC diagnostic push")
#  define CTLIB_DIAG_POP  _Pragma("GCC diagnostic pop")
#  define CTLIB_DIAG_GCC_IGNORE(what) \
     _Pragma(CTLIB_STRINGIFY(GCC diagnostic ignored what))
#else
#  define CTLIB_DIAG_PUSH
#  define CTLIB_DIAG_POP
#  define CTLIB_DIAG_GCC_IGNORE(what)
#endif

#define CTLIB_DIAG_IGNORE_STRINGOP_OVERFLOW \
          CTLIB_DIAG_GCC_IGNORE("-Wstringop-overflow")

#define CTLIB_DIAG_IGNORE_STRINGOP_OVERREAD \
          CTLIB_DIAG_GCC_IGNORE("-Wstringop-overread")

#define CONSTRUCT_OBJECT(type, name)                                           \
  type *name;                                                                  \
  AllocF(type *, name, sizeof(type));                                          \
  PROFILE_ADD(type, sizeof(type))

#define CLONE_OBJECT(type, dest, src)                                          \
  type *dest;                                                                  \
  if ((src) == NULL)                                                           \
    return NULL;                                                               \
  AllocF(type *, dest, sizeof(type));                                          \
  memcpy(dest, src, sizeof(type));                                             \
  PROFILE_ADD(type, sizeof(type))

#define CONSTRUCT_OBJECT_IDENT(type, name)                                     \
  type *name;                                                                  \
  if (identifier && id_len == 0)                                               \
    id_len = strlen(identifier);                                               \
  AllocF(type *, name, offsetof(type, identifier) + id_len + 1);               \
  if (identifier)                                                              \
  {                                                                            \
    CTLIB_DIAG_PUSH \
    CTLIB_DIAG_IGNORE_STRINGOP_OVERFLOW \
    CTLIB_DIAG_IGNORE_STRINGOP_OVERREAD \
    strncpy(name->identifier, identifier, id_len);                             \
    name->identifier[id_len] = '\0';                                           \
    CTLIB_DIAG_POP \
  }                                                                            \
  else                                                                         \
    name->identifier[0] = '\0';                                                \
  name->id_len = (unsigned char) (id_len < 255 ? id_len : 255);                \
  PROFILE_ADD(type, offsetof(type, identifier) + id_len + 1)

#define CLONE_OBJECT_IDENT(type, dest, src)                                    \
  type *dest;                                                                  \
  size_t count = offsetof(type, identifier) + 1;                               \
  if ((src) == NULL)                                                           \
    return NULL;                                                               \
  if ((src)->id_len)                                                           \
    count += CTT_IDLEN(src);                                                   \
  AllocF(type *, dest, count);                                                 \
  memcpy(dest, src, count);                                                    \
  PROFILE_ADD(type, count)

#define DELETE_OBJECT_IDENT(type, ptr)                                         \
        do {                                                                   \
          PROFILE_DEL(type, offsetof(type, identifier) + CTT_IDLEN(ptr) + 1);  \
          Free(ptr);                                                           \
        } while (0)

#define DELETE_OBJECT(type, ptr)                                               \
        do {                                                                   \
          PROFILE_DEL(type, sizeof(type));                                     \
          Free(ptr);                                                           \
        } while (0)

#ifdef CTLIB_PROFILE_MEM

#define PROFILE_ADD(ix, size)                                                  \
        do {                                                                   \
          struct MemProfile *p = &gs_profile[PROFILE_ ## ix];                  \
          p->total++;                                                          \
          p->mtotal += size;                                                   \
          if (++p->cur > p->max)                                               \
            p->max = p->cur;                                                   \
          p->mcur += size;                                                     \
          if (p->mcur > p->mmax)                                               \
            p->mmax = p->mcur;                                                 \
          if (!gs_profile_init)                                                \
          {                                                                    \
            gs_profile_init = 1;                                               \
            (void) atexit(profile_dump);                                       \
          }                                                                    \
        } while (0)

#define PROFILE_DEL(ix, size)                                                  \
        do {                                                                   \
          struct MemProfile *p = &gs_profile[PROFILE_ ## ix];                  \
          p->cur--;                                                            \
          p->mcur -= size;                                                     \
        } while (0)

#else

#define PROFILE_ADD(ix, size)  (void)0
#define PROFILE_DEL(ix, size)  (void)0

#endif

/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

#ifdef CTLIB_PROFILE_MEM

enum {
  PROFILE_Value,
  PROFILE_Enumerator,
  PROFILE_EnumSpecifier,
  PROFILE_Declarator,
  PROFILE_StructDeclaration,
  PROFILE_Struct,
  PROFILE_Typedef,
  PROFILE_TypedefList,
  PROFILE_MAX,
};

static struct MemProfile {
  const char *name;
  int size;
  long total, cur, max;
  long mtotal, mcur, mmax;
} gs_profile[PROFILE_MAX] = {
#define PROFTYPE(type) { #type, sizeof(type) }
  PROFTYPE(Value),
  PROFTYPE(Enumerator),
  PROFTYPE(EnumSpecifier),
  PROFTYPE(Declarator),
  PROFTYPE(StructDeclaration),
  PROFTYPE(Struct),
  PROFTYPE(Typedef),
  PROFTYPE(TypedefList)
#undef PROFTYPE
};

int gs_profile_init = 0;

#endif

/*===== STATIC FUNCTIONS =====================================================*/

#ifdef CTLIB_PROFILE_MEM

void profile_dump(void)
{
  int i;
  struct MemProfile *p = &gs_profile[0];

  fprintf(stderr, "\n\n=== MEMORY PROFILE ===\n\n");

  for (i = 0; i < PROFILE_MAX; i++, p++)
    fprintf(stderr, "%-20s (%3d bytes): total=%6ld (%9ld bytes) / "
                    "cur=%6ld (%9ld bytes) / max=%6ld (%9ld bytes)\n",
                    p->name, p->size, p->total, p->mtotal, p->cur,
                    p->mcur, p->max, p->mmax);

  fprintf(stderr, "\n======================\n\n");
}

#endif

/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: value_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Value object constructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

Value *value_new(signed long iv, u_32 flags)
{
  CONSTRUCT_OBJECT(Value, pValue);

  pValue->iv    = iv;
  pValue->flags = flags;

  CT_DEBUG(TYPE, ("type::value_new( iv=%ld flags=0x%08lX ) = %p",
                  iv, (unsigned long) flags, pValue));

  return pValue;
}

/*******************************************************************************
*
*   ROUTINE: value_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Value object destructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void value_delete(Value *pValue)
{
  CT_DEBUG(TYPE, ("type::value_delete( pValue=%p )", pValue));

  if (pValue)
    DELETE_OBJECT(Value, pValue);
}

/*******************************************************************************
*
*   ROUTINE: value_clone
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Clone Value object.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

Value *value_clone(const Value *pSrc)
{
  CLONE_OBJECT(Value, pDest, pSrc);

  CT_DEBUG(TYPE, ("type::value_clone( %p ) = %p", pSrc, pDest));

  return pDest;
}

/*******************************************************************************
*
*   ROUTINE: enum_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Enumeration object constructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

Enumerator *enum_new(const char *identifier, int id_len, Value *pValue)
{
  CONSTRUCT_OBJECT_IDENT(Enumerator, pEnum);

  if (pValue)
  {
    pEnum->value = *pValue;
    if (pValue->flags & V_IS_UNDEF)
      pEnum->value.flags |= V_IS_UNSAFE_UNDEF;
  }
  else
  {
    pEnum->value.iv    = 0;
    pEnum->value.flags = V_IS_UNDEF;
  }

  CT_DEBUG(TYPE, ("type::enum_new( identifier=\"%s\", pValue=%p "
                  "[iv=%ld, flags=0x%08lX] ) = %p",
                  pEnum->identifier, pValue, pEnum->value.iv,
                  (unsigned long) pEnum->value.flags, pEnum));

  return pEnum;
}

/*******************************************************************************
*
*   ROUTINE: enum_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Enumeration object destructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void enum_delete(Enumerator *pEnum)
{
  CT_DEBUG(TYPE, ("type::enum_delete( pEnum=%p [identifier=\"%s\"] )",
                  pEnum, pEnum ? pEnum->identifier : ""));

  if (pEnum)
    DELETE_OBJECT_IDENT(Enumerator, pEnum);
}

/*******************************************************************************
*
*   ROUTINE: enum_clone
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Clone Enumeration object.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

Enumerator *enum_clone(const Enumerator *pSrc)
{
  CLONE_OBJECT_IDENT(Enumerator, pDest, pSrc);

  CT_DEBUG(TYPE, ("type::enum_clone( pSrc=%p [identifier=\"%s\"] ) = %p",
                  pSrc, pSrc ? pSrc->identifier : "", pDest));

  return pDest;
}

/*******************************************************************************
*
*   ROUTINE: enumspec_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Enumeration Specifier object constructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

EnumSpecifier *enumspec_new(const char *identifier, int id_len, LinkedList enumerators)
{
  CONSTRUCT_OBJECT_IDENT(EnumSpecifier, pEnumSpec);

  pEnumSpec->ctype    = TYP_ENUM;
  pEnumSpec->tflags   = T_ENUM;
  pEnumSpec->refcount = 0;
  pEnumSpec->tags     = NULL;

  if (enumerators == NULL)
    pEnumSpec->enumerators = NULL;
  else
    enumspec_update(pEnumSpec, enumerators);

  CT_DEBUG(TYPE, ("type::enumspec_new( identifier=\"%s\", enumerators=%p [count=%d] ) = %p",
                  pEnumSpec->identifier, enumerators, LL_count( enumerators ), pEnumSpec));

  return pEnumSpec;
}

/*******************************************************************************
*
*   ROUTINE: enumspec_update
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Update an Enumeration Specifier object after all enumerators
*              have been added. This routine will update the sign and size
*              properties.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void enumspec_update(EnumSpecifier *pEnumSpec, LinkedList enumerators)
{
  ListIterator ei;
  Enumerator *pEnum;
  long min, max;

  CT_DEBUG(TYPE, ("type::enumspec_update( pEnumSpec=%p [identifier=\"%s\"], enumerators=%p [count=%d] )",
                  pEnumSpec, pEnumSpec->identifier, enumerators, LL_count( enumerators )));

  pEnumSpec->tflags      = 0;
  pEnumSpec->enumerators = enumerators;
  min = max = 0;

  LL_foreach(pEnum, ei, enumerators)
  {
    if (pEnum->value.iv > max)
      max = pEnum->value.iv;
    else if (pEnum->value.iv < min)
      min = pEnum->value.iv;

    if (IS_UNSAFE_VAL(pEnum->value))
      pEnumSpec->tflags |= T_UNSAFE_VAL;
  }

  if (min < 0)
  {
    pEnumSpec->tflags |= T_SIGNED;

    if (min >= -128 && max < 128)
    {
      pEnumSpec->sizes[ES_SIGNED_SIZE]   = 1U;
      pEnumSpec->sizes[ES_UNSIGNED_SIZE] = 1U;
    }
    else if (min >= -32768 && max < 32768)
    {
      pEnumSpec->sizes[ES_SIGNED_SIZE]   = 2U;
      pEnumSpec->sizes[ES_UNSIGNED_SIZE] = 2U;
    }
    else
    {
      pEnumSpec->sizes[ES_SIGNED_SIZE]   = 4U;
      pEnumSpec->sizes[ES_UNSIGNED_SIZE] = 4U;
    }
  }
  else
  {
    pEnumSpec->tflags |= T_UNSIGNED;

    if (max < 256)
      pEnumSpec->sizes[ES_UNSIGNED_SIZE] = 1U;
    else if (max < 65536)
      pEnumSpec->sizes[ES_UNSIGNED_SIZE] = 2U;
    else
      pEnumSpec->sizes[ES_UNSIGNED_SIZE] = 4U;

    if (max < 128)
      pEnumSpec->sizes[ES_SIGNED_SIZE] = 1U;
    else if (max < 32768)
      pEnumSpec->sizes[ES_SIGNED_SIZE] = 2U;
    else
      pEnumSpec->sizes[ES_SIGNED_SIZE] = 4U;
  }
}

/*******************************************************************************
*
*   ROUTINE: enumspec_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Enumeration Specifier object destructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void enumspec_delete(EnumSpecifier *pEnumSpec)
{
  CT_DEBUG(TYPE, ("type::enumspec_delete( pEnumSpec=%p [identifier=\"%s\"] )",
                  pEnumSpec, pEnumSpec ? pEnumSpec->identifier : ""));

  if (pEnumSpec)
  {
    LL_destroy(pEnumSpec->enumerators, (LLDestroyFunc) enum_delete);
    delete_taglist(&pEnumSpec->tags);
    DELETE_OBJECT_IDENT(EnumSpecifier, pEnumSpec);
  }
}

/*******************************************************************************
*
*   ROUTINE: enumspec_clone
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Clone Enumeration Specifier object.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

EnumSpecifier *enumspec_clone(const EnumSpecifier *pSrc)
{
  CLONE_OBJECT_IDENT(EnumSpecifier, pDest, pSrc);

  CT_DEBUG(TYPE, ("type::enumspec_clone( pSrc=%p [identifier=\"%s\"] ) = %p",
                  pSrc, pSrc ? pSrc->identifier : "", pDest));

  pDest->enumerators = LL_clone(pSrc->enumerators, (LLCloneFunc) enum_clone);
  pDest->tags        = clone_taglist(pSrc->tags);

  return pDest;
}

/*******************************************************************************
*
*   ROUTINE: decl_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Declarator object constructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

Declarator *decl_new(const char *identifier, int id_len)
{
  CONSTRUCT_OBJECT_IDENT(Declarator, pDecl);

  pDecl->offset            = -1;
  pDecl->size              = -1;
  pDecl->item_size         = -1;
  pDecl->tags              = NULL;
  pDecl->ext.array         = NULL;
  pDecl->ext.bitfield.size =  0;
  pDecl->ext.bitfield.bits =  0;
  pDecl->ext.bitfield.pos  =  0;
  pDecl->pointer_flag      =  0;
  pDecl->array_flag        =  0;
  pDecl->bitfield_flag     =  0;

  CT_DEBUG(TYPE, ("type::decl_new( identifier=\"%s\" ) = %p",
                  pDecl->identifier, pDecl));

  return pDecl;
}

/*******************************************************************************
*
*   ROUTINE: decl_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Declarator object destructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void decl_delete(Declarator *pDecl)
{
  CT_DEBUG(TYPE, ("type::decl_delete( pDecl=%p [identifier=\"%s\"] )",
                  pDecl, pDecl ? pDecl->identifier : ""));

  if (pDecl)
  {
    if (pDecl->array_flag)
      LL_destroy(pDecl->ext.array, (LLDestroyFunc) value_delete);
    delete_taglist(&pDecl->tags);
    DELETE_OBJECT_IDENT(Declarator, pDecl);
  }
}

/*******************************************************************************
*
*   ROUTINE: decl_clone
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Clone Declarator object.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

Declarator *decl_clone(const Declarator *pSrc)
{
  CLONE_OBJECT_IDENT(Declarator, pDest, pSrc);

  CT_DEBUG(TYPE, ("type::decl_clone( pSrc=%p [identifier=\"%s\"] ) = %p",
                  pSrc, pSrc ? pSrc->identifier : "", pDest));

  if (pSrc->array_flag)
    pDest->ext.array = LL_clone(pSrc->ext.array, (LLCloneFunc) value_clone);

  pDest->tags = clone_taglist(pSrc->tags);

  return pDest;
}

/*******************************************************************************
*
*   ROUTINE: structdecl_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Struct Declaration object constructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

StructDeclaration *structdecl_new(TypeSpec type, LinkedList declarators)
{
  CONSTRUCT_OBJECT(StructDeclaration, pStructDecl);

  pStructDecl->type        = type;
  pStructDecl->declarators = declarators;
  pStructDecl->offset      = 0;
  pStructDecl->size        = 0;

  CT_DEBUG(TYPE, ("type::structdecl_new( type=[tflags=0x%08lX,ptr=%p], "
                  "declarators=%p [count=%d] ) = %p",
                  (unsigned long) type.tflags, type.ptr, declarators,
                  LL_count(declarators), pStructDecl));

  return pStructDecl;
}

/*******************************************************************************
*
*   ROUTINE: structdecl_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Struct Declaration object destructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void structdecl_delete(StructDeclaration *pStructDecl)
{
  CT_DEBUG(TYPE, ("type::structdecl_delete( pStructDecl=%p )", pStructDecl));

  if (pStructDecl)
  {
    LL_destroy(pStructDecl->declarators, (LLDestroyFunc) decl_delete);
    DELETE_OBJECT(StructDeclaration, pStructDecl);
  }
}

/*******************************************************************************
*
*   ROUTINE: structdecl_clone
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Clone Struct Declaration object.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

StructDeclaration *structdecl_clone(const StructDeclaration *pSrc)
{
  CLONE_OBJECT(StructDeclaration, pDest, pSrc);

  CT_DEBUG(TYPE, ("type::structdecl_clone( pSrc=%p ) = %p", pSrc, pDest));

  pDest->declarators = LL_clone(pSrc->declarators, (LLCloneFunc) decl_clone);

  return pDest;
}

/*******************************************************************************
*
*   ROUTINE: struct_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Struct/Union object constructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

Struct *struct_new(const char *identifier, int id_len, u_32 tflags, unsigned pack, LinkedList declarations)
{
  CONSTRUCT_OBJECT_IDENT(Struct, pStruct);

  pStruct->ctype = TYP_STRUCT;

  pStruct->tflags       = tflags;
  pStruct->refcount     = 0;
  pStruct->align        = 0;
  pStruct->size         = 0;
  pStruct->pack         = pack;
  pStruct->declarations = declarations;
  pStruct->tags         = NULL;

  CT_DEBUG(TYPE, ("type::struct_new( identifier=\"%s\", tflags=0x%08lX, "
                  "pack=%d, declarations=%p [count=%d] ) = %p",
                  pStruct->identifier, (unsigned long) tflags, pack,
                  declarations, LL_count(declarations), pStruct));

  return pStruct;
}

/*******************************************************************************
*
*   ROUTINE: struct_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Struct/Union object destructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void struct_delete(Struct *pStruct)
{
  CT_DEBUG(TYPE, ("type::struct_delete( pStruct=%p )", pStruct));

  if (pStruct)
  {
    LL_destroy(pStruct->declarations, (LLDestroyFunc) structdecl_delete);
    delete_taglist(&pStruct->tags);
    DELETE_OBJECT_IDENT(Struct, pStruct);
  }
}

/*******************************************************************************
*
*   ROUTINE: struct_clone
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Clone Struct object.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

Struct *struct_clone(const Struct *pSrc)
{
  CLONE_OBJECT_IDENT(Struct, pDest, pSrc);

  CT_DEBUG(TYPE, ("type::struct_clone( pSrc=%p [identifier=\"%s\"] ) = %p",
                  pSrc, pSrc ? pSrc->identifier : "", pDest));

  pDest->declarations = LL_clone(pSrc->declarations, (LLCloneFunc) structdecl_clone);
  pDest->tags         = clone_taglist(pSrc->tags);

  return pDest;
}

/*******************************************************************************
*
*   ROUTINE: typedef_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Typedef object constructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

Typedef *typedef_new(TypeSpec *pType, Declarator *pDecl)
{
  CONSTRUCT_OBJECT(Typedef, pTypedef);

  pTypedef->ctype = TYP_TYPEDEF;

  pTypedef->pType = pType;
  pTypedef->pDecl = pDecl;

  CT_DEBUG(TYPE, ("type::typedef_new( type=[tflags=0x%08lX,ptr=%p], "
                  "pDecl=%p [identifier=\"%s\"] ) = %p",
                  (unsigned long) pType->tflags, pType->ptr, pDecl,
                  pDecl ? pDecl->identifier : "", pTypedef));

  return pTypedef;
}

/*******************************************************************************
*
*   ROUTINE: typedef_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Typedef object destructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void typedef_delete(Typedef *pTypedef)
{
  CT_DEBUG(TYPE, ("type::typedef_delete( pTypedef=%p )", pTypedef));

  if (pTypedef)
  {
    decl_delete(pTypedef->pDecl);
    DELETE_OBJECT(Typedef, pTypedef);
  }
}

/*******************************************************************************
*
*   ROUTINE: typedef_clone
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Clone Typedef object.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

Typedef *typedef_clone(const Typedef *pSrc)
{
  CLONE_OBJECT(Typedef, pDest, pSrc);

  CT_DEBUG(TYPE, ("type::typedef_clone( pSrc=%p ) = %p", pSrc, pDest));

  pDest->pDecl = decl_clone(pSrc->pDecl);

  return pDest;
}

/*******************************************************************************
*
*   ROUTINE: typedef_list_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Sep 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Typedef List object constructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

TypedefList *typedef_list_new(TypeSpec type, LinkedList typedefs)
{
  CONSTRUCT_OBJECT(TypedefList, pTypedefList);

  pTypedefList->ctype    = TYP_TYPEDEF_LIST;

  pTypedefList->type     = type;
  pTypedefList->typedefs = typedefs;

  CT_DEBUG(TYPE, ("type::typedef_list_new( type=[tflags=0x%08lX,ptr=%p], typedefs=%p ) = %p",
                  (unsigned long) type.tflags, type.ptr, typedefs, pTypedefList));

  return pTypedefList;
}

/*******************************************************************************
*
*   ROUTINE: typedef_list_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Sep 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Typedef List object destructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void typedef_list_delete(TypedefList *pTypedefList)
{
  CT_DEBUG(TYPE, ("type::typedef_list_delete( pTypedefList=%p )", pTypedefList));

  if (pTypedefList)
  {
    LL_destroy(pTypedefList->typedefs, (LLDestroyFunc) typedef_delete);
    DELETE_OBJECT(TypedefList, pTypedefList);
  }
}

/*******************************************************************************
*
*   ROUTINE: typedef_list_clone
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Clone Typedef List object.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

TypedefList *typedef_list_clone(const TypedefList *pSrc)
{
  CLONE_OBJECT(TypedefList, pDest, pSrc);

  CT_DEBUG(TYPE, ("type::typedef_list_clone( pSrc=%p ) = %p", pSrc, pDest));

  if (pSrc->typedefs)
  {
    ListIterator ti;
    Typedef *pTypedef;

    pDest->typedefs = LL_new();

    LL_foreach(pTypedef, ti, pSrc->typedefs)
    {
      Typedef *pClone = typedef_clone(pTypedef);
      pClone->pType = &pDest->type;
      LL_push(pDest->typedefs, pClone);
    }
  }

  return pDest;
}

/*******************************************************************************
*
*   ROUTINE: get_typedef_list
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Get typedef list object from a typedef object.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

TypedefList *get_typedef_list(Typedef *pTypedef)
{
  TypedefList *pTDL;

  CT_DEBUG(TYPE, ("type::get_typedef_list( pTypedef=%p )", pTypedef));

  if (pTypedef        == NULL        ||
      pTypedef->ctype != TYP_TYPEDEF ||
      pTypedef->pType == NULL)
    return NULL;

  /* assume that pType points to type member of typedef list */
  pTDL = (TypedefList *) (((u_8 *) pTypedef->pType) - offsetof(TypedefList, type));

  if (pTDL->ctype != TYP_TYPEDEF_LIST)
    return NULL;

  return pTDL;
}

/*******************************************************************************
*
*   ROUTINE: ctt_refcount_inc
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Increment reference count of structs / enums.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void ctt_refcount_inc(void *ptr)
{
  if (ptr == NULL)
    return;

  switch (GET_CTYPE(ptr))
  {
    case TYP_ENUM:
      if (((EnumSpecifier *) ptr)->refcount < ~((unsigned)0))
        ((EnumSpecifier *) ptr)->refcount++;
      break;

    case TYP_STRUCT:
      if (((Struct *) ptr)->refcount < ~((unsigned)0))
        ((Struct *) ptr)->refcount++;
      break;

    case TYP_TYPEDEF:
    case TYP_TYPEDEF_LIST:
      /* no refcounting */
      break;

    default:
      fatal_error("invalid cttype (%d) passed to ctt_refcount_inc()", GET_CTYPE(ptr));
      break;
  }
}

