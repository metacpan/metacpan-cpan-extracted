/*
 * (c) Thomas Pornin 1999 - 2002
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 4. The name of the authors may not be used to endorse or promote
 *    products derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR 
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#ifndef UCPP__UCPPI__
#define UCPP__UCPPI__

#include "tune.h"
#include "cpp.h"
#include "nhash.h"
#include "reent.h"

/*
 * A macro represented in a compact form; simple tokens are represented
 * by one byte, containing their number. Tokens with a string value are
 * followed by the value (string finished by a 0). Macro arguments are
 * followed by the argument number (in one byte -- thus implying a hard
 * limit of 254 arguments (number 255 is for __VA_ARGS__).
 */
struct comp_token_fifo {
	size_t length;
	size_t rp;
	unsigned char *t;
};

/* These declarations are used only internally by ucpp */

/*
 * S_TOKEN(x)	checks whether x is a token type with an embedded string
 * ttMWS(x)	checks whether x is macro whitespace (space, comment...)
 * ttWHI(x)	checks whether x is whitespace (MWS or newline)
 */
#define S_TOKEN(x)	STRING_TOKEN(x)
#define ttMWS(x)	((x) == NONE || (x) == COMMENT || (x) == OPT_NONE)
#define ttWHI(x)	(ttMWS(x) || (x) == NEWLINE)

/*
 * Function prototypes
 */
/*
 * from lexer.c
 */
#define init_cppm		UCPP_PRIVATE(init_cppm)
#define put_char		UCPP_PRIVATE(put_char)
#define discard_char		UCPP_PRIVATE(discard_char)
#define next_token		UCPP_PRIVATE(next_token)
#define grap_char		UCPP_PRIVATE(grap_char)
#define space_char		UCPP_PRIVATE(space_char)

void init_cppm(pCPP);
void put_char(pCPP_ struct lexer_state *, unsigned char);
void discard_char(pCPP_ struct lexer_state *);
int next_token(pCPP_ struct lexer_state *);
int grap_char(pCPP_ struct lexer_state *);
int space_char(int);

#ifdef UCPP_REENTRANT
#define new_cppm		UCPP_PRIVATE(new_cppm)
#define del_cppm		UCPP_PRIVATE(del_cppm)
CPPM new_cppm(void);
void del_cppm(CPPM);
#endif

#ifdef UCPP_CLONE
#define clone_cppm		UCPP_PRIVATE(clone_cppm)
CPPM clone_cppm(const CPPM);
#endif

/*
 * from assert.c
 */
struct assert {
	hash_item_header head;    /* first field */
	size_t nbval;
	struct token_fifo *val;
};

#define cmp_token_list		UCPP_PRIVATE(cmp_token_list)
#define handle_assert		UCPP_PRIVATE(handle_assert)
#define handle_unassert		UCPP_PRIVATE(handle_unassert)
#define get_assertion		UCPP_PRIVATE(get_assertion)
#define wipe_assertions		UCPP_PRIVATE(wipe_assertions)

int cmp_token_list(struct token_fifo *, struct token_fifo *);
int handle_assert(pCPP_ struct lexer_state *);
int handle_unassert(pCPP_ struct lexer_state *);
struct assert *get_assertion(pCPP_ char *);
void wipe_assertions(pCPP);

/*
 * from macro.c
 */
struct macro {
	hash_item_header head;     /* first field */
	int narg;
	char **arg;
	int nest;
	int vaarg;
#ifdef LOW_MEM
	struct comp_token_fifo cval;
#else
	struct token_fifo val;
#endif
};

#define print_token		UCPP_PRIVATE(print_token)
#define handle_define		UCPP_PRIVATE(handle_define)
#define handle_undef		UCPP_PRIVATE(handle_undef)
#define handle_ifdef		UCPP_PRIVATE(handle_ifdef)
#define handle_ifndef		UCPP_PRIVATE(handle_ifndef)
#define substitute_macro	UCPP_PRIVATE(substitute_macro)
#define get_macro		UCPP_PRIVATE(get_macro)
#define wipe_macros		UCPP_PRIVATE(wipe_macros)

void print_token(pCPP_ struct lexer_state *, struct token *, long);
int handle_define(pCPP_ struct lexer_state *);
int handle_undef(pCPP_ struct lexer_state *);
int handle_ifdef(pCPP_ struct lexer_state *);
int handle_ifndef(pCPP_ struct lexer_state *);
int substitute_macro(pCPP_ struct lexer_state *, struct macro *,
	struct token_fifo *, int, int, long);
struct macro *get_macro(pCPP_ char *);
void wipe_macros(pCPP);

#ifdef UCPP_REENTRANT

#define dsharp_lexer		(REENTR->_global.dsharp_lexer)
#define compile_time		(REENTR->_global.compile_time)
#define compile_date		(REENTR->_global.compile_date)
#ifdef PRAGMA_TOKENIZE
#define tokenize_lexer		(REENTR->_global.tokenize_lexer)
#endif

#else

#define dsharp_lexer		UCPP_PRIVATE(dsharp_lexer)
#define compile_time		UCPP_PRIVATE(compile_time)
#define compile_date		UCPP_PRIVATE(compile_date)
extern struct lexer_state dsharp_lexer;
extern char compile_time[], compile_date[];

#ifdef PRAGMA_TOKENIZE
#define tokenize_lexer		UCPP_PRIVATE(tokenize_lexer)
extern struct lexer_state tokenize_lexer;
#endif

#endif /* UCPP_REENTRANT */

/*
 * from eval.c
 */
#define strtoconst		UCPP_PRIVATE(strtoconst)
#define eval_expr		UCPP_PRIVATE(eval_expr)

unsigned long strtoconst(pCPP_ char *);
unsigned long eval_expr(pCPP_ struct token_fifo *, int *, int);

#ifdef UCPP_REENTRANT
#define eval_line		(REENTR->_global.eval_line)
#else
#define eval_line		UCPP_PRIVATE(eval_line)
extern long eval_line;
#endif

#ifdef UCPP_REENTRANT
#define eval_exception		(REENTR->_global.eval_exception)
#else
#define eval_exception		UCPP_PRIVATE(eval_exception)
extern JMP_BUF eval_exception;
#endif

/*
 * from cpp.c
 */
#define token_name		UCPP_PRIVATE(token_name)
#define throw_away		UCPP_PRIVATE(throw_away)
#define garbage_collect		UCPP_PRIVATE(garbage_collect)
#define init_buf_lexer_state	UCPP_PRIVATE(init_buf_lexer_state)
#ifdef PRAGMA_TOKENIZE
#define compress_token_list	UCPP_PRIVATE(compress_token_list)
#endif

char *token_name(struct token *);
void throw_away(struct garbage_fifo *, char *);
void garbage_collect(struct garbage_fifo *);
void init_buf_lexer_state(struct lexer_state *, int);
#ifdef PRAGMA_TOKENIZE
struct comp_token_fifo compress_token_list(struct token_fifo *);
#endif

#ifdef UCPP_REENTRANT

#define no_special_macros	(REENTR->no_special_macros)
#define emit_dependencies	(REENTR->emit_dependencies)
#define emit_defines		(REENTR->emit_defines)
#define emit_assertions		(REENTR->emit_assertions)
#define c99_compliant		(REENTR->c99_compliant)
#define c99_hosted		(REENTR->c99_hosted)
#define emit_output		(REENTR->emit_output)
#define current_filename	(REENTR->current_filename)
#define current_long_filename	(REENTR->current_long_filename)
#define ouch			(REENTR->ucpp_ouch)
#define error			(REENTR->ucpp_error)
#define warning			(REENTR->ucpp_warning)
#define transient_characters	(REENTR->transient_characters)
#define protect_detect		(REENTR->protect_detect)

#else

#define ouch			ucpp_ouch
#define error			ucpp_error
#define warning			ucpp_warning

#endif

#endif
