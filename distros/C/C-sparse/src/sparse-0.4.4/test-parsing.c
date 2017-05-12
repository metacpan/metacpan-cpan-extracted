/*
 * Example trivial client program that uses the sparse library
 * to tokenize, preprocess and parse a C file, and prints out
 * the results.
 *
 * Copyright (C) 2003 Transmeta Corp.
 *               2003 Linus Torvalds
 *
 *  Licensed under the Open Software License version 1.1
 */
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

static void clean_up_symbols(SCTX_ struct symbol_list *list)
{
	struct symbol *sym;

	FOR_EACH_PTR(list, sym) {
		expand_symbol(sctx_ sym);
	} END_FOR_EACH_PTR(sym);
}

int main(int argc, char **argv)
{
	struct symbol_list * list;
	struct string_list * filelist = NULL;
	char *file; SPARSE_CTX_INIT;

	list = sparse_initialize(sctx_ argc, argv, &filelist);

	// Simplification
	clean_up_symbols(sctx_ list);

#if 1
	show_symbol_list(sctx_ list, "\n\n");
	printf("\n\n");
#endif

	FOR_EACH_PTR_NOTAG(filelist, file) {
		list = sparse(sctx_ file);

		// Simplification
		clean_up_symbols(sctx_ list);

#if 1
		// Show the end result.
		show_symbol_list(sctx_ list, "\n\n");
		printf("\n\n");
#endif
	} END_FOR_EACH_PTR_NOTAG(file);

#if 0
	// And show the allocation statistics
	show_ident_alloc(sctx);
	show_token_alloc(sctx);
	show_symbol_alloc(sctx);
	show_expression_alloc(sctx);
	show_statement_alloc(sctx);
	show_string_alloc(sctx);
	show_bytes_alloc(sctx);
#endif
	return 0;
}
