%{
#include <stdio.h>
#include <stdlib.h>
#include "compiler.h"
#include "parser.h"

#define YY_DECL int yylex(YYSTYPE *yylval, amd_parse_param_t *param)

static int yyinteger(YYSTYPE *lvalp);
static int yyidentifier(YYSTYPE *lvalp, amd_parse_param_t *param);
%}

%option noyywrap
%option noinput
%option nounput
%option noreject
%option noyy_top_state

	/* %option debug */

%s CODE
%x BLANK
%x STRING
%x PPLINE
%x CCOMMENT
%x CPPCOMMENT

WHITE			[ \f\t\v]+
NONWHITE		[^ \f\t\v\r\n]
NL				(\r|\r\n|\n)

MESS			[^ \f\t\v\r\n]

LETTER			[[:alpha:]_]
NONLETTER		[^[:alpha:][:space:]_]

CHAR			[[:alnum:]_]
NONCHAR			[^[:alnum:][:space:]_]

TOKEN			{LETTER}{CHAR}*
NONTOKEN		[[:digit:]]({CHAR}|[[:digit:]])*

MACRO			{TOKEN}
NONMACRO		{NONLETTER}{NONWHITE}*

NONNUMBER		[[:digit:]]{CHAR}+

%%

<BLANK>{WHITE}		{ BEGIN(CODE); }
<BLANK>{NL}			{ /* Optimise for blank lines. */ }
<BLANK>#			{ BEGIN(PPLINE); }
<BLANK>[^#]			{ yyless(0); BEGIN(CODE); }

<PPLINE>{NL}		{ BEGIN(BLANK); }
<PPLINE>\\{NL}		{ }
<PPLINE>{WHITE}		{ }
<PPLINE>[^\\\n]+	{ }
<PPLINE>\\			{ }


\"					{ BEGIN(STRING); yylval->sv = newSVpv("", 0); }
<STRING>\"			{ BEGIN(INITIAL); return L_STRING; }
<STRING>[^\"\\]*	{ sv_catpv(yylval->sv, yytext); }

<STRING>\\[0-7]{1,2}			{ /* octal char */ }
<STRING>\\[0-3][0-7]{1,2}		{ /* octal char */ }
<STRING>\\x[[:xdigit:]]{1,2}	{ /* hex char */ }
<STRING>\\n					{ sv_catpv(yylval->sv, "\n"); }
<STRING>\\t					{ sv_catpv(yylval->sv, "\t"); }
<STRING>\\v					{ sv_catpv(yylval->sv, "\v"); }
<STRING>\\b					{ sv_catpv(yylval->sv, "\b"); }
<STRING>\\r					{ sv_catpv(yylval->sv, "\r"); }
<STRING>\\f					{ sv_catpv(yylval->sv, "\f"); }
<STRING>\\a					{ sv_catpv(yylval->sv, "\a"); }
<STRING>\\[\\\?\'\"]    	{ sv_catpvn(yylval->sv, (yytext + 1), 1); }
<STRING>\\x[^[:xdigit:]]{1,2}	{
						yywarnf("Bad hexadecimal escape %s", yytext);
						sv_catpv(yylval->sv, yytext);
							}
<STRING>\\[0-9]{1,2}		{
						yywarnf("Bad octal escape %s", yytext);
						sv_catpv(yylval->sv, yytext);
							}
<STRING>\\[^\\\?\'\"ntvbrfa0-9]	{
						warn("Unknown escape character \\%c",yytext[1]);
						sv_catpvn(yylval->sv, (yytext + 1), 1);
							}

[[:digit:]]+			{ return yyinteger(yylval); }
0x[[:xdigit:]]+			{ return yyinteger(yylval); }
\$[[:digit:]]+			{ yylval->number = atol(yytext); return L_PARAMETER; }
{TOKEN}					{ return yyidentifier(yylval, param); }
{NONNUMBER}				{ warn("Letters in number and not hex"); }

{WHITE}					{ }
{NL}					{ BEGIN(BLANK); /* increment lineno */ }
	/* \\ \n should never happen after the preprocessor */

\|\|=				{ return L_LOR_EQ; }
&&=					{ return L_LAND_EQ; }

\+=					{ return L_PLUS_EQ; }
-=					{ return L_MINUS_EQ; }
\/=					{ return L_DIV_EQ; }
\*=					{ return L_TIMES_EQ; }
%=					{ return L_MOD_EQ; }
&=					{ return L_AND_EQ; }
\|=					{ return L_OR_EQ; }
\^=					{ return L_XOR_EQ; }
\.=					{ return L_DOT_EQ; }

==					{ return L_EQ; }
!=					{ return L_NE; }
\<=					{ return L_LE; }
>=					{ return L_GE; }

\|\|				{ return L_LOR; }
&&					{ return L_LAND; }

\+\+				{ return L_INC; }
--					{ return L_DEC; }

>>					{ return L_RSH; }
\<<					{ return L_LSH; }

\(\[				{ return L_MAP_START; }
\]\)				{ return L_MAP_END; }
\(\{				{ return L_ARRAY_START; }
\}\)				{ return L_ARRAY_END; }
\(:					{ return L_FUNCTION_START; }
:\)					{ return L_FUNCTION_END; }

::					{ return L_COLONCOLON; }
->					{ return L_ARROW; }
\.\.				{ return L_RANGE; }

\.\.\.				{ return L_ELLIPSIS; }

[\+-/\*#%&\|<>\^~\?\.\{\},;:\(\)\[\]!=\$]	{ return *yytext; }

		/* Strays */

\\					{ yyerrorf("Stray \\ in program\n");  }
[[:print:]]			{ yyerrorf("Illegal character (hex %d) '%c'\n",
										*yytext, *yytext); }
<*>[^[:print:]]		{ yyerrorf("Unexpected non-ASCII %d\n", *yytext); }
<*><<EOF>>			{ return 0; }

%%

void
yywarnv(const char *fmt, va_list args)
{
	char	 msg[BUFSIZ];
	vsnprintf(msg, BUFSIZ, fmt, args);
	fprintf(stderr, "%s", msg);
}

void
yywarnf(const char *fmt, ...)
{
	va_list	 args;
	va_start(args, fmt);
	yywarnv(fmt, args);
	va_end(args);
}

void
yyerrorf(const char *fmt, ...)
{
	va_list	 args;
	va_start(args, fmt);
	yywarnv(fmt, args);
	va_end(args);
	exit(1);
}

void
yyerror(const char *str)
{
	yyerrorf("Parse error: %s\n", str);
}

static int
yyinteger(YYSTYPE *lvalp)
{
	unsigned long	 val;
	char			*ep;

	val = strtoul(yytext, &ep, 0);
	if (*ep) {
		yywarnf("Invalid integer %s: character %c is invalid\n",
						yytext, *ep);
		val = 0;
	}

	lvalp->number = val;

	return L_INTEGER;
}

static int
yyidentifier(YYSTYPE *lvalp, amd_parse_param_t *param)
{
	SV	**svp;
	SV	 *sv;
	SV	**lvp;

#if 0
	fprintf(stderr, "yyidentifier: %s\n", yytext);
	fflush(stderr);
#endif

	svp = hv_fetch(amd_kwtab, yytext, yyleng, FALSE);
	if (svp) {
		lvalp->number = 0;
		lvp = hv_fetch(amd_lvaltab, yytext, yyleng, FALSE);
		if (lvp) {
			*lvalp = *(INT2PTR(YYSTYPE *, SvIV(*lvp)));
		}

		return SvIV(*svp);
	}

	/* Throw the thing in some sort of hash table so we get an SV? */
	svp = hv_fetch(param->symtab, yytext, yyleng, FALSE);
	if (svp) {
		sv = *svp;
	}
	else {
		sv = newSVpv(yytext, yyleng);
		hv_store(param->symtab, yytext, yyleng, sv, 0);
	}

	lvalp->sv = sv;

	return L_IDENTIFIER;
}

void
yyunput_map_end()
{
	yyless(1);
}

void
yylex_init(const char *str)
{
	yy_scan_string(str);
	BEGIN(BLANK);
}

int
yylex_verbose(YYSTYPE *yylval, amd_parse_param_t *param)
{
	int	 tok;

	tok = yylex(yylval, param);
	fprintf(stderr, "L: %d (%s) [%s]\n", tok, yytokname(tok), yytext);

	return tok;
}

int
test_lexer(const char *str)
{
	YYSTYPE	 yylval;

	amd_parse_param_t	 param;

	memset(&param, 0, sizeof(param));
	param.program = NULL;
	param.symtab = newHV();


	yylex_init(str);

	while (yylex_verbose(&yylval, &param))
		;

	return 0;
}
