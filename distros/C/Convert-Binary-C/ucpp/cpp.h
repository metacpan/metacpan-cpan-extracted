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

#ifndef UCPP__CPP__
#define UCPP__CPP__

/*
 * Uncomment the following if you want ucpp to use externally provided
 * error-reporting functions (ucpp_warning(), ucpp_error() and ucpp_ouch())
 */
/* #define NO_UCPP_ERROR_FUNCTIONS */

/*
 * Tokens (do not change the order unless checking operators_name[] in cpp.c)
 *
 * It is important that the token NONE is 0
 * Check the STRING_TOKEN macro
 */
#define CPPERR	512
enum {
	NONE,		/* whitespace */
	NEWLINE,	/* newline */
	COMMENT,	/* comment */
	NUMBER,		/* number constant */
	NAME,		/* identifier */
	BUNCH,		/* non-C characters */
	PRAGMA,		/* a #pragma directive */
	CONTEXT,	/* new file or #line */
	STRING,		/* constant "xxx" */
	CHAR,		/* constant 'xxx' */
	SLASH,		/*	/	*/
	ASSLASH,	/*	/=	*/
	MINUS,		/*	-	*/
	MMINUS,		/*	--	*/
	ASMINUS,	/*	-=	*/
	ARROW,		/*	->	*/
	PLUS,		/*	+	*/
	PPLUS,		/*	++	*/
	ASPLUS,		/*	+=	*/
	LT,		/*	<	*/
	LEQ,		/*	<=	*/
	LSH,		/*	<<	*/
	ASLSH,		/*	<<=	*/
	GT,		/*	>	*/
	GEQ,		/*	>=	*/
	RSH,		/*	>>	*/
	ASRSH,		/*	>>=	*/
	ASGN,		/*	=	*/
	SAME,		/*	==	*/
#ifdef CAST_OP
	CAST,		/*	=>	*/
#endif
	NOT,		/*	~	*/
	NEQ,		/*	!=	*/
	AND,		/*	&	*/
	LAND,		/*	&&	*/
	ASAND,		/*	&=	*/
	OR,		/*	|	*/
	LOR,		/*	||	*/
	ASOR,		/*	|=	*/
	PCT,		/*	%	*/
	ASPCT,		/*	%=	*/
	STAR,		/*	*	*/
	ASSTAR,		/*	*=	*/
	CIRC,		/*	^	*/
	ASCIRC,		/*	^=	*/
	LNOT,		/*	!	*/
	LBRA,		/*	{	*/
	RBRA,		/*	}	*/
	LBRK,		/*	[	*/
	RBRK,		/*	]	*/
	LPAR,		/*	(	*/
	RPAR,		/*	)	*/
	COMMA,		/*	,	*/
	QUEST,		/*	?	*/
	SEMIC,		/*	;	*/
	COLON,		/*	:	*/
	DOT,		/*	.	*/
	MDOTS,		/*	...	*/
	SHARP,		/*	#	*/
	DSHARP,		/*	##	*/

	OPT_NONE,	/* optional space to separate tokens in text output */

	DIGRAPH_TOKENS,			/* there begin digraph tokens */

	/* for DIG_*, do not change order, unless checking undig() in cpp.c */
	DIG_LBRK,	/*	<:	*/
	DIG_RBRK,	/*	:>	*/
	DIG_LBRA,	/*	<%	*/
	DIG_RBRA,	/*	%>	*/
	DIG_SHARP,	/*	%:	*/
	DIG_DSHARP,	/*	%:%:	*/

	DIGRAPH_TOKENS_END,		/* digraph tokens end here */

	LAST_MEANINGFUL_TOKEN,		/* reserved words will go there */

	MACROARG,	/* special token for representing macro arguments */

	UPLUS = CPPERR,	/* unary + */
	UMINUS		/* unary - */
};

#include "tune.h"
#include <stdio.h>
#include <setjmp.h>

struct token {
	int type;
	long line;
	char *name;
};

struct token_fifo {
	struct token *t;
	size_t nt, art;
};

struct lexer_state {
	/* input control */
	FILE *input;
#ifndef NO_UCPP_BUF
	unsigned char *input_buf;
#ifdef UCPP_MMAP
	int from_mmap;
	unsigned char *input_buf_sav;
#endif
#endif
	unsigned char *input_string;
	size_t ebuf;
	size_t pbuf;
	int lka[2];
	int nlka;
	int macfile;
	int last;
	int discard;
	unsigned long utf8;
#ifndef NO_UCPP_COPY_LINE
	unsigned char copy_line[COPY_LINE_LENGTH];
	int cli;
#endif

	/* output control */
	FILE *output;
	struct token_fifo *output_fifo, *toplevel_of;
#ifndef NO_UCPP_BUF
	unsigned char *output_buf;
#endif
	size_t sbuf;

	/* token control */
	struct token *ctok;
	struct token *save_ctok;
	size_t tknl;
	int ltwnl;
	int pending_token;
#ifdef INMACRO_FLAG
	int inmacro;
	long macro_count;
#endif

	/* lexer options */
	long line;
	long oline;
	unsigned long flags;
	long count_trigraphs;
	struct garbage_fifo *gf;
	int ifnest;
	int condnest;
	int condcomp;
	int condmet;
	unsigned long condf[2];
};

/*
 * Callback argument for iterate_macros()
 */
struct macro_info {
  void *arg;
  const char *name;
  const char *definition;
  size_t definition_len;
};

/*
 * Flags for iterate_macros()
 */
#define MI_WITH_DEFINITION     0x00000001UL

/*
 * Flags for struct lexer_state
 */
/* warning flags */
#define WARN_STANDARD	     0x000001UL	/* emit standard warnings */
#define WARN_ANNOYING	     0x000002UL	/* emit annoying warnings */
#define WARN_TRIGRAPHS	     0x000004UL	/* warn when trigraphs are used */
#define WARN_TRIGRAPHS_MORE  0x000008UL	/* extra-warn for trigraphs */
#define WARN_PRAGMA	     0x000010UL	/* warn for pragmas in non-lexer mode */

/* error flags */
#define FAIL_SHARP	     0x000020UL	/* emit errors on rogue '#' */
#define CCHARSET	     0x000040UL	/* emit errors on non-C characters */

/* emission flags */
#define DISCARD_COMMENTS     0x000080UL	/* discard comments from text output */
#define CPLUSPLUS_COMMENTS   0x000100UL	/* understand C++-like comments */
#define LINE_NUM	     0x000200UL	/* emit #line directives in output */
#define GCC_LINE_NUM	     0x000400UL	/* same as #line, with gcc-syntax */

/* language flags */
#define HANDLE_ASSERTIONS    0x000800UL	/* understand assertions */
#define HANDLE_PRAGMA	     0x001000UL	/* emit PRAGMA tokens in lexer mode */
#define MACRO_VAARG	     0x002000UL	/* understand macros with '...' */
#define UTF8_SOURCE	     0x004000UL	/* identifiers are in UTF8 encoding */
#define HANDLE_TRIGRAPHS     0x008000UL	/* handle trigraphs */

/* global ucpp behaviour */
#define LEXER		     0x010000UL	/* behave as a lexer */
#define KEEP_OUTPUT	     0x020000UL	/* emit the result of preprocessing */
#define COPY_LINE	     0x040000UL /* make a copy of the parsed line */

/* internal flags */
#define READ_AGAIN	     0x080000UL	/* emit again the last token */
#define TEXT_OUTPUT	     0x100000UL	/* output text */

/*
 * Public function prototypes
 */

#include "reent.h"

#ifdef UCPP_REENTRANT
#define new_cpp			UCPP_PUBLIC(new_cpp)
#define del_cpp			UCPP_PUBLIC(del_cpp)
struct CPP *new_cpp(void);
void del_cpp(struct CPP *);
#endif /* UCPP_REENTRANT */

#ifdef UCPP_CLONE
#define clone_cpp		UCPP_PUBLIC(clone_cpp)
struct CPP *clone_cpp(const struct CPP *);
#endif /* UCPP_CLONE */

#ifndef NO_UCPP_BUF
#define flush_output		UCPP_PUBLIC(flush_output)
void flush_output(pCPP_ struct lexer_state *);
#endif

#define init_assertions		UCPP_PUBLIC(init_assertions)
#define make_assertion		UCPP_PUBLIC(make_assertion)
#define destroy_assertion	UCPP_PUBLIC(destroy_assertion)
#define print_assertions	UCPP_PUBLIC(print_assertions)
void init_assertions(pCPP);
int make_assertion(pCPP_ char *);
int destroy_assertion(pCPP_ char *);
void print_assertions(pCPP);

#define init_macros		UCPP_PUBLIC(init_macros)
#define define_macro		UCPP_PUBLIC(define_macro)
#define undef_macro		UCPP_PUBLIC(undef_macro)
#define print_defines		UCPP_PUBLIC(print_defines)
#define is_macro_defined	UCPP_PUBLIC(is_macro_defined)
#define get_macro_definition	UCPP_PUBLIC(get_macro_definition)
#define free_macro_definition	UCPP_PUBLIC(free_macro_definition)
#define iterate_macros		UCPP_PUBLIC(iterate_macros)
void init_macros(pCPP);
int define_macro(pCPP_ struct lexer_state *, char *);
int undef_macro(pCPP_ struct lexer_state *, char *);
void print_defines(pCPP);
int is_macro_defined(pCPP_ const char *);
char *get_macro_definition(pCPP_ const char *, size_t *);
void free_macro_definition(char *);
void iterate_macros(pCPP_ void (*)(const struct macro_info *), void *, unsigned long);

#define set_init_filename	UCPP_PUBLIC(set_init_filename)
#define init_cpp		UCPP_PUBLIC(init_cpp)
#define init_include_path	UCPP_PUBLIC(init_include_path)
#define init_lexer_state	UCPP_PUBLIC(init_lexer_state)
#define init_lexer_mode		UCPP_PUBLIC(init_lexer_mode)
#define free_lexer_state	UCPP_PUBLIC(free_lexer_state)
#define wipeout			UCPP_PUBLIC(wipeout)
#define lex			UCPP_PUBLIC(lex)
#define check_cpp_errors	UCPP_PUBLIC(check_cpp_errors)
#define add_incpath		UCPP_PUBLIC(add_incpath)
#define init_tables		UCPP_PUBLIC(init_tables)
#define enter_file		UCPP_PUBLIC(enter_file)
#define cpp			UCPP_PUBLIC(cpp)
#define set_identifier_char	UCPP_PUBLIC(set_identifier_char)
#define unset_identifier_char	UCPP_PUBLIC(unset_identifier_char)
void set_init_filename(pCPP_ char *, int);
void init_cpp(pCPP);
void init_include_path(pCPP_ char *[]);
void init_lexer_state(struct lexer_state *);
void init_lexer_mode(struct lexer_state *);
void free_lexer_state(struct lexer_state *);
void wipeout(pCPP);
int lex(pCPP_ struct lexer_state *);
int check_cpp_errors(pCPP_ struct lexer_state *);
void add_incpath(pCPP_ char *);
void init_tables(pCPP_ int);
int enter_file(pCPP_ struct lexer_state *, unsigned long);
int cpp(pCPP_ struct lexer_state *);
void set_identifier_char(pCPP_ int c);
void unset_identifier_char(pCPP_ int c);

#ifdef UCPP_MMAP
#define fopen_mmap_file		UCPP_PUBLIC(fopen_mmap_file)
#define set_input_file		UCPP_PUBLIC(set_input_file)
FILE *fopen_mmap_file(pCPP_ char *);
void set_input_file(pCPP_ struct lexer_state *, FILE *);
#endif

struct stack_context {
	char *long_name, *name;
	long line;
};
#define report_context		UCPP_PUBLIC(report_context)
struct stack_context *report_context(pCPP);

#ifndef UCPP_REENTRANT
#define no_special_macros	UCPP_PUBLIC(no_special_macros)
#define emit_dependencies	UCPP_PUBLIC(emit_dependencies)
#define emit_defines		UCPP_PUBLIC(emit_defines)
#define emit_assertions		UCPP_PUBLIC(emit_assertions)
#define c99_compliant		UCPP_PUBLIC(c99_compliant)
#define c99_hosted		UCPP_PUBLIC(c99_hosted)
#define emit_output		UCPP_PUBLIC(emit_output)
#define current_filename	UCPP_PUBLIC(current_filename)
#define current_long_filename	UCPP_PUBLIC(current_long_filename)
extern int no_special_macros,
	emit_dependencies, emit_defines, emit_assertions;
extern int c99_compliant, c99_hosted;
extern FILE *emit_output;
extern char *current_filename, *current_long_filename;
#endif

#define operators_name		UCPP_PUBLIC(operators_name)
extern char *operators_name[];

#ifndef UCPP_REENTRANT
#define protect_detect		UCPP_PUBLIC(protect_detect)
extern struct protect {
	char *macro;
	int state;
	struct found_file *ff;
} protect_detect;
#endif

#ifndef UCPP_REENTRANT
#define ucpp_ouch		UCPP_PUBLIC(ucpp_ouch)
#define ucpp_error		UCPP_PUBLIC(ucpp_error)
#define ucpp_warning		UCPP_PUBLIC(ucpp_warning)
void ucpp_ouch(char *, ...);
void ucpp_error(long, char *, ...);
void ucpp_warning(long, char *, ...);
#endif

#ifndef UCPP_REENTRANT
#define transient_characters	UCPP_PUBLIC(transient_characters)
extern int *transient_characters;
#endif

/*
 * Errors from CPPERR_EOF and above are not real erros, only show-stoppers.
 * Errors below CPPERR_EOF are real ones.
 */
#define CPPERR_NEST	 900
#define CPPERR_EOF	1000

/*
 * This macro tells whether the name field of a given token type is
 * relevant, or not. Irrelevant name field means that it might point
 * to outerspace.
 */
#ifdef SEMPER_FIDELIS
#define STRING_TOKEN(x)    ((x) == NONE || ((x) >= COMMENT && (x) <= CHAR))
#else
#define STRING_TOKEN(x)    ((x) >= NUMBER && (x) <= CHAR)
#endif

#endif
