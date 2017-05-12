#ifndef	DISSECT_H
#define	DISSECT_H

#include <stdio.h>
#include "parse.h"
#include "expression.h"

#define	U_SHIFT		8

#define	U_R_AOF		0x01
#define	U_W_AOF		0x02

#define	U_R_VAL		0x04
#define	U_W_VAL		0x08

#define	U_R_PTR		(U_R_VAL << U_SHIFT)
#define	U_W_PTR		(U_W_VAL << U_SHIFT)

enum {
	REPORT_SYMBOL,
	REPORT_MEMBER,
	REPORT_SYMDEF
};

struct reporter_def {
	int type, indent;
	union {
		struct {
			struct symbol *sym;
		};
		struct {
			unsigned sym_mode;
			struct token *sym_pos;
			struct symbol *sym_sym;
		};
		struct {
			unsigned mem_mode;
			struct token *mem_pos;
			struct symbol *mem_sym;
			struct symbol *mem_mem;
		};
	};
};

struct reporter
{
	void (*r_symdef)(SCTX_ struct symbol *);
	void (*r_symbol)(SCTX_ unsigned, struct token *, struct symbol *);
	void (*r_member)(SCTX_ unsigned, struct token *, struct symbol *, struct symbol *);
	struct reporter_symdef **defs; int defs_pos, defs_cnt;
	int indent;
};

#ifndef DO_CTX
extern struct reporter *reporter;
#endif

extern void dissect(SCTX_ struct symbol_list *, struct reporter *);
extern int dissect_arr(SCTX_ int argc, char **argv);

#define	MK_IDENT(s)	({				\
	static struct {					\
		struct ident ident;			\
		char __[sizeof(s)];			\
	} ident = {{					\
		.len  = sizeof(s)-1,			\
		.name = s,				\
	}};						\
	&ident.ident;					\
})

#endif
