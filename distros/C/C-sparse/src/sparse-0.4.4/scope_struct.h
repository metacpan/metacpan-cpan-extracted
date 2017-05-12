#ifndef SCOPE_STRUCT_H
#define SCOPE_STRUCT_H
/*
 * Symbol scoping is pretty simple.
 *
 * Copyright (C) 2003 Transmeta Corp.
 *               2003 Linus Torvalds
 *
 *  Licensed under the Open Software License version 1.1
 */

struct symbol;

struct scope {
	struct token *token;		/* Scope start information */
	struct symbol_list *symbols;	/* List of symbols in this scope */
	struct scope *next;
};

#endif
