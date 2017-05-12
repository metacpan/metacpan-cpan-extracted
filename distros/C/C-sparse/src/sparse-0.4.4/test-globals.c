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
	char *file;  void *ptr;
	struct symbol *sym, *symbt;
	struct symbol_list *view_syms = NULL;
	SPARSE_CTX_INIT;
	
	expand_symbols(sctx_ sparse_initialize(sctx_ argc, argv, &filelist));
	FOR_EACH_PTR_NOTAG(filelist, file) {
		printf("%s:\n",file);
		struct symbol_list *syms = sparse(sctx_ file);
		expand_symbols(sctx_ syms);
		
		FOR_EACH_PTR(((struct ptr_list *)syms), ptr) {
			sym = (struct symbol *) ptr; struct ident *i; const char *n;
			if (sym->type == SYM_NODE) {
				if ((symbt = sym->ctype.base_type)) {
					if (symbt->type != SYM_FN ) {
						n = show_ident(sctx_ i = sym->ident);
						printf(" +%s\n",n);
					} else {
						const char *n = show_typename_fn(sctx_ sym->ctype.base_type);
						//printf(" -%s\n",n);
						free((char *)n);
					}
				}
				
			}
		} END_FOR_EACH_PTR(ptr);
		
		concat_symbol_list(sctx_ syms, &view_syms);
	} END_FOR_EACH_PTR_NOTAG(file);
	
	return 0;
}


