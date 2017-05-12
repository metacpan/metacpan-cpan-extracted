/*
 * Symbol scoping.
 *
 * This is pretty trivial.
 *
 * Copyright (C) 2003 Transmeta Corp.
 *               2003-2004 Linus Torvalds
 *
 *  Licensed under the Open Software License version 1.1
 */
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "lib.h"
#include "allocate.h"
#include "symbol.h"
#include "scope.h"

#ifndef DO_CTX
static struct scope builtin_scope = { .next = &builtin_scope };

struct scope	*block_scope = &builtin_scope,		// regular automatic variables etc
		*function_scope = &builtin_scope,	// labels, arguments etc
		*file_scope = &builtin_scope,		// static
		*global_scope = &builtin_scope;		// externally visible
#else
void sparse_ctx_init_scope(SCTX) {
	sctxp builtin_scope.next =  &sctxp builtin_scope;
	sctxp block_scope = &sctxp builtin_scope;		// regular automatic variables etc
	sctxp function_scope = &sctxp builtin_scope;	// labels, arguments etc
	sctxp file_scope = &sctxp builtin_scope;		// static
	sctxp global_scope = &sctxp builtin_scope;		// externally visible
}
#endif

void bind_scope(SCTX_ struct symbol *sym, struct scope *scope)
{
	sym->scope = scope;
	add_symbol(sctx_ &scope->symbols, sym);
}

static void start_scope(SCTX_ struct scope **s)
{
	struct scope *scope = __alloc_scope(sctx_ 0);
	memset(scope, 0, sizeof(*scope));
	scope->next = *s;
	*s = scope;
}

void start_file_scope(SCTX)
{
	struct scope *scope = __alloc_scope(sctx_ 0);

	memset(scope, 0, sizeof(*scope));
	scope->next = &sctxp builtin_scope;
	sctxp file_scope = scope;

	/* top-level stuff defaults to file scope, "extern" etc will choose global scope */
	sctxp function_scope = scope;
	sctxp block_scope = scope;
}

void start_symbol_scope(SCTX)
{
	start_scope(sctx_ &sctxp block_scope);
}

void start_function_scope(SCTX)
{
	start_scope(sctx_ &sctxp function_scope);
	start_scope(sctx_ &sctxp block_scope);
}

static void remove_symbol_scope(SCTX_ struct symbol *sym)
{
	struct symbol **ptr = &sym->ident->symbols;

	while (*ptr != sym)
		ptr = &(*ptr)->next_id;
	*ptr = sym->next_id;
}

static void end_scope(SCTX_ struct scope **s)
{
	struct scope *scope = *s;
	struct symbol_list *symbols = scope->symbols;
	struct symbol *sym;

	*s = scope->next;
	scope->symbols = NULL;
	FOR_EACH_PTR(symbols, sym) {
		remove_symbol_scope(sctx_ sym);
	} END_FOR_EACH_PTR(sym);
}

void end_file_scope(SCTX)
{
	end_scope(sctx_ &sctxp file_scope);
}

void new_file_scope(SCTX)
{
	if (sctxp file_scope != &sctxp builtin_scope)
		end_file_scope(sctx );
	start_file_scope(sctx);
}

void end_symbol_scope(SCTX)
{
	end_scope(sctx_ &sctxp block_scope);
}

void end_function_scope(SCTX)
{
	end_scope(sctx_ &sctxp block_scope);
	end_scope(sctx_ &sctxp function_scope);
}

int is_outer_scope(SCTX_ struct scope *scope)
{
	if (scope == sctxp block_scope)
		return 0;
	if (scope == &sctxp builtin_scope && sctxp block_scope->next == &sctxp builtin_scope)
		return 0;
	return 1;
}
