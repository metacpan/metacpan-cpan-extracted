/*******************************************************************************
*
* MODULE: hash
*
********************************************************************************
*
* DESCRIPTION: Generic hash table routines
*
********************************************************************************
*
* Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>

#include "ccattr.h"
#include "memalloc.h"
#include "hash.h"

/*----------*/
/* Typedefs */
/*----------*/
struct _hashTable {
  int               count;
  int               size;
#ifdef DEBUG_UTIL_HASH
  unsigned          state;
#endif
  unsigned long     flags;
  unsigned long     bmask;
  HashNode         *root;
};

#ifdef DEBUG_UTIL_HASH

# ifdef UTIL_FORMAT_CHECK

#  define DEBUG( flag, out ) debug_check out

static void debug_check(const char *str, ...)
            __attribute__(( __format__( __printf__, 1, 2 ), __noreturn__ ));

# else

#  define DEBUG( flag, out )                                       \
            do {                                                   \
              if( gs_dbfunc && ((DB_HASH_ ## flag) & gs_dbflags) ) \
                gs_dbfunc out ;                                    \
            } while(0)

# endif

static void (*gs_dbfunc)(const char *, ...) = NULL;
static unsigned long gs_dbflags             = 0;

#define CHANGE_STATE(table)   (table)->state++

#else /* !DEBUG_UTIL_HASH */

#define DEBUG( flag, out )    (void) 0

#define CHANGE_STATE(table)   (void) 0

#endif /* DEBUG_UTIL_HASH */

/* size of fixed part of hash node */
#define HN_SIZE_FIX offsetof( struct _hashNode, key )

/* compare hash values / compute a minimum of two values */
#define CMPHASH( a, b ) ((a) == (b) ? 0 : ((a) < (b) ? -1 : 1))
#define MINIMUM( a, b ) ((a) <= (b) ? a : b)

#define ENTRY_FOUND( h, k, l, n )                                              \
        (   (cmp = CMPHASH(h, (n)->hash)) == 0                                 \
         && (cmp = l - (n)->keylen) == 0                                       \
         && (cmp = memcmp( (const void *) k, (n)->key,                         \
                           MINIMUM(l, (n)->keylen) )) == 0 )

#define ENTRY_FOUND_HKL( n ) \
          ENTRY_FOUND( hash, key, keylen, n )

#define ENTRY_FOUND_NODE( n ) \
          ENTRY_FOUND( (node)->hash, (node)->key, (node)->keylen, n )

#if defined DEBUG_UTIL_HASH && defined NO_TERMINATED_KEYS
#undef NO_TERMINATED_KEYS
#endif

/* normally, one extra byte is allocated per hash key
   to terminate the key with a zero byte              */
#ifdef NO_TERMINATED_KEYS
#define TERMINATOR_LENGTH 0
#else
#define TERMINATOR_LENGTH 1
#endif

#define AUTOSIZE_DYADES    3
#define AUTOGROW_DYADES    AUTOSIZE_DYADES
#define AUTOSHRINK_DYADES  AUTOSIZE_DYADES

/* macro for automatically growing the hash table */
#define CHECK_AUTOGROW( table )                                        \
        do {                                                           \
          if( table->flags & HT_AUTOGROW )                             \
            if( table->size < MAX_HASH_TABLE_SIZE &&                   \
                table->count >> (table->size+AUTOGROW_DYADES) > 0 )    \
              ht_grow( table, table->size+1 );                         \
        } while(0)

#define CHECK_AUTOSHRINK( table )                                      \
        do {                                                           \
          if( table->flags & HT_AUTOSHRINK )                           \
            if( table->size > 1 &&                                     \
                table->count >> (table->size-AUTOSHRINK_DYADES) == 0 ) \
              ht_shrink( table, table->size-1 );                       \
        } while(0)

/* static functions */

#if defined(DEBUG_UTIL_HASH) && defined(UTIL_FORMAT_CHECK)
static void debug_check(const char *str __attribute__(( __unused__ )), ...)
{
  fprintf( stderr, "compiled with UTIL_FORMAT_CHECK, please don't run\n" );
  abort();
}
#endif

static inline void ht_grow( HashTable table, int size )
{
  HashNode *pNode, *pOld, *pNew;
  int old_size, buckets;
  unsigned long mask;

  old_size = table->size;
  buckets  = 1<<size;

  /* grow hash table */
  ReAllocF( HashNode *, table->root, buckets * sizeof( HashNode ) );
  table->size  = size;
  table->bmask = (unsigned long) (buckets-1);

  /* initialize new buckets */
  pNode    = &table->root[1<<old_size];
  buckets -= 1<<old_size;
  while( buckets-- )
    *pNode++ = NULL;

  /* distribute hash elements */
  mask    = ((1 << (size-old_size)) - 1) << old_size;
  pNode   = &table->root[0];
  buckets = 1<<old_size;

  while( buckets-- ) {
    DEBUG( MAIN, ("growing, buckets to go: %d\n", buckets+1) );

    pOld = pNode++;

    while( *pOld ) {
      if( (*pOld)->hash & mask ) {
        DEBUG( MAIN, ("pOld=%p *pOld=%p (key=[%s] len=%d hash=0x%08lX)\n",
                     pOld, *pOld, (*pOld)->key, (*pOld)->keylen, (*pOld)->hash) );

        pNew = &table->root[(*pOld)->hash & table->bmask];
        while( *pNew )
          pNew = &(*pNew)->next;

        *pNew = *pOld;
        *pOld = (*pNew)->next;
        (*pNew)->next = NULL;
      }
      else
        pOld = &(*pOld)->next;
    }
  }

  DEBUG( MAIN, ("hash table @ %p grown to %d buckets\n", table, 1<<size) );
}

static inline void ht_shrink( HashTable table, int size )
{
  HashNode *pNode, *pNew, old, node;
  int old_size, buckets, cmp;

  old_size     = table->size;
  buckets      = 1<<size;
  table->size  = size;
  table->bmask = (unsigned long) (buckets-1);

  /* distribute hash elements */
  pNode    = &table->root[buckets];
  buckets  = (1<<old_size) - buckets;

  while( buckets-- ) {
    DEBUG( MAIN, ("shrinking, buckets to go: %d\n", buckets+1) );

    old = *pNode++;

    while( old ) {
      DEBUG( MAIN, ("old=%p (key=[%s] len=%d hash=0x%08lX)\n",
                   old, old->key, old->keylen, old->hash) );
      node = old;
      old  = old->next;
      pNew = &table->root[node->hash & table->bmask];

      while( *pNew ) {
        DEBUG( MAIN, ("pNew=%p *pNew=%p (key=[%s] len=%d hash=0x%08lX)\n",
                     pNew, *pNew, (*pNew)->key, (*pNew)->keylen, (*pNew)->hash) );

        (void) ENTRY_FOUND_NODE( *pNew );

        DEBUG( MAIN, ("cmp: %d\n", cmp) );

        if( cmp < 0 ) {
          DEBUG( MAIN, ("postition to insert new element found\n") );
          break;
        }

        DEBUG( MAIN, ("advancing to next hash element\n") );
        pNew = &(*pNew)->next;
      }

      node->next = *pNew;
      *pNew      = node;
    }
  }

  /* shrink hash table */
  buckets = 1<<size;
  ReAllocF( HashNode *, table->root, buckets * sizeof( HashNode ) );

  DEBUG( MAIN, ("hash table @ %p shrunk to %d buckets\n", table, buckets) );
}

/************************************************************
*
*  G L O B A L   F U N C T I O N S
*
************************************************************/

/**
 *  Extended Constructor
 *
 *  Using the HT_new_ex() function you create an empty hash
 *  table and set its flags.
 *
 *  \param size         Hash table base size.
 *
 *  \param flags        Hash table flags. Currently you can
 *                      use these flags only to specify the
 *                      hash tables autosize behaviour. Use
 *                      HT_AUTOGROW if you want the hash table
 *                      to grow automatically, HT_AUTOSHRINK
 *                      if you want the hash table to shrink
 *                      automatically. If you want both, just
 *                      do a binary OR combination of the
 *                      flags or use HT_AUTOSIZE.
 *
 *  \return A handle to the newly created hash table.
 *
 *  \see HT_new()
 */

HashTable HT_new_ex( int size, unsigned long flags )
{
  HashTable table;
  HashNode *pNode;
  int buckets;

  DEBUG( MAIN, ("HT_new( %d )\n", size) );

  assert( size > 0 );
  assert( size <= MAX_HASH_TABLE_SIZE );

  if( size <= 0 || size > MAX_HASH_TABLE_SIZE )
    return NULL;

  buckets = 1<<size;

  AllocF( HashTable, table, sizeof( struct _hashTable ) );
  AllocF( HashNode *, table->root, buckets * sizeof( HashNode ) );

  table->count = 0;
  table->size  = size;
  table->bmask = (unsigned long) (buckets-1);
  table->flags = flags;

#ifdef DEBUG_UTIL_HASH
  table->state = 0;
#endif

  DEBUG( MAIN, ("created new hash table @ %p with %d buckets\n", table, buckets) );

  pNode = &table->root[0];
  while( buckets-- )
    *pNode++ = NULL;

  return table;
}

/**
 *  Destructor
 *
 *  HT_delete() will free the resources occupied by a
 *  hash table. The function will fail silently if the
 *  associated hash table is not empty.
 *  You can also delete a hash table that is not empty by
 *  using the HT_destroy() function.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \see HT_new() and HT_destroy()
 */

void HT_delete( HashTable table )
{
  DEBUG( MAIN, ("HT_delete( %p )\n", table) );

  if( table == NULL )
    return;

  AssertValidPtr( table );
  AssertValidPtr( table->root );

  CHANGE_STATE(table);

  assert( table->count == 0 );

  Free( table->root );
  Free( table );

  DEBUG( MAIN, ("deleted hash table @ %p\n", table) );
}

/**
 *  Remove all entries from a hash table
 *
 *  HT_flush() will remove all entries from a hash table,
 *  optionally calling a destructor function for each object
 *  stored in it. It will not free the resources occupied
 *  by the hash table itself, so the hash table handle will
 *  still be valid.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \param destroy      Pointer to the destructor function
 *                      of the objects contained in the hash
 *                      table.
 *                      You can pass NULL if you don't want
 *                      HT_destroy() to call object destructors.
 *
 *  \see HT_destroy()
 */

void HT_flush( HashTable table, HTDestroyFunc destroy )
{
  int buckets;
  HashNode *pNode, node, old;

  DEBUG( MAIN, ("HT_flush( %p, %p )\n", table, destroy) );

  if( table == NULL || table->count == 0 )
    return;

  AssertValidPtr( table );
  AssertValidPtr( table->root );

  CHANGE_STATE(table);

  buckets = 1 << table->size;

  pNode = &table->root[0];

  while( buckets-- ) {
    node = *pNode;
    *pNode++ = NULL;

    while( node ) {
      if( destroy )
        destroy( node->pObj );

      old  = node;
      node = node->next;
      Free( old );
    }
  }

  table->count = 0;

  DEBUG( MAIN, ("flushed hash table @ %p\n", table) );
}

/**
 *  Extended Destructor
 *
 *  HT_destroy() will, like HT_delete(), free the resources
 *  occupied by a hash table. In addition, it will call a
 *  destructor function for each element, allowing to free
 *  the resources of the objects stored in the hash table.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \param destroy      Pointer to the destructor function
 *                      of the objects contained in the hash
 *                      table.
 *                      You can pass NULL if you don't want
 *                      HT_destroy() to call object destructors.
 *
 *  \see HT_new() and HT_delete()
 */

void HT_destroy( HashTable table, HTDestroyFunc destroy )
{
  DEBUG( MAIN, ("HT_destroy( %p )\n", table) );

  if( table == NULL )
    return;

  AssertValidPtr( table );
  AssertValidPtr( table->root );

  CHANGE_STATE(table);

  HT_flush( table, destroy );

  Free( table->root );
  Free( table );

  DEBUG( MAIN, ("destroyed hash table @ %p\n", table) );
}

/**
 *  Cloning a hash table
 *
 *  Using the HT_clone() function to create an exact copy
 *  of a hash table. If the objects stored in the table
 *  need to be cloned as well, you can pass a pointer to
 *  a function that clones each element.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \param func         Pointer to the cloning function of
 *                      the objects contained in the table.
 *                      If you pass NULL, the original
 *                      object is stored in the cloned table
 *                      instead of a cloned object.
 *
 *  \return A handle to the cloned hash table.
 *
 *  \see HT_new()
 */

HashTable HT_clone( ConstHashTable table, HTCloneFunc func )
{
  HashTable clone;
  HashNode *pSrcNode, *pDstNode, node, *pNode, cnode;
  int       buckets;

  if( table == NULL )
    return NULL;

  clone = HT_new_ex( table->size, table->flags );

  if( table->count > 0 ) {
    buckets  = 1<<table->size;
    pSrcNode = &table->root[0];
    pDstNode = &clone->root[0];

    while( buckets-- > 0 ) {
      node = *pSrcNode++;
      pNode = pDstNode++;

      while( node ) {
        AllocF( HashNode, cnode, HN_SIZE_FIX + node->keylen + TERMINATOR_LENGTH );

        cnode->next   = *pNode;
        cnode->pObj   = func ? func( node->pObj ) : node->pObj;
        cnode->hash   = node->hash;
        cnode->keylen = node->keylen;
        memcpy( cnode->key, (void *) node->key, node->keylen );
#ifndef NO_TERMINATED_KEYS
        cnode->key[cnode->keylen] = '\0';
#endif

        *pNode = cnode;

        pNode = &(*pNode)->next;
        node = node->next;
      }
    }

    clone->count = table->count;
  }

  return clone;
}

/**
 *  Resize a hash table
 *
 *  HT_resize() will allow to resize (shrink or grow) an
 *  existing hash table.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \param size         New size for the hash table.
 *                      This argument is the same as the
 *                      argument passed to HT_new().
 *
 *  \return Nonzero on success, zero if an invalid handle
 *          was passed or if the table wasn't resized.
 *
 *  \see HT_new() and HT_size()
 */

int HT_resize( HashTable table, int size )
{
  DEBUG( MAIN, ("HT_resize( %p, %d )\n", table, size) );

  assert( size > 0 );
  assert( size <= MAX_HASH_TABLE_SIZE );

  if( table == NULL || size <= 0 || size > MAX_HASH_TABLE_SIZE )
    return 0;

  AssertValidPtr( table );

  if( size == table->size )
    return 0;

  CHANGE_STATE(table);

  if( size > table->size )
    ht_grow( table, size );
  else
    ht_shrink( table, size );

  return 1;
}

#ifdef DEBUG_UTIL_HASH

/**
 *  Dump the contents of a hash table
 *
 *  HT_dump() will verbosely list all information related
 *  to a hash table. It will list the contents of all hash
 *  buckets and print all keys, hash sums and value pointers.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \note HT_dump() is only available if the code was compiled
 *        with the \c DEBUG_UTIL_HASH preprocessor flag.
 */

void HT_dump( ConstHashTable table )
{
  int i, j, buckets;
  HashNode *pNode, node;

  DEBUG( MAIN, ("HT_dump( %p )\n", table) );

  assert( table != NULL );
  AssertValidPtr( table );

  if( gs_dbfunc == NULL )
    return;

  gs_dbfunc( "----------------------------------------------------\n" );
  gs_dbfunc( "HashTable @ %p: %d elements in %d buckets (state=%u)\n",
             table, table->count, 1<<table->size, table->state );

  buckets = 1<<table->size;
  pNode = &table->root[0];

  for( i=0; i<buckets; ++i ) {
    gs_dbfunc( "\n  Bucket %d @ %p:%s\n", i+1, pNode,
               *pNode ? "" : " no elements" );

    node = *pNode++;

    for( j = 1; node != NULL; j++, node = node->next )
      gs_dbfunc( "\n    Element %d @ %p:\n"
                 "      Hash : 0x%08lX\n"
                 "      Key  : [%s] (len=%d)\n"
                 "      Value: %p\n",
                 j, node, node->hash, node->key, node->keylen, node->pObj );
  }

  gs_dbfunc( "----------------------------------------------------\n" );
}
#endif

/**
 *  Size of a hash table
 *
 *  HT_size() will return the size of the hash table.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \return The size of the table or -1 if an invalid handle
 *          was passed. The value is the same as the argument
 *          given to the HT_new() constructor.
 *
 *  \see HT_new()
 */

int HT_size( ConstHashTable table )
{
  if( table == NULL )
    return -1;

  AssertValidPtr( table );

  return table->size;
}

/**
 *  Current element count of a hash table
 *
 *  HT_count() will return the number of objects currently
 *  stored in a hash table.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \return The number of elements stored in the hash table
 *          or -1 if an invalid handle was passed.
 */

int HT_count( ConstHashTable table )
{
  if( table == NULL )
    return -1;

  AssertValidPtr( table );

  return table->count;
}

/**
 *  Pre-create a hash node
 *
 *  A hash node is the data structure that is stored in a
 *  hash table. You can pre-create a hash node using the
 *  HN_new() function. A pre-created hash node holds
 *  the hash key, but no value. The advantage of such a
 *  pre-created hash node is that no additional resources
 *  need to be allocated if you store the hash node in the
 *  hash table.
 *
 *  \param key          Pointer to the hash key.
 *
 *  \param keylen       Length of the hash key in bytes.
 *                      May be zero if \p key is a zero
 *                      terminated string.
 *
 *  \param hash         Pre-computed hash sum. If this is
 *                      zero, the hash sum is computed.
 *
 *  \return A handle to the new hash node.
 *
 *  \see HN_delete(), HT_storenode() and HT_fetchnode()
 */

HashNode HN_new( const char *key, int keylen, HashSum hash )
{
  HashNode node;

  DEBUG( MAIN, ("HN_new( %p, %d, 0x%08lX )\n", key, keylen, hash) );

  assert( key != NULL );

  if( hash == 0 ) {
    if( keylen )
      HASH_DATA( hash, keylen, key );
    else
      HASH_STR_LEN( hash, key, keylen );
  }

  AllocF( HashNode, node, HN_SIZE_FIX + keylen + TERMINATOR_LENGTH );

  node->pObj   = NULL;
  node->next   = NULL;
  node->hash   = hash;
  node->keylen = keylen;
  memcpy( node->key, (const void *) key, keylen );
#ifndef NO_TERMINATED_KEYS
  node->key[keylen] = '\0';
#endif

  DEBUG( MAIN, ("created new hash node @ %p with key \"%s\"\n", node, key) );

  return node;
}

/**
 *  Delete a hash node
 *
 *  Free the resources occupied by a hash node that
 *  was previously allocated using the HN_new() function.
 *  You cannot free the resources of a hash node that
 *  is still embedded in a hash table.
 *
 *  \param node         Handle to an existing hash node.
 *
 *  \see HN_new()
 */

void HN_delete( HashNode node )
{
  DEBUG( MAIN, ("HN_delete( %p )\n", node) );

  if( node == NULL )
    return;

  AssertValidPtr( node );
  assert( node->pObj == NULL );

  Free( node );

  DEBUG( MAIN, ("deleted hash node @ %p\n", node) );
}

/**
 *  Store a hash node in a hash table
 *
 *  Use this function to store a previously created hash
 *  node in an existing hash table.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \param node         Handle to an existing hash node.
 *
 *  \param pObj         Pointer to an object that will be
 *                      stored as a hash value.
 *
 *  \return Nonzero if the node could be stored, zero
 *          if it couldn't be stored.
 *
 *  \see HN_new and HT_fetchnode()
 */

int HT_storenode( HashTable table, HashNode node, void *pObj )
{
  HashNode *pNode;
  int cmp;

  DEBUG( MAIN, ("HT_storenode( %p, %p, %p )\n", table, node, pObj) );

  assert( table != NULL );
  assert( node  != NULL );

  AssertValidPtr( table );
  AssertValidPtr( node );

  CHANGE_STATE(table);

  CHECK_AUTOGROW( table );

  pNode = &table->root[node->hash & table->bmask];

  DEBUG( MAIN, ("key=[%s] len=%d hash=0x%08lX bucket=%lu/%d\n",
                node->key, node->keylen, node->hash,
                (node->hash & table->bmask) + 1U, 1<<table->size) );

  while( *pNode ) {
    DEBUG( MAIN, ("pNode=%p *pNode=%p (key=[%s] len=%d hash=0x%08lX)\n",
                 pNode, *pNode, (*pNode)->key, (*pNode)->keylen, (*pNode)->hash) );

    if( ENTRY_FOUND_NODE( *pNode ) ) {
      DEBUG( MAIN, ("key [%s] already in hash, can't store\n", node->key) );
      return 0;
    }

    DEBUG( MAIN, ("cmp: %d\n", cmp) );

    if( cmp < 0 ) {
      DEBUG( MAIN, ("postition to insert new element found\n") );
      break;
    }

    DEBUG( MAIN, ("advancing to next hash element\n") );
    pNode = &(*pNode)->next;
  }

  node->pObj = pObj;
  node->next = *pNode;
  *pNode     = node;

  DEBUG( MAIN, ("successfully stored node [%s] as element #%d into hash table\n",
                node->key, table->count+1) );

  return ++table->count;
}

/**
 *  Fetch a hash node from a hash table
 *
 *  Use this function to fetch a hash node from an
 *  existing hash table. The hash node will be removed
 *  from the hash table. However, the resources for the
 *  hash node will not be freed. The hash node can be
 *  stored in another hash table.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \param node         Handle to an existing hash node.
 *
 *  \return Pointer to the object that was stored as hash
 *          value with the hash node.
 *
 *  \see HN_delete() and HT_storenode()
 */

void *HT_fetchnode( HashTable table, HashNode node )
{
  HashNode *pNode;
  void *pObj;

  DEBUG( MAIN, ("HT_fetchnode( %p, %p )\n", table, node) );

  assert( table != NULL );
  assert( node  != NULL );

  AssertValidPtr( table );
  AssertValidPtr( node );

  CHANGE_STATE(table);

  pNode = &table->root[node->hash & table->bmask];

  DEBUG( MAIN, ("key [%s] hash 0x%08lX bucket %lu/%d\n",
                node->key, node->hash, (node->hash & table->bmask) + 1U, 1<<table->size) );

  while( *pNode && *pNode != node )
    pNode = &(*pNode)->next;

  if( *pNode == NULL ) {
    DEBUG( MAIN, ("hash element not found\n") );
    return NULL;
  }

  pObj   = node->pObj;
  *pNode = node->next;

  node->pObj = NULL;
  node->next = NULL;

  table->count--;

  DEBUG( MAIN, ("successfully fetched node @ %p (%d nodes still in hash table)\n",
                node, table->count) );

  CHECK_AUTOSHRINK( table );

  return pObj;
}

/**
 *  Remove a hash node from a hash table
 *
 *  Use this function to remove a hash node from an
 *  existing hash table. The hash node will be removed
 *  from the hash table and the resources for the
 *  hash node will be freed. This is like calling
 *  HT_fetchnode() and deleting the node with HN_delete().
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \param node         Handle to an existing hash node.
 *
 *  \return Pointer to the object that was stored as hash
 *          value with the hash node.
 *
 *  \see HN_delete() and HT_fetchnode()
 */

void *HT_rmnode( HashTable table, HashNode node )
{
  HashNode *pNode;
  void *pObj;

  DEBUG( MAIN, ("HT_rmnode( %p, %p )\n", table, node) );

  assert( table != NULL );
  assert( node  != NULL );

  AssertValidPtr( table );
  AssertValidPtr( node );

  CHANGE_STATE(table);

  pNode = &table->root[node->hash & table->bmask];

  DEBUG( MAIN, ("key [%s] hash 0x%08lX bucket %lu/%d\n",
         node->key, node->hash, (node->hash & table->bmask) + 1U, 1<<table->size) );

  while( *pNode && *pNode != node )
    pNode = &(*pNode)->next;

  if( *pNode == NULL ) {
    DEBUG( MAIN, ("hash element not found\n") );
    return NULL;
  }

  pObj   = node->pObj;
  *pNode = node->next;

  Free( node );

  table->count--;

  DEBUG( MAIN, ("successfully removed node @ %p (%d nodes still in hash table)\n",
                node, table->count) );

  CHECK_AUTOSHRINK( table );

  return pObj;
}

/**
 *  Store a new key/value pair in a hash table
 *
 *  Use this function to store a new key/value pair
 *  in an existing hash table.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \param key          Pointer to the hash key.
 *
 *  \param keylen       Length of the hash key in bytes.
 *                      May be zero if \p key is a zero
 *                      terminated string.
 *
 *  \param hash         Pre-computed hash sum. If this is
 *                      zero, the hash sum is computed.
 *
 *  \param pObj         Pointer to an object that will be
 *                      stored as a hash value.
 *
 *  \return Nonzero if the node could be stored, zero
 *          if it couldn't be stored.
 *
 *  \see HT_fetch() and HT_get()
 */

int HT_store( HashTable table, const char *key, int keylen, HashSum hash, void *pObj )
{
  HashNode *pNode, node;
  int cmp;

  DEBUG( MAIN, ("HT_store( %p, %p, %d, 0x%08lX, %p )\n",
                table, key, keylen, hash, pObj) );

  assert( table != NULL );
  assert( key   != NULL );

  AssertValidPtr( table );

  CHANGE_STATE(table);

  if( hash == 0 ) {
    if( keylen )
      HASH_DATA( hash, keylen, key );
    else
      HASH_STR_LEN( hash, key, keylen );
  }

  CHECK_AUTOGROW( table );

  pNode = &table->root[hash & table->bmask];

  DEBUG( MAIN, ("key=[%s] len=%d hash=0x%08lX bucket=%lu/%d\n",
                key, keylen, hash, (hash & table->bmask) + 1U, 1<<table->size) );

  while( *pNode ) {
    DEBUG( MAIN, ("pNode=%p *pNode=%p (key=[%s] len=%d hash=0x%08lX)\n",
                  pNode, *pNode, (*pNode)->key, (*pNode)->keylen, (*pNode)->hash) );

    if( ENTRY_FOUND_HKL( *pNode ) ) {
      DEBUG( MAIN, ("key [%s] already in hash, can't store\n", key) );
      return 0;
    }

    DEBUG( MAIN, ("cmp: %d\n", cmp) );

    if( cmp < 0 ) {
      DEBUG( MAIN, ("postition to insert new element found\n") );
      break;
    }

    DEBUG( MAIN, ("advancing to next hash element\n") );
    pNode = &(*pNode)->next;
  }

  AllocF( HashNode, node, HN_SIZE_FIX + keylen + TERMINATOR_LENGTH );

  node->next   = *pNode;
  node->pObj   = pObj;
  node->hash   = hash;
  node->keylen = keylen;
  memcpy( node->key, (const void *) key, keylen );
#ifndef NO_TERMINATED_KEYS
  node->key[keylen] = '\0';
#endif

  *pNode = node;

  DEBUG( MAIN, ("successfully stored [%s] as element #%d into hash table\n",
                key, table->count+1) );

  return ++table->count;
}

/**
 *  Fetch a value from a hash table
 *
 *  Use this function to fetch a hash value from an
 *  existing hash table. The key/value pair will be
 *  removed from the hash table. The resources occupied
 *  by the hash node used to store the key/value pair
 *  will be freed.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \param key          Pointer to a hash key.
 *
 *  \param keylen       Length of the hash key in bytes.
 *                      May be zero if \p key is a zero
 *                      terminated string.
 *
 *  \param hash         Pre-computed hash sum. If this is
 *                      zero, the hash sum is computed.
 *
 *  \return Pointer to the object that was stored as hash
 *          value. NULL if the key doesn't exist.
 *
 *  \see HT_get() and HT_store()
 */

void *HT_fetch( HashTable table, const char *key, int keylen, HashSum hash )
{
  HashNode *pNode, node;
  int   cmp;
  void *pObj;

  DEBUG( MAIN, ("HT_fetch( %p, %p, %d, 0x%08lX )\n", table, key, keylen, hash) );

  assert( table != NULL );
  assert( key   != NULL );

  AssertValidPtr( table );

  CHANGE_STATE(table);

  if( table->count == 0 )
    return NULL;

  if( hash == 0 ) {
    if( keylen )
      HASH_DATA( hash, keylen, key );
    else
      HASH_STR_LEN( hash, key, keylen );
  }

  pNode = &table->root[hash & table->bmask];

  DEBUG( MAIN, ("key [%s] hash 0x%08lX bucket %lu/%d\n",
                key, hash, (hash & table->bmask) + 1U, 1<<table->size) );

  while( *pNode ) {
    DEBUG( MAIN, ("node=%p (key=[%s] len=%d hash=0x%08lX)\n",
                  *pNode, (*pNode)->key, (*pNode)->keylen, (*pNode)->hash) );

    if( ENTRY_FOUND_HKL( *pNode ) ) {
      DEBUG( MAIN, ("hash element found\n") );
      break;
    }

    DEBUG( MAIN, ("cmp: %d\n", cmp) );

    if( cmp < 0 ) {
      DEBUG( MAIN, ("cannot find hash element\n") );
      return NULL;
    }

    DEBUG( MAIN, ("advancing to next hash element\n") );
    pNode = &(*pNode)->next;
  }

  if( *pNode == NULL ) {
    DEBUG( MAIN, ("hash element not found\n") );
    return NULL;
  }

  pObj = (*pNode)->pObj;

  node   = *pNode;
  *pNode = node->next;
  Free( node );

  table->count--;

  DEBUG( MAIN, ("successfully fetched [%s] (%d elements still in hash table)\n", key, table->count) );

  CHECK_AUTOSHRINK( table );

  return pObj;
}

/**
 *  Get a value from a hash table
 *
 *  Use this function to get a hash value from an
 *  existing hash table. The key/value pair will not be
 *  removed from the hash table.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \param key          Pointer to a hash key.
 *
 *  \param keylen       Length of the hash key in bytes.
 *                      May be zero if \p key is a zero
 *                      terminated string.
 *
 *  \param hash         Pre-computed hash sum. If this is
 *                      zero, the hash sum is computed.
 *
 *  \return Pointer to the object that is stored as hash
 *          value. NULL if the key doesn't exist.
 *
 *  \see HT_fetch() and HT_store()
 */

void *HT_get( ConstHashTable table, const char *key, int keylen, HashSum hash )
{
  HashNode node;
  int cmp;

  DEBUG( MAIN, ("HT_get( %p, %p, %d, 0x%08lX )\n", table, key, keylen, hash) );

  assert( table != NULL );
  assert( key   != NULL );

  AssertValidPtr( table );

  if( table->count == 0 )
    return NULL;

  if( hash == 0 ) {
    if( keylen )
      HASH_DATA( hash, keylen, key );
    else
      HASH_STR_LEN( hash, key, keylen );
  }

  node = table->root[hash & table->bmask];

  DEBUG( MAIN, ("key [%s] hash 0x%08lX bucket %lu/%d\n",
                key, hash, (hash & table->bmask) + 1U, 1<<table->size) );

  while( node ) {
    DEBUG( MAIN, ("node=%p (key=[%s] len=%d hash=0x%08lX)\n",
                  node, node->key, node->keylen, node->hash) );

    if( ENTRY_FOUND_HKL( node ) ) {
      DEBUG( MAIN, ("hash element found\n") );
      break;
    }

    DEBUG( MAIN, ("cmp: %d\n", cmp) );

    if( cmp < 0 ) {
      DEBUG( MAIN, ("cannot find hash element\n") );
      return NULL;
    }

    DEBUG( MAIN, ("advancing to next hash element\n") );
    node = node->next;
  }

#ifdef DEBUG_UTIL_HASH
  if( node == NULL )
    DEBUG( MAIN, ("hash element not found\n") );
  else
    DEBUG( MAIN, ("successfully found [%s] in hash table\n", node->key) );
#endif

  return node ? node->pObj : NULL;
}

/**
 *  Check if a key exists in a hash table
 *
 *  Use this function to check if a key is present in an
 *  existing hash table.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \param key          Pointer to a hash key.
 *
 *  \param keylen       Length of the hash key in bytes.
 *                      May be zero if \p key is a zero
 *                      terminated string.
 *
 *  \param hash         Pre-computed hash sum. If this is
 *                      zero, the hash sum is computed.
 *
 *  \return Nonzero if the key exists, zero if it doesn't.
 *
 *  \see HT_get() and HT_fetch()
 */

int HT_exists( ConstHashTable table, const char *key, int keylen, HashSum hash )
{
  HashNode node;
  int cmp;

  DEBUG( MAIN, ("HT_exists( %p, %p, %d, 0x%08lX )\n", table, key, keylen, hash) );

  assert( table != NULL );
  assert( key   != NULL );

  AssertValidPtr( table );

  if( table->count == 0 )
    return 0;

  if( hash == 0 ) {
    if( keylen )
      HASH_DATA( hash, keylen, key );
    else
      HASH_STR_LEN( hash, key, keylen );
  }

  node = table->root[hash & table->bmask];

  DEBUG( MAIN, ("key [%s] hash 0x%08lX bucket %lu/%d\n",
                key, hash, (hash & table->bmask) + 1U, 1<<table->size) );

  while( node ) {
    DEBUG( MAIN, ("node=%p (key=[%s] len=%d hash=0x%08lX)\n",
                  node, node->key, node->keylen, node->hash) );

    if( ENTRY_FOUND_HKL( node ) ) {
      DEBUG( MAIN, ("hash element found\n") );
      return 1;
    }

    DEBUG( MAIN, ("cmp: %d\n", cmp) );

    if( cmp < 0 ) {
      DEBUG( MAIN, ("cannot find hash element\n") );
      return 0;
    }

    DEBUG( MAIN, ("advancing to next hash element\n") );
    node = node->next;
  }

  return 0;
}

/**
 *  Initialize hash iterator object
 *
 *  HI_init() will initialize a hash iterator object.
 *  You must call this function prior to using HI_next().
 *
 *  \param it           Pointer to a hash iterator object.
 *
 *  \param table        Handle to an existing hash table.
 *
 *  \see HI_next()
 */

void HI_init(HashIterator *it, ConstHashTable table)
{
  DEBUG( MAIN, ("HI_init( %p, %p )\n", it, table) );

#ifdef DEBUG_UTIL_HASH
  it->table = table;
  it->orig_state = table->state;
#endif

  if (table)
  {
    AssertValidPtr(table);

    it->remain  = 1 << table->size;
    it->pBucket = &table->root[1];
    it->pNode   = table->root[0];

    DEBUG( MAIN, ("hash table iterator has been reset\n") );
  }
}

/**
 *  Get next hash element
 *
 *  Get the next key/value pair while iterating through a
 *  hash table. You must have called HI_init() before and
 *  you mustn't modify the hash table between consecutive
 *  calls to HI_next().
 *
 *  \param it           Pointer to a hash iterator object.
 *
 *  \param ppKey        Pointer to a variable that will
 *                      receive a pointer to the hash key.
 *                      May be \c NULL if you don't need
 *                      it. You mustn't modify the memory
 *                      pointed to by that pointer.
 *
 *  \param pKeylen      Pointer to a variable that will
 *                      receive the length of the hash key.
 *                      May be \c NULL if you don't need
 *                      it.
 *
 *  \param ppObj        Pointer to a variable that will
 *                      receive a pointer to the object
 *                      that is stored as hash value.
 *                      May be \c NULL if you don't need
 *                      it.
 *
 *  \return Nonzero if another key/value pair could be
 *          retrieved, zero if all elements have been
 *          processed.
 *
 *  \see HI_init()
 */

int HI_next(HashIterator *it, const char **ppKey, int *pKeylen, void **ppObj)
{
  ConstHashNode node;

  DEBUG( MAIN, ("HI_next( %p )\n", it) );

  if (it == NULL)
    return 0;

#ifdef DEBUG_UTIL_HASH
  AssertValidPtr(it->table);

  assert(it->orig_state == it->table->state);
#endif

  DEBUG( MAIN, ("it->remain=%d it->pBucket=%p it->pNode=%p\n",
                it->remain, it->pBucket, it->pNode) );

  while (it->remain > 0)
  {
    while ((node = it->pNode) != NULL)
    {
      it->pNode = it->pNode->next;
      if (ppKey  ) *ppKey   = node->key;
      if (pKeylen) *pKeylen = node->keylen;
      if (ppObj  ) *ppObj   = node->pObj;
      return 1;
    }
    DEBUG( MAIN, ("going to next bucket\n") );

    if (--it->remain > 0)
      it->pNode = *it->pBucket++;
    else
    {
      it->pBucket = NULL;
      it->pNode   = NULL;
    }

    DEBUG( MAIN, ("it->remain=%d it->pBucket=%p it->pNode=%p\n",
                  it->remain, it->pBucket, it->pNode) );
  }

  DEBUG( MAIN, ("iteration through all elements completed\n") );

  return 0;
}

#ifdef DEBUG_UTIL_HASH
int SetDebugHash( void (*dbfunc)(const char *, ...), unsigned long dbflags )
{
  gs_dbfunc  = dbfunc;
  gs_dbflags = dbflags;
  return 1;
}
#endif /* DEBUG_UTIL_HASH */

