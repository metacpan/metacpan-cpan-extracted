#ifndef SYMBOL_STRUCT_H
#define SYMBOL_STRUCT_H
/*
 * Basic symbol and namespace definitions.
 *
 * Copyright (C) 2003 Transmeta Corp.
 *               2003 Linus Torvalds
 *
 *  Licensed under the Open Software License version 1.1
 */

#include "token_struct.h"

/*
 * An identifier with semantic meaning is a "symbol".
 *
 * There's a 1:n relationship: each symbol is always
 * associated with one identifier, while each identifier
 * can have one or more semantic meanings due to C scope
 * rules.
 *
 * The progression is symbol -> token -> identifier. The
 * token contains the information on where the symbol was
 * declared.
 */
enum namespace {
	NS_NONE = 0,
	NS_MACRO = 1,
	NS_TYPEDEF = 2,
	NS_STRUCT = 4,  // Also used for unions and enums.
	NS_LABEL = 8,
	NS_SYMBOL = 16,
	NS_ITERATOR = 32,
	NS_PREPROCESSOR = 64,
	NS_UNDEF = 128,
	NS_KEYWORD = 256,
};

enum type {
	SYM_UNINITIALIZED,
	SYM_PREPROCESSOR,
	SYM_BASETYPE,
	SYM_NODE,
	SYM_PTR,
	SYM_FN,
	SYM_ARRAY,
	SYM_STRUCT,
	SYM_UNION,
	SYM_ENUM,
	SYM_TYPEDEF,
	SYM_TYPEOF,
	SYM_MEMBER,
	SYM_BITFIELD,
	SYM_LABEL,
	SYM_RESTRICT,
	SYM_FOULED,
	SYM_KEYWORD,
	SYM_BAD,
};

enum keyword {
	KW_SPECIFIER 	= 1 << 0,
	KW_MODIFIER	= 1 << 1,
	KW_QUALIFIER	= 1 << 2,
	KW_ATTRIBUTE	= 1 << 3,
	KW_STATEMENT	= 1 << 4,
	KW_ASM		= 1 << 5,
	KW_MODE		= 1 << 6,
	KW_SHORT	= 1 << 7,
	KW_LONG		= 1 << 8,
	KW_EXACT	= 1 << 9,
};

struct sym_context {
	struct expression *context;
	unsigned int in, out;
};

extern struct sym_context *alloc_context(SCTX);

DECLARE_PTR_LIST(context_list, struct sym_context);

struct ctype {
	unsigned long modifiers;
	unsigned long alignment;
	struct context_list *contexts;
	unsigned int as;
	struct symbol *base_type;
};

struct decl_state {
	struct ctype ctype;
	struct ident **ident;
	struct symbol_op *mode;
	unsigned char prefer_abstract, is_inline, storage_class, is_tls;
};

struct symbol_op {
	enum keyword type;
	int (*evaluate)(SCTX_ struct expression *);
	int (*expand)(SCTX_ struct expression *, int);
	int (*args)(SCTX_ struct expression *);

	/* keywords */
	struct token *(*declarator)(SCTX_ struct token *token, struct decl_state *ctx);
	struct token *(*statement)(SCTX_ struct token *token, struct statement *stmt);
	struct token *(*toplevel)(SCTX_ struct token *token, struct symbol_list **list);
	struct token *(*attribute)(SCTX_ struct token *token, struct symbol *attr, struct decl_state *ctx);
	struct symbol *(*to_mode)(SCTX_ struct symbol *);

	int test, set, class;
};

extern int expand_safe_p(SCTX_ struct expression *expr, int cost);
extern int expand_constant_p(SCTX_ struct expression *expr, int cost);

#define SYM_ATTR_WEAK		0
#define SYM_ATTR_NORMAL		1
#define SYM_ATTR_STRONG		2

struct symbol {
#ifdef DO_CTX
	struct sparse_ctx *ctx;
#endif
	enum type type:8;
	enum namespace namespace:9;
	unsigned char used:1, attr:2, enum_member:1, bound:1;
	struct token *tok;
	struct token *pos;		/* Where this symbol was declared */
	struct token *endpos;		/* Where this symbol ends*/
	struct ident *ident;		/* What identifier this symbol is associated with */
	struct symbol *next_id;		/* Next semantic symbol that shares this identifier */
	struct symbol	*replace;	/* What is this symbol shadowed by in copy-expression */
	struct scope	*scope;
	union {
		struct symbol	*same_symbol;
		struct symbol	*next_subobject;
	};

	struct symbol_op *op;

	union {
		struct /* NS_MACRO */ {
			struct token *expansion;
			struct token *arglist;
			struct scope *used_in;
		};
		struct /* NS_PREPROCESSOR */ {
			int (*handler)(SCTX_ struct stream *, struct token **, struct token *);
			int normal;
		};
		struct /* NS_SYMBOL */ {
			unsigned long	offset;
			int		bit_size;
			unsigned int	bit_offset:8,
					arg_count:10,
					variadic:1,
					initialized:1,
					examined:1,
					expanding:1,
					evaluated:1,
					string:1,
					designated_init:1,
					forced_arg:1;
			struct expression *array_size;
			struct ctype ctype;
			struct symbol_list *arguments;
			struct statement *stmt;
			struct symbol_list *symbol_list;
			struct statement *inline_stmt;
			struct symbol_list *inline_symbol_list;
			struct expression *initializer;
			struct entrypoint *ep;
			long long value;		/* Initial value */
			struct symbol *definition;
		};
	};
	union /* backend */ {
		struct basic_block *bb_target;	/* label */
		void *aux;			/* Auxiliary info, e.g. backend information */
		struct {			/* sparse ctags */
			char kind;
			unsigned char visited:1;
		};
	};
	pseudo_t pseudo;
};

/* Modifiers */
#define MOD_AUTO	0x0001
#define MOD_REGISTER	0x0002
#define MOD_STATIC	0x0004
#define MOD_EXTERN	0x0008

#define MOD_CONST	0x0010
#define MOD_VOLATILE	0x0020
#define MOD_SIGNED	0x0040
#define MOD_UNSIGNED	0x0080

#define MOD_CHAR	0x0100
#define MOD_SHORT	0x0200
#define MOD_LONG	0x0400
#define MOD_LONGLONG	0x0800
#define MOD_LONGLONGLONG	0x1000
#define MOD_PURE	0x2000

#define MOD_TYPEDEF	0x10000

#define MOD_TLS		0x20000
#define MOD_INLINE	0x40000
#define MOD_ADDRESSABLE	0x80000

#define MOD_NOCAST	0x100000
#define MOD_NODEREF	0x200000
#define MOD_ACCESSED	0x400000
#define MOD_TOPLEVEL	0x800000	// scoping..

#define MOD_ASSIGNED	0x2000000
#define MOD_TYPE	0x4000000
#define MOD_SAFE	0x8000000	// non-null/non-trapping pointer

#define MOD_USERTYPE	0x10000000
#define MOD_NORETURN	0x20000000
#define MOD_EXPLICITLY_SIGNED	0x40000000
#define MOD_BITWISE	0x80000000


#define MOD_NONLOCAL	(MOD_EXTERN | MOD_TOPLEVEL)
#define MOD_STORAGE	(MOD_AUTO | MOD_REGISTER | MOD_STATIC | MOD_EXTERN | MOD_INLINE | MOD_TOPLEVEL)
#define MOD_SIGNEDNESS	(MOD_SIGNED | MOD_UNSIGNED | MOD_EXPLICITLY_SIGNED)
#define MOD_LONG_ALL	(MOD_LONG | MOD_LONGLONG | MOD_LONGLONGLONG)
#define MOD_SPECIFIER	(MOD_CHAR | MOD_SHORT | MOD_LONG_ALL | MOD_SIGNEDNESS)
#define MOD_SIZE	(MOD_CHAR | MOD_SHORT | MOD_LONG_ALL)
#define MOD_IGNORE (MOD_TOPLEVEL | MOD_STORAGE | MOD_ADDRESSABLE |	\
	MOD_ASSIGNED | MOD_USERTYPE | MOD_ACCESSED | MOD_EXPLICITLY_SIGNED)
#define MOD_PTRINHERIT (MOD_VOLATILE | MOD_CONST | MOD_NODEREF | MOD_STORAGE | MOD_NORETURN)

#endif /* SYMBOL_H */
