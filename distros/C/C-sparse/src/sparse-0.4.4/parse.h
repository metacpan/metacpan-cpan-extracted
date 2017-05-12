#ifndef PARSE_H
#define PARSE_H
/*
 * Basic parsing data structures. Statements and symbols.
 *
 * Copyright (C) 2003 Transmeta Corp.
 *               2003 Linus Torvalds
 *
 *  Licensed under the Open Software License version 1.1
 */

#include "symbol.h"

enum statement_type {
	STMT_NONE,
	STMT_DECLARATION,
	STMT_EXPRESSION,
	STMT_COMPOUND,
	STMT_IF,
	STMT_RETURN,
	STMT_CASE,
	STMT_SWITCH,
	STMT_ITERATOR,
	STMT_LABEL,
	STMT_GOTO,
	STMT_ASM,
	STMT_CONTEXT,
	STMT_RANGE,
};

struct statement {
	enum statement_type type;
	struct token *tok;
	struct token *pos;
	union {
		struct /* declaration */ {
			struct symbol_list *declaration;
		};
		struct {
			struct expression *expression;
			struct expression *context;
		};
		struct /* return_statement */ {
			struct expression *ret_value;
			struct symbol *ret_target;
		};
		struct /* if_statement */ {
			struct expression *if_conditional;
			struct statement *if_true;
			struct statement *if_false;
		};
		struct /* compound_struct */ {
			struct statement_list *stmts;
			struct symbol *ret;
			struct symbol *inline_fn;
			struct statement *args;
		};
		struct /* labeled_struct */ {
			struct symbol *label_identifier;
			struct statement *label_statement;
		};
		struct /* case_struct */ {
			struct expression *case_expression;
			struct expression *case_to;
			struct statement *case_statement;
			struct symbol *case_label;
		};
		struct /* switch_struct */ {
			struct expression *switch_expression;
			struct statement *switch_statement;
			struct symbol *switch_break, *switch_case;
		};
		struct /* iterator_struct */ {
			struct symbol *iterator_break;
			struct symbol *iterator_continue;
			struct symbol_list *iterator_syms;
			struct statement  *iterator_pre_statement;
			struct expression *iterator_pre_condition;

			struct statement  *iterator_statement;

			struct statement  *iterator_post_statement;
			struct expression *iterator_post_condition;
		};
		struct /* goto_struct */ {
			struct symbol *goto_label;

			/* computed gotos have these: */
			struct expression *goto_expression;
			struct symbol_list *target_list;
		};
		struct /* goto_bb */ {
			struct expression *bb_conditional;
			struct symbol *bb_target;
		};
		struct /* multijmp */ {
			struct expression *multi_from;
			struct expression *multi_to;
			struct symbol *multi_target;
		};
		struct /* asm */ {
			struct expression *asm_string;
			struct expression_list *asm_outputs;
			struct expression_list *asm_inputs;
			struct expression_list *asm_clobbers;
			struct symbol_list *asm_labels;
		};
		struct /* range */ {
			struct expression *range_expression;
			struct expression *range_low;
			struct expression *range_high;
		};
	};
};

#ifndef DO_CTX
extern struct symbol_list *function_computed_target_list;
extern struct statement_list *function_computed_goto_list;
#endif

extern struct token *parse_expression(SCTX_ struct token *, struct expression **);
extern struct symbol *label_symbol(SCTX_ struct token *token);

extern int show_statement(SCTX_ struct statement *);
extern void show_statement_list(SCTX_ struct statement_list *, const char *);
extern int show_expression(SCTX_ struct expression *);

extern struct token *external_declaration(SCTX_ struct token *token, struct symbol_list **list);

extern struct symbol *ctype_integer(SCTX_ int size, int want_unsigned);

extern void copy_statement(SCTX_ struct statement *src, struct statement *dst);
extern int inline_function(SCTX_ struct expression *expr, struct symbol *sym);
extern void uninline(SCTX_ struct symbol *sym);
extern void init_parser(SCTX_ int);

extern int builtin_type(SCTX_ struct symbol *sym);

#endif /* PARSE_H */
