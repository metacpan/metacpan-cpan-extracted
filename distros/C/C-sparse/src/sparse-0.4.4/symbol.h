#ifndef SYMBOL_H
#define SYMBOL_H

#include "ctx.h"


#ifndef DO_CTX
/* Current parsing/evaluation function */
extern struct symbol *current_fn;
/* Abstract types */
extern struct symbol	int_type,
			fp_type;

/* C types */
extern struct symbol	bool_ctype, void_ctype, type_ctype,
			char_ctype, schar_ctype, uchar_ctype,
			short_ctype, sshort_ctype, ushort_ctype,
			int_ctype, sint_ctype, uint_ctype,
			long_ctype, slong_ctype, ulong_ctype,
			llong_ctype, sllong_ctype, ullong_ctype,
			lllong_ctype, slllong_ctype, ulllong_ctype,
			float_ctype, double_ctype, ldouble_ctype,
			string_ctype, ptr_ctype, lazy_ptr_ctype,
			incomplete_ctype, label_ctype, bad_ctype,
			null_ctype;

/* Special internal symbols */
extern struct symbol	zero_int;
#endif

#ifndef DO_CTX
#define __IDENT(n,str,res) \
	extern struct ident n
#include "ident-list.h"
#endif

#define symbol_is_typename(sym) ((sym)->type == SYM_TYPE)

#ifndef DO_CTX
extern struct symbol_list *translation_unit_used_list;
extern struct stream *stream_sc;
extern struct stream *stream_sb;
#endif

extern void access_symbol(SCTX_ struct symbol *);

extern const char * type_difference(SCTX_ struct ctype *c1, struct ctype *c2,
	unsigned long mod1, unsigned long mod2);

extern struct symbol *lookup_symbol(SCTX_ struct ident *, enum namespace);
extern struct symbol *create_symbol(SCTX_ int stream, const char *name, int type, int namespace);
extern void init_symbols(SCTX);
extern void init_ctype(SCTX);
extern struct symbol *alloc_symbol(SCTX_ struct token *tok, int type);
extern void show_type(SCTX_ struct symbol *);
extern const char *modifier_string(SCTX_ unsigned long mod);
extern void show_symbol(SCTX_ struct symbol *);
extern int show_symbol_expr_init(SCTX_ struct symbol *sym);
extern void show_type_list(SCTX_ struct symbol *);
extern void show_symbol_list(SCTX_ struct symbol_list *, const char *);
extern void add_symbol(SCTX_ struct symbol_list **, struct symbol *);
extern void bind_symbol(SCTX_ struct symbol *, struct ident *, enum namespace);

extern struct symbol *examine_symbol_type(SCTX_ struct symbol *);
extern struct symbol *examine_pointer_target(SCTX_ struct symbol *);
extern void examine_simple_symbol_type(SCTX_ struct symbol *);
extern const char *show_typename(SCTX_ struct symbol *sym);
extern const char *show_typename_fn(SCTX_ struct symbol *sym);
extern const char *builtin_typename(SCTX_ struct symbol *sym);
extern const char *builtin_ctypename(SCTX_ struct ctype *ctype);
extern const char* get_type_name(SCTX_ enum type type);

extern void debug_symbol(SCTX_ struct symbol *);
extern void merge_type(SCTX_ struct symbol *sym, struct symbol *base_type);
extern void check_declaration(SCTX_ struct symbol *sym);

#include "target.h"

static inline struct symbol *get_base_type(SCTX_ const struct symbol *sym)
{
	return examine_symbol_type(sctx_ sym->ctype.base_type);
}

static inline int is_int_type(SCTX_ const struct symbol *type)
{
	if (type->type == SYM_NODE)
		type = type->ctype.base_type;
	if (type->type == SYM_ENUM)
		type = type->ctype.base_type;
	return type->type == SYM_BITFIELD ||
	       type->ctype.base_type == &sctxp int_type;
}

static inline int is_enum_type(const struct symbol *type)
{
	if (type->type == SYM_NODE)
		type = type->ctype.base_type;
	return (type->type == SYM_ENUM);
}

static inline int is_type_type(struct symbol *type)
{
	return (type->ctype.modifiers & MOD_TYPE) != 0;
}

static inline int is_ptr_type(struct symbol *type)
{
	if (type->type == SYM_NODE)
		type = type->ctype.base_type;
	return type->type == SYM_PTR || type->type == SYM_ARRAY || type->type == SYM_FN;
}

static inline int is_float_type(SCTX_ struct symbol *type)
{
	if (type->type == SYM_NODE)
		type = type->ctype.base_type;
	return type->ctype.base_type == &sctxp fp_type;
}

static inline int is_byte_type(SCTX_ struct symbol *type)
{
	return type->bit_size == sctxp bits_in_char && type->type != SYM_BITFIELD;
}

static inline int is_void_type(SCTX_ struct symbol *type)
{
	if (type->type == SYM_NODE)
		type = type->ctype.base_type;
	return type == &sctxp void_ctype;
}

static inline int is_bool_type(SCTX_ struct symbol *type)
{
	if (type->type == SYM_NODE)
		type = type->ctype.base_type;
	return type == &sctxp bool_ctype;
}

static inline int is_function(struct symbol *type)
{
	return type && type->type == SYM_FN;
}

static inline int is_extern_inline(struct symbol *sym)
{
	return (sym->ctype.modifiers & MOD_EXTERN) &&
		(sym->ctype.modifiers & MOD_INLINE) &&
		is_function(sym->ctype.base_type);
}

static inline int get_sym_type(struct symbol *type)
{
	if (type->type == SYM_NODE)
		type = type->ctype.base_type;
	if (type->type == SYM_ENUM)
		type = type->ctype.base_type;
	return type->type;
}

static inline struct symbol *lookup_keyword(SCTX_ struct ident *ident, enum namespace ns)
{
	if (!ident->keyword)
		return NULL;
	return lookup_symbol(sctx_ ident, ns);
}

#define is_restricted_type(type) (get_sym_type(type) == SYM_RESTRICT)
#define is_fouled_type(type) (get_sym_type(type) == SYM_FOULED)
#define is_bitfield_type(type)   (get_sym_type(type) == SYM_BITFIELD)
extern int is_ptr_type(struct symbol *);

void create_fouled(SCTX_ struct symbol *type);
struct symbol *befoul(SCTX_ struct symbol *type);


#endif /* SYMBOL_H */
