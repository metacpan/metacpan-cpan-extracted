/*******************************************************************************
*
* HEADER: hash
*
********************************************************************************
*
* DESCRIPTION: Generic hash table routines
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
 *  \file hash.h
 *  \brief Generic implementation of Hash Tables
 */
#ifndef _UTIL_HASH_H
#define _UTIL_HASH_H

/**
 *  Maximum allowed hash size
 *
 *  This controls the maximum number of hash buckets,
 *  currently 2^16 = 65536.
 */
#define MAX_HASH_TABLE_SIZE 16

/**
 *  Compute hash sum and string length
 *
 *  The HASH_STR_LEN() macro computes the hash sum and
 *  string length of a zero terminated string.
 *
 *  \param hash         Variable that will receive the
 *                      hash sum.
 *
 *  \param str          Pointer to the zero terminated
 *                      string.
 *
 *  \param len          Variable that will receive the
 *                      string length.
 *
 *  \see HASH_STRING() and HASH_DATA()
 *  \hideinitializer
 */
#define HASH_STR_LEN( hash, str, len )         \
        do {                                   \
          register int         _len = 0;       \
          register const char *_str = str;     \
          register HashSum     _hash = 0;      \
                                               \
          while( *_str ) {                     \
            _len++;                            \
            _hash += *_str++;                  \
            _hash += (_hash << 10);            \
            _hash ^= (_hash >> 6);             \
          }                                    \
                                               \
          _hash += (_hash << 3);               \
          _hash ^= (_hash >> 11);              \
          (hash) = (_hash + (_hash << 15));    \
          (len)  = _len;                       \
        } while(0)

/**
 *  Compute hash sum
 *
 *  The HASH_STRING() macro computes the hash sum
 *  of a zero terminated string.
 *
 *  \param hash         Variable that will receive the
 *                      hash sum.
 *
 *  \param str          Pointer to the zero terminated
 *                      string.
 *
 *  \see HASH_STR_LEN() and HASH_DATA()
 *  \hideinitializer
 */
#define HASH_STRING( hash, str )               \
        do {                                   \
          register const char *_str = str;     \
          register HashSum     _hash = 0;      \
                                               \
          while( *_str ) {                     \
            _hash += *_str++;                  \
            _hash += (_hash << 10);            \
            _hash ^= (_hash >> 6);             \
          }                                    \
                                               \
          _hash += (_hash << 3);               \
          _hash ^= (_hash >> 11);              \
          (hash) = (_hash + (_hash << 15));    \
        } while(0)

/**
 *  Compute hash sum of arbitrary data
 *
 *  The HASH_DATA() macro computes the hash sum
 *  of a an arbitrary data memory block.
 *
 *  \param hash         Variable that will receive the
 *                      hash sum.
 *
 *  \param len          Length of the data block.
 *
 *  \param data         Pointer to the data block.
 *
 *  \see HASH_STR_LEN() and HASH_STRING()
 *  \hideinitializer
 */
#define HASH_DATA( hash, len, data )           \
        do {                                   \
          register const char *_data = data;   \
          register int         _len  = len;    \
          register HashSum     _hash = 0;      \
                                               \
          while( _len-- ) {                    \
            _hash += *_data++;                 \
            _hash += (_hash << 10);            \
            _hash ^= (_hash >> 6);             \
          }                                    \
                                               \
          _hash += (_hash << 3);               \
          _hash ^= (_hash >> 11);              \
          (hash) = (_hash + (_hash << 15));    \
        } while(0)

/**
 *  Hash Table Handle
 */
typedef struct _hashTable * HashTable;
typedef const struct _hashTable * ConstHashTable;

/**
 *  Hash Sum
 */
typedef unsigned long HashSum;

/**
 *  Hash Node
 */
typedef struct _hashNode *HashNode;
typedef const struct _hashNode *ConstHashNode;

struct _hashNode {
  HashNode  next;
  void     *pObj;
  HashSum   hash;
  int       keylen;
  char      key[1];
};

/**
 *  Hash Table Iterator
 */
typedef struct _hashIterator {
  ConstHashNode pNode;
  HashNode *pBucket;
  int remain;
#ifdef DEBUG_UTIL_HASH
  ConstHashTable table;
  unsigned orig_state;
#endif
} HashIterator;

/**
 *  Destructor Function Pointer
 */
typedef void (* HTDestroyFunc)(void *);

/**
 *  Cloning Function Pointer
 */
typedef void * (* HTCloneFunc)(const void *);

HashTable  HT_new_ex( int size, unsigned long flags );
void       HT_delete( HashTable table );
void       HT_flush( HashTable table, HTDestroyFunc destroy );
void       HT_destroy( HashTable table, HTDestroyFunc destroy );
HashTable  HT_clone( ConstHashTable table, HTCloneFunc func );

int        HT_resize( HashTable table, int size );
int        HT_size( ConstHashTable table );
int        HT_count( ConstHashTable table );

HashNode   HN_new( const char *key, int keylen, HashSum hash );
void       HN_delete( HashNode node );

int        HT_storenode( HashTable table, HashNode node, void *pObj );
void *     HT_fetchnode( HashTable table, HashNode node );
void *     HT_rmnode( HashTable table, HashNode node );

int        HT_store( HashTable table, const char *key, int keylen, HashSum hash, void *pObj );
void *     HT_fetch( HashTable table, const char *key, int keylen, HashSum hash );
void *     HT_get( ConstHashTable table, const char *key, int keylen, HashSum hash );
int        HT_exists( ConstHashTable table, const char *key, int keylen, HashSum hash );

void       HI_init(HashIterator *it, ConstHashTable table);
int        HI_next(HashIterator *it, const char **ppKey, int *pKeylen, void **ppObj);

/* hash table flags */
#define HT_AUTOGROW            0x00000001
#define HT_AUTOSHRINK          0x00000002
#define HT_AUTOSIZE            (HT_AUTOGROW|HT_AUTOSHRINK)

/* debug flags */
#define DB_HASH_MAIN           0x00000001

#ifdef DEBUG_UTIL_HASH
void HT_dump( ConstHashTable table );
int  SetDebugHash( void (*dbfunc)(const char *, ...), unsigned long dbflags );
#else
#define SetDebugHash( func, flags ) 0
#endif

/**
 *  Constructor
 *
 *  Using the HT_new() function you create an empty hash table.
 *
 *  \param size         Hash table base size. You can specify
 *                      any value between 1 and 16. Depending
 *                      on how many elements you plan to store
 *                      in the hash table, values from 6 to 12
 *                      can be considered useful. The number
 *                      of buckets created is 2^size, so if
 *                      you specify a size of 10, 1024 buckets
 *                      will be created and the empty hash
 *                      table will consume about 4kB of memory.
 *                      However, 1024 buckets will be enough
 *                      to very efficiently manage 100000 hash
 *                      elements.
 *
 *  \return A handle to the newly created hash table.
 *
 *  \see HT_new_ex(), HT_delete() and HT_destroy()
 */
#define HT_new( size ) HT_new_ex( size, 0 )

/**
 *  Loop over all hash elements.
 *
 *  The HT_foreach() macro is actually only a shortcut for the
 *  following loop:
 *
 *  \code
 *  for( HT_reset(table); HT_next(table, (char **)&(pKey), NULL, (void **)&(pObj)); ) {
 *    // do something with pKey and pObj
 *  }
 *  \endcode
 *
 *  It is safe to use HT_foreach() even if \a hash table handle is NULL.
 *  In that case, the loop won't be executed.
 *
 *  \param pKey         Variable that will receive a pointer
 *                      to the current hash key string.
 *
 *  \param pObj         Variable that will receive a pointer
 *                      to the current object.
 *
 *  \param iter         Pointer to hash iterator object.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \see HT_reset() and HT_next()
 *  \hideinitializer
 */
#define HT_foreach(pKey, pObj, iter, table) \
          for (HI_init(&iter, table); HI_next(&iter, &(pKey), NULL, (void **)&(pObj)); )

/**
 *  Loop over all hash keys.
 *
 *  Like HT_foreach(), just that the value parameter isn't used.
 *
 *  It is safe to use HT_foreach_keys() even if \a hash table handle is NULL.
 *  In that case, the loop won't be executed.
 *
 *  \param pKey         Variable that will receive a pointer
 *                      to the current hash key string.
 *
 *  \param iter         Pointer to hash iterator object.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \see HT_foreach() and HT_foreach_values()
 *  \hideinitializer
 */
#define HT_foreach_keys(pKey, iter, table) \
          for (HI_init(&iter, table); HI_next(&iter, &(pKey), NULL, NULL); )

/**
 *  Loop over all hash values.
 *
 *  Like HT_foreach(), just that the key parameter isn't used.
 *
 *  It is safe to use HT_foreach_values() even if \a hash table handle is NULL.
 *  In that case, the loop won't be executed.
 *
 *  \param pObj         Variable that will receive a pointer
 *                      to the current object.
 *
 *  \param iter         Pointer to hash iterator object.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \see HT_foreach() and HT_foreach_keys()
 *  \hideinitializer
 */
#define HT_foreach_values(pObj, iter, table) \
          for (HI_init(&iter, table); HI_next(&iter, NULL, NULL, (void **)&(pObj)); )

#endif
