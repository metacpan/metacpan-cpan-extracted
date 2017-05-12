
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <fcntl.h>

#include "lib.h"
#include "allocate.h"
#include "token.h"
#include "parse.h"
#include "symbol.h"
#include "expression.h"

#include "ast-view.h"

static void expand_symbols(SCTX_ struct symbol_list *list)
{
	struct symbol *sym;
	FOR_EACH_PTR(list, sym) {
		expand_symbol(sctx_ sym);
	} END_FOR_EACH_PTR(sym);
}

int main(int argc, char **argv)
{
	struct string_list *filelist = NULL; 
	char *file; 
	struct symbol_list *view_syms = NULL;
	SPARSE_CTX_INIT;

	gtk_init(&argc,&argv);
	expand_symbols(sctx_ sparse_initialize(sctx_ argc, argv, &filelist));
	FOR_EACH_PTR_NOTAG(filelist, file) {
		struct symbol_list *syms = sparse(sctx_ file);
		expand_symbols(sctx_ syms);
		concat_symbol_list(sctx_ syms, &view_syms);
	} END_FOR_EACH_PTR_NOTAG(file);
	treeview_main(sctx_ view_syms);
	return 0;
}
 
