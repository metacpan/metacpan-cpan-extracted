/*
 * Example trivial client program that uses the sparse library
 * and x86 backend.
 *
 * Copyright (C) 2003 Transmeta Corp.
 *               2003 Linus Torvalds
 * Copyright 2003 Jeff Garzik
 *
 *  Licensed under the Open Software License version 1.1
 *
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
#include "compile.h"

static void clean_up_symbols(SCTX_ struct symbol_list *list)
{
	struct symbol *sym;

	FOR_EACH_PTR(list, sym) {
		expand_symbol(sctx_ sym);
		emit_one_symbol(sctx_ sym);
	} END_FOR_EACH_PTR(sym);
}

int main(int argc, char **argv)
{
	char *file;
	struct string_list *filelist = NULL;
	SPARSE_CTX_INIT;

	clean_up_symbols(sctx_ sparse_initialize(sctx_ argc, argv, &filelist));
	FOR_EACH_PTR_NOTAG(filelist, file) {
		struct symbol_list *list;
		const char *basename = strrchr(file, '/');
		basename = basename ?  basename+1 : file;

		list = sparse(sctx_ file);

		// Do type evaluation and simplification
		emit_unit_begin(sctx_ basename);
		clean_up_symbols(sctx_ list);
		emit_unit_end(sctx );
	} END_FOR_EACH_PTR_NOTAG(file);

#if 0
	// And show the allocation statistics
	show_ident_alloc(&sctx);
	show_token_alloc(&sctx);
	show_symbol_alloc(&sctx);
	show_expression_alloc(&sctx);
	show_statement_alloc(&sctx);
	show_string_alloc(&sctx);
	show_bytes_alloc(&sctx);
#endif
	return 0;
}
