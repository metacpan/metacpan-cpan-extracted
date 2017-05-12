#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "compiler.h"
#include "parser.h"
#include "../Type/type.h"

/* Apparently we are expected to provide this type as named. */

typedef
struct _amd_parser {
	void	*foo;
} *Anarres__Mud__Driver__Compiler;

typedef char *Anarres__Mud__Driver__Compiler__Type;

typedef
struct _keyword_t
{
	char		*keyword;
	int			 token;
	AMD_YYSTYPE	 lval;
}
keyword_t;

#define LVAL_NONE		{ .number = 0 }

	/* We have to allocate static storage for all of these. */
static const char LVAL_BOOL[] = { C_BOOL, 0 };
static const char LVAL_CLOSURE[] = { C_CLOSURE, 0 };
static const char LVAL_INTEGER[] = { C_INTEGER, 0 };
static const char LVAL_MAPPING[] = { C_M_MAPPING, C_UNKNOWN, 0 };
static const char LVAL_UNKNOWN[] = { C_UNKNOWN, 0 };
static const char LVAL_OBJECT[] = { C_OBJECT, 0 };
static const char LVAL_STRING[] = { C_STRING, 0 };
static const char LVAL_VOID[] = { C_VOID, 0 };

static keyword_t keywords[] = {
	{ "bool",		L_BASIC_TYPE,		{ .str = LVAL_BOOL } },
	{ "break",		L_BREAK,			LVAL_NONE },
	{ "case",		L_CASE,				LVAL_NONE },
	{ "class",		L_CLASS,			LVAL_NONE },
	{ "continue",	L_CONTINUE,			LVAL_NONE },
	{ "default",	L_DEFAULT,			LVAL_NONE },
	{ "do",			L_DO,				LVAL_NONE },
	{ "efun",		L_EFUN,				LVAL_NONE },
	{ "else",		L_ELSE,				LVAL_NONE },
	{ "for",		L_FOR,				LVAL_NONE },
	{ "foreach",	L_FOREACH,			LVAL_NONE },
	{ "function",	L_BASIC_TYPE,		{ .str = LVAL_CLOSURE } },
	{ "if",			L_IF,				LVAL_NONE },
	{ "in",			L_IN,				LVAL_NONE },
	{ "inherit",	L_INHERIT,			LVAL_NONE },
	{ "int",		L_BASIC_TYPE,		{ .str = LVAL_INTEGER } },
	{ "mapping",	L_BASIC_TYPE,		{ .str = LVAL_MAPPING } },
	{ "mixed",		L_BASIC_TYPE,		{ .str = LVAL_UNKNOWN } },
	{ "nil",		L_NIL,				LVAL_NONE },
	{ "new",		L_NEW,				LVAL_NONE },
	{ "nomask",		L_TYPE_MODIFIER,	{ .number = M_NOMASK } },
	{ "nosave",		L_TYPE_MODIFIER,	{ .number = M_NOSAVE } },
	{ "object",		L_BASIC_TYPE,		{ .str = LVAL_OBJECT } },
	{ "private",	L_TYPE_MODIFIER,	{ .number = M_PRIVATE } },
	{ "protected",	L_TYPE_MODIFIER,	{ .number = M_PROTECTED } },
	{ "public",		L_TYPE_MODIFIER,	{ .number = M_PUBLIC } },
	{ "return",		L_RETURN,			LVAL_NONE },
	{ "rlimits",	L_RLIMITS,			LVAL_NONE },
	{ "sscanf",		L_SSCANF,			LVAL_NONE },
	{ "string",		L_BASIC_TYPE,		{ .str = LVAL_STRING } },
	{ "static",		L_TYPE_MODIFIER,	{ .number = M_STATIC } },
	{ "switch",		L_SWITCH,			LVAL_NONE },
	{ "varargs",	L_TYPE_MODIFIER,	{ .number = M_VARARGS } },
	// { "virtual",	L_TYPE_MODIFIER,	{ .number = M_VIRTUAL } },
	{ "void",		L_VOID,				{ .str = LVAL_VOID } },
	{ "while",		L_WHILE,			LVAL_NONE },
};

MODULE = Anarres::Mud::Driver::Compiler	PACKAGE = Anarres::Mud::Driver::Compiler

PROTOTYPES: ENABLE

BOOT:
{
	{
		SV			*sv;
		int			 size;
		int			 i;

		size = sizeof(keywords) / sizeof(keywords[0]);

		/* Don't put this into Perl-space or it can get fucked with. */
		/* One day we might want to allow that. */
		amd_kwtab = newHV();
		amd_lvaltab = newHV();

		for (i = 0; i < size; i++) {
			hv_store(amd_kwtab,
				keywords[i].keyword, strlen(keywords[i].keyword),
				newSViv(keywords[i].token), 0);
			if (keywords[i].lval.number) {
				sv = newSViv(PTR2IV((void *)(&keywords[i].lval) ));
				hv_store(amd_lvaltab,
					keywords[i].keyword, strlen(keywords[i].keyword),
					sv, 0);
			}
		}
	}

	{
		/* The parser needs these to build the tree. */
		amd_require(_AMD "::Compiler::Type");
		amd_require(_AMD "::Compiler::Node");
		amd_require(_AMD "::Program");
	}
}

Anarres::Mud::Driver::Compiler
new(class)
	SV *	class
	CODE:
		RETVAL = Newz(0, RETVAL, 1, struct _amd_parser);
	OUTPUT:
		RETVAL

int
lex(class, str)
	SV *	class
	char *	str
	CODE:
		test_lexer(str);
		RETVAL = 0;
	OUTPUT:
		RETVAL

int
parse(class, prog, str)
	SV *	class
	SV *	prog
	char *	str
	CODE:
		amd_yyparser_parse(prog, str);
		RETVAL = 0;
	OUTPUT:
		RETVAL

void
DESTROY(self)
	Anarres::Mud::Driver::Compiler	self
	CODE:
		Safefree(self);
