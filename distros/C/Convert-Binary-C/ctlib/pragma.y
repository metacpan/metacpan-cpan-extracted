%{
/*******************************************************************************
*
* MODULE: pragma.y
*
********************************************************************************
*
* DESCRIPTION: Pragma parser
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

/*===== GLOBAL INCLUDES ======================================================*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/*===== LOCAL INCLUDES =======================================================*/

#include "ctdebug.h"
#include "cterror.h"
#include "pragma.h"

#include "util/ccattr.h"
#include "util/memalloc.h"
#include "util/list.h"

#include "ucpp/cpp.h"


/*===== DEFINES ==============================================================*/

/* ADDITIONAL BISON CONFIGURATION */

#define YYPARSE_PARAM pState
#define YYLEX_PARAM   pState
#define YYERROR_VERBOSE

/*
 * Bison version >= 1.31 is needed for YYFPRINTF
 */
#if YYDEBUG && defined CTLIB_DEBUGGING
#define YYFPRINTF BisonDebugFunc
#endif

#define pragma_error( msg )     \
        CT_DEBUG( PRAGMA, ("pragma_error(): %s", msg) )

#define pragma_parse            CTlib_pragma_parse

/* MACROS */

#define PSTATE                  ((PragmaState *) pState)

#define VALID_PACK( value )     \
         (   (value) ==  0      \
          || (value) ==  1      \
          || (value) ==  2      \
          || (value) ==  4      \
          || (value) ==  8      \
         )


/*===== TYPEDEFS =============================================================*/

struct _pragmaState {

  CParseInfo  *pCPI;
  const char  *file;
  long int     line;
  const char  *code;

  struct {
    LinkedList stack;
    unsigned   current;
  }            pack;

};

typedef struct {
  unsigned size;
} PackElement;


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/* TOKEN MAPPING TABLE */

static const int tokentab[] = {
	0,		/* NONE, */		/* whitespace */
	0,		/* NEWLINE, */		/* newline */
	0,		/* COMMENT, */		/* comment */
	0,		/* NUMBER, */		/* number constant */
	0,		/* NAME, */		/* identifier */
	0,		/* BUNCH, */		/* non-C characters */
	0,		/* PRAGMA, */		/* a #pragma directive */
	0,		/* CONTEXT, */		/* new file or #line */
	0,		/* STRING, */		/* constant "xxx" */
	0,		/* CHAR, */		/* constant 'xxx' */
	'/',		/* SLASH, */		/*	/	*/
	0,		/* ASSLASH, */		/*	/=	*/
	'-',		/* MINUS, */		/*	-	*/
	0,		/* MMINUS, */		/*	--	*/
	0,		/* ASMINUS, */		/*	-=	*/
	0,		/* ARROW, */		/*	->	*/
	'+',		/* PLUS, */		/*	+	*/
	0,		/* PPLUS, */		/*	++	*/
	0,		/* ASPLUS, */		/*	+=	*/
	'<',		/* LT, */		/*	<	*/
	0,		/* LEQ, */		/*	<=	*/
	0,		/* LSH, */		/*	<<	*/
	0,		/* ASLSH, */		/*	<<=	*/
	'>',		/* GT, */		/*	>	*/
	0,		/* GEQ, */		/*	>=	*/
	0,		/* RSH, */		/*	>>	*/
	0,		/* ASRSH, */		/*	>>=	*/
	'=',		/* ASGN, */		/*	=	*/
	0,		/* SAME, */		/*	==	*/
#ifdef CAST_OP
	0,		/* CAST, */		/*	=>	*/
#endif
	'~',		/* NOT, */		/*	~	*/
	0,		/* NEQ, */		/*	!=	*/
	'&',		/* AND, */		/*	&	*/
	0,		/* LAND, */		/*	&&	*/
	0,		/* ASAND, */		/*	&=	*/
	'|',		/* OR, */		/*	|	*/
	0,		/* LOR, */		/*	||	*/
	0,		/* ASOR, */		/*	|=	*/
	'%',		/* PCT, */		/*	%	*/
	0,		/* ASPCT, */		/*	%=	*/
	'*',		/* STAR, */		/*	*	*/
	0,		/* ASSTAR, */		/*	*=	*/
	'^',		/* CIRC, */		/*	^	*/
	0,		/* ASCIRC, */		/*	^=	*/
	'!',		/* LNOT, */		/*	!	*/
	'{',		/* LBRA, */		/*	{	*/
	'}',		/* RBRA, */		/*	}	*/
	'[',		/* LBRK, */		/*	[	*/
	']',		/* RBRK, */		/*	]	*/
	'(',		/* LPAR, */		/*	(	*/
	')',		/* RPAR, */		/*	)	*/
	',',		/* COMMA, */		/*	,	*/
	'?',		/* QUEST, */		/*	?	*/
	';',		/* SEMIC, */		/*	;	*/
	':',		/* COLON, */		/*	:	*/
	'.',		/* DOT, */		/*	.	*/
	0,		/* MDOTS, */		/*	...	*/
	0,		/* SHARP, */		/*	#	*/
	0,		/* DSHARP, */		/*	##	*/

	0,		/* OPT_NONE, */		/* optional space to separate tokens in text output */

	0,		/* DIGRAPH_TOKENS, */		/* there begin digraph tokens */

	/* for DIG_*, do not change order, unless checking undig() in cpp.c */
	'[',		/* DIG_LBRK, */		/*	<:	*/
	']',		/* DIG_RBRK, */		/*	:>	*/
	'{',		/* DIG_LBRA, */		/*	<%	*/
	'}',		/* DIG_RBRA, */		/*	%>	*/
	0,		/* DIG_SHARP, */	/*	%:	*/
	0,		/* DIG_DSHARP, */	/*	%:%:	*/

	0,		/* DIGRAPH_TOKENS_END, */	/* digraph tokens end here */

	0,		/* LAST_MEANINGFUL_TOKEN, */	/* reserved words will go there */

	0,		/* MACROARG, */		/* special token for representing macro arguments */

	0,		/* UPLUS = CPPERR, */	/* unary + */
	0,		/* UMINUS */		/* unary - */
};

%}

/*===== YACC PARSER DEFINITION ================================================*/

%union {
  int ival;
}

%{

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static        int          is_valid_pack_arg(PragmaState *pState, int arg);

static inline int          pragma_lex(YYSTYPE *plval, PragmaState *pState);

static        PackElement *packelem_new(unsigned size);
static        void         packelem_delete(PackElement *pPack);

%}

%token <ival> CONSTANT

%token PACK_TOK

%token PUSH_TOK POP_TOK

%pure_parser

%start pragma
%%

pragma
	: pragma_pack
	;

pragma_pack
	: PACK_TOK
	  { PSTATE->pack.current = 0; }
	| PACK_TOK '(' ')'
	  { PSTATE->pack.current = 0; }
	| PACK_TOK '(' pragma_pack_args ')'
	;

pragma_pack_args
	: CONSTANT
	  {
	    if (is_valid_pack_arg(PSTATE, $1))
	    {
	      PSTATE->pack.current = $1;
	    }
	  }
	| PUSH_TOK ',' CONSTANT
	  {
	    if (is_valid_pack_arg(PSTATE, $3))
	    {
	      LL_push(PSTATE->pack.stack, packelem_new(PSTATE->pack.current));
	      PSTATE->pack.current = $3;
	    }
	  }
	| POP_TOK
	  {
	    PackElement *pPack = LL_pop(PSTATE->pack.stack);

	    if (pPack)
	    {
	      PSTATE->pack.current = pPack->size;
	      packelem_delete(pPack);
	    }
	    else
	      PSTATE->pack.current = 0;
	  }
	;

%%

/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: is_valid_pack_arg
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jun 2007
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Pack element constructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

static int is_valid_pack_arg(PragmaState *pState, int arg)
{
  if (VALID_PACK(arg))
    return 1;

  push_error(pState->pCPI, "%s, line %ld: invalid argument %d to #pragma pack",
             pState->file, pState->line, arg);

  return 0;
}

/*******************************************************************************
*
*   ROUTINE: packelem_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Pack element constructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

static PackElement *packelem_new(unsigned size)
{
  PackElement *pPack;

  AllocF(PackElement *, pPack, sizeof(PackElement));

  pPack->size = size;

  return pPack;
}

/*******************************************************************************
*
*   ROUTINE: packelem_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Pack element destructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

static void packelem_delete(PackElement *pPack)
{
  if (pPack)
    Free(pPack);
}

/*******************************************************************************
*
*   ROUTINE: pragma_lex
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Pragma lexer.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

static inline int pragma_lex(YYSTYPE *plval, PragmaState *pState)
{
  int token, rval;

  CT_DEBUG( PRAGMA, ("pragma_lex()"));

  while ((token = (int) *pState->code++) != 0)
  {
    switch (token)
    {
      case NUMBER:
        {
          const char *num = pState->code;

          pState->code = strchr(num, PRAGMA_TOKEN_END) + 1;
          plval->ival = strtol(num, NULL, 0);

          CT_DEBUG(PRAGMA, ("pragma - constant: %d", plval->ival));

          return CONSTANT;
        }

      case NAME:
        {
          const char *tokstr = pState->code;
          int toklen, tokval;

#include "token/t_pragma.c"

        success:
          pState->code += toklen + 1;
          return tokval;

        unknown:
          break;
        }

      default:
        if ((rval = tokentab[token]) != 0)
          return rval;

        break;
    }
  }

  return 0;
}


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: pragma_parser_parse
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jun 2007
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION:
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

int pragma_parser_parse(PragmaState *pPragma)
{
  return pragma_parse(pPragma);
}

/*******************************************************************************
*
*   ROUTINE: pragma_parser_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION:
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

PragmaState *pragma_parser_new(CParseInfo *pCPI)
{
  PragmaState *pState;

  CT_DEBUG(PRAGMA, ("pragma_parser_new"));

  AllocF(PragmaState *, pState, sizeof(PragmaState));

  pState->pCPI = pCPI;
  pState->file = 0;
  pState->line = 0;
  pState->code = 0;
  pState->pack.stack = LL_new();
  pState->pack.current = 0;

  return pState;
}

/*******************************************************************************
*
*   ROUTINE: pragma_parser_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION:
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void pragma_parser_delete(PragmaState *pPragma)
{
  if (pPragma)
  {
    CT_DEBUG(PRAGMA, ("pragma_parser_delete"));
    LL_destroy(pPragma->pack.stack, (LLDestroyFunc) packelem_delete);
    Free(pPragma);
  }
}

/*******************************************************************************
*
*   ROUTINE: pragma_parser_set_context
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jun 2007
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION:
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void pragma_parser_set_context(PragmaState *pPragma, const char *file, long int line, const char *code)
{
  pPragma->file = file;
  pPragma->line = line;
  pPragma->code = code;
}

/*******************************************************************************
*
*   ROUTINE: pragma_parser_get_pack
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jun 2007
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION:
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

unsigned pragma_parser_get_pack(PragmaState *pPragma)
{
  return pPragma->pack.current;
}

