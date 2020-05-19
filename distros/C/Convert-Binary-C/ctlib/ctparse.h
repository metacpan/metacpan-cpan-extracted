/*******************************************************************************
*
* HEADER: ctparse.h
*
********************************************************************************
*
* DESCRIPTION: Parser interface routines
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CTLIB_CTPARSE_H
#define _CTLIB_CTPARSE_H

/*===== GLOBAL INCLUDES ======================================================*/

/*===== LOCAL INCLUDES =======================================================*/

#include "ctlib/arch.h"
#include "ctlib/cttype.h"
#include "ctlib/layout.h"
#include "util/list.h"
#include "util/hash.h"


/*===== DEFINES ==============================================================*/


/*===== TYPEDEFS =============================================================*/

struct CPP;

typedef struct {
  char          *buffer;
  unsigned long  pos, length;
} Buffer;

typedef struct {
  LayoutParam layout;

  ErrorGTI (*get_type_info)(const LayoutParam *, const TypeSpec *,
                            const Declarator *, const char *, ...);

  void (*layout_compound)(const LayoutParam *, Struct *);

  /* boolean options */
  unsigned unsigned_chars     : 1;
  unsigned unsigned_bitfields : 1;
  unsigned issue_warnings     : 1;
  unsigned disable_parser     : 1;
  unsigned has_cpp_comments   : 1;
  unsigned has_macro_vaargs   : 1;
  unsigned has_std_c          : 1;
  unsigned has_std_c_hosted   : 1;
  unsigned is_std_c_hosted    : 1;

  long int std_c_version;

  u_32 keywords;

#define HAS_KEYWORD_AUTO     0x00000001U
#define HAS_KEYWORD_CONST    0x00000002U
#define HAS_KEYWORD_DOUBLE   0x00000004U
#define HAS_KEYWORD_ENUM     0x00000008U
#define HAS_KEYWORD_EXTERN   0x00000010U
#define HAS_KEYWORD_FLOAT    0x00000020U
#define HAS_KEYWORD_INLINE   0x00000040U
#define HAS_KEYWORD_LONG     0x00000080U
#define HAS_KEYWORD_REGISTER 0x00000100U
#define HAS_KEYWORD_RESTRICT 0x00000200U
#define HAS_KEYWORD_SHORT    0x00000400U
#define HAS_KEYWORD_SIGNED   0x00000800U
#define HAS_KEYWORD_STATIC   0x00001000U
#define HAS_KEYWORD_UNSIGNED 0x00002000U
#define HAS_KEYWORD_VOID     0x00004000U
#define HAS_KEYWORD_VOLATILE 0x00008000U
#define HAS_KEYWORD_ASM      0x00010000U

#define HAS_ALL_KEYWORDS     0x0001FFFFU

  LinkedList disabled_keywords;
  LinkedList includes;
  LinkedList defines;
  LinkedList assertions;

  HashTable  keyword_map;
} CParseConfig;

typedef struct {
  LinkedList enums;
  LinkedList structs;
  LinkedList typedef_lists;
  HashTable  htEnumerators;
  HashTable  htEnums;
  HashTable  htStructs;
  HashTable  htTypedefs;
  HashTable  htFiles;
  HashTable  htPredefined;
  LinkedList errorStack;
  struct CPP *pp;
  unsigned   available : 1;
  unsigned   ready     : 1;
} CParseInfo;

typedef struct {
  void       *arg;
  const char *name;
  const char *definition;
  size_t      definition_len;
} CMacroInfo;

#define CMIF_WITH_DEFINITION 0x00000001
#define CMIF_NO_PREDEFINED   0x00000002
typedef unsigned CMIFlags;


/*===== FUNCTION PROTOTYPES ==================================================*/

#define parse_buffer CTlib_parse_buffer
int parse_buffer(const char *filename, const Buffer *pBuf,
                 const CParseConfig *pCPC, CParseInfo *pCPI);

#define init_parse_info CTlib_init_parse_info
void init_parse_info(CParseInfo *pCPI);

#define free_parse_info CTlib_free_parse_info
void free_parse_info(CParseInfo *pCPI);

#define reset_preprocessor CTlib_reset_preprocessor
void reset_preprocessor(CParseInfo *pCPI);

#define reset_parse_info CTlib_reset_parse_info
void reset_parse_info(CParseInfo *pCPI);

#define update_parse_info CTlib_update_parse_info
void update_parse_info(CParseInfo *pCPI, const CParseConfig *pCPC);

#define clone_parse_info CTlib_clone_parse_info
void clone_parse_info(CParseInfo *pDest, const CParseInfo *pSrc);

#define macro_is_defined CTlib_macro_is_defined
int macro_is_defined(CParseInfo *pCPI, const char *name);

#define macro_get_def CTlib_macro_get_def
char *macro_get_def(CParseInfo *pCPI, const char *name, size_t *plen);

#define macro_free_def CTlib_macro_free_def
void macro_free_def(char *p);

#define macro_iterate_defs CTlib_macro_iterate_defs
void macro_iterate_defs(CParseInfo *pCPI, void (*func)(const CMacroInfo *),
                        void *arg, CMIFlags flags);

#endif
