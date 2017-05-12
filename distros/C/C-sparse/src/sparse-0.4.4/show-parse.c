/*
 * sparse/show-parse.c
 *
 * Copyright (C) 2003 Transmeta Corp.
 *               2003-2004 Linus Torvalds
 *
 *  Licensed under the Open Software License version 1.1
 *
 * Print out results of parsing for debugging and testing.
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
#include "scope.h"
#include "expression.h"
#include "target.h"

static int show_symbol_expr(SCTX_ struct symbol *sym);
static int show_string_expr(SCTX_ struct expression *expr);

static void do_debug_symbol(SCTX_ struct symbol *sym, int indent)
{
	static const char indent_string[] = "                                  ";
	static const char *typestr[] = {
		[SYM_UNINITIALIZED] = "none",
		[SYM_PREPROCESSOR] = "cpp.",
		[SYM_BASETYPE] = "base",
		[SYM_NODE] = "node",
		[SYM_PTR] = "ptr.",
		[SYM_FN] = "fn..",
		[SYM_ARRAY] = "arry",
		[SYM_STRUCT] = "strt",
		[SYM_UNION] = "unin",
		[SYM_ENUM] = "enum",
		[SYM_TYPEDEF] = "tdef",
		[SYM_TYPEOF] = "tpof",
		[SYM_MEMBER] = "memb",
		[SYM_BITFIELD] = "bitf",
		[SYM_LABEL] = "labl",
		[SYM_RESTRICT] = "rstr",
		[SYM_FOULED] = "foul",
		[SYM_BAD] = "bad.",
	};
	struct sym_context *context;
	int i;

	if (!sym)
		return;
	fprintf(stderr, "%.*s%s%3d:%lu %s %s (as: %d) %p (%s:%d:%d) %s\n",
		indent, indent_string, typestr[sym->type],
		sym->bit_size, sym->ctype.alignment,
		modifier_string(sctx_ sym->ctype.modifiers), show_ident(sctx_ sym->ident), sym->ctype.as,
		sym, stream_name(sctx_ sym->pos->pos.stream), sym->pos->pos.line, sym->pos->pos.pos,
		builtin_typename(sctx_ sym) ?: "");
	i = 0;
	FOR_EACH_PTR(sym->ctype.contexts, context) {
		/* FIXME: should print context expression */
		fprintf(stderr, "< context%d: in=%d, out=%d\n",
			i, context->in, context->out);
		fprintf(stderr, "  end context%d >\n", i);
		i++;
	} END_FOR_EACH_PTR(context);
	if (sym->type == SYM_FN) {
		struct symbol *arg;
		i = 0;
		FOR_EACH_PTR(sym->arguments, arg) {
			fprintf(stderr, "< arg%d:\n", i);
			do_debug_symbol(sctx_ arg, 0);
			fprintf(stderr, "  end arg%d >\n", i);
			i++;
		} END_FOR_EACH_PTR(arg);
	}
	do_debug_symbol(sctx_ sym->ctype.base_type, indent+2);
}

void debug_symbol(SCTX_ struct symbol *sym)
{
	do_debug_symbol(sctx_ sym, 0);
}

/*
 * Symbol type printout. The type system is by far the most
 * complicated part of C - everything else is trivial.
 */
const char *modifier_string(SCTX_ unsigned long mod)
{
	static char buffer[100];
	int len = 0;
	int i;
	struct mod_name {
		unsigned long mod;
		const char *name;
	} *m;

	static struct mod_name mod_names[] = {
		{MOD_AUTO,		"auto"},
		{MOD_REGISTER,		"register"},
		{MOD_STATIC,		"static"},
		{MOD_EXTERN,		"extern"},
		{MOD_CONST,		"const"},
		{MOD_VOLATILE,		"volatile"},
		{MOD_SIGNED,		"[signed]"},
		{MOD_UNSIGNED,		"[unsigned]"},
		{MOD_CHAR,		"[char]"},
		{MOD_SHORT,		"[short]"},
		{MOD_LONG,		"[long]"},
		{MOD_LONGLONG,		"[long long]"},
		{MOD_LONGLONGLONG,	"[long long long]"},
		{MOD_TYPEDEF,		"[typedef]"},
		{MOD_TLS,		"[tls]"},
		{MOD_INLINE,		"inline"},
		{MOD_ADDRESSABLE,	"[addressable]"},
		{MOD_NOCAST,		"[nocast]"},
		{MOD_NODEREF,		"[noderef]"},
		{MOD_ACCESSED,		"[accessed]"},
		{MOD_TOPLEVEL,		"[toplevel]"},
		{MOD_ASSIGNED,		"[assigned]"},
		{MOD_TYPE,		"[type]"},
		{MOD_SAFE,		"[safe]"},
		{MOD_USERTYPE,		"[usertype]"},
		{MOD_NORETURN,		"[noreturn]"},
		{MOD_EXPLICITLY_SIGNED,	"[explicitly-signed]"},
		{MOD_BITWISE,		"[bitwise]"},
		{MOD_PURE,		"[pure]"},
	};

	for (i = 0; i < ARRAY_SIZE(mod_names); i++) {
		m = mod_names + i;
		if (mod & m->mod) {
			char c;
			const char *name = m->name;
			while ((c = *name++) != '\0' && len + 2 < sizeof buffer)
				buffer[len++] = c;
			buffer[len++] = ' ';
		}
	}
	buffer[len] = 0;
	return buffer;
}

static void show_struct_member(SCTX_ struct symbol *sym)
{
	printf("\t%s:%d:%ld at offset %ld.%d", show_ident(sctx_ sym->ident), sym->bit_size, sym->ctype.alignment, sym->offset, sym->bit_offset);
	printf("\n");
}

void show_symbol_list(SCTX_ struct symbol_list *list, const char *sep)
{
	struct symbol *sym;
	const char *prepend = "";

	FOR_EACH_PTR(list, sym) {
		puts(prepend);
		prepend = ", ";
		show_symbol(sctx_ sym);
	} END_FOR_EACH_PTR(sym);
}

struct type_name {
	int fnargs;
	char *start;
	char *end;
};

static void prepend_cnt(SCTX_ struct type_name *name, const char *buffer, int n)
{
	if (name->fnargs) {
		int l = name->end - name->start;
		if (name->fnargs < (l + n + 1)) {
			name->fnargs = (l + n + 1) * 2;
			name->start = (char *)realloc(name->start, name->fnargs);
			name->end = name->start + l;
		}
		if (l)
			memmove(name->start+n, name->start, l);
		if (n)
			memcpy(name->start, buffer, n);
		name->end += n;
	} else {
		name->start -= n;
		memcpy(name->start, buffer, n);
	}
}

static void FORMAT_ATTR(2+SCTXCNT) prepend(SCTX_ struct type_name *name, const char *fmt, ...)
{
	static char buffer[512];
	int n;

	va_list args;
	va_start(args, fmt);
	n = vsprintf(buffer, fmt, args);
	va_end(args);

	prepend_cnt(sctx_ name, buffer, n);
}

static void append_cnt(SCTX_ struct type_name *name, const char *buffer, int n)
{
	if (name->fnargs) {
		int l = name->end - name->start;
		if (name->fnargs < (l + n + 1)) {
			name->fnargs = (l + n + 1) * 2;
			name->start = (char *)realloc(name->start, name->fnargs);
			name->end = name->start + l;
		}
		if (n)
			memcpy(name->end, buffer, n);
		name->end += n;
	} else {
		memcpy(name->end, buffer, n);
		name->end += n;
	}
}

static void FORMAT_ATTR(2+SCTXCNT) append(SCTX_ struct type_name *name, const char *fmt, ...)
{
	static char buffer[512];
	int n;

	va_list args;
	va_start(args, fmt);
	n = vsprintf(buffer, fmt, args);
	va_end(args);

	append_cnt(sctx_ name, buffer, n);
}

#ifndef DO_CTX
static
#else
void sparse_ctx_init_show_parse(SCTX) {
#endif

struct ctype_name typenames[] = {
	{ & sctxp char_ctype,  "char" },
	{ &sctxp schar_ctype,  "signed char" },
	{ &sctxp uchar_ctype,  "unsigned char" },
	{ &sctxp  short_ctype, "short" },
	{ &sctxp sshort_ctype, "signed short" },
	{ &sctxp ushort_ctype, "unsigned short" },
	{ &sctxp  int_ctype,   "int" },
	{ &sctxp sint_ctype,   "signed int" },
	{ &sctxp uint_ctype,   "unsigned int" },
	{ &sctxp slong_ctype,  "signed long" },
	{ &sctxp  long_ctype,  "long" },
	{ &sctxp ulong_ctype,  "unsigned long" },
	{ &sctxp  llong_ctype, "long long" },
	{ &sctxp sllong_ctype, "signed long long" },
	{ &sctxp ullong_ctype, "unsigned long long" },
	{ &sctxp  lllong_ctype, "long long long" },
	{ &sctxp slllong_ctype, "signed long long long" },
	{ &sctxp ulllong_ctype, "unsigned long long long" },

	{ &sctxp void_ctype,   "void" },
	{ &sctxp bool_ctype,   "bool" },
	{ &sctxp string_ctype, "string" },

	{ &sctxp float_ctype,  "float" },
	{ &sctxp double_ctype, "double" },
	{ &sctxp ldouble_ctype,"long double" },
	{ &sctxp incomplete_ctype, "incomplete type" },
	{ &sctxp int_type, "abstract int" },
	{ &sctxp fp_type, "abstract fp" },
	{ &sctxp label_ctype, "label type" },
	{ &sctxp bad_ctype, "bad type" },
};

#ifndef DO_CTX
	static int typenames_cnt = ARRAY_SIZE(typenames);
#else
	sctxp typenames_cnt = ARRAY_SIZE(typenames);
	sctxp typenames = malloc(sizeof(typenames)); /* todo: release */
	memcpy(sctxp typenames, typenames, sizeof(typenames));
}
#endif


int builtin_type(SCTX_ struct symbol *sym)
{
	int i;

	for (i = 0; i < sctxp typenames_cnt; i++)
		if (sctxp typenames[i].sym == sym)
			return 1;
	return 0;
}

const char *builtin_typename(SCTX_ struct symbol *sym)
{
	int i;

	for (i = 0; i < sctxp typenames_cnt; i++)
		if (sctxp typenames[i].sym == sym)
			return sctxp typenames[i].name;
	return NULL;
}

const char *builtin_ctypename(SCTX_ struct ctype *ctype)
{
	int i;

	for (i = 0; i < sctxp typenames_cnt; i++)
		if (&sctxp typenames[i].sym->ctype == ctype)
			return sctxp typenames[i].name;
	return NULL;
}

static void do_show_type(SCTX_ struct symbol *sym, struct type_name *name)
{
	const char *typename;
	unsigned long mod = 0;
	int as = 0;
	int was_ptr = 0;
	int restr = 0;
	int fouled = 0;

deeper:
	if (!sym || (sym->type != SYM_NODE && sym->type != SYM_ARRAY &&
		     sym->type != SYM_BITFIELD)) {
		const char *s;
		size_t len;

		if (as)
			prepend(sctx_ name, "<asn:%d>", as);

		s = modifier_string(sctx_ mod);
		len = strlen(s);
		prepend_cnt(sctx_ name, s, len);
		mod = 0;
		as = 0;
	}

	if (!sym)
		goto out;

	if ((typename = builtin_typename(sctx_ sym))) {
		int len = strlen(typename);
		if (name->start != name->end)
			prepend_cnt(sctx_ name, " ", 1);
		prepend_cnt(sctx_ name, typename, len);
		goto out;
	}

	/* Prepend */
	switch (sym->type) {
	case SYM_PTR:
		prepend(sctx_ name, "*");
		mod = sym->ctype.modifiers;
		as = sym->ctype.as;
		was_ptr = 1;
		break;

	case SYM_FN:
		if (was_ptr) {
			prepend(sctx_ name, "( ");
			append(sctx_ name, " )");
			was_ptr = 0;
		}
		if (name->fnargs) {
			struct symbol *a; int i = 0;
			append(sctx_ name, "(");
			FOR_EACH_PTR(sym->arguments, a) {
				const char *n = show_typename_fn(sctx_ a);
				if (i != 0)
					append(sctx_ name, ", ");
				append(sctx_ name, "%s", n);
				free((char *)n);
				i++;
			} END_FOR_EACH_PTR(a);
			append(sctx_ name, ")");
		} else 
			append(sctx_ name, "( ... )");
		break;

	case SYM_STRUCT:
		if (name->start != name->end)
			prepend_cnt(sctx_ name, " ", 1);
		prepend(sctx_ name, "struct %s", show_ident(sctx_ sym->ident));
		goto out;

	case SYM_UNION:
		if (name->start != name->end)
			prepend_cnt(sctx_ name, " ", 1);
		prepend(sctx_ name, "union %s", show_ident(sctx_ sym->ident));
		goto out;

	case SYM_ENUM:
		prepend(sctx_ name, "enum %s ", show_ident(sctx_ sym->ident));
		break;

	case SYM_NODE:
		append(sctx_ name, "%s", show_ident(sctx_ sym->ident));
		mod |= sym->ctype.modifiers;
		as |= sym->ctype.as;
		break;

	case SYM_BITFIELD:
		mod |= sym->ctype.modifiers;
		as |= sym->ctype.as;
		append(sctx_ name, ":%d", sym->bit_size);
		break;

	case SYM_LABEL:
		append(sctx_ name, "label(%s:%p)", show_ident(sctx_ sym->ident), sym);
		return;

	case SYM_ARRAY:
		mod |= sym->ctype.modifiers;
		as |= sym->ctype.as;
		if (was_ptr) {
			prepend(sctx_ name, "( ");
			append(sctx_ name, " )");
			was_ptr = 0;
		}
		append(sctx_ name, "[%lld]", get_expression_value(sctx_ sym->array_size));
		break;

	case SYM_RESTRICT:
		if (!sym->ident) {
			restr = 1;
			break;
		}
		if (name->start != name->end)
			prepend_cnt(sctx_ name, " ", 1);
		prepend(sctx_ name, "restricted %s", show_ident(sctx_ sym->ident));
		goto out;

	case SYM_FOULED:
		fouled = 1;
		break;

	default:
		if (name->start != name->end)
			prepend_cnt(sctx_ name, " ", 1);
		prepend(sctx_ name, "unknown type %d", sym->type);
		goto out;
	}

	sym = sym->ctype.base_type;
	goto deeper;

out:
	if (restr)
		prepend(sctx_ name, "restricted ");
	if (fouled)
		prepend(sctx_ name, "fouled ");
}

void show_type(SCTX_ struct symbol *sym)
{
	char array[200];
	struct type_name name;
	name.fnargs = 0;
	name.start = name.end = array+100;
	do_show_type(sctx_ sym, &name);
	*name.end = 0;
	printf("%s", name.start);
}

const char *show_typename(SCTX_ struct symbol *sym)
{
	static char array[200];
	struct type_name name;
	name.fnargs = 0;
	name.start = name.end = array+100;
	do_show_type(sctx_ sym, &name);
	*name.end = 0;
	return name.start;
}

const char *show_typename_fn(SCTX_ struct symbol *sym)
{
	struct type_name name; char *n;
	name.fnargs = 100;
	name.start = name.end = n = (char *) malloc(name.fnargs);
	do_show_type(sctx_ sym, &name);
	*name.end = 0;
	return name.start;
}

void show_symbol(SCTX_ struct symbol *sym)
{
	struct symbol *type;

	if (!sym)
		return;

	if (sym->ctype.alignment)
		printf(".align %ld\n", sym->ctype.alignment);

	show_type(sctx_ sym);
	type = sym->ctype.base_type;
	if (!type) {
		printf("\n");
		return;
	}

	/*
	 * Show actual implementation information
	 */
	switch (type->type) {
		struct symbol *member;

	case SYM_STRUCT:
	case SYM_UNION:
		printf(" {\n");
		FOR_EACH_PTR(type->symbol_list, member) {
			show_struct_member(sctx_ member);
		} END_FOR_EACH_PTR(member);
		printf("}\n");
		break;

	case SYM_FN: {
		struct statement *stmt = type->stmt;
		printf("\n");
		if (stmt) {
			int val;
			val = show_statement(sctx_ stmt);
			if (val)
				printf("\tmov.%d\t\tretval,%d\n", stmt->ret->bit_size, val);
			printf("\tret\n");
		}
		break;
	}

	default:
		printf("\n");
		break;
	}

	if (sym->initializer) {
		printf(" = \n");
		show_expression(sctx_ sym->initializer);
	}
}

static int show_symbol_init(SCTX_ struct symbol *sym);

static int new_pseudo(SCTX)
{
	static int nr = 0;
	return ++nr;
}

static int new_label(SCTX)
{
	static int label = 0;
	return ++label;
}

static void show_switch_statement(SCTX_ struct statement *stmt)
{
	int val = show_expression(sctx_ stmt->switch_expression);
	struct symbol *sym;
	printf("\tswitch v%d\n", val);

	/*
	 * Debugging only: Check that the case list is correct
	 * by printing it out.
	 *
	 * This is where a _real_ back-end would go through the
	 * cases to decide whether to use a lookup table or a
	 * series of comparisons etc
	 */
	printf("# case table:\n");
	FOR_EACH_PTR(stmt->switch_case->symbol_list, sym) {
		struct statement *case_stmt = sym->stmt;
		struct expression *expr = case_stmt->case_expression;
		struct expression *to = case_stmt->case_to;

		if (!expr) {
			printf("    default");
		} else {
			if (expr->type == EXPR_VALUE) {
				printf("    case %lld", expr->value);
				if (to) {
					if (to->type == EXPR_VALUE) {
						printf(" .. %lld", to->value);
					} else {
						printf(" .. what?");
					}
				}
			} else
				printf("    what?");
		}
		printf(": .L%p\n", sym->bb_target);
	} END_FOR_EACH_PTR(sym);
	printf("# end case table\n");

	show_statement(sctx_ stmt->switch_statement);

	if (stmt->switch_break->used)
		printf(".L%p:\n", stmt->switch_break->bb_target);
}

static void show_symbol_decl(SCTX_ struct symbol_list *syms)
{
	struct symbol *sym;
	FOR_EACH_PTR(syms, sym) {
		show_symbol_init(sctx_ sym);
	} END_FOR_EACH_PTR(sym);
}

static int show_return_stmt(SCTX_ struct statement *stmt);

/*
 * Print out a statement
 */
int show_statement(SCTX_ struct statement *stmt)
{
	if (!stmt)
		return 0;
	switch (stmt->type) {
	case STMT_DECLARATION:
		show_symbol_decl(sctx_ stmt->declaration);
		return 0;
	case STMT_RETURN:
		return show_return_stmt(sctx_ stmt);
	case STMT_COMPOUND: {
		struct statement *s;
		int last = 0;

		if (stmt->inline_fn) {
			show_statement(sctx_ stmt->args);
			printf("\tbegin_inline \t%s\n", show_ident(sctx_ stmt->inline_fn->ident));
		}
		FOR_EACH_PTR(stmt->stmts, s) {
			last = show_statement(sctx_ s);
		} END_FOR_EACH_PTR(s);
		if (stmt->ret) {
			int addr, bits;
			printf(".L%p:\n", stmt->ret);
			addr = show_symbol_expr(sctx_ stmt->ret);
			bits = stmt->ret->bit_size;
			last = new_pseudo(sctx );
			printf("\tld.%d\t\tv%d,[v%d]\n", bits, last, addr);
		}
		if (stmt->inline_fn)
			printf("\tend_inlined\t%s\n", show_ident(sctx_ stmt->inline_fn->ident));
		return last;
	}

	case STMT_EXPRESSION:
		return show_expression(sctx_ stmt->expression);
	case STMT_IF: {
		int val, target;
		struct expression *cond = stmt->if_conditional;

/* This is only valid if nobody can jump into the "dead" statement */
#if 0
		if (cond->type == EXPR_VALUE) {
			struct statement *s = stmt->if_true;
			if (!cond->value)
				s = stmt->if_false;
			show_statement(s);
			break;
		}
#endif
		val = show_expression(sctx_ cond);
		target = new_label(sctx );
		printf("\tje\t\tv%d,.L%d\n", val, target);
		show_statement(sctx_ stmt->if_true);
		if (stmt->if_false) {
			int last = new_label(sctx );
			printf("\tjmp\t\t.L%d\n", last);
			printf(".L%d:\n", target);
			target = last;
			show_statement(sctx_ stmt->if_false);
		}
		printf(".L%d:\n", target);
		break;
	}
	case STMT_SWITCH:
		show_switch_statement(sctx_ stmt);
		break;

	case STMT_CASE:
		printf(".L%p:\n", stmt->case_label);
		show_statement(sctx_ stmt->case_statement);
		break;

	case STMT_ITERATOR: {
		struct statement  *pre_statement = stmt->iterator_pre_statement;
		struct expression *pre_condition = stmt->iterator_pre_condition;
		struct statement  *statement = stmt->iterator_statement;
		struct statement  *post_statement = stmt->iterator_post_statement;
		struct expression *post_condition = stmt->iterator_post_condition;
		int val, loop_top = 0, loop_bottom = 0;

		show_symbol_decl(sctx_ stmt->iterator_syms);
		show_statement(sctx_ pre_statement);
		if (pre_condition) {
			if (pre_condition->type == EXPR_VALUE) {
				if (!pre_condition->value) {
					loop_bottom = new_label(sctx);   
					printf("\tjmp\t\t.L%d\n", loop_bottom);
				}
			} else {
				loop_bottom = new_label(sctx);
				val = show_expression(sctx_ pre_condition);
				printf("\tje\t\tv%d, .L%d\n", val, loop_bottom);
			}
		}
		if (!post_condition || post_condition->type != EXPR_VALUE || post_condition->value) {
			loop_top = new_label(sctx);
			printf(".L%d:\n", loop_top);
		}
		show_statement(sctx_ statement);
		if (stmt->iterator_continue->used)
			printf(".L%p:\n", stmt->iterator_continue);
		show_statement(sctx_ post_statement);
		if (!post_condition) {
			printf("\tjmp\t\t.L%d\n", loop_top);
		} else if (post_condition->type == EXPR_VALUE) {
			if (post_condition->value)
				printf("\tjmp\t\t.L%d\n", loop_top);
		} else {
			val = show_expression(sctx_ post_condition);
			printf("\tjne\t\tv%d, .L%d\n", val, loop_top);
		}
		if (stmt->iterator_break->used)
			printf(".L%p:\n", stmt->iterator_break);
		if (loop_bottom)
			printf(".L%d:\n", loop_bottom);
		break;
	}
	case STMT_NONE:
		break;
	
	case STMT_LABEL:
		printf(".L%p:\n", stmt->label_identifier);
		show_statement(sctx_ stmt->label_statement);
		break;

	case STMT_GOTO:
		if (stmt->goto_expression) {
			int val = show_expression(sctx_ stmt->goto_expression);
			printf("\tgoto\t\t*v%d\n", val);
		} else {
			printf("\tgoto\t\t.L%p\n", stmt->goto_label->bb_target);
		}
		break;
	case STMT_ASM:
		printf("\tasm( .... )\n");
		break;
	case STMT_CONTEXT: {
		int val = show_expression(sctx_ stmt->expression);
		printf("\tcontext( %d )\n", val);
		break;
	}
	case STMT_RANGE: {
		int val = show_expression(sctx_ stmt->range_expression);
		int low = show_expression(sctx_ stmt->range_low);
		int high = show_expression(sctx_ stmt->range_high);
		printf("\trange( %d %d-%d)\n", val, low, high); 
		break;
	}	
	}
	return 0;
}

static int show_call_expression(SCTX_ struct expression *expr)
{
	struct symbol *direct;
	struct expression *arg, *fn;
	int fncall, retval;
	int framesize;

	if (!expr->ctype) {
		warning(sctx_ expr->pos->pos, "\tcall with no type!");
		return 0;
	}

	framesize = 0;
	FOR_EACH_PTR_REVERSE(expr->args, arg) {
		int new = show_expression(sctx_ arg);
		int size = arg->ctype->bit_size;
		printf("\tpush.%d\t\tv%d\n", size, new);
		framesize += bits_to_bytes(sctx_ size);
	} END_FOR_EACH_PTR_REVERSE(arg);

	fn = expr->fn;

	/* Remove dereference, if any */
	direct = NULL;
	if (fn->type == EXPR_PREOP) {
		if (fn->unop->type == EXPR_SYMBOL) {
			struct symbol *sym = fn->unop->symbol;
			if (sym->ctype.base_type->type == SYM_FN)
				direct = sym;
		}
	}
	if (direct) {
		printf("\tcall\t\t%s\n", show_ident(sctx_ direct->ident));
	} else {
		fncall = show_expression(sctx_ fn);
		printf("\tcall\t\t*v%d\n", fncall);
	}
	if (framesize)
		printf("\tadd.%d\t\tvSP,vSP,$%d\n", sctxp bits_in_pointer, framesize);

	retval = new_pseudo(sctx );
	printf("\tmov.%d\t\tv%d,retval\n", expr->ctype->bit_size, retval);
	return retval;
}

static int show_comma(SCTX_ struct expression *expr)
{
	show_expression(sctx_ expr->left);
	return show_expression(sctx_ expr->right);
}

static int show_binop(SCTX_ struct expression *expr)
{
	int left = show_expression(sctx_ expr->left);
	int right = show_expression(sctx_ expr->right);
	int new = new_pseudo(sctx );
	const char *opname;
	static const char *name[] = {
		['+'] = "add", ['-'] = "sub",
		['*'] = "mul", ['/'] = "div",
		['%'] = "mod", ['&'] = "and",
		['|'] = "lor", ['^'] = "xor"
	};
	unsigned int op = expr->op;

	opname = show_special(sctx_ op);
	if (op < ARRAY_SIZE(name))
		opname = name[op];
	printf("\t%s.%d\t\tv%d,v%d,v%d\n", opname,
		expr->ctype->bit_size,
		new, left, right);
	return new;
}

static int show_slice(SCTX_ struct expression *expr)
{
	int target = show_expression(sctx_ expr->base);
	int new = new_pseudo(sctx );
	printf("\tslice.%d\t\tv%d,v%d,%d\n", expr->r_nrbits, target, new, expr->r_bitpos);
	return new;
}

static int show_regular_preop(SCTX_ struct expression *expr)
{
	int target = show_expression(sctx_ expr->unop);
	int new = new_pseudo(sctx );
	static const char *name[] = {
		['!'] = "nonzero", ['-'] = "neg",
		['~'] = "not",
	};
	unsigned int op = expr->op;
	const char *opname;

	opname = show_special(sctx_ op);
	if (op < ARRAY_SIZE(name))
		opname = name[op];
	printf("\t%s.%d\t\tv%d,v%d\n", opname, expr->ctype->bit_size, new, target);
	return new;
}

/*
 * FIXME! Not all accesses are memory loads. We should
 * check what kind of symbol is behind the dereference.
 */
static int show_address_gen(SCTX_ struct expression *expr)
{
	return show_expression(sctx_ expr->unop);
}

static int show_load_gen(SCTX_ int bits, struct expression *expr, int addr)
{
	int new = new_pseudo(sctx);

	printf("\tld.%d\t\tv%d,[v%d]\n", bits, new, addr);
	return new;
}

static void show_store_gen(SCTX_ int bits, int value, struct expression *expr, int addr)
{
	/* FIXME!!! Bitfield store! */
	printf("\tst.%d\t\tv%d,[v%d]\n", bits, value, addr);
}

static int show_assignment(SCTX_ struct expression *expr)
{
	struct expression *target = expr->left;
	int val, addr, bits;

	if (!expr->ctype)
		return 0;

	bits = expr->ctype->bit_size;
	val = show_expression(sctx_ expr->right);
	addr = show_address_gen(sctx_ target);
	show_store_gen(sctx_ bits, val, target, addr);
	return val;
}

static int show_return_stmt(SCTX_ struct statement *stmt)
{
	struct expression *expr = stmt->ret_value;
	struct symbol *target = stmt->ret_target;

	if (expr && expr->ctype) {
		int val = show_expression(sctx_ expr);
		int bits = expr->ctype->bit_size;
		int addr = show_symbol_expr(sctx_ target);
		show_store_gen(sctx_ bits, val, NULL, addr);
	}
	printf("\tret\t\t(%p)\n", target);
	return 0;
}

static int show_initialization(SCTX_ struct symbol *sym, struct expression *expr)
{
	int val, addr, bits;

	if (!expr->ctype)
		return 0;

	bits = expr->ctype->bit_size;
	val = show_expression(sctx_ expr);
	addr = show_symbol_expr(sctx_ sym);
	// FIXME! The "target" expression is for bitfield store information.
	// Leave it NULL, which works fine.
	show_store_gen(sctx_ bits, val, NULL, addr);
	return 0;
}

static int show_access(SCTX_ struct expression *expr)
{
	int addr = show_address_gen(sctx_ expr);
	return show_load_gen(sctx_ expr->ctype->bit_size, expr, addr);
}

static int show_inc_dec(SCTX_ struct expression *expr, int postop)
{
	int addr = show_address_gen(sctx_ expr->unop);
	int retval, new;
	const char *opname = expr->op == SPECIAL_INCREMENT ? "add" : "sub";
	int bits = expr->ctype->bit_size;

	retval = show_load_gen(sctx_ bits, expr->unop, addr);
	new = retval;
	if (postop)
		new = new_pseudo(sctx );
	printf("\t%s.%d\t\tv%d,v%d,$1\n", opname, bits, new, retval);
	show_store_gen(sctx_ bits, new, expr->unop, addr);
	return retval;
}	

static int show_preop(SCTX_ struct expression *expr)
{
	/*
	 * '*' is an lvalue access, and is fundamentally different
	 * from an arithmetic operation. Maybe it should have an
	 * expression type of its own..
	 */
	if (expr->op == '*')
		return show_access(sctx_ expr);
	if (expr->op == SPECIAL_INCREMENT || expr->op == SPECIAL_DECREMENT)
		return show_inc_dec(sctx_ expr, 0);
	return show_regular_preop(sctx_ expr);
}

static int show_postop(SCTX_ struct expression *expr)
{
	return show_inc_dec(sctx_ expr, 1);
}	

static int show_symbol_expr(SCTX_ struct symbol *sym)
{
	int new = new_pseudo(sctx );

	if (sym->initializer && sym->initializer->type == EXPR_STRING)
		return show_string_expr(sctx_ sym->initializer);

	if (sym->ctype.modifiers & (MOD_TOPLEVEL | MOD_EXTERN | MOD_STATIC)) {
		printf("\tmovi.%d\t\tv%d,$%s\n", sctxp bits_in_pointer, new, show_ident(sctx_ sym->ident));
		return new;
	}
	if (sym->ctype.modifiers & MOD_ADDRESSABLE) {
		printf("\taddi.%d\t\tv%d,vFP,$%lld\n", sctxp bits_in_pointer, new, sym->value);
		return new;
	}
	printf("\taddi.%d\t\tv%d,vFP,$offsetof(%s:%p)\n", sctxp bits_in_pointer, new, show_ident(sctx_ sym->ident), sym);
	return new;
}

static int show_symbol_init(SCTX_ struct symbol *sym)
{
	struct expression *expr = sym->initializer;

	if (expr) {
		int val, addr, bits;

		bits = expr->ctype->bit_size;
		val = show_expression(sctx_ expr);
		addr = show_symbol_expr(sctx_ sym);
		show_store_gen(sctx_ bits, val, NULL, addr);
	}
	return 0;
}

static int type_is_signed(SCTX_ struct symbol *sym)
{
	if (sym->type == SYM_NODE)
		sym = sym->ctype.base_type;
	if (sym->type == SYM_PTR)
		return 0;
	return !(sym->ctype.modifiers & MOD_UNSIGNED);
}

static int show_cast_expr(SCTX_ struct expression *expr)
{
	struct symbol *old_type, *new_type;
	int op = show_expression(sctx_ expr->cast_expression);
	int oldbits, newbits;
	int new, is_signed;

	old_type = expr->cast_expression->ctype;
	new_type = expr->cast_type;
	
	oldbits = old_type->bit_size;
	newbits = new_type->bit_size;
	if (oldbits >= newbits)
		return op;
	new = new_pseudo(sctx );
	is_signed = type_is_signed(sctx_ old_type);
	if (is_signed) {
		printf("\tsext%d.%d\tv%d,v%d\n", oldbits, newbits, new, op);
	} else {
		printf("\tandl.%d\t\tv%d,v%d,$%lu\n", newbits, new, op, (1UL << oldbits)-1);
	}
	return new;
}

static int show_value(SCTX_ struct expression *expr)
{
	int new = new_pseudo(sctx );
	unsigned long long value = expr->value;

	printf("\tmovi.%d\t\tv%d,$%llu\n", expr->ctype->bit_size, new, value);
	return new;
}

static int show_fvalue(SCTX_ struct expression *expr)
{
	int new = new_pseudo(sctx );
	long double value = expr->fvalue;

	printf("\tmovf.%d\t\tv%d,$%Lf\n", expr->ctype->bit_size, new, value);
	return new;
}

static int show_string_expr(SCTX_ struct expression *expr)
{
	int new = new_pseudo(sctx);

	printf("\tmovi.%d\t\tv%d,&%s\n", sctxp bits_in_pointer, new, show_string(sctx_ expr->string));
	return new;
}

static int show_label_expr(SCTX_ struct expression *expr)
{
	int new = new_pseudo(sctx);
	printf("\tmovi.%d\t\tv%d,.L%p\n",sctxp bits_in_pointer, new, expr->label_symbol);
	return new;
}

static int show_conditional_expr(SCTX_ struct expression *expr)
{
	int cond = show_expression(sctx_ expr->conditional);
	int true_sim = show_expression(sctx_ expr->cond_true);
	int false_sim = show_expression(sctx_ expr->cond_false);
	int new = new_pseudo(sctx);

	printf("[v%d]\tcmov.%d\t\tv%d,v%d,v%d\n", cond, expr->ctype->bit_size, new, true_sim, false_sim);
	return new;
}

static int show_statement_expr(SCTX_ struct expression *expr)
{
	return show_statement(sctx_ expr->statement);
}

static int show_position_expr(SCTX_ struct expression *expr, struct symbol *base)
{
	int new = show_expression(sctx_ expr->init_expr);
	struct symbol *ctype = expr->init_expr->ctype;
	int bit_offset;

	bit_offset = ctype ? ctype->bit_offset : -1;

	printf("\tinsert v%d at [%d:%d] of %s\n", new,
		expr->init_offset, bit_offset,
		show_ident(sctx_ base->ident));
	return 0;
}

static int show_initializer_expr(SCTX_ struct expression *expr, struct symbol *ctype)
{
	struct expression *entry;

	FOR_EACH_PTR(expr->expr_list, entry) {

again:
		// Nested initializers have their positions already
		// recursively calculated - just output them too
		if (entry->type == EXPR_INITIALIZER) {
			show_initializer_expr(sctx_ entry, ctype);
			continue;
		}

		// Initializer indexes and identifiers should
		// have been evaluated to EXPR_POS
		if (entry->type == EXPR_IDENTIFIER) {
			printf(" AT '%s':\n", show_ident(sctx_ entry->expr_ident));
			entry = entry->ident_expression;
			goto again;
		}
			
		if (entry->type == EXPR_INDEX) {
			printf(" AT '%d..%d:\n", entry->idx_from, entry->idx_to);
			entry = entry->idx_expression;
			goto again;
		}
		if (entry->type == EXPR_POS) {
			show_position_expr(sctx_ entry, ctype);
			continue;
		}
		show_initialization(sctx_ ctype, entry);
	} END_FOR_EACH_PTR(entry);
	return 0;
}

int show_symbol_expr_init(SCTX_ struct symbol *sym)
{
	struct expression *expr = sym->initializer;

	if (expr)
		show_expression(sctx_ expr);
	return show_symbol_expr(sctx_ sym);
}

/*
 * Print out an expression. Return the pseudo that contains the
 * variable.
 */
int show_expression(SCTX_ struct expression *expr)
{
	if (!expr)
		return 0;

	if (!expr->ctype) {
		struct position *pos = &expr->pos->pos;
		printf("\tno type at %s:%d:%d\n",
			stream_name(sctx_ pos->stream),
			pos->line, pos->pos);
		return 0;
	}
		
	switch (expr->type) {
	case EXPR_CALL:
		return show_call_expression(sctx_ expr);
		
	case EXPR_ASSIGNMENT:
		return show_assignment(sctx_ expr);

	case EXPR_COMMA:
		return show_comma(sctx_ expr);
	case EXPR_BINOP:
	case EXPR_COMPARE:
	case EXPR_LOGICAL:
		return show_binop(sctx_ expr);
	case EXPR_PREOP:
		return show_preop(sctx_ expr);
	case EXPR_POSTOP:
		return show_postop(sctx_ expr);
	case EXPR_SYMBOL:
		return show_symbol_expr(sctx_ expr->symbol);
	case EXPR_DEREF:
	case EXPR_SIZEOF:
	case EXPR_PTRSIZEOF:
	case EXPR_ALIGNOF:
	case EXPR_OFFSETOF:
		warning(sctx_ expr->pos->pos, "invalid expression after evaluation");
		return 0;
	case EXPR_CAST:
	case EXPR_FORCE_CAST:
	case EXPR_IMPLIED_CAST:
		return show_cast_expr(sctx_ expr);
	case EXPR_VALUE:
		return show_value(sctx_ expr);
	case EXPR_FVALUE:
		return show_fvalue(sctx_ expr);
	case EXPR_STRING:
		return show_string_expr(sctx_ expr);
	case EXPR_INITIALIZER:
		return show_initializer_expr(sctx_ expr, expr->ctype);
	case EXPR_SELECT:
	case EXPR_CONDITIONAL:
		return show_conditional_expr(sctx_ expr);
	case EXPR_STATEMENT:
		return show_statement_expr(sctx_ expr);
	case EXPR_LABEL:
		return show_label_expr(sctx_ expr);
	case EXPR_SLICE:
		return show_slice(sctx_ expr);

	// None of these should exist as direct expressions: they are only
	// valid as sub-expressions of initializers.
	case EXPR_POS:
		warning(sctx_ expr->pos->pos, "unable to show plain initializer position expression");
		return 0;
	case EXPR_IDENTIFIER:
		warning(sctx_ expr->pos->pos, "unable to show identifier expression");
		return 0;
	case EXPR_INDEX:
		warning(sctx_ expr->pos->pos, "unable to show index expression");
		return 0;
	case EXPR_TYPE:
		warning(sctx_ expr->pos->pos, "unable to show type expression");
		return 0;
	}
	return 0;
}
