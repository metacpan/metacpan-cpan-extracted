/*
  AVL balanced tree library

  This is an adaptation of the AVL balanced tree C library
  created by Julienne Walker which can be found here:

  http://www.eternallyconfuzzled.com/Libraries.aspx

*/
#include "avltree.h"

#ifdef __cplusplus
#include <cstdlib>

using std::malloc;
using std::free;
using std::size_t;
#else
#include <stdlib.h>
#include <stdio.h>
#endif

#ifndef HEIGHT_LIMIT
#define HEIGHT_LIMIT 64 /* Tallest allowable tree */
#endif

typedef struct avlnode {
  int                 balance; /* Balance factor */
  SV                 *data;    /* User-defined content */
  struct avlnode *link[2]; /* Left (0) and right (1) links */
} avlnode_t;

struct avltree {
  avlnode_t *root; /* Top of the tree */
  cmp_f          cmp;    /* Compare two items */
  dup_f          dup;    /* Clone an item (user-defined) */
  rel_f          rel;    /* Destroy an item (user-defined) */
  size_t         size;   /* Number of items (user-defined) */
};

struct avltrav {
  avltree_t *tree;               /* Paired tree */
  avlnode_t *it;                 /* Current node */
  avlnode_t *path[HEIGHT_LIMIT]; /* Traversal path */
  size_t         top;                /* Top of stack */
};

/* Two way single rotation */
#define single(root,dir) do {         \
  avlnode_t *save = root->link[!dir]; \
  root->link[!dir] = save->link[dir];     \
  save->link[dir] = root;                 \
  root = save;                            \
} while (0)

/* Two way double rotation */
#define double(root,dir) do {                    \
  avlnode_t *save = root->link[!dir]->link[dir]; \
  root->link[!dir]->link[dir] = save->link[!dir];    \
  save->link[!dir] = root->link[!dir];               \
  root->link[!dir] = save;                           \
  save = root->link[!dir];                           \
  root->link[!dir] = save->link[dir];                \
  save->link[dir] = root;                            \
  root = save;                                       \
} while (0)

/* Adjust balance before double rotation */
#define adjust_balance(root,dir,bal) do { \
  avlnode_t *n = root->link[dir];         \
  avlnode_t *nn = n->link[!dir];          \
  if ( nn->balance == 0 )                     \
    root->balance = n->balance = 0;           \
  else if ( nn->balance == bal ) {            \
    root->balance = -bal;                     \
    n->balance = 0;                           \
  }                                           \
  else { /* nn->balance == -bal */            \
    root->balance = 0;                        \
    n->balance = bal;                         \
  }                                           \
  nn->balance = 0;                            \
} while (0)

/* Rebalance after insertion */
#define insert_balance(root,dir) do {  \
  avlnode_t *n = root->link[dir];      \
  int bal = dir == 0 ? -1 : +1;            \
  if ( n->balance == bal ) {               \
    root->balance = n->balance = 0;        \
    single ( root, !dir );             \
  }                                        \
  else { /* n->balance == -bal */          \
    adjust_balance ( root, dir, bal ); \
    double ( root, !dir );             \
  }                                        \
} while (0)

/* Rebalance after deletion */
#define remove_balance(root,dir,done) do { \
  avlnode_t *n = root->link[!dir];         \
  int bal = dir == 0 ? -1 : +1;                \
  if ( n->balance == -bal ) {                  \
    root->balance = n->balance = 0;            \
    single ( root, dir );                  \
  }                                            \
  else if ( n->balance == bal ) {              \
    adjust_balance ( root, !dir, -bal );   \
    double ( root, dir );                  \
  }                                            \
  else { /* n->balance == 0 */                 \
    root->balance = -bal;                      \
    n->balance = bal;                          \
    single ( root, dir );                  \
    done = 1;                                  \
  }                                            \
} while (0)

static avlnode_t *new_node ( avltree_t *tree, SV *data )
{
  avlnode_t *rn = (avlnode_t *)malloc ( sizeof *rn );

  if ( rn == NULL )
    return NULL;

  rn->balance = 0;
  rn->data = tree->dup ( data );
  rn->link[0] = rn->link[1] = NULL;

  return rn;
}

avltree_t *avltree_new ( cmp_f cmp, dup_f dup, rel_f rel )
{
  avltree_t *rt = (avltree_t *)malloc ( sizeof *rt );

  if ( rt == NULL )
    return NULL;

  rt->root = NULL;
  rt->cmp = cmp;
  rt->dup = dup;
  rt->rel = rel;
  rt->size = 0;

  return rt;
}

void avltree_delete ( avltree_t *tree )
{
  avlnode_t *it = tree->root;
  avlnode_t *save;

  /* Destruction by rotation */
  while ( it != NULL ) {
    if ( it->link[0] == NULL ) {
      /* Remove node */
      save = it->link[1];
      tree->rel ( it->data );
      free ( it );
    }
    else {
      /* Rotate right */
      save = it->link[0];
      it->link[0] = save->link[1];
      save->link[1] = it;
    }

    it = save;
  }

  free ( tree );
}

SV *avltree_find ( avltree_t *tree, SV *data )
{
  avlnode_t *it = tree->root;

  while ( it != NULL ) {
    int cmp = tree->cmp ( it->data, data );

    if ( cmp == 0 )
      break;

    it = it->link[cmp < 0];
  }

  return it == NULL ? &PL_sv_undef : it->data;
}

int avltree_insert ( avltree_t *tree, SV *data )
{
  /* Empty tree case */
  if ( tree->root == NULL ) {
    tree->root = new_node ( tree, data );
    if ( tree->root == NULL )
      return 0;
  }
  else {
    avlnode_t head = {0}; /* Temporary tree root */
    avlnode_t *s, *t;     /* Place to rebalance and parent */
    avlnode_t *p, *q;     /* Iterator and save pointer */
    int dir;

    /* Set up false root to ease maintenance */
    t = &head;
    t->link[1] = tree->root;

    /* Search down the tree, saving rebalance points */
    for ( s = p = t->link[1]; ; p = q ) {
      dir = tree->cmp ( p->data, data ) < 0;
      q = p->link[dir];

      if ( q == NULL )
        break;
      
      if ( q->balance != 0 ) {
        t = p;
        s = q;
      }
    }

    p->link[dir] = q = new_node ( tree, data );
    if ( q == NULL )
      return 0;

    /* Update balance factors */
    for ( p = s; p != q; p = p->link[dir] ) {
      dir = tree->cmp ( p->data, data ) < 0;
      p->balance += dir == 0 ? -1 : +1;
    }

    q = s; /* Save rebalance point for parent fix */

    /* Rebalance if necessary */
    if ( abs ( s->balance ) > 1 ) {
      dir = tree->cmp ( s->data, data ) < 0;
      insert_balance ( s, dir );
    }

    /* Fix parent */
    if ( q == head.link[1] )
      tree->root = s;
    else
      t->link[q == t->link[1]] = s;
  }

  ++tree->size;

  return 1;
}

int avltree_erase ( avltree_t *tree, SV *data )
{
  if ( tree->root != NULL ) {
    avlnode_t *it, *up[HEIGHT_LIMIT];
    int upd[HEIGHT_LIMIT], top = 0;
    int done = 0;

    it = tree->root;

    /* Search down tree and save path */
    for ( ; ; ) {
      if ( it == NULL )
        return 0;
      else if ( tree->cmp ( it->data, data ) == 0 )
        break;

      /* Push direction and node onto stack */
      upd[top] = tree->cmp ( it->data, data ) < 0;
      up[top++] = it;

      it = it->link[upd[top - 1]];
    }

    /* Remove the node */
    if ( it->link[0] == NULL || it->link[1] == NULL ) {
      /* Which child is not null? */
      int dir = it->link[0] == NULL;

      /* Fix parent */
      if ( top != 0 )
        up[top - 1]->link[upd[top - 1]] = it->link[dir];
      else
        tree->root = it->link[dir];

      tree->rel ( it->data );
      free ( it );
    }
    else {
      /* Find the inorder successor */
      avlnode_t *heir = it->link[1];
      SV *save;
      
      /* Save this path too */
      upd[top] = 1;
      up[top++] = it;

      while ( heir->link[0] != NULL ) {
        upd[top] = 0;
        up[top++] = heir;
        heir = heir->link[0];
      }

      /* Swap data */
      save = it->data;
      it->data = heir->data;
      heir->data = save;

      /* Unlink successor and fix parent */
      up[top - 1]->link[up[top - 1] == it] = heir->link[1];

      tree->rel ( heir->data );
      free ( heir );
    }

    /* Walk back up the search path */
    while ( --top >= 0 && !done ) {
      /* Update balance factors */
      up[top]->balance += upd[top] != 0 ? -1 : +1;

      /* Terminate or rebalance as necessary */
      if ( abs ( up[top]->balance ) == 1 )
        break;
      else if ( abs ( up[top]->balance ) > 1 ) {
        remove_balance ( up[top], upd[top], done );

        /* Fix parent */
        if ( top != 0 )
          up[top - 1]->link[upd[top - 1]] = up[top];
        else
          tree->root = up[0];
      }
    }

    --tree->size;
  }

  return 1;
}

size_t avltree_size ( avltree_t *tree )
{
  return tree->size;
}

avltrav_t *avltnew ( void )
{
  return malloc ( sizeof ( avltrav_t ) );
}

void avltdelete ( avltrav_t *trav )
{
  free ( trav );
}

/*
  First step in traversal,
  handles min and max
*/
static SV *start ( avltrav_t *trav, avltree_t *tree, int dir )
{
  trav->tree = tree;
  trav->it = tree->root;
  trav->top = 0;

  /* Build a path to work with */
  if ( trav->it != NULL ) {
    while ( trav->it->link[dir] != NULL ) {
      trav->path[trav->top++] = trav->it;
      trav->it = trav->it->link[dir];
    }
  }

  return trav->it == NULL ? &PL_sv_undef : trav->it->data;
}

/*
  Subsequent traversal steps,
  handles ascending and descending
*/
static SV *move ( avltrav_t *trav, int dir )
{
  if ( trav->it->link[dir] != NULL ) {
    /* Continue down this branch */
    trav->path[trav->top++] = trav->it;
    trav->it = trav->it->link[dir];

    while ( trav->it->link[!dir] != NULL ) {
      trav->path[trav->top++] = trav->it;
      trav->it = trav->it->link[!dir];
    }
  }
  else {
    /* Move to the next branch */
    avlnode_t *last;

    do {
      if ( trav->top == 0 ) {
        trav->it = NULL;
        break;
      }

      last = trav->it;
      trav->it = trav->path[--trav->top];
    } while ( last == trav->it->link[dir] );
  }

  return trav->it == NULL ? &PL_sv_undef : trav->it->data;
}

SV *avltfirst ( avltrav_t *trav, avltree_t *tree )
{
  return start ( trav, tree, 0 ); /* Min value */
}

SV *avltlast ( avltrav_t *trav, avltree_t *tree )
{
  return start ( trav, tree, 1 ); /* Max value */
}

SV *avltnext ( avltrav_t *trav )
{
  return move ( trav, 1 ); /* Toward larger items */
}

SV *avltprev ( avltrav_t *trav )
{
  return move ( trav, 0 ); /* Toward smaller items */
}
