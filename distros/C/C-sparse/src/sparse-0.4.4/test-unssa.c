#include <stdio.h>
#include <assert.h>

#include "symbol.h"
#include "expression.h"
#include "linearize.h"
#include "flow.h"


static void output_bb(SCTX_ struct basic_block *bb, unsigned long generation)
{
	struct instruction *insn;

	bb->generation = generation;
	printf(".L%p\n", bb);

	FOR_EACH_PTR(bb->insns, insn) {
		if (!insn->bb)
			continue;
		printf("\t%s\n", show_instruction(sctx_ insn));
	}
	END_FOR_EACH_PTR(insn);

	printf("\n");
}

static void output_fn(SCTX_ struct entrypoint *ep)
{
	struct basic_block *bb;
	unsigned long generation = ++sctxp bb_generation;
	struct symbol *sym = ep->name;
	const char *name = show_ident(sctx_ sym->ident);

	if (sym->ctype.modifiers & MOD_STATIC)
		printf("\n\n%s:\n", name);
	else
		printf("\n\n.globl %s\n%s:\n", name, name);

	unssa(sctx_ ep);

	FOR_EACH_PTR(ep->bbs, bb) {
		if (bb->generation == generation)
			continue;
		output_bb(sctx_ bb, generation);
	}
	END_FOR_EACH_PTR(bb);
}

static int output_data(SCTX_ struct symbol *sym)
{
	printf("symbol %s:\n", show_ident(sctx_ sym->ident));
	printf("\ttype = %d\n", sym->ctype.base_type->type);
	printf("\tmodif= %lx\n", sym->ctype.modifiers);

	return 0;
}

static int compile(SCTX_ struct symbol_list *list)
{
	struct symbol *sym;
	FOR_EACH_PTR(list, sym) {
		struct entrypoint *ep;
		expand_symbol(sctx_ sym);
		ep = linearize_symbol(sctx_ sym);
		if (ep)
			output_fn(sctx_ ep);
		else
			output_data(sctx_ sym);
	}
	END_FOR_EACH_PTR(sym);

	return 0;
}

int main(int argc, char **argv)
{
	struct string_list * filelist = NULL;
	char *file; 
	SPARSE_CTX_INIT;

	compile(sctx_ sparse_initialize(sctx_ argc, argv, &filelist));
	FOR_EACH_PTR_NOTAG(filelist, file) {
		compile(sctx_ sparse(sctx_ file));
	} END_FOR_EACH_PTR_NOTAG(file);

	return 0;
}
