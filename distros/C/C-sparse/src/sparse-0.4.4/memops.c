/*
 * memops - try to combine memory ops.
 *
 * Copyright (C) 2004 Linus Torvalds
 */

#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <assert.h>

#include "parse.h"
#include "expression.h"
#include "linearize.h"
#include "flow.h"

static int find_dominating_parents_mem(SCTX_ pseudo_t pseudo, struct instruction *insn,
	struct basic_block *bb, unsigned long generation, struct pseudo_list **dominators,
	int local, int loads)
{
	struct basic_block *parent;

	if (bb_list_size(sctx_ bb->parents) > 1)
		loads = 0;
	FOR_EACH_PTR(bb->parents, parent) {
		struct instruction *one;
		struct instruction *br;
		pseudo_t phi;

		FOR_EACH_PTR_REVERSE(parent->insns, one) {
			int dominance;
			if (one == insn)
				goto no_dominance;
			dominance = dominates(sctx_ pseudo, insn, one, local);
			if (dominance < 0) {
				if (one->opcode == OP_LOAD)
					continue;
				return 0;
			}
			if (!dominance)
				continue;
			if (one->opcode == OP_LOAD && !loads)
				continue;
			goto found_dominator;
		} END_FOR_EACH_PTR_REVERSE(one);
no_dominance:
		if (parent->generation == generation)
			continue;
		parent->generation = generation;

		if (!find_dominating_parents_mem(sctx_ pseudo, insn, parent, generation, dominators, local, loads))
			return 0;
		continue;

found_dominator:
		br = delete_last_instruction(sctx_ &parent->insns);
		phi = alloc_phi(sctx_ parent, one->target, one->size);
		phi->ident = phi->ident ? : one->target->ident;
		add_instruction(sctx_ &parent->insns, br);
		use_pseudo(sctx_ insn, phi, add_pseudo(sctx_ dominators, phi));
	} END_FOR_EACH_PTR(parent);
	return 1;
}		

static int address_taken(SCTX_ pseudo_t pseudo)
{
	struct pseudo_user *pu;
	FOR_EACH_PTR(pseudo->users, pu) {
		struct instruction *insn = pu->insn;
		if (insn->bb && (insn->opcode != OP_LOAD && insn->opcode != OP_STORE))
			return 1;
	} END_FOR_EACH_PTR(pu);
	return 0;
}

static int local_pseudo(SCTX_ pseudo_t pseudo)
{
	return pseudo->type == PSEUDO_SYM
		&& !(pseudo->sym->ctype.modifiers & (MOD_STATIC | MOD_NONLOCAL))
		&& !address_taken(sctx_ pseudo);
}

static void simplify_loads(SCTX_ struct basic_block *bb)
{
	struct instruction *insn;

	FOR_EACH_PTR_REVERSE(bb->insns, insn) {
		if (!insn->bb)
			continue;
		if (insn->opcode == OP_LOAD) {
			struct instruction *dom;
			pseudo_t pseudo = insn->src;
			int local = local_pseudo(sctx_ pseudo);
			struct pseudo_list *dominators;
			unsigned long generation;

			/* Check for illegal offsets.. */
			check_access(sctx_ insn);

			RECURSE_PTR_REVERSE(insn, dom) {
				int dominance;
				if (!dom->bb)
					continue;
				dominance = dominates(sctx_ pseudo, insn, dom, local);
				if (dominance) {
					/* possible partial dominance? */
					if (dominance < 0)  {
						if (dom->opcode == OP_LOAD)
							continue;
						goto next_load;
					}
					/* Yeehaa! Found one! */
					convert_load_instruction(sctx_ insn, dom->target);
					goto next_load;
				}
			} END_FOR_EACH_PTR_REVERSE(dom);

			/* OK, go find the parents */
			generation = ++sctxp bb_generation;
			bb->generation = generation;
			dominators = NULL;
			if (find_dominating_parents_mem(sctx_ pseudo, insn, bb, generation, &dominators, local, 1)) {
				/* This happens with initial assignments to structures etc.. */
				if (!dominators) {
					if (local) {
						assert(pseudo->type != PSEUDO_ARG);
						convert_load_instruction(sctx_ insn, value_pseudo(sctx_ 0));
					}
					goto next_load;
				}
				rewrite_load_instruction(sctx_ insn, dominators);
			}
		}
next_load:
		/* Do the next one */;
	} END_FOR_EACH_PTR_REVERSE(insn);
}

static void kill_store_mem(SCTX_ struct instruction *insn)
{
	if (insn) {
		insn->bb = NULL;
		insn->opcode = OP_SNOP;
		kill_use(sctx_ &insn->target);
	}
}

static void kill_dominated_stores_mem(SCTX_ struct basic_block *bb)
{
	struct instruction *insn;

	FOR_EACH_PTR_REVERSE(bb->insns, insn) {
		if (!insn->bb)
			continue;
		if (insn->opcode == OP_STORE) {
			struct instruction *dom;
			pseudo_t pseudo = insn->src;
			int local = local_pseudo(sctx_ pseudo);

			RECURSE_PTR_REVERSE(insn, dom) {
				int dominance;
				if (!dom->bb)
					continue;
				dominance = dominates(sctx_ pseudo, insn, dom, local);
				if (dominance) {
					/* possible partial dominance? */
					if (dominance < 0)
						goto next_store;
					if (dom->opcode == OP_LOAD)
						goto next_store;
					/* Yeehaa! Found one! */
					kill_store_mem(sctx_ dom);
				}
			} END_FOR_EACH_PTR_REVERSE(dom);

			/* OK, we should check the parents now */
		}
next_store:
		/* Do the next one */;
	} END_FOR_EACH_PTR_REVERSE(insn);
}

void simplify_memops(SCTX_ struct entrypoint *ep)
{
	struct basic_block *bb;

	FOR_EACH_PTR_REVERSE(ep->bbs, bb) {
		simplify_loads(sctx_ bb);
	} END_FOR_EACH_PTR_REVERSE(bb);

	FOR_EACH_PTR_REVERSE(ep->bbs, bb) {
		kill_dominated_stores_mem(sctx_ bb);
	} END_FOR_EACH_PTR_REVERSE(bb);
}
