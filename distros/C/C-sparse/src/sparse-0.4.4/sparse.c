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

static int context_increase(SCTX_ struct basic_block *bb, int entry)
{
	int sum = 0;
	struct instruction *insn;

	FOR_EACH_PTR(bb->insns, insn) {
		int val;
		if (insn->opcode != OP_CONTEXT)
			continue;
		val = insn->increment;
		if (insn->check) {
			int current = sum + entry;
			if (!val) {
				if (!current)
					continue;
			} else if (current >= val)
				continue;
			warning(sctx_ insn->pos, "context check failure");
			continue;
		}
		sum += val;
	} END_FOR_EACH_PTR(insn);
	return sum;
}

static int imbalance(SCTX_ struct entrypoint *ep, struct basic_block *bb, int entry, int exit, const char *why)
{
	if (sctxp Wcontext) {
		struct symbol *sym = ep->name;
		warning(sctx_ bb->pos->pos, "context imbalance in '%s' - %s", show_ident(sctx_ sym->ident), why);
	}
	return -1;
}

static int check_bb_context(SCTX_ struct entrypoint *ep, struct basic_block *bb, int entry, int exit);

static int check_children(SCTX_ struct entrypoint *ep, struct basic_block *bb, int entry, int exit)
{
	struct instruction *insn;
	struct basic_block *child;

	insn = last_instruction(sctx_ bb->insns);
	if (!insn)
		return 0;
	if (insn->opcode == OP_RET)
		return entry != exit ? imbalance(sctx_ ep, bb, entry, exit, "wrong count at exit") : 0;

	FOR_EACH_PTR(bb->children, child) {
		if (check_bb_context(sctx_ ep, child, entry, exit))
			return -1;
	} END_FOR_EACH_PTR(child);
	return 0;
}

static int check_bb_context(SCTX_ struct entrypoint *ep, struct basic_block *bb, int entry, int exit)
{
	if (!bb)
		return 0;
	if (bb->context == entry)
		return 0;

	/* Now that's not good.. */
	if (bb->context >= 0)
		return imbalance(sctx_ ep, bb, entry, bb->context, "different lock contexts for basic block");

	bb->context = entry;
	entry += context_increase(sctx_ bb, entry);
	if (entry < 0)
		return imbalance(sctx_ ep, bb, entry, exit, "unexpected unlock");

	return check_children(sctx_ ep, bb, entry, exit);
}

static void check_cast_instruction(SCTX_ struct instruction *insn)
{
	struct symbol *orig_type = insn->orig_type;
	if (orig_type) {
		int old = orig_type->bit_size;
		int new = insn->size;
		int oldsigned = (orig_type->ctype.modifiers & MOD_SIGNED) != 0;
		int newsigned = insn->opcode == OP_SCAST;

		if (new > old) {
			if (oldsigned == newsigned)
				return;
			if (newsigned)
				return;
			warning(sctx_ insn->pos, "cast loses sign");
			return;
		}
		if (new < old) {
			warning(sctx_ insn->pos, "cast drops bits");
			return;
		}
		if (oldsigned == newsigned) {
			warning(sctx_ insn->pos, "cast wasn't removed");
			return;
		}
		warning(sctx_ insn->pos, "cast changes sign");
	}
}

static void check_range_instruction(SCTX_ struct instruction *insn)
{
	warning(sctx_ insn->pos, "value out of range");
}

static void check_byte_count(SCTX_ struct instruction *insn, pseudo_t count)
{
	if (!count)
		return;
	if (count->type == PSEUDO_VAL) {
		long long val = count->value;
		if (val <= 0 || val > 100000)
			warning(sctx_ insn->pos, "%s with byte count of %lld",
				show_ident(sctx_ insn->func->sym->ident), val);
		return;
	}
	/* OK, we could try to do the range analysis here */
}

static pseudo_t argument(SCTX_ struct instruction *call, unsigned int argno)
{
	pseudo_t args[8];
	struct ptr_list *arg_list = (struct ptr_list *) call->arguments;

	argno--;
	if (linearize_ptr_list(sctx_ arg_list, (void *)args, 8) > argno)
		return args[argno];
	return NULL;
}

static void check_memset(SCTX_ struct instruction *insn)
{
	check_byte_count(sctx_ insn, argument(sctx_ insn, 3));
}

#define check_memcpy check_memset
#define check_ctu check_memset
#define check_cfu check_memset

struct checkfn {
	struct ident *id;
	void (*check)(SCTX_ struct instruction *insn);
};

static void check_call_instruction(SCTX_ struct instruction *insn)
{
	pseudo_t fn = insn->func;
	struct ident *ident;
	/*static*/ const struct checkfn check_fn[] = {
		{ (struct ident *)&sctxp memset_ident, check_memset },
		{ (struct ident *)&sctxp memcpy_ident, check_memcpy },
		{ (struct ident *)&sctxp copy_to_user_ident, check_ctu },
		{ (struct ident *)&sctxp copy_from_user_ident, check_cfu },
	};
	int i;

	if (fn->type != PSEUDO_SYM)
		return;
	ident = fn->sym->ident;
	if (!ident)
		return;
	for (i = 0; i < ARRAY_SIZE(check_fn); i++) {
		if (check_fn[i].id != ident)
			continue;
		check_fn[i].check(sctx_ insn);
		break;
	}
}

static void check_one_instruction(SCTX_ struct instruction *insn)
{
	switch (insn->opcode) {
	case OP_CAST: case OP_SCAST:
		if (sctxp verbose)
			check_cast_instruction(sctx_ insn);
		break;
	case OP_RANGE_LIN:
		check_range_instruction(sctx_ insn);
		break;
	case OP_CALL:
		check_call_instruction(sctx_ insn);
		break;
	default:
		break;
	}
}

static void check_bb_instructions(SCTX_ struct basic_block *bb)
{
	struct instruction *insn;
	FOR_EACH_PTR(bb->insns, insn) {
		if (!insn->bb)
			continue;
		check_one_instruction(sctx_ insn);
	} END_FOR_EACH_PTR(insn);
}

static void check_instructions(SCTX_ struct entrypoint *ep)
{
	struct basic_block *bb;
	FOR_EACH_PTR(ep->bbs, bb) {
		check_bb_instructions(sctx_ bb);
	} END_FOR_EACH_PTR(bb);
}

static void check_context(SCTX_ struct entrypoint *ep)
{
	struct symbol *sym = ep->name;
	struct sym_context *context;
	unsigned int in_context = 0, out_context = 0;

	if (sctxp Wuninitialized && sctxp verbose && ep->entry->bb->needs) {
		pseudo_t pseudo;
		FOR_EACH_PTR(ep->entry->bb->needs, pseudo) {
			if (pseudo->type != PSEUDO_ARG)
				warning(sctx_ sym->pos->pos, "%s: possible uninitialized variable (%s)",
					show_ident(sctx_ sym->ident), show_pseudo(sctx_ pseudo));
		} END_FOR_EACH_PTR(pseudo);
	}

	check_instructions(sctx_ ep);

	FOR_EACH_PTR(sym->ctype.contexts, context) {
		in_context += context->in;
		out_context += context->out;
	} END_FOR_EACH_PTR(context);
	check_bb_context(sctx_ ep, ep->entry->bb, in_context, out_context);
}

static void check_symbols(SCTX_ struct symbol_list *list)
{
	struct symbol *sym;

	FOR_EACH_PTR(list, sym) {
		struct entrypoint *ep;

		expand_symbol(sctx_ sym);
		ep = linearize_symbol(sctx_ sym);
		if (ep) {
			if (sctxp dbg_entry)
				show_entry(sctx_ ep);

			check_context(sctx_ ep);
		}
	} END_FOR_EACH_PTR(sym);
}

int main(int argc, char **argv)
{
	struct string_list *filelist = NULL;
	char *file; SPARSE_CTX_INIT;

	// Expand, linearize and show it.
	check_symbols(sctx_ sparse_initialize(sctx_ argc, argv, &filelist));
	FOR_EACH_PTR_NOTAG(filelist, file) {
		check_symbols(sctx_ sparse(sctx_ file));
	} END_FOR_EACH_PTR_NOTAG(file);
	return 0;
}
