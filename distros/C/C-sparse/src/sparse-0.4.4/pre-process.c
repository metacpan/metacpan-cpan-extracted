/*
 * Do C preprocessing, based on a token list gathered by
 * the tokenizer.
 *
 * This may not be the smartest preprocessor on the planet.
 *
 * Copyright (C) 2003 Transmeta Corp.
 *               2003-2004 Linus Torvalds
 *
 *  Licensed under the Open Software License version 1.1
 */

/*
  stream [ t0 t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 ]
              |
              expand
              
              
         [ t0 t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 ]
	 
	 
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stddef.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <fcntl.h>
#include <limits.h>
#include <time.h>

#include "lib.h"
#include "allocate.h"
#include "parse.h"
#include "token.h"
#include "symbol.h"
#include "expression.h"
#include "scope.h"

#define PUSHTOK(p,v) *p = v; p = &((*p)->next);
#define PUSHTOKCPY(p,v) *p = dup_one(v); p = &((*p)->next);

#ifndef DO_CTX

static int false_nesting = 0;
static struct pushdown_stack_op *cur_stack_op = 0;

#define INCLUDEPATHS 300
const char *includepath[INCLUDEPATHS+1] = { /* insync with ctx.c */
	"",
	"/usr/include",
	"/usr/local/include",
	NULL
};

static const char **quote_includepath = includepath;
static const char **angle_includepath = includepath + 1;
static const char **isys_includepath   = includepath + 1;
static const char **sys_includepath   = includepath + 1;
static const char **dirafter_includepath = includepath + 3;
#endif

#define dirty_stream(stream)				\
	do {						\
		if (!stream->dirty) {			\
			stream->dirty = 1;		\
			if (!stream->ifndef)		\
				stream->protect = NULL;	\
		}					\
	} while(0)

#define end_group(stream)					\
	do {							\
		if (stream->ifndef == stream->top_if) {		\
			stream->ifndef = NULL;			\
			if (!stream->dirty)			\
				stream->protect = NULL;		\
			else if (stream->protect)		\
				stream->dirty = 0;		\
		}						\
	} while(0)

#define nesting_error(stream)		\
	do {				\
		stream->dirty = 1;	\
		stream->ifndef = NULL;	\
		stream->protect = NULL;	\
	} while(0)

struct expansion *expansion_new(SCTX_ int typ)
{
	struct expansion *e = __alloc_expansion(sctx_ 0);
	memset(e, 0, sizeof(struct expansion));
#ifdef DO_CTX
	e->ctx = sctx;
#endif
	e->typ = typ;
	return e;
}

static struct cons *expansion_consume(SCTX_ struct expansion *e, struct cons *c) {
	struct cons *l, *p;
	l = c;
	while (l) {
		l->e = e;
		if ((p = l->t->c)) {
			p->down = l;
			l->up = c;
			l->t->c = l;
		}
		l = l->next;
	}
	return c;
}

static struct cons *cons_of(SCTX_ struct cons *c, struct token *t) {
	while (c) {
		if ((c->t == t))
			return c;
		c = c->next;
	}
	return 0;
}

/* get the cons that point to <t> */
struct cons *expansion_get_cons_of(SCTX_ struct expansion *e, struct token *t) {
	struct cons *l = 0;
	if ((l = cons_of(sctx_ e->up, t)))
		return l;
	if ((l = cons_of(sctx_ e->down, t)))
		return l;
	return 0;
}

static struct cons *expansion_cons_consume(SCTX_ struct expansion *e, struct token *from, struct token *to) {
	return expansion_consume(sctx_ e, cons_list(sctx_ from, to));
}

static struct cons *expansion_produce(SCTX_ struct expansion *e, struct cons *c) {
	struct cons *l;
	l = c;
	while (l) {
		l->e = e;
		l->t->c = l;
		l = l->next;
	}
	return c;
}

static struct cons *expansion_cons_produce(SCTX_ struct expansion *e, struct token *from, struct token *to) {
	return expansion_produce(sctx_ e, cons_list(sctx_ from, to));
}

static struct token *alloc_token(SCTX_ struct position *pos)
{
	struct token *token = __alloc_token(sctx_ 0);
#ifdef DO_CTX
	token->ctx = sctx;
#endif
	token->space = 0;
	token->pos.stream = pos->stream;
	token->pos.line = pos->line;
	token->pos.pos = pos->pos;
	token->pos.whitespace = 1;
	return token;
}

/* Expand symbol 'sym' at '*list' */
static int expand(SCTX_ struct token **, struct symbol *, struct token *);

static void replace_with_string(SCTX_ struct token *token, const char *str)
{
	int size = strlen(str) + 1;
	struct string *s = __alloc_string(sctx_ size);

	s->length = size;
	memcpy(s->data, str, size);
	token_type(token) = TOKEN_STRING;
	token->string = s;
}

static void replace_with_integer(SCTX_ struct token *token, unsigned int val)
{
	char *buf = __alloc_bytes(sctx_ 11);
	sprintf(buf, "%u", val);
	token_type(token) = TOKEN_NUMBER;
	token->number = buf;
}

static struct symbol *lookup_macro(SCTX_ struct ident *ident)
{
	struct symbol *sym = lookup_symbol(sctx_ ident, NS_MACRO | NS_UNDEF);
	if (sym && sym->namespace != NS_MACRO)
		sym = NULL;
	return sym;
}

static int token_defined(SCTX_ struct token *token)
{
	if (token_type(token) == TOKEN_IDENT) {
		struct symbol *sym = lookup_macro(sctx_ token->ident);
		if (sym) {
			sym->used_in = sctxp file_scope;
			return 1;
		}
		return 0;
	}

	sparse_error(sctx_ token->pos, "expected preprocessor identifier");
	return 0;
}

static void replace_with_defined(SCTX_ struct token *token)
{
	static const char *string[] = { "0", "1" };
	int defined = token_defined(sctx_ token);

	token_type(token) = TOKEN_NUMBER;
	token->number = string[defined];
}

static int expand_one_symbol(SCTX_ struct token **list)
{
	struct token *token = *list;
	struct symbol *sym;
	static char buffer[12]; /* __DATE__: 3 + ' ' + 2 + ' ' + 4 + '\0' */
	static time_t t = 0;

	if (token->pos.noexpand)
		return 1;

	sym = lookup_macro(sctx_ token->ident);
	if (sym) {
		sym->used_in = sctxp file_scope;
		return expand(sctx_ list, sym, token);
	}
	if (token->ident == (struct ident *)&sctxp __LINE___ident) {
		replace_with_integer(sctx_ token, token->pos.line);
	} else if (token->ident == (struct ident *)&sctxp __FILE___ident) {
		replace_with_string(sctx_ token, stream_name(sctx_ token->pos.stream));
	} else if (token->ident == (struct ident *)&sctxp __DATE___ident) {
		if (!t)
			time(&t);
		strftime(buffer, 12, "%b %e %Y", localtime(&t));
		replace_with_string(sctx_ token, buffer);
	} else if (token->ident == (struct ident *)&sctxp __TIME___ident) {
		if (!t)
			time(&t);
		strftime(buffer, 9, "%T", localtime(&t));
		replace_with_string(sctx_ token, buffer);
	}
	return 1;
}

#ifndef DO_CTX
struct token_stack *tok_stk = 0;
#endif

static inline int expansion_depth(SCTX_ struct expansion *e)
{
	int max = -1, c; struct token *tok;
	switch(e->typ) {
	case EXPANSION_MACRO:
		tok = e->s;
		while (!eof_token(tok)) {
			if (tok->pos.type != TOKEN_CONS)
				error_die(sctx_ tok->pos, "Expecting TOKEN_CONS\n");
			if (tok->e) {
				c = expansion_depth(sctx_ tok->e);
				max = max > c ? max : c;
			}
			tok = tok->next;
		}
		break;
	}
	return max;
}

static inline struct token_stack *token_push_rec(SCTX)
{
	struct token_stack *t = malloc(sizeof(struct token_stack));
	memset(t, 0, sizeof(struct token_stack));
	t->p = &t->h;
	t->n = sctxp tok_stk;
	sctxp tok_stk = t;
	return t;
}

static inline struct cons *token_pop_rec(SCTX)
{
	struct token_stack *t = sctxp tok_stk;
	struct cons *h = t->h;
	sctxp tok_stk = t->n;
	free(t);
	return h;
}

static inline void token_push_torec(SCTX_ struct token_stack *t, struct token *tok) {
	struct cons *n;
	if (t->p) {
		n = cons_list(sctx_ tok, tok->next);
		*t->p = n;
		t->p = &n->next;
	}
}

static inline void token_unshift_torec(SCTX_ struct token_stack *t, struct token *tok) {
	struct cons *n;
	if (t->p) {
		n = cons_list(sctx_ tok, tok->next);
		if (t->p == &t->h) {
			t->h = n;
			n->next =  0;
			t->p = &n->next;
		} else {
			n->next = t->h;
			t->h = n;
		}
	}
}

static inline struct token *token_push(SCTX_ struct token *tok)
{
       	struct token_stack *t = sctxp tok_stk; 
	while (t) {
		token_push_torec(sctx_ t, tok);
		t = t->n;
	}
	return tok;
}

static inline struct token *scan_next(SCTX_ struct token **where)
{
	struct token *token = *where;
	if (token_type(token) != TOKEN_UNTAINT)
		return token_push(sctx_ token),token;
	do {
		token->ident->tainted = 0;
		token = token->next;
	} while (token_type(token) == TOKEN_UNTAINT);
	*where = token;
	return token_push(sctx_ token), token;
}

static void expand_list(SCTX_ struct token **list )
{
	struct token *next;
	while (!eof_token(next = scan_next(sctx_ list))) {
		if (token_type(next) != TOKEN_IDENT || expand_one_symbol(sctx_ list))
			list = &next->next;
	}
}

static void preprocessor_line(SCTX_ struct stream *stream, struct token **line);

static struct token *collect_arg(SCTX_ struct token *prev, int vararg, struct position *pos)
{
	struct stream *stream = sctxp input_streams + prev->pos.stream;
	struct token **p = &prev->next;
	struct token *next;
	int nesting = 0;

	while (!eof_token(next = scan_next(sctx_ p))) {
		if (next->pos.newline && match_op(next, '#')) {
			if (!next->pos.noexpand) {
				sparse_error(sctx_ next->pos,
					     "directive in argument list");
				preprocessor_line(sctx_ stream, p);
				__free_token(sctx_ next);	/* Free the '#' token */
				continue;
			}
		}
		switch (token_type(next)) {
		case TOKEN_STREAMEND:
		case TOKEN_STREAMBEGIN:
			*p = &sctxp eof_token_entry;
			return next;
		}
		if (sctxp false_nesting) {
			*p = next->next;
			__free_token(sctx_ next);
			continue;
		}
		if (match_op(next, '(')) {
			nesting++;
		} else if (match_op(next, ')')) {
			if (!nesting--)
				break;
		} else if (match_op(next, ',') && !nesting && !vararg) {
			break;
		}
		next->pos.stream = pos->stream;
		next->pos.line = pos->line;
		next->pos.pos = pos->pos;
		p = &next->next;
	}
	*p = &sctxp eof_token_entry;
	return next;
}

/*
 * We store arglist as <counter> [arg1] <number of uses for arg1> ... eof
 */

struct arg {
	struct token *arg;
	struct token *expanded;
	struct token *str, *from, *to;
	int n_normal;
	int n_quoted;
	int n_str;
};

static int collect_arguments(SCTX_ struct token *start, struct token *arglist, struct arg *args, struct token *what)
{
	int wanted = arglist->count.normal;
	struct token *next = NULL;
	int count = 0;

	arglist = arglist->next;	/* skip counter */

	if (!wanted) {
		next = collect_arg(sctx_ start, 0, &what->pos);
		if (eof_token(next))
			goto Eclosing;
		if (!eof_token(start->next) || !match_op(next, ')')) {
			count++;
			goto Emany;
		}
	} else {
		for (count = 0; count < wanted; count++) {
			struct argcount *p = &arglist->next->count;
			next = collect_arg(sctx_ start, p->vararg, &what->pos);
			arglist = arglist->next->next;
			if (eof_token(next))
				goto Eclosing;
			args[count].arg = start->next;
			args[count].n_normal = p->normal;
			args[count].n_quoted = p->quoted;
			args[count].n_str = p->str;
			if (match_op(next, ')')) {
				count++;
				break;
			}
			start = next;
		}
		if (count == wanted && !match_op(next, ')'))
			goto Emany;
		if (count == wanted - 1) {
			struct argcount *p = &arglist->next->count;
			if (!p->vararg)
				goto Efew;
			args[count].arg = NULL;
			args[count].n_normal = p->normal;
			args[count].n_quoted = p->quoted;
			args[count].n_str = p->str;
		}
		if (count < wanted - 1)
			goto Efew;
	}
	what->next = next->next;
	return 1;

Efew:
	sparse_error(sctx_ what->pos, "macro \"%s\" requires %d arguments, but only %d given",
		show_token(sctx_ what), wanted, count);
	goto out;
Emany:
	while (match_op(next, ',')) {
		next = collect_arg(sctx_ next, 0, &what->pos);
		count++;
	}
	if (eof_token(next))
		goto Eclosing;
	sparse_error(sctx_ what->pos, "macro \"%s\" passed %d arguments, but takes just %d",
		show_token(sctx_ what), count, wanted);
	goto out;
Eclosing:
	sparse_error(sctx_ what->pos, "unterminated argument list invoking macro \"%s\"",
		show_token(sctx_ what));
out:
	what->next = next->next;
	return 0;
}

static struct token *dup_one(SCTX_ struct token *tok)
{
	struct token *newtok = __alloc_token(sctx_ 0);
	*newtok = *tok;
	newtok->copy = tok;
#ifdef DO_CTX
	newtok->ctx = sctx;
#endif
	return newtok;
}

static struct token *dup_list(SCTX_ struct token *list, struct token *end)
{
	struct token *res = NULL;
	struct token **p = &res;

	while ((list != end) && !eof_token(list)) {
		struct token *newtok = __alloc_token(sctx_ 0);
		*newtok = *list;
		newtok->copy = list;
#ifdef DO_CTX
		newtok->ctx = sctx;
#endif
		*p = newtok;
		p = &newtok->next;
		list = list->next;
	}
	*p = &sctxp eof_token_entry;
	return res;
}

struct cons *cons_list(SCTX_ struct token *list, struct token *end)
{	
	struct cons *c = 0, **p;
	p = &c;
	while ((list != end) && !eof_token(list)) {
		struct cons *n = __alloc_cons(sctx_ 0);
		memset(n,0,sizeof(*n));
		n->t = list;
		*p = n;
		p = &n->next;
		list = list->next;
	}
	return c;
}

static struct token *dup_list_e(SCTX_ struct token *list, struct token *end, struct expansion *e)
{
	return list_e(sctx_ dup_list(sctx_ list, end), 0, e);
}

static const char *show_token_sequence(SCTX_ struct token *token, int quote)
{
	static char buffer[MAX_STRING];
	char *ptr = buffer;
	int whitespace = 0;

	if (!token && !quote)
		return "<none>";
	while (!eof_token(token)) {
		const char *val = quote ? quote_token(sctx_ token) : show_token(sctx_ token);
		int len = strlen(val);

		if (ptr + whitespace + len >= buffer + sizeof(buffer)) {
			sparse_error(sctx_ token->pos, "too long token expansion");
			break;
		}

		if (whitespace)
			*ptr++ = ' ';
		memcpy(ptr, val, len);
		ptr += len;
		token = token->next;
		whitespace = token->pos.whitespace;
	}
	*ptr = 0;
	return buffer;
}

static struct token *stringify(SCTX_ struct token *arg)
{
	const char *s = show_token_sequence(sctx_ arg, 1);
	int size = strlen(s)+1;
	struct token *token = __alloc_token(sctx_ 0);
	struct string *string = __alloc_string(sctx_ size);

	memcpy(string->data, s, size);
	string->length = size;
	token->space = 0;
	token->pos = arg->pos;
	token_type(token) = TOKEN_STRING;
	token->string = string;
	token->next = &sctxp eof_token_entry;
#ifdef DO_CTX
	token->ctx = sctx;
#endif

	return token;
}

int mark_expand_arguments(SCTX_ struct token *from, struct token *to, struct expansion *e) {
	return 0;
}

static void expand_arguments_pp(SCTX_ int count, struct arg *args, struct expansion *m)
{
	int i; struct expansion *e;
	for (i = 0; i < count; i++) {
		struct token *arg = args[i].arg;
		if (!arg)
			arg = &sctxp eof_token_entry;
		if (args[i].n_str)
			args[i].str = stringify(sctx_ arg);
		if (args[i].n_normal) {
			if (!args[i].n_quoted) {
				args[i].expanded = arg;
				args[i].arg = NULL;
			} else if (eof_token(arg)) {
				args[i].expanded = arg;
			} else {
				args[i].expanded = dup_list(sctx_ arg, 0);
			}
			
			e = expansion_new(sctx_ EXPANSION_MACROARG);
			e->s = arg;
			e->mac = m;
			expand_list(sctx_ &args[i].expanded);
			e->d = args[i].expanded;
		}
	}
}

/*
 * Possibly valid combinations:
 *  - ident + ident -> ident
 *  - ident + number -> ident unless number contains '.', '+' or '-'.
 *  - 'L' + char constant -> wide char constant
 *  - 'L' + string literal -> wide string literal
 *  - number + number -> number
 *  - number + ident -> number
 *  - number + '.' -> number
 *  - number + '+' or '-' -> number, if number used to end on [eEpP].
 *  - '.' + number -> number, if number used to start with a digit.
 *  - special + special -> either special or an error.
 */
static enum token_type combine(SCTX_ struct token *left, struct token *right, char *p)
{
	int len;
	enum token_type t1 = token_type(left), t2 = token_type(right);

	if (t1 != TOKEN_IDENT && t1 != TOKEN_NUMBER && t1 != TOKEN_SPECIAL)
		return TOKEN_ERROR;

	if (t1 == TOKEN_IDENT && left->ident == (struct ident *)&sctxp L_ident) {
		if (t2 >= TOKEN_CHAR && t2 < TOKEN_WIDE_CHAR)
			return t2 + TOKEN_WIDE_CHAR - TOKEN_CHAR;
		if (t2 == TOKEN_STRING)
			return TOKEN_WIDE_STRING;
	}

	if (t2 != TOKEN_IDENT && t2 != TOKEN_NUMBER && t2 != TOKEN_SPECIAL)
		return TOKEN_ERROR;

	strcpy(p, show_token(sctx_ left));
	strcat(p, show_token(sctx_ right));
	len = strlen(p);

	if (len >= 256)
		return TOKEN_ERROR;

	if (t1 == TOKEN_IDENT) {
		if (t2 == TOKEN_SPECIAL)
			return TOKEN_ERROR;
		if (t2 == TOKEN_NUMBER && strpbrk(p, "+-."))
			return TOKEN_ERROR;
		return TOKEN_IDENT;
	}

	if (t1 == TOKEN_NUMBER) {
		if (t2 == TOKEN_SPECIAL) {
			switch (right->special) {
			case '.':
				break;
			case '+': case '-':
				if (strchr("eEpP", p[len - 2]))
					break;
			default:
				return TOKEN_ERROR;
			}
		}
		return TOKEN_NUMBER;
	}

	if (p[0] == '.' && isdigit((unsigned char)p[1]))
		return TOKEN_NUMBER;

	return TOKEN_SPECIAL;
}

static int merge(SCTX_ struct token *left, struct token *right)
{
	static char buffer[512];
	enum token_type res = combine(sctx_ left, right, buffer);
	int n; struct token *tok;
	struct expansion *e;

	e = expansion_new(sctx_ EXPANSION_CONCAT);
	e->s = dup_one(sctx_ left);
	e->s->next = tok = dup_one(sctx_ right); tok->next = NULL;
	e->d = left;

	switch (res) {
	case TOKEN_IDENT:
		left->ident = built_in_ident(sctx_ buffer);
		left->pos.noexpand = 0;
		left->e = e;
		return 1;

	case TOKEN_NUMBER: {
		char *number = __alloc_bytes(sctx_ strlen(buffer) + 1);
		memcpy(number, buffer, strlen(buffer) + 1);
		token_type(left) = TOKEN_NUMBER;	/* could be . + num */
		left->number = number;
		left->e = e;
		return 1;
	}

	case TOKEN_SPECIAL:
		if (buffer[2] && buffer[3])
			break;
		for (n = SPECIAL_BASE; n < SPECIAL_ARG_SEPARATOR; n++) {
			if (!memcmp(buffer, combinations[n-SPECIAL_BASE], 3)) {
				left->special = n;
				left->e = e;
				return 1;
			}
		}
		break;

	case TOKEN_WIDE_CHAR:
	case TOKEN_WIDE_STRING:
		token_type(left) = res;
		left->pos.noexpand = 0;
		left->string = right->string;
		left->e = e;
		return 1;

	case TOKEN_WIDE_CHAR_EMBEDDED_0 ... TOKEN_WIDE_CHAR_EMBEDDED_3:
		token_type(left) = res;
		left->pos.noexpand = 0;
		memcpy(left->embedded, right->embedded, 4);
		left->e = e;
		return 1;

	default:
		;
	}
	sparse_error(sctx_ left->pos, "'##' failed: concatenation is not a valid token");
	return 0;
}

static struct token *dup_token(SCTX_ struct token *token, struct position *streampos)
{
	struct token *alloc = alloc_token(sctx_ streampos);
	token_type(alloc) = token_type(token);
	alloc->pos.newline = token->pos.newline;
	alloc->pos.whitespace = token->pos.whitespace;
	alloc->number = token->number;
	alloc->pos.noexpand = token->pos.noexpand;
	alloc->space = token->space;
	return alloc;	
}

static struct token **copy(SCTX_ struct token **where, struct token *body, struct token *list, int *count)
{
	int need_copy = --*count; struct expansion *e;
	struct token **o = where; struct cons *l;
	need_copy = 1;
	while (!eof_token(list)) {
		struct token *token;
		if (need_copy)
			token = dup_token(sctx_ list, &list->pos);
		else
			token = list;
		if (token_type(token) == TOKEN_IDENT && token->ident->tainted)
			token->pos.noexpand = 1;
		*where = token;
		where = &token->next;
		list = list->next;
	}

	*where = &sctxp eof_token_entry;
	
	e = expansion_new(sctx_ EXPANSION_SUBST);
	
	e->up   = l = expansion_cons_consume(sctx_ e, body, body->next);
	e->down = l = expansion_cons_produce(sctx_ e, *o, 0);
	
	return where;
}

static int handle_kludge(SCTX_ struct token **p, struct arg *args)
{
	struct token *t = (*p)->next->next;
	while (1) {
		struct arg *v = &args[t->argnum];
		if (token_type(t->next) != TOKEN_CONCAT) {
			if (v->arg) {
				/* ignore the first ## */
				*p = (*p)->next;
				return 0;
			}
			/* skip the entire thing */
			*p = t;
			return 1;
		}
		if (v->arg && !eof_token(v->arg))
			return 0; /* no magic */
		t = t->next->next;
	}
}

static struct token **substitute(SCTX_ struct token **list, struct token *body, struct arg *args)
{
	struct position *base_pos = &(*list)->pos;
	int *count;
	enum {Normal, Placeholder, Concat} state = Normal;

	for (; !eof_token(body); body = body->next) {
		struct token *added, *arg;
		struct token **tail;
		struct token *t;

		switch (token_type(body)) {
		case TOKEN_GNU_KLUDGE:
			/*
			 * GNU kludge: if we had <comma>##<vararg>, behaviour
			 * depends on whether we had enough arguments to have
			 * a vararg.  If we did, ## is just ignored.  Otherwise
			 * both , and ## are ignored.  Worse, there can be
			 * an arbitrary number of ##<arg> in between; if all of
			 * those are empty, we act as if they hadn't been there,
			 * otherwise we act as if the kludge didn't exist.
			 */
			t = body;
			if (handle_kludge(sctx_ &body, args)) {
				if (state == Concat)
					state = Normal;
				else
					state = Placeholder;
				continue;
			}
			added = dup_token(sctx_ t, base_pos);
			token_type(added) = TOKEN_SPECIAL;
			tail = &added->next;
			break;

		case TOKEN_STR_ARGUMENT:
			arg = args[body->argnum].str;
			count = &args[body->argnum].n_str;
			goto copy_arg;

		case TOKEN_QUOTED_ARGUMENT:
			arg = args[body->argnum].arg;
			count = &args[body->argnum].n_quoted;
			if (!arg || eof_token(arg)) {
				if (state == Concat)
					state = Normal;
				else
					state = Placeholder;
				continue;
			}
			goto copy_arg;

		case TOKEN_MACRO_ARGUMENT:
			arg = args[body->argnum].expanded;
			count = &args[body->argnum].n_normal;
			if (eof_token(arg)) {
				state = Normal;
				continue;
			}
		copy_arg:
			/* todo: mark the argument replacemnt as expansion */

			tail = copy(sctx_ &added, body, arg, count);
			added->pos.newline = body->pos.newline;
			added->pos.whitespace = body->pos.whitespace;
			break;

		case TOKEN_CONCAT:
			if (state == Placeholder)
				state = Normal;
			else
				state = Concat;
			continue;

		case TOKEN_IDENT:
			added = dup_token(sctx_ body, base_pos);
			if (added->ident->tainted)
				added->pos.noexpand = 1;
			tail = &added->next;
			break;

		default:
			added = dup_token(sctx_ body, base_pos);
			tail = &added->next;
			break;
		}

		/*
		 * if we got to doing real concatenation, we already have
		 * added something into the list, so containing_token() is OK.
		 */
		if (state == Concat && merge(sctx_ containing_token(list), added)) {
			*list = added->next;
			if (tail != &added->next)
				list = tail;
		} else {
			*list = added;
			list = tail;
		}
		state = Normal;
	}
	*list = &sctxp eof_token_entry;
	return list;
}

int mark_expand(SCTX_ struct token *from, struct token *to, struct expansion *e) {
	return 0;
}

static int expand(SCTX_ struct token **list, struct symbol *sym, struct token *mtok)
{
	struct expansion *e;
	struct token *last;
	struct token *token = *list;
	struct ident *expanding = token->ident;
	struct token **tail; struct cons *l;
	int nargs = sym->arglist ? sym->arglist->count.normal : 0;
	struct arg *args = NULL; /*[nargs];*/
	struct token_stack *t = 0; int ret = 0;

	if (nargs)
		args = malloc(nargs * sizeof(struct arg));
	
	if (expanding->tainted) {
		token->pos.noexpand = 1;
		goto ret1;
	}

	t = token_push_rec(sctx); /* register args_colllect */

	e = expansion_new(sctx_ EXPANSION_MACRO);
	
	e->s = 0 /*sym->expansion;*/;
	e->d = 0 /*dup_list_e(sctx_ sym->expansion, 0, e)*/;
	e->tok = mtok;
	e->msym = sym;
	
	
	if (sym->arglist) {
		if (!match_op(scan_next(sctx_ &token->next), '('))
			goto ret1;
		if (!collect_arguments(sctx_ token->next, sym->arglist, args, token))
			goto ret1;
		expand_arguments_pp(sctx_ nargs, args, e);
	}
	e->up = l = token_pop_rec(sctx); t = 0;
	expansion_consume(sctx_ e, l);
	
	expanding->tainted = 1;

	/* todo: mark token->last with macro expansion, it will
	   become the source for the substitution */

	last = token->next;
	tail = substitute(sctx_ list, sym->expansion, args);
	
	/*
	 * Note that it won't be eof - at least TOKEN_UNTAINT will be there.
	 * We still can lose the newline flag if the sucker expands to nothing,
	 * but the price of dealing with that is probably too high (we'd need
	 * to collect the flags during scan_next())
	 */
	(*list)->pos.newline = token->pos.newline;
	(*list)->pos.whitespace = token->pos.whitespace;
	*tail = last;

	e->down = l = cons_list(sctx_ *list, last);
	expansion_produce(sctx_ e, l);
	
ret2:
	if (t) (token_pop_rec(sctx), t = 0);
	if (args)
		free(args);
	return ret;
ret1:
	ret = 1;
	goto ret2;
}

static const char *token_name_sequence(SCTX_ struct token *token, int endop, struct token *start)
{
	static char buffer[256];
	char *ptr = buffer;

	while (!eof_token(token) && !match_op(token, endop)) {
		int len;
		const char *val = token->string->data;
		if (token_type(token) != TOKEN_STRING)
			val = show_token(sctx_ token);
		len = strlen(val);
		memcpy(ptr, val, len);
		ptr += len;
		token = token->next;
	}
	*ptr = 0;
	if (endop && !match_op(token, endop))
		sparse_error(sctx_ start->pos, "expected '>' at end of filename");
	return buffer;
}

static int already_tokenized(SCTX_ const char *path)
{
	int stream, next;

	if (sctxp ppnoopt)
		return 0;

	for (stream = *hash_stream(sctx_ path); stream >= 0 ; stream = next) {
		struct stream *s = sctxp input_streams + stream;

		next = s->next_stream;
		if (s->once) {
			if (strcmp(path, s->name))
				continue;
			return 1;
		}
		if (s->constant != CONSTANT_FILE_YES)
			continue;
		if (strcmp(path, s->name))
			continue;
		if (s->protect && !lookup_macro(sctx_ s->protect))
			continue;
		return 1;
	}
	return 0;
}

/* Handle include of header files.
 * The relevant options are made compatible with gcc. The only options that
 * are not supported is -withprefix and friends.
 *
 * Three set of include paths are known:
 * quote_includepath:	Path to search when using #include "file.h"
 * angle_includepath:	Paths to search when using #include <file.h>
 * isys_includepath:	Paths specified with -isystem, come before the
 *			built-in system include paths. Gcc would suppress
 *			warnings from system headers. Here we separate
 *			them from the angle_ ones to keep search ordering.
 *
 * sys_includepath:	Built-in include paths.
 * dirafter_includepath Paths added with -dirafter.
 *
 * The above is implemented as one array with pointers
 *                         +--------------+
 * quote_includepath --->  |              |
 *                         +--------------+
 *                         |              |
 *                         +--------------+
 * angle_includepath --->  |              |
 *                         +--------------+
 * isys_includepath  --->  |              |
 *                         +--------------+
 * sys_includepath   --->  |              |
 *                         +--------------+
 * dirafter_includepath -> |              |
 *                         +--------------+
 *
 * -I dir insert dir just before isys_includepath and move the rest
 * -I- makes all dirs specified with -I before to quote dirs only and
 *   angle_includepath is set equal to isys_includepath.
 * -nostdinc removes all sys dirs by storing NULL in entry pointed
 *   to by * sys_includepath. Note that this will reset all dirs built-in
 *   and added before -nostdinc by -isystem and -idirafter.
 * -isystem dir adds dir where isys_includepath points adding this dir as
 *   first systemdir
 * -idirafter dir adds dir to the end of the list
 */

static void set_stream_include_path(SCTX_ struct stream *stream)
{
	const char *path = stream->path;
	if (!path) {
		const char *p = strrchr(stream->name, '/');
		path = "";
		if (p) {
			int len = p - stream->name + 1;
			char *m = malloc(len+1);
			/* This includes the final "/" */
			memcpy(m, stream->name, len);
			m[len] = 0;
			path = m;
		}
		stream->path = path;
	}
	sctxp includepath[0] = path;
}

static int try_include(SCTX_ const char *path, const char *filename, int flen, struct token **where, const char **next_path)
{
	int fd; struct expansion *e;
	int plen = strlen(path);
	static char fullname[PATH_MAX];

	memcpy(fullname, path, plen);
	if (plen && path[plen-1] != '/') {
		fullname[plen] = '/';
		plen++;
	}
	memcpy(fullname+plen, filename, flen);
	if (already_tokenized(sctx_ fullname))
		return 1;
	fd = open(fullname, O_RDONLY);
	if (fd >= 0) {
		char * streamname = __alloc_bytes(sctx_ plen + flen);
		memcpy(streamname, fullname, plen + flen);
		e = tokenize(sctx_ streamname, fd, *where, next_path);
		*where = e->s;
		close(fd);
		return 1;
	}
	return 0;
}

static int do_include_path(SCTX_ const char **pptr, struct token **list, struct token *token, const char *filename, int flen)
{
	const char *path;

	while ((path = *pptr++) != NULL) {
		if (!try_include(sctx_ path, filename, flen, list, pptr))
			continue;
		return 1;
	}
	return 0;
}

static int free_preprocessor_line(SCTX_ struct token *token)
{
	while (token_type(token) != TOKEN_EOF) {
		struct token *free = token;
		token = token->next;
		__free_token(sctx_ free);
	};
	return 1;
}

static int handle_include_path(SCTX_ struct stream *stream, struct token **list, struct token *token, int how)
{
	const char *filename;
	struct token *next;
	const char **path;
	int expect;
	int flen;

	next = token->next;
	expect = '>';
	if (!match_op(next, '<')) {
		expand_list(sctx_ &token->next);
		expect = 0;
		next = token;
		if (match_op(token->next, '<')) {
			next = token->next;
			expect = '>';
		}
	}

	token = next->next;
	filename = token_name_sequence(sctx_ token, expect, token);
	flen = strlen(filename) + 1;

	/* Absolute path? */
	if (filename[0] == '/') {
		if (try_include(sctx_ "", filename, flen, list, sctxp includepath))
			return 0;
		goto out;
	}

	switch (how) {
	case 1:
		path = stream->next_path;
		break;
	case 2:
		sctxp includepath[0] = "";
		path = sctxp includepath;
		break;
	default:
		/* Dir of input file is first dir to search for quoted includes */
		set_stream_include_path(sctx_ stream);
		path = expect ? sctxp angle_includepath : sctxp quote_includepath;
		break;
	}
	/* Check the standard include paths.. */
	if (do_include_path(sctx_ path, list, token, filename, flen))
		return 0;
out:
	error_die(sctx_ token->pos, "unable to open '%s'", filename);
	return 0;
}

static int handle_include(SCTX_ struct stream *stream, struct token **list, struct token *token)
{
	return handle_include_path(sctx_ stream, list, token, 0);
}

static int handle_include_next(SCTX_ struct stream *stream, struct token **list, struct token *token)
{
	return handle_include_path(sctx_ stream, list, token, 1);
}

static int handle_argv_include(SCTX_ struct stream *stream, struct token **list, struct token *token)
{
	return handle_include_path(sctx_ stream, list, token, 2);
}

static int token_different(SCTX_ struct token *t1, struct token *t2)
{
	int different;

	if (token_type(t1) != token_type(t2))
		return 1;

	switch (token_type(t1)) {
	case TOKEN_IDENT:
		different = t1->ident != t2->ident;
		break;
	case TOKEN_ARG_COUNT:
	case TOKEN_UNTAINT:
	case TOKEN_CONCAT:
	case TOKEN_GNU_KLUDGE:
		different = 0;
		break;
	case TOKEN_NUMBER:
		different = strcmp(t1->number, t2->number);
		break;
	case TOKEN_SPECIAL:
		different = t1->special != t2->special;
		break;
	case TOKEN_MACRO_ARGUMENT:
	case TOKEN_QUOTED_ARGUMENT:
	case TOKEN_STR_ARGUMENT:
		different = t1->argnum != t2->argnum;
		break;
	case TOKEN_CHAR_EMBEDDED_0 ... TOKEN_CHAR_EMBEDDED_3:
	case TOKEN_WIDE_CHAR_EMBEDDED_0 ... TOKEN_WIDE_CHAR_EMBEDDED_3:
		different = memcmp(t1->embedded, t2->embedded, 4);
		break;
	case TOKEN_CHAR:
	case TOKEN_WIDE_CHAR:
	case TOKEN_STRING:
	case TOKEN_WIDE_STRING: {
		struct string *s1, *s2;

		s1 = t1->string;
		s2 = t2->string;
		different = 1;
		if (s1->length != s2->length)
			break;
		different = memcmp(s1->data, s2->data, s1->length);
		break;
	}
	default:
		different = 1;
		break;
	}
	return different;
}

static int token_list_different(SCTX_ struct token *list1, struct token *list2)
{
	for (;;) {
		if (list1 == list2)
			return 0;
		if (!list1 || !list2)
			return 1;
		if (token_different(sctx_ list1, list2))
			return 1;
		list1 = list1->next;
		list2 = list2->next;
	}
}

static inline void set_arg_count(struct token *token)
{
	token_type(token) = TOKEN_ARG_COUNT;
	token->count.normal = token->count.quoted =
	token->count.str = token->count.vararg = 0;
}

static struct token *parse_arguments(SCTX_ struct token **arglist)
{
	struct token *list = *arglist = dup_one(sctx_ *arglist);
	struct token *arg = list->next = dup_one(sctx_ list->next), *next = list;
	struct argcount *count = &list->count;

	set_arg_count(list);

	if (match_op(arg, ')')) {
		next = arg->next;
		list->next = &sctxp eof_token_entry;
		return next;
	}

	while (token_type(arg) == TOKEN_IDENT) {
		if (arg->ident == (struct ident *)&sctxp __VA_ARGS___ident)
			goto Eva_args;
		if (!++count->normal)
			goto Eargs;
		next = arg->next = dup_one(sctx_ arg->next);

		if (match_op(next, ',')) {
			set_arg_count(next);
			arg = next->next = dup_one(sctx_ next->next);
			continue;
		}

		if (match_op(next, ')')) {
			set_arg_count(next);
			next = next->next;
			arg->next->next = &sctxp eof_token_entry;
			return next;
		}

		/* normal cases are finished here */

		if (match_op(next, SPECIAL_ELLIPSIS)) {
			if (match_op(next->next, ')')) {
				set_arg_count(next);
				next->count.vararg = 1;
				next = next->next;
				arg->next->next = &sctxp eof_token_entry;
				return next->next;
			}

			arg = next;
			goto Enotclosed;
		}

		if (eof_token(next)) {
			goto Enotclosed;
		} else {
			arg = next;
			goto Ebadstuff;
		}
	}

	if (match_op(arg, SPECIAL_ELLIPSIS)) {
		next = arg->next = dup_one(sctx_ arg->next);
		token_type(arg) = TOKEN_IDENT;
		arg->ident = (struct ident *)&sctxp __VA_ARGS___ident;
		if (!match_op(next, ')'))
			goto Enotclosed;
		if (!++count->normal)
			goto Eargs;
		set_arg_count(next);
		next->count.vararg = 1;
		next = next->next;
		arg->next->next = &sctxp eof_token_entry;
		return next;
	}

	if (eof_token(arg)) {
		arg = next;
		goto Enotclosed;
	}
	if (match_op(arg, ','))
		goto Emissing;
	else
		goto Ebadstuff;


Emissing:
	sparse_error(sctx_ arg->pos, "parameter name missing");
	return NULL;
Ebadstuff:
	sparse_error(sctx_ arg->pos, "\"%s\" may not appear in macro parameter list",
		show_token(sctx_ arg));
	return NULL;
Enotclosed:
	sparse_error(sctx_ arg->pos, "missing ')' in macro parameter list");
	return NULL;
Eva_args:
	sparse_error(sctx_ arg->pos, "__VA_ARGS__ can only appear in the expansion of a C99 variadic macro");
	return NULL;
Eargs:
	sparse_error(sctx_ arg->pos, "too many arguments in macro definition");
	return NULL;
}

static int try_arg(SCTX_ struct token *token, enum token_type type, struct token *arglist)
{
	struct ident *ident = token->ident;
	int nr;

	if (!arglist || token_type(token) != TOKEN_IDENT)
		return 0;

	arglist = arglist->next;

	for (nr = 0; !eof_token(arglist); nr++, arglist = arglist->next->next) {
		if (arglist->ident == ident) {
			struct argcount *count = &arglist->next->count;
			int n;

			token->argnum = nr;
			token_type(token) = type;
			switch (type) {
			case TOKEN_MACRO_ARGUMENT:
				n = ++count->normal;
				break;
			case TOKEN_QUOTED_ARGUMENT:
				n = ++count->quoted;
				break;
			default:
				n = ++count->str;
			}
			if (n)
				return count->vararg ? 2 : 1;
			/*
			 * XXX - need saner handling of that
			 * (>= 1024 instances of argument)
			 */
			token_type(token) = TOKEN_ERROR;
			return -1;
		}
	}
	return 0;
}

static struct token *handle_hash(SCTX_ struct token **p, struct token *arglist)
{
	struct token *token = *p;
	if (arglist) {
		struct token *next = token->next;
		if (!try_arg(sctx_ next, TOKEN_STR_ARGUMENT, arglist))
			goto Equote;
		next->pos.whitespace = token->pos.whitespace;
		__free_token(sctx_ token);
		token = *p = next;
	} else {
		token->pos.noexpand = 1;
	}
	return token;

Equote:
	sparse_error(sctx_ token->pos, "'#' is not followed by a macro parameter");
	return NULL;
}

/* token->next is ## */
static struct token *handle_hashhash(SCTX_ struct token *token, struct token *arglist)
{
	struct token *last = token;
	struct token *concat;
	int state = match_op(token, ',');
	
	try_arg(sctx_ token, TOKEN_QUOTED_ARGUMENT, arglist);

	while (1) {
		struct token *t;
		int is_arg;

		/* eat duplicate ## */
		concat = token->next;
		while (match_op(t = concat->next, SPECIAL_HASHHASH)) {
			token->next = t;
			__free_token(sctx_ concat);
			concat = t;
		}
		token_type(concat) = TOKEN_CONCAT;

		if (eof_token(t))
			goto Econcat;

		if (match_op(t, '#')) {
			t = handle_hash(sctx_ &concat->next, arglist);
			if (!t)
				return NULL;
		}

		is_arg = try_arg(sctx_ t, TOKEN_QUOTED_ARGUMENT, arglist);

		if (state == 1 && is_arg) {
			state = is_arg;
		} else {
			last = t;
			state = match_op(t, ',');
		}

		token = t;
		if (!match_op(token->next, SPECIAL_HASHHASH))
			break;
	}
	/* handle GNU ,##__VA_ARGS__ kludge, in all its weirdness */
	if (state == 2)
		token_type(last) = TOKEN_GNU_KLUDGE;
	return token;

Econcat:
	sparse_error(sctx_ concat->pos, "'##' cannot appear at the ends of macro expansion");
	return NULL;
}

static struct token *parse_expansion(SCTX_ struct token *expansion, struct token *arglist, struct ident *name)
{
	struct token *token = expansion;
	struct token **p;

	if (match_op(token, SPECIAL_HASHHASH))
		goto Econcat;

	for (p = &expansion; !eof_token(token); p = &token->next, token = *p) {
		if (match_op(token, '#')) {
			token = handle_hash(sctx_ p, arglist);
			if (!token)
				return NULL;
		}
		if (match_op(token->next, SPECIAL_HASHHASH)) {
			token = handle_hashhash(sctx_ token, arglist);
			if (!token)
				return NULL;
		} else {
			try_arg(sctx_ token, TOKEN_MACRO_ARGUMENT, arglist);
		}
		if (token_type(token) == TOKEN_ERROR)
			goto Earg;
	}
	token = alloc_token(sctx_ &expansion->pos);
	token_type(token) = TOKEN_UNTAINT;
	token->ident = name;
	token->space = 0;
	token->next = *p;
	*p = token;
	return expansion;

Econcat:
	sparse_error(sctx_ token->pos, "'##' cannot appear at the ends of macro expansion");
	return NULL;
Earg:
	sparse_error(sctx_ token->pos, "too many instances of argument in body");
	return NULL;
}

static int do_handle_define(SCTX_ struct stream *stream, struct token **line, struct token *token, int attr)
{
	struct token *arglist, *expansion;
	struct token *left = token->next;
	struct symbol *sym;
	struct ident *name;
	struct expansion *e;
	int ret;

	if (token_type(left) != TOKEN_IDENT) {
		sparse_error(sctx_ token->pos, "expected identifier to 'define'");
		return 1;
	}

	name = left->ident;

	arglist = NULL;
	expansion = left->next;
	if (!expansion->pos.whitespace) {
		if (match_op(expansion, '(')) {
			arglist = expansion;
			expansion = parse_arguments(sctx_ &arglist);
			if (!expansion)
				return 1;
		} else if (!eof_token(expansion)) {
			warning(sctx_ expansion->pos,
				"no whitespace before object-like macro body");
		}
	}

	expansion = parse_expansion(sctx_ expansion, arglist, name);
	if (!expansion)
		return 1;

	ret = 1;
	sym = lookup_symbol(sctx_ name, NS_MACRO /*| NS_UNDEF*/);
	if (sym) {
		int clean;

		if (attr < sym->attr)
			goto out; 

		clean = (attr == sym->attr && sym->namespace == NS_MACRO);

		if (token_list_different(sctx_ sym->expansion, expansion) ||
		    token_list_different(sctx_ sym->arglist, arglist)) {
			ret = 0;
			if ((clean && attr == SYM_ATTR_NORMAL)
					|| sym->used_in == sctxp file_scope) {
				warning(sctx_ left->pos, "preprocessor token %.*s redefined",
						name->len, name->name);
				info(sctx_ sym->pos->pos, "this was the original definition");
			}
		} else if (0 && clean)
			goto out;
	}

	if (1 || !sym || sym->scope != sctxp file_scope) {
		sym = alloc_symbol(sctx_ left, SYM_NODE);
		bind_symbol(sctx_ sym, name, NS_MACRO);
		ret = 0;
	}

	if (!ret) {
		sym->expansion = expansion;
		sym->arglist = arglist;
		__free_token(sctx_ token);	/* Free the "define" token, but not the rest of the line */
	}

	sym->namespace = NS_MACRO;
	sym->used_in = NULL;
	sym->attr = attr;
	
	e = __alloc_expansion(sctx_ 0);
	memset(e, 0, sizeof(struct expansion));
#ifdef DO_CTX
	e->ctx = sctx;
#endif
	e->typ = EXPANSION_MACRODEF;
	e->mdefsym = sym;
	if (sym->expansion)
		list_e(sctx_ sym->expansion, 0, e);

out:
	return ret;
}

static int handle_define(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	return do_handle_define(sctx_ stream, line, token, SYM_ATTR_NORMAL);
}

static int handle_weak_define(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	return do_handle_define(sctx_ stream, line, token, SYM_ATTR_WEAK);
}

static int handle_strong_define(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	return do_handle_define(sctx_ stream, line, token, SYM_ATTR_STRONG);
}

static int do_handle_undef(SCTX_ struct stream *stream, struct token **line, struct token *token, int attr)
{
	struct token *left = token->next;
	struct symbol *sym;

	if (token_type(left) != TOKEN_IDENT) {
		sparse_error(sctx_ token->pos, "expected identifier to 'undef'");
		return 1;
	}

	sym = lookup_symbol(sctx_ left->ident, NS_MACRO | NS_UNDEF);
	if (sym) {
		if (attr < sym->attr)
			return 1;
		if (attr == sym->attr && sym->namespace == NS_UNDEF)
			return 1;
	} else if (attr <= SYM_ATTR_NORMAL)
		return 1;

	if (!sym || sym->scope != sctxp file_scope) {
		sym = alloc_symbol(sctx_ left, SYM_NODE);
		bind_symbol(sctx_ sym, left->ident, NS_MACRO);
	}

	sym->namespace = NS_UNDEF;
	sym->used_in = NULL;
	sym->attr = attr;

	return 1;
}

static int handle_undef(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	return do_handle_undef(sctx_ stream, line, token, SYM_ATTR_NORMAL);
}

static int handle_strong_undef(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	return do_handle_undef(sctx_ stream, line, token, SYM_ATTR_STRONG);
}

static int preprocessor_if(SCTX_ struct stream *stream, struct token *token, int true_sim)
{
	token_type(token) = sctxp false_nesting ? TOKEN_SKIP_GROUPS : TOKEN_IF;
	free_preprocessor_line(sctx_ token->next);
	token->next = stream->top_if;
	stream->top_if = token;
	if (sctxp false_nesting || true_sim != 1)
		sctxp false_nesting++;
	return 0;
}

static int handle_ifdef(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	struct token *next = token->next;
	int arg;
	if (token_type(next) == TOKEN_IDENT) {
		arg = token_defined(sctx_ next);
	} else {
		dirty_stream(stream);
		if (!sctxp false_nesting)
			sparse_error(sctx_ token->pos, "expected preprocessor identifier");
		arg = -1;
	}
	return preprocessor_if(sctx_ stream, token, arg);
}

static int handle_ifndef(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	struct token *next = token->next;
	int arg;
	if (token_type(next) == TOKEN_IDENT) {
		if (!stream->dirty && !stream->ifndef) {
			if (!stream->protect) {
				stream->ifndef = token;
				stream->protect = next->ident;
			} else if (stream->protect == next->ident) {
				stream->ifndef = token;
				stream->dirty = 1;
			}
		}
		arg = !token_defined(sctx_ next);
	} else {
		dirty_stream(stream);
		if (!sctxp false_nesting)
			sparse_error(sctx_ token->pos, "expected preprocessor identifier");
		arg = -1;
	}

	return preprocessor_if(sctx_ stream, token, arg);
}

static const char *show_token_sequence(SCTX_ struct token *token, int quote);

/*
 * Expression handling for #if and #elif; it differs from normal expansion
 * due to special treatment of "defined".
 */
static int expression_value(SCTX_ struct token **where)
{
	struct expression *expr;
	struct token *p;
	struct token **list = where, **beginning = NULL;
	long long value;
	int state = 0;

	while (!eof_token(p = scan_next(sctx_ list))) {
		switch (state) {
		case 0:
			if (token_type(p) != TOKEN_IDENT)
				break;
			if (p->ident == (struct ident *)&sctxp defined_ident) {
			  	state = 1;
				beginning = list;
				break;
			}
			if (!expand_one_symbol(sctx_ list))
				continue;
			if (token_type(p) != TOKEN_IDENT)
				break;
			token_type(p) = TOKEN_ZERO_IDENT;
			break;
		case 1:
			if (match_op(p, '(')) {
				state = 2;
			} else {
				state = 0;
				replace_with_defined(sctx_ p);
				*beginning = p;
			}
			break;
		case 2:
			if (token_type(p) == TOKEN_IDENT)
				state = 3;
			else
				state = 0;
			replace_with_defined(sctx_ p);
			*beginning = p;
			break;
		case 3:
			state = 0;
			if (!match_op(p, ')'))
				sparse_error(sctx_ p->pos, "missing ')' after \"defined\"");
			*list = p->next;
			continue;
		}
		list = &p->next;
	}

	p = constant_expression(sctx_ *where, &expr);
	if (!eof_token(p))
		sparse_error(sctx_ p->pos, "garbage at end: %s", show_token_sequence(sctx_ p, 0));
	value = get_expression_value(sctx_ expr);
	return value != 0;
}

static int handle_if(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	int value = 0;
	if (!sctxp false_nesting)
		value = expression_value(sctx_ &token->next);

	dirty_stream(stream);
	return preprocessor_if(sctx_ stream, token, value);
}

static int handle_elif(SCTX_ struct stream * stream, struct token **line, struct token *token)
{
	struct token *top_if = stream->top_if;
	end_group(stream);

	if (!top_if) {
		nesting_error(stream);
		sparse_error(sctx_ token->pos, "unmatched #elif within stream");
		return 1;
	}

	if (token_type(top_if) == TOKEN_ELSE) {
		nesting_error(stream);
		sparse_error(sctx_ token->pos, "#elif after #else");
		if (!sctxp false_nesting)
			sctxp false_nesting = 1;
		return 1;
	}

	dirty_stream(stream);
	if (token_type(top_if) != TOKEN_IF)
		return 1;
	if (sctxp false_nesting) {
		sctxp false_nesting = 0;
		if (!expression_value(sctx_ &token->next))
			sctxp false_nesting = 1;
	} else {
		sctxp false_nesting = 1;
		token_type(top_if) = TOKEN_SKIP_GROUPS;
	}
	return 1;
}

static int handle_else(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	struct token *top_if = stream->top_if;
	end_group(stream);

	if (!top_if) {
		nesting_error(stream);
		sparse_error(sctx_ token->pos, "unmatched #else within stream");
		return 1;
	}

	if (token_type(top_if) == TOKEN_ELSE) {
		nesting_error(stream);
		sparse_error(sctx_ token->pos, "#else after #else");
	}
	if (sctxp false_nesting) {
		if (token_type(top_if) == TOKEN_IF)
			sctxp false_nesting = 0;
	} else {
		sctxp false_nesting = 1;
	}
	token_type(top_if) = TOKEN_ELSE;
	return 1;
}

static int handle_endif(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	struct token *top_if = stream->top_if;
	end_group(stream);
	if (!top_if) {
		nesting_error(stream);
		sparse_error(sctx_ token->pos, "unmatched #endif in stream");
		return 1;
	}
	if (sctxp false_nesting)
		sctxp false_nesting--;
	stream->top_if = top_if->next;
	__free_token(sctx_ top_if);
	return 1;
}

static int handle_warning(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	warning(sctx_ token->pos, "%s", show_token_sequence(sctx_ token->next, 0));
	return 1;
}

static int handle_error(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	sparse_error(sctx_ token->pos, "%s", show_token_sequence(sctx_ token->next, 0));
	return 1;
}

static int handle_nostdinc(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	/*
	 * Do we have any non-system includes?
	 * Clear them out if so..
	 */
	*(sctxp sys_includepath) = NULL;
	return 1;
}

static inline void update_inc_ptrs(SCTX_ const char ***where)
{

	if (*where <= sctxp dirafter_includepath) {
		sctxp dirafter_includepath++;
		/* If this was the entry that we prepend, don't
		 * rise the lower entries, even if they are at
		 * the same level. */
		if (where == &sctxp dirafter_includepath)
			return;
	}
	if (*where <= sctxp sys_includepath) {
		sctxp sys_includepath++;
		if (where == &sctxp sys_includepath)
			return;
	}
	if (*where <= sctxp isys_includepath) {
		sctxp isys_includepath++;
		if (where == &sctxp isys_includepath)
			return;
	}

	/* angle_includepath is actually never updated, since we
	 * don't suppport -iquote rught now. May change some day. */
	if (*where <= sctxp angle_includepath) {
		sctxp angle_includepath++;
		if (where == &sctxp angle_includepath)
			return;
	}
}

int ppre_issys(SCTX_ const char **p) {
  if (p >= sctxp isys_includepath)
    return 1;
  return 0;
}

/* Add a path before 'where' and update the pointers associated with the
 * includepath array */
static void add_path_entry(SCTX_ struct token *token, const char *path,
	const char ***where)
{
	const char **dst;
	const char *next;

	/* Need one free entry.. */
	if (sctxp includepath[INCLUDEPATHS-2])
		error_die(sctx_ token->pos, "too many include path entries");

	/* check that this is not a duplicate */
	dst = sctxp includepath;
	while (*dst) {
		if (strcmp(*dst, path) == 0)
			return;
		dst++;
	}
	next = path;
	dst = *where;

	update_inc_ptrs(sctx_ where);

	/*
	 * Move them all up starting at dst,
	 * insert the new entry..
	 */
	do {
		const char *tmp = *dst;
		*dst = next;
		next = tmp;
		dst++;
	} while (next);
}

static int handle_add_include(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	for (;;) {
		token = token->next;
		if (eof_token(token))
			return 1;
		if (token_type(token) != TOKEN_STRING) {
			warning(sctx_ token->pos, "expected path string");
			return 1;
		}
		add_path_entry(sctx_ token, token->string->data, &sctxp isys_includepath);
	}
}

static int handle_add_isystem(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	for (;;) {
		token = token->next;
		if (eof_token(token))
			return 1;
		if (token_type(token) != TOKEN_STRING) {
			sparse_error(sctx_ token->pos, "expected path string");
			return 1;
		}
		add_path_entry(sctx_ token, token->string->data, &sctxp sys_includepath);
	}
}

static int handle_add_system(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	for (;;) {
		token = token->next;
		if (eof_token(token))
			return 1;
		if (token_type(token) != TOKEN_STRING) {
			sparse_error(sctx_ token->pos, "expected path string");
			return 1;
		}
		add_path_entry(sctx_ token, token->string->data, &sctxp dirafter_includepath);
	}
}

/* Add to end on includepath list - no pointer updates */
static void add_dirafter_entry(SCTX_ struct token *token, const char *path)
{
	const char **dst = sctxp includepath;

	/* Need one free entry.. */
	if (sctxp includepath[INCLUDEPATHS-2])
		error_die(sctx_ token->pos, "too many include path entries");

	/* Add to the end */
	while (*dst)
		dst++;
	*dst = path;
	dst++;
	*dst = NULL;
}

static int handle_add_dirafter(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	for (;;) {
		token = token->next;
		if (eof_token(token))
			return 1;
		if (token_type(token) != TOKEN_STRING) {
			sparse_error(sctx_ token->pos, "expected path string");
			return 1;
		}
		add_dirafter_entry(sctx_ token, token->string->data);
	}
}

static int handle_split_include(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	/*
	 * -I-
	 *  From info gcc:
	 *  Split the include path.  Any directories specified with `-I'
	 *  options before `-I-' are searched only for headers requested with
	 *  `#include "FILE"'; they are not searched for `#include <FILE>'.
	 *  If additional directories are specified with `-I' options after
	 *  the `-I-', those directories are searched for all `#include'
	 *  directives.
	 *  In addition, `-I-' inhibits the use of the directory of the current
	 *  file directory as the first search directory for `#include "FILE"'.
	 */
	sctxp quote_includepath = sctxp includepath+1;
	sctxp angle_includepath = sctxp sys_includepath;
	return 1;
}

/*
 * We replace "#pragma xxx" with "__pragma__" in the token
 * stream. Just as an example.
 *
 * We'll just #define that away for now, but the theory here
 * is that we can use this to insert arbitrary token sequences
 * to turn the pragmas into internal front-end sequences for
 * when we actually start caring about them.
 *
 * So eventually this will turn into some kind of extended
 * __attribute__() like thing, except called __pragma__(xxx).
 */
static int handle_pragma(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	struct token *next = *line;

	if (match_ident(token->next, (struct ident *)&sctxp once_ident) && eof_token(token->next->next)) {
		stream->once = 1;
		return 1;
	}
	token->ident = (struct ident *)&sctxp pragma_ident;
	token->pos.newline = 1;
	token->pos.whitespace = 1;
	token->pos.pos = 1;
	*line = token;
	token->next = next;
	return 0;
}

/*
 * We ignore #line for now.
 */
static int handle_line(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	return 1;
}

static int handle_nondirective(SCTX_ struct stream *stream, struct token **line, struct token *token)
{
	sparse_error(sctx_ token->pos, "unrecognized preprocessor line '%s'", show_token_sequence(sctx_ token, 0));
	return 1;
}

void init_preprocessor(SCTX)
{
	int i;
	struct stream *s;
	int stream;
	static struct {
		const char *name;
		int (*handler)(SCTX_ struct stream *, struct token **, struct token *);
	} normal[] = {
		{ "define",		handle_define },
		{ "weak_define",	handle_weak_define },
		{ "strong_define",	handle_strong_define },
		{ "undef",		handle_undef },
		{ "strong_undef",	handle_strong_undef },
		{ "warning",		handle_warning },
		{ "error",		handle_error },
		{ "include",		handle_include },
		{ "include_next",	handle_include_next },
		{ "pragma",		handle_pragma },
		{ "line",		handle_line },

		// our internal preprocessor tokens
		{ "nostdinc",	   handle_nostdinc },
		{ "add_include",   handle_add_include },
		{ "add_isystem",   handle_add_isystem },
		{ "add_system",    handle_add_system },
		{ "add_dirafter",  handle_add_dirafter },
		{ "split_include", handle_split_include },
		{ "argv_include",  handle_argv_include },
	}, special[] = {
		{ "ifdef",	handle_ifdef },
		{ "ifndef",	handle_ifndef },
		{ "else",	handle_else },
		{ "endif",	handle_endif },
		{ "if",		handle_if },
		{ "elif",	handle_elif },
	};

	if (sctxp ppisinit)
		return;
	sctxp ppisinit = 1;
	
	s = init_stream(sctx_ "<preprocessor>", -1, sctxp includepath);
	stream = s->id;

	for (i = 0; i < ARRAY_SIZE(normal); i++) {
		struct symbol *sym;
		sym = create_symbol(sctx_ stream, normal[i].name, SYM_PREPROCESSOR, NS_PREPROCESSOR);
		sym->handler = normal[i].handler;
		sym->normal = 1;
	}
	for (i = 0; i < ARRAY_SIZE(special); i++) {
		struct symbol *sym;
		sym = create_symbol(sctx_ stream, special[i].name, SYM_PREPROCESSOR, NS_PREPROCESSOR);
		sym->handler = special[i].handler;
		sym->normal = 0;
	}

}

static void handle_preprocessor_line(SCTX_ struct stream *stream, struct token **line, struct token *start)
{
	int (*handler)(SCTX_ struct stream *, struct token **, struct token *);
	struct token *token = start->next;
	struct expansion *e;
	int is_normal = 1;

	if (eof_token(token))
		return;

	e = __alloc_expansion(sctx_ 0);
	memset(e, 0, sizeof(struct expansion));
#ifdef DO_CTX
	e->ctx = sctx;
#endif
	e->typ = EXPANSION_PREPRO;
	e->s = start;
	e->d = dup_list_e(sctx_ token, 0, e);

	if (token_type(token) == TOKEN_IDENT) {
		struct symbol *sym = lookup_symbol(sctx_ token->ident, NS_PREPROCESSOR);
		if (sym) {
			handler = sym->handler;
			is_normal = sym->normal;
		} else {
			handler = handle_nondirective;
		}
	} else if (token_type(token) == TOKEN_NUMBER) {
		handler = handle_line;
	} else {
		handler = handle_nondirective;
	}

	if (is_normal) {
		dirty_stream(stream);
		if (sctxp false_nesting)
			goto out;
	}
	if (!handler(sctx_ stream, line, token))	/* all set */
		return;

out:
	free_preprocessor_line(sctx_ token);
}

static void preprocessor_line(SCTX_ struct stream *stream, struct token **line)
{
	struct token *start = *line, *next;
	struct token **tp = &start->next;

	for (;;) {
		next = *tp;
		if (next->pos.newline)
			break;
		tp = &next->next;
	}
	*line = next;
	*tp = &sctxp eof_token_entry;
	handle_preprocessor_line(sctx_ stream, line, start);
}

static struct token *do_preprocess(SCTX_ struct token **list)
{
	struct token *next; struct token *l = NULL; /*, **c = &l;*/

	while (!eof_token(next = scan_next(sctx_ list))) {
		struct stream *stream = sctxp input_streams + next->pos.stream;

		if (next->pos.newline && match_op(next, '#')) {
			if (!next->pos.noexpand) {
				preprocessor_line(sctx_ stream, list);
				__free_token(sctx_ next);	/* Free the '#' token */
				continue;
			}
		}

		switch (token_type(next)) {
		case TOKEN_STREAMEND:
			if (stream->top_if) {
				nesting_error(stream);
				sparse_error(sctx_ stream->top_if->pos, "unterminated preprocessor conditional");
				stream->top_if = NULL;
				sctxp false_nesting = 0;
			}
			if (!stream->dirty)
				stream->constant = CONSTANT_FILE_YES;
			*list = next->next;
			continue;
		case TOKEN_STREAMBEGIN:
			*list = next->next;
			continue;

		default:
			dirty_stream(stream);
			if (sctxp false_nesting) {
				*list = next->next;
				__free_token(sctx_ next);
				continue;
			}

			if (token_type(next) != TOKEN_IDENT ||
			    expand_one_symbol(sctx_ list))
				list = &next->next;
		}
	}
	return l;
}

struct token * preprocess(SCTX_ struct expansion *e)
{
	sctxp preprocessing = 1;
	init_preprocessor(sctx );

	e->d = dup_list_e(sctx_ e->s, 0, e);
	do_preprocess(sctx_ &e->d);

	// Drop all expressions from preprocessing, they're not used any more.
	// This is not true when we have multiple files, though ;/
	// clear_expression_alloc();
	sctxp preprocessing = 0;

	/*printf("e:%p d:%p %p\n",e, e->d, e->d->next);*/
	
	return e->d;
}
