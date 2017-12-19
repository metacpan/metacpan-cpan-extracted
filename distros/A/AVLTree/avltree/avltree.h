#ifndef AVLTREE_H
#define AVLTREE_H

/*
  AVL balanced tree library

  This is an adaptation of the AVL balanced tree C library
  created by Julienne Walker which can be found here:

  http://www.eternallyconfuzzled.com/Libraries.aspx
  
  This particular implementation makes it suitable for the
  creation of a Perl tiny wrapper around this library using 
  the Perl extension mechanism. 

  The way this is accomplished is by using pointers to Perl 
  variables as node items, instead of generic void pointers.

*/
#ifdef __cplusplus
#include <cstddef>

using std::size_t;

extern "C" {
#else
#include <stddef.h>
#endif

#include <EXTERN.h>
#include <perl.h>

/* Opaque types */
typedef struct avltree avltree_t;
typedef struct avltrav avltrav_t;

/* User-defined item handling */
typedef int   (*cmp_f) ( SV *p1, SV *p2 );
typedef SV *(*dup_f) ( SV* p );
typedef void  (*rel_f) ( SV* p );

/* AVL tree functions */
avltree_t     *avltree_new ( cmp_f cmp, dup_f dup, rel_f rel );
void           avltree_delete ( avltree_t *tree );
SV            *avltree_find ( avltree_t *tree, SV *data );
int            avltree_insert ( avltree_t *tree, SV *data );
int            avltree_erase ( avltree_t *tree, SV *data );
size_t         avltree_size ( avltree_t *tree );

/* Traversal functions */
avltrav_t *avltnew ( void );
void       avltdelete ( avltrav_t *trav );
SV        *avltfirst ( avltrav_t *trav, avltree_t *tree );
SV        *avltlast ( avltrav_t *trav, avltree_t *tree );
SV        *avltnext ( avltrav_t *trav );
SV        *avltprev ( avltrav_t *trav );

#ifdef __cplusplus
}
#endif

#endif /* AVLTREE_H */
