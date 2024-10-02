/*******************************************************************************
*
* HEADER: cttype.h
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

#ifndef _CTLIB_CTTYPE_H
#define _CTLIB_CTTYPE_H

/*===== GLOBAL INCLUDES ======================================================*/

/*===== LOCAL INCLUDES =======================================================*/

#include "arch.h"
#include "cttags.h"
#include "fileinfo.h"
#include "util/list.h"


/*===== DEFINES ==============================================================*/

/* value flags */

#define V_IS_UNDEF                     0x00000001
#define V_IS_UNSAFE                    0x08000000
#define V_IS_UNSAFE_UNDEF              0x10000000
#define V_IS_UNSAFE_CAST               0x20000000
#define V_IS_UNSAFE_PTROP              0x40000000

#define IS_UNSAFE_VAL( val ) ( (val).flags & ( V_IS_UNSAFE       \
                                             | V_IS_UNSAFE_UNDEF \
                                             | V_IS_UNSAFE_CAST  \
                                             | V_IS_UNSAFE_PTROP ) )

/* type flags */

#define T_VOID                         0x00000001
#define T_CHAR                         0x00000002
#define T_SHORT                        0x00000004
#define T_INT                          0x00000008

#define T_LONG                         0x00000010
#define T_FLOAT                        0x00000020
#define T_DOUBLE                       0x00000040
#define T_SIGNED                       0x00000080

#define T_UNSIGNED                     0x00000100
#define T_ENUM                         0x00000200
#define T_STRUCT                       0x00000400
#define T_UNION                        0x00000800
#define T_COMPOUND                     (T_STRUCT | T_UNION)

#define T_TYPE                         0x00001000
#define T_TYPEDEF                      0x00002000
#define T_LONGLONG                     0x00004000

/* these flags are reserved for user defined purposes */
#define T_USER_FLAG_1                  0x00100000
#define T_USER_FLAG_2                  0x00200000
#define T_USER_FLAG_3                  0x00400000
#define T_USER_FLAG_4                  0x00800000

/* this flag indicates the usage of bitfields in structures as they're unsupported */
#define T_HASBITFIELD                  0x40000000

/* this flag indicates the use of unsafe values (e.g. sizes of bitfields) */
#define T_UNSAFE_VAL                   0x80000000

#define ANY_TYPE_NAME ( T_VOID | T_CHAR | T_SHORT | T_INT | T_LONG | T_FLOAT | T_DOUBLE \
                        | T_SIGNED | T_UNSIGNED | T_ENUM | T_STRUCT | T_UNION | T_TYPE )

/* get the type out of a pointer to EnumSpecifier / Struct / Typedef */
#define GET_CTYPE( ptr ) (*((CTType *) ptr))

#define IS_TYP_ENUM( ptr )            ( GET_CTYPE( ptr ) == TYP_ENUM )
#define IS_TYP_STRUCT( ptr )          ( GET_CTYPE( ptr ) == TYP_STRUCT )
#define IS_TYP_TYPEDEF( ptr )         ( GET_CTYPE( ptr ) == TYP_TYPEDEF )
#define IS_TYP_TYPEDEF_LIST( ptr )    ( GET_CTYPE( ptr ) == TYP_TYPEDEF_LIST )

#define CTT_IDLEN(ptr)  ((ptr)->id_len < 255 ? (ptr)->id_len                   \
                         : 255 + strlen((ptr)->identifier + 255))

/*===== TYPEDEFS =============================================================*/

typedef enum {
  TYP_ENUM,
  TYP_STRUCT,
  TYP_TYPEDEF,
  TYP_TYPEDEF_LIST
} CTType;

enum {
  ES_UNSIGNED_SIZE,
  ES_SIGNED_SIZE,
  ES_NUM_ENUM_SIZES
};

typedef struct {
  signed long iv;
  u_32        flags;
} Value;

typedef struct {
  FileInfo     *pFI;
  unsigned long line;
} ContextInfo;

typedef struct {
  void       *ptr;
  u_32        tflags;
} TypeSpec;

typedef struct {
  Value       value;
  unsigned char id_len;
  char        identifier[1];
} Enumerator;

typedef struct {
  CTType      ctype;
  u_32        tflags;
  unsigned    refcount;
  unsigned    sizes[ES_NUM_ENUM_SIZES];
  ContextInfo context;
  LinkedList  enumerators;
  CtTagList   tags;
  unsigned char id_len;
  char        identifier[1];
} EnumSpecifier;

typedef struct {
  unsigned char size;     /* size (in bytes), usually same as Declarator.size */
  unsigned char bits;     /* size (in bits) of the bitfield                   */
  unsigned char pos;      /* pos (in bits) of the bitfield (relative to LSB)  */
} BitfieldInfo;

typedef struct {
  signed      offset        : 29;
  unsigned    pointer_flag  :  1;
  unsigned    array_flag    :  1;
  unsigned    bitfield_flag :  1;
  signed      size, item_size;
  CtTagList   tags;
  union {
    LinkedList   array;
    BitfieldInfo bitfield;
  }           ext;
  unsigned char id_len;
  char        identifier[1];
} Declarator;

typedef struct {
  int         pointer_flag;
  int         multiplicator;
} AbstractDeclarator;

typedef struct {
  TypeSpec    type;
  LinkedList  declarators;
  int         offset, size;
} StructDeclaration;

typedef struct {
  CTType      ctype;
  u_32        tflags;
  unsigned    refcount;
  unsigned    align : 16;
  unsigned    pack  : 16;
  unsigned    size;
  ContextInfo context;
  LinkedList  declarations;
  CtTagList   tags;
  unsigned char id_len;
  char        identifier[1];
} Struct;

typedef struct {
  CTType      ctype;
  TypeSpec   *pType;
  Declarator *pDecl;
} Typedef;

typedef struct {
  CTType      ctype;
  TypeSpec    type;
  LinkedList  typedefs;
} TypedefList;

/*===== FUNCTION PROTOTYPES ==================================================*/

#define value_new CTlib_value_new
Value *value_new(signed long iv, u_32 flags);
#define value_delete CTlib_value_delete
void value_delete(Value *pValue);
#define value_clone CTlib_value_clone
Value *value_clone(const Value *pSrc);

#define enum_new CTlib_enum_new
Enumerator *enum_new(const char *identifier, int id_len, Value *pValue);
#define enum_delete CTlib_enum_delete
void enum_delete(Enumerator *pEnum);
#define enum_clone CTlib_enum_clone
Enumerator *enum_clone(const Enumerator *pSrc);

#define enumspec_new CTlib_enumspec_new
EnumSpecifier *enumspec_new(const char *identifier, int id_len, LinkedList enumerators);
#define enumspec_update CTlib_enumspec_update
void enumspec_update(EnumSpecifier *pEnumSpec, LinkedList enumerators);
#define enumspec_delete CTlib_enumspec_delete
void enumspec_delete(EnumSpecifier *pEnumSpec);
#define enumspec_clone CTlib_enumspec_clone
EnumSpecifier *enumspec_clone(const EnumSpecifier *pSrc);

#define decl_new CTlib_decl_new
Declarator *decl_new(const char *identifier, int id_len);
#define decl_delete CTlib_decl_delete
void decl_delete(Declarator *pDecl);
#define decl_clone CTlib_decl_clone
Declarator *decl_clone(const Declarator *pSrc);

#define structdecl_new CTlib_structdecl_new
StructDeclaration *structdecl_new(TypeSpec type, LinkedList declarators);
#define structdecl_delete CTlib_structdecl_delete
void structdecl_delete(StructDeclaration *pStructDecl);
#define structdecl_clone CTlib_structdecl_clone
StructDeclaration *structdecl_clone(const StructDeclaration *pSrc);

#define struct_new CTlib_struct_new
Struct *struct_new(const char *identifier, int id_len, u_32 tflags, unsigned pack,
                   LinkedList declarations);
#define struct_delete CTlib_struct_delete
void struct_delete(Struct *pStruct);
#define struct_clone CTlib_struct_clone
Struct *struct_clone(const Struct *pSrc);

#define typedef_new CTlib_typedef_new
Typedef *typedef_new(TypeSpec *pType, Declarator *pDecl);
#define typedef_delete CTlib_typedef_delete
void typedef_delete(Typedef *pTypedef);
#define typedef_clone CTlib_typedef_clone
Typedef *typedef_clone(const Typedef *pSrc);

#define typedef_list_new CTlib_typedef_list_new
TypedefList *typedef_list_new(TypeSpec type, LinkedList typedefs);
#define typedef_list_delete CTlib_typedef_list_delete
void typedef_list_delete(TypedefList *pTypedefList);
#define typedef_list_clone CTlib_typedef_list_clone
TypedefList *typedef_list_clone(const TypedefList *pSrc);

#define get_typedef_list CTlib_get_typedef_list
TypedefList *get_typedef_list(Typedef *pTypedef);

#define ctt_refcount_inc CTlib_ctt_refcount_inc
void ctt_refcount_inc(void *ptr);

#endif
