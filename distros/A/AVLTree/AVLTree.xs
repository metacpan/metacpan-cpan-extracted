#ifdef __cplusplus
extern "C" {
#endif
  
#define PERL_NO_GET_CONTEXT
  
#ifdef ENABLE_DEBUG
#define TRACEME(x) do {						\
    if (SvTRUE(perl_get_sv("AVLTree::ENABLE_DEBUG", TRUE)))	\
      { PerlIO_stdoutf (x); PerlIO_stdoutf ("\n"); }		\
  } while (0)
#else
#define TRACEME(x)
#endif
  
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
  
#include "ppport.h"
  
#include "avltree.h"
  
#ifdef __cplusplus
}
#endif

typedef avltree_t AVLTree;

/* C-level callbacks required by the AVL tree library */

static SV* callback = (SV*)NULL;

static int compare(SV *p1, SV *p2) {
  int cmp;
  
  dSP;
  int count;

  //ENTER;
  //SAVETMPS;
  
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVsv(p1)));
  XPUSHs(sv_2mortal(newSVsv(p2)));
  PUTBACK;
  
  /* Call the Perl sub to process the callback */
  count = call_sv(callback, G_SCALAR);

  SPAGAIN;

  if(count != 1)
    croak("Did not return a value\n");
  
  cmp = POPi;
  PUTBACK;

  //FREETMPS;
  //LEAVE;

  return cmp;
}

static SV* clone(SV* p) {
  return newSVsv(p);
}

void destroy(SV* p) {
  SvREFCNT_dec(p);
}

/*====================================================================
 * XS SECTION                                                     
 *====================================================================*/

MODULE = AVLTree 	PACKAGE = AVLTree
  
AVLTree*
new( class, cmp_f )
  char* class
  SV*   cmp_f
  PROTOTYPE: $$
  CODE:
    TRACEME("Registering callback for comparison");
    if(callback == (SV*)NULL)
      callback = newSVsv(cmp_f);
    else
      SvSetSV(callback, cmp_f);
    
    TRACEME("Allocating AVL tree");
    RETVAL = avltree_new(compare, clone, destroy);

    if(RETVAL == NULL) {
      warn("Unable to allocate AVL tree");
      XSRETURN_UNDEF;
    }

  OUTPUT:
    RETVAL

MODULE = AVLTree 	PACKAGE = AVLTreePtr

SV*
find(t, ...)
  AVLTree* t
  INIT:
    if(items < 2 || !SvOK(ST(1)) || SvTYPE(ST(1)) == SVt_NULL) {
      XSRETURN_UNDEF;
    }
  CODE:
    SV* result = avltree_find(t, ST(1));
    if(SvOK(result) && SvTYPE(result) != SVt_NULL) {
      /* WARN: if it's mortalised e.g. sv_2mortal(...)? returns "Attempt to free unreferenced scalar: SV" */
      RETVAL = newSVsv(result);
    } else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

int
insert(t, item)
  AVLTree* t
  SV* item
  PROTOTYPE: $$
  CODE:
    RETVAL = avltree_insert(t, item);
  OUTPUT:
    RETVAL

int
remove(t, item)
  AVLTree* t
  SV* item
  PROTOTYPE: $$
  CODE:
    RETVAL = avltree_erase(t, item);
  OUTPUT:
    RETVAL

int
size(t)
  AVLTree* t
  PROTOTYPE: $
  CODE:
    RETVAL = avltree_size(t);
  OUTPUT:
    RETVAL
    
void DESTROY(t)
  AVLTree* t
  PROTOTYPE: $
  CODE:
      TRACEME("Deleting AVL tree");
      avltree_delete(t);

  
