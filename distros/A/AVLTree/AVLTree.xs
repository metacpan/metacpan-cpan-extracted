#ifdef __cplusplus
extern "C" {
#endif

/* 
   From http://blogs.perl.org/users/nick_wellnhofer/2015/03/writing-xs-like-a-pro---perl-no-get-context-and-static-functions.html
   The perlxs man page recommends to define the PERL_NO_GET_CONTEXT macro before including EXTERN.h, perl.h, and XSUB.h. 
   If this macro is defined, it is assumed that the interpreter context is passed as a parameter to every function. 
   If it's undefined, the context will typically be fetched from thread-local storage when calling the Perl API, which 
   incurs a performance overhead.
   
   WARNING:
   
    setting this macro involves additional changes to the XS code. For example, if the XS file has static functions that 
    call into the Perl API, you'll get somewhat cryptic error messages like the following:

    /usr/lib/i386-linux-gnu/perl/5.20/CORE/perl.h:155:16: error: ‘my_perl’ undeclared (first use in this function)
    #  define aTHX my_perl

   See http://perldoc.perl.org/perlguts.html#How-do-I-use-all-this-in-extensions? for ways in which to avoid these
   errors when using the macro.

   One way is to begin each static function that invoke the perl API with the dTHX macro to fetch context. This is
   used in the following static functions.
   Another more efficient approach is to prepend pTHX_ to the argument list in the declaration of each static
   function and aTHX_ when each of these functions are invoked. This is used directly in the AVL tree library
   source code.
*/
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
typedef avltrav_t AVLTrav;

/* C-level callbacks required by the AVL tree library */

static SV* callback = (SV*)NULL;

static int svcompare(SV *p1, SV *p2) {
  /*
    This is one way to avoid the above mentioned error when 
    declaring the PERL_NO_GET_CONTEXT macro
  */
  dTHX; 
  
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

static SV* svclone(SV* p) {
  dTHX;       /* fetch context */
  
  return newSVsv(p);
}

void svdestroy(SV* p) {
  dTHX;       /* fetch context */
  
  SvREFCNT_dec(p);
}

/*====================================================================
 * XS SECTION                                                     
 *====================================================================*/

MODULE = AVLTree 	PACKAGE = AVLTree

void
new ( class, cmp_fn )
    char* class
    SV*   cmp_fn
    PROTOTYPE: $$
    PREINIT:
        AVLTree* tree;
        AVLTrav* trav;
    PPCODE:
    {
      SV* self;
      HV* hash = newHV();

      TRACEME("Registering callback for comparison");
      if(callback == (SV*)NULL)
        callback = newSVsv(cmp_fn);
      else
        SvSetSV(callback, cmp_fn);
    
      TRACEME("Allocating AVL tree");      
      tree = avltree_new(svcompare, svclone, svdestroy);
      if(tree == NULL)
	croak("Unable to allocate AVL tree");	
      hv_store(hash, "tree", 4, newSViv(PTR2IV(tree)), 0);

      TRACEME("Allocating AVL tree traversal");
      trav = avltnew();
      if(trav == NULL)
	croak("Unable to allocate AVL tree traversal");
      hv_store(hash, "trav", 4, newSViv(PTR2IV(trav)), 0);
      
      self = newRV_noinc((SV*)hash);;
      sv_2mortal(self);
      sv_bless(self, gv_stashpv(class, FALSE));
     
      PUSHs(self);
      XSRETURN(1);
    }

SV*
find(self, ...)
  SV* self
  PREINIT:
    AVLTree* tree;
  INIT:
    if(items < 2 || !SvOK(ST(1)) || SvTYPE(ST(1)) == SVt_NULL) {
      XSRETURN_UNDEF;
    }
  CODE:
    // get tree pointer
    SV** svp = hv_fetch((HV*)SvRV(self), "tree", 4, 0);
    if(svp == NULL)
      croak("Unable to access tree\n");
    tree = INT2PTR(AVLTree*, SvIV(*svp));

    SV* result = avltree_find(aTHX_ tree, ST(1));
    if(SvOK(result) && SvTYPE(result) != SVt_NULL) {
      /* WARN: if it's mortalised e.g. sv_2mortal(...)? returns "Attempt to free unreferenced scalar: SV" */
      RETVAL = newSVsv(result);
    } else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

int
insert(self, item)
  SV* self
  SV* item
  PROTOTYPE: $$
  PREINIT:
    AVLTree* tree;
  CODE:
    SV** svp = hv_fetch((HV*)SvRV(self), "tree", 4, 0);
    if(svp == NULL)
      croak("Unable to access tree\n");
    tree = INT2PTR(AVLTree*, SvIV(*svp));
    
    RETVAL = avltree_insert(tree, item);

  OUTPUT:
    RETVAL

int
remove(self, item)
  SV* self
  SV* item
  PROTOTYPE: $$
  PREINIT:
    AVLTree* tree;
  CODE:
    SV** svp = hv_fetch((HV*)SvRV(self), "tree", 4, 0);
    if(svp == NULL)
      croak("Unable to access tree\n");
    tree = INT2PTR(AVLTree*, SvIV(*svp));

    RETVAL = avltree_erase(tree, item);

  OUTPUT:
    RETVAL

int
size(self)
  SV* self
  PROTOTYPE: $
  PREINIT:
    AVLTree* tree;
  CODE:
    SV** svp = hv_fetch((HV*)SvRV(self), "tree", 4, 0);
    if(svp == NULL)
      croak("Unable to access tree\n");
    tree = INT2PTR(AVLTree*, SvIV(*svp));
  
    RETVAL = avltree_size(tree);
  OUTPUT:
    RETVAL

SV*
first(self)
  SV* self
  PROTOTYPE: $
  PREINIT:
    AVLTree* tree;
    AVLTrav* trav;
  CODE:
    SV** svp = hv_fetch((HV*)SvRV(self), "tree", 4, 0);
    if(svp == NULL)
      croak("Unable to access tree\n");
    tree = INT2PTR(AVLTree*, SvIV(*svp));
    svp = hv_fetch((HV*)SvRV(self), "trav", 4, 0);
    if(svp == NULL)
      croak("Unable to access tree traversal\n");
    trav = INT2PTR(AVLTrav*, SvIV(*svp));

    RETVAL = newSVsv(avltfirst(aTHX_ trav, tree));

  OUTPUT:
    RETVAL

SV*
last(self)
  SV* self
  PROTOTYPE: $
  PREINIT:
    AVLTree* tree;
    AVLTrav* trav;
  CODE:
    SV** svp = hv_fetch((HV*)SvRV(self), "tree", 4, 0);
    if(svp == NULL)
      croak("Unable to access tree\n");
    tree = INT2PTR(AVLTree*, SvIV(*svp));
    svp = hv_fetch((HV*)SvRV(self), "trav", 4, 0);
    if(svp == NULL)
      croak("Unable to access tree traversal\n");
    trav = INT2PTR(AVLTrav*, SvIV(*svp));

    RETVAL = newSVsv(avltlast(aTHX_ trav, tree));

  OUTPUT:
    RETVAL

SV*
next(self)
  SV* self
  PROTOTYPE: $
  PREINIT:
    AVLTree* tree;
    AVLTrav* trav;
  CODE:
    SV** svp = hv_fetch((HV*)SvRV(self), "trav", 4, 0);
    if(svp == NULL)
      croak("Unable to access tree traversal\n");
    trav = INT2PTR(AVLTrav*, SvIV(*svp));

    RETVAL = newSVsv(avltnext(aTHX_ trav));

  OUTPUT:
    RETVAL

SV*
prev(self)
  SV* self
  PROTOTYPE: $
  PREINIT:
    AVLTree* tree;
    AVLTrav* trav;
  CODE:
    SV** svp = hv_fetch((HV*)SvRV(self), "trav", 4, 0);
    if(svp == NULL)
      croak("Unable to access tree traversal\n");
    trav = INT2PTR(AVLTrav*, SvIV(*svp));

    RETVAL = newSVsv(avltprev(aTHX_ trav));

  OUTPUT:
    RETVAL

void DESTROY(self)
  SV* self
  PROTOTYPE: $
  PREINIT:
    AVLTree* tree;
    AVLTrav* trav;
  CODE:
    TRACEME("Deleting AVL tree");
    SV** svp = hv_fetch((HV*)SvRV(self), "tree", 4, 0);
    if(svp == NULL)
      croak("Unable to access tree\n");
    tree = INT2PTR(AVLTree*, SvIV(*svp));
    avltree_delete(tree);

    TRACEME("Deleting AVL tree traversal");
    svp = hv_fetch((HV*)SvRV(self), "trav", 4, 0);
    if(svp == NULL)
      croak("Unable to access tree traversal\n");
    trav = INT2PTR(AVLTrav*, SvIV(*svp));
    avltdelete(trav);



  
