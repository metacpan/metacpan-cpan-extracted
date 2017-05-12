/*
 * sparse/dissect.c
 *
 * Started by Oleg Nesterov <oleg@tv-sign.ru>
 *
 * Licensed under the Open Software License version 1.1
 */

#include "dissect.h"
#include "token.h"

#define	U_VOID	 0x00
#define	U_SELF	((1 << U_SHIFT) - 1)
#define	U_MASK	(U_R_VAL | U_W_VAL | U_R_AOF)

#define	DO_LIST(l__, p__, expr__)		\
	do {					\
		typeof(l__->list[0]) p__;	\
		FOR_EACH_PTR(l__, p__)		\
			expr__;			\
		END_FOR_EACH_PTR(p__);		\
	} while (0)

#define	DO_2_LIST(l1__,l2__, p1__,p2__, expr__)	\
	do {					\
		typeof(l1__->list[0]) p1__;	\
		typeof(l2__->list[0]) p2__;	\
		PREPARE_PTR_LIST(l1__, p1__);	\
		FOR_EACH_PTR(l2__, p2__)	\
			expr__;			\
			NEXT_PTR_LIST(p1__);	\
		END_FOR_EACH_PTR(p2__);		\
		FINISH_PTR_LIST(p1__);		\
	} while (0)


typedef unsigned usage_t;

#ifndef DO_CTX
struct reporter *reporter;
static struct symbol *return_type;
#endif

static void do_sym_list(SCTX_ struct symbol_list *list);

static struct symbol
	*base_type_dis(SCTX_ struct symbol *sym),
	*do_initializer(SCTX_ struct symbol *type, struct expression *expr),
	*do_expression(SCTX_ usage_t mode, struct expression *expr),
	*do_statement(SCTX_ usage_t mode, struct statement *stmt);

static inline int is_ptr(struct symbol *type)
{
	return type->type == SYM_PTR || type->type == SYM_ARRAY;
}

static inline usage_t u_rval(usage_t mode)
{
	return mode & (U_R_VAL | (U_MASK << U_SHIFT))
		? U_R_VAL : 0;
}

static inline usage_t u_addr(usage_t mode)
{
	return mode = mode & U_MASK
		? U_R_AOF | (mode & U_W_AOF) : 0;
}

static usage_t u_lval(SCTX_ struct symbol *type)
{
	int wptr = is_ptr(type) && !(type->ctype.modifiers & MOD_CONST);
	return wptr || type == &sctxp bad_ctype
		? U_W_AOF | U_R_VAL : U_R_VAL;
}

static usage_t fix_mode(SCTX_ struct symbol *type, usage_t mode)
{
	mode &= (U_SELF | (U_SELF << U_SHIFT));

	switch (type->type) {
		case SYM_BASETYPE:
			if (!type->ctype.base_type)
				break;
		case SYM_ENUM:
		case SYM_BITFIELD:
			if (mode & U_MASK)
				mode &= U_SELF;
		default:

		break; case SYM_FN:
			if (mode & U_R_VAL)
				mode |= U_R_AOF;
			mode &= ~(U_R_VAL | U_W_AOF);

		break; case SYM_ARRAY:
			if (mode & (U_MASK << U_SHIFT))
				mode >>= U_SHIFT;
			else if (mode != U_W_VAL)
				mode = u_addr(mode);
	}

	if (!(mode & U_R_AOF))
		mode &= ~U_W_AOF;

	return mode;
}

static inline struct symbol *no_member(SCTX_ struct ident *name)
{
	static struct symbol sym = {
		.type = SYM_BAD,
	};

	sym.ctype.base_type = &sctxp bad_ctype;
	sym.ident = name;

	return &sym;
}

static struct symbol *report_member(SCTX_ mode_t mode, struct token *pos,
					struct symbol *type, struct symbol *mem)
{
	struct symbol *ret = mem->ctype.base_type;

	if (sctxp reporter->r_member)
		sctxp reporter->r_member(sctx_ fix_mode(sctx_ ret, mode), pos, type, mem);

	return ret;
}

static void report_implicit(SCTX_ usage_t mode, struct token *pos, struct symbol *type)
{
	if (type->type != SYM_STRUCT && type->type != SYM_UNION)
		return;

	if (!sctxp reporter->r_member)
		return;

	if (type->ident != NULL)
		sctxp reporter->r_member(sctx_ mode, pos, type, NULL);

	DO_LIST(type->symbol_list, mem,
		report_implicit(sctx_ mode, pos, base_type_dis(sctx_ mem)));
}

static inline struct symbol *expr_symbol(SCTX_ struct expression *expr)
{
	struct symbol *sym = expr->symbol;

	if (!sym) {
		sym = lookup_symbol(sctx_ expr->symbol_name, NS_SYMBOL);

		if (!sym) {
			sym = alloc_symbol(sctx_ expr->tok, SYM_BAD);
			bind_symbol(sctx_ sym, expr->symbol_name, NS_SYMBOL);
			sym->ctype.modifiers = MOD_EXTERN;
		}
	}

	if (!sym->ctype.base_type)
		sym->ctype.base_type = &sctxp bad_ctype;

	return sym;
}

static struct symbol *report_symbol(SCTX_ usage_t mode, struct expression *expr)
{
	struct symbol *sym = expr_symbol(sctx_ expr);
	struct symbol *ret = base_type_dis(sctx_ sym);

	if (0 && ret->type == SYM_ENUM)
		return report_member(sctx_ mode, expr->pos, ret, expr->symbol);

	if (sctxp reporter->r_symbol)
		sctxp reporter->r_symbol(sctx_ fix_mode(sctx_ ret, mode), expr->pos, sym);

	return ret;
}

static inline struct ident *mk_name(SCTX_ struct ident *root, struct ident *node)
{
	char name[256];

	snprintf(name, sizeof(name), "%.*s:%.*s",
			root ? root->len : 0, root ? root->name : "",
			node ? node->len : 0, node ? node->name : "");

	return built_in_ident(sctx_ name);
}

static void examine_sym_node(SCTX_ struct symbol *node, struct ident *root)
{
	struct symbol *base;
	struct ident *name;

	if (node->examined)
		return;

	node->examined = 1;
	name = node->ident;

	while ((base = node->ctype.base_type) != NULL)
		switch (base->type) {
		case SYM_TYPEOF:
			node->ctype.base_type =
				do_expression(sctx_ U_VOID, base->initializer);
			break;

		case SYM_ARRAY:
			do_expression(sctx_ U_R_VAL, base->array_size);
		case SYM_PTR: case SYM_FN:
			node = base;
			break;

		case SYM_STRUCT: case SYM_UNION: //case SYM_ENUM:
			if (base->evaluated)
				return;
			if (!base->symbol_list)
				return;
			base->evaluated = 1;

			if (!base->ident && name)
				base->ident = mk_name(sctx_ root, name);
			if (base->ident && sctxp reporter->r_symdef)
				sctxp reporter->r_symdef(sctx_ base);
			DO_LIST(base->symbol_list, mem,
				examine_sym_node(sctx_ mem, base->ident ?: root));
		default:
			return;
		}
}

static struct symbol *base_type_dis(SCTX_ struct symbol *sym)
{
	if (!sym)
		return &sctxp bad_ctype;

	if (sym->type == SYM_NODE)
		examine_sym_node(sctx_ sym, NULL);

	return sym->ctype.base_type	// builtin_fn_type
		?: &sctxp bad_ctype;
}

static struct symbol *__lookup_member(SCTX_ struct symbol *type, struct ident *name, int *p_addr)
{
	struct symbol *node;
	int addr = 0;

	FOR_EACH_PTR(type->symbol_list, node)
		if (!name) {
			if (addr == *p_addr)
				return node;
		}
		else if (node->ident == NULL) {
			node = __lookup_member(sctx_ node->ctype.base_type, name, NULL);
			if (node)
				goto found;
		}
		else if (node->ident == name) {
found:
			if (p_addr)
				*p_addr = addr;
			return node;
		}
		addr++;
	END_FOR_EACH_PTR(node);

	return NULL;
}

static struct symbol *lookup_member(SCTX_ struct symbol *type, struct ident *name, int *addr)
{
	return __lookup_member(sctx_ type, name, addr)
		?: no_member(sctx_ name);
}

static struct expression *peek_preop(SCTX_ struct expression *expr, int op)
{
	do {
		if (expr->type != EXPR_PREOP)
			break;
		if (expr->op == op)
			return expr->unop;
		if (expr->op == '(')
			expr = expr->unop;
		else
			break;
	} while (expr);

	return NULL;
}

static struct symbol *do_expression(SCTX_ usage_t mode, struct expression *expr)
{
	struct symbol *ret = &sctxp int_ctype;

again:
	if (expr) switch (expr->type) {
	default:
		warning(sctx_ expr->pos->pos, "bad expr->type: %d", expr->type);

	case EXPR_TYPE:		// [struct T]; Why ???
	case EXPR_VALUE:
	case EXPR_FVALUE:

	break; case EXPR_LABEL:
		ret = &sctxp label_ctype;

	break; case EXPR_STRING:
		ret = &sctxp string_ctype;

	break; case EXPR_STATEMENT:
		ret = do_statement(sctx_ mode, expr->statement);

	break; case EXPR_SIZEOF: case EXPR_ALIGNOF: case EXPR_PTRSIZEOF:
		do_expression(sctx_ U_VOID, expr->cast_expression);

	break; case EXPR_COMMA:
		do_expression(sctx_ U_VOID, expr->left);
		ret = do_expression(sctx_ mode, expr->right);

	break; case EXPR_CAST: case EXPR_FORCE_CAST: //case EXPR_IMPLIED_CAST:
		ret = base_type_dis(sctx_ expr->cast_type);
		do_initializer(sctx_ ret, expr->cast_expression);

	break; case EXPR_COMPARE: case EXPR_LOGICAL:
		mode = u_rval(mode);
		do_expression(sctx_ mode, expr->left);
		do_expression(sctx_ mode, expr->right);

	break; case EXPR_CONDITIONAL: //case EXPR_SELECT:
		do_expression(sctx_ expr->cond_true
					? U_R_VAL : U_R_VAL | mode,
				expr->conditional);
		ret = do_expression(sctx_ mode, expr->cond_true);
		ret = do_expression(sctx_ mode, expr->cond_false);

	break; case EXPR_CALL:
		ret = do_expression(sctx_ U_R_PTR, expr->fn);
		if (is_ptr(ret))
			ret = ret->ctype.base_type;
		DO_2_LIST(ret->arguments, expr->args, arg, val,
			do_expression(sctx_ u_lval(sctx_ base_type_dis(sctx_ arg)), val));
		ret = ret->type == SYM_FN ? base_type_dis(sctx_ ret)
			: &sctxp bad_ctype;

	break; case EXPR_ASSIGNMENT:
		mode |= U_W_VAL | U_R_VAL;
		if (expr->op == '=')
			mode &= ~U_R_VAL;
		ret = do_expression(sctx_ mode, expr->left);
		report_implicit(sctx_ mode, expr->pos, ret);
		mode = expr->op == '='
			? u_lval(sctx_ ret) : U_R_VAL;
		do_expression(sctx_ mode, expr->right);

	break; case EXPR_BINOP: {
		struct symbol *l, *r;
		mode |= u_rval(mode);
		l = do_expression(sctx_ mode, expr->left);
		r = do_expression(sctx_ mode, expr->right);
		if (expr->op != '+' && expr->op != '-')
			;
		else if (!is_ptr_type(r))
			ret = l;
		else if (!is_ptr_type(l))
			ret = r;
	}

	break; case EXPR_PREOP: case EXPR_POSTOP: {
		struct expression *unop = expr->unop;

		switch (expr->op) {
		case SPECIAL_INCREMENT:
		case SPECIAL_DECREMENT:
			mode |= U_W_VAL | U_R_VAL;
		default:
			mode |= u_rval(mode);
		case '(':
			ret = do_expression(sctx_ mode, unop);

		break; case '&':
			if ((expr = peek_preop(sctx_ unop, '*')))
				goto again;
			ret = alloc_symbol(sctx_ unop->tok, SYM_PTR);
			ret->ctype.base_type =
				do_expression(sctx_ u_addr(mode), unop);

		break; case '*':
			if ((expr = peek_preop(sctx_ unop, '&')))
				goto again;
			if (mode & (U_MASK << U_SHIFT))
				mode |= U_R_VAL;
			mode <<= U_SHIFT;
			if (mode & (U_R_AOF << U_SHIFT))
				mode |= U_R_VAL;
			if (mode & (U_W_VAL << U_SHIFT))
				mode |= U_W_AOF;
			ret = do_expression(sctx_ mode, unop);
			ret = is_ptr(ret) ? base_type_dis(sctx_ ret)
				: &sctxp bad_ctype;
		}
	}

	break; case EXPR_DEREF: {
		struct symbol *p_type;
		usage_t p_mode;

		p_mode = mode & U_SELF;
		if (!(mode & U_MASK) && (mode & (U_MASK << U_SHIFT)))
			p_mode = U_R_VAL;
		p_type = do_expression(sctx_ p_mode, expr->deref);

		ret = report_member(sctx_ mode, expr->pos, p_type,
			lookup_member(sctx_ p_type, expr->member, NULL));
	}

	break; case EXPR_SYMBOL:
		ret = report_symbol(sctx_ mode, expr);
	}

	return ret;
}

static void do_asm_xputs(SCTX_ usage_t mode, struct expression_list *xputs)
{
	int nr = 0;

	DO_LIST(xputs, expr,
		if (++nr % 3 == 0)
			do_expression(sctx_ U_W_AOF | mode, expr));
}

static struct symbol *do_statement(SCTX_ usage_t mode, struct statement *stmt)
{
	struct symbol *ret = &sctxp void_ctype;

	if (stmt) switch (stmt->type) {
	default:
		warning(sctx_ stmt->pos->pos, "bad stmt->type: %d", stmt->type);

	case STMT_NONE:
	case STMT_RANGE:
	case STMT_CONTEXT:

	break; case STMT_DECLARATION:
		do_sym_list(sctx_ stmt->declaration);

	break; case STMT_EXPRESSION:
		ret = do_expression(sctx_ mode, stmt->expression);

	break; case STMT_RETURN:
		do_expression(sctx_ u_lval(sctx_ sctxp return_type), stmt->expression);

	break; case STMT_ASM:
		do_expression(sctx_ U_R_VAL, stmt->asm_string);
		do_asm_xputs(sctx_ U_W_VAL, stmt->asm_outputs);
		do_asm_xputs(sctx_ U_R_VAL, stmt->asm_inputs);

	break; case STMT_COMPOUND: {
		int count;

		count = statement_list_size(sctx_ stmt->stmts);
		DO_LIST(stmt->stmts, st,
			ret = do_statement(sctx_ --count ? U_VOID : mode, st));
	}

	break; case STMT_ITERATOR:
		do_sym_list(sctx_ stmt->iterator_syms);
		do_statement(sctx_ U_VOID, stmt->iterator_pre_statement);
		do_expression(sctx_ U_R_VAL, stmt->iterator_pre_condition);
		do_statement(sctx_ U_VOID, stmt->iterator_post_statement);
		do_statement(sctx_ U_VOID, stmt->iterator_statement);
		do_expression(sctx_ U_R_VAL, stmt->iterator_post_condition);

	break; case STMT_IF:
		do_expression(sctx_ U_R_VAL, stmt->if_conditional);
		do_statement(sctx_ U_VOID, stmt->if_true);
		do_statement(sctx_ U_VOID, stmt->if_false);

	break; case STMT_SWITCH:
		do_expression(sctx_ U_R_VAL, stmt->switch_expression);
		do_statement(sctx_ U_VOID, stmt->switch_statement);

	break; case STMT_CASE:
		do_expression(sctx_ U_R_VAL, stmt->case_expression);
		do_expression(sctx_ U_R_VAL, stmt->case_to);
		do_statement(sctx_ U_VOID, stmt->case_statement);

	break; case STMT_GOTO:
		do_expression(sctx_ U_R_PTR, stmt->goto_expression);

	break; case STMT_LABEL:
		do_statement(sctx_ mode, stmt->label_statement);

	}

	return ret;
}

static struct symbol *do_initializer(SCTX_ struct symbol *type, struct expression *expr)
{
	struct symbol *m_type;
	struct expression *m_expr;
	int m_addr;

	if (expr) switch (expr->type) {
	default:
		do_expression(sctx_ u_lval(sctx_ type), expr);

	break; case EXPR_INDEX:
		do_initializer(sctx_ base_type_dis(sctx_ type), expr->idx_expression);

	break; case EXPR_INITIALIZER:
		m_addr = 0;
		FOR_EACH_PTR(expr->expr_list, m_expr)
			if (type->type == SYM_ARRAY) {
				m_type = base_type_dis(sctx_ type);
				if (m_expr->type == EXPR_INDEX)
					m_expr = m_expr->idx_expression;
			} else {
				struct token *pos = m_expr->pos;
				struct ident *m_name = NULL;

				if (m_expr->type == EXPR_IDENTIFIER) {
					m_name = m_expr->expr_ident;
					m_expr = m_expr->ident_expression;
				}

				m_type = report_member(sctx_ U_W_VAL, pos, type,
						lookup_member(sctx_ type, m_name, &m_addr));
				if (m_expr->type != EXPR_INITIALIZER)
					report_implicit(sctx_ U_W_VAL, pos, m_type);
			}
			do_initializer(sctx_ m_type, m_expr);
			m_addr++;
		END_FOR_EACH_PTR(m_expr);
	}

	return type;
}

static inline struct symbol *do_symbol(SCTX_ struct symbol *sym)
{
	struct symbol *type;

	type = base_type_dis(sctx_ sym);

	if (sctxp reporter->r_symdef)
		sctxp reporter->r_symdef(sctx_ sym);

	sctxp reporter->indent++;
	switch (type->type) {
	default:
		if (!sym->initializer)
			break;
		if (sctxp reporter->r_symbol)
			sctxp reporter->r_symbol(sctx_ U_W_VAL, sym->pos, sym);
		do_initializer(sctx_ type, sym->initializer);
		
	break; case SYM_FN:
		do_sym_list(sctx_ type->arguments);
		sctxp return_type = base_type_dis(sctx_ type);
		do_statement(sctx_ U_VOID, sym->ctype.modifiers & MOD_INLINE
					? type->inline_stmt
					: type->stmt);
	}
	sctxp reporter->indent--;

	return type;
}

static void do_sym_list(SCTX_ struct symbol_list *list)
{
	DO_LIST(list, sym, do_symbol(sctx_ sym));
}

void dissect(SCTX_ struct symbol_list *list, struct reporter *rep)
{
	sctxp reporter = rep;
	do_sym_list(sctx_ list);
}

/******** disssect arr ********/

#ifndef DO_CTX
static unsigned dotc_stream;
#endif

char dissect_storage(SCTX_ struct symbol *sym)
{
	int t = sym->type;
	unsigned m = sym->ctype.modifiers;

	if (m & MOD_INLINE || t == SYM_STRUCT || t == SYM_UNION /*|| t == SYM_ENUM*/)
		return sym->pos->pos.stream == sctxp dotc_stream ? 's' : 'g';

	return (m & MOD_STATIC) ? 's' : (m & MOD_NONLOCAL) ? 'g' : 'l';
}

const char *dissect_show_mode(SCTX_ unsigned mode)
{
	static char str[3];

	if (mode == -1)
		return "def";

#define	U(u_r)	"-rwm"[(mode / u_r) & 3]
	str[0] = U(U_R_AOF);
	str[1] = U(U_R_VAL);
	str[2] = U(U_R_PTR);
#undef	U

	return str;
}

#define PUSH_REPORT(n,r) do {						\
		int i = sctxp reporter->defs_pos++;				\
		if (i >= sctxp reporter->defs_cnt)  {				\
			sctxp reporter->defs_cnt = (i+1)*2;			\
			sctxp reporter->defs = realloc(sctxp reporter->defs,sctxp reporter->defs_cnt*sizeof(void*)); \
		}							\
		r = (struct reporter_def*)(sctxp reporter->defs[i] = malloc(sizeof(struct reporter_def)));	\
		r->indent = sctxp reporter->indent;				\
	} while(0);

static void r_symdef(SCTX_ struct symbol *sym)
{
	struct reporter_def *r;
	PUSH_REPORT(symdefs,r);
	r->type = REPORT_SYMDEF;
	r->sym = sym;
}

static void r_symbol(SCTX_ unsigned mode, struct token *pos, struct symbol *sym)
{
	struct reporter_def *r;
	PUSH_REPORT(syms,r);
	r->type = REPORT_SYMBOL;
	r->sym_mode = mode;
	r->sym_pos = pos;
	r->sym_sym = sym;
}

static void r_member(SCTX_ unsigned mode, struct token *pos, struct symbol *sym, struct symbol *mem)
{
	struct reporter_def *r;
	PUSH_REPORT(members,r);
	r->type = REPORT_MEMBER;
	r->mem_mode = mode;
	r->mem_pos = pos;
	r->mem_sym = sym;
	r->mem_mem = mem;
}

int dissect_arr(SCTX_ int argc, char **argv)
{
	static struct reporter reporter = {
		.r_symdef = r_symdef,
		.r_symbol = r_symbol,
		.r_member = r_member,
	};
	struct string_list *filelist = NULL;
	char *file;

	sparse_initialize(sctx_ argc, argv, &filelist);

	FOR_EACH_PTR_NOTAG(filelist, file) {
		sctxp dotc_stream = sctxp input_stream_nr;
		dissect(sctx_ __sparse(sctx_ file), &reporter);
	} END_FOR_EACH_PTR_NOTAG(file);

	return 0;
}
