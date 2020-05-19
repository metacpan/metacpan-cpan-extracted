/*******************************************************************************
*
* HEADER: idl.h
*
********************************************************************************
*
* DESCRIPTION: C::B::C identifier lists
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_IDL_H
#define _CBC_IDL_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/


/*===== DEFINES ==============================================================*/

#define IDLIST_GRANULARITY    8
#define IDLIST_INITIAL_SIZE   (2*IDLIST_GRANULARITY)

#define IDLIST_GROW(idl, size)                                                 \
        STMT_START {                                                           \
          if ((size) > (idl)->max)                                             \
          {                                                                    \
            unsigned grow = ((size)+(IDLIST_GRANULARITY-1))/IDLIST_GRANULARITY;\
            grow *= IDLIST_GRANULARITY;                                        \
            Renew((idl)->list, grow, struct IDList_list);                      \
            (idl)->max = grow;                                                 \
          }                                                                    \
        } STMT_END

#define IDLIST_INIT(idl)                                                       \
        STMT_START {                                                           \
          (idl)->count = 0;                                                    \
          (idl)->max   = IDLIST_INITIAL_SIZE;                                  \
          (idl)->cur   = NULL;                                                 \
          New(0, (idl)->list, (idl)->max, struct IDList_list);                 \
        } STMT_END

#define IDLIST_FREE(idl)                                                       \
        STMT_START {                                                           \
          if ((idl)->list)                                                     \
            Safefree((idl)->list);                                             \
        } STMT_END

#define IDLIST_PUSH(idl, what)                                                 \
        STMT_START {                                                           \
          IDLIST_GROW(idl, (idl)->count+1);                                    \
          (idl)->cur = (idl)->list + (idl)->count++;                           \
          (idl)->cur->choice = IDL_ ## what;                                   \
        } STMT_END

#define IDLIST_SET_ID(idl, value)                                              \
          (idl)->cur->val.id = value

#define IDLIST_SET_IX(idl, index)                                              \
          (idl)->cur->val.ix = index

#define IDLIST_POP(idl)                                                        \
        STMT_START {                                                           \
          assert((idl)->count > 0);                                            \
          if (--(idl)->count > 0)                                              \
            (idl)->cur--;                                                      \
          else                                                                 \
            (idl)->cur = NULL;                                                 \
        } STMT_END


/*===== TYPEDEFS =============================================================*/

typedef struct {
  unsigned count, max;
  struct IDList_list {
    enum { IDL_ID, IDL_IX } choice;
    union {
      const char *id;
      long        ix;
    } val;
  } *cur, *list;
} IDList;


/*===== FUNCTION PROTOTYPES ==================================================*/

#define idl_to_str CBC_idl_to_str
const char *idl_to_str(pTHX_ IDList *idl);

#endif
