#ifndef TOKEN_H
#define TOKEN_H

#include "token_struct.h"
#include "ctx.h"

#define MAX_STRING 8191

static inline struct token *containing_token(struct token **p)
{
	void *addr = (char *)p - ((char *)&((struct token *)0)->next - (char *)0);
	return addr;
}

#define token_type(x) ((x)->pos.type)

/*
 * Last token in the stream - points to itself.
 * This allows us to not test for NULL pointers
 * when following the token->next chain..
 */
#ifndef DO_CTX
extern struct token eof_token_entry;
#endif
#define eof_token(x) ((x) == &sctxp eof_token_entry)

static inline struct token *list_e(SCTX_ struct token *l, struct token *end, struct expansion *e)
{
	struct token *r = l;
	while (l != end && !eof_token(l)) {
		l->e = e;
		l = l->next;
	}
	return r;
}

/*
static inline struct token *list_cons_c(SCTX_ struct token *l, struct token *end, struct expansion *e)
{
	struct token *r = l, *c;
	while (l != end && !eof_token(l)) {
		c = l->copy;
		if (c)
			c->c = e;
		l = l->next;
	}
	return r;
}
*/

static inline struct token *list_set_type(SCTX_ struct token *l, struct token *end, enum token_type typ)
{
	struct token *r = l;
	while (l != end && !eof_token(l)) {
		l->pos.type = typ;
		l = l->next;
	}
	return r;
}

extern struct stream *init_stream(SCTX_ const char *, int fd, const char **next_path);
extern const char *stream_name(SCTX_ int stream);
extern struct stream *stream_get(SCTX_ int stream);
extern struct ident *hash_ident(SCTX_ struct ident *);
extern struct ident *built_in_ident(SCTX_ const char *);
extern struct token *built_in_token(SCTX_ int, const char *);
extern const char *show_special(SCTX_ int);
extern const char *show_ident(SCTX_ const struct ident *);
extern const char *show_string(SCTX_ const struct string *string);
extern const char *show_token(SCTX_ const struct token *);
extern const char *quote_token(SCTX_ const struct token *);
extern struct expansion *tokenize(SCTX_ const char *, int, struct token *, const char **next_path);
extern struct expansion * tokenize_buffer(SCTX_ void *, unsigned , unsigned long, struct token **);
extern void init_preprocessor(SCTX);
extern unsigned long hash_name(SCTX_ const char *name, int len);
extern struct ident *create_hashed_ident(SCTX_ const char *name, int len, unsigned long hash);
extern void cstr_ccat(SCTX_ CString *cstr, int ch);
extern void cstr_new(SCTX_ CString *cstr);
extern void cstr_cstring(SCTX_ CString *cstr);
extern int stream_issys(stream_t *stream);
extern int ppre_issys(SCTX_ const char **p);
extern struct cons *cons_list(SCTX_ struct token *list, struct token *end);
extern struct expansion *expansion_new(SCTX_ int typ);

extern void show_identifier_stats(SCTX);
extern struct token *preprocess(SCTX_ struct expansion *);

static inline int match_op(struct token *token, int op)
{
	return token->pos.type == TOKEN_SPECIAL && token->special == op;
}

static inline int match_ident(struct token *token, struct ident *id)
{
	return token->pos.type == TOKEN_IDENT && token->ident == id;
}

#endif
