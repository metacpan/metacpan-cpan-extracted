/* A Bison parser, made by GNU Bison 2.4.3.  */

/* Skeleton implementation for Bison's Yacc-like parsers in C
   
      Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006,
   2009, 2010 Free Software Foundation, Inc.
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.
   
   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Bison version.  */
#define YYBISON_VERSION "2.4.3"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 1

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1

/* Using locations.  */
#define YYLSP_NEEDED 0

/* Substitute the variable and function names.  */
#define yyparse         c_parse
#define yylex           c_lex
#define yyerror         c_error
#define yylval          c_lval
#define yychar          c_char
#define yydebug         c_debug
#define yynerrs         c_nerrs


/* Copy the first part of user declarations.  */

/* Line 189 of yacc.c  */
#line 1 "ctlib/parser.y"

/*******************************************************************************
*
* MODULE: parser.y
*
********************************************************************************
*
* DESCRIPTION: C parser
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
* Portions Copyright (c) 1989, 1990 James A. Roskind.
* Also see the original copyright notice below.
*
*******************************************************************************/

/* Copyright (C) 1989,1990 James A. Roskind, All rights reserved.
This grammar was developed  and  written  by  James  A.  Roskind.
Copying  of  this  grammar  description, as a whole, is permitted
providing this notice is intact and applicable  in  all  complete
copies.   Translations as a whole to other parser generator input
languages  (or  grammar  description  languages)   is   permitted
provided  that  this  notice is intact and applicable in all such
copies,  along  with  a  disclaimer  that  the  contents  are   a
translation.   The reproduction of derived text, such as modified
versions of this grammar, or the output of parser generators,  is
permitted,  provided  the  resulting  work includes the copyright
notice "Portions Copyright (c)  1989,  1990  James  A.  Roskind".
Derived products, such as compilers, translators, browsers, etc.,
that  use  this  grammar,  must also provide the notice "Portions
Copyright  (c)  1989,  1990  James  A.  Roskind"  in   a   manner
appropriate  to  the  utility,  and in keeping with copyright law
(e.g.: EITHER displayed when first invoked/executed; OR displayed
continuously on display terminal; OR via placement in the  object
code  in  form  readable in a printout, with or near the title of
the work, or at the end of the file).  No royalties, licenses  or
commissions  of  any  kind are required to copy this grammar, its
translations, or derivative products, when the copies are made in
compliance with this notice. Persons or corporations that do make
copies in compliance with this notice may charge  whatever  price
is  agreeable  to  a  buyer, for such copies or derivative works.
THIS GRAMMAR IS PROVIDED ``AS IS'' AND  WITHOUT  ANY  EXPRESS  OR
IMPLIED  WARRANTIES,  INCLUDING,  WITHOUT LIMITATION, THE IMPLIED
WARRANTIES  OF  MERCHANTABILITY  AND  FITNESS  FOR  A  PARTICULAR
PURPOSE.

James A. Roskind
Independent Consultant
516 Latania Palm Drive
Indialantic FL, 32903
(407)729-4348
jar@ileaf.com


ACKNOWLEDGMENT:

Without the effort expended by the ANSI C standardizing committee,  I
would  have been lost.  Although the ANSI C standard does not include
a fully disambiguated syntax description, the committee has at  least
provided most of the disambiguating rules in narratives.

Several  reviewers  have also recently critiqued this grammar, and/or
assisted in discussions during it's preparation.  These reviewers are
certainly not responsible for the errors I have committed  here,  but
they  are responsible for allowing me to provide fewer errors.  These
colleagues include: Bruce Blodgett, and Mark Langley.

*/

/*===== GLOBAL INCLUDES ======================================================*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/*===== LOCAL INCLUDES =======================================================*/

#include "ctdebug.h"
#include "ctparse.h"
#include "cterror.h"
#include "fileinfo.h"
#include "parser.h"
#include "pragma.h"

#include "util/ccattr.h"
#include "util/list.h"
#include "util/memalloc.h"

#include "ucpp/cpp.h"

#include "cppreent.h"


/*===== DEFINES ==============================================================*/

/* ADDITIONAL BISON CONFIGURATION */

#define YYMAXDEPTH        10000
#define YYPARSE_PARAM    pState
#define YYLEX_PARAM      pState

/*
 * Bison version >= 1.31 is needed for YYFPRINTF
 */
#if YYDEBUG && defined CTLIB_DEBUGGING
#define YYFPRINTF BisonDebugFunc
#endif

#define c_error(msg)    parser_error(PSTATE, msg)

#define c_parse         CTlib_c_parse

/* MACROS */

#define PSTATE          ((ParserState *) pState)

#define DELETE_NODE(node)                                                      \
        do {                                                                   \
          if (node != NULL)                                                    \
            HN_delete(node);                                                   \
        } while (0)

#define POSTFIX_DECL(decl, postfix)                                            \
        do {                                                                   \
          if (postfix)                                                         \
          {                                                                    \
            if (decl->pointer_flag)                                            \
              LL_destroy(postfix, (LLDestroyFunc) value_delete);               \
            else                                                               \
            {                                                                  \
              if (decl->array_flag)                                            \
                LL_delete(LL_splice(decl->ext.array, 0, 0, postfix));          \
              else                                                             \
              {                                                                \
                decl->array_flag = 1;                                          \
                decl->ext.array = postfix;                                     \
              }                                                                \
            }                                                                  \
          }                                                                    \
        } while (0)

#define MAKE_TYPEDEF(list, decl)                                               \
        do {                                                                   \
          Typedef *pTypedef = typedef_new(&(list->type), decl);                \
          CT_DEBUG(PARSER, ("making new typedef => %s (list @ %p)",            \
                            decl->identifier, list));                          \
          LL_push(list->typedefs, pTypedef);                                   \
          HT_store(PSTATE->pCPI->htTypedefs, decl->identifier, 0, 0, pTypedef);\
        } while (0)

#define UNDEF_VAL(x) do { x.iv = 0; x.flags = V_IS_UNDEF; } while (0)

#define UNARY_OP(result, op, val) \
          do { result.iv = op val.iv; result.flags = val.flags; } while (0)

#define BINARY_OP(result, val1, op, val2)             \
          do {                                        \
            result.iv    = val1.iv   op val2.iv;      \
            result.flags = val1.flags | val2.flags;   \
          } while (0)

#define LLC_OR(t1, t2)                                \
        (                                             \
          ((t1) & T_LONG) && ((t2) & T_LONG)          \
          ? (t1) | (t2) | T_LONGLONG : (t1) | (t2)    \
        )

#define F_LOCAL     0x00000001U
#define BEGIN_LOCAL (PSTATE->flags |= F_LOCAL)
#define END_LOCAL   (PSTATE->flags &= ~F_LOCAL)
#define IS_LOCAL    (PSTATE->flags & F_LOCAL)


/*===== TYPEDEFS =============================================================*/

struct _parserState {

  const CParseConfig *pCPC;

  CParseInfo         *pCPI;

  PragmaState        *pragma;

  struct CPP         *pp;
  struct lexer_state *pLexer;

  FileInfo           *pFI;

  u_32                flags;

};



/* Line 189 of yacc.c  */
#line 280 "ctlib/y_parser.c"

/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 1
#endif

/* Enabling the token table.  */
#ifndef YYTOKEN_TABLE
# define YYTOKEN_TABLE 0
#endif


/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     AUTO_TOK = 258,
     DOUBLE_TOK = 259,
     INT_TOK = 260,
     STRUCT_TOK = 261,
     BREAK_TOK = 262,
     ELSE_TOK = 263,
     LONG_TOK = 264,
     SWITCH_TOK = 265,
     CASE_TOK = 266,
     ENUM_TOK = 267,
     REGISTER_TOK = 268,
     TYPEDEF_TOK = 269,
     CHAR_TOK = 270,
     EXTERN_TOK = 271,
     RETURN_TOK = 272,
     UNION_TOK = 273,
     CONST_TOK = 274,
     FLOAT_TOK = 275,
     SHORT_TOK = 276,
     UNSIGNED_TOK = 277,
     CONTINUE_TOK = 278,
     FOR_TOK = 279,
     SIGNED_TOK = 280,
     VOID_TOK = 281,
     DEFAULT_TOK = 282,
     GOTO_TOK = 283,
     SIZEOF_TOK = 284,
     VOLATILE_TOK = 285,
     DO_TOK = 286,
     IF_TOK = 287,
     STATIC_TOK = 288,
     WHILE_TOK = 289,
     INLINE_TOK = 290,
     RESTRICT_TOK = 291,
     ASM_TOK = 292,
     SKIP_TOK = 293,
     PTR_OP = 294,
     INC_OP = 295,
     DEC_OP = 296,
     LEFT_OP = 297,
     RIGHT_OP = 298,
     LE_OP = 299,
     GE_OP = 300,
     EQ_OP = 301,
     NE_OP = 302,
     AND_OP = 303,
     OR_OP = 304,
     ELLIPSIS = 305,
     MUL_ASSIGN = 306,
     DIV_ASSIGN = 307,
     MOD_ASSIGN = 308,
     ADD_ASSIGN = 309,
     SUB_ASSIGN = 310,
     LEFT_ASSIGN = 311,
     RIGHT_ASSIGN = 312,
     AND_ASSIGN = 313,
     XOR_ASSIGN = 314,
     OR_ASSIGN = 315,
     STRING_LITERAL = 316,
     CONSTANT = 317,
     TYPE_NAME = 318,
     IDENTIFIER = 319
   };
#endif



#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
{

/* Line 214 of yacc.c  */
#line 244 "ctlib/parser.y"

  HashNode           identifier;
  Declarator        *pDecl;
  AbstractDeclarator absDecl;
  StructDeclaration *pStructDecl;
  TypedefList       *pTypedefList;
  LinkedList         list;
  Enumerator        *pEnum;
  Typedef           *pTypedef;
  TypeSpec           tspec;
  Value              value;
  struct {
    u_32             uval;
    ContextInfo      ctx;
  }                  context;
  u_32               uval;
  char               oper;



/* Line 214 of yacc.c  */
#line 401 "ctlib/y_parser.c"
} YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif


/* Copy the second part of user declarations.  */

/* Line 264 of yacc.c  */
#line 263 "ctlib/parser.y"


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
	CONSTANT,	/* CHAR, */		/* constant 'xxx' */
	'/',		/* SLASH, */		/*	/	*/
	DIV_ASSIGN,	/* ASSLASH, */		/*	/=	*/
	'-',		/* MINUS, */		/*	-	*/
	DEC_OP,		/* MMINUS, */		/*	--	*/
	SUB_ASSIGN,	/* ASMINUS, */		/*	-=	*/
	PTR_OP,		/* ARROW, */		/*	->	*/
	'+',		/* PLUS, */		/*	+	*/
	INC_OP,		/* PPLUS, */		/*	++	*/
	ADD_ASSIGN,	/* ASPLUS, */		/*	+=	*/
	'<',		/* LT, */		/*	<	*/
	LE_OP,		/* LEQ, */		/*	<=	*/
	LEFT_OP,	/* LSH, */		/*	<<	*/
	LEFT_ASSIGN,	/* ASLSH, */		/*	<<=	*/
	'>',		/* GT, */		/*	>	*/
	GE_OP,		/* GEQ, */		/*	>=	*/
	RIGHT_OP,	/* RSH, */		/*	>>	*/
	RIGHT_ASSIGN,	/* ASRSH, */		/*	>>=	*/
	'=',		/* ASGN, */		/*	=	*/
	EQ_OP,		/* SAME, */		/*	==	*/
#ifdef CAST_OP
	0,		/* CAST, */		/*	=>	*/
#endif
	'~',		/* NOT, */		/*	~	*/
	NE_OP,		/* NEQ, */		/*	!=	*/
	'&',		/* AND, */		/*	&	*/
	AND_OP,		/* LAND, */		/*	&&	*/
	AND_ASSIGN,	/* ASAND, */		/*	&=	*/
	'|',		/* OR, */		/*	|	*/
	OR_OP,		/* LOR, */		/*	||	*/
	OR_ASSIGN,	/* ASOR, */		/*	|=	*/
	'%',		/* PCT, */		/*	%	*/
	MOD_ASSIGN,	/* ASPCT, */		/*	%=	*/
	'*',		/* STAR, */		/*	*	*/
	MUL_ASSIGN,	/* ASSTAR, */		/*	*=	*/
	'^',		/* CIRC, */		/*	^	*/
	XOR_ASSIGN,	/* ASCIRC, */		/*	^=	*/
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
	ELLIPSIS,	/* MDOTS, */		/*	...	*/
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


/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static inline int   c_lex(YYSTYPE *plval, ParserState *pState);

static inline int   get_char_value(const char *s);
static inline int   string_size(const char *s);
static inline int   check_type(YYSTYPE *plval, ParserState *pState, const char *s);
static        void  parser_error(ParserState *pState, const char *msg);



/* Line 264 of yacc.c  */
#line 517 "ctlib/y_parser.c"

#ifdef short
# undef short
#endif

#ifdef YYTYPE_UINT8
typedef YYTYPE_UINT8 yytype_uint8;
#else
typedef unsigned char yytype_uint8;
#endif

#ifdef YYTYPE_INT8
typedef YYTYPE_INT8 yytype_int8;
#elif (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
typedef signed char yytype_int8;
#else
typedef short int yytype_int8;
#endif

#ifdef YYTYPE_UINT16
typedef YYTYPE_UINT16 yytype_uint16;
#else
typedef unsigned short int yytype_uint16;
#endif

#ifdef YYTYPE_INT16
typedef YYTYPE_INT16 yytype_int16;
#else
typedef short int yytype_int16;
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif ! defined YYSIZE_T && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned int
# endif
#endif

#define YYSIZE_MAXIMUM ((YYSIZE_T) -1)

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(msgid) dgettext ("bison-runtime", msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(msgid) msgid
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(e) ((void) (e))
#else
# define YYUSE(e) /* empty */
#endif

/* Identity function, used to suppress warnings about constant conditions.  */
#ifndef lint
# define YYID(n) (n)
#else
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static int
YYID (int yyi)
#else
static int
YYID (yyi)
    int yyi;
#endif
{
  return yyi;
}
#endif

#if ! defined yyoverflow || YYERROR_VERBOSE

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#     ifndef _STDLIB_H
#      define _STDLIB_H 1
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's `empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (YYID (0))
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined _STDLIB_H \
       && ! ((defined YYMALLOC || defined malloc) \
	     && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef _STDLIB_H
#    define _STDLIB_H 1
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* ! defined yyoverflow || YYERROR_VERBOSE */


#if (! defined yyoverflow \
     && (! defined __cplusplus \
	 || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yytype_int16 yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (yytype_int16) + sizeof (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

/* Copy COUNT objects from FROM to TO.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(To, From, Count) \
      __builtin_memcpy (To, From, (Count) * sizeof (*(From)))
#  else
#   define YYCOPY(To, From, Count)		\
      do					\
	{					\
	  YYSIZE_T yyi;				\
	  for (yyi = 0; yyi < (Count); yyi++)	\
	    (To)[yyi] = (From)[yyi];		\
	}					\
      while (YYID (0))
#  endif
# endif

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)				\
    do									\
      {									\
	YYSIZE_T yynewbytes;						\
	YYCOPY (&yyptr->Stack_alloc, Stack, yysize);			\
	Stack = &yyptr->Stack_alloc;					\
	yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAXIMUM; \
	yyptr += yynewbytes / sizeof (*yyptr);				\
      }									\
    while (YYID (0))

#endif

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  125
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   2186

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  89
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  133
/* YYNRULES -- Number of rules.  */
#define YYNRULES  367
/* YYNRULES -- Number of states.  */
#define YYNSTATES  618

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   319

#define YYTRANSLATE(YYX)						\
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const yytype_uint8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    80,     2,     2,     2,    82,    75,     2,
      65,    66,    76,    77,    69,    78,    72,    81,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,    68,    67,
      83,    88,    84,    87,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,    70,     2,    71,    85,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    73,    86,    74,    79,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const yytype_uint16 yyprhs[] =
{
       0,     0,     3,     5,     8,    13,    14,    16,    22,    29,
      38,    49,    62,    63,    65,    67,    71,    76,    84,    86,
      90,    92,    94,    96,   100,   102,   107,   111,   116,   117,
     122,   123,   128,   131,   134,   142,   144,   146,   148,   152,
     154,   157,   160,   163,   166,   171,   173,   175,   177,   179,
     181,   183,   185,   190,   192,   196,   200,   204,   206,   210,
     214,   216,   220,   224,   226,   230,   234,   238,   242,   244,
     248,   252,   254,   258,   260,   264,   266,   270,   272,   276,
     278,   282,   284,   290,   292,   296,   298,   300,   302,   304,
     306,   308,   310,   312,   314,   316,   318,   319,   321,   323,
     327,   329,   330,   332,   335,   338,   341,   344,   349,   354,
     360,   365,   370,   376,   378,   380,   382,   384,   386,   388,
     390,   393,   396,   398,   401,   402,   404,   406,   408,   410,
     412,   414,   417,   420,   423,   426,   428,   431,   434,   437,
     440,   443,   446,   448,   450,   452,   455,   458,   460,   463,
     466,   468,   470,   473,   476,   479,   481,   484,   487,   489,
     491,   493,   495,   497,   499,   501,   503,   505,   507,   509,
     511,   513,   515,   517,   519,   521,   526,   532,   535,   537,
     539,   541,   542,   544,   546,   549,   552,   555,   557,   560,
     564,   567,   569,   570,   572,   575,   581,   588,   591,   593,
     595,   599,   601,   605,   607,   611,   613,   617,   619,   622,
     625,   628,   630,   633,   636,   638,   641,   644,   647,   649,
     652,   655,   657,   661,   663,   665,   667,   670,   672,   675,
     676,   679,   682,   687,   689,   692,   697,   698,   701,   703,
     706,   710,   713,   714,   716,   718,   720,   722,   724,   726,
     728,   730,   734,   739,   743,   746,   750,   754,   759,   761,
     764,   766,   769,   772,   778,   786,   792,   798,   806,   816,
     820,   823,   826,   830,   831,   833,   835,   838,   840,   842,
     844,   845,   849,   850,   855,   856,   861,   862,   867,   868,
     873,   874,   878,   879,   884,   885,   890,   891,   896,   897,
     902,   903,   908,   909,   915,   916,   922,   923,   929,   930,
     936,   938,   940,   942,   944,   946,   949,   951,   953,   956,
     960,   964,   969,   971,   976,   982,   985,   989,   993,   998,
    1003,  1005,  1009,  1011,  1013,  1015,  1018,  1022,  1025,  1029,
    1034,  1036,  1040,  1042,  1045,  1049,  1054,  1058,  1063,  1065,
    1067,  1069,  1071,  1074,  1078,  1083,  1089,  1095,  1100,  1105,
    1110,  1112,  1115,  1118,  1122,  1126,  1130,  1134
};

/* YYRHS -- A `-1'-separated list of the rules' RHS.  */
static const yytype_int16 yyrhs[] =
{
     184,     0,    -1,    61,    -1,    90,    61,    -1,    37,    65,
      90,    66,    -1,    -1,    91,    -1,    37,    65,   122,    66,
      67,    -1,    37,   132,    65,   122,    66,    67,    -1,    37,
     132,    65,   122,    68,    95,    66,    67,    -1,    37,   132,
      65,   122,    68,    95,    68,    95,    66,    67,    -1,    37,
     132,    65,   122,    68,    95,    68,    95,    68,    98,    66,
      67,    -1,    -1,    96,    -1,    97,    -1,    96,    69,    97,
      -1,    61,    65,   122,    66,    -1,    70,    64,    71,    61,
      65,   122,    66,    -1,    90,    -1,    98,    69,    90,    -1,
      64,    -1,    62,    -1,    90,    -1,    65,   122,    66,    -1,
      99,    -1,   100,    70,   122,    71,    -1,   100,    65,    66,
      -1,   100,    65,   104,    66,    -1,    -1,   100,   101,    72,
     103,    -1,    -1,   100,   102,    39,   103,    -1,   100,    40,
      -1,   100,    41,    -1,    65,   167,    66,    73,   170,   174,
      74,    -1,    64,    -1,    63,    -1,   119,    -1,   104,    69,
     119,    -1,   100,    -1,    40,   105,    -1,    41,   105,    -1,
     106,   107,    -1,    29,   105,    -1,    29,    65,   167,    66,
      -1,    75,    -1,    76,    -1,    77,    -1,    78,    -1,    79,
      -1,    80,    -1,   105,    -1,    65,   167,    66,   107,    -1,
     107,    -1,   108,    76,   107,    -1,   108,    81,   107,    -1,
     108,    82,   107,    -1,   108,    -1,   109,    77,   108,    -1,
     109,    78,   108,    -1,   109,    -1,   110,    42,   109,    -1,
     110,    43,   109,    -1,   110,    -1,   111,    83,   110,    -1,
     111,    84,   110,    -1,   111,    44,   110,    -1,   111,    45,
     110,    -1,   111,    -1,   112,    46,   111,    -1,   112,    47,
     111,    -1,   112,    -1,   113,    75,   112,    -1,   113,    -1,
     114,    85,   113,    -1,   114,    -1,   115,    86,   114,    -1,
     115,    -1,   116,    48,   115,    -1,   116,    -1,   117,    49,
     116,    -1,   117,    -1,   117,    87,   122,    68,   118,    -1,
     118,    -1,   105,   120,   119,    -1,    88,    -1,    51,    -1,
      52,    -1,    53,    -1,    54,    -1,    55,    -1,    56,    -1,
      57,    -1,    58,    -1,    59,    -1,    60,    -1,    -1,   119,
      -1,   119,    -1,   122,    69,   119,    -1,   118,    -1,    -1,
     122,    -1,   137,    67,    -1,   138,    67,    -1,   127,    67,
      -1,   126,    67,    -1,   130,   211,    92,   168,    -1,   131,
     211,    92,   168,    -1,   126,    69,   211,    92,   168,    -1,
     128,   203,    92,   168,    -1,   129,   203,    92,   168,    -1,
     127,    69,   203,    92,   168,    -1,   135,    -1,   137,    -1,
     142,    -1,   136,    -1,   138,    -1,   143,    -1,   144,    -1,
     131,   144,    -1,   130,   133,    -1,   134,    -1,   131,   134,
      -1,    -1,   131,    -1,   144,    -1,   134,    -1,    19,    -1,
      36,    -1,    30,    -1,   130,   145,    -1,   136,   144,    -1,
     135,   133,    -1,   135,   145,    -1,   145,    -1,   131,   145,
      -1,   136,   134,    -1,   136,   145,    -1,   130,   146,    -1,
     138,   144,    -1,   137,   133,    -1,   140,    -1,   139,    -1,
     158,    -1,   131,   158,    -1,   139,   134,    -1,   147,    -1,
     131,   147,    -1,   140,   134,    -1,   140,    -1,   143,    -1,
     143,   144,    -1,   130,    63,    -1,   142,   133,    -1,    63,
      -1,   131,    63,    -1,   143,   134,    -1,    14,    -1,    16,
      -1,    33,    -1,     3,    -1,    13,    -1,    35,    -1,     5,
      -1,    15,    -1,    21,    -1,     9,    -1,    20,    -1,     4,
      -1,    25,    -1,    22,    -1,    26,    -1,   147,    -1,   158,
      -1,   148,    73,   150,    74,    -1,   148,   166,    73,   150,
      74,    -1,   148,   166,    -1,   149,    -1,     6,    -1,    18,
      -1,    -1,   151,    -1,   152,    -1,   151,   152,    -1,   154,
      67,    -1,   153,    67,    -1,   141,    -1,   129,   155,    -1,
     154,    69,   155,    -1,   203,   156,    -1,   157,    -1,    -1,
     157,    -1,    68,   123,    -1,   159,    73,   160,   174,    74,
      -1,   159,   166,    73,   160,   174,    74,    -1,   159,   166,
      -1,    12,    -1,   161,    -1,   160,    69,   161,    -1,   166,
      -1,   166,    88,   123,    -1,   163,    -1,   163,    69,    50,
      -1,   164,    -1,   163,    69,   164,    -1,   128,    -1,   128,
     217,    -1,   128,   211,    -1,   128,   205,    -1,   130,    -1,
     130,   217,    -1,   130,   211,    -1,   129,    -1,   129,   217,
      -1,   129,   211,    -1,   129,   205,    -1,   131,    -1,   131,
     217,    -1,   131,   211,    -1,    64,    -1,   165,    69,    64,
      -1,    64,    -1,    63,    -1,   129,    -1,   129,   217,    -1,
     131,    -1,   131,   217,    -1,    -1,    88,   169,    -1,    73,
      74,    -1,    73,   170,   174,    74,    -1,   119,    -1,   171,
     169,    -1,   170,    69,   171,   169,    -1,    -1,   172,    88,
      -1,   173,    -1,   172,   173,    -1,    70,   123,    71,    -1,
      72,   166,    -1,    -1,    69,    -1,   176,    -1,   177,    -1,
     180,    -1,   181,    -1,   182,    -1,   183,    -1,    94,    -1,
     166,    68,   175,    -1,    11,   123,    68,   175,    -1,    27,
      68,   175,    -1,    73,    74,    -1,    73,   178,    74,    -1,
      73,   179,    74,    -1,    73,   178,   179,    74,    -1,   125,
      -1,   178,   125,    -1,   175,    -1,   179,   175,    -1,   124,
      67,    -1,    32,    65,   122,    66,   175,    -1,    32,    65,
     122,    66,   175,     8,   175,    -1,    10,    65,   122,    66,
     175,    -1,    34,    65,   122,    66,   175,    -1,    31,   175,
      34,    65,   122,    66,    67,    -1,    24,    65,   124,    67,
     124,    67,   124,    66,   175,    -1,    28,   166,    67,    -1,
      23,    67,    -1,     7,    67,    -1,    17,   124,    67,    -1,
      -1,   185,    -1,   186,    -1,   185,   186,    -1,   187,    -1,
     125,    -1,    93,    -1,    -1,   211,   188,   177,    -1,    -1,
     128,   211,   189,   177,    -1,    -1,   129,   211,   190,   177,
      -1,    -1,   130,   211,   191,   177,    -1,    -1,   131,   211,
     192,   177,    -1,    -1,   215,   193,   177,    -1,    -1,   128,
     215,   194,   177,    -1,    -1,   129,   215,   195,   177,    -1,
      -1,   130,   215,   196,   177,    -1,    -1,   131,   215,   197,
     177,    -1,    -1,   215,   178,   198,   177,    -1,    -1,   128,
     215,   178,   199,   177,    -1,    -1,   129,   215,   178,   200,
     177,    -1,    -1,   130,   215,   178,   201,   177,    -1,    -1,
     131,   215,   178,   202,   177,    -1,   211,    -1,   204,    -1,
     208,    -1,   205,    -1,    63,    -1,    63,   218,    -1,   206,
      -1,   207,    -1,    76,   205,    -1,    76,   131,   205,    -1,
      65,   206,    66,    -1,    65,   206,    66,   218,    -1,   209,
      -1,    76,    65,   210,    66,    -1,    76,   131,    65,   210,
      66,    -1,    76,   208,    -1,    76,   131,   208,    -1,    65,
     208,    66,    -1,    65,   210,   218,    66,    -1,    65,   208,
      66,   218,    -1,    63,    -1,    65,   210,    66,    -1,   212,
      -1,   214,    -1,   213,    -1,    76,   211,    -1,    76,   131,
     211,    -1,   214,   218,    -1,    65,   212,    66,    -1,    65,
     212,    66,   218,    -1,    64,    -1,    65,   214,    66,    -1,
     216,    -1,    76,   215,    -1,    76,   131,   215,    -1,   214,
      65,   165,    66,    -1,    65,   215,    66,    -1,    65,   215,
      66,   218,    -1,   220,    -1,   221,    -1,   218,    -1,   219,
      -1,    65,    66,    -1,    65,   162,    66,    -1,    70,   132,
     121,    71,    -1,    70,    33,   132,   119,    71,    -1,    70,
     131,    33,   119,    71,    -1,    70,   132,    76,    71,    -1,
     219,    70,   119,    71,    -1,   219,    70,    76,    71,    -1,
      76,    -1,    76,   131,    -1,    76,   217,    -1,    76,   131,
     217,    -1,    65,   220,    66,    -1,    65,   221,    66,    -1,
      65,   218,    66,    -1,    65,   220,    66,   218,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const yytype_uint16 yyrline[] =
{
       0,   619,   619,   620,   628,   631,   633,   637,   641,   642,
     644,   647,   653,   655,   659,   660,   664,   665,   673,   674,
     679,   694,   695,   696,   706,   707,   708,   709,   710,   710,
     711,   711,   712,   713,   714,   718,   719,   723,   724,   728,
     729,   730,   731,   749,   750,   754,   755,   756,   757,   758,
     759,   763,   764,   768,   769,   771,   778,   788,   789,   791,
     796,   797,   799,   804,   805,   807,   809,   811,   816,   817,
     819,   824,   825,   830,   831,   836,   837,   842,   843,   848,
     849,   854,   855,   860,   861,   865,   866,   867,   868,   869,
     870,   871,   872,   873,   874,   875,   879,   880,   883,   884,
     888,   892,   894,   932,   933,   934,   935,   942,   966,   972,
     983,  1005,  1011,  1023,  1028,  1029,  1034,  1039,  1040,  1046,
    1047,  1048,  1052,  1053,  1056,  1058,  1062,  1063,  1067,  1068,
    1069,  1073,  1074,  1075,  1076,  1080,  1081,  1082,  1083,  1087,
    1092,  1097,  1105,  1106,  1110,  1111,  1112,  1116,  1117,  1118,
    1122,  1123,  1126,  1131,  1136,  1144,  1145,  1146,  1150,  1151,
    1152,  1153,  1154,  1155,  1159,  1160,  1161,  1162,  1163,  1164,
    1165,  1166,  1167,  1171,  1172,  1176,  1193,  1229,  1258,  1267,
    1268,  1272,  1273,  1277,  1288,  1302,  1303,  1307,  1311,  1324,
    1338,  1365,  1385,  1386,  1390,  1394,  1411,  1447,  1478,  1486,
    1501,  1520,  1533,  1549,  1550,  1554,  1555,  1559,  1560,  1561,
    1562,  1563,  1564,  1565,  1566,  1567,  1568,  1569,  1570,  1571,
    1572,  1580,  1581,  1585,  1586,  1593,  1606,  1627,  1635,  1646,
    1648,  1652,  1653,  1654,  1658,  1659,  1662,  1664,  1668,  1669,
    1673,  1674,  1677,  1679,  1684,  1685,  1686,  1687,  1688,  1689,
    1690,  1694,  1695,  1696,  1700,  1701,  1702,  1703,  1707,  1708,
    1712,  1713,  1717,  1721,  1722,  1723,  1727,  1728,  1729,  1733,
    1734,  1735,  1736,  1742,  1744,  1748,  1749,  1753,  1754,  1755,
    1759,  1759,  1761,  1761,  1763,  1763,  1765,  1765,  1767,  1767,
    1770,  1770,  1771,  1771,  1772,  1772,  1773,  1773,  1774,  1774,
    1776,  1776,  1777,  1777,  1778,  1778,  1779,  1779,  1780,  1780,
    1784,  1785,  1789,  1790,  1794,  1798,  1812,  1819,  1820,  1826,
    1835,  1836,  1847,  1848,  1854,  1860,  1866,  1875,  1876,  1881,
    1889,  1893,  1897,  1898,  1902,  1903,  1909,  1918,  1923,  1924,
    1932,  1944,  1948,  1949,  1950,  1954,  1959,  1960,  1968,  1969,
    1970,  1988,  1989,  1990,  1994,  2005,  2016,  2027,  2028,  2039,
    2053,  2058,  2063,  2068,  2076,  2077,  2078,  2093
};
#endif

#if YYDEBUG || YYERROR_VERBOSE || YYTOKEN_TABLE
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "AUTO_TOK", "DOUBLE_TOK", "INT_TOK",
  "STRUCT_TOK", "BREAK_TOK", "ELSE_TOK", "LONG_TOK", "SWITCH_TOK",
  "CASE_TOK", "ENUM_TOK", "REGISTER_TOK", "TYPEDEF_TOK", "CHAR_TOK",
  "EXTERN_TOK", "RETURN_TOK", "UNION_TOK", "CONST_TOK", "FLOAT_TOK",
  "SHORT_TOK", "UNSIGNED_TOK", "CONTINUE_TOK", "FOR_TOK", "SIGNED_TOK",
  "VOID_TOK", "DEFAULT_TOK", "GOTO_TOK", "SIZEOF_TOK", "VOLATILE_TOK",
  "DO_TOK", "IF_TOK", "STATIC_TOK", "WHILE_TOK", "INLINE_TOK",
  "RESTRICT_TOK", "ASM_TOK", "SKIP_TOK", "PTR_OP", "INC_OP", "DEC_OP",
  "LEFT_OP", "RIGHT_OP", "LE_OP", "GE_OP", "EQ_OP", "NE_OP", "AND_OP",
  "OR_OP", "ELLIPSIS", "MUL_ASSIGN", "DIV_ASSIGN", "MOD_ASSIGN",
  "ADD_ASSIGN", "SUB_ASSIGN", "LEFT_ASSIGN", "RIGHT_ASSIGN", "AND_ASSIGN",
  "XOR_ASSIGN", "OR_ASSIGN", "STRING_LITERAL", "CONSTANT", "TYPE_NAME",
  "IDENTIFIER", "'('", "')'", "';'", "':'", "','", "'['", "']'", "'.'",
  "'{'", "'}'", "'&'", "'*'", "'+'", "'-'", "'~'", "'!'", "'/'", "'%'",
  "'<'", "'>'", "'^'", "'|'", "'?'", "'='", "$accept",
  "string_literal_list", "asm_string", "asm_string_opt", "asm_expr",
  "asm_statement", "asm_operands_opt", "asm_operands", "asm_operand",
  "asm_clobbers", "primary_expression", "postfix_expression", "$@1", "$@2",
  "member_name", "argument_expression_list", "unary_expression",
  "unary_operator", "cast_expression", "multiplicative_expression",
  "additive_expression", "shift_expression", "relational_expression",
  "equality_expression", "AND_expression", "exclusive_OR_expression",
  "inclusive_OR_expression", "logical_AND_expression",
  "logical_OR_expression", "conditional_expression",
  "assignment_expression", "assignment_operator",
  "assignment_expression_opt", "comma_expression", "constant_expression",
  "comma_expression_opt", "declaration", "default_declaring_list",
  "declaring_list", "declaration_specifier", "type_specifier",
  "declaration_qualifier_list", "type_qualifier_list",
  "type_qualifier_list_opt", "declaration_qualifier", "type_qualifier",
  "basic_declaration_specifier", "basic_type_specifier",
  "sue_declaration_specifier", "sue_type_specifier", "enum_type_specifier",
  "su_type_specifier", "sut_type_specifier",
  "typedef_declaration_specifier", "typedef_type_specifier",
  "storage_class", "basic_type_name", "elaborated_type_name",
  "aggregate_name", "aggregate_key_context", "aggregate_key",
  "member_declaration_list_opt", "member_declaration_list",
  "member_declaration", "unnamed_su_declaration", "member_declaring_list",
  "member_declarator", "bit_field_size_opt", "bit_field_size", "enum_name",
  "enum_key_context", "enumerator_list", "enumerator",
  "parameter_type_list", "parameter_list", "parameter_declaration",
  "identifier_list", "identifier_or_typedef_name", "type_name",
  "initializer_opt", "initializer", "initializer_list", "designation_opt",
  "designator_list", "designator", "comma_opt", "statement",
  "labeled_statement", "compound_statement", "declaration_list",
  "statement_list", "expression_statement", "selection_statement",
  "iteration_statement", "jump_statement", "source_file",
  "translation_unit", "external_definition", "function_definition", "$@3",
  "$@4", "$@5", "$@6", "$@7", "$@8", "$@9", "$@10", "$@11", "$@12", "$@13",
  "$@14", "$@15", "$@16", "$@17", "declarator", "typedef_declarator",
  "parameter_typedef_declarator", "clean_typedef_declarator",
  "clean_postfix_typedef_declarator", "paren_typedef_declarator",
  "paren_postfix_typedef_declarator", "simple_paren_typedef_declarator",
  "identifier_declarator", "unary_identifier_declarator",
  "postfix_identifier_declarator", "paren_identifier_declarator",
  "old_function_declarator", "postfix_old_function_declarator",
  "abstract_declarator", "postfixing_abstract_declarator",
  "array_abstract_declarator", "unary_abstract_declarator",
  "postfix_abstract_declarator", 0
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[YYLEX-NUM] -- Internal token number corresponding to
   token YYLEX-NUM.  */
static const yytype_uint16 yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
     275,   276,   277,   278,   279,   280,   281,   282,   283,   284,
     285,   286,   287,   288,   289,   290,   291,   292,   293,   294,
     295,   296,   297,   298,   299,   300,   301,   302,   303,   304,
     305,   306,   307,   308,   309,   310,   311,   312,   313,   314,
     315,   316,   317,   318,   319,    40,    41,    59,    58,    44,
      91,    93,    46,   123,   125,    38,    42,    43,    45,   126,
      33,    47,    37,    60,    62,    94,   124,    63,    61
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] =
{
       0,    89,    90,    90,    91,    92,    92,    93,    94,    94,
      94,    94,    95,    95,    96,    96,    97,    97,    98,    98,
      99,    99,    99,    99,   100,   100,   100,   100,   101,   100,
     102,   100,   100,   100,   100,   103,   103,   104,   104,   105,
     105,   105,   105,   105,   105,   106,   106,   106,   106,   106,
     106,   107,   107,   108,   108,   108,   108,   109,   109,   109,
     110,   110,   110,   111,   111,   111,   111,   111,   112,   112,
     112,   113,   113,   114,   114,   115,   115,   116,   116,   117,
     117,   118,   118,   119,   119,   120,   120,   120,   120,   120,
     120,   120,   120,   120,   120,   120,   121,   121,   122,   122,
     123,   124,   124,   125,   125,   125,   125,   126,   126,   126,
     127,   127,   127,   128,   128,   128,   129,   129,   129,   130,
     130,   130,   131,   131,   132,   132,   133,   133,   134,   134,
     134,   135,   135,   135,   135,   136,   136,   136,   136,   137,
     137,   137,   138,   138,   139,   139,   139,   140,   140,   140,
     141,   141,   142,   142,   142,   143,   143,   143,   144,   144,
     144,   144,   144,   144,   145,   145,   145,   145,   145,   145,
     145,   145,   145,   146,   146,   147,   147,   147,   148,   149,
     149,   150,   150,   151,   151,   152,   152,   153,   154,   154,
     155,   155,   156,   156,   157,   158,   158,   158,   159,   160,
     160,   161,   161,   162,   162,   163,   163,   164,   164,   164,
     164,   164,   164,   164,   164,   164,   164,   164,   164,   164,
     164,   165,   165,   166,   166,   167,   167,   167,   167,   168,
     168,   169,   169,   169,   170,   170,   171,   171,   172,   172,
     173,   173,   174,   174,   175,   175,   175,   175,   175,   175,
     175,   176,   176,   176,   177,   177,   177,   177,   178,   178,
     179,   179,   180,   181,   181,   181,   182,   182,   182,   183,
     183,   183,   183,   184,   184,   185,   185,   186,   186,   186,
     188,   187,   189,   187,   190,   187,   191,   187,   192,   187,
     193,   187,   194,   187,   195,   187,   196,   187,   197,   187,
     198,   187,   199,   187,   200,   187,   201,   187,   202,   187,
     203,   203,   204,   204,   205,   205,   205,   206,   206,   206,
     207,   207,   208,   208,   208,   208,   208,   209,   209,   209,
     210,   210,   211,   211,   212,   212,   212,   213,   213,   213,
     214,   214,   215,   215,   215,   216,   216,   216,   217,   217,
     217,   218,   218,   218,   219,   219,   219,   219,   219,   219,
     220,   220,   220,   220,   221,   221,   221,   221
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     1,     2,     4,     0,     1,     5,     6,     8,
      10,    12,     0,     1,     1,     3,     4,     7,     1,     3,
       1,     1,     1,     3,     1,     4,     3,     4,     0,     4,
       0,     4,     2,     2,     7,     1,     1,     1,     3,     1,
       2,     2,     2,     2,     4,     1,     1,     1,     1,     1,
       1,     1,     4,     1,     3,     3,     3,     1,     3,     3,
       1,     3,     3,     1,     3,     3,     3,     3,     1,     3,
       3,     1,     3,     1,     3,     1,     3,     1,     3,     1,
       3,     1,     5,     1,     3,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     0,     1,     1,     3,
       1,     0,     1,     2,     2,     2,     2,     4,     4,     5,
       4,     4,     5,     1,     1,     1,     1,     1,     1,     1,
       2,     2,     1,     2,     0,     1,     1,     1,     1,     1,
       1,     2,     2,     2,     2,     1,     2,     2,     2,     2,
       2,     2,     1,     1,     1,     2,     2,     1,     2,     2,
       1,     1,     2,     2,     2,     1,     2,     2,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     4,     5,     2,     1,     1,
       1,     0,     1,     1,     2,     2,     2,     1,     2,     3,
       2,     1,     0,     1,     2,     5,     6,     2,     1,     1,
       3,     1,     3,     1,     3,     1,     3,     1,     2,     2,
       2,     1,     2,     2,     1,     2,     2,     2,     1,     2,
       2,     1,     3,     1,     1,     1,     2,     1,     2,     0,
       2,     2,     4,     1,     2,     4,     0,     2,     1,     2,
       3,     2,     0,     1,     1,     1,     1,     1,     1,     1,
       1,     3,     4,     3,     2,     3,     3,     4,     1,     2,
       1,     2,     2,     5,     7,     5,     5,     7,     9,     3,
       2,     2,     3,     0,     1,     1,     2,     1,     1,     1,
       0,     3,     0,     4,     0,     4,     0,     4,     0,     4,
       0,     3,     0,     4,     0,     4,     0,     4,     0,     4,
       0,     4,     0,     5,     0,     5,     0,     5,     0,     5,
       1,     1,     1,     1,     1,     2,     1,     1,     2,     3,
       3,     4,     1,     4,     5,     2,     3,     3,     4,     4,
       1,     3,     1,     1,     1,     2,     3,     2,     3,     4,
       1,     3,     1,     2,     3,     4,     3,     4,     1,     1,
       1,     1,     2,     3,     4,     5,     5,     4,     4,     4,
       1,     2,     2,     3,     3,     3,     3,     4
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint16 yydefact[] =
{
     273,   161,   169,   164,   179,   167,   198,   162,   158,   165,
     159,   180,   128,   168,   166,   171,   170,   172,   130,   160,
     163,   129,     0,   155,   340,     0,     0,   279,   278,     0,
       0,     0,     0,     0,     0,   122,   113,   116,   114,   117,
     143,   142,   115,   118,   119,   135,   147,     0,   178,   144,
       0,     0,   274,   275,   277,   280,   332,   334,   333,   290,
     342,     0,     0,     0,     0,     0,   335,   343,   106,     0,
     105,     0,   314,     0,     0,     5,   311,   313,   316,   317,
     312,   322,   310,   292,     5,   310,   294,   153,   121,   127,
     126,   131,   139,   173,   174,     5,   296,   156,   123,   120,
     136,   148,   145,     5,   298,   133,   134,   137,   132,   138,
     103,   141,   104,   140,   146,   149,   154,   157,   152,   224,
     223,   181,   177,     0,   197,     1,   276,     0,     0,   124,
     337,   351,   258,     0,     0,     0,     0,   300,     0,     0,
       0,     0,     2,    21,    20,     0,    45,    46,    47,    48,
      49,    50,    22,    24,    39,    51,     0,    53,    57,    60,
      63,    68,    71,    73,    75,    77,    79,    81,    83,    98,
       0,   338,   341,   346,   336,   344,     0,     0,     5,   333,
       0,     0,     5,   310,     0,   315,   330,     0,     0,     0,
       0,     0,     0,   318,   325,     0,     6,   229,     0,   302,
       0,   229,     0,   304,     0,   229,     0,   306,     0,   229,
       0,   308,     0,     0,     0,   116,   117,   142,   187,   118,
       0,   182,   183,     0,     0,   181,   242,   199,   201,     0,
     101,   281,   221,   352,   207,   214,   211,   218,   114,   117,
       0,   203,   205,     0,   124,   125,    96,     0,     5,     5,
     259,     0,   291,     0,    43,     0,    40,    41,     0,   225,
     227,   118,     0,     3,    32,    33,     0,     0,     0,     0,
      86,    87,    88,    89,    90,    91,    92,    93,    94,    95,
      85,     0,    51,    42,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,   339,   347,     0,     0,   229,
       0,     0,     0,   229,     0,   320,   327,     0,     0,     0,
     319,   326,     0,     0,   110,   283,     0,   293,   111,   285,
       0,   295,   107,   287,     0,   297,   108,   289,     0,   299,
       0,   188,   191,   192,   175,   184,   186,   185,     0,     0,
     243,     0,     0,   242,     0,     0,     0,   101,     0,     0,
       0,     0,   101,     0,     0,   124,   155,    20,   254,   250,
     102,     0,     0,   260,   244,   245,   101,   101,   246,   247,
     248,   249,     0,   360,   210,   209,   208,   350,   348,   349,
     217,   216,   215,     0,   360,   213,   212,   220,   219,   353,
       0,   345,     0,   125,     0,     0,    46,    97,     0,    46,
       0,   301,     0,     0,    23,     0,   360,   226,   228,     0,
      26,     0,    37,     0,     0,     0,    84,    54,    55,    56,
      58,    59,    61,    62,    66,    67,    64,    65,    69,    70,
      72,    74,    76,    78,    80,     0,     7,    99,   109,     0,
     112,   331,   321,   329,   328,   323,     0,     0,   236,   233,
     230,   303,   305,   307,   309,   100,   194,   190,   193,   189,
     176,   200,   195,   202,     0,   271,     0,     0,     0,   270,
     101,   101,     0,     0,     0,     0,     0,   262,   101,   255,
     101,   256,   261,     0,     0,     0,   361,   362,   361,   204,
     206,   222,     0,     0,   357,   354,   359,   358,    44,     0,
     361,   236,    52,    27,     0,    25,    36,    35,    29,    31,
       0,   324,     4,     0,     0,   231,   242,     0,     0,   238,
     196,     0,   101,   272,     0,   253,   269,     0,     0,     0,
       0,   251,   257,   366,   364,   365,   363,   355,   356,   242,
      38,    82,     0,   241,   236,     0,   234,   237,   239,   101,
     252,   101,     0,   101,   101,     0,   367,     0,   240,     0,
     232,   265,     0,     0,   263,   266,     0,    12,    34,   235,
     101,     0,   101,     8,     0,     0,     0,    13,    14,     0,
     267,   264,     0,     0,     0,    12,     0,   101,     0,     0,
       9,     0,    15,   268,    16,     0,     0,     0,     0,    10,
      18,     0,     0,     0,     0,    17,    11,    19
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
      -1,   152,   196,   205,    27,   369,   586,   587,   588,   611,
     153,   154,   268,   269,   518,   421,   155,   156,   157,   158,
     159,   160,   161,   162,   163,   164,   165,   166,   167,   168,
     169,   281,   408,   370,   466,   371,   132,    29,    30,   133,
     134,   135,   136,   246,    88,    35,    36,    37,    38,    39,
      40,    41,   218,    42,    43,    44,    45,    92,    46,    47,
      48,   220,   221,   222,   223,   224,   341,   467,   342,    49,
      50,   226,   227,   240,   241,   242,   243,   372,   262,   324,
     460,   526,   527,   528,   529,   351,   373,   374,   375,   137,
     377,   378,   379,   380,   381,    51,    52,    53,    54,   127,
     198,   202,   206,   210,   138,   200,   204,   208,   212,   251,
     326,   330,   334,   338,    75,    76,    77,    78,    79,   189,
      81,   190,    66,    56,    57,   179,    64,    60,   497,   387,
     131,   388,   389
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -507
static const yytype_int16 yypact[] =
{
    1279,  -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,
    -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,
    -507,  -507,   -56,  -507,  -507,    42,   331,  -507,  -507,   134,
     144,   431,   431,  1487,  1523,  -507,  2106,  2106,   970,   696,
      67,    67,   798,   798,  -507,  -507,  -507,   227,  -507,  -507,
     262,    28,  1279,  -507,  -507,  -507,  -507,  -507,   -40,  1851,
    -507,  1969,   -42,   307,    -1,   331,  -507,  -507,  -507,   113,
    -507,   620,   231,   656,    49,    94,  -507,  -507,  -507,  -507,
    -507,  -507,    87,  1851,    94,   157,  1851,  -507,  -507,  -507,
    -507,  -507,  -507,  -507,  -507,    22,  1851,  -507,  -507,  -507,
    -507,  -507,  -507,    32,  1851,  -507,  -507,  -507,  -507,  -507,
    -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,
    -507,  1885,   167,   117,   203,  -507,  -507,   210,  1722,   198,
    -507,    82,  -507,   620,   620,  1588,  1624,  1851,   210,  1976,
    2021,  2021,  -507,  -507,  -507,   917,  -507,  -507,  -507,  -507,
    -507,  -507,   111,  -507,   469,   911,  1969,  -507,   191,   245,
     385,    17,   477,   272,   271,   303,   335,     9,  -507,  -507,
      21,   231,  -507,   231,  -507,  -507,   113,   876,    94,   231,
     670,   103,    94,  -507,  1778,  -507,  -507,   656,   327,   332,
     231,   656,   686,  -507,  -507,   351,  -507,   347,   210,  1851,
     210,   347,   210,  1851,   210,   347,   210,  1851,   210,   347,
     210,  1851,   210,   407,  1913,  2150,  -507,    24,  -507,    62,
     346,  1885,  -507,   379,   297,  1885,   388,  -507,   405,   117,
     762,  -507,  -507,  -507,   694,   694,  1315,  1383,   798,   599,
     414,   404,  -507,   173,    67,   224,  2028,  2073,    94,    94,
    -507,   210,  -507,   917,  -507,   917,  -507,  -507,   218,    34,
    1686,    67,   434,  -507,  -507,  -507,  1916,  1969,   441,   501,
    -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,
    -507,  1969,  -507,  -507,  1969,  1969,  1969,  1969,  1969,  1969,
    1969,  1969,  1969,  1969,  1969,  1969,  1969,  1969,  1969,  1969,
    1969,  1969,  1969,   475,  1969,  -507,  -507,   314,   876,   347,
     670,   670,  1044,   347,   356,   231,   231,   485,   378,   656,
    -507,  -507,   497,  1110,  -507,  -507,   210,  -507,  -507,  -507,
     210,  -507,  -507,  -507,   210,  -507,  -507,  -507,   210,  -507,
    1969,  -507,  -507,   505,  -507,  -507,  -507,  -507,   407,   502,
     117,   503,  1969,   388,   508,   514,  1969,  1969,   513,   517,
     533,   117,  1065,   544,   545,    67,   549,   553,  -507,  -507,
     554,   558,   561,  -507,  -507,  -507,   840,   663,  -507,  -507,
    -507,  -507,  1143,  1014,  -507,  -507,  -507,  -507,  -507,  -507,
    -507,  -507,  -507,  1211,  1175,  -507,  -507,  -507,  -507,  -507,
    1812,  -507,   567,    67,  1969,  1969,   562,  -507,   564,   565,
     566,  -507,   575,   578,  -507,  1419,   641,  -507,  -507,  1924,
    -507,   239,  -507,     7,   464,   464,  -507,  -507,  -507,  -507,
     191,   191,   245,   245,   385,   385,   385,   385,    17,    17,
     477,   272,   271,   303,   335,   480,  -507,  -507,  -507,   670,
    -507,  -507,  -507,  -507,  -507,  -507,   421,   267,   266,  -507,
    -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,
    -507,  -507,  -507,  -507,   576,  -507,  1969,   581,   585,  -507,
    1969,  1065,   586,   633,  1969,  1969,   589,  -507,  1065,  -507,
     991,  -507,  -507,   602,   606,   609,  1014,  -507,  1175,  -507,
    -507,  -507,   607,   610,  -507,  -507,  -507,  -507,   616,   616,
     641,   205,  -507,  -507,  1969,  -507,  -507,  -507,  -507,  -507,
    1969,  -507,  -507,  1969,   117,  -507,   613,  1110,    99,  -507,
    -507,   282,  1065,  -507,   626,  -507,  -507,   636,   291,   316,
    1969,  -507,  -507,  -507,   231,  -507,  -507,  -507,  -507,   613,
    -507,  -507,   627,  -507,   340,   628,  -507,  -507,  -507,  1065,
    -507,  1969,  1969,  1065,  1065,   416,  -507,   634,  -507,  1110,
    -507,  -507,   640,   333,   705,  -507,   647,    41,  -507,  -507,
    1969,   648,  1065,  -507,   658,   666,   410,   676,  -507,   681,
    -507,  -507,  1969,   682,   687,    41,    41,  1065,   381,   699,
    -507,   454,  -507,  -507,  -507,   690,   733,   497,  1969,  -507,
     111,   392,   445,   737,   497,  -507,  -507,   111
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -507,  -310,  -507,   -20,  -507,  -507,   166,  -507,   209,  -507,
    -507,  -507,  -507,  -507,   382,  -507,   299,  -507,  -139,   276,
     265,   365,   275,   511,   512,   510,   515,   519,  -507,  -338,
    -172,  -507,  -507,   -61,  -325,  -354,     5,  -507,  -507,    36,
     153,    37,   150,  -204,   -23,     8,  -507,   304,   -76,   137,
    -507,  -105,  -507,  -507,   353,   426,   252,  -507,   217,  -507,
    -507,   588,  -507,   595,  -507,  -507,   470,  -507,   478,   367,
    -507,   600,   482,  -507,  -507,   430,  -507,   -43,   283,   208,
    -506,   337,   324,  -507,   354,  -331,    79,  -507,   418,   -57,
     507,  -507,  -507,  -507,  -507,  -507,  -507,   827,  -507,  -507,
    -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,  -507,
    -507,  -507,  -507,  -507,     6,  -507,   -51,   -63,  -507,   178,
    -507,  -120,     1,   -17,  -507,   123,   614,  -507,   109,   -52,
    -507,  -300,  -123
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -289
static const yytype_int16 yytable[] =
{
     170,    55,   465,   478,   122,    28,   130,   124,    62,    61,
     188,   130,   457,   105,   465,   111,   217,   283,   465,   116,
     185,   556,   474,   193,   171,   128,   199,   473,   125,   203,
     129,   477,    82,    85,    95,   103,    31,    33,    84,   207,
     404,    89,    98,    12,    89,   107,    89,   211,   114,   115,
      89,   117,   238,    55,    18,   197,    62,    28,   301,   195,
      21,   291,   292,   579,   201,   173,   174,   314,    12,   195,
     178,   318,   183,    98,   407,   410,   304,   182,   515,    18,
     228,    12,   494,   209,   258,    21,    12,   303,    31,    33,
     304,  -150,    18,   494,   422,  -286,   302,    18,    21,   415,
     293,   294,   584,    21,   129,  -288,    24,    25,   238,   426,
     416,   585,    72,    24,   191,   494,   217,   188,    26,   305,
     217,   306,    12,    58,   188,    74,   534,   130,   188,  -151,
     193,   195,   447,    18,   183,   183,   248,   249,   317,    21,
      84,   320,   250,    89,    98,   427,   428,   429,    63,    58,
      34,   459,   247,    32,    58,    58,    58,    58,   309,    62,
    -282,   486,   313,    62,   234,   236,    72,    24,   311,   523,
      62,   524,   263,   376,    62,    58,    65,    24,   176,   181,
     119,   120,   551,   384,   390,   465,   228,   557,    58,   177,
     314,   318,   258,   174,   258,   555,    63,    58,   552,   456,
      98,    68,    34,    69,   250,    32,   423,   572,   250,    80,
      80,    70,   250,    71,   183,   111,   250,    12,   567,   343,
     234,   236,    98,   107,   192,   115,   589,   117,    18,   209,
    -284,   244,   502,   503,    21,   385,   391,   395,   397,   401,
     225,   445,   402,    12,    89,    98,    89,   188,   188,    80,
      93,   101,   194,    98,    18,   130,   188,   405,   216,   495,
      21,   320,   317,   452,   453,   239,   317,   284,    98,   117,
     495,   214,   285,   286,   213,   523,   229,   524,   237,   245,
     512,   235,   216,   230,   414,    91,   100,   304,   106,   109,
     119,   120,   495,    62,    62,   260,   184,   610,   259,   307,
     121,   129,    62,   307,   617,   513,   238,   228,   514,   174,
      63,    80,    80,   174,    63,    58,    98,   238,   482,   188,
      98,   239,   287,   288,   238,   119,   120,   308,   263,   456,
     493,   312,   193,   522,   237,   123,   523,   235,   524,   238,
     525,   493,   550,   386,   392,   396,   398,   297,   559,   183,
      12,   304,    93,   101,   343,   459,   298,   563,   216,   194,
     304,    18,   216,   493,   347,    62,   348,    21,   417,   418,
     321,   214,   128,   172,   213,   214,    62,   129,   213,   184,
     172,   250,   564,   300,   129,   304,   188,    91,   100,   299,
     216,    80,   216,   315,   403,    24,    25,   459,   316,   581,
      94,   102,   304,   260,   317,   260,   259,    26,   259,   328,
     523,    98,   524,   332,  -243,   531,   322,   336,   234,   236,
     344,   184,   451,   538,   539,   215,   129,   289,   290,   234,
     236,   101,    62,   307,   307,   323,   234,   236,   254,   256,
     257,   483,    63,   184,   455,   320,   346,   604,   129,   215,
     304,   234,   236,    93,   101,   282,   492,   350,   613,    90,
      99,   614,    90,   108,    90,   113,   100,   109,    90,   118,
      72,    24,   180,   400,   219,   340,   594,   101,   595,   565,
     399,   553,   576,   181,   577,   304,   184,   521,    91,   100,
     321,   129,   566,   352,    72,    24,    73,   174,   261,   174,
     419,   573,    94,   102,    98,   307,    98,    74,   -30,   264,
     265,   615,   100,   424,   304,   403,   307,   448,    98,   239,
     606,   450,   607,   295,   296,   215,    80,   516,   517,   215,
     239,   598,   237,   496,   266,   235,   412,   239,   413,   267,
     425,   -28,   446,   237,   498,   231,   235,   612,   520,   304,
     237,   454,   239,   235,   432,   433,   252,   215,   142,   215,
     535,    90,    99,   430,   431,   237,   510,   541,   235,   492,
     438,   439,   307,   340,   219,   475,   470,   472,   219,   476,
     479,   102,   480,   282,   282,   282,   282,   282,   282,   282,
     282,   282,   282,   282,   282,   282,   282,   282,   282,   282,
     282,   481,     1,    94,   102,   546,   261,   546,   261,   484,
     485,   560,     7,     8,    59,    10,   325,  -224,   327,   546,
     329,  -223,   331,   304,   333,   487,   335,   102,   337,   488,
     339,   501,    19,   504,    20,   505,   506,   507,   571,   282,
      67,   508,   574,   575,   509,    83,    86,    96,   104,   532,
     530,   282,   533,   536,   540,   282,   434,   435,   436,   437,
      12,   591,    90,    99,    90,   113,    59,   537,   543,   411,
     354,    18,   544,   355,   356,   545,   603,    21,   547,   175,
     357,   548,   554,    72,    24,   180,   358,   359,    67,   511,
     360,   361,   139,   561,   362,   363,   181,   364,   568,     1,
     365,   562,   570,   140,   141,    12,   415,   580,   578,     7,
       8,   129,    10,   582,   583,   590,    18,   416,   282,   186,
      24,   187,    21,   592,   142,   143,   119,   367,   145,    19,
     593,    20,    74,   186,    24,   310,   230,   491,   146,   147,
     148,   149,   150,   151,   461,   596,   181,   597,   462,    72,
      24,   319,   463,   599,   600,   608,   464,    72,    24,   382,
     605,   601,    74,   112,   129,     1,     2,     3,     4,   354,
     383,     5,   355,   356,     6,     7,     8,     9,    10,   357,
      11,    12,    13,    14,    15,   358,   359,    16,    17,   360,
     361,   139,    18,   362,   363,    19,   364,    20,    21,   365,
     609,     1,   140,   141,   616,   602,   175,   519,   440,   442,
     441,     7,     8,   349,    10,   443,   345,    12,   469,   282,
     444,   468,   282,   142,   143,   366,   367,   145,    18,   353,
     500,    19,   471,    20,    21,   230,   368,   146,   147,   148,
     149,   150,   151,     1,     2,     3,     4,   354,   549,     5,
     355,   356,     6,     7,     8,     9,    10,   357,    11,    12,
      13,    14,    15,   358,   359,    16,    17,   360,   361,   139,
      18,   362,   363,    19,   364,    20,    21,   365,   569,   126,
     140,   141,   558,   490,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    12,     0,     0,     0,     0,
       0,   142,   143,   366,   367,   145,    18,     0,     0,     0,
       0,     0,    21,   230,   489,   146,   147,   148,   149,   150,
     151,     2,     3,     4,     0,     0,     5,     0,     0,     6,
       0,     0,     9,     0,     0,    11,    12,    13,    14,    15,
      24,   176,    16,    17,     0,     0,   139,    18,     0,     0,
       0,     0,   177,    21,     0,     0,     0,   140,   141,     0,
       0,     0,   270,   271,   272,   273,   274,   275,   276,   277,
     278,   279,     0,     1,     0,     0,     0,     0,   142,   143,
      23,   144,   145,     7,     8,     0,    10,     0,     0,    12,
       0,     0,   146,   147,   148,   149,   150,   151,   354,   280,
      18,   355,   356,    19,     0,    20,    21,     0,   357,     0,
       0,     0,     0,     0,   358,   359,     0,     0,   360,   361,
     139,     0,   362,   363,     0,   364,     0,     0,   365,     0,
       0,   140,   141,    12,     0,     0,     0,   110,     0,     0,
       0,     0,     0,     0,    18,     0,     0,     0,     0,     0,
      21,     0,   142,   143,   119,   367,   145,     0,     0,     0,
       0,     0,     0,    12,   230,   542,   146,   147,   148,   149,
     150,   151,   354,     0,    18,   355,   356,    72,    24,   382,
      21,     0,   357,     0,   129,     0,     0,     0,   358,   359,
     383,     0,   360,   361,   139,     0,   362,   363,     0,   364,
       0,     0,   365,     0,     0,   140,   141,    72,    24,   449,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     181,     0,     0,     0,     0,     0,   142,   143,   119,   367,
     145,     0,     0,     0,     0,     0,     0,     0,   230,   139,
     146,   147,   148,   149,   150,   151,     1,     2,     3,     4,
     140,   141,     5,     0,     0,     6,     7,     8,     9,    10,
       0,    11,    12,    13,    14,    15,     0,     0,    16,    17,
       0,   142,   143,    18,   144,   145,    19,     0,    20,    21,
       0,     0,     0,   458,     0,   146,   147,   148,   149,   150,
     151,     0,     0,     0,    12,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    18,    23,    24,   382,   233,
       0,    21,     0,   129,     1,     2,     3,     4,     0,   383,
       5,     0,     0,     6,     7,     8,     9,    10,     0,    11,
      12,    13,    14,    15,     0,     0,    16,    17,     0,    24,
     393,    18,     0,     0,    19,   129,    20,    21,     0,     0,
       0,   394,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    23,    24,   393,   233,     0,     0,
       0,   129,     1,     2,     3,     4,     0,   394,     5,     0,
       0,     6,     7,     8,     9,    10,     0,    11,    12,    13,
      14,    15,     0,     0,    16,    17,     0,     0,     0,    18,
       0,     0,    19,     0,    20,    21,    22,     0,     1,     2,
       3,     4,     0,     0,     5,     0,     0,     6,     7,     8,
       9,    10,     0,    11,    12,    13,    14,    15,     0,     0,
      16,    17,    23,    24,    25,    18,     0,     0,    19,     0,
      20,    21,     0,     0,     0,    26,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,    87,    24,
     393,     0,     0,     0,     0,   129,     1,     2,     3,     4,
       0,   394,     5,     0,     0,     6,     7,     8,     9,    10,
       0,    11,    12,    13,    14,    15,     0,     0,    16,    17,
       0,     0,     0,    18,     0,     0,    19,     0,    20,    21,
       0,     0,     1,     2,     3,     4,     0,     0,     5,     0,
       0,     6,     7,     8,     9,    10,     0,    11,    12,    13,
      14,    15,     0,     0,    16,    17,    97,    24,   393,    18,
       0,     0,    19,   129,    20,    21,     0,     0,     0,   394,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    23,     0,   415,   233,     0,     0,     0,   129,
       1,     2,     3,     4,     0,   416,     5,     0,     0,     6,
       7,     8,     9,    10,     0,    11,    12,    13,    14,    15,
       0,     0,    16,    17,     0,     0,     0,    18,     0,     0,
      19,     0,    20,    21,     0,     0,     1,     2,     3,     4,
       0,     0,     5,     0,     0,     6,     7,     8,     9,    10,
       0,    11,    12,    13,    14,    15,     0,     0,    16,    17,
      87,    24,    25,    18,     0,     0,    19,     0,    20,    21,
       0,     0,     0,    26,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    97,    24,    25,     0,
       0,     1,     2,     3,     4,     0,     0,     5,     0,    26,
       6,     7,     8,     9,    10,     0,    11,    12,    13,    14,
      15,     0,     0,    16,    17,     0,     0,     0,    18,     0,
       0,    19,     0,    20,    21,     0,     0,     1,     2,     3,
       4,     0,     0,     5,     0,     0,     6,     7,     8,     9,
      10,     0,    11,    12,    13,    14,    15,     0,     0,    16,
      17,    87,    24,   176,    18,     0,     0,    19,     0,    20,
      21,     0,     0,     0,   177,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    97,    24,   176,
       2,     3,     4,     0,     0,     5,     0,     0,     6,     0,
     177,     9,     0,     0,    11,    12,    13,    14,    15,     0,
       0,    16,    17,     0,     0,     0,    18,     0,     0,     0,
       0,     0,    21,     0,     0,     1,     2,     3,     4,     0,
       0,     5,     0,     0,     6,     7,     8,     9,    10,     0,
      11,    12,    13,    14,    15,     0,     0,    16,    17,    97,
       0,   415,    18,     0,     0,    19,   129,    20,    21,     0,
       0,     0,   416,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     1,     2,     3,     4,    23,   232,     5,   233,     0,
       6,     7,     8,     9,    10,     0,    11,    12,    13,    14,
      15,     0,     0,    16,    17,     0,     0,     0,    18,     0,
       0,    19,     0,    20,    21,     1,     2,     3,     4,     0,
       0,     5,     0,     0,     6,     7,     8,     9,    10,     0,
      11,    12,    13,    14,    15,     0,     0,    16,    17,     0,
       0,    23,    18,     0,   233,    19,     0,    20,    21,     0,
       0,     0,     0,     0,     1,     2,     3,     4,     0,     0,
       5,     0,   499,     6,     7,     8,     9,    10,     0,    11,
      12,    13,    14,    15,     0,    23,    16,    17,     0,     0,
       0,    18,     0,     0,    19,     0,    20,    21,     0,     2,
       3,     4,     0,     0,     5,     0,     0,     6,     0,     0,
       9,     0,     0,    11,    12,    13,    14,    15,     0,     0,
      16,    17,     0,     0,    23,    18,     0,     2,     3,     4,
       0,    21,     5,     0,     0,     6,     0,     0,     9,     0,
       0,    11,    12,    13,    14,    15,     0,     0,    16,    17,
       0,     0,     0,    18,     0,   139,     0,     0,    23,    21,
       0,     0,     0,   139,     0,     0,   140,   141,     0,     0,
       0,     0,     0,     0,   140,   141,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    97,   142,   143,     0,
     144,   145,   420,     0,     0,   142,   143,     0,   144,   145,
       0,   146,   147,   148,   149,   150,   151,   511,   139,   146,
     147,   148,   149,   150,   151,   139,     0,     0,     0,   140,
     141,     0,     0,     0,     0,     0,   140,   141,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     142,   143,     0,   144,   145,     0,     0,   142,   143,     0,
     144,   253,     0,     0,   146,   147,   148,   149,   150,   151,
     139,   146,   147,   148,   149,   150,   151,   139,     0,     0,
       0,   140,   141,     0,     0,     0,     0,     0,   140,   141,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,   142,   143,     0,   144,   255,     0,     0,   142,
     143,     0,   144,   145,     0,     0,   146,   147,   148,   149,
     150,   151,   139,   146,   406,   148,   149,   150,   151,     1,
       2,     3,     0,   140,   141,     5,     0,     0,     0,     7,
       8,     9,    10,     0,     0,    12,    13,    14,    15,     0,
       0,    16,    17,     0,   142,   143,    18,   144,   145,    19,
       0,    20,    21,     0,     0,     0,     0,     0,   146,   409,
     148,   149,   150,   151,     2,     3,     0,     0,     0,     5,
       0,     0,     0,     0,     0,     9,     0,     0,     0,    12,
      13,    14,    15,     0,     0,    16,    17,     0,     0,     0,
      18,     0,     0,     0,     0,     0,    21
};

static const yytype_int16 yycheck[] =
{
      61,     0,   340,   357,    47,     0,    58,    50,    25,    65,
      73,    63,   322,    36,   352,    38,   121,   156,   356,    42,
      72,   527,   353,    74,    66,    65,    83,   352,     0,    86,
      70,   356,    31,    32,    33,    34,     0,     0,    32,    96,
     244,    33,    34,    19,    36,    37,    38,   104,    40,    41,
      42,    43,   128,    52,    30,    75,    73,    52,    49,    37,
      36,    44,    45,   569,    84,    66,    65,   187,    19,    37,
      69,   191,    71,    65,   246,   247,    69,    71,    71,    30,
     123,    19,   382,   103,   145,    36,    19,    66,    52,    52,
      69,    67,    30,   393,   266,    73,    87,    30,    36,    65,
      83,    84,    61,    36,    70,    73,    64,    65,   184,   281,
      76,    70,    63,    64,    65,   415,   221,   180,    76,   171,
     225,   173,    19,     0,   187,    76,   480,   179,   191,    67,
     181,    37,   304,    30,   133,   134,   135,   136,   190,    36,
     134,   192,   137,   135,   136,   284,   285,   286,    25,    26,
       0,   323,    70,     0,    31,    32,    33,    34,   178,   176,
      73,   365,   182,   180,   128,   128,    63,    64,    65,    70,
     187,    72,    61,   230,   191,    52,    26,    64,    65,    76,
      63,    64,   520,   234,   235,   523,   229,    88,    65,    76,
     310,   311,   253,   192,   255,   526,    73,    74,   523,   319,
     192,    67,    52,    69,   199,    52,   267,   561,   203,    31,
      32,    67,   207,    69,   213,   238,   211,    19,   549,   213,
     184,   184,   214,   215,    74,   217,   580,   219,    30,   249,
      73,    33,   404,   405,    36,   234,   235,   236,   237,    66,
      73,   302,    69,    19,   236,   237,   238,   310,   311,    71,
      33,    34,    74,   245,    30,   307,   319,    33,   121,   382,
      36,   312,   314,   315,   316,   128,   318,    76,   260,   261,
     393,   121,    81,    82,   121,    70,    73,    72,   128,   129,
     419,   128,   145,    73,    66,    33,    34,    69,    36,    37,
      63,    64,   415,   310,   311,   145,    65,   607,   145,   176,
      73,    70,   319,   180,   614,    66,   382,   350,    69,   308,
     187,   133,   134,   312,   191,   192,   308,   393,   361,   382,
     312,   184,    77,    78,   400,    63,    64,   177,    61,   449,
     382,   181,   383,    66,   184,    73,    70,   184,    72,   415,
      74,   393,   514,   234,   235,   236,   237,    75,    66,   348,
      19,    69,   135,   136,   348,   527,    85,    66,   221,   181,
      69,    30,   225,   415,    67,   382,    69,    36,   259,   260,
     192,   221,    65,    66,   221,   225,   393,    70,   225,    65,
      66,   376,    66,    48,    70,    69,   449,   135,   136,    86,
     253,   213,   255,    66,   244,    64,    65,   569,    66,    66,
      33,    34,    69,   253,   456,   255,   253,    76,   255,   201,
      70,   403,    72,   205,    74,   476,    65,   209,   382,   382,
      74,    65,    66,   484,   485,   121,    70,    42,    43,   393,
     393,   214,   449,   310,   311,    88,   400,   400,   139,   140,
     141,   362,   319,    65,    66,   496,    67,    66,    70,   145,
      69,   415,   415,   236,   237,   156,   377,    69,    66,    33,
      34,    69,    36,    37,    38,    39,   214,   215,    42,    43,
      63,    64,    65,    69,   121,    68,    66,   260,    68,   540,
      66,   524,    66,    76,    68,    69,    65,    66,   236,   237,
     312,    70,   544,    88,    63,    64,    65,   496,   145,   498,
      66,   562,   135,   136,   496,   382,   498,    76,    39,    40,
      41,    66,   260,    72,    69,   365,   393,   309,   510,   382,
      66,   313,    68,    46,    47,   221,   348,    63,    64,   225,
     393,   592,   382,   383,    65,   382,   253,   400,   255,    70,
      39,    72,    67,   393,   394,   127,   393,   608,    68,    69,
     400,    66,   415,   400,   289,   290,   138,   253,    61,   255,
     481,   135,   136,   287,   288,   415,   416,   488,   415,   490,
     295,   296,   449,    68,   221,    67,    74,    74,   225,    65,
      67,   214,    65,   284,   285,   286,   287,   288,   289,   290,
     291,   292,   293,   294,   295,   296,   297,   298,   299,   300,
     301,    68,     3,   236,   237,   496,   253,   498,   255,    65,
      65,   532,    13,    14,     0,    16,   198,    68,   200,   510,
     202,    68,   204,    69,   206,    67,   208,   260,   210,    68,
     212,    64,    33,    71,    35,    71,    71,    71,   559,   340,
      26,    66,   563,   564,    66,    31,    32,    33,    34,    68,
      74,   352,    67,    67,    65,   356,   291,   292,   293,   294,
      19,   582,   236,   237,   238,   239,    52,    34,    66,   251,
       7,    30,    66,    10,    11,    66,   597,    36,    71,    65,
      17,    71,    69,    63,    64,    65,    23,    24,    74,    73,
      27,    28,    29,    67,    31,    32,    76,    34,    71,     3,
      37,    65,    74,    40,    41,    19,    65,    67,    74,    13,
      14,    70,    16,     8,    67,    67,    30,    76,   419,    63,
      64,    65,    36,    65,    61,    62,    63,    64,    65,    33,
      64,    35,    76,    63,    64,    65,    73,    74,    75,    76,
      77,    78,    79,    80,   326,    69,    76,    66,   330,    63,
      64,    65,   334,    71,    67,    65,   338,    63,    64,    65,
      61,   595,    76,    67,    70,     3,     4,     5,     6,     7,
      76,     9,    10,    11,    12,    13,    14,    15,    16,    17,
      18,    19,    20,    21,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      67,     3,    40,    41,    67,   596,   192,   425,   297,   299,
     298,    13,    14,   225,    16,   300,   221,    19,   348,   520,
     301,   343,   523,    61,    62,    63,    64,    65,    30,   229,
     400,    33,   350,    35,    36,    73,    74,    75,    76,    77,
      78,    79,    80,     3,     4,     5,     6,     7,   511,     9,
      10,    11,    12,    13,    14,    15,    16,    17,    18,    19,
      20,    21,    22,    23,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,   554,    52,
      40,    41,   528,   376,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    19,    -1,    -1,    -1,    -1,
      -1,    61,    62,    63,    64,    65,    30,    -1,    -1,    -1,
      -1,    -1,    36,    73,    74,    75,    76,    77,    78,    79,
      80,     4,     5,     6,    -1,    -1,     9,    -1,    -1,    12,
      -1,    -1,    15,    -1,    -1,    18,    19,    20,    21,    22,
      64,    65,    25,    26,    -1,    -1,    29,    30,    -1,    -1,
      -1,    -1,    76,    36,    -1,    -1,    -1,    40,    41,    -1,
      -1,    -1,    51,    52,    53,    54,    55,    56,    57,    58,
      59,    60,    -1,     3,    -1,    -1,    -1,    -1,    61,    62,
      63,    64,    65,    13,    14,    -1,    16,    -1,    -1,    19,
      -1,    -1,    75,    76,    77,    78,    79,    80,     7,    88,
      30,    10,    11,    33,    -1,    35,    36,    -1,    17,    -1,
      -1,    -1,    -1,    -1,    23,    24,    -1,    -1,    27,    28,
      29,    -1,    31,    32,    -1,    34,    -1,    -1,    37,    -1,
      -1,    40,    41,    19,    -1,    -1,    -1,    67,    -1,    -1,
      -1,    -1,    -1,    -1,    30,    -1,    -1,    -1,    -1,    -1,
      36,    -1,    61,    62,    63,    64,    65,    -1,    -1,    -1,
      -1,    -1,    -1,    19,    73,    74,    75,    76,    77,    78,
      79,    80,     7,    -1,    30,    10,    11,    63,    64,    65,
      36,    -1,    17,    -1,    70,    -1,    -1,    -1,    23,    24,
      76,    -1,    27,    28,    29,    -1,    31,    32,    -1,    34,
      -1,    -1,    37,    -1,    -1,    40,    41,    63,    64,    65,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      76,    -1,    -1,    -1,    -1,    -1,    61,    62,    63,    64,
      65,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    73,    29,
      75,    76,    77,    78,    79,    80,     3,     4,     5,     6,
      40,    41,     9,    -1,    -1,    12,    13,    14,    15,    16,
      -1,    18,    19,    20,    21,    22,    -1,    -1,    25,    26,
      -1,    61,    62,    30,    64,    65,    33,    -1,    35,    36,
      -1,    -1,    -1,    73,    -1,    75,    76,    77,    78,    79,
      80,    -1,    -1,    -1,    19,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    30,    63,    64,    65,    66,
      -1,    36,    -1,    70,     3,     4,     5,     6,    -1,    76,
       9,    -1,    -1,    12,    13,    14,    15,    16,    -1,    18,
      19,    20,    21,    22,    -1,    -1,    25,    26,    -1,    64,
      65,    30,    -1,    -1,    33,    70,    35,    36,    -1,    -1,
      -1,    76,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    63,    64,    65,    66,    -1,    -1,
      -1,    70,     3,     4,     5,     6,    -1,    76,     9,    -1,
      -1,    12,    13,    14,    15,    16,    -1,    18,    19,    20,
      21,    22,    -1,    -1,    25,    26,    -1,    -1,    -1,    30,
      -1,    -1,    33,    -1,    35,    36,    37,    -1,     3,     4,
       5,     6,    -1,    -1,     9,    -1,    -1,    12,    13,    14,
      15,    16,    -1,    18,    19,    20,    21,    22,    -1,    -1,
      25,    26,    63,    64,    65,    30,    -1,    -1,    33,    -1,
      35,    36,    -1,    -1,    -1,    76,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    63,    64,
      65,    -1,    -1,    -1,    -1,    70,     3,     4,     5,     6,
      -1,    76,     9,    -1,    -1,    12,    13,    14,    15,    16,
      -1,    18,    19,    20,    21,    22,    -1,    -1,    25,    26,
      -1,    -1,    -1,    30,    -1,    -1,    33,    -1,    35,    36,
      -1,    -1,     3,     4,     5,     6,    -1,    -1,     9,    -1,
      -1,    12,    13,    14,    15,    16,    -1,    18,    19,    20,
      21,    22,    -1,    -1,    25,    26,    63,    64,    65,    30,
      -1,    -1,    33,    70,    35,    36,    -1,    -1,    -1,    76,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    63,    -1,    65,    66,    -1,    -1,    -1,    70,
       3,     4,     5,     6,    -1,    76,     9,    -1,    -1,    12,
      13,    14,    15,    16,    -1,    18,    19,    20,    21,    22,
      -1,    -1,    25,    26,    -1,    -1,    -1,    30,    -1,    -1,
      33,    -1,    35,    36,    -1,    -1,     3,     4,     5,     6,
      -1,    -1,     9,    -1,    -1,    12,    13,    14,    15,    16,
      -1,    18,    19,    20,    21,    22,    -1,    -1,    25,    26,
      63,    64,    65,    30,    -1,    -1,    33,    -1,    35,    36,
      -1,    -1,    -1,    76,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    63,    64,    65,    -1,
      -1,     3,     4,     5,     6,    -1,    -1,     9,    -1,    76,
      12,    13,    14,    15,    16,    -1,    18,    19,    20,    21,
      22,    -1,    -1,    25,    26,    -1,    -1,    -1,    30,    -1,
      -1,    33,    -1,    35,    36,    -1,    -1,     3,     4,     5,
       6,    -1,    -1,     9,    -1,    -1,    12,    13,    14,    15,
      16,    -1,    18,    19,    20,    21,    22,    -1,    -1,    25,
      26,    63,    64,    65,    30,    -1,    -1,    33,    -1,    35,
      36,    -1,    -1,    -1,    76,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    63,    64,    65,
       4,     5,     6,    -1,    -1,     9,    -1,    -1,    12,    -1,
      76,    15,    -1,    -1,    18,    19,    20,    21,    22,    -1,
      -1,    25,    26,    -1,    -1,    -1,    30,    -1,    -1,    -1,
      -1,    -1,    36,    -1,    -1,     3,     4,     5,     6,    -1,
      -1,     9,    -1,    -1,    12,    13,    14,    15,    16,    -1,
      18,    19,    20,    21,    22,    -1,    -1,    25,    26,    63,
      -1,    65,    30,    -1,    -1,    33,    70,    35,    36,    -1,
      -1,    -1,    76,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,     3,     4,     5,     6,    63,    64,     9,    66,    -1,
      12,    13,    14,    15,    16,    -1,    18,    19,    20,    21,
      22,    -1,    -1,    25,    26,    -1,    -1,    -1,    30,    -1,
      -1,    33,    -1,    35,    36,     3,     4,     5,     6,    -1,
      -1,     9,    -1,    -1,    12,    13,    14,    15,    16,    -1,
      18,    19,    20,    21,    22,    -1,    -1,    25,    26,    -1,
      -1,    63,    30,    -1,    66,    33,    -1,    35,    36,    -1,
      -1,    -1,    -1,    -1,     3,     4,     5,     6,    -1,    -1,
       9,    -1,    50,    12,    13,    14,    15,    16,    -1,    18,
      19,    20,    21,    22,    -1,    63,    25,    26,    -1,    -1,
      -1,    30,    -1,    -1,    33,    -1,    35,    36,    -1,     4,
       5,     6,    -1,    -1,     9,    -1,    -1,    12,    -1,    -1,
      15,    -1,    -1,    18,    19,    20,    21,    22,    -1,    -1,
      25,    26,    -1,    -1,    63,    30,    -1,     4,     5,     6,
      -1,    36,     9,    -1,    -1,    12,    -1,    -1,    15,    -1,
      -1,    18,    19,    20,    21,    22,    -1,    -1,    25,    26,
      -1,    -1,    -1,    30,    -1,    29,    -1,    -1,    63,    36,
      -1,    -1,    -1,    29,    -1,    -1,    40,    41,    -1,    -1,
      -1,    -1,    -1,    -1,    40,    41,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    63,    61,    62,    -1,
      64,    65,    66,    -1,    -1,    61,    62,    -1,    64,    65,
      -1,    75,    76,    77,    78,    79,    80,    73,    29,    75,
      76,    77,    78,    79,    80,    29,    -1,    -1,    -1,    40,
      41,    -1,    -1,    -1,    -1,    -1,    40,    41,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      61,    62,    -1,    64,    65,    -1,    -1,    61,    62,    -1,
      64,    65,    -1,    -1,    75,    76,    77,    78,    79,    80,
      29,    75,    76,    77,    78,    79,    80,    29,    -1,    -1,
      -1,    40,    41,    -1,    -1,    -1,    -1,    -1,    40,    41,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    61,    62,    -1,    64,    65,    -1,    -1,    61,
      62,    -1,    64,    65,    -1,    -1,    75,    76,    77,    78,
      79,    80,    29,    75,    76,    77,    78,    79,    80,     3,
       4,     5,    -1,    40,    41,     9,    -1,    -1,    -1,    13,
      14,    15,    16,    -1,    -1,    19,    20,    21,    22,    -1,
      -1,    25,    26,    -1,    61,    62,    30,    64,    65,    33,
      -1,    35,    36,    -1,    -1,    -1,    -1,    -1,    75,    76,
      77,    78,    79,    80,     4,     5,    -1,    -1,    -1,     9,
      -1,    -1,    -1,    -1,    -1,    15,    -1,    -1,    -1,    19,
      20,    21,    22,    -1,    -1,    25,    26,    -1,    -1,    -1,
      30,    -1,    -1,    -1,    -1,    -1,    36
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,     3,     4,     5,     6,     9,    12,    13,    14,    15,
      16,    18,    19,    20,    21,    22,    25,    26,    30,    33,
      35,    36,    37,    63,    64,    65,    76,    93,   125,   126,
     127,   128,   129,   130,   131,   134,   135,   136,   137,   138,
     139,   140,   142,   143,   144,   145,   147,   148,   149,   158,
     159,   184,   185,   186,   187,   211,   212,   213,   214,   215,
     216,    65,   212,   214,   215,   131,   211,   215,    67,    69,
      67,    69,    63,    65,    76,   203,   204,   205,   206,   207,
     208,   209,   211,   215,   203,   211,   215,    63,   133,   134,
     144,   145,   146,   147,   158,   211,   215,    63,   134,   144,
     145,   147,   158,   211,   215,   133,   145,   134,   144,   145,
      67,   133,    67,   144,   134,   134,   133,   134,   144,    63,
      64,    73,   166,    73,   166,     0,   186,   188,    65,    70,
     218,   219,   125,   128,   129,   130,   131,   178,   193,    29,
      40,    41,    61,    62,    64,    65,    75,    76,    77,    78,
      79,    80,    90,    99,   100,   105,   106,   107,   108,   109,
     110,   111,   112,   113,   114,   115,   116,   117,   118,   119,
     122,    66,    66,    66,   211,   215,    65,    76,   211,   214,
      65,    76,   203,   211,    65,   218,    63,    65,   206,   208,
     210,    65,   131,   205,   208,    37,    91,    92,   189,   178,
     194,    92,   190,   178,   195,    92,   191,   178,   196,    92,
     192,   178,   197,   129,   131,   136,   138,   140,   141,   143,
     150,   151,   152,   153,   154,    73,   160,   161,   166,    73,
      73,   177,    64,    66,   128,   129,   130,   131,   137,   138,
     162,   163,   164,   165,    33,   131,   132,    70,   211,   211,
     125,   198,   177,    65,   105,    65,   105,   105,   122,   129,
     131,   143,   167,    61,    40,    41,    65,    70,   101,   102,
      51,    52,    53,    54,    55,    56,    57,    58,    59,    60,
      88,   120,   105,   107,    76,    81,    82,    77,    78,    42,
      43,    44,    45,    83,    84,    46,    47,    75,    85,    86,
      48,    49,    87,    66,    69,   218,   218,   214,   131,    92,
      65,    65,   131,    92,   210,    66,    66,   218,   210,    65,
     205,   208,    65,    88,   168,   177,   199,   177,   168,   177,
     200,   177,   168,   177,   201,   177,   168,   177,   202,   177,
      68,   155,   157,   203,    74,   152,    67,    67,    69,   150,
      69,   174,    88,   160,     7,    10,    11,    17,    23,    24,
      27,    28,    31,    32,    34,    37,    63,    64,    74,    94,
     122,   124,   166,   175,   176,   177,   178,   179,   180,   181,
     182,   183,    65,    76,   205,   211,   217,   218,   220,   221,
     205,   211,   217,    65,    76,   211,   217,   211,   217,    66,
      69,    66,    69,   131,   132,    33,    76,   119,   121,    76,
     119,   177,   167,   167,    66,    65,    76,   217,   217,    66,
      66,   104,   119,   122,    72,    39,   119,   107,   107,   107,
     108,   108,   109,   109,   110,   110,   110,   110,   111,   111,
     112,   113,   114,   115,   116,   122,    67,   119,   168,    65,
     168,    66,   218,   218,    66,    66,   210,    90,    73,   119,
     169,   177,   177,   177,   177,   118,   123,   156,   157,   155,
      74,   161,    74,   123,   174,    67,    65,   123,   124,    67,
      65,    68,   166,   175,    65,    65,   132,    67,    68,    74,
     179,    74,   175,   218,   220,   221,   131,   217,   131,    50,
     164,    64,   119,   119,    71,    71,    71,    71,    66,    66,
     131,    73,   107,    66,    69,    71,    63,    64,   103,   103,
      68,    66,    66,    70,    72,    74,   170,   171,   172,   173,
      74,   122,    68,    67,   124,   175,    67,    34,   122,   122,
      65,   175,    74,    66,    66,    66,   217,    71,    71,   170,
     119,   118,   123,   166,    69,   174,   169,    88,   173,    66,
     175,    67,    65,    66,    66,   122,   218,   174,    71,   171,
      74,   175,   124,   122,   175,   175,    66,    68,    74,   169,
      67,    66,     8,    67,    61,    70,    95,    96,    97,   124,
      67,   175,    65,    64,    66,    68,    69,    66,   122,    71,
      67,    95,    97,   175,    66,    61,    66,    68,    65,    67,
      90,    98,   122,    66,    69,    66,    67,    90
};

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		(-2)
#define YYEOF		0

#define YYACCEPT	goto yyacceptlab
#define YYABORT		goto yyabortlab
#define YYERROR		goto yyerrorlab


/* Like YYERROR except do call yyerror.  This remains here temporarily
   to ease the transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  However,
   YYFAIL appears to be in use.  Nevertheless, it is formally deprecated
   in Bison 2.4.2's NEWS entry, where a plan to phase it out is
   discussed.  */

#define YYFAIL		goto yyerrlab
#if defined YYFAIL
  /* This is here to suppress warnings from the GCC cpp's
     -Wunused-macros.  Normally we don't worry about that warning, but
     some users do, and we want to make it easy for users to remove
     YYFAIL uses, which will produce warnings from Bison 2.5.  */
#endif

#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)					\
do								\
  if (yychar == YYEMPTY && yylen == 1)				\
    {								\
      yychar = (Token);						\
      yylval = (Value);						\
      yytoken = YYTRANSLATE (yychar);				\
      YYPOPSTACK (1);						\
      goto yybackup;						\
    }								\
  else								\
    {								\
      yyerror (YY_("syntax error: cannot back up")); \
      YYERROR;							\
    }								\
while (YYID (0))


#define YYTERROR	1
#define YYERRCODE	256


/* YYLLOC_DEFAULT -- Set CURRENT to span from RHS[1] to RHS[N].
   If N is 0, then set CURRENT to the empty location which ends
   the previous symbol: RHS[0] (always defined).  */

#define YYRHSLOC(Rhs, K) ((Rhs)[K])
#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)				\
    do									\
      if (YYID (N))                                                    \
	{								\
	  (Current).first_line   = YYRHSLOC (Rhs, 1).first_line;	\
	  (Current).first_column = YYRHSLOC (Rhs, 1).first_column;	\
	  (Current).last_line    = YYRHSLOC (Rhs, N).last_line;		\
	  (Current).last_column  = YYRHSLOC (Rhs, N).last_column;	\
	}								\
      else								\
	{								\
	  (Current).first_line   = (Current).last_line   =		\
	    YYRHSLOC (Rhs, 0).last_line;				\
	  (Current).first_column = (Current).last_column =		\
	    YYRHSLOC (Rhs, 0).last_column;				\
	}								\
    while (YYID (0))
#endif


/* YY_LOCATION_PRINT -- Print the location on the stream.
   This macro was not mandated originally: define only if we know
   we won't break user code: when these are the locations we know.  */

#ifndef YY_LOCATION_PRINT
# if defined YYLTYPE_IS_TRIVIAL && YYLTYPE_IS_TRIVIAL
#  define YY_LOCATION_PRINT(File, Loc)			\
     fprintf (File, "%d.%d-%d.%d",			\
	      (Loc).first_line, (Loc).first_column,	\
	      (Loc).last_line,  (Loc).last_column)
# else
#  define YY_LOCATION_PRINT(File, Loc) ((void) 0)
# endif
#endif


/* YYLEX -- calling `yylex' with the right arguments.  */

#ifdef YYLEX_PARAM
# define YYLEX yylex (&yylval, YYLEX_PARAM)
#else
# define YYLEX yylex (&yylval)
#endif

/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)			\
do {						\
  if (yydebug)					\
    YYFPRINTF Args;				\
} while (YYID (0))

# define YY_SYMBOL_PRINT(Title, Type, Value, Location)			  \
do {									  \
  if (yydebug)								  \
    {									  \
      YYFPRINTF (stderr, "%s ", Title);					  \
      yy_symbol_print (stderr,						  \
		  Type, Value); \
      YYFPRINTF (stderr, "\n");						  \
    }									  \
} while (YYID (0))


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_value_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep)
#else
static void
yy_symbol_value_print (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
#endif
{
  if (!yyvaluep)
    return;
# ifdef YYPRINT
  if (yytype < YYNTOKENS)
    YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
# else
  YYUSE (yyoutput);
# endif
  switch (yytype)
    {
      case 64: /* "IDENTIFIER" */

/* Line 724 of yacc.c  */
#line 423 "ctlib/parser.y"
	{
  if ((yyvaluep->identifier))
    fprintf(yyoutput, "'%s' len=%d, hash=0x%lx", (yyvaluep->identifier)->key, (yyvaluep->identifier)->keylen, (unsigned long)(yyvaluep->identifier)->hash);
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2020 "ctlib/y_parser.c"
	break;
      case 155: /* "member_declarator" */

/* Line 724 of yacc.c  */
#line 503 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    if ((yyvaluep->pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", (yyvaluep->pDecl)->identifier, (yyvaluep->pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", (yyvaluep->pDecl)->pointer_flag ? "*" : "", (yyvaluep->pDecl)->identifier);

      if ((yyvaluep->pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, (yyvaluep->pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2050 "ctlib/y_parser.c"
	break;
      case 166: /* "identifier_or_typedef_name" */

/* Line 724 of yacc.c  */
#line 423 "ctlib/parser.y"
	{
  if ((yyvaluep->identifier))
    fprintf(yyoutput, "'%s' len=%d, hash=0x%lx", (yyvaluep->identifier)->key, (yyvaluep->identifier)->keylen, (unsigned long)(yyvaluep->identifier)->hash);
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2064 "ctlib/y_parser.c"
	break;
      case 203: /* "declarator" */

/* Line 724 of yacc.c  */
#line 503 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    if ((yyvaluep->pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", (yyvaluep->pDecl)->identifier, (yyvaluep->pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", (yyvaluep->pDecl)->pointer_flag ? "*" : "", (yyvaluep->pDecl)->identifier);

      if ((yyvaluep->pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, (yyvaluep->pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2094 "ctlib/y_parser.c"
	break;
      case 204: /* "typedef_declarator" */

/* Line 724 of yacc.c  */
#line 503 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    if ((yyvaluep->pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", (yyvaluep->pDecl)->identifier, (yyvaluep->pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", (yyvaluep->pDecl)->pointer_flag ? "*" : "", (yyvaluep->pDecl)->identifier);

      if ((yyvaluep->pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, (yyvaluep->pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2124 "ctlib/y_parser.c"
	break;
      case 205: /* "parameter_typedef_declarator" */

/* Line 724 of yacc.c  */
#line 503 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    if ((yyvaluep->pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", (yyvaluep->pDecl)->identifier, (yyvaluep->pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", (yyvaluep->pDecl)->pointer_flag ? "*" : "", (yyvaluep->pDecl)->identifier);

      if ((yyvaluep->pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, (yyvaluep->pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2154 "ctlib/y_parser.c"
	break;
      case 206: /* "clean_typedef_declarator" */

/* Line 724 of yacc.c  */
#line 503 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    if ((yyvaluep->pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", (yyvaluep->pDecl)->identifier, (yyvaluep->pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", (yyvaluep->pDecl)->pointer_flag ? "*" : "", (yyvaluep->pDecl)->identifier);

      if ((yyvaluep->pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, (yyvaluep->pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2184 "ctlib/y_parser.c"
	break;
      case 207: /* "clean_postfix_typedef_declarator" */

/* Line 724 of yacc.c  */
#line 503 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    if ((yyvaluep->pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", (yyvaluep->pDecl)->identifier, (yyvaluep->pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", (yyvaluep->pDecl)->pointer_flag ? "*" : "", (yyvaluep->pDecl)->identifier);

      if ((yyvaluep->pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, (yyvaluep->pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2214 "ctlib/y_parser.c"
	break;
      case 208: /* "paren_typedef_declarator" */

/* Line 724 of yacc.c  */
#line 503 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    if ((yyvaluep->pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", (yyvaluep->pDecl)->identifier, (yyvaluep->pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", (yyvaluep->pDecl)->pointer_flag ? "*" : "", (yyvaluep->pDecl)->identifier);

      if ((yyvaluep->pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, (yyvaluep->pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2244 "ctlib/y_parser.c"
	break;
      case 209: /* "paren_postfix_typedef_declarator" */

/* Line 724 of yacc.c  */
#line 503 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    if ((yyvaluep->pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", (yyvaluep->pDecl)->identifier, (yyvaluep->pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", (yyvaluep->pDecl)->pointer_flag ? "*" : "", (yyvaluep->pDecl)->identifier);

      if ((yyvaluep->pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, (yyvaluep->pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2274 "ctlib/y_parser.c"
	break;
      case 210: /* "simple_paren_typedef_declarator" */

/* Line 724 of yacc.c  */
#line 503 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    if ((yyvaluep->pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", (yyvaluep->pDecl)->identifier, (yyvaluep->pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", (yyvaluep->pDecl)->pointer_flag ? "*" : "", (yyvaluep->pDecl)->identifier);

      if ((yyvaluep->pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, (yyvaluep->pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2304 "ctlib/y_parser.c"
	break;
      case 211: /* "identifier_declarator" */

/* Line 724 of yacc.c  */
#line 503 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    if ((yyvaluep->pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", (yyvaluep->pDecl)->identifier, (yyvaluep->pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", (yyvaluep->pDecl)->pointer_flag ? "*" : "", (yyvaluep->pDecl)->identifier);

      if ((yyvaluep->pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, (yyvaluep->pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2334 "ctlib/y_parser.c"
	break;
      case 212: /* "unary_identifier_declarator" */

/* Line 724 of yacc.c  */
#line 503 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    if ((yyvaluep->pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", (yyvaluep->pDecl)->identifier, (yyvaluep->pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", (yyvaluep->pDecl)->pointer_flag ? "*" : "", (yyvaluep->pDecl)->identifier);

      if ((yyvaluep->pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, (yyvaluep->pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2364 "ctlib/y_parser.c"
	break;
      case 213: /* "postfix_identifier_declarator" */

/* Line 724 of yacc.c  */
#line 503 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    if ((yyvaluep->pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", (yyvaluep->pDecl)->identifier, (yyvaluep->pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", (yyvaluep->pDecl)->pointer_flag ? "*" : "", (yyvaluep->pDecl)->identifier);

      if ((yyvaluep->pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, (yyvaluep->pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2394 "ctlib/y_parser.c"
	break;
      case 214: /* "paren_identifier_declarator" */

/* Line 724 of yacc.c  */
#line 503 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    if ((yyvaluep->pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", (yyvaluep->pDecl)->identifier, (yyvaluep->pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", (yyvaluep->pDecl)->pointer_flag ? "*" : "", (yyvaluep->pDecl)->identifier);

      if ((yyvaluep->pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, (yyvaluep->pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
};

/* Line 724 of yacc.c  */
#line 2424 "ctlib/y_parser.c"
	break;
      default:
	break;
    }
}


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep)
#else
static void
yy_symbol_print (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
#endif
{
  if (yytype < YYNTOKENS)
    YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
  else
    YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);

  yy_symbol_value_print (yyoutput, yytype, yyvaluep);
  YYFPRINTF (yyoutput, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_stack_print (yytype_int16 *yybottom, yytype_int16 *yytop)
#else
static void
yy_stack_print (yybottom, yytop)
    yytype_int16 *yybottom;
    yytype_int16 *yytop;
#endif
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)				\
do {								\
  if (yydebug)							\
    yy_stack_print ((Bottom), (Top));				\
} while (YYID (0))


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_reduce_print (YYSTYPE *yyvsp, int yyrule)
#else
static void
yy_reduce_print (yyvsp, yyrule)
    YYSTYPE *yyvsp;
    int yyrule;
#endif
{
  int yynrhs = yyr2[yyrule];
  int yyi;
  unsigned long int yylno = yyrline[yyrule];
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %lu):\n",
	     yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr, yyrhs[yyprhs[yyrule] + yyi],
		       &(yyvsp[(yyi + 1) - (yynrhs)])
		       		       );
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)		\
do {					\
  if (yydebug)				\
    yy_reduce_print (yyvsp, Rule); \
} while (YYID (0))

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
# define YY_SYMBOL_PRINT(Title, Type, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef	YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif



#if YYERROR_VERBOSE

# ifndef yystrlen
#  if defined __GLIBC__ && defined _STRING_H
#   define yystrlen strlen
#  else
/* Return the length of YYSTR.  */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static YYSIZE_T
yystrlen (const char *yystr)
#else
static YYSIZE_T
yystrlen (yystr)
    const char *yystr;
#endif
{
  YYSIZE_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
#  endif
# endif

# ifndef yystpcpy
#  if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#   define yystpcpy stpcpy
#  else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static char *
yystpcpy (char *yydest, const char *yysrc)
#else
static char *
yystpcpy (yydest, yysrc)
    char *yydest;
    const char *yysrc;
#endif
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#  endif
# endif

# ifndef yytnamerr
/* Copy to YYRES the contents of YYSTR after stripping away unnecessary
   quotes and backslashes, so that it's suitable for yyerror.  The
   heuristic is that double-quoting is unnecessary unless the string
   contains an apostrophe, a comma, or backslash (other than
   backslash-backslash).  YYSTR is taken from yytname.  If YYRES is
   null, do not copy; instead, return the length of what the result
   would have been.  */
static YYSIZE_T
yytnamerr (char *yyres, const char *yystr)
{
  if (*yystr == '"')
    {
      YYSIZE_T yyn = 0;
      char const *yyp = yystr;

      for (;;)
	switch (*++yyp)
	  {
	  case '\'':
	  case ',':
	    goto do_not_strip_quotes;

	  case '\\':
	    if (*++yyp != '\\')
	      goto do_not_strip_quotes;
	    /* Fall through.  */
	  default:
	    if (yyres)
	      yyres[yyn] = *yyp;
	    yyn++;
	    break;

	  case '"':
	    if (yyres)
	      yyres[yyn] = '\0';
	    return yyn;
	  }
    do_not_strip_quotes: ;
    }

  if (! yyres)
    return yystrlen (yystr);

  return yystpcpy (yyres, yystr) - yyres;
}
# endif

/* Copy into YYRESULT an error message about the unexpected token
   YYCHAR while in state YYSTATE.  Return the number of bytes copied,
   including the terminating null byte.  If YYRESULT is null, do not
   copy anything; just return the number of bytes that would be
   copied.  As a special case, return 0 if an ordinary "syntax error"
   message will do.  Return YYSIZE_MAXIMUM if overflow occurs during
   size calculation.  */
static YYSIZE_T
yysyntax_error (char *yyresult, int yystate, int yychar)
{
  int yyn = yypact[yystate];

  if (! (YYPACT_NINF < yyn && yyn <= YYLAST))
    return 0;
  else
    {
      int yytype = YYTRANSLATE (yychar);
      YYSIZE_T yysize0 = yytnamerr (0, yytname[yytype]);
      YYSIZE_T yysize = yysize0;
      YYSIZE_T yysize1;
      int yysize_overflow = 0;
      enum { YYERROR_VERBOSE_ARGS_MAXIMUM = 5 };
      char const *yyarg[YYERROR_VERBOSE_ARGS_MAXIMUM];
      int yyx;

# if 0
      /* This is so xgettext sees the translatable formats that are
	 constructed on the fly.  */
      YY_("syntax error, unexpected %s");
      YY_("syntax error, unexpected %s, expecting %s");
      YY_("syntax error, unexpected %s, expecting %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s");
# endif
      char *yyfmt;
      char const *yyf;
      static char const yyunexpected[] = "syntax error, unexpected %s";
      static char const yyexpecting[] = ", expecting %s";
      static char const yyor[] = " or %s";
      char yyformat[sizeof yyunexpected
		    + sizeof yyexpecting - 1
		    + ((YYERROR_VERBOSE_ARGS_MAXIMUM - 2)
		       * (sizeof yyor - 1))];
      char const *yyprefix = yyexpecting;

      /* Start YYX at -YYN if negative to avoid negative indexes in
	 YYCHECK.  */
      int yyxbegin = yyn < 0 ? -yyn : 0;

      /* Stay within bounds of both yycheck and yytname.  */
      int yychecklim = YYLAST - yyn + 1;
      int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
      int yycount = 1;

      yyarg[0] = yytname[yytype];
      yyfmt = yystpcpy (yyformat, yyunexpected);

      for (yyx = yyxbegin; yyx < yyxend; ++yyx)
	if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
	  {
	    if (yycount == YYERROR_VERBOSE_ARGS_MAXIMUM)
	      {
		yycount = 1;
		yysize = yysize0;
		yyformat[sizeof yyunexpected - 1] = '\0';
		break;
	      }
	    yyarg[yycount++] = yytname[yyx];
	    yysize1 = yysize + yytnamerr (0, yytname[yyx]);
	    yysize_overflow |= (yysize1 < yysize);
	    yysize = yysize1;
	    yyfmt = yystpcpy (yyfmt, yyprefix);
	    yyprefix = yyor;
	  }

      yyf = YY_(yyformat);
      yysize1 = yysize + yystrlen (yyf);
      yysize_overflow |= (yysize1 < yysize);
      yysize = yysize1;

      if (yysize_overflow)
	return YYSIZE_MAXIMUM;

      if (yyresult)
	{
	  /* Avoid sprintf, as that infringes on the user's name space.
	     Don't have undefined behavior even if the translation
	     produced a string with the wrong number of "%s"s.  */
	  char *yyp = yyresult;
	  int yyi = 0;
	  while ((*yyp = *yyf) != '\0')
	    {
	      if (*yyp == '%' && yyf[1] == 's' && yyi < yycount)
		{
		  yyp += yytnamerr (yyp, yyarg[yyi++]);
		  yyf += 2;
		}
	      else
		{
		  yyp++;
		  yyf++;
		}
	    }
	}
      return yysize;
    }
}
#endif /* YYERROR_VERBOSE */


/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep)
#else
static void
yydestruct (yymsg, yytype, yyvaluep)
    const char *yymsg;
    int yytype;
    YYSTYPE *yyvaluep;
#endif
{
  YYUSE (yyvaluep);

  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

  switch (yytype)
    {
      case 64: /* "IDENTIFIER" */

/* Line 1009 of yacc.c  */
#line 414 "ctlib/parser.y"
	{
  if ((yyvaluep->identifier))
  {
    CT_DEBUG(PARSER, ("deleting node @ %p", (yyvaluep->identifier)));
    HN_delete((yyvaluep->identifier));
  }
};

/* Line 1009 of yacc.c  */
#line 2804 "ctlib/y_parser.c"
	break;
      case 150: /* "member_declaration_list_opt" */

/* Line 1009 of yacc.c  */
#line 562 "ctlib/parser.y"
	{
  if ((yyvaluep->list))
  {
    CT_DEBUG(PARSER, ("deleting struct declaration list @ %p", (yyvaluep->list)));
    LL_destroy((yyvaluep->list), (LLDestroyFunc) structdecl_delete);
  }
};

/* Line 1009 of yacc.c  */
#line 2819 "ctlib/y_parser.c"
	break;
      case 151: /* "member_declaration_list" */

/* Line 1009 of yacc.c  */
#line 562 "ctlib/parser.y"
	{
  if ((yyvaluep->list))
  {
    CT_DEBUG(PARSER, ("deleting struct declaration list @ %p", (yyvaluep->list)));
    LL_destroy((yyvaluep->list), (LLDestroyFunc) structdecl_delete);
  }
};

/* Line 1009 of yacc.c  */
#line 2834 "ctlib/y_parser.c"
	break;
      case 152: /* "member_declaration" */

/* Line 1009 of yacc.c  */
#line 459 "ctlib/parser.y"
	{
  if ((yyvaluep->pStructDecl))
  {
    CT_DEBUG(PARSER, ("deleting struct declaration @ %p", (yyvaluep->pStructDecl)));
    structdecl_delete((yyvaluep->pStructDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 2849 "ctlib/y_parser.c"
	break;
      case 153: /* "unnamed_su_declaration" */

/* Line 1009 of yacc.c  */
#line 459 "ctlib/parser.y"
	{
  if ((yyvaluep->pStructDecl))
  {
    CT_DEBUG(PARSER, ("deleting struct declaration @ %p", (yyvaluep->pStructDecl)));
    structdecl_delete((yyvaluep->pStructDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 2864 "ctlib/y_parser.c"
	break;
      case 154: /* "member_declaring_list" */

/* Line 1009 of yacc.c  */
#line 459 "ctlib/parser.y"
	{
  if ((yyvaluep->pStructDecl))
  {
    CT_DEBUG(PARSER, ("deleting struct declaration @ %p", (yyvaluep->pStructDecl)));
    structdecl_delete((yyvaluep->pStructDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 2879 "ctlib/y_parser.c"
	break;
      case 155: /* "member_declarator" */

/* Line 1009 of yacc.c  */
#line 483 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", (yyvaluep->pDecl)));
    decl_delete((yyvaluep->pDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 2894 "ctlib/y_parser.c"
	break;
      case 160: /* "enumerator_list" */

/* Line 1009 of yacc.c  */
#line 545 "ctlib/parser.y"
	{
  if ((yyvaluep->list))
  {
    CT_DEBUG(PARSER, ("deleting enumerator list @ %p", (yyvaluep->list)));
    LL_destroy((yyvaluep->list), (LLDestroyFunc) enum_delete);
  }
};

/* Line 1009 of yacc.c  */
#line 2909 "ctlib/y_parser.c"
	break;
      case 166: /* "identifier_or_typedef_name" */

/* Line 1009 of yacc.c  */
#line 414 "ctlib/parser.y"
	{
  if ((yyvaluep->identifier))
  {
    CT_DEBUG(PARSER, ("deleting node @ %p", (yyvaluep->identifier)));
    HN_delete((yyvaluep->identifier));
  }
};

/* Line 1009 of yacc.c  */
#line 2924 "ctlib/y_parser.c"
	break;
      case 203: /* "declarator" */

/* Line 1009 of yacc.c  */
#line 483 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", (yyvaluep->pDecl)));
    decl_delete((yyvaluep->pDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 2939 "ctlib/y_parser.c"
	break;
      case 204: /* "typedef_declarator" */

/* Line 1009 of yacc.c  */
#line 483 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", (yyvaluep->pDecl)));
    decl_delete((yyvaluep->pDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 2954 "ctlib/y_parser.c"
	break;
      case 205: /* "parameter_typedef_declarator" */

/* Line 1009 of yacc.c  */
#line 483 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", (yyvaluep->pDecl)));
    decl_delete((yyvaluep->pDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 2969 "ctlib/y_parser.c"
	break;
      case 206: /* "clean_typedef_declarator" */

/* Line 1009 of yacc.c  */
#line 483 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", (yyvaluep->pDecl)));
    decl_delete((yyvaluep->pDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 2984 "ctlib/y_parser.c"
	break;
      case 207: /* "clean_postfix_typedef_declarator" */

/* Line 1009 of yacc.c  */
#line 483 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", (yyvaluep->pDecl)));
    decl_delete((yyvaluep->pDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 2999 "ctlib/y_parser.c"
	break;
      case 208: /* "paren_typedef_declarator" */

/* Line 1009 of yacc.c  */
#line 483 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", (yyvaluep->pDecl)));
    decl_delete((yyvaluep->pDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 3014 "ctlib/y_parser.c"
	break;
      case 209: /* "paren_postfix_typedef_declarator" */

/* Line 1009 of yacc.c  */
#line 483 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", (yyvaluep->pDecl)));
    decl_delete((yyvaluep->pDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 3029 "ctlib/y_parser.c"
	break;
      case 210: /* "simple_paren_typedef_declarator" */

/* Line 1009 of yacc.c  */
#line 483 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", (yyvaluep->pDecl)));
    decl_delete((yyvaluep->pDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 3044 "ctlib/y_parser.c"
	break;
      case 211: /* "identifier_declarator" */

/* Line 1009 of yacc.c  */
#line 483 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", (yyvaluep->pDecl)));
    decl_delete((yyvaluep->pDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 3059 "ctlib/y_parser.c"
	break;
      case 212: /* "unary_identifier_declarator" */

/* Line 1009 of yacc.c  */
#line 483 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", (yyvaluep->pDecl)));
    decl_delete((yyvaluep->pDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 3074 "ctlib/y_parser.c"
	break;
      case 213: /* "postfix_identifier_declarator" */

/* Line 1009 of yacc.c  */
#line 483 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", (yyvaluep->pDecl)));
    decl_delete((yyvaluep->pDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 3089 "ctlib/y_parser.c"
	break;
      case 214: /* "paren_identifier_declarator" */

/* Line 1009 of yacc.c  */
#line 483 "ctlib/parser.y"
	{
  if ((yyvaluep->pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", (yyvaluep->pDecl)));
    decl_delete((yyvaluep->pDecl));
  }
};

/* Line 1009 of yacc.c  */
#line 3104 "ctlib/y_parser.c"
	break;
      case 218: /* "postfixing_abstract_declarator" */

/* Line 1009 of yacc.c  */
#line 553 "ctlib/parser.y"
	{
  if ((yyvaluep->list))
  {
    CT_DEBUG(PARSER, ("deleting array list @ %p", (yyvaluep->list)));
    LL_destroy((yyvaluep->list), (LLDestroyFunc) value_delete);
  }
};

/* Line 1009 of yacc.c  */
#line 3119 "ctlib/y_parser.c"
	break;
      case 219: /* "array_abstract_declarator" */

/* Line 1009 of yacc.c  */
#line 553 "ctlib/parser.y"
	{
  if ((yyvaluep->list))
  {
    CT_DEBUG(PARSER, ("deleting array list @ %p", (yyvaluep->list)));
    LL_destroy((yyvaluep->list), (LLDestroyFunc) value_delete);
  }
};

/* Line 1009 of yacc.c  */
#line 3134 "ctlib/y_parser.c"
	break;

      default:
	break;
    }
}

/* Prevent warnings from -Wmissing-prototypes.  */
#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int yyparse (void *YYPARSE_PARAM);
#else
int yyparse ();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int yyparse (void);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */





/*-------------------------.
| yyparse or yypush_parse.  |
`-------------------------*/

#ifdef YYPARSE_PARAM
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (void *YYPARSE_PARAM)
#else
int
yyparse (YYPARSE_PARAM)
    void *YYPARSE_PARAM;
#endif
#else /* ! YYPARSE_PARAM */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (void)
#else
int
yyparse ()

#endif
#endif
{
/* The lookahead symbol.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;

    /* Number of syntax errors so far.  */
    int yynerrs;

    int yystate;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus;

    /* The stacks and their tools:
       `yyss': related to states.
       `yyvs': related to semantic values.

       Refer to the stacks thru separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* The state stack.  */
    yytype_int16 yyssa[YYINITDEPTH];
    yytype_int16 *yyss;
    yytype_int16 *yyssp;

    /* The semantic value stack.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs;
    YYSTYPE *yyvsp;

    YYSIZE_T yystacksize;

  int yyn;
  int yyresult;
  /* Lookahead token as an internal (translated) token number.  */
  int yytoken;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;

#if YYERROR_VERBOSE
  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYSIZE_T yymsg_alloc = sizeof yymsgbuf;
#endif

#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  yytoken = 0;
  yyss = yyssa;
  yyvs = yyvsa;
  yystacksize = YYINITDEPTH;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY; /* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */
  yyssp = yyss;
  yyvsp = yyvs;

  goto yysetstate;

/*------------------------------------------------------------.
| yynewstate -- Push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
 yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;

 yysetstate:
  *yyssp = yystate;

  if (yyss + yystacksize - 1 <= yyssp)
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYSIZE_T yysize = yyssp - yyss + 1;

#ifdef yyoverflow
      {
	/* Give user a chance to reallocate the stack.  Use copies of
	   these so that the &'s don't force the real ones into
	   memory.  */
	YYSTYPE *yyvs1 = yyvs;
	yytype_int16 *yyss1 = yyss;

	/* Each stack pointer address is followed by the size of the
	   data in use in that stack, in bytes.  This used to be a
	   conditional around just the two extra args, but that might
	   be undefined if yyoverflow is a macro.  */
	yyoverflow (YY_("memory exhausted"),
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),
		    &yystacksize);

	yyss = yyss1;
	yyvs = yyvs1;
      }
#else /* no yyoverflow */
# ifndef YYSTACK_RELOCATE
      goto yyexhaustedlab;
# else
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
	goto yyexhaustedlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
	yystacksize = YYMAXDEPTH;

      {
	yytype_int16 *yyss1 = yyss;
	union yyalloc *yyptr =
	  (union yyalloc *) YYSTACK_ALLOC (YYSTACK_BYTES (yystacksize));
	if (! yyptr)
	  goto yyexhaustedlab;
	YYSTACK_RELOCATE (yyss_alloc, yyss);
	YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
	if (yyss1 != yyssa)
	  YYSTACK_FREE (yyss1);
      }
# endif
#endif /* no yyoverflow */

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YYDPRINTF ((stderr, "Stack size increased to %lu\n",
		  (unsigned long int) yystacksize));

      if (yyss + yystacksize - 1 <= yyssp)
	YYABORT;
    }

  YYDPRINTF ((stderr, "Entering state %d\n", yystate));

  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;

/*-----------.
| yybackup.  |
`-----------*/
yybackup:

  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yyn == YYPACT_NINF)
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either YYEMPTY or YYEOF or a valid lookahead symbol.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = YYLEX;
    }

  if (yychar <= YYEOF)
    {
      yychar = yytoken = YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yyn == 0 || yyn == YYTABLE_NINF)
	goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);

  /* Discard the shifted token.  */
  yychar = YYEMPTY;

  yystate = yyn;
  *++yyvsp = yylval;

  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- Do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     `$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
        case 3:

/* Line 1464 of yacc.c  */
#line 621 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (2)].value), +, (yyvsp[(2) - (2)].value)); ;}
    break;

  case 17:

/* Line 1464 of yacc.c  */
#line 666 "ctlib/parser.y"
    {
	    if ((yyvsp[(2) - (7)].identifier))
	      HN_delete((yyvsp[(2) - (7)].identifier));
	  ;}
    break;

  case 20:

/* Line 1464 of yacc.c  */
#line 680 "ctlib/parser.y"
    {
	    UNDEF_VAL((yyval.value));
	    if ((yyvsp[(1) - (1)].identifier))
	    {
	      Enumerator *pEnum = HT_get(PSTATE->pCPI->htEnumerators,
	                                 (yyvsp[(1) - (1)].identifier)->key, (yyvsp[(1) - (1)].identifier)->keylen, (yyvsp[(1) - (1)].identifier)->hash);
	      if (pEnum)
	      {
	        CT_DEBUG(CLEXER, ("enum found!"));
	        (yyval.value) = pEnum->value;
	      }
	      HN_delete((yyvsp[(1) - (1)].identifier));
	    }
	  ;}
    break;

  case 22:

/* Line 1464 of yacc.c  */
#line 695 "ctlib/parser.y"
    { (yyval.value) = (yyvsp[(1) - (1)].value); (yyval.value).iv++; ;}
    break;

  case 23:

/* Line 1464 of yacc.c  */
#line 696 "ctlib/parser.y"
    { (yyval.value) = (yyvsp[(2) - (3)].value); ;}
    break;

  case 25:

/* Line 1464 of yacc.c  */
#line 707 "ctlib/parser.y"
    { UNDEF_VAL((yyval.value)); ;}
    break;

  case 26:

/* Line 1464 of yacc.c  */
#line 708 "ctlib/parser.y"
    { UNDEF_VAL((yyval.value)); ;}
    break;

  case 27:

/* Line 1464 of yacc.c  */
#line 709 "ctlib/parser.y"
    { UNDEF_VAL((yyval.value)); ;}
    break;

  case 28:

/* Line 1464 of yacc.c  */
#line 710 "ctlib/parser.y"
    {;}
    break;

  case 29:

/* Line 1464 of yacc.c  */
#line 710 "ctlib/parser.y"
    { UNDEF_VAL((yyval.value)); ;}
    break;

  case 30:

/* Line 1464 of yacc.c  */
#line 711 "ctlib/parser.y"
    {;}
    break;

  case 31:

/* Line 1464 of yacc.c  */
#line 711 "ctlib/parser.y"
    { UNDEF_VAL((yyval.value)); ;}
    break;

  case 32:

/* Line 1464 of yacc.c  */
#line 712 "ctlib/parser.y"
    { UNDEF_VAL((yyval.value)); ;}
    break;

  case 33:

/* Line 1464 of yacc.c  */
#line 713 "ctlib/parser.y"
    { UNDEF_VAL((yyval.value)); ;}
    break;

  case 34:

/* Line 1464 of yacc.c  */
#line 714 "ctlib/parser.y"
    { UNDEF_VAL((yyval.value)); ;}
    break;

  case 35:

/* Line 1464 of yacc.c  */
#line 718 "ctlib/parser.y"
    { if((yyvsp[(1) - (1)].identifier)) HN_delete((yyvsp[(1) - (1)].identifier)); ;}
    break;

  case 36:

/* Line 1464 of yacc.c  */
#line 719 "ctlib/parser.y"
    {;}
    break;

  case 37:

/* Line 1464 of yacc.c  */
#line 723 "ctlib/parser.y"
    {;}
    break;

  case 38:

/* Line 1464 of yacc.c  */
#line 724 "ctlib/parser.y"
    {;}
    break;

  case 40:

/* Line 1464 of yacc.c  */
#line 729 "ctlib/parser.y"
    { UNDEF_VAL((yyval.value)); ;}
    break;

  case 41:

/* Line 1464 of yacc.c  */
#line 730 "ctlib/parser.y"
    { UNDEF_VAL((yyval.value)); ;}
    break;

  case 42:

/* Line 1464 of yacc.c  */
#line 732 "ctlib/parser.y"
    {
	    switch( (yyvsp[(1) - (2)].oper) ) {
	      case '-' : UNARY_OP((yyval.value), -, (yyvsp[(2) - (2)].value)); break;
	      case '~' : UNARY_OP((yyval.value), ~, (yyvsp[(2) - (2)].value)); break;
	      case '!' : UNARY_OP((yyval.value), !, (yyvsp[(2) - (2)].value)); break;
	      case '+' : (yyval.value) = (yyvsp[(2) - (2)].value);             break;

	      case '*' :
	      case '&' :
	        (yyval.value) = (yyvsp[(2) - (2)].value); (yyval.value).flags |= V_IS_UNSAFE_PTROP;
	        break;

	      default:
	        UNDEF_VAL((yyval.value));
	        break;
	    }
	  ;}
    break;

  case 43:

/* Line 1464 of yacc.c  */
#line 749 "ctlib/parser.y"
    { (yyval.value) = (yyvsp[(2) - (2)].value); ;}
    break;

  case 44:

/* Line 1464 of yacc.c  */
#line 750 "ctlib/parser.y"
    { (yyval.value) = (yyvsp[(3) - (4)].value); ;}
    break;

  case 45:

/* Line 1464 of yacc.c  */
#line 754 "ctlib/parser.y"
    { (yyval.oper) = '&'; ;}
    break;

  case 46:

/* Line 1464 of yacc.c  */
#line 755 "ctlib/parser.y"
    { (yyval.oper) = '*'; ;}
    break;

  case 47:

/* Line 1464 of yacc.c  */
#line 756 "ctlib/parser.y"
    { (yyval.oper) = '+'; ;}
    break;

  case 48:

/* Line 1464 of yacc.c  */
#line 757 "ctlib/parser.y"
    { (yyval.oper) = '-'; ;}
    break;

  case 49:

/* Line 1464 of yacc.c  */
#line 758 "ctlib/parser.y"
    { (yyval.oper) = '~'; ;}
    break;

  case 50:

/* Line 1464 of yacc.c  */
#line 759 "ctlib/parser.y"
    { (yyval.oper) = '!'; ;}
    break;

  case 52:

/* Line 1464 of yacc.c  */
#line 764 "ctlib/parser.y"
    { (yyval.value) = (yyvsp[(4) - (4)].value); (yyval.value).flags |= V_IS_UNSAFE_CAST; ;}
    break;

  case 54:

/* Line 1464 of yacc.c  */
#line 770 "ctlib/parser.y"
    { BINARY_OP( (yyval.value), (yyvsp[(1) - (3)].value), *, (yyvsp[(3) - (3)].value) ); ;}
    break;

  case 55:

/* Line 1464 of yacc.c  */
#line 772 "ctlib/parser.y"
    {
	    if ((yyvsp[(3) - (3)].value).iv == 0)
	      UNDEF_VAL((yyval.value));
	    else
	      BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), /, (yyvsp[(3) - (3)].value));
	  ;}
    break;

  case 56:

/* Line 1464 of yacc.c  */
#line 779 "ctlib/parser.y"
    {
	    if ((yyvsp[(3) - (3)].value).iv == 0)
	      UNDEF_VAL((yyval.value));
	    else
	      BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), %, (yyvsp[(3) - (3)].value));
	  ;}
    break;

  case 58:

/* Line 1464 of yacc.c  */
#line 790 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), +, (yyvsp[(3) - (3)].value)); ;}
    break;

  case 59:

/* Line 1464 of yacc.c  */
#line 792 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), -, (yyvsp[(3) - (3)].value)); ;}
    break;

  case 61:

/* Line 1464 of yacc.c  */
#line 798 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), <<, (yyvsp[(3) - (3)].value)); ;}
    break;

  case 62:

/* Line 1464 of yacc.c  */
#line 800 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), >>, (yyvsp[(3) - (3)].value)); ;}
    break;

  case 64:

/* Line 1464 of yacc.c  */
#line 806 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), <,  (yyvsp[(3) - (3)].value)); ;}
    break;

  case 65:

/* Line 1464 of yacc.c  */
#line 808 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), >,  (yyvsp[(3) - (3)].value)); ;}
    break;

  case 66:

/* Line 1464 of yacc.c  */
#line 810 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), <=, (yyvsp[(3) - (3)].value)); ;}
    break;

  case 67:

/* Line 1464 of yacc.c  */
#line 812 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), >=, (yyvsp[(3) - (3)].value)); ;}
    break;

  case 69:

/* Line 1464 of yacc.c  */
#line 818 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), ==, (yyvsp[(3) - (3)].value)); ;}
    break;

  case 70:

/* Line 1464 of yacc.c  */
#line 820 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), !=, (yyvsp[(3) - (3)].value)); ;}
    break;

  case 72:

/* Line 1464 of yacc.c  */
#line 826 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), &, (yyvsp[(3) - (3)].value)); ;}
    break;

  case 74:

/* Line 1464 of yacc.c  */
#line 832 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), ^, (yyvsp[(3) - (3)].value)); ;}
    break;

  case 76:

/* Line 1464 of yacc.c  */
#line 838 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), |, (yyvsp[(3) - (3)].value)); ;}
    break;

  case 78:

/* Line 1464 of yacc.c  */
#line 844 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), &&, (yyvsp[(3) - (3)].value)); ;}
    break;

  case 80:

/* Line 1464 of yacc.c  */
#line 850 "ctlib/parser.y"
    { BINARY_OP((yyval.value), (yyvsp[(1) - (3)].value), ||, (yyvsp[(3) - (3)].value)); ;}
    break;

  case 82:

/* Line 1464 of yacc.c  */
#line 856 "ctlib/parser.y"
    { (yyval.value) = (yyvsp[(1) - (5)].value).iv ? (yyvsp[(3) - (5)].value) : (yyvsp[(5) - (5)].value); (yyval.value).flags |= (yyvsp[(1) - (5)].value).flags; ;}
    break;

  case 84:

/* Line 1464 of yacc.c  */
#line 861 "ctlib/parser.y"
    { UNDEF_VAL((yyval.value)); ;}
    break;

  case 85:

/* Line 1464 of yacc.c  */
#line 865 "ctlib/parser.y"
    {;}
    break;

  case 86:

/* Line 1464 of yacc.c  */
#line 866 "ctlib/parser.y"
    {;}
    break;

  case 87:

/* Line 1464 of yacc.c  */
#line 867 "ctlib/parser.y"
    {;}
    break;

  case 88:

/* Line 1464 of yacc.c  */
#line 868 "ctlib/parser.y"
    {;}
    break;

  case 89:

/* Line 1464 of yacc.c  */
#line 869 "ctlib/parser.y"
    {;}
    break;

  case 90:

/* Line 1464 of yacc.c  */
#line 870 "ctlib/parser.y"
    {;}
    break;

  case 91:

/* Line 1464 of yacc.c  */
#line 871 "ctlib/parser.y"
    {;}
    break;

  case 92:

/* Line 1464 of yacc.c  */
#line 872 "ctlib/parser.y"
    {;}
    break;

  case 93:

/* Line 1464 of yacc.c  */
#line 873 "ctlib/parser.y"
    {;}
    break;

  case 94:

/* Line 1464 of yacc.c  */
#line 874 "ctlib/parser.y"
    {;}
    break;

  case 95:

/* Line 1464 of yacc.c  */
#line 875 "ctlib/parser.y"
    {;}
    break;

  case 96:

/* Line 1464 of yacc.c  */
#line 879 "ctlib/parser.y"
    { UNDEF_VAL((yyval.value)); ;}
    break;

  case 99:

/* Line 1464 of yacc.c  */
#line 884 "ctlib/parser.y"
    { (yyval.value) = (yyvsp[(3) - (3)].value); ;}
    break;

  case 102:

/* Line 1464 of yacc.c  */
#line 894 "ctlib/parser.y"
    {;}
    break;

  case 103:

/* Line 1464 of yacc.c  */
#line 932 "ctlib/parser.y"
    {;}
    break;

  case 104:

/* Line 1464 of yacc.c  */
#line 933 "ctlib/parser.y"
    {;}
    break;

  case 105:

/* Line 1464 of yacc.c  */
#line 934 "ctlib/parser.y"
    {;}
    break;

  case 106:

/* Line 1464 of yacc.c  */
#line 935 "ctlib/parser.y"
    {;}
    break;

  case 107:

/* Line 1464 of yacc.c  */
#line 943 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.pTypedefList) = NULL;
	    else
	    {
	      if ((yyvsp[(1) - (4)].uval) & T_TYPEDEF)
	      {
	        TypeSpec ts;
	        ts.tflags = (yyvsp[(1) - (4)].uval);
	        ts.ptr    = NULL;
	        if ((ts.tflags & ANY_TYPE_NAME) == 0)
	          ts.tflags |= T_INT;
	        (yyval.pTypedefList) = typedef_list_new(ts, LL_new());
	        LL_push(PSTATE->pCPI->typedef_lists, (yyval.pTypedefList));
	        MAKE_TYPEDEF((yyval.pTypedefList), (yyvsp[(2) - (4)].pDecl));
	      }
	      else
	      {
	        (yyval.pTypedefList) = NULL;
	        decl_delete((yyvsp[(2) - (4)].pDecl));
	      }
	    }
	  ;}
    break;

  case 108:

/* Line 1464 of yacc.c  */
#line 967 "ctlib/parser.y"
    {
	    (yyval.pTypedefList) = NULL;
	    if ((yyvsp[(2) - (4)].pDecl))
	      decl_delete((yyvsp[(2) - (4)].pDecl));
	  ;}
    break;

  case 109:

/* Line 1464 of yacc.c  */
#line 973 "ctlib/parser.y"
    {
	    (yyval.pTypedefList) = (yyvsp[(1) - (5)].pTypedefList);
	    if ((yyval.pTypedefList))
	      MAKE_TYPEDEF((yyval.pTypedefList), (yyvsp[(3) - (5)].pDecl));
	    else if((yyvsp[(3) - (5)].pDecl))
	      decl_delete((yyvsp[(3) - (5)].pDecl));
	  ;}
    break;

  case 110:

/* Line 1464 of yacc.c  */
#line 984 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.pTypedefList) = NULL;
	    else
	    {
	      if ((yyvsp[(1) - (4)].tspec).tflags & T_TYPEDEF)
	      {
	        if (((yyvsp[(1) - (4)].tspec).tflags & ANY_TYPE_NAME) == 0)
	          (yyvsp[(1) - (4)].tspec).tflags |= T_INT;
	        ctt_refcount_inc((yyvsp[(1) - (4)].tspec).ptr);
	        (yyval.pTypedefList) = typedef_list_new((yyvsp[(1) - (4)].tspec), LL_new());
	        LL_push(PSTATE->pCPI->typedef_lists, (yyval.pTypedefList));
	        MAKE_TYPEDEF((yyval.pTypedefList), (yyvsp[(2) - (4)].pDecl));
	      }
	      else
	      {
	        (yyval.pTypedefList) = NULL;
	        decl_delete((yyvsp[(2) - (4)].pDecl));
	      }
	    }
	  ;}
    break;

  case 111:

/* Line 1464 of yacc.c  */
#line 1006 "ctlib/parser.y"
    {
	    (yyval.pTypedefList) = NULL;
	    if ((yyvsp[(2) - (4)].pDecl))
	      decl_delete((yyvsp[(2) - (4)].pDecl));
	  ;}
    break;

  case 112:

/* Line 1464 of yacc.c  */
#line 1012 "ctlib/parser.y"
    {
	    (yyval.pTypedefList) = (yyvsp[(1) - (5)].pTypedefList);
	    if ((yyval.pTypedefList))
	      MAKE_TYPEDEF((yyval.pTypedefList), (yyvsp[(3) - (5)].pDecl));
	    else if ((yyvsp[(3) - (5)].pDecl))
	      decl_delete((yyvsp[(3) - (5)].pDecl));
	  ;}
    break;

  case 113:

/* Line 1464 of yacc.c  */
#line 1024 "ctlib/parser.y"
    {
	    (yyval.tspec).ptr    = NULL;
	    (yyval.tspec).tflags = (yyvsp[(1) - (1)].uval);
	  ;}
    break;

  case 116:

/* Line 1464 of yacc.c  */
#line 1035 "ctlib/parser.y"
    {
	    (yyval.tspec).ptr    = NULL;
	    (yyval.tspec).tflags = (yyvsp[(1) - (1)].uval);
	  ;}
    break;

  case 120:

/* Line 1464 of yacc.c  */
#line 1047 "ctlib/parser.y"
    { (yyval.uval) = (yyvsp[(2) - (2)].uval);      ;}
    break;

  case 121:

/* Line 1464 of yacc.c  */
#line 1048 "ctlib/parser.y"
    { (yyval.uval) = (yyvsp[(1) - (2)].uval) | (yyvsp[(2) - (2)].uval); ;}
    break;

  case 127:

/* Line 1464 of yacc.c  */
#line 1063 "ctlib/parser.y"
    { (yyval.uval) = 0;  ;}
    break;

  case 131:

/* Line 1464 of yacc.c  */
#line 1073 "ctlib/parser.y"
    { (yyval.uval) = LLC_OR((yyvsp[(1) - (2)].uval), (yyvsp[(2) - (2)].uval)); ;}
    break;

  case 132:

/* Line 1464 of yacc.c  */
#line 1074 "ctlib/parser.y"
    { (yyval.uval) = LLC_OR((yyvsp[(1) - (2)].uval), (yyvsp[(2) - (2)].uval)); ;}
    break;

  case 133:

/* Line 1464 of yacc.c  */
#line 1075 "ctlib/parser.y"
    { (yyval.uval) = LLC_OR((yyvsp[(1) - (2)].uval), (yyvsp[(2) - (2)].uval)); ;}
    break;

  case 134:

/* Line 1464 of yacc.c  */
#line 1076 "ctlib/parser.y"
    { (yyval.uval) = LLC_OR((yyvsp[(1) - (2)].uval), (yyvsp[(2) - (2)].uval)); ;}
    break;

  case 136:

/* Line 1464 of yacc.c  */
#line 1081 "ctlib/parser.y"
    { (yyval.uval) = (yyvsp[(2) - (2)].uval);             ;}
    break;

  case 137:

/* Line 1464 of yacc.c  */
#line 1082 "ctlib/parser.y"
    { (yyval.uval) = (yyvsp[(1) - (2)].uval);             ;}
    break;

  case 138:

/* Line 1464 of yacc.c  */
#line 1083 "ctlib/parser.y"
    { (yyval.uval) = LLC_OR((yyvsp[(1) - (2)].uval), (yyvsp[(2) - (2)].uval)); ;}
    break;

  case 139:

/* Line 1464 of yacc.c  */
#line 1088 "ctlib/parser.y"
    {
	    (yyval.tspec).ptr    = (yyvsp[(2) - (2)].tspec).ptr;
	    (yyval.tspec).tflags = (yyvsp[(2) - (2)].tspec).tflags | (yyvsp[(1) - (2)].uval);
	  ;}
    break;

  case 140:

/* Line 1464 of yacc.c  */
#line 1093 "ctlib/parser.y"
    {
	    (yyval.tspec).ptr    = (yyvsp[(1) - (2)].tspec).ptr;
	    (yyval.tspec).tflags = (yyvsp[(1) - (2)].tspec).tflags | (yyvsp[(2) - (2)].uval);
	  ;}
    break;

  case 141:

/* Line 1464 of yacc.c  */
#line 1098 "ctlib/parser.y"
    {
	    (yyval.tspec).ptr    = (yyvsp[(1) - (2)].tspec).ptr;
	    (yyval.tspec).tflags = (yyvsp[(1) - (2)].tspec).tflags | (yyvsp[(2) - (2)].uval);
	  ;}
    break;

  case 145:

/* Line 1464 of yacc.c  */
#line 1111 "ctlib/parser.y"
    { (yyval.tspec) = (yyvsp[(2) - (2)].tspec); ;}
    break;

  case 146:

/* Line 1464 of yacc.c  */
#line 1112 "ctlib/parser.y"
    { (yyval.tspec) = (yyvsp[(1) - (2)].tspec); ;}
    break;

  case 148:

/* Line 1464 of yacc.c  */
#line 1117 "ctlib/parser.y"
    { (yyval.tspec) = (yyvsp[(2) - (2)].tspec); ;}
    break;

  case 149:

/* Line 1464 of yacc.c  */
#line 1118 "ctlib/parser.y"
    { (yyval.tspec) = (yyvsp[(1) - (2)].tspec); ;}
    break;

  case 152:

/* Line 1464 of yacc.c  */
#line 1127 "ctlib/parser.y"
    {
	    (yyval.tspec).ptr    = (yyvsp[(1) - (2)].tspec).ptr;
	    (yyval.tspec).tflags = (yyvsp[(1) - (2)].tspec).tflags | (yyvsp[(2) - (2)].uval);
	  ;}
    break;

  case 153:

/* Line 1464 of yacc.c  */
#line 1132 "ctlib/parser.y"
    {
	    (yyval.tspec).ptr    = (yyvsp[(2) - (2)].pTypedef);
	    (yyval.tspec).tflags = T_TYPE | (yyvsp[(1) - (2)].uval);
	  ;}
    break;

  case 154:

/* Line 1464 of yacc.c  */
#line 1137 "ctlib/parser.y"
    {
	    (yyval.tspec).ptr    = (yyvsp[(1) - (2)].tspec).ptr;
	    (yyval.tspec).tflags = (yyvsp[(1) - (2)].tspec).tflags | (yyvsp[(2) - (2)].uval);
	  ;}
    break;

  case 155:

/* Line 1464 of yacc.c  */
#line 1144 "ctlib/parser.y"
    { (yyval.tspec).ptr = (yyvsp[(1) - (1)].pTypedef); (yyval.tspec).tflags = T_TYPE; ;}
    break;

  case 156:

/* Line 1464 of yacc.c  */
#line 1145 "ctlib/parser.y"
    { (yyval.tspec).ptr = (yyvsp[(2) - (2)].pTypedef); (yyval.tspec).tflags = T_TYPE; ;}
    break;

  case 157:

/* Line 1464 of yacc.c  */
#line 1146 "ctlib/parser.y"
    { (yyval.tspec) = (yyvsp[(1) - (2)].tspec);                         ;}
    break;

  case 158:

/* Line 1464 of yacc.c  */
#line 1150 "ctlib/parser.y"
    { (yyval.uval) = T_TYPEDEF;  ;}
    break;

  case 159:

/* Line 1464 of yacc.c  */
#line 1151 "ctlib/parser.y"
    { (yyval.uval) = 0;          ;}
    break;

  case 160:

/* Line 1464 of yacc.c  */
#line 1152 "ctlib/parser.y"
    { (yyval.uval) = 0;          ;}
    break;

  case 161:

/* Line 1464 of yacc.c  */
#line 1153 "ctlib/parser.y"
    { (yyval.uval) = 0;          ;}
    break;

  case 162:

/* Line 1464 of yacc.c  */
#line 1154 "ctlib/parser.y"
    { (yyval.uval) = 0;          ;}
    break;

  case 163:

/* Line 1464 of yacc.c  */
#line 1155 "ctlib/parser.y"
    { (yyval.uval) = 0;          ;}
    break;

  case 164:

/* Line 1464 of yacc.c  */
#line 1159 "ctlib/parser.y"
    { (yyval.uval) = T_INT;      ;}
    break;

  case 165:

/* Line 1464 of yacc.c  */
#line 1160 "ctlib/parser.y"
    { (yyval.uval) = T_CHAR;     ;}
    break;

  case 166:

/* Line 1464 of yacc.c  */
#line 1161 "ctlib/parser.y"
    { (yyval.uval) = T_SHORT;    ;}
    break;

  case 167:

/* Line 1464 of yacc.c  */
#line 1162 "ctlib/parser.y"
    { (yyval.uval) = T_LONG;     ;}
    break;

  case 168:

/* Line 1464 of yacc.c  */
#line 1163 "ctlib/parser.y"
    { (yyval.uval) = T_FLOAT;    ;}
    break;

  case 169:

/* Line 1464 of yacc.c  */
#line 1164 "ctlib/parser.y"
    { (yyval.uval) = T_DOUBLE;   ;}
    break;

  case 170:

/* Line 1464 of yacc.c  */
#line 1165 "ctlib/parser.y"
    { (yyval.uval) = T_SIGNED;   ;}
    break;

  case 171:

/* Line 1464 of yacc.c  */
#line 1166 "ctlib/parser.y"
    { (yyval.uval) = T_UNSIGNED; ;}
    break;

  case 172:

/* Line 1464 of yacc.c  */
#line 1167 "ctlib/parser.y"
    { (yyval.uval) = T_VOID;     ;}
    break;

  case 175:

/* Line 1464 of yacc.c  */
#line 1177 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	    {
	      (yyval.tspec).tflags = 0;
	      (yyval.tspec).ptr = NULL;
	    }
	    else
	    {
	      Struct *pStruct;
	      pStruct = struct_new(NULL, 0, (yyvsp[(1) - (4)].context).uval, pragma_parser_get_pack(PSTATE->pragma), (yyvsp[(3) - (4)].list));
	      pStruct->context = (yyvsp[(1) - (4)].context).ctx;
	      LL_push(PSTATE->pCPI->structs, pStruct);
	      (yyval.tspec).tflags = (yyvsp[(1) - (4)].context).uval;
	      (yyval.tspec).ptr = pStruct;
	    }
	  ;}
    break;

  case 176:

/* Line 1464 of yacc.c  */
#line 1194 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	    {
	      (yyval.tspec).tflags = 0;
	      (yyval.tspec).ptr = NULL;
	      /* identifier_or_typedef_name is NULL */
	    }
	    else
	    {
	      Struct *pStruct = HT_get(PSTATE->pCPI->htStructs, (yyvsp[(2) - (5)].identifier)->key, (yyvsp[(2) - (5)].identifier)->keylen, (yyvsp[(2) - (5)].identifier)->hash);

	      if (pStruct == NULL)
	      {
	        pStruct = struct_new((yyvsp[(2) - (5)].identifier)->key, (yyvsp[(2) - (5)].identifier)->keylen, (yyvsp[(1) - (5)].context).uval, pragma_parser_get_pack(PSTATE->pragma), (yyvsp[(4) - (5)].list));
	        pStruct->context = (yyvsp[(1) - (5)].context).ctx;
	        LL_push(PSTATE->pCPI->structs, pStruct);
	        HT_storenode(PSTATE->pCPI->htStructs, (yyvsp[(2) - (5)].identifier), pStruct);
	      }
	      else
	      {
	        DELETE_NODE((yyvsp[(2) - (5)].identifier));

	        if (pStruct->declarations == NULL)
	        {
	          pStruct->context      = (yyvsp[(1) - (5)].context).ctx;
	          pStruct->declarations = (yyvsp[(4) - (5)].list);
	          pStruct->pack         = pragma_parser_get_pack(PSTATE->pragma);
	        }
	        else
	          LL_destroy((yyvsp[(4) - (5)].list), (LLDestroyFunc) structdecl_delete);
	      }
	      (yyval.tspec).tflags = (yyvsp[(1) - (5)].context).uval;
	      (yyval.tspec).ptr = pStruct;
	    }
	  ;}
    break;

  case 177:

/* Line 1464 of yacc.c  */
#line 1230 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	    {
	      (yyval.tspec).tflags = 0;
	      (yyval.tspec).ptr = NULL;
	      /* identifier_or_typedef_name is NULL */
	    }
	    else
	    {
	      Struct *pStruct = HT_get(PSTATE->pCPI->htStructs, (yyvsp[(2) - (2)].identifier)->key, (yyvsp[(2) - (2)].identifier)->keylen, (yyvsp[(2) - (2)].identifier)->hash);

	      if (pStruct == NULL)
	      {
	        pStruct = struct_new((yyvsp[(2) - (2)].identifier)->key, (yyvsp[(2) - (2)].identifier)->keylen, (yyvsp[(1) - (2)].context).uval, 0, NULL);
	        pStruct->context = (yyvsp[(1) - (2)].context).ctx;
	        LL_push(PSTATE->pCPI->structs, pStruct);
	        HT_storenode(PSTATE->pCPI->htStructs, (yyvsp[(2) - (2)].identifier), pStruct);
	      }
	      else
	        DELETE_NODE((yyvsp[(2) - (2)].identifier));

	      (yyval.tspec).tflags = (yyvsp[(1) - (2)].context).uval;
	      (yyval.tspec).ptr = pStruct;
	    }
	  ;}
    break;

  case 178:

/* Line 1464 of yacc.c  */
#line 1259 "ctlib/parser.y"
    {
	    (yyval.context).uval     = (yyvsp[(1) - (1)].uval);
	    (yyval.context).ctx.pFI  = PSTATE->pFI;
	    (yyval.context).ctx.line = PSTATE->pLexer->ctok->line;
	  ;}
    break;

  case 179:

/* Line 1464 of yacc.c  */
#line 1267 "ctlib/parser.y"
    { (yyval.uval) = T_STRUCT; ;}
    break;

  case 180:

/* Line 1464 of yacc.c  */
#line 1268 "ctlib/parser.y"
    { (yyval.uval) = T_UNION;  ;}
    break;

  case 181:

/* Line 1464 of yacc.c  */
#line 1272 "ctlib/parser.y"
    { (yyval.list) = IS_LOCAL ? NULL : LL_new(); ;}
    break;

  case 183:

/* Line 1464 of yacc.c  */
#line 1278 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      ctt_refcount_inc((yyvsp[(1) - (1)].pStructDecl)->type.ptr);
	      (yyval.list) = LL_new();
	      LL_push((yyval.list), (yyvsp[(1) - (1)].pStructDecl));
	    }
	  ;}
    break;

  case 184:

/* Line 1464 of yacc.c  */
#line 1289 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      ctt_refcount_inc((yyvsp[(2) - (2)].pStructDecl)->type.ptr);
	      (yyval.list) = (yyvsp[(1) - (2)].list);
	      LL_push((yyval.list), (yyvsp[(2) - (2)].pStructDecl));
	    }
	  ;}
    break;

  case 187:

/* Line 1464 of yacc.c  */
#line 1307 "ctlib/parser.y"
    { (yyval.pStructDecl) = IS_LOCAL ? NULL : structdecl_new((yyvsp[(1) - (1)].tspec), NULL); ;}
    break;

  case 188:

/* Line 1464 of yacc.c  */
#line 1312 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.pStructDecl) = NULL;
	    else
	    {
	      if (((yyvsp[(1) - (2)].tspec).tflags & ANY_TYPE_NAME) == 0)
	        (yyvsp[(1) - (2)].tspec).tflags |= T_INT;
	      (yyval.pStructDecl) = structdecl_new((yyvsp[(1) - (2)].tspec), LL_new());
	      if ((yyvsp[(2) - (2)].pDecl))
	        LL_push((yyval.pStructDecl)->declarators, (yyvsp[(2) - (2)].pDecl));
	    }
	  ;}
    break;

  case 189:

/* Line 1464 of yacc.c  */
#line 1325 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.pStructDecl) = NULL;
	    else
	    {
	      (yyval.pStructDecl) = (yyvsp[(1) - (3)].pStructDecl);
	      if ((yyvsp[(3) - (3)].pDecl))
	        LL_push((yyval.pStructDecl)->declarators, (yyvsp[(3) - (3)].pDecl));
	    }
	  ;}
    break;

  case 190:

/* Line 1464 of yacc.c  */
#line 1339 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.pDecl) = NULL;
	    else
	    {
	      (yyval.pDecl) = (yyvsp[(1) - (2)].pDecl);

	      if (((yyvsp[(2) - (2)].value).flags & V_IS_UNDEF) == 0)
	      {
	        if ((yyvsp[(2) - (2)].value).iv <= 0)
	        {
	          char *msg;
	          AllocF(char *, msg, 80 + CTT_IDLEN((yyvsp[(1) - (2)].pDecl)));
	          sprintf(msg, "%s width for bit-field '%s'",
	                  (yyvsp[(2) - (2)].value).iv < 0 ? "negative" : "zero", (yyvsp[(1) - (2)].pDecl)->identifier);
	          decl_delete((yyvsp[(1) - (2)].pDecl));
	          yyerror(msg);
	          Free(msg);
	          YYERROR;
	        }

	        (yyval.pDecl)->bitfield_flag = 1;
	        (yyval.pDecl)->ext.bitfield.bits = (unsigned char) (yyvsp[(2) - (2)].value).iv;
	      }
	    }
	  ;}
    break;

  case 191:

/* Line 1464 of yacc.c  */
#line 1366 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.pDecl) = NULL;
	    else
	    {
	      if ((yyvsp[(1) - (1)].value).iv < 0)
	      {
	        yyerror("negative width for bit-field");
	        YYERROR;
	      }

	      (yyval.pDecl) = decl_new("", 0);
	      (yyval.pDecl)->bitfield_flag = 1;
	      (yyval.pDecl)->ext.bitfield.bits = (unsigned char) (yyvsp[(1) - (1)].value).iv;
	    }
	  ;}
    break;

  case 192:

/* Line 1464 of yacc.c  */
#line 1385 "ctlib/parser.y"
    { UNDEF_VAL((yyval.value)); ;}
    break;

  case 194:

/* Line 1464 of yacc.c  */
#line 1390 "ctlib/parser.y"
    { (yyval.value) = (yyvsp[(2) - (2)].value); ;}
    break;

  case 195:

/* Line 1464 of yacc.c  */
#line 1395 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	    {
	      (yyval.tspec).tflags = 0;
	      (yyval.tspec).ptr = NULL;
	      LL_destroy((yyvsp[(3) - (5)].list), (LLDestroyFunc) enum_delete);
	    }
	    else
	    {
	      EnumSpecifier *pEnum = enumspec_new(NULL, 0, (yyvsp[(3) - (5)].list));
	      pEnum->context = (yyvsp[(1) - (5)].context).ctx;
	      LL_push(PSTATE->pCPI->enums, pEnum);
	      (yyval.tspec).tflags = T_ENUM;
	      (yyval.tspec).ptr = pEnum;
	    }
	  ;}
    break;

  case 196:

/* Line 1464 of yacc.c  */
#line 1412 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	    {
	      (yyval.tspec).tflags = 0;
	      (yyval.tspec).ptr = NULL;
	      /* identifier_or_typedef_name is NULL */
	    }
	    else
	    {
	      EnumSpecifier *pEnum = HT_get(PSTATE->pCPI->htEnums, (yyvsp[(2) - (6)].identifier)->key, (yyvsp[(2) - (6)].identifier)->keylen, (yyvsp[(2) - (6)].identifier)->hash);

	      if (pEnum == NULL)
	      {
	        pEnum = enumspec_new((yyvsp[(2) - (6)].identifier)->key, (yyvsp[(2) - (6)].identifier)->keylen, (yyvsp[(4) - (6)].list));
	        pEnum->context = (yyvsp[(1) - (6)].context).ctx;
	        LL_push(PSTATE->pCPI->enums, pEnum);
	        HT_storenode(PSTATE->pCPI->htEnums, (yyvsp[(2) - (6)].identifier), pEnum);
	      }
	      else
	      {
	        DELETE_NODE((yyvsp[(2) - (6)].identifier));

	        if (pEnum->enumerators == NULL)
	        {
	          enumspec_update(pEnum, (yyvsp[(4) - (6)].list));
	          pEnum->context = (yyvsp[(1) - (6)].context).ctx;
	        }
	        else
	          LL_destroy((yyvsp[(4) - (6)].list), (LLDestroyFunc) enum_delete);
	      }

	      (yyval.tspec).tflags = T_ENUM;
	      (yyval.tspec).ptr = pEnum;
	    }
	  ;}
    break;

  case 197:

/* Line 1464 of yacc.c  */
#line 1448 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	    {
	      (yyval.tspec).tflags = 0;
	      (yyval.tspec).ptr = NULL;
	      /* identifier_or_typedef_name is NULL */
	    }
	    else
	    {
	      EnumSpecifier *pEnum = HT_get(PSTATE->pCPI->htEnums, (yyvsp[(2) - (2)].identifier)->key, (yyvsp[(2) - (2)].identifier)->keylen, (yyvsp[(2) - (2)].identifier)->hash);

	      if (pEnum == NULL)
	      {
	        pEnum = enumspec_new((yyvsp[(2) - (2)].identifier)->key, (yyvsp[(2) - (2)].identifier)->keylen, NULL);
	        pEnum->context = (yyvsp[(1) - (2)].context).ctx;
	        LL_push(PSTATE->pCPI->enums, pEnum);
	        HT_storenode(PSTATE->pCPI->htEnums, (yyvsp[(2) - (2)].identifier), pEnum);
	      }
	      else
	      {
	        DELETE_NODE((yyvsp[(2) - (2)].identifier));
	      }

	      (yyval.tspec).tflags = T_ENUM;
	      (yyval.tspec).ptr = pEnum;
	    }
	  ;}
    break;

  case 198:

/* Line 1464 of yacc.c  */
#line 1479 "ctlib/parser.y"
    {
	    (yyval.context).ctx.pFI  = PSTATE->pFI;
	    (yyval.context).ctx.line = PSTATE->pLexer->ctok->line;
	  ;}
    break;

  case 199:

/* Line 1464 of yacc.c  */
#line 1487 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      (yyval.list) = LL_new();
	      if ((yyvsp[(1) - (1)].pEnum)->value.flags & V_IS_UNDEF)
	      {
	        (yyvsp[(1) - (1)].pEnum)->value.flags &= ~V_IS_UNDEF;
	        (yyvsp[(1) - (1)].pEnum)->value.iv     = 0;
	      }
	      LL_push((yyval.list), (yyvsp[(1) - (1)].pEnum));
	    }
	  ;}
    break;

  case 200:

/* Line 1464 of yacc.c  */
#line 1502 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      if ((yyvsp[(3) - (3)].pEnum)->value.flags & V_IS_UNDEF)
	      {
	        Enumerator *pEnum = LL_get((yyvsp[(1) - (3)].list), -1);
	        (yyvsp[(3) - (3)].pEnum)->value.flags = pEnum->value.flags;
	        (yyvsp[(3) - (3)].pEnum)->value.iv    = pEnum->value.iv + 1;
	      }
	      LL_push((yyvsp[(1) - (3)].list), (yyvsp[(3) - (3)].pEnum));
	      (yyval.list) = (yyvsp[(1) - (3)].list);
	    }
	  ;}
    break;

  case 201:

/* Line 1464 of yacc.c  */
#line 1521 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	    {
	      (yyval.pEnum) = NULL;
	      /* identifier_or_typedef_name is NULL */
	    }
	    else
	    {
	      (yyval.pEnum) = enum_new((yyvsp[(1) - (1)].identifier)->key, (yyvsp[(1) - (1)].identifier)->keylen, NULL);
	      HT_storenode(PSTATE->pCPI->htEnumerators, (yyvsp[(1) - (1)].identifier), (yyval.pEnum));
	    }
	  ;}
    break;

  case 202:

/* Line 1464 of yacc.c  */
#line 1534 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	    {
	      (yyval.pEnum) = NULL;
	      /* identifier_or_typedef_name is NULL */
	    }
	    else
	    {
	      (yyval.pEnum) = enum_new((yyvsp[(1) - (3)].identifier)->key, (yyvsp[(1) - (3)].identifier)->keylen, &(yyvsp[(3) - (3)].value));
	      HT_storenode(PSTATE->pCPI->htEnumerators, (yyvsp[(1) - (3)].identifier), (yyval.pEnum));
	    }
	  ;}
    break;

  case 207:

/* Line 1464 of yacc.c  */
#line 1559 "ctlib/parser.y"
    {;}
    break;

  case 208:

/* Line 1464 of yacc.c  */
#line 1560 "ctlib/parser.y"
    {;}
    break;

  case 209:

/* Line 1464 of yacc.c  */
#line 1561 "ctlib/parser.y"
    { if ((yyvsp[(2) - (2)].pDecl)) decl_delete((yyvsp[(2) - (2)].pDecl)); ;}
    break;

  case 210:

/* Line 1464 of yacc.c  */
#line 1562 "ctlib/parser.y"
    { if ((yyvsp[(2) - (2)].pDecl)) decl_delete((yyvsp[(2) - (2)].pDecl)); ;}
    break;

  case 211:

/* Line 1464 of yacc.c  */
#line 1563 "ctlib/parser.y"
    {;}
    break;

  case 212:

/* Line 1464 of yacc.c  */
#line 1564 "ctlib/parser.y"
    {;}
    break;

  case 213:

/* Line 1464 of yacc.c  */
#line 1565 "ctlib/parser.y"
    { if ((yyvsp[(2) - (2)].pDecl)) decl_delete((yyvsp[(2) - (2)].pDecl)); ;}
    break;

  case 214:

/* Line 1464 of yacc.c  */
#line 1566 "ctlib/parser.y"
    {;}
    break;

  case 215:

/* Line 1464 of yacc.c  */
#line 1567 "ctlib/parser.y"
    {;}
    break;

  case 216:

/* Line 1464 of yacc.c  */
#line 1568 "ctlib/parser.y"
    { if ((yyvsp[(2) - (2)].pDecl)) decl_delete((yyvsp[(2) - (2)].pDecl)); ;}
    break;

  case 217:

/* Line 1464 of yacc.c  */
#line 1569 "ctlib/parser.y"
    { if ((yyvsp[(2) - (2)].pDecl)) decl_delete((yyvsp[(2) - (2)].pDecl)); ;}
    break;

  case 218:

/* Line 1464 of yacc.c  */
#line 1570 "ctlib/parser.y"
    {;}
    break;

  case 219:

/* Line 1464 of yacc.c  */
#line 1571 "ctlib/parser.y"
    {;}
    break;

  case 220:

/* Line 1464 of yacc.c  */
#line 1572 "ctlib/parser.y"
    { if ((yyvsp[(2) - (2)].pDecl)) decl_delete((yyvsp[(2) - (2)].pDecl)); ;}
    break;

  case 221:

/* Line 1464 of yacc.c  */
#line 1580 "ctlib/parser.y"
    { if ((yyvsp[(1) - (1)].identifier)) HN_delete((yyvsp[(1) - (1)].identifier)); ;}
    break;

  case 222:

/* Line 1464 of yacc.c  */
#line 1581 "ctlib/parser.y"
    { if ((yyvsp[(3) - (3)].identifier)) HN_delete((yyvsp[(3) - (3)].identifier)); ;}
    break;

  case 224:

/* Line 1464 of yacc.c  */
#line 1587 "ctlib/parser.y"
    {
	    (yyval.identifier) = IS_LOCAL ? NULL : HN_new((yyvsp[(1) - (1)].pTypedef)->pDecl->identifier, CTT_IDLEN((yyvsp[(1) - (1)].pTypedef)->pDecl), 0);
	  ;}
    break;

  case 225:

/* Line 1464 of yacc.c  */
#line 1594 "ctlib/parser.y"
    {
	    if (!IS_LOCAL)
	    {
	      unsigned size;
	      u_32 flags;
	      (void) PSTATE->pCPC->get_type_info(&PSTATE->pCPC->layout, &(yyvsp[(1) - (1)].tspec), NULL, "sf", &size, &flags);
	      (yyval.value).iv    = size;
	      (yyval.value).flags = 0;
	      if (flags & T_UNSAFE_VAL)
	        (yyval.value).flags |= V_IS_UNSAFE;
	    }
	  ;}
    break;

  case 226:

/* Line 1464 of yacc.c  */
#line 1607 "ctlib/parser.y"
    {
	    if (!IS_LOCAL)
	    {
	      if ((yyvsp[(2) - (2)].absDecl).pointer_flag)
	      {
	        (yyval.value).iv = PSTATE->pCPC->layout.ptr_size * (yyvsp[(2) - (2)].absDecl).multiplicator;
	        (yyval.value).flags = 0;
	      }
	      else
	      {
	        unsigned size;
	        u_32 flags;
	        (void) PSTATE->pCPC->get_type_info(&PSTATE->pCPC->layout, &(yyvsp[(1) - (2)].tspec), NULL, "sf", &size, &flags);
	        (yyval.value).iv = size * (yyvsp[(2) - (2)].absDecl).multiplicator;
	        (yyval.value).flags = 0;
	        if (flags & T_UNSAFE_VAL)
	          (yyval.value).flags |= V_IS_UNSAFE;
	      }
	    }
	  ;}
    break;

  case 227:

/* Line 1464 of yacc.c  */
#line 1628 "ctlib/parser.y"
    {
	    if (!IS_LOCAL)
	    {
	      (yyval.value).iv = PSTATE->pCPC->layout.int_size;
	      (yyval.value).flags = 0;
	    }
	  ;}
    break;

  case 228:

/* Line 1464 of yacc.c  */
#line 1636 "ctlib/parser.y"
    {
	    if (!IS_LOCAL)
	    {
	      (yyval.value).iv = (yyvsp[(2) - (2)].absDecl).multiplicator * ((yyvsp[(2) - (2)].absDecl).pointer_flag ?
	              PSTATE->pCPC->layout.ptr_size : PSTATE->pCPC->layout.int_size);
	      (yyval.value).flags = 0;
	    }
	  ;}
    break;

  case 233:

/* Line 1464 of yacc.c  */
#line 1654 "ctlib/parser.y"
    {;}
    break;

  case 241:

/* Line 1464 of yacc.c  */
#line 1674 "ctlib/parser.y"
    { DELETE_NODE((yyvsp[(2) - (2)].identifier)); ;}
    break;

  case 251:

/* Line 1464 of yacc.c  */
#line 1694 "ctlib/parser.y"
    { DELETE_NODE((yyvsp[(1) - (3)].identifier)); ;}
    break;

  case 269:

/* Line 1464 of yacc.c  */
#line 1733 "ctlib/parser.y"
    { DELETE_NODE((yyvsp[(2) - (3)].identifier)); ;}
    break;

  case 280:

/* Line 1464 of yacc.c  */
#line 1759 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 281:

/* Line 1464 of yacc.c  */
#line 1760 "ctlib/parser.y"
    { END_LOCAL; decl_delete((yyvsp[(1) - (3)].pDecl)); ;}
    break;

  case 282:

/* Line 1464 of yacc.c  */
#line 1761 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 283:

/* Line 1464 of yacc.c  */
#line 1762 "ctlib/parser.y"
    { END_LOCAL; decl_delete((yyvsp[(2) - (4)].pDecl)); ;}
    break;

  case 284:

/* Line 1464 of yacc.c  */
#line 1763 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 285:

/* Line 1464 of yacc.c  */
#line 1764 "ctlib/parser.y"
    { END_LOCAL; decl_delete((yyvsp[(2) - (4)].pDecl)); ;}
    break;

  case 286:

/* Line 1464 of yacc.c  */
#line 1765 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 287:

/* Line 1464 of yacc.c  */
#line 1766 "ctlib/parser.y"
    { END_LOCAL; decl_delete((yyvsp[(2) - (4)].pDecl)); ;}
    break;

  case 288:

/* Line 1464 of yacc.c  */
#line 1767 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 289:

/* Line 1464 of yacc.c  */
#line 1768 "ctlib/parser.y"
    { END_LOCAL; decl_delete((yyvsp[(2) - (4)].pDecl)); ;}
    break;

  case 290:

/* Line 1464 of yacc.c  */
#line 1770 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 291:

/* Line 1464 of yacc.c  */
#line 1770 "ctlib/parser.y"
    { END_LOCAL; ;}
    break;

  case 292:

/* Line 1464 of yacc.c  */
#line 1771 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 293:

/* Line 1464 of yacc.c  */
#line 1771 "ctlib/parser.y"
    { END_LOCAL; ;}
    break;

  case 294:

/* Line 1464 of yacc.c  */
#line 1772 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 295:

/* Line 1464 of yacc.c  */
#line 1772 "ctlib/parser.y"
    { END_LOCAL; ;}
    break;

  case 296:

/* Line 1464 of yacc.c  */
#line 1773 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 297:

/* Line 1464 of yacc.c  */
#line 1773 "ctlib/parser.y"
    { END_LOCAL; ;}
    break;

  case 298:

/* Line 1464 of yacc.c  */
#line 1774 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 299:

/* Line 1464 of yacc.c  */
#line 1774 "ctlib/parser.y"
    { END_LOCAL; ;}
    break;

  case 300:

/* Line 1464 of yacc.c  */
#line 1776 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 301:

/* Line 1464 of yacc.c  */
#line 1776 "ctlib/parser.y"
    { END_LOCAL; ;}
    break;

  case 302:

/* Line 1464 of yacc.c  */
#line 1777 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 303:

/* Line 1464 of yacc.c  */
#line 1777 "ctlib/parser.y"
    { END_LOCAL; ;}
    break;

  case 304:

/* Line 1464 of yacc.c  */
#line 1778 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 305:

/* Line 1464 of yacc.c  */
#line 1778 "ctlib/parser.y"
    { END_LOCAL; ;}
    break;

  case 306:

/* Line 1464 of yacc.c  */
#line 1779 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 307:

/* Line 1464 of yacc.c  */
#line 1779 "ctlib/parser.y"
    { END_LOCAL; ;}
    break;

  case 308:

/* Line 1464 of yacc.c  */
#line 1780 "ctlib/parser.y"
    { BEGIN_LOCAL; ;}
    break;

  case 309:

/* Line 1464 of yacc.c  */
#line 1780 "ctlib/parser.y"
    { END_LOCAL; ;}
    break;

  case 314:

/* Line 1464 of yacc.c  */
#line 1795 "ctlib/parser.y"
    {
	    (yyval.pDecl) = IS_LOCAL ? NULL : decl_new((yyvsp[(1) - (1)].pTypedef)->pDecl->identifier, CTT_IDLEN((yyvsp[(1) - (1)].pTypedef)->pDecl));
	  ;}
    break;

  case 315:

/* Line 1464 of yacc.c  */
#line 1799 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.pDecl) = NULL;
	    else
	    {
	      (yyval.pDecl) = decl_new((yyvsp[(1) - (2)].pTypedef)->pDecl->identifier, CTT_IDLEN((yyvsp[(1) - (2)].pTypedef)->pDecl));
	      if ((yyvsp[(2) - (2)].list))
	      {
	        (yyval.pDecl)->array_flag = 1;
	        (yyval.pDecl)->ext.array = (yyvsp[(2) - (2)].list);
	      }
	    }
	  ;}
    break;

  case 318:

/* Line 1464 of yacc.c  */
#line 1821 "ctlib/parser.y"
    {
	    if ((yyvsp[(2) - (2)].pDecl))
	      (yyvsp[(2) - (2)].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[(2) - (2)].pDecl);
	  ;}
    break;

  case 319:

/* Line 1464 of yacc.c  */
#line 1827 "ctlib/parser.y"
    {
	    if ((yyvsp[(3) - (3)].pDecl))
	      (yyvsp[(3) - (3)].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[(3) - (3)].pDecl);
	  ;}
    break;

  case 320:

/* Line 1464 of yacc.c  */
#line 1835 "ctlib/parser.y"
    { (yyval.pDecl) = (yyvsp[(2) - (3)].pDecl); ;}
    break;

  case 321:

/* Line 1464 of yacc.c  */
#line 1837 "ctlib/parser.y"
    {
	    POSTFIX_DECL((yyvsp[(2) - (4)].pDecl), (yyvsp[(4) - (4)].list));
	    (yyval.pDecl) = (yyvsp[(2) - (4)].pDecl);
	  ;}
    break;

  case 323:

/* Line 1464 of yacc.c  */
#line 1849 "ctlib/parser.y"
    {
	    if ((yyvsp[(3) - (4)].pDecl))
	      (yyvsp[(3) - (4)].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[(3) - (4)].pDecl);
	  ;}
    break;

  case 324:

/* Line 1464 of yacc.c  */
#line 1855 "ctlib/parser.y"
    {
	    if ((yyvsp[(4) - (5)].pDecl))
	      (yyvsp[(4) - (5)].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[(4) - (5)].pDecl);
	  ;}
    break;

  case 325:

/* Line 1464 of yacc.c  */
#line 1861 "ctlib/parser.y"
    {
	    if ((yyvsp[(2) - (2)].pDecl))
	      (yyvsp[(2) - (2)].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[(2) - (2)].pDecl);
	  ;}
    break;

  case 326:

/* Line 1464 of yacc.c  */
#line 1867 "ctlib/parser.y"
    {
	    if ((yyvsp[(3) - (3)].pDecl))
	      (yyvsp[(3) - (3)].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[(3) - (3)].pDecl);
	  ;}
    break;

  case 327:

/* Line 1464 of yacc.c  */
#line 1875 "ctlib/parser.y"
    { (yyval.pDecl) = (yyvsp[(2) - (3)].pDecl); ;}
    break;

  case 328:

/* Line 1464 of yacc.c  */
#line 1877 "ctlib/parser.y"
    {
	    POSTFIX_DECL((yyvsp[(2) - (4)].pDecl), (yyvsp[(3) - (4)].list));
	    (yyval.pDecl) = (yyvsp[(2) - (4)].pDecl);
	  ;}
    break;

  case 329:

/* Line 1464 of yacc.c  */
#line 1882 "ctlib/parser.y"
    {
	    POSTFIX_DECL((yyvsp[(2) - (4)].pDecl), (yyvsp[(4) - (4)].list));
	    (yyval.pDecl) = (yyvsp[(2) - (4)].pDecl);
	  ;}
    break;

  case 330:

/* Line 1464 of yacc.c  */
#line 1890 "ctlib/parser.y"
    {
	    (yyval.pDecl) = IS_LOCAL ? NULL : decl_new((yyvsp[(1) - (1)].pTypedef)->pDecl->identifier, CTT_IDLEN((yyvsp[(1) - (1)].pTypedef)->pDecl));
	  ;}
    break;

  case 331:

/* Line 1464 of yacc.c  */
#line 1893 "ctlib/parser.y"
    { (yyval.pDecl) = (yyvsp[(2) - (3)].pDecl); ;}
    break;

  case 335:

/* Line 1464 of yacc.c  */
#line 1904 "ctlib/parser.y"
    {
	    if ((yyvsp[(2) - (2)].pDecl))
	      (yyvsp[(2) - (2)].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[(2) - (2)].pDecl);
	  ;}
    break;

  case 336:

/* Line 1464 of yacc.c  */
#line 1910 "ctlib/parser.y"
    {
	    if ((yyvsp[(3) - (3)].pDecl))
	      (yyvsp[(3) - (3)].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[(3) - (3)].pDecl);
	  ;}
    break;

  case 337:

/* Line 1464 of yacc.c  */
#line 1919 "ctlib/parser.y"
    {
	    POSTFIX_DECL((yyvsp[(1) - (2)].pDecl), (yyvsp[(2) - (2)].list));
	    (yyval.pDecl) = (yyvsp[(1) - (2)].pDecl);
	  ;}
    break;

  case 338:

/* Line 1464 of yacc.c  */
#line 1923 "ctlib/parser.y"
    { (yyval.pDecl) = (yyvsp[(2) - (3)].pDecl); ;}
    break;

  case 339:

/* Line 1464 of yacc.c  */
#line 1925 "ctlib/parser.y"
    {
	    POSTFIX_DECL((yyvsp[(2) - (4)].pDecl), (yyvsp[(4) - (4)].list));
	    (yyval.pDecl) = (yyvsp[(2) - (4)].pDecl);
	  ;}
    break;

  case 340:

/* Line 1464 of yacc.c  */
#line 1933 "ctlib/parser.y"
    {
	    if ((yyvsp[(1) - (1)].identifier))
	    {
	      (yyval.pDecl) = decl_new((yyvsp[(1) - (1)].identifier)->key, (yyvsp[(1) - (1)].identifier)->keylen);
	      HN_delete((yyvsp[(1) - (1)].identifier));
	    }
	    else
	    {
	      (yyval.pDecl) = NULL;
	    }
	  ;}
    break;

  case 341:

/* Line 1464 of yacc.c  */
#line 1944 "ctlib/parser.y"
    { (yyval.pDecl) = (yyvsp[(2) - (3)].pDecl); ;}
    break;

  case 342:

/* Line 1464 of yacc.c  */
#line 1948 "ctlib/parser.y"
    {;}
    break;

  case 343:

/* Line 1464 of yacc.c  */
#line 1949 "ctlib/parser.y"
    {;}
    break;

  case 344:

/* Line 1464 of yacc.c  */
#line 1950 "ctlib/parser.y"
    {;}
    break;

  case 345:

/* Line 1464 of yacc.c  */
#line 1955 "ctlib/parser.y"
    {
	    if ((yyvsp[(1) - (4)].pDecl))
	      decl_delete((yyvsp[(1) - (4)].pDecl));
	  ;}
    break;

  case 346:

/* Line 1464 of yacc.c  */
#line 1959 "ctlib/parser.y"
    {;}
    break;

  case 347:

/* Line 1464 of yacc.c  */
#line 1961 "ctlib/parser.y"
    {
	    if ((yyvsp[(4) - (4)].list))
	      LL_destroy((yyvsp[(4) - (4)].list), (LLDestroyFunc) value_delete);
	  ;}
    break;

  case 350:

/* Line 1464 of yacc.c  */
#line 1971 "ctlib/parser.y"
    {
	    (yyval.absDecl).pointer_flag  = 0;
	    (yyval.absDecl).multiplicator = 1;
	    if ((yyvsp[(1) - (1)].list))
	    {
	      ListIterator ai;
	      Value *pValue;

	      LL_foreach(pValue, ai, (yyvsp[(1) - (1)].list))
	        (yyval.absDecl).multiplicator *= pValue->iv;

	      LL_destroy((yyvsp[(1) - (1)].list), (LLDestroyFunc) value_delete);
	    }
	  ;}
    break;

  case 352:

/* Line 1464 of yacc.c  */
#line 1989 "ctlib/parser.y"
    { (yyval.list) = NULL; ;}
    break;

  case 353:

/* Line 1464 of yacc.c  */
#line 1990 "ctlib/parser.y"
    { (yyval.list) = NULL; ;}
    break;

  case 354:

/* Line 1464 of yacc.c  */
#line 1995 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      (yyval.list) = LL_new();
	      LL_push((yyval.list), value_new((yyvsp[(3) - (4)].value).iv, (yyvsp[(3) - (4)].value).flags));
	      CT_DEBUG(PARSER, ("array dimension => %ld", (yyvsp[(3) - (4)].value).iv));
	    }
	  ;}
    break;

  case 355:

/* Line 1464 of yacc.c  */
#line 2006 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      (yyval.list) = LL_new();
	      LL_push((yyval.list), value_new((yyvsp[(4) - (5)].value).iv, (yyvsp[(4) - (5)].value).flags));
	      CT_DEBUG(PARSER, ("array dimension => %ld", (yyvsp[(4) - (5)].value).iv));
	    }
	  ;}
    break;

  case 356:

/* Line 1464 of yacc.c  */
#line 2017 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      (yyval.list) = LL_new();
	      LL_push((yyval.list), value_new((yyvsp[(4) - (5)].value).iv, (yyvsp[(4) - (5)].value).flags));
	      CT_DEBUG(PARSER, ("array dimension => %ld", (yyvsp[(4) - (5)].value).iv));
	    }
	  ;}
    break;

  case 357:

/* Line 1464 of yacc.c  */
#line 2027 "ctlib/parser.y"
    { (yyval.list) = NULL; ;}
    break;

  case 358:

/* Line 1464 of yacc.c  */
#line 2029 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      (yyval.list) = (yyvsp[(1) - (4)].list) ? (yyvsp[(1) - (4)].list) : LL_new();
	      LL_push((yyval.list), value_new((yyvsp[(3) - (4)].value).iv, (yyvsp[(3) - (4)].value).flags));
	      CT_DEBUG(PARSER, ("array dimension => %ld", (yyvsp[(3) - (4)].value).iv));
	    }
	  ;}
    break;

  case 359:

/* Line 1464 of yacc.c  */
#line 2040 "ctlib/parser.y"
    {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      (yyval.list) = (yyvsp[(1) - (4)].list) ? (yyvsp[(1) - (4)].list) : LL_new();
	      LL_push((yyval.list), value_new(0, 0));
	      CT_DEBUG(PARSER, ("array dimension => *" ));
	    }
	  ;}
    break;

  case 360:

/* Line 1464 of yacc.c  */
#line 2054 "ctlib/parser.y"
    {
	    (yyval.absDecl).pointer_flag = 1;
	    (yyval.absDecl).multiplicator = 1;
	  ;}
    break;

  case 361:

/* Line 1464 of yacc.c  */
#line 2059 "ctlib/parser.y"
    {
	    (yyval.absDecl).pointer_flag = 1;
	    (yyval.absDecl).multiplicator = 1;
	  ;}
    break;

  case 362:

/* Line 1464 of yacc.c  */
#line 2064 "ctlib/parser.y"
    {
	    (yyvsp[(2) - (2)].absDecl).pointer_flag = 1;
	    (yyval.absDecl) = (yyvsp[(2) - (2)].absDecl);
	  ;}
    break;

  case 363:

/* Line 1464 of yacc.c  */
#line 2069 "ctlib/parser.y"
    {
	    (yyvsp[(3) - (3)].absDecl).pointer_flag = 1;
	    (yyval.absDecl) = (yyvsp[(3) - (3)].absDecl);
	  ;}
    break;

  case 364:

/* Line 1464 of yacc.c  */
#line 2076 "ctlib/parser.y"
    { (yyval.absDecl) = (yyvsp[(2) - (3)].absDecl); ;}
    break;

  case 365:

/* Line 1464 of yacc.c  */
#line 2077 "ctlib/parser.y"
    { (yyval.absDecl) = (yyvsp[(2) - (3)].absDecl); ;}
    break;

  case 366:

/* Line 1464 of yacc.c  */
#line 2079 "ctlib/parser.y"
    {
	    (yyval.absDecl).pointer_flag  = 0;
	    (yyval.absDecl).multiplicator = 1;
	    if ((yyvsp[(2) - (3)].list))
	    {
	      ListIterator ai;
	      Value *pValue;

	      LL_foreach(pValue, ai, (yyvsp[(2) - (3)].list))
	        (yyval.absDecl).multiplicator *= pValue->iv;

	      LL_destroy((yyvsp[(2) - (3)].list), (LLDestroyFunc) value_delete);
	    }
	  ;}
    break;

  case 367:

/* Line 1464 of yacc.c  */
#line 2094 "ctlib/parser.y"
    {
	    (yyval.absDecl) = (yyvsp[(2) - (4)].absDecl);
	    if ((yyvsp[(4) - (4)].list))
	      LL_destroy((yyvsp[(4) - (4)].list), (LLDestroyFunc) value_delete);
	  ;}
    break;



/* Line 1464 of yacc.c  */
#line 5732 "ctlib/y_parser.c"
      default: break;
    }
  YY_SYMBOL_PRINT ("-> $$ =", yyr1[yyn], &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);

  *++yyvsp = yyval;

  /* Now `shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTOKENS] + *yyssp;
  if (0 <= yystate && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTOKENS];

  goto yynewstate;


/*------------------------------------.
| yyerrlab -- here on detecting error |
`------------------------------------*/
yyerrlab:
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
#if ! YYERROR_VERBOSE
      yyerror (YY_("syntax error"));
#else
      {
	YYSIZE_T yysize = yysyntax_error (0, yystate, yychar);
	if (yymsg_alloc < yysize && yymsg_alloc < YYSTACK_ALLOC_MAXIMUM)
	  {
	    YYSIZE_T yyalloc = 2 * yysize;
	    if (! (yysize <= yyalloc && yyalloc <= YYSTACK_ALLOC_MAXIMUM))
	      yyalloc = YYSTACK_ALLOC_MAXIMUM;
	    if (yymsg != yymsgbuf)
	      YYSTACK_FREE (yymsg);
	    yymsg = (char *) YYSTACK_ALLOC (yyalloc);
	    if (yymsg)
	      yymsg_alloc = yyalloc;
	    else
	      {
		yymsg = yymsgbuf;
		yymsg_alloc = sizeof yymsgbuf;
	      }
	  }

	if (0 < yysize && yysize <= yymsg_alloc)
	  {
	    (void) yysyntax_error (yymsg, yystate, yychar);
	    yyerror (yymsg);
	  }
	else
	  {
	    yyerror (YY_("syntax error"));
	    if (yysize != 0)
	      goto yyexhaustedlab;
	  }
      }
#endif
    }



  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
	 error, discard it.  */

      if (yychar <= YYEOF)
	{
	  /* Return failure if at end of input.  */
	  if (yychar == YYEOF)
	    YYABORT;
	}
      else
	{
	  yydestruct ("Error: discarding",
		      yytoken, &yylval);
	  yychar = YYEMPTY;
	}
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:

  /* Pacify compilers like GCC when the user code never invokes
     YYERROR and the label yyerrorlab therefore never appears in user
     code.  */
  if (/*CONSTCOND*/ 0)
     goto yyerrorlab;

  /* Do not reclaim the symbols of the rule which action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;	/* Each real token shifted decrements this.  */

  for (;;)
    {
      yyn = yypact[yystate];
      if (yyn != YYPACT_NINF)
	{
	  yyn += YYTERROR;
	  if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYTERROR)
	    {
	      yyn = yytable[yyn];
	      if (0 < yyn)
		break;
	    }
	}

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
	YYABORT;


      yydestruct ("Error: popping",
		  yystos[yystate], yyvsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  *++yyvsp = yylval;


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", yystos[yyn], yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturn;

/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturn;

#if !defined(yyoverflow) || YYERROR_VERBOSE
/*-------------------------------------------------.
| yyexhaustedlab -- memory exhaustion comes here.  |
`-------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  /* Fall through.  */
#endif

yyreturn:
  if (yychar != YYEMPTY)
     yydestruct ("Cleanup: discarding lookahead",
		 yytoken, &yylval);
  /* Do not reclaim the symbols of the rule which action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
		  yystos[*yyssp], yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
#if YYERROR_VERBOSE
  if (yymsg != yymsgbuf)
    YYSTACK_FREE (yymsg);
#endif
  /* Make sure YYID is used.  */
  return YYID (yyresult);
}



/* Line 1684 of yacc.c  */
#line 2101 "ctlib/parser.y"



/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: c_lex
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: C lexer.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

static inline int c_lex(YYSTYPE *plval, ParserState *pState)
{
  int rval, token;
  struct lexer_state *pLexer = pState->pLexer;
  dUCPP(pState->pp);

  CT_DEBUG(CLEXER, ("parser.y::c_lex()"));

  while ((rval = lex(aUCPP_ pLexer)) < CPPERR_EOF)
  {
    if (rval)
    {
      CT_DEBUG(CLEXER, ("lex() returned %d", rval));
      continue;
    }

    token = pLexer->ctok->type;

    switch (token)
    {
      case NONE:
        CT_DEBUG(CLEXER, ("token-type => NONE"));
        break;

      case COMMENT:
        CT_DEBUG(CLEXER, ("token-type => COMMENT => [%s]", pLexer->ctok->name));
        break;

      case NEWLINE:
        CT_DEBUG(CLEXER, ("token-type => NEWLINE"));
        break;

      case BUNCH:
        CT_DEBUG(CLEXER, ("token-type => BUNCH => [%s]", pLexer->ctok->name));
        break;

      case CONTEXT:
        CT_DEBUG(CLEXER, ("token-type => CONTEXT => [%s]", pLexer->ctok->name));
        {
          FileInfo *pFI;
          size_t len = strlen(pLexer->ctok->name);

          CT_DEBUG(CLEXER, ("new context: file '%s', line %ld",
                            pLexer->ctok->name, pLexer->ctok->line));

          pFI = HT_get(pState->pCPI->htFiles, pLexer->ctok->name, len, 0);

          if (pFI == NULL)
          {
            pFI = fileinfo_new(pLexer->input, pLexer->ctok->name, len);
            HT_store(pState->pCPI->htFiles, pLexer->ctok->name, len, 0, pFI);
          }

          pState->pFI = pFI;
        }
        break;

      case NUMBER:
        CT_DEBUG(CLEXER, ("token-type => NUMBER => [%s]", pLexer->ctok->name));
        plval->value.iv = strtol(pLexer->ctok->name, NULL, 0);
        plval->value.flags = 0;
        CT_DEBUG(CLEXER, ("constant: %s -> %ld", pLexer->ctok->name, plval->value.iv));
        return CONSTANT;

      case STRING:
        CT_DEBUG(CLEXER, ("token-type => STRING => [%s]", pLexer->ctok->name));
        plval->value.iv = string_size(pLexer->ctok->name);
        plval->value.flags = 0;
        CT_DEBUG(CLEXER, ("string literal: %s -> %ld", pLexer->ctok->name, plval->value.iv));
        return STRING_LITERAL;

      case CHAR:
        CT_DEBUG(CLEXER, ("token-type => CHAR => [%s]", pLexer->ctok->name));
        plval->value.iv = get_char_value(pLexer->ctok->name);
        plval->value.flags = 0;
        CT_DEBUG(CLEXER, ("constant: %s -> %ld", pLexer->ctok->name, plval->value.iv));
        return CONSTANT;

      case PRAGMA:
        CT_DEBUG(CLEXER, ("token-type => PRAGMA"));
        CT_DEBUG(CLEXER, ("line %ld: <#pragma>", pLexer->line));

        pragma_parser_set_context(pState->pragma, pState->pFI ? pState->pFI->name : "unknown",
                                                  pLexer->line - 1, pLexer->ctok->name);
        pragma_parser_parse(pState->pragma);

        CT_DEBUG(CLEXER, ("current packing: %d\n", pragma_parser_get_pack(pState->pragma)));
        break;

      case NAME:
        CT_DEBUG(CLEXER, ("token-type => NAME => [%s]", pLexer->ctok->name));
        {
          char *tokstr = pLexer->ctok->name;
          const CKeywordToken *ckt;

#include "token/t_parser.c"

          unknown:

          if ((ckt = HT_get(pState->pCPC->keyword_map, tokstr, 0, 0)) != NULL)
          {
            if (ckt->token == SKIP_TOK)
            {
              CT_DEBUG(CLEXER, ("skipping token '%s' in line %ld", tokstr, pLexer->line));
              break;
            }

            return ckt->token;
          }

          return check_type(plval, pState, tokstr);
        }

      default:
        CT_DEBUG(CLEXER, ("token-type => %d", token));
        if ((rval = tokentab[token]) != 0)
          return rval;

        CT_DEBUG(CLEXER, ("unhandled token in line %ld: <%2d>", pLexer->line, token));
        break;
    }
  }

  CT_DEBUG(CLEXER, ("EOF!"));

  return 0;
}

/*******************************************************************************
*
*   ROUTINE: parser_error
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

static void parser_error(ParserState *pState, const char *msg)
{
  push_error(pState->pCPI, "%s, line %ld: %s",
             pState->pFI ? pState->pFI->name : "[unknown]",
             pState->pLexer->ctok->line, msg);
}

/*******************************************************************************
*
*   ROUTINE: get_char_value
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

static inline int get_char_value(const char *s)
{
  while (*s && *s != '\'')
    s++;

  if (*++s != '\\')
    return (int) *s;

  switch (*++s)
  {
    case '0' :
    case '1' :
    case '2' :
    case '3' : return (int) strtol(s, NULL, 8);
    case 'a' : return (int) '\a';
    case 'b' : return (int) '\b';
    case 'f' : return (int) '\f';
    case 'h' : return (int) strtol(++s, NULL, 16);
    case 'n' : return (int) '\n';
    case 'r' : return (int) '\r';
    case 't' : return (int) '\t';
    case 'v' : return (int) '\v';

    default:   return (int) *s;
  }
}

/*******************************************************************************
*
*   ROUTINE: string_size
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

static inline int string_size(const char *s)
{
  int size, count;

  while (*s && *s != '\"')
    s++;

  for (s++, size=0; *s; size++)
  {
    if (*s == '\"')
      break;

    if (*s++ != '\\')
      continue;

    if (*s == 'x')
    {
      count = 0;
      do s++; while (count++ < 2 &&
                     ((*s >= '0' && *s <= '9') ||
                      (*s >= 'a' && *s <= 'f') ||
                      (*s >= 'A' && *s <= 'F')));
      continue;
    }

    if (*s >= '0' && *s <= '7')
    {
      count = 0;
      do s++; while (count++ < 2 && *s >= '0' && *s <= '7');
    }
    else
      s++;
  }

  return size;
}

/*******************************************************************************
*
*   ROUTINE: check_type
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

static inline int check_type(YYSTYPE *plval, ParserState *pState, const char *s)
{
  Typedef    *pTypedef;
  HashSum     hash;
  int         len;

  CT_DEBUG(CLEXER, ("check_type( \"%s\" )", s));

  HASH_STR_LEN(hash, s, len);

  pTypedef = HT_get(pState->pCPI->htTypedefs, s, len, hash);

  if (pTypedef)
  {
    CT_DEBUG(CLEXER, ("typedef found!"));
    plval->pTypedef = pTypedef;
    return TYPE_NAME;
  }

  plval->identifier = pState->flags & F_LOCAL ? NULL : HN_new(s, len, hash);

  return IDENTIFIER;
}


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: get_c_keyword_token
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Create a new C parser.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

const CKeywordToken *get_c_keyword_token(const char *name)
{
#include "token/t_ckeytok.c"
unknown:
  return NULL;
}

/*******************************************************************************
*
*   ROUTINE: get_skip_token
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Create a new C parser.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

const CKeywordToken *get_skip_token(void)
{
  static const CKeywordToken ckt = { SKIP_TOK, NULL };
  return &ckt;
}

/*******************************************************************************
*
*   ROUTINE: c_parser_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Create a new C parser.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

ParserState *c_parser_new(const CParseConfig *pCPC, CParseInfo *pCPI,
                          pUCPP_ struct lexer_state *pLexer)
{
  ParserState *pState;

#ifdef CTLIB_DEBUGGING
#ifdef YYDEBUG
  extern int pragma_debug;
  c_debug = pragma_debug = DEBUG_FLAG(YACC) ? 1 : 0;
#endif
#endif

  if (pCPC == NULL || pCPI == NULL || pLexer == NULL)
    return NULL;

  AllocF(ParserState *, pState, sizeof(ParserState));

  pState->pCPI = pCPI;
  pState->pCPC = pCPC;
  pState->pLexer = pLexer;
  pState->pp = aUCPP;

  pState->flags = 0;
  pState->pFI = NULL;

  pState->pragma = pragma_parser_new(pCPI);

  return pState;
}

/*******************************************************************************
*
*   ROUTINE: c_parser_run
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Run the C parser.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

int c_parser_run(ParserState *pState)
{
  return c_parse((void *) pState);
}

/*******************************************************************************
*
*   ROUTINE: c_parser_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Delete a C parser object.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void c_parser_delete(ParserState *pState)
{
  if (pState == NULL)
    return;

  pragma_parser_delete(pState->pragma);

  Free(pState);
}

