/*
 * sparse/expand.c
 *
 * Copyright (C) 2003 Transmeta Corp.
 *               2003-2004 Linus Torvalds
 *
 *  Licensed under the Open Software License version 1.1
 *
 * expand constant expressions.
 */
#include <stdlib.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <fcntl.h>
#include <limits.h>

#include "lib.h"
#include "allocate.h"
#include "parse.h"
#include "token.h"
#include "symbol.h"
#include "target.h"
#include "expression.h"

/* Random cost numbers */
#define SIDE_EFFECTS 10000	/* The expression has side effects */
#define UNSAFE 100		/* The expression may be "infinitely costly" due to exceptions */
#define SELECT_COST 20		/* Cut-off for turning a conditional into a select */
#define BRANCH_COST 10		/* Cost of a conditional branch */

static int expand_expression(SCTX_ struct expression *);
static int expand_statement(SCTX_ struct statement *);
#ifndef DO_CTX
static int conservative;
#endif

static int expand_symbol_expression(SCTX_ struct expression *expr)
{
	struct symbol *sym = expr->symbol;

	if (sym == &sctxp zero_int) {
		if (sctxp Wundef)
			warning(sctx_ expr->pos->pos, "undefined preprocessor identifier '%s'", show_ident(sctx_ expr->symbol_name));
		expr->type = EXPR_VALUE;
		expr->value = 0;
		expr->taint = 0;
		return 0;
	}
	/* The cost of a symbol expression is lower for on-stack symbols */
	return (sym->ctype.modifiers & (MOD_STATIC | MOD_EXTERN)) ? 2 : 1;
}

static long long get_longlong(SCTX_ struct expression *expr)
{
	int no_expand = expr->ctype->ctype.modifiers & MOD_UNSIGNED;
	long long mask = 1ULL << (expr->ctype->bit_size - 1);
	long long value = expr->value;
	long long ormask, andmask;

	if (!(value & mask))
		no_expand = 1;
	andmask = mask | (mask-1);
	ormask = ~andmask;
	if (no_expand)
		ormask = 0;
	return (value & andmask) | ormask;
}

void cast_value(SCTX_ struct expression *expr, struct symbol *newtype,
		struct expression *old, struct symbol *oldtype)
{
	int old_size = oldtype->bit_size;
	int new_size = newtype->bit_size;
	long long value, mask, signmask;
	long long oldmask, oldsignmask, dropped;

	if (newtype->ctype.base_type == &sctxp fp_type ||
	    oldtype->ctype.base_type == &sctxp fp_type)
		goto Float;

	// For pointers and integers, we can just move the value around
	expr->type = EXPR_VALUE;
	expr->taint = old->taint;
	if (old_size == new_size) {
		expr->value = old->value;
		return;
	}

	// expand it to the full "long long" value
	value = get_longlong(sctx_ old);

Int:
	// _Bool requires a zero test rather than truncation.
	if (is_bool_type(sctx_ newtype)) {
		expr->value = !!value;
		if (!sctxp conservative && value != 0 && value != 1)
			warning(sctx_ old->pos->pos, "odd constant _Bool cast (%llx becomes 1)", value);
		return;
	}

	// Truncate it to the new size
	signmask = 1ULL << (new_size-1);
	mask = signmask | (signmask-1);
	expr->value = value & mask;

	// Stop here unless checking for truncation
	if (!sctxp Wcast_truncate || sctxp conservative)
		return;
	
	// Check if we dropped any bits..
	oldsignmask = 1ULL << (old_size-1);
	oldmask = oldsignmask | (oldsignmask-1);
	dropped = oldmask & ~mask;

	// OK if the bits were (and still are) purely sign bits
	if (value & dropped) {
		if (!(value & oldsignmask) || !(value & signmask) || (value & dropped) != dropped)
			warning(sctx_ old->pos->pos, "cast truncates bits from constant value (%llx becomes %llx)",
				value & oldmask,
				value & mask);
	}
	return;

Float:
	if (!is_float_type(sctx_ newtype)) {
		value = (long long)old->fvalue;
		expr->type = EXPR_VALUE;
		expr->taint = 0;
		goto Int;
	}

	if (!is_float_type(sctx_ oldtype))
		expr->fvalue = (long double)get_longlong(sctx_ old);
	else
		expr->fvalue = old->fvalue;

	if (!(newtype->ctype.modifiers & MOD_LONGLONG) && \
	    !(newtype->ctype.modifiers & MOD_LONGLONGLONG)) {
		if ((newtype->ctype.modifiers & MOD_LONG))
			expr->fvalue = (double)expr->fvalue;
		else
			expr->fvalue = (float)expr->fvalue;
	}
	expr->type = EXPR_FVALUE;
}

static int check_shift_count(SCTX_ struct expression *expr, struct symbol *ctype, unsigned int count)
{
	warning(sctx_ expr->pos->pos, "shift too big (%u) for type %s", count, show_typename(sctx_ ctype));
	count &= ctype->bit_size-1;
	return count;
}

/*
 * CAREFUL! We need to get the size and sign of the
 * result right!
 */
#define CONVERT(op,s)	(((op)<<1)+(s))
#define SIGNED(op)	CONVERT(op, 1)
#define UNSIGNED(op)	CONVERT(op, 0)
static int simplify_int_binop(SCTX_ struct expression *expr, struct symbol *ctype)
{
	struct expression *left = expr->left, *right = expr->right;
	unsigned long long v, l, r, mask;
	signed long long sl, sr;
	int is_signed;

	if (right->type != EXPR_VALUE)
		return 0;
	r = right->value;
	if (expr->op == SPECIAL_LEFTSHIFT || expr->op == SPECIAL_RIGHTSHIFT) {
		if (r >= ctype->bit_size) {
			if (sctxp conservative)
				return 0;
			r = check_shift_count(sctx_ expr, ctype, r);
			right->value = r;
		}
	}
	if (left->type != EXPR_VALUE)
		return 0;
	l = left->value; r = right->value;
	is_signed = !(ctype->ctype.modifiers & MOD_UNSIGNED);
	mask = 1ULL << (ctype->bit_size-1);
	sl = l; sr = r;
	if (is_signed && (sl & mask))
		sl |= ~(mask-1);
	if (is_signed && (sr & mask))
		sr |= ~(mask-1);
	
	switch (CONVERT(expr->op,is_signed)) {
	case SIGNED('+'):
	case UNSIGNED('+'):
		v = l + r;
		break;

	case SIGNED('-'):
	case UNSIGNED('-'):
		v = l - r;
		break;

	case SIGNED('&'):
	case UNSIGNED('&'):
		v = l & r;
		break;

	case SIGNED('|'):
	case UNSIGNED('|'):
		v = l | r;
		break;

	case SIGNED('^'):
	case UNSIGNED('^'):
		v = l ^ r;
		break;

	case SIGNED('*'):
		v = sl * sr;
		break;

	case UNSIGNED('*'):
		v = l * r;
		break;

	case SIGNED('/'):
		if (!r)
			goto Div;
		if (l == mask && sr == -1)
			goto Overflow;
		v = sl / sr;
		break;

	case UNSIGNED('/'):
		if (!r) goto Div;
		v = l / r; 
		break;

	case SIGNED('%'):
		if (!r)
			goto Div;
		v = sl % sr;
		break;

	case UNSIGNED('%'):
		if (!r) goto Div;
		v = l % r;
		break;

	case SIGNED(SPECIAL_LEFTSHIFT):
	case UNSIGNED(SPECIAL_LEFTSHIFT):
		v = l << r;
		break; 

	case SIGNED(SPECIAL_RIGHTSHIFT):
		v = sl >> r;
		break;

	case UNSIGNED(SPECIAL_RIGHTSHIFT):
		v = l >> r;
		break;

	default:
		return 0;
	}
	mask = mask | (mask-1);
	expr->value = v & mask;
	expr->type = EXPR_VALUE;
	expr->taint = left->taint | right->taint;
	return 1;
Div:
	if (!sctxp conservative)
		warning(sctx_ expr->pos->pos, "division by zero");
	return 0;
Overflow:
	if (!sctxp conservative)
		warning(sctx_ expr->pos->pos, "constant integer operation overflow");
	return 0;
}

static int simplify_cmp_binop(SCTX_ struct expression *expr, struct symbol *ctype)
{
	struct expression *left = expr->left, *right = expr->right;
	unsigned long long l, r, mask;
	signed long long sl, sr;

	if (left->type != EXPR_VALUE || right->type != EXPR_VALUE)
		return 0;
	l = left->value; r = right->value;
	mask = 1ULL << (ctype->bit_size-1);
	sl = l; sr = r;
	if (sl & mask)
		sl |= ~(mask-1);
	if (sr & mask)
		sr |= ~(mask-1);
	switch (expr->op) {
	case '<':		expr->value = sl < sr; break;
	case '>':		expr->value = sl > sr; break;
	case SPECIAL_LTE:	expr->value = sl <= sr; break;
	case SPECIAL_GTE:	expr->value = sl >= sr; break;
	case SPECIAL_EQUAL:	expr->value = l == r; break;
	case SPECIAL_NOTEQUAL:	expr->value = l != r; break;
	case SPECIAL_UNSIGNED_LT:expr->value = l < r; break;
	case SPECIAL_UNSIGNED_GT:expr->value = l > r; break;
	case SPECIAL_UNSIGNED_LTE:expr->value = l <= r; break;
	case SPECIAL_UNSIGNED_GTE:expr->value = l >= r; break;
	}
	expr->type = EXPR_VALUE;
	expr->taint = left->taint | right->taint;
	return 1;
}

static int simplify_float_binop(SCTX_ struct expression *expr)
{
	struct expression *left = expr->left, *right = expr->right;
	unsigned long mod = expr->ctype->ctype.modifiers;
	long double l, r, res;

	if (left->type != EXPR_FVALUE || right->type != EXPR_FVALUE)
		return 0;

	l = left->fvalue;
	r = right->fvalue;

	if (mod & MOD_LONGLONG) {
		switch (expr->op) {
		case '+':	res = l + r; break;
		case '-':	res = l - r; break;
		case '*':	res = l * r; break;
		case '/':	if (!r) goto Div;
				res = l / r; break;
		default: return 0;
		}
	} else if (mod & MOD_LONG) {
		switch (expr->op) {
		case '+':	res = (double) l + (double) r; break;
		case '-':	res = (double) l - (double) r; break;
		case '*':	res = (double) l * (double) r; break;
		case '/':	if (!r) goto Div;
				res = (double) l / (double) r; break;
		default: return 0;
		}
	} else {
		switch (expr->op) {
		case '+':	res = (float)l + (float)r; break;
		case '-':	res = (float)l - (float)r; break;
		case '*':	res = (float)l * (float)r; break;
		case '/':	if (!r) goto Div;
				res = (float)l / (float)r; break;
		default: return 0;
		}
	}
	expr->type = EXPR_FVALUE;
	expr->fvalue = res;
	return 1;
Div:
	if (!sctxp conservative)
		warning(sctx_ expr->pos->pos, "division by zero");
	return 0;
}

static int simplify_float_cmp(SCTX_ struct expression *expr, struct symbol *ctype)
{
	struct expression *left = expr->left, *right = expr->right;
	long double l, r;

	if (left->type != EXPR_FVALUE || right->type != EXPR_FVALUE)
		return 0;

	l = left->fvalue;
	r = right->fvalue;
	switch (expr->op) {
	case '<':		expr->value = l < r; break;
	case '>':		expr->value = l > r; break;
	case SPECIAL_LTE:	expr->value = l <= r; break;
	case SPECIAL_GTE:	expr->value = l >= r; break;
	case SPECIAL_EQUAL:	expr->value = l == r; break;
	case SPECIAL_NOTEQUAL:	expr->value = l != r; break;
	}
	expr->type = EXPR_VALUE;
	expr->taint = 0;
	return 1;
}

static int expand_binop(SCTX_ struct expression *expr)
{
	int cost;

	cost = expand_expression(sctx_ expr->left);
	cost += expand_expression(sctx_ expr->right);
	if (simplify_int_binop(sctx_ expr, expr->ctype))
		return 0;
	if (simplify_float_binop(sctx_ expr))
		return 0;
	return cost + 1;
}

static int expand_logical(SCTX_ struct expression *expr)
{
	struct expression *left = expr->left;
	struct expression *right;
	int cost, rcost;

	/* Do immediate short-circuiting ... */
	cost = expand_expression(sctx_ left);
	if (left->type == EXPR_VALUE) {
		if (expr->op == SPECIAL_LOGICAL_AND) {
			if (!left->value) {
				expr->type = EXPR_VALUE;
				expr->value = 0;
				expr->taint = left->taint;
				return 0;
			}
		} else {
			if (left->value) {
				expr->type = EXPR_VALUE;
				expr->value = 1;
				expr->taint = left->taint;
				return 0;
			}
		}
	}

	right = expr->right;
	rcost = expand_expression(sctx_ right);
	if (left->type == EXPR_VALUE && right->type == EXPR_VALUE) {
		/*
		 * We know the left value doesn't matter, since
		 * otherwise we would have short-circuited it..
		 */
		expr->type = EXPR_VALUE;
		expr->value = right->value != 0;
		expr->taint = left->taint | right->taint;
		return 0;
	}

	/*
	 * If the right side is safe and cheaper than a branch,
	 * just avoid the branch and turn it into a regular binop
	 * style SAFELOGICAL.
	 */
	if (rcost < BRANCH_COST) {
		expr->type = EXPR_BINOP;
		rcost -= BRANCH_COST - 1;
	}

	return cost + BRANCH_COST + rcost;
}

static int expand_comma(SCTX_ struct expression *expr)
{
	int cost;

	cost = expand_expression(sctx_ expr->left);
	cost += expand_expression(sctx_ expr->right);
	if (expr->left->type == EXPR_VALUE || expr->left->type == EXPR_FVALUE) {
		unsigned flags = expr->flags;
		unsigned taint;
		taint = expr->left->type == EXPR_VALUE ? expr->left->taint : 0;
		*expr = *expr->right;
		expr->flags = flags;
		if (expr->type == EXPR_VALUE)
			expr->taint |= Taint_comma | taint;
	}
	return cost;
}

#define MOD_IGN (MOD_VOLATILE | MOD_CONST)

static int compare_types(SCTX_ int op, struct symbol *left, struct symbol *right)
{
	struct ctype c1 = {.base_type = left};
	struct ctype c2 = {.base_type = right};
	switch (op) {
	case SPECIAL_EQUAL:
		return !type_difference(sctx_ &c1, &c2, MOD_IGN, MOD_IGN);
	case SPECIAL_NOTEQUAL:
		return type_difference(sctx_ &c1, &c2, MOD_IGN, MOD_IGN) != NULL;
	case '<':
		return left->bit_size < right->bit_size;
	case '>':
		return left->bit_size > right->bit_size;
	case SPECIAL_LTE:
		return left->bit_size <= right->bit_size;
	case SPECIAL_GTE:
		return left->bit_size >= right->bit_size;
	}
	return 0;
}

static int expand_compare(SCTX_ struct expression *expr)
{
	struct expression *left = expr->left, *right = expr->right;
	int cost;

	cost = expand_expression(sctx_ left);
	cost += expand_expression(sctx_ right);

	if (left && right) {
		/* Type comparison? */
		if (left->type == EXPR_TYPE && right->type == EXPR_TYPE) {
			int op = expr->op;
			expr->type = EXPR_VALUE;
			expr->value = compare_types(sctx_ op, left->symbol, right->symbol);
			expr->taint = 0;
			return 0;
		}
		if (simplify_cmp_binop(sctx_ expr, left->ctype))
			return 0;
		if (simplify_float_cmp(sctx_ expr, left->ctype))
			return 0;
	}
	return cost + 1;
}

static int expand_conditional(SCTX_ struct expression *expr)
{
	struct expression *cond = expr->conditional;
	struct expression *true_sim = expr->cond_true;
	struct expression *false_sim = expr->cond_false;
	int cost, cond_cost;

	cond_cost = expand_expression(sctx_ cond);
	if (cond->type == EXPR_VALUE) {
		unsigned flags = expr->flags;
		if (!cond->value)
			true_sim = false_sim;
		if (!true_sim)
			true_sim = cond;
		cost = expand_expression(sctx_ true_sim);
		*expr = *true_sim;
		expr->flags = flags;
		if (expr->type == EXPR_VALUE)
			expr->taint |= cond->taint;
		return cost;
	}

	cost = expand_expression(sctx_ true_sim);
	cost += expand_expression(sctx_ false_sim);

	if (cost < SELECT_COST) {
		expr->type = EXPR_SELECT;
		cost -= BRANCH_COST - 1;
	}

	return cost + cond_cost + BRANCH_COST;
}
		
static int expand_assignment(SCTX_ struct expression *expr)
{
	expand_expression(sctx_ expr->left);
	expand_expression(sctx_ expr->right);
	return SIDE_EFFECTS;
}

static int expand_addressof(SCTX_ struct expression *expr)
{
	return expand_expression(sctx_ expr->unop);
}

/*
 * Look up a trustable initializer value at the requested offset.
 *
 * Return NULL if no such value can be found or statically trusted.
 *
 * FIXME!! We should check that the size is right!
 */
static struct expression *constant_symbol_value(SCTX_ struct symbol *sym, int offset)
{
	struct expression *value;

	if (sym->ctype.modifiers & (MOD_ASSIGNED | MOD_ADDRESSABLE))
		return NULL;
	value = sym->initializer;
	if (!value)
		return NULL;
	if (value->type == EXPR_INITIALIZER) {
		struct expression *entry;
		FOR_EACH_PTR(value->expr_list, entry) {
			if (entry->type != EXPR_POS) {
				if (offset)
					continue;
				return entry;
			}
			if (entry->init_offset < offset)
				continue;
			if (entry->init_offset > offset)
				return NULL;
			return entry->init_expr;
		} END_FOR_EACH_PTR(entry);
		return NULL;
	}
	return value;
}

static int expand_dereference(SCTX_ struct expression *expr)
{
	struct expression *unop = expr->unop;
	unsigned int offset;

	expand_expression(sctx_ unop);

	/*
	 * NOTE! We get a bogus warning right now for some special
	 * cases: apparently I've screwed up the optimization of
	 * a zero-offset dereference, and the ctype is wrong.
	 *
	 * Leave the warning in anyway, since this is also a good
	 * test for me to get the type evaluation right..
	 */
	if (expr->ctype->ctype.modifiers & MOD_NODEREF)
		warning(sctx_ unop->pos->pos, "dereference of noderef expression");

	/*
	 * Is it "symbol" or "symbol + offset"?
	 */
	offset = 0;
	if (unop->type == EXPR_BINOP && unop->op == '+') {
		struct expression *right = unop->right;
		if (right->type == EXPR_VALUE) {
			offset = right->value;
			unop = unop->left;
		}
	}

	if (unop->type == EXPR_SYMBOL) {
		struct symbol *sym = unop->symbol;
		struct expression *value = constant_symbol_value(sctx_ sym, offset);

		/* Const symbol with a constant initializer? */
		if (value) {
			/* FIXME! We should check that the size is right! */
			if (value->type == EXPR_VALUE) {
				expr->type = EXPR_VALUE;
				expr->value = value->value;
				expr->taint = 0;
				return 0;
			} else if (value->type == EXPR_FVALUE) {
				expr->type = EXPR_FVALUE;
				expr->fvalue = value->fvalue;
				return 0;
			}
		}

		/* Direct symbol dereference? Cheap and safe */
		return (sym->ctype.modifiers & (MOD_STATIC | MOD_EXTERN)) ? 2 : 1;
	}

	return UNSAFE;
}

static int simplify_preop(SCTX_ struct expression *expr)
{
	struct expression *op = expr->unop;
	unsigned long long v, mask;

	if (op->type != EXPR_VALUE)
		return 0;

	mask = 1ULL << (expr->ctype->bit_size-1);
	v = op->value;
	switch (expr->op) {
	case '+': break;
	case '-':
		if (v == mask && !(expr->ctype->ctype.modifiers & MOD_UNSIGNED))
			goto Overflow;
		v = -v;
		break;
	case '!': v = !v; break;
	case '~': v = ~v; break;
	default: return 0;
	}
	mask = mask | (mask-1);
	expr->value = v & mask;
	expr->type = EXPR_VALUE;
	expr->taint = op->taint;
	return 1;

Overflow:
	if (!sctxp conservative)
		warning(sctx_ expr->pos->pos, "constant integer operation overflow");
	return 0;
}

static int simplify_float_preop(SCTX_ struct expression *expr)
{
	struct expression *op = expr->unop;
	long double v;

	if (op->type != EXPR_FVALUE)
		return 0;
	v = op->fvalue;
	switch (expr->op) {
	case '+': break;
	case '-': v = -v; break;
	default: return 0;
	}
	expr->fvalue = v;
	expr->type = EXPR_FVALUE;
	return 1;
}

/*
 * Unary post-ops: x++ and x--
 */
static int expand_postop(SCTX_ struct expression *expr)
{
	expand_expression(sctx_ expr->unop);
	return SIDE_EFFECTS;
}

static int expand_preop(SCTX_ struct expression *expr)
{
	int cost;

	switch (expr->op) {
	case '*':
		return expand_dereference(sctx_ expr);

	case '&':
		return expand_addressof(sctx_ expr);

	case SPECIAL_INCREMENT:
	case SPECIAL_DECREMENT:
		/*
		 * From a type evaluation standpoint the preops are
		 * the same as the postops
		 */
		return expand_postop(sctx_ expr);

	default:
		break;
	}
	cost = expand_expression(sctx_ expr->unop);

	if (simplify_preop(sctx_ expr))
		return 0;
	if (simplify_float_preop(sctx_ expr))
		return 0;
	return cost + 1;
}

static int expand_arguments(SCTX_ struct expression_list *head)
{
	int cost = 0;
	struct expression *expr;

	FOR_EACH_PTR (head, expr) {
		cost += expand_expression(sctx_ expr);
	} END_FOR_EACH_PTR(expr);
	return cost;
}

static int expand_cast(SCTX_ struct expression *expr)
{
	int cost;
	struct expression *target = expr->cast_expression;

	cost = expand_expression(sctx_ target);

	/* Simplify normal integer casts.. */
	if (target->type == EXPR_VALUE || target->type == EXPR_FVALUE) {
		cast_value(sctx_ expr, expr->ctype, target, target->ctype);
		return 0;
	}
	return cost + 1;
}

/* The arguments are constant if the cost of all of them is zero */
int expand_constant_p(SCTX_ struct expression *expr, int cost)
{
	expr->type = EXPR_VALUE;
	expr->value = !cost;
	expr->taint = 0;
	return 0;
}

/* The arguments are safe, if their cost is less than SIDE_EFFECTS */
int expand_safe_p(SCTX_ struct expression *expr, int cost)
{
	expr->type = EXPR_VALUE;
	expr->value = (cost < SIDE_EFFECTS);
	expr->taint = 0;
	return 0;
}

/*
 * expand a call expression with a symbol. This
 * should expand builtins.
 */
static int expand_symbol_call(SCTX_ struct expression *expr, int cost)
{
	struct expression *fn = expr->fn;
	struct symbol *ctype = fn->ctype;

	if (fn->type != EXPR_PREOP)
		return SIDE_EFFECTS;

	if (ctype->op && ctype->op->expand)
		return ctype->op->expand(sctx_ expr, cost);

	if (ctype->ctype.modifiers & MOD_PURE)
		return 0;

	return SIDE_EFFECTS;
}

static int expand_call(SCTX_ struct expression *expr)
{
	int cost;
	struct symbol *sym;
	struct expression *fn = expr->fn;

	cost = expand_arguments(sctx_ expr->args);
	sym = fn->ctype;
	if (!sym) {
		expression_error(sctx_ expr, "function has no type");
		return SIDE_EFFECTS;
	}
	if (sym->type == SYM_NODE)
		return expand_symbol_call(sctx_ expr, cost);

	return SIDE_EFFECTS;
}

static int expand_expression_list(SCTX_ struct expression_list *list)
{
	int cost = 0;
	struct expression *expr;

	FOR_EACH_PTR(list, expr) {
		cost += expand_expression(sctx_ expr);
	} END_FOR_EACH_PTR(expr);
	return cost;
}

/* 
 * We can simplify nested position expressions if
 * this is a simple (single) positional expression.
 */
static int expand_pos_expression(SCTX_ struct expression *expr)
{
	struct expression *nested = expr->init_expr;
	unsigned long offset = expr->init_offset;
	int nr = expr->init_nr;

	if (nr == 1) {
		switch (nested->type) {
		case EXPR_POS:
			offset += nested->init_offset;
			*expr = *nested;
			expr->init_offset = offset;
			nested = expr;
			break;

		case EXPR_INITIALIZER: {
			struct expression *reuse = nested, *entry;
			*expr = *nested;
			FOR_EACH_PTR(expr->expr_list, entry) {
				if (entry->type == EXPR_POS) {
					entry->init_offset += offset;
				} else {
					if (!reuse) {
						/*
						 * This happens rarely, but it can happen
						 * with bitfields that are all at offset
						 * zero..
						 */
						reuse = alloc_expression(sctx_ entry->tok, EXPR_POS);
					}
					reuse->type = EXPR_POS;
					reuse->ctype = entry->ctype;
					reuse->init_offset = offset;
					reuse->init_nr = 1;
					reuse->init_expr = entry;
					REPLACE_CURRENT_PTR(entry, reuse);
					reuse = NULL;
				}
			} END_FOR_EACH_PTR(entry);
			nested = expr;
			break;
		}

		default:
			break;
		}
	}
	return expand_expression(sctx_ nested);
}

static unsigned long bit_offset(SCTX_ const struct expression *expr)
{
	unsigned long offset = 0;
	while (expr->type == EXPR_POS) {
		offset += bytes_to_bits(sctx_ expr->init_offset);
		expr = expr->init_expr;
	}
	if (expr && expr->ctype)
		offset += expr->ctype->bit_offset;
	return offset;
}

static int compare_expressions(SCTX_ const void *_a, const void *_b)
{
	const struct expression *a = _a;
	const struct expression *b = _b;
	unsigned long a_pos = bit_offset(sctx_ a);
	unsigned long b_pos = bit_offset(sctx_ b);

	return (a_pos < b_pos) ? -1 : (a_pos == b_pos) ? 0 : 1;
}

static void sort_expression_list(SCTX_ struct expression_list **list)
{
	sort_list(sctx_ (struct ptr_list **)list, compare_expressions);
}

static void verify_nonoverlapping(SCTX_ struct expression_list **list)
{
	struct expression *a = NULL;
	struct expression *b;

	FOR_EACH_PTR(*list, b) {
		if (!b->ctype || !b->ctype->bit_size)
			continue;
		if (a && bit_offset(sctx_ a) == bit_offset(sctx_ b)) {
			warning(sctx_ a->pos->pos, "Initializer entry defined twice");
			info(sctx_ b->pos->pos, "  also defined here");
			return;
		}
		a = b;
	} END_FOR_EACH_PTR(b);
}

static int expand_expression(SCTX_ struct expression *expr)
{
	if (!expr)
		return 0;
	if (!expr->ctype || expr->ctype == &sctxp bad_ctype)
		return UNSAFE;

	switch (expr->type) {
	case EXPR_VALUE:
	case EXPR_FVALUE:
	case EXPR_STRING:
		return 0;
	case EXPR_TYPE:
	case EXPR_SYMBOL:
		return expand_symbol_expression(sctx_ expr);
	case EXPR_BINOP:
		return expand_binop(sctx_ expr);

	case EXPR_LOGICAL:
		return expand_logical(sctx_ expr);

	case EXPR_COMMA:
		return expand_comma(sctx_ expr);

	case EXPR_COMPARE:
		return expand_compare(sctx_ expr);

	case EXPR_ASSIGNMENT:
		return expand_assignment(sctx_ expr);

	case EXPR_PREOP:
		return expand_preop(sctx_ expr);

	case EXPR_POSTOP:
		return expand_postop(sctx_ expr);

	case EXPR_CAST:
	case EXPR_FORCE_CAST:
	case EXPR_IMPLIED_CAST:
		return expand_cast(sctx_ expr);

	case EXPR_CALL:
		return expand_call(sctx_ expr);

	case EXPR_DEREF:
		warning(sctx_ expr->pos->pos, "we should not have an EXPR_DEREF left at expansion time");
		return UNSAFE;

	case EXPR_SELECT:
	case EXPR_CONDITIONAL:
		return expand_conditional(sctx_ expr);

	case EXPR_STATEMENT: {
		struct statement *stmt = expr->statement;
		int cost = expand_statement(sctx_ stmt);

		if (stmt->type == STMT_EXPRESSION && stmt->expression)
			*expr = *stmt->expression;
		return cost;
	}

	case EXPR_LABEL:
		return 0;

	case EXPR_INITIALIZER:
		sort_expression_list(sctx_ &expr->expr_list);
		verify_nonoverlapping(sctx_ &expr->expr_list);
		return expand_expression_list(sctx_ expr->expr_list);

	case EXPR_IDENTIFIER:
		return UNSAFE;

	case EXPR_INDEX:
		return UNSAFE;

	case EXPR_SLICE:
		return expand_expression(sctx_ expr->base) + 1;

	case EXPR_POS:
		return expand_pos_expression(sctx_ expr);

	case EXPR_SIZEOF:
	case EXPR_PTRSIZEOF:
	case EXPR_ALIGNOF:
	case EXPR_OFFSETOF:
		expression_error(sctx_ expr, "internal front-end error: sizeof in expansion?");
		return UNSAFE;
	}
	return SIDE_EFFECTS;
}

static void expand_const_expression(SCTX_ struct expression *expr, const char *where)
{
	if (expr) {
		expand_expression(sctx_ expr);
		if (expr->type != EXPR_VALUE)
			expression_error(sctx_ expr, "Expected constant expression in %s", where);
	}
}

int expand_symbol(SCTX_ struct symbol *sym)
{
	int retval;
	struct symbol *base_type;

	if (!sym)
		return 0;
	base_type = sym->ctype.base_type;
	if (!base_type)
		return 0;

	retval = expand_expression(sctx_ sym->initializer);
	/* expand the body of the symbol */
	if (base_type->type == SYM_FN) {
		if (base_type->stmt)
			expand_statement(sctx_ base_type->stmt);
	}
	return retval;
}

static void expand_return_expression(SCTX_ struct statement *stmt)
{
	expand_expression(sctx_ stmt->expression);
}

static int expand_if_statement(SCTX_ struct statement *stmt)
{
	struct expression *expr = stmt->if_conditional;

	if (!expr || !expr->ctype || expr->ctype == &sctxp bad_ctype)
		return UNSAFE;

	expand_expression(sctx_ expr);

/* This is only valid if nobody jumps into the "dead" side */
#if 0
	/* Simplify constant conditionals without even evaluating the false side */
	if (expr->type == EXPR_VALUE) {
		struct statement *simple;
		simple = expr->value ? stmt->if_true : stmt->if_false;

		/* Nothing? */
		if (!simple) {
			stmt->type = STMT_NONE;
			return 0;
		}
		expand_statement(simple);
		*stmt = *simple;
		return SIDE_EFFECTS;
	}
#endif
	expand_statement(sctx_ stmt->if_true);
	expand_statement(sctx_ stmt->if_false);
	return SIDE_EFFECTS;
}

/*
 * Expanding a compound statement is really just
 * about adding up the costs of each individual
 * statement.
 *
 * We also collapse a simple compound statement:
 * this would trigger for simple inline functions,
 * except we would have to check the "return"
 * symbol usage. Next time.
 */
static int expand_compound(SCTX_ struct statement *stmt)
{
	struct statement *s, *last;
	int cost, statements;

	if (stmt->ret)
		expand_symbol(sctx_ stmt->ret);

	last = stmt->args;
	cost = expand_statement(sctx_ last);
	statements = last != NULL;
	FOR_EACH_PTR(stmt->stmts, s) {
		statements++;
		last = s;
		cost += expand_statement(sctx_ s);
	} END_FOR_EACH_PTR(s);

	if (statements == 1 && !stmt->ret)
		*stmt = *last;

	return cost;
}

static int expand_statement(SCTX_ struct statement *stmt)
{
	if (!stmt)
		return 0;

	switch (stmt->type) {
	case STMT_DECLARATION: {
		struct symbol *sym;
		FOR_EACH_PTR(stmt->declaration, sym) {
			expand_symbol(sctx_ sym);
		} END_FOR_EACH_PTR(sym);
		return SIDE_EFFECTS;
	}

	case STMT_RETURN:
		expand_return_expression(sctx_ stmt);
		return SIDE_EFFECTS;

	case STMT_EXPRESSION:
		return expand_expression(sctx_ stmt->expression);

	case STMT_COMPOUND:
		return expand_compound(sctx_ stmt);

	case STMT_IF:
		return expand_if_statement(sctx_ stmt);

	case STMT_ITERATOR:
		expand_expression(sctx_ stmt->iterator_pre_condition);
		expand_expression(sctx_ stmt->iterator_post_condition);
		expand_statement(sctx_ stmt->iterator_pre_statement);
		expand_statement(sctx_ stmt->iterator_statement);
		expand_statement(sctx_ stmt->iterator_post_statement);
		return SIDE_EFFECTS;

	case STMT_SWITCH:
		expand_expression(sctx_ stmt->switch_expression);
		expand_statement(sctx_ stmt->switch_statement);
		return SIDE_EFFECTS;

	case STMT_CASE:
		expand_const_expression(sctx_ stmt->case_expression, "case statement");
		expand_const_expression(sctx_ stmt->case_to, "case statement");
		expand_statement(sctx_ stmt->case_statement);
		return SIDE_EFFECTS;

	case STMT_LABEL:
		expand_statement(sctx_ stmt->label_statement);
		return SIDE_EFFECTS;

	case STMT_GOTO:
		expand_expression(sctx_ stmt->goto_expression);
		return SIDE_EFFECTS;

	case STMT_NONE:
		break;
	case STMT_ASM:
		/* FIXME! Do the asm parameter evaluation! */
		break;
	case STMT_CONTEXT:
		expand_expression(sctx_ stmt->expression);
		break;
	case STMT_RANGE:
		expand_expression(sctx_ stmt->range_expression);
		expand_expression(sctx_ stmt->range_low);
		expand_expression(sctx_ stmt->range_high);
		break;
	}
	return SIDE_EFFECTS;
}

static inline int bad_integer_constant_expression(struct expression *expr)
{
	if (!(expr->flags & Int_const_expr))
		return 1;
	if (expr->taint & Taint_comma)
		return 1;
	return 0;
}

static long long __get_expression_value(SCTX_ struct expression *expr, int strict)
{
	long long value, mask;
	struct symbol *ctype;

	if (!expr)
		return 0;
	ctype = evaluate_expression(sctx_ expr);
	if (!ctype) {
		expression_error(sctx_ expr, "bad constant expression type");
		return 0;
	}
	expand_expression(sctx_ expr);
	if (expr->type != EXPR_VALUE) {
		if (strict != 2)
			expression_error(sctx_ expr, "bad constant expression");
		return 0;
	}
	if ((strict == 1) && bad_integer_constant_expression(expr)) {
		expression_error(sctx_ expr, "bad integer constant expression");
		return 0;
	}

	value = expr->value;
	mask = 1ULL << (ctype->bit_size-1);

	if (value & mask) {
		while (ctype->type != SYM_BASETYPE)
			ctype = ctype->ctype.base_type;
		if (!(ctype->ctype.modifiers & MOD_UNSIGNED))
			value = value | mask | ~(mask-1);
	}
	return value;
}

long long get_expression_value(SCTX_ struct expression *expr)
{
	return __get_expression_value(sctx_ expr, 0);
}

long long const_expression_value(SCTX_ struct expression *expr)
{
	return __get_expression_value(sctx_ expr, 1);
}

long long get_expression_value_silent(SCTX_ struct expression *expr)
{

	return __get_expression_value(sctx_ expr, 2);
}

int is_zero_constant(SCTX_ struct expression *expr)
{
	const int saved = sctxp conservative;
	sctxp conservative = 1;
	expand_expression(sctx_ expr);
	sctxp conservative = saved;
	return expr->type == EXPR_VALUE && !expr->value;
}
