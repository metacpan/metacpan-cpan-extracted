/*
 * Example trivial client program that uses the sparse library
 * to tokenize, preprocess and parse a C file, and prints out
 * the results.
 *
 * Copyright (C) 2003 Transmeta Corp.
 *               2003-2004 Linus Torvalds
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
#include "linearize.h"

static void emit_entrypoint(SCTX_ struct entrypoint *ep)
{
	
}

static void emit_symbol(SCTX_ struct symbol *sym)
{
	struct entrypoint *ep;
	ep = linearize_symbol(sctx_ sym);
	if (ep)
		emit_entrypoint(sctx_ ep);
}

static void emit_symbol_list(SCTX_ struct symbol_list *list)
{
	struct symbol *sym;

	FOR_EACH_PTR(list, sym) {
		expand_symbol(sctx_ sym);
		emit_symbol(sctx_ sym);
	} END_FOR_EACH_PTR(sym);
}

int main(int argc, char **argv)
{
	struct string_list *filelist = NULL;
	char *file; SPARSE_CTX_INIT;

	emit_symbol_list(sctx_ sparse_initialize(sctx_ argc, argv, &filelist));
	FOR_EACH_PTR_NOTAG(filelist, file) {
		emit_symbol_list(sctx_ sparse(sctx_ file));
	} END_FOR_EACH_PTR_NOTAG(file);
	return 0;
}
