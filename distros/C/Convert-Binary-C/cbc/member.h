/*******************************************************************************
*
* HEADER: member.h
*
********************************************************************************
*
* DESCRIPTION: C::B::C struct member utilities
*
********************************************************************************
*
* Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_MEMBER_H
#define _CBC_MEMBER_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "util/list.h"
#include "util/hash.h"
#include "ctlib/cttype.h"


/*===== DEFINES ==============================================================*/

#define CBC_GM_ACCEPT_DOTLESS_MEMBER         0x00000001U
#define CBC_GM_DONT_CROAK                    0x00000002U
#define CBC_GM_NO_OFFSET_SIZE_CALC           0x00000004U
#define CBC_GM_REJECT_OUT_OF_BOUNDS_INDEX    0x00000008U
#define CBC_GM_REJECT_OFFSET                 0x00000010U

/*===== TYPEDEFS =============================================================*/

typedef struct {
  LinkedList hit, off, pad;
  HashTable  htpad;
} GMSInfo;

typedef struct {
  TypeSpec    type;
  Struct     *parent;
  Declarator *pDecl;
  int         level;
  int         offset;
  unsigned    size;
  u_32        flags;
} MemberInfo;

struct me_walk_info
{
  enum me_walk_rv
  {
    MERV_COMPOUND_MEMBER,
    MERV_ARRAY_INDEX,
    MERV_OFFSET,
    MERV_ERR_INVALID_MEMBER_START,
    MERV_ERR_INVALID_INDEX,
    MERV_ERR_INVALID_CHAR,
    MERV_ERR_INDEX_NOT_TERMINATED,
    MERV_ERR_INCOMPLETE,
    MERV_ERR_TERMINATED,
    MERV_END
  } retval;

  union
  {
    struct {
      const char *name;
      size_t name_length;
      unsigned has_dot : 1;
    } compound_member;
    int array_index;
    int offset;
    char invalid_char;
  } u;
};

typedef struct member_expr *MemberExprWalker;


/*===== FUNCTION PROTOTYPES ==================================================*/

#define get_all_member_strings CBC_get_all_member_strings
int get_all_member_strings(pTHX_ MemberInfo *pMI, LinkedList list);

#define get_member_string CBC_get_member_string
SV *get_member_string(pTHX_ const MemberInfo *pMI, int offset, GMSInfo *pInfo);

#define get_member CBC_get_member
int get_member(pTHX_ const MemberInfo *pMI, const char *member,
               MemberInfo *pMIout, unsigned gm_flags);

#define member_expr_walker_new CBC_member_expr_walker_new
MemberExprWalker member_expr_walker_new(pTHX_ const char *expr, size_t len);

#define member_expr_walker_retval_string CBC_member_expr_walker_retval_string
const char *member_expr_walker_retval_string(enum me_walk_rv retval);

#define member_expr_walker_walk CBC_member_expr_walker_walk
void member_expr_walker_walk(pTHX_ MemberExprWalker me, struct me_walk_info *info);

#define member_expr_walker_delete CBC_member_expr_walker_delete
void member_expr_walker_delete(pTHX_ MemberExprWalker me);

#endif
