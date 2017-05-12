/*
 * Sparse - a semantic source parser.
 *
 * Copyright (C) 2003 Transmeta Corp.
 *               2003-2004 Linus Torvalds
 *
 *  Licensed under the Open Software License version 1.1
 */

#include <stdlib.h>
#include <stdio.h>

#include "lib.h"
#include "allocate.h"
#include "token.h"
#include "parse.h"
#include "symbol.h"
#include "expression.h"

static struct expression * dup_expression(SCTX_ struct expression *expr)
{
	struct expression *dup = alloc_expression(sctx_ expr->tok, expr->type);
	*dup = *expr;
	return dup;
}

static struct statement * dup_statement(SCTX_ struct statement *stmt)
{
	struct statement *dup = alloc_statement(sctx_ stmt->tok, stmt->type);
	*dup = *stmt;
	return dup;
}

static struct symbol *copy_symbol(SCTX_ struct position pos, struct symbol *sym)
{
	if (!sym)
		return sym;
	if (sym->ctype.modifiers & (MOD_STATIC | MOD_EXTERN | MOD_TOPLEVEL | MOD_INLINE))
		return sym;
	if (!sym->replace) {
		warning(sctx_ pos, "unreplaced symbol '%s'", show_ident(sctx_ sym->ident));
		return sym;
	}
	return sym->replace;
}

static struct symbol_list *copy_symbol_list(SCTX_ struct symbol_list *src)
{
	struct symbol_list *dst = NULL;
	struct symbol *sym;

	FOR_EACH_PTR(src, sym) {
		struct symbol *newsym = copy_symbol(sctx_ sym->pos->pos, sym);
		add_symbol(sctx_ &dst, newsym);
	} END_FOR_EACH_PTR(sym);
	return dst;
}

static struct expression * copy_expression(SCTX_ struct expression *expr)
{
	if (!expr)
		return NULL;

	switch (expr->type) {
	/*
	 * EXPR_SYMBOL is the interesting case, we may need to replace the
	 * symbol to the new copy.
	 */
	case EXPR_SYMBOL: {
		struct symbol *sym = copy_symbol(sctx_ expr->pos->pos, expr->symbol);
		if (sym == expr->symbol)
			break;
		expr = dup_expression(sctx_ expr);
		expr->symbol = sym;
		break;
	}

	/* Atomics, never change, just return the expression directly */
	case EXPR_VALUE:
	case EXPR_STRING:
	case EXPR_FVALUE:
	case EXPR_TYPE:
		break;

	/* Unops: check if the subexpression is unique */
	case EXPR_PREOP:
	case EXPR_POSTOP: {
		struct expression *unop = copy_expression(sctx_ expr->unop);
		if (expr->unop == unop)
			break;
		expr = dup_expression(sctx_ expr);
		expr->unop = unop;
		break;
	}

	case EXPR_SLICE: {
		struct expression *base = copy_expression(sctx_ expr->base);
		expr = dup_expression(sctx_ expr);
		expr->base = base;
		break;
	}

	/* Binops: copy left/right expressions */
	case EXPR_BINOP:
	case EXPR_COMMA:
	case EXPR_COMPARE:
	case EXPR_LOGICAL: {
		struct expression *left = copy_expression(sctx_ expr->left);
		struct expression *right = copy_expression(sctx_ expr->right);
		if (left == expr->left && right == expr->right)
			break;
		expr = dup_expression(sctx_ expr);
		expr->left = left;
		expr->right = right;
		break;
	}

	case EXPR_ASSIGNMENT: {
		struct expression *left = copy_expression(sctx_ expr->left);
		struct expression *right = copy_expression(sctx_ expr->right);
		if (expr->op == '=' && left == expr->left && right == expr->right)
			break;
		expr = dup_expression(sctx_ expr);
		expr->left = left;
		expr->right = right;
		break;
	}

	/* Dereference */
	case EXPR_DEREF: {
		struct expression *deref = copy_expression(sctx_ expr->deref);
		expr = dup_expression(sctx_ expr);
		expr->deref = deref;
		break;
	}

	/* Cast/sizeof/__alignof__ */
	case EXPR_CAST:
		if (expr->cast_expression->type == EXPR_INITIALIZER) {
			struct expression *cast = expr->cast_expression;
			struct symbol *sym = expr->cast_type;
			expr = dup_expression(sctx_ expr);
			expr->cast_expression = copy_expression(sctx_ cast);
			expr->cast_type = alloc_symbol(sctx_ sym->tok, sym->type);
			*expr->cast_type = *sym;
			break;
		}
	case EXPR_FORCE_CAST:
	case EXPR_IMPLIED_CAST:
	case EXPR_SIZEOF: 
	case EXPR_PTRSIZEOF:
	case EXPR_ALIGNOF: {
		struct expression *cast = copy_expression(sctx_ expr->cast_expression);
		if (cast == expr->cast_expression)
			break;
		expr = dup_expression(sctx_ expr);
		expr->cast_expression = cast;
		break;
	}

	/* Conditional expression */
	case EXPR_SELECT:
	case EXPR_CONDITIONAL: {
		struct expression *cond = copy_expression(sctx_ expr->conditional);
		struct expression *true_sim = copy_expression(sctx_ expr->cond_true);
		struct expression *false_sim = copy_expression(sctx_ expr->cond_false);
		if (cond == expr->conditional && true_sim == expr->cond_true && false_sim == expr->cond_false)
			break;
		expr = dup_expression(sctx_ expr);
		expr->conditional = cond;
		expr->cond_true = true_sim;
		expr->cond_false = false_sim;
		break;
	}

	/* Statement expression */
	case EXPR_STATEMENT: {
		struct statement *stmt = alloc_statement(sctx_ expr->tok, STMT_COMPOUND);
		copy_statement(sctx_ expr->statement, stmt);
		expr = dup_expression(sctx_ expr);
		expr->statement = stmt;
		break;
	}

	/* Call expression */
	case EXPR_CALL: {
		struct expression *fn = copy_expression(sctx_ expr->fn);
		struct expression_list *list = expr->args;
		struct expression *arg;

		expr = dup_expression(sctx_ expr);
		expr->fn = fn;
		expr->args = NULL;
		FOR_EACH_PTR(list, arg) {
			add_expression(sctx_ &expr->args, copy_expression(sctx_ arg));
		} END_FOR_EACH_PTR(arg);
		break;
	}

	/* Initializer list statement */
	case EXPR_INITIALIZER: {
		struct expression_list *list = expr->expr_list;
		struct expression *entry;
		expr = dup_expression(sctx_ expr);
		expr->expr_list = NULL;
		FOR_EACH_PTR(list, entry) {
			add_expression(sctx_ &expr->expr_list, copy_expression(sctx_ entry));
		} END_FOR_EACH_PTR(entry);
		break;
	}

	/* Label in inline function - hmm. */
	case EXPR_LABEL: {
		struct symbol *label_symbol = copy_symbol(sctx_ expr->pos->pos, expr->label_symbol);
		expr = dup_expression(sctx_ expr);
		expr->label_symbol = label_symbol;
		break;
	}

	case EXPR_INDEX: {
		struct expression *sub_expr = copy_expression(sctx_ expr->idx_expression);
		expr = dup_expression(sctx_ expr);
		expr->idx_expression = sub_expr;
		break;
	}
		
	case EXPR_IDENTIFIER: {
		struct expression *sub_expr = copy_expression(sctx_ expr->ident_expression);
		expr = dup_expression(sctx_ expr);
		expr->ident_expression = sub_expr;
		break;
	}

	/* Position in initializer.. */
	case EXPR_POS: {
		struct expression *val = copy_expression(sctx_ expr->init_expr);
		expr = dup_expression(sctx_ expr);
		expr->init_expr = val;
		break;
	}
	case EXPR_OFFSETOF: {
		struct expression *val = copy_expression(sctx_ expr->down);
		if (expr->op == '.') {
			if (expr->down != val) {
				expr = dup_expression(sctx_ expr);
				expr->down = val;
			}
		} else {
			struct expression *idx = copy_expression(sctx_ expr->index);
			if (expr->down != val || expr->index != idx) {
				expr = dup_expression(sctx_ expr);
				expr->down = val;
				expr->index = idx;
			}
		}
		break;
	}
	default:
		warning(sctx_ expr->pos->pos, "trying to copy expression type %d", expr->type);
	}
	return expr;
}

static struct expression_list *copy_asm_constraints(SCTX_ struct expression_list *in)
{
	struct expression_list *out = NULL;
	struct expression *expr;
	int state = 0;

	FOR_EACH_PTR(in, expr) {
		switch (state) {
		case 0: /* identifier */
		case 1: /* constraint */
			state++;
			add_expression(sctx_ &out, expr);
			continue;
		case 2: /* expression */
			state = 0;
			add_expression(sctx_ &out, copy_expression(sctx_ expr));
			continue;
		}
	} END_FOR_EACH_PTR(expr);
	return out;
}

static void set_replace(SCTX_ struct symbol *old, struct symbol *new)
{
	new->replace = old;
	old->replace = new;
}

static void unset_replace(SCTX_ struct symbol *sym)
{
	struct symbol *r = sym->replace;
	if (!r) {
		warning(sctx_ sym->pos->pos, "symbol '%s' not replaced?", show_ident(sctx_ sym->ident));
		return;
	}
	r->replace = NULL;
	sym->replace = NULL;
}

static void unset_replace_list(SCTX_ struct symbol_list *list)
{
	struct symbol *sym;
	FOR_EACH_PTR(list, sym) {
		unset_replace(sctx_ sym);
	} END_FOR_EACH_PTR(sym);
}

static struct statement *copy_one_statement(SCTX_ struct statement *stmt)
{
	if (!stmt)
		return NULL;
	switch(stmt->type) {
	case STMT_NONE:
		break;
	case STMT_DECLARATION: {
		struct symbol *sym;
		struct statement *newstmt = dup_statement(sctx_ stmt);
		newstmt->declaration = NULL;
		FOR_EACH_PTR(stmt->declaration, sym) {
			struct symbol *newsym = copy_symbol(sctx_ stmt->pos->pos, sym);
			if (newsym != sym)
				newsym->initializer = copy_expression(sctx_ sym->initializer);
			add_symbol(sctx_ &newstmt->declaration, newsym);
		} END_FOR_EACH_PTR(sym);
		stmt = newstmt;
		break;
	}
	case STMT_CONTEXT:
	case STMT_EXPRESSION: {
		struct expression *expr = copy_expression(sctx_ stmt->expression);
		if (expr == stmt->expression)
			break;
		stmt = dup_statement(sctx_ stmt);
		stmt->expression = expr;
		break;
	}
	case STMT_RANGE: {
		struct expression *expr = copy_expression(sctx_ stmt->range_expression);
		if (expr == stmt->expression)
			break;
		stmt = dup_statement(sctx_ stmt);
		stmt->range_expression = expr;
		break;
	}
	case STMT_COMPOUND: {
		struct statement *new = alloc_statement(sctx_ stmt->tok, STMT_COMPOUND);
		copy_statement(sctx_ stmt, new);
		stmt = new;
		break;
	}
	case STMT_IF: {
		struct expression *cond = stmt->if_conditional;
		struct statement *true_sim = stmt->if_true;
		struct statement *false_sim = stmt->if_false;

		cond = copy_expression(sctx_ cond);
		true_sim = copy_one_statement(sctx_ true_sim);
		false_sim = copy_one_statement(sctx_ false_sim);
		if (stmt->if_conditional == cond &&
		    stmt->if_true == true_sim &&
		    stmt->if_false == false_sim)
			break;
		stmt = dup_statement(sctx_ stmt);
		stmt->if_conditional = cond;
		stmt->if_true = true_sim;
		stmt->if_false = false_sim;
		break;
	}
	case STMT_RETURN: {
		struct expression *retval = copy_expression(sctx_ stmt->ret_value);
		struct symbol *sym = copy_symbol(sctx_ stmt->pos->pos, stmt->ret_target);

		stmt = dup_statement(sctx_ stmt);
		stmt->ret_value = retval;
		stmt->ret_target = sym;
		break;
	}
	case STMT_CASE: {
		stmt = dup_statement(sctx_ stmt);
		stmt->case_label = copy_symbol(sctx_ stmt->pos->pos, stmt->case_label);
		stmt->case_label->stmt = stmt;
		stmt->case_expression = copy_expression(sctx_ stmt->case_expression);
		stmt->case_to = copy_expression(sctx_ stmt->case_to);
		stmt->case_statement = copy_one_statement(sctx_ stmt->case_statement);
		break;
	}
	case STMT_SWITCH: {
		struct symbol *switch_break = copy_symbol(sctx_ stmt->pos->pos, stmt->switch_break);
		struct symbol *switch_case = copy_symbol(sctx_ stmt->pos->pos, stmt->switch_case);
		struct expression *expr = copy_expression(sctx_ stmt->switch_expression);
		struct statement *switch_stmt = copy_one_statement(sctx_ stmt->switch_statement);

		stmt = dup_statement(sctx_ stmt);
		switch_case->symbol_list = copy_symbol_list(sctx_ switch_case->symbol_list);
		stmt->switch_break = switch_break;
		stmt->switch_case = switch_case;
		stmt->switch_expression = expr;
		stmt->switch_statement = switch_stmt;
		break;		
	}
	case STMT_ITERATOR: {
		stmt = dup_statement(sctx_ stmt);
		stmt->iterator_break = copy_symbol(sctx_ stmt->pos->pos, stmt->iterator_break);
		stmt->iterator_continue = copy_symbol(sctx_ stmt->pos->pos, stmt->iterator_continue);
		stmt->iterator_syms = copy_symbol_list(sctx_ stmt->iterator_syms);

		stmt->iterator_pre_statement = copy_one_statement(sctx_ stmt->iterator_pre_statement);
		stmt->iterator_pre_condition = copy_expression(sctx_ stmt->iterator_pre_condition);

		stmt->iterator_statement = copy_one_statement(sctx_ stmt->iterator_statement);

		stmt->iterator_post_statement = copy_one_statement(sctx_ stmt->iterator_post_statement);
		stmt->iterator_post_condition = copy_expression(sctx_ stmt->iterator_post_condition);
		break;
	}
	case STMT_LABEL: {
		stmt = dup_statement(sctx_ stmt);
		stmt->label_identifier = copy_symbol(sctx_ stmt->pos->pos, stmt->label_identifier);
		stmt->label_statement = copy_one_statement(sctx_ stmt->label_statement);
		break;
	}
	case STMT_GOTO: {
		stmt = dup_statement(sctx_ stmt);
		stmt->goto_label = copy_symbol(sctx_ stmt->pos->pos, stmt->goto_label);
		stmt->goto_expression = copy_expression(sctx_ stmt->goto_expression);
		stmt->target_list = copy_symbol_list(sctx_ stmt->target_list);
		break;
	}
	case STMT_ASM: {
		stmt = dup_statement(sctx_ stmt);
		stmt->asm_inputs = copy_asm_constraints(sctx_ stmt->asm_inputs);
		stmt->asm_outputs = copy_asm_constraints(sctx_ stmt->asm_outputs);
		/* no need to dup "clobbers", since they are all constant strings */
		break;
	}
	default:
		warning(sctx_ stmt->pos->pos, "trying to copy statement type %d", stmt->type);
		break;
	}
	return stmt;
}

/*
 * Copy a statement tree from 'src' to 'dst', where both
 * source and destination are of type STMT_COMPOUND.
 *
 * We do this for the tree-level inliner.
 *
 * This doesn't do the symbol replacement right: it's not
 * re-entrant.
 */
void copy_statement(SCTX_ struct statement *src, struct statement *dst)
{
	struct statement *stmt;

	FOR_EACH_PTR(src->stmts, stmt) {
		add_statement(sctx_ &dst->stmts, copy_one_statement(sctx_ stmt));
	} END_FOR_EACH_PTR(stmt);
	dst->args = copy_one_statement(sctx_ src->args);
	dst->ret = copy_symbol(sctx_ src->pos->pos, src->ret);
	dst->inline_fn = src->inline_fn;
}

static struct symbol *create_copy_symbol(SCTX_ struct symbol *orig)
{
	struct symbol *sym = orig;
	if (orig) {
		sym = alloc_symbol(sctx_ orig->tok, orig->type);
		*sym = *orig;
		sym->bb_target = NULL;
		sym->pseudo = NULL;
		set_replace(sctx_ orig, sym);
		orig = sym;
	}
	return orig;
}

static struct symbol_list *create_symbol_list(SCTX_ struct symbol_list *src)
{
	struct symbol_list *dst = NULL;
	struct symbol *sym;

	FOR_EACH_PTR(src, sym) {
		struct symbol *newsym = create_copy_symbol(sctx_ sym);
		add_symbol(sctx_ &dst, newsym);
	} END_FOR_EACH_PTR(sym);
	return dst;
}

int inline_function(SCTX_ struct expression *expr, struct symbol *sym)
{
	struct symbol_list * fn_symbol_list;
	struct symbol *fn = sym->ctype.base_type;
	struct expression_list *arg_list = expr->args;
	struct statement *stmt = alloc_statement(sctx_ expr->tok, STMT_COMPOUND);
	struct symbol_list *name_list, *arg_decl;
	struct symbol *name;
	struct expression *arg;

	if (!fn->inline_stmt) {
		sparse_error(sctx_ fn->pos->pos, "marked inline, but without a definition");
		return 0;
	}
	if (fn->expanding)
		return 0;

	fn->expanding = 1;

	name_list = fn->arguments;

	expr->type = EXPR_STATEMENT;
	expr->statement = stmt;
	expr->ctype = fn->ctype.base_type;

	fn_symbol_list = create_symbol_list(sctx_ sym->inline_symbol_list);

	arg_decl = NULL;
	PREPARE_PTR_LIST(name_list, name);
	FOR_EACH_PTR(arg_list, arg) {
		struct symbol *a = alloc_symbol(sctx_ arg->tok, SYM_NODE);

		a->ctype.base_type = arg->ctype;
		if (name) {
			*a = *name;
			set_replace(sctx_ name, a);
			add_symbol(sctx_ &fn_symbol_list, a);
		}
		a->initializer = arg;
		add_symbol(sctx_ &arg_decl, a);

		NEXT_PTR_LIST(name);
	} END_FOR_EACH_PTR(arg);
	FINISH_PTR_LIST(name);

	copy_statement(sctx_ fn->inline_stmt, stmt);

	if (arg_decl) {
		struct statement *decl = alloc_statement(sctx_ expr->tok, STMT_DECLARATION);
		decl->declaration = arg_decl;
		stmt->args = decl;
	}
	stmt->inline_fn = sym;

	unset_replace_list(sctx_ fn_symbol_list);

	evaluate_statement(sctx_ stmt);

	fn->expanding = 0;
	return 1;
}

void uninline(SCTX_ struct symbol *sym)
{
	struct symbol *fn = sym->ctype.base_type;
	struct symbol_list *arg_list = fn->arguments;
	struct symbol *p;

	sym->symbol_list = create_symbol_list(sctx_ sym->inline_symbol_list);
	FOR_EACH_PTR(arg_list, p) {
		p->replace = p;
	} END_FOR_EACH_PTR(p);
	fn->stmt = alloc_statement(sctx_ fn->tok, STMT_COMPOUND);
	copy_statement(sctx_ fn->inline_stmt, fn->stmt);
	unset_replace_list(sctx_ sym->symbol_list);
	unset_replace_list(sctx_ arg_list);
}
