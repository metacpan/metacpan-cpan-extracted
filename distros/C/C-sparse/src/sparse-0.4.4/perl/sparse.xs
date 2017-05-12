#include <assert.h>
#ifdef __linux__
#undef  _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "patchlevel.h"

#include "../token.h"
#include "../lib.h"
#include "../symbol.h"
#include "../parse.h"
#include "../expression.h"
#include "../symbol.h"
#include "../scope.h"

/* include the complete sparse tree */
#ifdef D_USE_LIB
#include "../parse.h"
#else
#define D_USE_ONE
#include "../parse.c"
#endif

#include "const-c.inc"

#define TRACE(x) 
#define TRACE_ACTIVE()
#ifdef NDEBUG
#define assert_support(x)
#else
#define assert_support(x) x
#endif

static HV *sparsestash;

typedef struct token     t_token;
typedef struct position  t_position;
typedef struct position  sparse__pos;
typedef struct token     sparse__tok;

#define SvSPARSE(s,type)      ((type) (long)SvIV((SV*) SvRV(s)))
#define SvSPARSE_CTX(s)       SvSPARSE(s,sparsectx)
#define SvSPARSE_POS(s)       SvSPARSE(s,sparsepos)
#define SvSPARSE_TOK(s)       SvSPARSE(s,sparsetok)
#define SvSPARSE_STMT(s)      SvSPARSE(s,sparsestmt)
#define SvSPARSE_EXPR(s)      SvSPARSE(s,sparseexpr)
#define SvSPARSE_SYM(s)       SvSPARSE(s,sparsesym)
#define SvSPARSE_IDENT(s)     SvSPARSE(s,sparseident)
#define SvSPARSE_CTYPE(s)     SvSPARSE(s,sparsectype)
#define SvSPARSE_SYMCTX(s)    SvSPARSE(s,sparsesymctx)
#define SvSPARSE_SCOPE(s)     SvSPARSE(s,sparsescope)
#define SvSPARSE_EXPAND(s)    SvSPARSE(s,sparseexpand)
#define SvSPARSE_STREAM(s)    SvSPARSE(s,sparsestream)

#define SPARSE_ASSUME(x,sv,type)			\
  do {							\
    assert (sv_derived_from (sv, type##_class));	\
    x = SvSPARSE(sv,type);                              \
  } while (0)

#define SPARSE_POS_ASSUME(x,sv)    SPARSE_ASSUME(x,sv,sparse_pos)
#define SPARSE_TOK_ASSUME(x,sv)    SPARSE_ASSUME(x,sv,sparse_tok)

#define SPARSE_MALLOC_ID  42
#define SPARSE_HASHSIZE 1024

#define CREATE_SPARSE(type,package,structtype)				\
  static const char type##_class[]  = #package;				\
  static HV *type##_class_hv;						\
  typedef struct structtype  *type##_ptr;				\
  typedef struct structtype  *type##_t;					\
  assert_support (static long type##_count = 0;)			\
									\
  struct type##_elem {							\
    type##_t            m;						\
    struct type##_elem  *next;						\
  };									\
  typedef struct type##_elem  *type;					\
  typedef struct type##_elem  *type##_assume;				\
  typedef type##_ptr          type##_coerce;				\
									\
  static type type##_freelist = NULL;					\
  static type type##_hash[SPARSE_HASHSIZE];				\
									\
  static type								\
  hash_##type (type##_t e, int h)					\
  {									\
    type p = 0; p  =type##_hash[h];					\
    while (p) {								\
      if (p->m == e)							\
	return p;							\
      p = p->next;							\
    }									\
    return p;								\
  }									\
									\
  static type								\
  new_##type (type##_t e)						\
  {									\
    unsigned int h = (int) (long)e;					\
    h = ((h >> 4) ^ (h >> 8) ^ (h >> 12) ^ 0x57a45) & (SPARSE_HASHSIZE-1); \
    type p = hash_##type(e,h);						\
    TRACE (printf ("new %s(%p=>%p)\n", type##_class, e, p));		\
    if (!p) {								\
      if (type##_freelist != NULL)					\
	{								\
	  p = type##_freelist;						\
	  type##_freelist = type##_freelist->next;			\
	}								\
      else								\
	{								\
	  New (SPARSE_MALLOC_ID, p, 1, struct type##_elem);		\
        }								\
      p->next = type##_hash[h]; 					\
      type##_hash[h] = p; 						\
      p->m = e;/*TRACE (printf ("  p=%p\n", p));*/			\
      assert_support (type##_count++);					\
    }									\
    TRACE (printf (" =>%p\n", p));					\
    TRACE_ACTIVE ();							\
    return p;								\
  }									\
  static SV *								\
  newbless_##type (type##_t e)						\
  {									\
    if (!e) return &PL_sv_undef;					\
    return sv_bless (sv_setref_pv (sv_newmortal(), NULL, new_##type (e)), type##_class_hv); \
  }									\
  static SV *newsv_##type (type##_t e)					\
  {									\
    if (!e) return &PL_sv_undef;					\
    return sv_setref_pv (sv_newmortal(), NULL, new_##type (e));		\
  }									\

CREATE_SPARSE(sparsepos,   C::sparse::pos   , position);
CREATE_SPARSE(sparsetok,   C::sparse::tok   , token);
CREATE_SPARSE(sparsestmt,  C::sparse::stmt  , statement);
CREATE_SPARSE(sparseexpr,  C::sparse::expr  , expression);
CREATE_SPARSE(sparsesym,   C::sparse::sym   , symbol);
CREATE_SPARSE(sparseident, C::sparse::ident , ident);
CREATE_SPARSE(sparsectype, C::sparse::ctype , ctype);
CREATE_SPARSE(sparsesymctx,C::sparse::symctx, sym_context);
CREATE_SPARSE(sparsescope, C::sparse::scope , scope);
CREATE_SPARSE(sparseexpand,C::sparse::expand, expansion);
CREATE_SPARSE(sparsectx,   C::sparse::ctx   , sparse_ctx);
CREATE_SPARSE(sparsestream,C::sparse::stream, stream);

static char *token_types_class[] =  {
	"C::sparse::tok::TOKEN_EOF",
	"C::sparse::tok::TOKEN_ERROR",
	"C::sparse::tok::TOKEN_IDENT",
	"C::sparse::tok::TOKEN_ZERO_IDENT",
	"C::sparse::tok::TOKEN_NUMBER",
	"C::sparse::tok::TOKEN_CHAR",
	"C::sparse::tok::TOKEN_CHAR_EMBEDDED_0",
	"C::sparse::tok::TOKEN_CHAR_EMBEDDED_1",
	"C::sparse::tok::TOKEN_CHAR_EMBEDDED_2",
	"C::sparse::tok::TOKEN_CHAR_EMBEDDED_3",
	"C::sparse::tok::TOKEN_WIDE_CHAR",
	"C::sparse::tok::TOKEN_WIDE_CHAR_EMBEDDED_0",
	"C::sparse::tok::TOKEN_WIDE_CHAR_EMBEDDED_1",
	"C::sparse::tok::TOKEN_WIDE_CHAR_EMBEDDED_2",
	"C::sparse::tok::TOKEN_WIDE_CHAR_EMBEDDED_3",
	"C::sparse::tok::TOKEN_STRING",
	"C::sparse::tok::TOKEN_WIDE_STRING",
	"C::sparse::tok::TOKEN_SPECIAL",
	"C::sparse::tok::TOKEN_STREAMBEGIN",
	"C::sparse::tok::TOKEN_STREAMEND",
	"C::sparse::tok::TOKEN_MACRO_ARGUMENT",
	"C::sparse::tok::TOKEN_STR_ARGUMENT",
	"C::sparse::tok::TOKEN_QUOTED_ARGUMENT",
	"C::sparse::tok::TOKEN_CONCAT",
	"C::sparse::tok::TOKEN_GNU_KLUDGE",
	"C::sparse::tok::TOKEN_UNTAINT",
	"C::sparse::tok::TOKEN_ARG_COUNT",
	"C::sparse::tok::TOKEN_IF",
	"C::sparse::tok::TOKEN_SKIP_GROUPS",
	"C::sparse::tok::TOKEN_ELSE",
	"C::sparse::tok::TOKEN_CONS",
	0
};
static SV *bless_tok(sparsetok_t e) {
    if (!e) return &PL_sv_undef;
    return sv_bless (newsv_sparsetok (e), gv_stashpv (token_types_class[token_type(e)],1));
}
static SV *bless_sparsetok(sparsetok_t e) { return bless_tok(e); }
static char *stmt_types_class[] =  {
	"C::sparse::stmt::STMT_NONE",
	"C::sparse::stmt::STMT_DECLARATION",
	"C::sparse::stmt::STMT_EXPRESSION",
	"C::sparse::stmt::STMT_COMPOUND",
	"C::sparse::stmt::STMT_IF",
	"C::sparse::stmt::STMT_RETURN",
	"C::sparse::stmt::STMT_CASE",
	"C::sparse::stmt::STMT_SWITCH",
	"C::sparse::stmt::STMT_ITERATOR",
	"C::sparse::stmt::STMT_LABEL",
	"C::sparse::stmt::STMT_GOTO",
	"C::sparse::stmt::STMT_ASM",
	"C::sparse::stmt::STMT_CONTEXT",
	"C::sparse::stmt::STMT_RANGE"
};
static SV *bless_stmt(sparsestmt_t e) {
    if (!e) return &PL_sv_undef;
    return sv_bless (newsv_sparsestmt(e), gv_stashpv (stmt_types_class[e->type],1));
}
static SV *bless_sparsestmt(sparsestmt_t e) { return bless_stmt(e); }

static char *sym_types_class[] =  {
	"C::sparse::sym::SYM_UNINITIALIZED",
	"C::sparse::sym::SYM_PREPROCESSOR",
	"C::sparse::sym::SYM_BASETYPE",
	"C::sparse::sym::SYM_NODE",
	"C::sparse::sym::SYM_PTR",
	"C::sparse::sym::SYM_FN",
	"C::sparse::sym::SYM_ARRAY",
	"C::sparse::sym::SYM_STRUCT",
	"C::sparse::sym::SYM_UNION",
	"C::sparse::sym::SYM_ENUM",
	"C::sparse::sym::SYM_TYPEDEF",
	"C::sparse::sym::SYM_TYPEOF",
	"C::sparse::sym::SYM_MEMBER",
	"C::sparse::sym::SYM_BITFIELD",
	"C::sparse::sym::SYM_LABEL",
	"C::sparse::sym::SYM_RESTRICT",
	"C::sparse::sym::SYM_FOULED",
	"C::sparse::sym::SYM_KEYWORD",
	"C::sparse::sym::SYM_BAD",
};
static SV *bless_sym(sparsesym_t e)   { 
    if (!e) return &PL_sv_undef;
    return sv_bless (newsv_sparsesym(e), gv_stashpv (sym_types_class[e->type],1));
}
static SV *bless_sparsesym(sparsesym_t e)   { return bless_sym(e); }

static char *expr_types_class[] =  {
        "C::sparse::expr::EXPR_NONE",
	"C::sparse::expr::EXPR_VALUE",
	"C::sparse::expr::EXPR_STRING",
	"C::sparse::expr::EXPR_SYMBOL",
	"C::sparse::expr::EXPR_TYPE",
	"C::sparse::expr::EXPR_BINOP",
	"C::sparse::expr::EXPR_ASSIGNMENT",
	"C::sparse::expr::EXPR_LOGICAL",
	"C::sparse::expr::EXPR_DEREF",
	"C::sparse::expr::EXPR_PREOP",
	"C::sparse::expr::EXPR_POSTOP",
	"C::sparse::expr::EXPR_CAST",
	"C::sparse::expr::EXPR_FORCE_CAST",
	"C::sparse::expr::EXPR_IMPLIED_CAST",
	"C::sparse::expr::EXPR_SIZEOF",
	"C::sparse::expr::EXPR_ALIGNOF",
	"C::sparse::expr::EXPR_PTRSIZEOF",
	"C::sparse::expr::EXPR_CONDITIONAL",
	"C::sparse::expr::EXPR_SELECT",
	"C::sparse::expr::EXPR_STATEMENT",
	"C::sparse::expr::EXPR_CALL",
	"C::sparse::expr::EXPR_COMMA",
	"C::sparse::expr::EXPR_COMPARE",
	"C::sparse::expr::EXPR_LABEL",
	"C::sparse::expr::EXPR_INITIALIZER",
	"C::sparse::expr::EXPR_IDENTIFIER",
	"C::sparse::expr::EXPR_INDEX",
	"C::sparse::expr::EXPR_POS",
	"C::sparse::expr::EXPR_FVALUE",
	"C::sparse::expr::EXPR_SLICE",
	"C::sparse::expr::EXPR_OFFSETOF"
};
static SV *bless_expr(sparseexpr_t e) {
    if (!e) return &PL_sv_undef;
    return sv_bless (newsv_sparseexpr(e), gv_stashpv (expr_types_class[e->type],1));
}
static SV *bless_sparseexpr(sparseexpr_t e) { return bless_expr(e); }

static SV *bless_ctype(sparsectype_t e) {
    if (!e) return &PL_sv_undef;
    return sv_bless (newsv_sparsectype(e), gv_stashpv (sparsectype_class,1));
}
static SV *bless_sparsectype(sparsectype_t e) { return bless_ctype(e); }
static SV *bless_symctx(sparsesymctx_t e) {
    if (!e) return &PL_sv_undef;
    return sv_bless (newsv_sparsesymctx(e), gv_stashpv (sparsesymctx_class,1));
}
static SV *bless_sparsesymctx(sparsesymctx_t e) { return bless_symctx(e); }
static SV *bless_scope(sparsescope_t e) {
    if (!e) return &PL_sv_undef;
    return sv_bless (newsv_sparsescope(e), gv_stashpv (sparsescope_class,1));
}
static SV *bless_sparsescope(sparsesymctx_t e) { return bless_symctx(e); }

static char *expand_types_class[] =  {
	"C::sparse::expand::EXPANSION_CMDLINE",
	"C::sparse::expand::EXPANSION_STREAM",
	"C::sparse::expand::EXPANSION_MACRO",
	"C::sparse::expand::EXPANSION_MACROARG",
	"C::sparse::expand::EXPANSION_CONCAT",
	"C::sparse::expand::EXPANSION_SUBST",
};
static SV *bless_expand(sparseexpand_t e) {
    if (!e) return &PL_sv_undef;
    return sv_bless (newsv_sparseexpand(e), gv_stashpv (expand_types_class[e->typ],1));
}
static SV *bless_sparseexpand(sparseexpand_t e) { return bless_expand(e); }

static SV *bless_stream(sparsestream_t e) {
    if (!e) return &PL_sv_undef;
    return sv_bless (newsv_sparsestream(e), gv_stashpv ("C::sparse::stream",1));
}
static SV *bless_sparsestream(sparsestream_t e) { return bless_stream(e); }


static void
class_or_croak (SV *sv, const char *cl)
{
  if (! sv_derived_from (sv, cl))
    croak("not type %s", cl);
}

static void clean_up_symbols(SCTX_ struct symbol_list *list)
{
	struct symbol *sym;

	FOR_EACH_PTR(list, sym) {
		expand_symbol(sctx_ sym);
	} END_FOR_EACH_PTR(sym);
}

int
sparse_main(SCTX_ int argc, char **argv)
{
	struct symbol_list * list;
	struct string_list *filelist = NULL; int i;
	char *file; struct symbol_list *all_syms = 0;
	
	list = sparse_initialize(sctx_ argc, argv, &filelist);
	clean_up_symbols(sctx_ list);

	FOR_EACH_PTR_NOTAG(filelist, file) {
	        printf("Sparse %s\n",file);
		struct symbol_list *syms = sparse(sctx_ file);
		clean_up_symbols(sctx_ syms);
		concat_symbol_list(sctx_ syms, &all_syms);
	} END_FOR_EACH_PTR_NOTAG(file);
}


MODULE = C::sparse         PACKAGE = C::sparse

INCLUDE: const-xs.inc

BOOT:
    TRACE (printf ("sparse boot\n"));
    sparsectx_class_hv = gv_stashpv (sparsectx_class, 1);
    sparsepos_class_hv  = gv_stashpv (sparsepos_class, 1);
    sparsetok_class_hv  = gv_stashpv (sparsetok_class, 1);
    sparsestmt_class_hv = gv_stashpv (sparsestmt_class, 1);
    sparsesym_class_hv = gv_stashpv (sparsesym_class, 1);
    sparseexpr_class_hv = gv_stashpv (sparseexpr_class, 1);
    sparseident_class_hv = gv_stashpv (sparseident_class, 1);
    sparsectype_class_hv = gv_stashpv (sparsectype_class, 1);
    sparsesymctx_class_hv = gv_stashpv (sparsesymctx_class, 1);
    sparsescope_class_hv = gv_stashpv (sparsescope_class, 1);
    sparseexpand_class_hv = gv_stashpv (sparseexpand_class, 1);
    sparsestream_class_hv = gv_stashpv (sparsestream_class, 1);

INCLUDE_COMMAND: perl scripts/constdef.pl

void
END()
CODE:
    TRACE (printf ("sparse end\n"));

MODULE = C::sparse		PACKAGE = C::sparse		

SV *
hello()
    PREINIT:
        char *av[3] = {"prog", "test.c", 0};
    CODE:
        printf("Call sparse_main\n");
	/*SPARSE_CTX_INIT;
        sparse_main(sctx_ 2,av);*/
	RETVAL = newSV(0);
    OUTPUT:
	RETVAL

sparsepos
x2()
    PREINIT:
        char *av[3] = {"prog", "test.c", 0};
    CODE:
    OUTPUT:
	RETVAL


sparsectx
sparse(...)
    PREINIT:
	struct string_list *filelist = NULL;
	char *file; char **a = 0; int i; struct symbol *sym; struct symbol_list *symlist;
	struct sparse_ctx *_sctx;
    CODE:
        a = (char **)malloc(sizeof(void *) * (items+2));
	a[0] = "sparse";
        for (i = 0; i < items; i++) {
            a[i+1] = strdup(SvPV_nolen(ST(i)));
	}
        a[items+1] = 0;
	TRACE(printf("sparse_initialize("));
	for (i = 0; i < items+1; i++) {
	    TRACE(printf(" \"%s\"",a[i]));
        }
	TRACE(printf(")\n"));
	New (SPARSE_MALLOC_ID,  _sctx, 1, struct sparse_ctx);
	_sctx = sparse_ctx_init( _sctx);
        _sctx ->ppnoopt = 1;
	_sctx ->symlist = sparse_initialize(sctx_ items+1, a, &_sctx->filelist);
	FOR_EACH_PTR_NOTAG(_sctx->filelist, file) {
            concat_symbol_list(sctx_ sparse(sctx_ file), &_sctx ->symlist);
        } END_FOR_EACH_PTR_NOTAG(file);
	RETVAL = new_sparsectx((sparsectx_t)_sctx);
    OUTPUT:
	RETVAL	

MODULE = C::sparse   PACKAGE = C::sparse::ctx
PROTOTYPES: ENABLE

void
DESTROY (r)
        sparsectx r
    PREINIT:
        struct sparse_ctx *c;
    CODE:
        c = r->m;
        /*TRACE (printf ("%s DESTROY %p\n", sparsectx_class, r);fflush(stdout););*/
        assert_support (sparsectx_count--);
        TRACE_ACTIVE ();

MODULE = C::sparse   PACKAGE = C::sparse
PROTOTYPES: ENABLE

void
streams(p,...)
	sparsectx p
    PREINIT:
    struct token *t; int cnt = 0; SPARSE_CTX_GEN(0); int id = 0; struct stream *s;
    PPCODE:
        SPARSE_CTX_SET((struct sparse_ctx *)p->m);
	while(s = stream_get(sctx_ id)) { 
	    if (GIMME_V == G_ARRAY) {
	        EXTEND(SP, 1);
		PUSHs(bless_stream (s));
            }
            id++; cnt++;
	}
 	if (GIMME_V == G_SCALAR) {
 	    EXTEND(SP, 1);
            PUSHs(sv_2mortal(newSViv(cnt)));
	}

void
symbols(p,...)
	sparsectx p
    PREINIT:
    struct token *t; int i, ns, cnt = 0; SPARSE_CTX_GEN(0); int id = 0; struct ptr_list *ptrlist; void *ptr; struct symbol *sym; struct ident *ident;
    PPCODE:
        SPARSE_CTX_SET((struct sparse_ctx *)p->m);
        if( items > 1 ) {
            ns = SvIV(ST(1));
	    for (i = 0; i < IDENT_HASH_SIZE; i++) {
            	ident = _sctx->hash_table[i];
 		while (ident) {
	            for (sym = ident->symbols; sym; sym = sym->next_id) {
		        if (sym->namespace & ns) {
	                    EXTEND(SP, 1);
		            PUSHs(bless_sym (sym));
		        }
    		    }
		    ident = ident->next;
		}
	    }
        } else {
	    ptrlist = (struct ptr_list *)_sctx ->symlist;
            if (ptrlist) {
    	        FOR_EACH_PTR(ptrlist, ptr) {
	            sym = (struct symbol *) ptr;
	            if (GIMME_V == G_ARRAY) {
	                EXTEND(SP, 1);
		        PUSHs(bless_sym (sym));
                    }
                    cnt++;
	        } END_FOR_EACH_PTR(ptr);
            }
 	    if (GIMME_V == G_SCALAR) {
 	        EXTEND(SP, 1);
                PUSHs(sv_2mortal(newSViv(cnt)));
	    }
	}


MODULE = C::sparse   PACKAGE = C::sparse::tok
PROTOTYPES: ENABLE

void
list(p,...)
	sparsetok p
    PREINIT:
    struct token *t, *e = 0; int cnt = 0; SPARSE_CTX_GEN(0); sparsetok _e;
    PPCODE:
	t = p->m;
        SPARSE_CTX_SET(t->ctx);
	if (items >= 2 && sv_derived_from (ST(1), sparsetok_class)) {
	        _e = SvSPARSE_TOK(ST(1)); e = _e->m;
	}
        while(t != e && !eof_token(t)) {
	        cnt++;
 	    	if (GIMME_V == G_ARRAY) {
		   EXTEND(SP, 1);
		   PUSHs(bless_tok (t));
 		}
		t = t->next;
	}
 	if (GIMME_V == G_SCALAR) {
 	    EXTEND(SP, 1);
            PUSHs(sv_2mortal(newSViv(cnt)));
	}

void
fold(p,...)
	sparsetok p
    PREINIT:
    struct token *t, *e = 0; int cnt = 0; SPARSE_CTX_GEN(0); sparsetok _e;
    PPCODE:
	t = p->m;
        SPARSE_CTX_SET(t->ctx);
	if (items >= 2 && sv_derived_from (ST(1), sparsetok_class)) {
	        _e = SvSPARSE_TOK(ST(1)); e = _e->m;
	}
        while(t != e && !eof_token(t)) {
	        cnt++;
 		t = t->next;
	}

void
tok2str(p,...)
	sparsetok p
    PREINIT:
        struct token *t; int cnt = 0; SPARSE_CTX_GEN(0); 
        int prec = 1; char *separator = ""; char *pre = "", *v;
        const char *n; SV *r;
    PPCODE:
        t = p->m;
        SPARSE_CTX_SET(t->ctx);
	EXTEND(SP, 1);
        n = show_token(sctx_ t);
/*if (t->space && t->space->data) { pre = (char *)t->space->data;}*/
        v = malloc(strlen(n) + strlen(pre) + 1);
        v[0] = 0; strcat(v, pre); strcat(v, n);
        PUSHs(sv_2mortal(newSVpv(v, strlen(v))));
        free(v);

MODULE = C::sparse   PACKAGE = C::sparse::ident
PROTOTYPES: ENABLE

SV *
name(i)
	sparseident i
    PREINIT:
        int len = 0;
    CODE:
        RETVAL = newSVpv(i->m ? i->m->name : "<undef>",i->m ? i->m->len : 7);
    OUTPUT:
	RETVAL

MODULE = C::sparse   PACKAGE = C::sparse::sym
PROTOTYPES: ENABLE

SV *
name(s)
	sparsesym s
    PREINIT:
        int len = 0; struct ident *i; const char *n;
    CODE:
	if (!s->m || !(i = s->m->ident))
	   XSRETURN_UNDEF;
	n = show_ident(s->m->ctx, i);
        RETVAL = newSVpv(n,0);
    OUTPUT:
	RETVAL

MODULE = C::sparse   PACKAGE = C::sparse::sym
PROTOTYPES: ENABLE

SV *
id(s)
	sparsesym s
    PREINIT:
        int len = 0; const char *n; struct symbol *sym;
    CODE:
	if (!s->m || ! (sym = s->m))
	   XSRETURN_UNDEF;
	n = builtin_typename(sym->ctx,sym) ?: show_ident(sym->ctx,sym->ident);
        RETVAL = newSVpv(n,0);
    OUTPUT:
	RETVAL

SV *
typename(s)
	sparsesym s
    PREINIT:
        int len = 0; const char *n; struct symbol *sym;
    CODE:
	if (!s->m || ! (sym = s->m))
	   XSRETURN_UNDEF;
	n = show_typename_fn(sym->ctx,sym);
        RETVAL = newSVpv(n,0);
	if (n)
	    free((char*)n);
    OUTPUT:
	RETVAL


INCLUDE_COMMAND: perl scripts/sparse.pl sparse.xsh
