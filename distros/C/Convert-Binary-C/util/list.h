/*******************************************************************************
*
* HEADER: list
*
********************************************************************************
*
* DESCRIPTION: Generic routines for a doubly linked ring list
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of either the Artistic License or the
* GNU General Public License as published by the Free Software
* Foundation; either version 2 of the License, or (at your option)
* any later version.
*
* THIS PROGRAM IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
* IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
* WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
*
*******************************************************************************/

/**
 *  \file list.h
 *  \brief Generic implementation of Linked Lists
 *
 *  The interface is laid out to make the linked lists look
 *  as they were arrays that can be manipulated in multiple
 *  ways. Internally, each array is represented by a doubly
 *  linked ring list, which is quite efficient for most cases.
 *  The following piece of code provides some examples of how
 *  the linked list functions can be used.
 *
 *  \include LinkedList.c
 *
 *  If you're familiar with Perl, you may notice a certain
 *  similarity between these routines and the functions
 *  Perl uses for manipulating arrays. This is absolutely
 *  intended.
 */
#ifndef _UTIL_LIST_H
#define _UTIL_LIST_H

/**
 *  Linked List Handle
 */
typedef struct _linkedList * LinkedList;
typedef const struct _linkedList * ConstLinkedList;

/**
 *  Linked List Iterator
 */
typedef struct _listIterator {
  ConstLinkedList list;
  const struct _link *cur;
#ifdef DEBUG_UTIL_LIST
  unsigned orig_state;
#endif
} ListIterator;

/**
 *  Destructor Function Pointer
 */
typedef void (* LLDestroyFunc)(void *);

/**
 *  Cloning Function Pointer
 */
typedef void * (* LLCloneFunc)(const void *);

/**
 *  Comparison Function Pointer
 */
typedef int (* LLCompareFunc)(const void *, const void *);

LinkedList   LL_new( void );
void         LL_delete( LinkedList list );
void         LL_flush( LinkedList list, LLDestroyFunc destroy );
void         LL_destroy( LinkedList list, LLDestroyFunc destroy );
LinkedList   LL_clone( ConstLinkedList list, LLCloneFunc func );

int          LL_count( ConstLinkedList list );

void         LL_push( LinkedList list, void *pObj );
void *       LL_pop( LinkedList list );

void         LL_unshift( LinkedList list, void *pObj );
void *       LL_shift( LinkedList list );

void         LL_insert( LinkedList list, int item, void *pObj );
void *       LL_extract( LinkedList list, int item );

void *       LL_get( ConstLinkedList list, int item );

LinkedList   LL_splice( LinkedList list, int offset, int length, LinkedList rlist );

void         LL_sort( LinkedList list, LLCompareFunc cmp );

void         LI_init(ListIterator *it, ConstLinkedList list);
int          LI_next(ListIterator *it);
int          LI_prev(ListIterator *it);
void *       LI_curr(const ListIterator *it);

/**
 *  Loop over all list elements.
 *
 *  The LL_foreach() macro is actually only a shortcut for the
 *  following loop:
 *
 *  \code
 *  for (LI_reset(&iter, list); LI_next(&iter) && ((pObj) = LL_curr(&iter)) != NULL;) {
 *    // do something with pObj
 *  }
 *  \endcode
 *
 *  It is safe to use LL_foreach() even if \a list is NULL.
 *  In that case, the loop won't be executed.
 *
 *  \param pObj         Variable that will receive a pointer
 *                      to the current object.
 *
 *  \param iter         Iterator state object.
 *
 *  \param list         Handle to an existing linked list.
 *
 *  \see LL_reset() and LL_next()
 *  \hideinitializer
 */
#define LL_foreach(pObj, iter, list) \
          for (LI_init(&iter, list); ((pObj) = LI_next(&iter) ? LI_curr(&iter) : NULL) != NULL;)

#endif
