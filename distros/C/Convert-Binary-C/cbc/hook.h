/*******************************************************************************
*
* HEADER: hook.h
*
********************************************************************************
*
* DESCRIPTION: C::B::C hooks
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_HOOK_H
#define _CBC_HOOK_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/


/*===== DEFINES ==============================================================*/

#define SHF_ALLOW_ARG_SELF   0x00000001U
#define SHF_ALLOW_ARG_TYPE   0x00000002U
#define SHF_ALLOW_ARG_DATA   0x00000004U
#define SHF_ALLOW_ARG_HOOK   0x00000008U

#define SHF_ALLOW_ALL_ARGS   0xFFFFFFFFU


/*===== TYPEDEFS =============================================================*/

typedef enum {
  HOOK_ARG_SELF,
  HOOK_ARG_TYPE,
  HOOK_ARG_DATA,
  HOOK_ARG_HOOK
} HookArgType;

typedef struct {
  SV *sub;
  AV *arg;
} SingleHook;

#include "token/t_hookid.h"

typedef struct {
  SingleHook hooks[HOOKID_COUNT];
} TypeHooks;


/*===== FUNCTION PROTOTYPES ==================================================*/

#define single_hook_fill CBC_single_hook_fill
void single_hook_fill(pTHX_ const char *hook, const char *type, SingleHook *sth,
                            SV *sub, U32 allowed_args);

#define single_hook_new CBC_single_hook_new
SingleHook *single_hook_new(const SingleHook *h);

#define hook_new CBC_hook_new
TypeHooks *hook_new(const TypeHooks *h);

#define single_hook_update CBC_single_hook_update
void single_hook_update(SingleHook *dst, const SingleHook *src);

#define hook_update CBC_hook_update
void hook_update(TypeHooks *dst, const TypeHooks *src);

#define single_hook_delete CBC_single_hook_delete
void single_hook_delete(SingleHook *hook);

#define hook_delete CBC_hook_delete
void hook_delete(TypeHooks *h);

#define single_hook_call CBC_single_hook_call
SV *single_hook_call(pTHX_ SV *self, const char *hook_id_str, const char *id_pre,
                     const char *id, const SingleHook *hook, SV *in, int mortal);

#define hook_call CBC_hook_call
SV *hook_call(pTHX_ SV *self, const char *id_pre, const char *id,
              const TypeHooks *pTH, enum HookId hook_id, SV *in, int mortal);

#define find_hooks CBC_find_hooks
int find_hooks(pTHX_ const char *type, HV *hooks, TypeHooks *pTH);

#define get_single_hook CBC_get_single_hook
SV *get_single_hook(pTHX_ const SingleHook *hook);

#define get_hooks CBC_get_hooks
HV *get_hooks(pTHX_ const TypeHooks *pTH);

#endif
