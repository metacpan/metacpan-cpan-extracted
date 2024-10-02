/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

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

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30802

/* Bison version string.  */
#define YYBISON_VERSION "3.8.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 1

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1


/* Substitute the variable and function names.  */
#define yyparse         c_parse
#define yylex           c_lex
#define yyerror         c_error
#define yydebug         c_debug
#define yynerrs         c_nerrs

/* First part of user prologue.  */
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
* Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
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

/*
 * Bison version >= 1.31 is needed for YYFPRINTF
 */
#if YYDEBUG && defined CTLIB_DEBUGGING
#define YYFPRINTF BisonDebugFunc
#endif

#define c_error         parser_error

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


#line 273 "ctlib/y_parser.c"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif


/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int c_debug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    AUTO_TOK = 258,                /* AUTO_TOK  */
    DOUBLE_TOK = 259,              /* DOUBLE_TOK  */
    INT_TOK = 260,                 /* INT_TOK  */
    STRUCT_TOK = 261,              /* STRUCT_TOK  */
    BREAK_TOK = 262,               /* BREAK_TOK  */
    ELSE_TOK = 263,                /* ELSE_TOK  */
    LONG_TOK = 264,                /* LONG_TOK  */
    SWITCH_TOK = 265,              /* SWITCH_TOK  */
    CASE_TOK = 266,                /* CASE_TOK  */
    ENUM_TOK = 267,                /* ENUM_TOK  */
    REGISTER_TOK = 268,            /* REGISTER_TOK  */
    TYPEDEF_TOK = 269,             /* TYPEDEF_TOK  */
    CHAR_TOK = 270,                /* CHAR_TOK  */
    EXTERN_TOK = 271,              /* EXTERN_TOK  */
    RETURN_TOK = 272,              /* RETURN_TOK  */
    UNION_TOK = 273,               /* UNION_TOK  */
    CONST_TOK = 274,               /* CONST_TOK  */
    FLOAT_TOK = 275,               /* FLOAT_TOK  */
    SHORT_TOK = 276,               /* SHORT_TOK  */
    UNSIGNED_TOK = 277,            /* UNSIGNED_TOK  */
    CONTINUE_TOK = 278,            /* CONTINUE_TOK  */
    FOR_TOK = 279,                 /* FOR_TOK  */
    SIGNED_TOK = 280,              /* SIGNED_TOK  */
    VOID_TOK = 281,                /* VOID_TOK  */
    DEFAULT_TOK = 282,             /* DEFAULT_TOK  */
    GOTO_TOK = 283,                /* GOTO_TOK  */
    SIZEOF_TOK = 284,              /* SIZEOF_TOK  */
    VOLATILE_TOK = 285,            /* VOLATILE_TOK  */
    DO_TOK = 286,                  /* DO_TOK  */
    IF_TOK = 287,                  /* IF_TOK  */
    STATIC_TOK = 288,              /* STATIC_TOK  */
    WHILE_TOK = 289,               /* WHILE_TOK  */
    INLINE_TOK = 290,              /* INLINE_TOK  */
    RESTRICT_TOK = 291,            /* RESTRICT_TOK  */
    ASM_TOK = 292,                 /* ASM_TOK  */
    SKIP_TOK = 293,                /* SKIP_TOK  */
    PTR_OP = 294,                  /* PTR_OP  */
    INC_OP = 295,                  /* INC_OP  */
    DEC_OP = 296,                  /* DEC_OP  */
    LEFT_OP = 297,                 /* LEFT_OP  */
    RIGHT_OP = 298,                /* RIGHT_OP  */
    LE_OP = 299,                   /* LE_OP  */
    GE_OP = 300,                   /* GE_OP  */
    EQ_OP = 301,                   /* EQ_OP  */
    NE_OP = 302,                   /* NE_OP  */
    AND_OP = 303,                  /* AND_OP  */
    OR_OP = 304,                   /* OR_OP  */
    ELLIPSIS = 305,                /* ELLIPSIS  */
    MUL_ASSIGN = 306,              /* MUL_ASSIGN  */
    DIV_ASSIGN = 307,              /* DIV_ASSIGN  */
    MOD_ASSIGN = 308,              /* MOD_ASSIGN  */
    ADD_ASSIGN = 309,              /* ADD_ASSIGN  */
    SUB_ASSIGN = 310,              /* SUB_ASSIGN  */
    LEFT_ASSIGN = 311,             /* LEFT_ASSIGN  */
    RIGHT_ASSIGN = 312,            /* RIGHT_ASSIGN  */
    AND_ASSIGN = 313,              /* AND_ASSIGN  */
    XOR_ASSIGN = 314,              /* XOR_ASSIGN  */
    OR_ASSIGN = 315,               /* OR_ASSIGN  */
    STRING_LITERAL = 316,          /* STRING_LITERAL  */
    CONSTANT = 317,                /* CONSTANT  */
    TYPE_NAME = 318,               /* TYPE_NAME  */
    IDENTIFIER = 319               /* IDENTIFIER  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 242 "ctlib/parser.y"

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

#line 403 "ctlib/y_parser.c"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif




int c_parse (ParserState *pState);



/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL_AUTO_TOK = 3,                   /* AUTO_TOK  */
  YYSYMBOL_DOUBLE_TOK = 4,                 /* DOUBLE_TOK  */
  YYSYMBOL_INT_TOK = 5,                    /* INT_TOK  */
  YYSYMBOL_STRUCT_TOK = 6,                 /* STRUCT_TOK  */
  YYSYMBOL_BREAK_TOK = 7,                  /* BREAK_TOK  */
  YYSYMBOL_ELSE_TOK = 8,                   /* ELSE_TOK  */
  YYSYMBOL_LONG_TOK = 9,                   /* LONG_TOK  */
  YYSYMBOL_SWITCH_TOK = 10,                /* SWITCH_TOK  */
  YYSYMBOL_CASE_TOK = 11,                  /* CASE_TOK  */
  YYSYMBOL_ENUM_TOK = 12,                  /* ENUM_TOK  */
  YYSYMBOL_REGISTER_TOK = 13,              /* REGISTER_TOK  */
  YYSYMBOL_TYPEDEF_TOK = 14,               /* TYPEDEF_TOK  */
  YYSYMBOL_CHAR_TOK = 15,                  /* CHAR_TOK  */
  YYSYMBOL_EXTERN_TOK = 16,                /* EXTERN_TOK  */
  YYSYMBOL_RETURN_TOK = 17,                /* RETURN_TOK  */
  YYSYMBOL_UNION_TOK = 18,                 /* UNION_TOK  */
  YYSYMBOL_CONST_TOK = 19,                 /* CONST_TOK  */
  YYSYMBOL_FLOAT_TOK = 20,                 /* FLOAT_TOK  */
  YYSYMBOL_SHORT_TOK = 21,                 /* SHORT_TOK  */
  YYSYMBOL_UNSIGNED_TOK = 22,              /* UNSIGNED_TOK  */
  YYSYMBOL_CONTINUE_TOK = 23,              /* CONTINUE_TOK  */
  YYSYMBOL_FOR_TOK = 24,                   /* FOR_TOK  */
  YYSYMBOL_SIGNED_TOK = 25,                /* SIGNED_TOK  */
  YYSYMBOL_VOID_TOK = 26,                  /* VOID_TOK  */
  YYSYMBOL_DEFAULT_TOK = 27,               /* DEFAULT_TOK  */
  YYSYMBOL_GOTO_TOK = 28,                  /* GOTO_TOK  */
  YYSYMBOL_SIZEOF_TOK = 29,                /* SIZEOF_TOK  */
  YYSYMBOL_VOLATILE_TOK = 30,              /* VOLATILE_TOK  */
  YYSYMBOL_DO_TOK = 31,                    /* DO_TOK  */
  YYSYMBOL_IF_TOK = 32,                    /* IF_TOK  */
  YYSYMBOL_STATIC_TOK = 33,                /* STATIC_TOK  */
  YYSYMBOL_WHILE_TOK = 34,                 /* WHILE_TOK  */
  YYSYMBOL_INLINE_TOK = 35,                /* INLINE_TOK  */
  YYSYMBOL_RESTRICT_TOK = 36,              /* RESTRICT_TOK  */
  YYSYMBOL_ASM_TOK = 37,                   /* ASM_TOK  */
  YYSYMBOL_SKIP_TOK = 38,                  /* SKIP_TOK  */
  YYSYMBOL_PTR_OP = 39,                    /* PTR_OP  */
  YYSYMBOL_INC_OP = 40,                    /* INC_OP  */
  YYSYMBOL_DEC_OP = 41,                    /* DEC_OP  */
  YYSYMBOL_LEFT_OP = 42,                   /* LEFT_OP  */
  YYSYMBOL_RIGHT_OP = 43,                  /* RIGHT_OP  */
  YYSYMBOL_LE_OP = 44,                     /* LE_OP  */
  YYSYMBOL_GE_OP = 45,                     /* GE_OP  */
  YYSYMBOL_EQ_OP = 46,                     /* EQ_OP  */
  YYSYMBOL_NE_OP = 47,                     /* NE_OP  */
  YYSYMBOL_AND_OP = 48,                    /* AND_OP  */
  YYSYMBOL_OR_OP = 49,                     /* OR_OP  */
  YYSYMBOL_ELLIPSIS = 50,                  /* ELLIPSIS  */
  YYSYMBOL_MUL_ASSIGN = 51,                /* MUL_ASSIGN  */
  YYSYMBOL_DIV_ASSIGN = 52,                /* DIV_ASSIGN  */
  YYSYMBOL_MOD_ASSIGN = 53,                /* MOD_ASSIGN  */
  YYSYMBOL_ADD_ASSIGN = 54,                /* ADD_ASSIGN  */
  YYSYMBOL_SUB_ASSIGN = 55,                /* SUB_ASSIGN  */
  YYSYMBOL_LEFT_ASSIGN = 56,               /* LEFT_ASSIGN  */
  YYSYMBOL_RIGHT_ASSIGN = 57,              /* RIGHT_ASSIGN  */
  YYSYMBOL_AND_ASSIGN = 58,                /* AND_ASSIGN  */
  YYSYMBOL_XOR_ASSIGN = 59,                /* XOR_ASSIGN  */
  YYSYMBOL_OR_ASSIGN = 60,                 /* OR_ASSIGN  */
  YYSYMBOL_STRING_LITERAL = 61,            /* STRING_LITERAL  */
  YYSYMBOL_CONSTANT = 62,                  /* CONSTANT  */
  YYSYMBOL_TYPE_NAME = 63,                 /* TYPE_NAME  */
  YYSYMBOL_IDENTIFIER = 64,                /* IDENTIFIER  */
  YYSYMBOL_65_ = 65,                       /* '('  */
  YYSYMBOL_66_ = 66,                       /* ')'  */
  YYSYMBOL_67_ = 67,                       /* ';'  */
  YYSYMBOL_68_ = 68,                       /* ':'  */
  YYSYMBOL_69_ = 69,                       /* ','  */
  YYSYMBOL_70_ = 70,                       /* '['  */
  YYSYMBOL_71_ = 71,                       /* ']'  */
  YYSYMBOL_72_ = 72,                       /* '.'  */
  YYSYMBOL_73_ = 73,                       /* '{'  */
  YYSYMBOL_74_ = 74,                       /* '}'  */
  YYSYMBOL_75_ = 75,                       /* '&'  */
  YYSYMBOL_76_ = 76,                       /* '*'  */
  YYSYMBOL_77_ = 77,                       /* '+'  */
  YYSYMBOL_78_ = 78,                       /* '-'  */
  YYSYMBOL_79_ = 79,                       /* '~'  */
  YYSYMBOL_80_ = 80,                       /* '!'  */
  YYSYMBOL_81_ = 81,                       /* '/'  */
  YYSYMBOL_82_ = 82,                       /* '%'  */
  YYSYMBOL_83_ = 83,                       /* '<'  */
  YYSYMBOL_84_ = 84,                       /* '>'  */
  YYSYMBOL_85_ = 85,                       /* '^'  */
  YYSYMBOL_86_ = 86,                       /* '|'  */
  YYSYMBOL_87_ = 87,                       /* '?'  */
  YYSYMBOL_88_ = 88,                       /* '='  */
  YYSYMBOL_YYACCEPT = 89,                  /* $accept  */
  YYSYMBOL_string_literal_list = 90,       /* string_literal_list  */
  YYSYMBOL_asm_string = 91,                /* asm_string  */
  YYSYMBOL_asm_string_opt = 92,            /* asm_string_opt  */
  YYSYMBOL_asm_expr = 93,                  /* asm_expr  */
  YYSYMBOL_asm_statement = 94,             /* asm_statement  */
  YYSYMBOL_asm_operands_opt = 95,          /* asm_operands_opt  */
  YYSYMBOL_asm_operands = 96,              /* asm_operands  */
  YYSYMBOL_asm_operand = 97,               /* asm_operand  */
  YYSYMBOL_asm_clobbers = 98,              /* asm_clobbers  */
  YYSYMBOL_primary_expression = 99,        /* primary_expression  */
  YYSYMBOL_postfix_expression = 100,       /* postfix_expression  */
  YYSYMBOL_101_1 = 101,                    /* $@1  */
  YYSYMBOL_102_2 = 102,                    /* $@2  */
  YYSYMBOL_member_name = 103,              /* member_name  */
  YYSYMBOL_argument_expression_list = 104, /* argument_expression_list  */
  YYSYMBOL_unary_expression = 105,         /* unary_expression  */
  YYSYMBOL_unary_operator = 106,           /* unary_operator  */
  YYSYMBOL_cast_expression = 107,          /* cast_expression  */
  YYSYMBOL_multiplicative_expression = 108, /* multiplicative_expression  */
  YYSYMBOL_additive_expression = 109,      /* additive_expression  */
  YYSYMBOL_shift_expression = 110,         /* shift_expression  */
  YYSYMBOL_relational_expression = 111,    /* relational_expression  */
  YYSYMBOL_equality_expression = 112,      /* equality_expression  */
  YYSYMBOL_AND_expression = 113,           /* AND_expression  */
  YYSYMBOL_exclusive_OR_expression = 114,  /* exclusive_OR_expression  */
  YYSYMBOL_inclusive_OR_expression = 115,  /* inclusive_OR_expression  */
  YYSYMBOL_logical_AND_expression = 116,   /* logical_AND_expression  */
  YYSYMBOL_logical_OR_expression = 117,    /* logical_OR_expression  */
  YYSYMBOL_conditional_expression = 118,   /* conditional_expression  */
  YYSYMBOL_assignment_expression = 119,    /* assignment_expression  */
  YYSYMBOL_assignment_operator = 120,      /* assignment_operator  */
  YYSYMBOL_assignment_expression_opt = 121, /* assignment_expression_opt  */
  YYSYMBOL_comma_expression = 122,         /* comma_expression  */
  YYSYMBOL_constant_expression = 123,      /* constant_expression  */
  YYSYMBOL_comma_expression_opt = 124,     /* comma_expression_opt  */
  YYSYMBOL_declaration = 125,              /* declaration  */
  YYSYMBOL_default_declaring_list = 126,   /* default_declaring_list  */
  YYSYMBOL_declaring_list = 127,           /* declaring_list  */
  YYSYMBOL_declaration_specifier = 128,    /* declaration_specifier  */
  YYSYMBOL_type_specifier = 129,           /* type_specifier  */
  YYSYMBOL_declaration_qualifier_list = 130, /* declaration_qualifier_list  */
  YYSYMBOL_type_qualifier_list = 131,      /* type_qualifier_list  */
  YYSYMBOL_type_qualifier_list_opt = 132,  /* type_qualifier_list_opt  */
  YYSYMBOL_declaration_qualifier = 133,    /* declaration_qualifier  */
  YYSYMBOL_type_qualifier = 134,           /* type_qualifier  */
  YYSYMBOL_basic_declaration_specifier = 135, /* basic_declaration_specifier  */
  YYSYMBOL_basic_type_specifier = 136,     /* basic_type_specifier  */
  YYSYMBOL_sue_declaration_specifier = 137, /* sue_declaration_specifier  */
  YYSYMBOL_sue_type_specifier = 138,       /* sue_type_specifier  */
  YYSYMBOL_enum_type_specifier = 139,      /* enum_type_specifier  */
  YYSYMBOL_su_type_specifier = 140,        /* su_type_specifier  */
  YYSYMBOL_sut_type_specifier = 141,       /* sut_type_specifier  */
  YYSYMBOL_typedef_declaration_specifier = 142, /* typedef_declaration_specifier  */
  YYSYMBOL_typedef_type_specifier = 143,   /* typedef_type_specifier  */
  YYSYMBOL_storage_class = 144,            /* storage_class  */
  YYSYMBOL_basic_type_name = 145,          /* basic_type_name  */
  YYSYMBOL_elaborated_type_name = 146,     /* elaborated_type_name  */
  YYSYMBOL_aggregate_name = 147,           /* aggregate_name  */
  YYSYMBOL_aggregate_key_context = 148,    /* aggregate_key_context  */
  YYSYMBOL_aggregate_key = 149,            /* aggregate_key  */
  YYSYMBOL_member_declaration_list_opt = 150, /* member_declaration_list_opt  */
  YYSYMBOL_member_declaration_list = 151,  /* member_declaration_list  */
  YYSYMBOL_member_declaration = 152,       /* member_declaration  */
  YYSYMBOL_unnamed_su_declaration = 153,   /* unnamed_su_declaration  */
  YYSYMBOL_member_declaring_list = 154,    /* member_declaring_list  */
  YYSYMBOL_member_declarator = 155,        /* member_declarator  */
  YYSYMBOL_bit_field_size_opt = 156,       /* bit_field_size_opt  */
  YYSYMBOL_bit_field_size = 157,           /* bit_field_size  */
  YYSYMBOL_enum_name = 158,                /* enum_name  */
  YYSYMBOL_enum_key_context = 159,         /* enum_key_context  */
  YYSYMBOL_enumerator_list = 160,          /* enumerator_list  */
  YYSYMBOL_enumerator = 161,               /* enumerator  */
  YYSYMBOL_parameter_type_list = 162,      /* parameter_type_list  */
  YYSYMBOL_parameter_list = 163,           /* parameter_list  */
  YYSYMBOL_parameter_declaration = 164,    /* parameter_declaration  */
  YYSYMBOL_identifier_list = 165,          /* identifier_list  */
  YYSYMBOL_identifier_or_typedef_name = 166, /* identifier_or_typedef_name  */
  YYSYMBOL_type_name = 167,                /* type_name  */
  YYSYMBOL_initializer_opt = 168,          /* initializer_opt  */
  YYSYMBOL_initializer = 169,              /* initializer  */
  YYSYMBOL_initializer_list = 170,         /* initializer_list  */
  YYSYMBOL_designation_opt = 171,          /* designation_opt  */
  YYSYMBOL_designator_list = 172,          /* designator_list  */
  YYSYMBOL_designator = 173,               /* designator  */
  YYSYMBOL_comma_opt = 174,                /* comma_opt  */
  YYSYMBOL_statement = 175,                /* statement  */
  YYSYMBOL_labeled_statement = 176,        /* labeled_statement  */
  YYSYMBOL_compound_statement = 177,       /* compound_statement  */
  YYSYMBOL_declaration_list = 178,         /* declaration_list  */
  YYSYMBOL_statement_list = 179,           /* statement_list  */
  YYSYMBOL_expression_statement = 180,     /* expression_statement  */
  YYSYMBOL_selection_statement = 181,      /* selection_statement  */
  YYSYMBOL_iteration_statement = 182,      /* iteration_statement  */
  YYSYMBOL_jump_statement = 183,           /* jump_statement  */
  YYSYMBOL_source_file = 184,              /* source_file  */
  YYSYMBOL_translation_unit = 185,         /* translation_unit  */
  YYSYMBOL_external_definition = 186,      /* external_definition  */
  YYSYMBOL_function_definition = 187,      /* function_definition  */
  YYSYMBOL_188_3 = 188,                    /* $@3  */
  YYSYMBOL_189_4 = 189,                    /* $@4  */
  YYSYMBOL_190_5 = 190,                    /* $@5  */
  YYSYMBOL_191_6 = 191,                    /* $@6  */
  YYSYMBOL_192_7 = 192,                    /* $@7  */
  YYSYMBOL_193_8 = 193,                    /* $@8  */
  YYSYMBOL_194_9 = 194,                    /* $@9  */
  YYSYMBOL_195_10 = 195,                   /* $@10  */
  YYSYMBOL_196_11 = 196,                   /* $@11  */
  YYSYMBOL_197_12 = 197,                   /* $@12  */
  YYSYMBOL_198_13 = 198,                   /* $@13  */
  YYSYMBOL_199_14 = 199,                   /* $@14  */
  YYSYMBOL_200_15 = 200,                   /* $@15  */
  YYSYMBOL_201_16 = 201,                   /* $@16  */
  YYSYMBOL_202_17 = 202,                   /* $@17  */
  YYSYMBOL_declarator = 203,               /* declarator  */
  YYSYMBOL_typedef_declarator = 204,       /* typedef_declarator  */
  YYSYMBOL_parameter_typedef_declarator = 205, /* parameter_typedef_declarator  */
  YYSYMBOL_clean_typedef_declarator = 206, /* clean_typedef_declarator  */
  YYSYMBOL_clean_postfix_typedef_declarator = 207, /* clean_postfix_typedef_declarator  */
  YYSYMBOL_paren_typedef_declarator = 208, /* paren_typedef_declarator  */
  YYSYMBOL_paren_postfix_typedef_declarator = 209, /* paren_postfix_typedef_declarator  */
  YYSYMBOL_simple_paren_typedef_declarator = 210, /* simple_paren_typedef_declarator  */
  YYSYMBOL_identifier_declarator = 211,    /* identifier_declarator  */
  YYSYMBOL_unary_identifier_declarator = 212, /* unary_identifier_declarator  */
  YYSYMBOL_postfix_identifier_declarator = 213, /* postfix_identifier_declarator  */
  YYSYMBOL_paren_identifier_declarator = 214, /* paren_identifier_declarator  */
  YYSYMBOL_old_function_declarator = 215,  /* old_function_declarator  */
  YYSYMBOL_postfix_old_function_declarator = 216, /* postfix_old_function_declarator  */
  YYSYMBOL_abstract_declarator = 217,      /* abstract_declarator  */
  YYSYMBOL_postfixing_abstract_declarator = 218, /* postfixing_abstract_declarator  */
  YYSYMBOL_array_abstract_declarator = 219, /* array_abstract_declarator  */
  YYSYMBOL_unary_abstract_declarator = 220, /* unary_abstract_declarator  */
  YYSYMBOL_postfix_abstract_declarator = 221 /* postfix_abstract_declarator  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;


/* Second part of user prologue.  */
#line 261 "ctlib/parser.y"


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


#line 752 "ctlib/y_parser.c"


#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

/* Work around bug in HP-UX 11.23, which defines these macros
   incorrectly for preprocessor constants.  This workaround can likely
   be removed in 2023, as HPE has promised support for HP-UX 11.23
   (aka HP-UX 11i v2) only through the end of 2022; see Table 2 of
   <https://h20195.www2.hpe.com/V2/getpdf.aspx/4AA4-7673ENW.pdf>.  */
#ifdef __hpux
# undef UINT_LEAST8_MAX
# undef UINT_LEAST16_MAX
# define UINT_LEAST8_MAX 255
# define UINT_LEAST16_MAX 65535
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_int16 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YY_USE(E) ((void) (E))
#else
# define YY_USE(E) /* empty */
#endif

/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
#if defined __GNUC__ && ! defined __ICC && 406 <= __GNUC__ * 100 + __GNUC_MINOR__
# if __GNUC__ * 100 + __GNUC_MINOR__ < 407
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")
# else
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# endif
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if 1

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
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
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
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* 1 */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

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
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  618

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   319


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
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
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,   620,   620,   621,   629,   633,   634,   638,   642,   643,
     645,   648,   655,   656,   660,   661,   665,   666,   674,   675,
     680,   695,   696,   697,   707,   708,   709,   710,   711,   711,
     712,   712,   713,   714,   715,   719,   720,   724,   725,   729,
     730,   731,   732,   750,   751,   755,   756,   757,   758,   759,
     760,   764,   765,   769,   770,   772,   779,   789,   790,   792,
     797,   798,   800,   805,   806,   808,   810,   812,   817,   818,
     820,   825,   826,   831,   832,   837,   838,   843,   844,   849,
     850,   855,   856,   861,   862,   866,   867,   868,   869,   870,
     871,   872,   873,   874,   875,   876,   880,   881,   884,   885,
     889,   894,   895,   933,   934,   935,   936,   943,   967,   973,
     984,  1006,  1012,  1024,  1029,  1030,  1035,  1040,  1041,  1047,
    1048,  1049,  1053,  1054,  1058,  1059,  1063,  1064,  1068,  1069,
    1070,  1074,  1075,  1076,  1077,  1081,  1082,  1083,  1084,  1088,
    1093,  1098,  1106,  1107,  1111,  1112,  1113,  1117,  1118,  1119,
    1123,  1124,  1127,  1132,  1137,  1145,  1146,  1147,  1151,  1152,
    1153,  1154,  1155,  1156,  1160,  1161,  1162,  1163,  1164,  1165,
    1166,  1167,  1168,  1172,  1173,  1177,  1194,  1230,  1259,  1268,
    1269,  1273,  1274,  1278,  1289,  1303,  1304,  1308,  1312,  1325,
    1339,  1366,  1386,  1387,  1391,  1395,  1412,  1448,  1479,  1487,
    1502,  1521,  1534,  1550,  1551,  1555,  1556,  1560,  1561,  1562,
    1563,  1564,  1565,  1566,  1567,  1568,  1569,  1570,  1571,  1572,
    1573,  1581,  1582,  1586,  1587,  1594,  1607,  1628,  1636,  1648,
    1649,  1653,  1654,  1655,  1659,  1660,  1664,  1665,  1669,  1670,
    1674,  1675,  1679,  1680,  1685,  1686,  1687,  1688,  1689,  1690,
    1691,  1695,  1696,  1697,  1701,  1702,  1703,  1704,  1708,  1709,
    1713,  1714,  1718,  1722,  1723,  1724,  1728,  1729,  1730,  1734,
    1735,  1736,  1737,  1744,  1745,  1749,  1750,  1754,  1755,  1756,
    1760,  1760,  1762,  1762,  1764,  1764,  1766,  1766,  1768,  1768,
    1771,  1771,  1772,  1772,  1773,  1773,  1774,  1774,  1775,  1775,
    1777,  1777,  1778,  1778,  1779,  1779,  1780,  1780,  1781,  1781,
    1785,  1786,  1790,  1791,  1795,  1799,  1813,  1820,  1821,  1827,
    1836,  1837,  1848,  1849,  1855,  1861,  1867,  1876,  1877,  1882,
    1890,  1894,  1898,  1899,  1903,  1904,  1910,  1919,  1924,  1925,
    1933,  1945,  1949,  1950,  1951,  1955,  1960,  1961,  1969,  1970,
    1971,  1989,  1990,  1991,  1995,  2006,  2017,  2028,  2029,  2040,
    2054,  2059,  2064,  2069,  2077,  2078,  2079,  2094
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if 1
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "\"end of file\"", "error", "\"invalid token\"", "AUTO_TOK",
  "DOUBLE_TOK", "INT_TOK", "STRUCT_TOK", "BREAK_TOK", "ELSE_TOK",
  "LONG_TOK", "SWITCH_TOK", "CASE_TOK", "ENUM_TOK", "REGISTER_TOK",
  "TYPEDEF_TOK", "CHAR_TOK", "EXTERN_TOK", "RETURN_TOK", "UNION_TOK",
  "CONST_TOK", "FLOAT_TOK", "SHORT_TOK", "UNSIGNED_TOK", "CONTINUE_TOK",
  "FOR_TOK", "SIGNED_TOK", "VOID_TOK", "DEFAULT_TOK", "GOTO_TOK",
  "SIZEOF_TOK", "VOLATILE_TOK", "DO_TOK", "IF_TOK", "STATIC_TOK",
  "WHILE_TOK", "INLINE_TOK", "RESTRICT_TOK", "ASM_TOK", "SKIP_TOK",
  "PTR_OP", "INC_OP", "DEC_OP", "LEFT_OP", "RIGHT_OP", "LE_OP", "GE_OP",
  "EQ_OP", "NE_OP", "AND_OP", "OR_OP", "ELLIPSIS", "MUL_ASSIGN",
  "DIV_ASSIGN", "MOD_ASSIGN", "ADD_ASSIGN", "SUB_ASSIGN", "LEFT_ASSIGN",
  "RIGHT_ASSIGN", "AND_ASSIGN", "XOR_ASSIGN", "OR_ASSIGN",
  "STRING_LITERAL", "CONSTANT", "TYPE_NAME", "IDENTIFIER", "'('", "')'",
  "';'", "':'", "','", "'['", "']'", "'.'", "'{'", "'}'", "'&'", "'*'",
  "'+'", "'-'", "'~'", "'!'", "'/'", "'%'", "'<'", "'>'", "'^'", "'|'",
  "'?'", "'='", "$accept", "string_literal_list", "asm_string",
  "asm_string_opt", "asm_expr", "asm_statement", "asm_operands_opt",
  "asm_operands", "asm_operand", "asm_clobbers", "primary_expression",
  "postfix_expression", "$@1", "$@2", "member_name",
  "argument_expression_list", "unary_expression", "unary_operator",
  "cast_expression", "multiplicative_expression", "additive_expression",
  "shift_expression", "relational_expression", "equality_expression",
  "AND_expression", "exclusive_OR_expression", "inclusive_OR_expression",
  "logical_AND_expression", "logical_OR_expression",
  "conditional_expression", "assignment_expression", "assignment_operator",
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
  "postfix_abstract_declarator", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#define YYPACT_NINF (-507)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-289)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
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

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_int16 yydefact[] =
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

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
       0,   152,   196,   205,    27,   369,   586,   587,   588,   611,
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

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
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

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
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

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
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

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
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


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYNOMEM         goto yyexhaustedlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (pState, YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use YYerror or YYUNDEF. */
#define YYERRCODE YYUNDEF


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)




# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value, pState); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, ParserState *pState)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  YY_USE (pState);
  if (!yyvaluep)
    return;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  switch (yykind)
    {
    case YYSYMBOL_IDENTIFIER: /* IDENTIFIER  */
#line 421 "ctlib/parser.y"
         {
  if (((*yyvaluep).identifier))
    fprintf(yyoutput, "'%s' len=%d, hash=0x%lx", ((*yyvaluep).identifier)->key, ((*yyvaluep).identifier)->keylen, (unsigned long)((*yyvaluep).identifier)->hash);
  else
    fprintf(yyoutput, "NULL");
}
#line 2135 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_member_declarator: /* member_declarator  */
#line 501 "ctlib/parser.y"
         {
  if (((*yyvaluep).pDecl))
  {
    if (((*yyvaluep).pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", ((*yyvaluep).pDecl)->identifier, ((*yyvaluep).pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", ((*yyvaluep).pDecl)->pointer_flag ? "*" : "", ((*yyvaluep).pDecl)->identifier);

      if (((*yyvaluep).pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, ((*yyvaluep).pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
}
#line 2162 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_identifier_or_typedef_name: /* identifier_or_typedef_name  */
#line 421 "ctlib/parser.y"
         {
  if (((*yyvaluep).identifier))
    fprintf(yyoutput, "'%s' len=%d, hash=0x%lx", ((*yyvaluep).identifier)->key, ((*yyvaluep).identifier)->keylen, (unsigned long)((*yyvaluep).identifier)->hash);
  else
    fprintf(yyoutput, "NULL");
}
#line 2173 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_declarator: /* declarator  */
#line 501 "ctlib/parser.y"
         {
  if (((*yyvaluep).pDecl))
  {
    if (((*yyvaluep).pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", ((*yyvaluep).pDecl)->identifier, ((*yyvaluep).pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", ((*yyvaluep).pDecl)->pointer_flag ? "*" : "", ((*yyvaluep).pDecl)->identifier);

      if (((*yyvaluep).pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, ((*yyvaluep).pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
}
#line 2200 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_typedef_declarator: /* typedef_declarator  */
#line 501 "ctlib/parser.y"
         {
  if (((*yyvaluep).pDecl))
  {
    if (((*yyvaluep).pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", ((*yyvaluep).pDecl)->identifier, ((*yyvaluep).pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", ((*yyvaluep).pDecl)->pointer_flag ? "*" : "", ((*yyvaluep).pDecl)->identifier);

      if (((*yyvaluep).pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, ((*yyvaluep).pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
}
#line 2227 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_parameter_typedef_declarator: /* parameter_typedef_declarator  */
#line 501 "ctlib/parser.y"
         {
  if (((*yyvaluep).pDecl))
  {
    if (((*yyvaluep).pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", ((*yyvaluep).pDecl)->identifier, ((*yyvaluep).pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", ((*yyvaluep).pDecl)->pointer_flag ? "*" : "", ((*yyvaluep).pDecl)->identifier);

      if (((*yyvaluep).pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, ((*yyvaluep).pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
}
#line 2254 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_clean_typedef_declarator: /* clean_typedef_declarator  */
#line 501 "ctlib/parser.y"
         {
  if (((*yyvaluep).pDecl))
  {
    if (((*yyvaluep).pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", ((*yyvaluep).pDecl)->identifier, ((*yyvaluep).pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", ((*yyvaluep).pDecl)->pointer_flag ? "*" : "", ((*yyvaluep).pDecl)->identifier);

      if (((*yyvaluep).pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, ((*yyvaluep).pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
}
#line 2281 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_clean_postfix_typedef_declarator: /* clean_postfix_typedef_declarator  */
#line 501 "ctlib/parser.y"
         {
  if (((*yyvaluep).pDecl))
  {
    if (((*yyvaluep).pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", ((*yyvaluep).pDecl)->identifier, ((*yyvaluep).pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", ((*yyvaluep).pDecl)->pointer_flag ? "*" : "", ((*yyvaluep).pDecl)->identifier);

      if (((*yyvaluep).pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, ((*yyvaluep).pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
}
#line 2308 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_paren_typedef_declarator: /* paren_typedef_declarator  */
#line 501 "ctlib/parser.y"
         {
  if (((*yyvaluep).pDecl))
  {
    if (((*yyvaluep).pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", ((*yyvaluep).pDecl)->identifier, ((*yyvaluep).pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", ((*yyvaluep).pDecl)->pointer_flag ? "*" : "", ((*yyvaluep).pDecl)->identifier);

      if (((*yyvaluep).pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, ((*yyvaluep).pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
}
#line 2335 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_paren_postfix_typedef_declarator: /* paren_postfix_typedef_declarator  */
#line 501 "ctlib/parser.y"
         {
  if (((*yyvaluep).pDecl))
  {
    if (((*yyvaluep).pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", ((*yyvaluep).pDecl)->identifier, ((*yyvaluep).pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", ((*yyvaluep).pDecl)->pointer_flag ? "*" : "", ((*yyvaluep).pDecl)->identifier);

      if (((*yyvaluep).pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, ((*yyvaluep).pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
}
#line 2362 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_simple_paren_typedef_declarator: /* simple_paren_typedef_declarator  */
#line 501 "ctlib/parser.y"
         {
  if (((*yyvaluep).pDecl))
  {
    if (((*yyvaluep).pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", ((*yyvaluep).pDecl)->identifier, ((*yyvaluep).pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", ((*yyvaluep).pDecl)->pointer_flag ? "*" : "", ((*yyvaluep).pDecl)->identifier);

      if (((*yyvaluep).pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, ((*yyvaluep).pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
}
#line 2389 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_identifier_declarator: /* identifier_declarator  */
#line 501 "ctlib/parser.y"
         {
  if (((*yyvaluep).pDecl))
  {
    if (((*yyvaluep).pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", ((*yyvaluep).pDecl)->identifier, ((*yyvaluep).pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", ((*yyvaluep).pDecl)->pointer_flag ? "*" : "", ((*yyvaluep).pDecl)->identifier);

      if (((*yyvaluep).pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, ((*yyvaluep).pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
}
#line 2416 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_unary_identifier_declarator: /* unary_identifier_declarator  */
#line 501 "ctlib/parser.y"
         {
  if (((*yyvaluep).pDecl))
  {
    if (((*yyvaluep).pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", ((*yyvaluep).pDecl)->identifier, ((*yyvaluep).pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", ((*yyvaluep).pDecl)->pointer_flag ? "*" : "", ((*yyvaluep).pDecl)->identifier);

      if (((*yyvaluep).pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, ((*yyvaluep).pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
}
#line 2443 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_postfix_identifier_declarator: /* postfix_identifier_declarator  */
#line 501 "ctlib/parser.y"
         {
  if (((*yyvaluep).pDecl))
  {
    if (((*yyvaluep).pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", ((*yyvaluep).pDecl)->identifier, ((*yyvaluep).pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", ((*yyvaluep).pDecl)->pointer_flag ? "*" : "", ((*yyvaluep).pDecl)->identifier);

      if (((*yyvaluep).pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, ((*yyvaluep).pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
}
#line 2470 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_paren_identifier_declarator: /* paren_identifier_declarator  */
#line 501 "ctlib/parser.y"
         {
  if (((*yyvaluep).pDecl))
  {
    if (((*yyvaluep).pDecl)->bitfield_flag)
      fprintf(yyoutput, "%s:%d", ((*yyvaluep).pDecl)->identifier, ((*yyvaluep).pDecl)->ext.bitfield.bits);
    else
    {
      fprintf(yyoutput, "%s%s", ((*yyvaluep).pDecl)->pointer_flag ? "*" : "", ((*yyvaluep).pDecl)->identifier);

      if (((*yyvaluep).pDecl)->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        LL_foreach(pValue, ai, ((*yyvaluep).pDecl)->ext.array)
          fprintf(yyoutput, "[%ld]", pValue->iv);
      }
    }
  }
  else
    fprintf(yyoutput, "NULL");
}
#line 2497 "ctlib/y_parser.c"
        break;

      default:
        break;
    }
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, ParserState *pState)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep, pState);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp,
                 int yyrule, ParserState *pState)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)], pState);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule, pState); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
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


/* Context of a parse error.  */
typedef struct
{
  yy_state_t *yyssp;
  yysymbol_kind_t yytoken;
} yypcontext_t;

/* Put in YYARG at most YYARGN of the expected tokens given the
   current YYCTX, and return the number of tokens stored in YYARG.  If
   YYARG is null, return the number of expected tokens (guaranteed to
   be less than YYNTOKENS).  Return YYENOMEM on memory exhaustion.
   Return 0 if there are more than YYARGN expected tokens, yet fill
   YYARG up to YYARGN. */
static int
yypcontext_expected_tokens (const yypcontext_t *yyctx,
                            yysymbol_kind_t yyarg[], int yyargn)
{
  /* Actual size of YYARG. */
  int yycount = 0;
  int yyn = yypact[+*yyctx->yyssp];
  if (!yypact_value_is_default (yyn))
    {
      /* Start YYX at -YYN if negative to avoid negative indexes in
         YYCHECK.  In other words, skip the first -YYN actions for
         this state because they are default actions.  */
      int yyxbegin = yyn < 0 ? -yyn : 0;
      /* Stay within bounds of both yycheck and yytname.  */
      int yychecklim = YYLAST - yyn + 1;
      int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
      int yyx;
      for (yyx = yyxbegin; yyx < yyxend; ++yyx)
        if (yycheck[yyx + yyn] == yyx && yyx != YYSYMBOL_YYerror
            && !yytable_value_is_error (yytable[yyx + yyn]))
          {
            if (!yyarg)
              ++yycount;
            else if (yycount == yyargn)
              return 0;
            else
              yyarg[yycount++] = YY_CAST (yysymbol_kind_t, yyx);
          }
    }
  if (yyarg && yycount == 0 && 0 < yyargn)
    yyarg[0] = YYSYMBOL_YYEMPTY;
  return yycount;
}




#ifndef yystrlen
# if defined __GLIBC__ && defined _STRING_H
#  define yystrlen(S) (YY_CAST (YYPTRDIFF_T, strlen (S)))
# else
/* Return the length of YYSTR.  */
static YYPTRDIFF_T
yystrlen (const char *yystr)
{
  YYPTRDIFF_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
# endif
#endif

#ifndef yystpcpy
# if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#  define yystpcpy stpcpy
# else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
static char *
yystpcpy (char *yydest, const char *yysrc)
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
# endif
#endif

#ifndef yytnamerr
/* Copy to YYRES the contents of YYSTR after stripping away unnecessary
   quotes and backslashes, so that it's suitable for yyerror.  The
   heuristic is that double-quoting is unnecessary unless the string
   contains an apostrophe, a comma, or backslash (other than
   backslash-backslash).  YYSTR is taken from yytname.  If YYRES is
   null, do not copy; instead, return the length of what the result
   would have been.  */
static YYPTRDIFF_T
yytnamerr (char *yyres, const char *yystr)
{
  if (*yystr == '"')
    {
      YYPTRDIFF_T yyn = 0;
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
            else
              goto append;

          append:
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

  if (yyres)
    return yystpcpy (yyres, yystr) - yyres;
  else
    return yystrlen (yystr);
}
#endif


static int
yy_syntax_error_arguments (const yypcontext_t *yyctx,
                           yysymbol_kind_t yyarg[], int yyargn)
{
  /* Actual size of YYARG. */
  int yycount = 0;
  /* There are many possibilities here to consider:
     - If this state is a consistent state with a default action, then
       the only way this function was invoked is if the default action
       is an error action.  In that case, don't check for expected
       tokens because there are none.
     - The only way there can be no lookahead present (in yychar) is if
       this state is a consistent state with a default action.  Thus,
       detecting the absence of a lookahead is sufficient to determine
       that there is no unexpected or expected token to report.  In that
       case, just report a simple "syntax error".
     - Don't assume there isn't a lookahead just because this state is a
       consistent state with a default action.  There might have been a
       previous inconsistent state, consistent state with a non-default
       action, or user semantic action that manipulated yychar.
     - Of course, the expected token list depends on states to have
       correct lookahead information, and it depends on the parser not
       to perform extra reductions after fetching a lookahead from the
       scanner and before detecting a syntax error.  Thus, state merging
       (from LALR or IELR) and default reductions corrupt the expected
       token list.  However, the list is correct for canonical LR with
       one exception: it will still contain any token that will not be
       accepted due to an error action in a later state.
  */
  if (yyctx->yytoken != YYSYMBOL_YYEMPTY)
    {
      int yyn;
      if (yyarg)
        yyarg[yycount] = yyctx->yytoken;
      ++yycount;
      yyn = yypcontext_expected_tokens (yyctx,
                                        yyarg ? yyarg + 1 : yyarg, yyargn - 1);
      if (yyn == YYENOMEM)
        return YYENOMEM;
      else
        yycount += yyn;
    }
  return yycount;
}

/* Copy into *YYMSG, which is of size *YYMSG_ALLOC, an error message
   about the unexpected token YYTOKEN for the state stack whose top is
   YYSSP.

   Return 0 if *YYMSG was successfully written.  Return -1 if *YYMSG is
   not large enough to hold the message.  In that case, also set
   *YYMSG_ALLOC to the required number of bytes.  Return YYENOMEM if the
   required number of bytes is too large to store.  */
static int
yysyntax_error (YYPTRDIFF_T *yymsg_alloc, char **yymsg,
                const yypcontext_t *yyctx)
{
  enum { YYARGS_MAX = 5 };
  /* Internationalized format string. */
  const char *yyformat = YY_NULLPTR;
  /* Arguments of yyformat: reported tokens (one for the "unexpected",
     one per "expected"). */
  yysymbol_kind_t yyarg[YYARGS_MAX];
  /* Cumulated lengths of YYARG.  */
  YYPTRDIFF_T yysize = 0;

  /* Actual size of YYARG. */
  int yycount = yy_syntax_error_arguments (yyctx, yyarg, YYARGS_MAX);
  if (yycount == YYENOMEM)
    return YYENOMEM;

  switch (yycount)
    {
#define YYCASE_(N, S)                       \
      case N:                               \
        yyformat = S;                       \
        break
    default: /* Avoid compiler warnings. */
      YYCASE_(0, YY_("syntax error"));
      YYCASE_(1, YY_("syntax error, unexpected %s"));
      YYCASE_(2, YY_("syntax error, unexpected %s, expecting %s"));
      YYCASE_(3, YY_("syntax error, unexpected %s, expecting %s or %s"));
      YYCASE_(4, YY_("syntax error, unexpected %s, expecting %s or %s or %s"));
      YYCASE_(5, YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s"));
#undef YYCASE_
    }

  /* Compute error message size.  Don't count the "%s"s, but reserve
     room for the terminator.  */
  yysize = yystrlen (yyformat) - 2 * yycount + 1;
  {
    int yyi;
    for (yyi = 0; yyi < yycount; ++yyi)
      {
        YYPTRDIFF_T yysize1
          = yysize + yytnamerr (YY_NULLPTR, yytname[yyarg[yyi]]);
        if (yysize <= yysize1 && yysize1 <= YYSTACK_ALLOC_MAXIMUM)
          yysize = yysize1;
        else
          return YYENOMEM;
      }
  }

  if (*yymsg_alloc < yysize)
    {
      *yymsg_alloc = 2 * yysize;
      if (! (yysize <= *yymsg_alloc
             && *yymsg_alloc <= YYSTACK_ALLOC_MAXIMUM))
        *yymsg_alloc = YYSTACK_ALLOC_MAXIMUM;
      return -1;
    }

  /* Avoid sprintf, as that infringes on the user's name space.
     Don't have undefined behavior even if the translation
     produced a string with the wrong number of "%s"s.  */
  {
    char *yyp = *yymsg;
    int yyi = 0;
    while ((*yyp = *yyformat) != '\0')
      if (*yyp == '%' && yyformat[1] == 's' && yyi < yycount)
        {
          yyp += yytnamerr (yyp, yytname[yyarg[yyi++]]);
          yyformat += 2;
        }
      else
        {
          ++yyp;
          ++yyformat;
        }
  }
  return 0;
}


/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep, ParserState *pState)
{
  YY_USE (yyvaluep);
  YY_USE (pState);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  switch (yykind)
    {
    case YYSYMBOL_IDENTIFIER: /* IDENTIFIER  */
#line 412 "ctlib/parser.y"
            {
  if (((*yyvaluep).identifier))
  {
    CT_DEBUG(PARSER, ("deleting node @ %p", ((*yyvaluep).identifier)));
    HN_delete(((*yyvaluep).identifier));
  }
}
#line 2901 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_member_declaration_list_opt: /* member_declaration_list_opt  */
#line 560 "ctlib/parser.y"
            {
  if (((*yyvaluep).list))
  {
    CT_DEBUG(PARSER, ("deleting struct declaration list @ %p", ((*yyvaluep).list)));
    LL_destroy(((*yyvaluep).list), (LLDestroyFunc) structdecl_delete);
  }
}
#line 2913 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_member_declaration_list: /* member_declaration_list  */
#line 560 "ctlib/parser.y"
            {
  if (((*yyvaluep).list))
  {
    CT_DEBUG(PARSER, ("deleting struct declaration list @ %p", ((*yyvaluep).list)));
    LL_destroy(((*yyvaluep).list), (LLDestroyFunc) structdecl_delete);
  }
}
#line 2925 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_member_declaration: /* member_declaration  */
#line 457 "ctlib/parser.y"
            {
  if (((*yyvaluep).pStructDecl))
  {
    CT_DEBUG(PARSER, ("deleting struct declaration @ %p", ((*yyvaluep).pStructDecl)));
    structdecl_delete(((*yyvaluep).pStructDecl));
  }
}
#line 2937 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_unnamed_su_declaration: /* unnamed_su_declaration  */
#line 457 "ctlib/parser.y"
            {
  if (((*yyvaluep).pStructDecl))
  {
    CT_DEBUG(PARSER, ("deleting struct declaration @ %p", ((*yyvaluep).pStructDecl)));
    structdecl_delete(((*yyvaluep).pStructDecl));
  }
}
#line 2949 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_member_declaring_list: /* member_declaring_list  */
#line 457 "ctlib/parser.y"
            {
  if (((*yyvaluep).pStructDecl))
  {
    CT_DEBUG(PARSER, ("deleting struct declaration @ %p", ((*yyvaluep).pStructDecl)));
    structdecl_delete(((*yyvaluep).pStructDecl));
  }
}
#line 2961 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_member_declarator: /* member_declarator  */
#line 481 "ctlib/parser.y"
            {
  if (((*yyvaluep).pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", ((*yyvaluep).pDecl)));
    decl_delete(((*yyvaluep).pDecl));
  }
}
#line 2973 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_enumerator_list: /* enumerator_list  */
#line 543 "ctlib/parser.y"
            {
  if (((*yyvaluep).list))
  {
    CT_DEBUG(PARSER, ("deleting enumerator list @ %p", ((*yyvaluep).list)));
    LL_destroy(((*yyvaluep).list), (LLDestroyFunc) enum_delete);
  }
}
#line 2985 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_identifier_or_typedef_name: /* identifier_or_typedef_name  */
#line 412 "ctlib/parser.y"
            {
  if (((*yyvaluep).identifier))
  {
    CT_DEBUG(PARSER, ("deleting node @ %p", ((*yyvaluep).identifier)));
    HN_delete(((*yyvaluep).identifier));
  }
}
#line 2997 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_declarator: /* declarator  */
#line 481 "ctlib/parser.y"
            {
  if (((*yyvaluep).pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", ((*yyvaluep).pDecl)));
    decl_delete(((*yyvaluep).pDecl));
  }
}
#line 3009 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_typedef_declarator: /* typedef_declarator  */
#line 481 "ctlib/parser.y"
            {
  if (((*yyvaluep).pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", ((*yyvaluep).pDecl)));
    decl_delete(((*yyvaluep).pDecl));
  }
}
#line 3021 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_parameter_typedef_declarator: /* parameter_typedef_declarator  */
#line 481 "ctlib/parser.y"
            {
  if (((*yyvaluep).pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", ((*yyvaluep).pDecl)));
    decl_delete(((*yyvaluep).pDecl));
  }
}
#line 3033 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_clean_typedef_declarator: /* clean_typedef_declarator  */
#line 481 "ctlib/parser.y"
            {
  if (((*yyvaluep).pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", ((*yyvaluep).pDecl)));
    decl_delete(((*yyvaluep).pDecl));
  }
}
#line 3045 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_clean_postfix_typedef_declarator: /* clean_postfix_typedef_declarator  */
#line 481 "ctlib/parser.y"
            {
  if (((*yyvaluep).pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", ((*yyvaluep).pDecl)));
    decl_delete(((*yyvaluep).pDecl));
  }
}
#line 3057 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_paren_typedef_declarator: /* paren_typedef_declarator  */
#line 481 "ctlib/parser.y"
            {
  if (((*yyvaluep).pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", ((*yyvaluep).pDecl)));
    decl_delete(((*yyvaluep).pDecl));
  }
}
#line 3069 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_paren_postfix_typedef_declarator: /* paren_postfix_typedef_declarator  */
#line 481 "ctlib/parser.y"
            {
  if (((*yyvaluep).pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", ((*yyvaluep).pDecl)));
    decl_delete(((*yyvaluep).pDecl));
  }
}
#line 3081 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_simple_paren_typedef_declarator: /* simple_paren_typedef_declarator  */
#line 481 "ctlib/parser.y"
            {
  if (((*yyvaluep).pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", ((*yyvaluep).pDecl)));
    decl_delete(((*yyvaluep).pDecl));
  }
}
#line 3093 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_identifier_declarator: /* identifier_declarator  */
#line 481 "ctlib/parser.y"
            {
  if (((*yyvaluep).pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", ((*yyvaluep).pDecl)));
    decl_delete(((*yyvaluep).pDecl));
  }
}
#line 3105 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_unary_identifier_declarator: /* unary_identifier_declarator  */
#line 481 "ctlib/parser.y"
            {
  if (((*yyvaluep).pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", ((*yyvaluep).pDecl)));
    decl_delete(((*yyvaluep).pDecl));
  }
}
#line 3117 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_postfix_identifier_declarator: /* postfix_identifier_declarator  */
#line 481 "ctlib/parser.y"
            {
  if (((*yyvaluep).pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", ((*yyvaluep).pDecl)));
    decl_delete(((*yyvaluep).pDecl));
  }
}
#line 3129 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_paren_identifier_declarator: /* paren_identifier_declarator  */
#line 481 "ctlib/parser.y"
            {
  if (((*yyvaluep).pDecl))
  {
    CT_DEBUG(PARSER, ("deleting declarator @ %p", ((*yyvaluep).pDecl)));
    decl_delete(((*yyvaluep).pDecl));
  }
}
#line 3141 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_postfixing_abstract_declarator: /* postfixing_abstract_declarator  */
#line 551 "ctlib/parser.y"
            {
  if (((*yyvaluep).list))
  {
    CT_DEBUG(PARSER, ("deleting array list @ %p", ((*yyvaluep).list)));
    LL_destroy(((*yyvaluep).list), (LLDestroyFunc) value_delete);
  }
}
#line 3153 "ctlib/y_parser.c"
        break;

    case YYSYMBOL_array_abstract_declarator: /* array_abstract_declarator  */
#line 551 "ctlib/parser.y"
            {
  if (((*yyvaluep).list))
  {
    CT_DEBUG(PARSER, ("deleting array list @ %p", ((*yyvaluep).list)));
    LL_destroy(((*yyvaluep).list), (LLDestroyFunc) value_delete);
  }
}
#line 3165 "ctlib/y_parser.c"
        break;

      default:
        break;
    }
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}






/*----------.
| yyparse.  |
`----------*/

int
yyparse (ParserState *pState)
{
/* Lookahead token kind.  */
int yychar;


/* The semantic value of the lookahead symbol.  */
/* Default value used for initialization, for pacifying older GCCs
   or non-GCC compilers.  */
YY_INITIAL_VALUE (static YYSTYPE yyval_default;)
YYSTYPE yylval YY_INITIAL_VALUE (= yyval_default);

    /* Number of syntax errors so far.  */
    int yynerrs = 0;

    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;

  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYPTRDIFF_T yymsg_alloc = sizeof yymsgbuf;

#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = YYEMPTY; /* Cause a token to be read.  */

  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    YYNOMEM;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        YYNOMEM;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          YYNOMEM;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */


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
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex (&yylval, pState);
    }

  if (yychar <= YYEOF)
    {
      yychar = YYEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == YYerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = YYUNDEF;
      yytoken = YYSYMBOL_YYerror;
      goto yyerrlab1;
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
      if (yytable_value_is_error (yyn))
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
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
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
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 3: /* string_literal_list: string_literal_list STRING_LITERAL  */
#line 622 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-1].value), +, (yyvsp[0].value)); }
#line 3444 "ctlib/y_parser.c"
    break;

  case 17: /* asm_operand: '[' IDENTIFIER ']' STRING_LITERAL '(' comma_expression ')'  */
#line 667 "ctlib/parser.y"
          {
	    if ((yyvsp[-5].identifier))
	      HN_delete((yyvsp[-5].identifier));
	  }
#line 3453 "ctlib/y_parser.c"
    break;

  case 20: /* primary_expression: IDENTIFIER  */
#line 681 "ctlib/parser.y"
          {
	    UNDEF_VAL((yyval.value));
	    if ((yyvsp[0].identifier))
	    {
	      Enumerator *pEnum = HT_get(PSTATE->pCPI->htEnumerators,
	                                 (yyvsp[0].identifier)->key, (yyvsp[0].identifier)->keylen, (yyvsp[0].identifier)->hash);
	      if (pEnum)
	      {
	        CT_DEBUG(CLEXER, ("enum found!"));
	        (yyval.value) = pEnum->value;
	      }
	      HN_delete((yyvsp[0].identifier));
	    }
	  }
#line 3472 "ctlib/y_parser.c"
    break;

  case 22: /* primary_expression: string_literal_list  */
#line 696 "ctlib/parser.y"
                              { (yyval.value) = (yyvsp[0].value); (yyval.value).iv++; }
#line 3478 "ctlib/y_parser.c"
    break;

  case 23: /* primary_expression: '(' comma_expression ')'  */
#line 697 "ctlib/parser.y"
                                   { (yyval.value) = (yyvsp[-1].value); }
#line 3484 "ctlib/y_parser.c"
    break;

  case 25: /* postfix_expression: postfix_expression '[' comma_expression ']'  */
#line 708 "ctlib/parser.y"
                                                                { UNDEF_VAL((yyval.value)); }
#line 3490 "ctlib/y_parser.c"
    break;

  case 26: /* postfix_expression: postfix_expression '(' ')'  */
#line 709 "ctlib/parser.y"
                                                                { UNDEF_VAL((yyval.value)); }
#line 3496 "ctlib/y_parser.c"
    break;

  case 27: /* postfix_expression: postfix_expression '(' argument_expression_list ')'  */
#line 710 "ctlib/parser.y"
                                                                { UNDEF_VAL((yyval.value)); }
#line 3502 "ctlib/y_parser.c"
    break;

  case 28: /* $@1: %empty  */
#line 711 "ctlib/parser.y"
                             {}
#line 3508 "ctlib/y_parser.c"
    break;

  case 29: /* postfix_expression: postfix_expression $@1 '.' member_name  */
#line 711 "ctlib/parser.y"
                                                                { UNDEF_VAL((yyval.value)); }
#line 3514 "ctlib/y_parser.c"
    break;

  case 30: /* $@2: %empty  */
#line 712 "ctlib/parser.y"
                             {}
#line 3520 "ctlib/y_parser.c"
    break;

  case 31: /* postfix_expression: postfix_expression $@2 PTR_OP member_name  */
#line 712 "ctlib/parser.y"
                                                                { UNDEF_VAL((yyval.value)); }
#line 3526 "ctlib/y_parser.c"
    break;

  case 32: /* postfix_expression: postfix_expression INC_OP  */
#line 713 "ctlib/parser.y"
                                                                { UNDEF_VAL((yyval.value)); }
#line 3532 "ctlib/y_parser.c"
    break;

  case 33: /* postfix_expression: postfix_expression DEC_OP  */
#line 714 "ctlib/parser.y"
                                                                { UNDEF_VAL((yyval.value)); }
#line 3538 "ctlib/y_parser.c"
    break;

  case 34: /* postfix_expression: '(' type_name ')' '{' initializer_list comma_opt '}'  */
#line 715 "ctlib/parser.y"
                                                                { UNDEF_VAL((yyval.value)); }
#line 3544 "ctlib/y_parser.c"
    break;

  case 35: /* member_name: IDENTIFIER  */
#line 719 "ctlib/parser.y"
                     { if((yyvsp[0].identifier)) HN_delete((yyvsp[0].identifier)); }
#line 3550 "ctlib/y_parser.c"
    break;

  case 36: /* member_name: TYPE_NAME  */
#line 720 "ctlib/parser.y"
                    {}
#line 3556 "ctlib/y_parser.c"
    break;

  case 37: /* argument_expression_list: assignment_expression  */
#line 724 "ctlib/parser.y"
                                {}
#line 3562 "ctlib/y_parser.c"
    break;

  case 38: /* argument_expression_list: argument_expression_list ',' assignment_expression  */
#line 725 "ctlib/parser.y"
                                                             {}
#line 3568 "ctlib/y_parser.c"
    break;

  case 40: /* unary_expression: INC_OP unary_expression  */
#line 730 "ctlib/parser.y"
                                  { UNDEF_VAL((yyval.value)); }
#line 3574 "ctlib/y_parser.c"
    break;

  case 41: /* unary_expression: DEC_OP unary_expression  */
#line 731 "ctlib/parser.y"
                                  { UNDEF_VAL((yyval.value)); }
#line 3580 "ctlib/y_parser.c"
    break;

  case 42: /* unary_expression: unary_operator cast_expression  */
#line 733 "ctlib/parser.y"
          {
	    switch( (yyvsp[-1].oper) ) {
	      case '-' : UNARY_OP((yyval.value), -, (yyvsp[0].value)); break;
	      case '~' : UNARY_OP((yyval.value), ~, (yyvsp[0].value)); break;
	      case '!' : UNARY_OP((yyval.value), !, (yyvsp[0].value)); break;
	      case '+' : (yyval.value) = (yyvsp[0].value);             break;

	      case '*' :
	      case '&' :
	        (yyval.value) = (yyvsp[0].value); (yyval.value).flags |= V_IS_UNSAFE_PTROP;
	        break;

	      default:
	        UNDEF_VAL((yyval.value));
	        break;
	    }
	  }
#line 3602 "ctlib/y_parser.c"
    break;

  case 43: /* unary_expression: SIZEOF_TOK unary_expression  */
#line 750 "ctlib/parser.y"
                                       { (yyval.value) = (yyvsp[0].value); }
#line 3608 "ctlib/y_parser.c"
    break;

  case 44: /* unary_expression: SIZEOF_TOK '(' type_name ')'  */
#line 751 "ctlib/parser.y"
                                       { (yyval.value) = (yyvsp[-1].value); }
#line 3614 "ctlib/y_parser.c"
    break;

  case 45: /* unary_operator: '&'  */
#line 755 "ctlib/parser.y"
              { (yyval.oper) = '&'; }
#line 3620 "ctlib/y_parser.c"
    break;

  case 46: /* unary_operator: '*'  */
#line 756 "ctlib/parser.y"
              { (yyval.oper) = '*'; }
#line 3626 "ctlib/y_parser.c"
    break;

  case 47: /* unary_operator: '+'  */
#line 757 "ctlib/parser.y"
              { (yyval.oper) = '+'; }
#line 3632 "ctlib/y_parser.c"
    break;

  case 48: /* unary_operator: '-'  */
#line 758 "ctlib/parser.y"
              { (yyval.oper) = '-'; }
#line 3638 "ctlib/y_parser.c"
    break;

  case 49: /* unary_operator: '~'  */
#line 759 "ctlib/parser.y"
              { (yyval.oper) = '~'; }
#line 3644 "ctlib/y_parser.c"
    break;

  case 50: /* unary_operator: '!'  */
#line 760 "ctlib/parser.y"
              { (yyval.oper) = '!'; }
#line 3650 "ctlib/y_parser.c"
    break;

  case 52: /* cast_expression: '(' type_name ')' cast_expression  */
#line 765 "ctlib/parser.y"
                                            { (yyval.value) = (yyvsp[0].value); (yyval.value).flags |= V_IS_UNSAFE_CAST; }
#line 3656 "ctlib/y_parser.c"
    break;

  case 54: /* multiplicative_expression: multiplicative_expression '*' cast_expression  */
#line 771 "ctlib/parser.y"
          { BINARY_OP( (yyval.value), (yyvsp[-2].value), *, (yyvsp[0].value) ); }
#line 3662 "ctlib/y_parser.c"
    break;

  case 55: /* multiplicative_expression: multiplicative_expression '/' cast_expression  */
#line 773 "ctlib/parser.y"
          {
	    if ((yyvsp[0].value).iv == 0)
	      UNDEF_VAL((yyval.value));
	    else
	      BINARY_OP((yyval.value), (yyvsp[-2].value), /, (yyvsp[0].value));
	  }
#line 3673 "ctlib/y_parser.c"
    break;

  case 56: /* multiplicative_expression: multiplicative_expression '%' cast_expression  */
#line 780 "ctlib/parser.y"
          {
	    if ((yyvsp[0].value).iv == 0)
	      UNDEF_VAL((yyval.value));
	    else
	      BINARY_OP((yyval.value), (yyvsp[-2].value), %, (yyvsp[0].value));
	  }
#line 3684 "ctlib/y_parser.c"
    break;

  case 58: /* additive_expression: additive_expression '+' multiplicative_expression  */
#line 791 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), +, (yyvsp[0].value)); }
#line 3690 "ctlib/y_parser.c"
    break;

  case 59: /* additive_expression: additive_expression '-' multiplicative_expression  */
#line 793 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), -, (yyvsp[0].value)); }
#line 3696 "ctlib/y_parser.c"
    break;

  case 61: /* shift_expression: shift_expression LEFT_OP additive_expression  */
#line 799 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), <<, (yyvsp[0].value)); }
#line 3702 "ctlib/y_parser.c"
    break;

  case 62: /* shift_expression: shift_expression RIGHT_OP additive_expression  */
#line 801 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), >>, (yyvsp[0].value)); }
#line 3708 "ctlib/y_parser.c"
    break;

  case 64: /* relational_expression: relational_expression '<' shift_expression  */
#line 807 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), <,  (yyvsp[0].value)); }
#line 3714 "ctlib/y_parser.c"
    break;

  case 65: /* relational_expression: relational_expression '>' shift_expression  */
#line 809 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), >,  (yyvsp[0].value)); }
#line 3720 "ctlib/y_parser.c"
    break;

  case 66: /* relational_expression: relational_expression LE_OP shift_expression  */
#line 811 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), <=, (yyvsp[0].value)); }
#line 3726 "ctlib/y_parser.c"
    break;

  case 67: /* relational_expression: relational_expression GE_OP shift_expression  */
#line 813 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), >=, (yyvsp[0].value)); }
#line 3732 "ctlib/y_parser.c"
    break;

  case 69: /* equality_expression: equality_expression EQ_OP relational_expression  */
#line 819 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), ==, (yyvsp[0].value)); }
#line 3738 "ctlib/y_parser.c"
    break;

  case 70: /* equality_expression: equality_expression NE_OP relational_expression  */
#line 821 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), !=, (yyvsp[0].value)); }
#line 3744 "ctlib/y_parser.c"
    break;

  case 72: /* AND_expression: AND_expression '&' equality_expression  */
#line 827 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), &, (yyvsp[0].value)); }
#line 3750 "ctlib/y_parser.c"
    break;

  case 74: /* exclusive_OR_expression: exclusive_OR_expression '^' AND_expression  */
#line 833 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), ^, (yyvsp[0].value)); }
#line 3756 "ctlib/y_parser.c"
    break;

  case 76: /* inclusive_OR_expression: inclusive_OR_expression '|' exclusive_OR_expression  */
#line 839 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), |, (yyvsp[0].value)); }
#line 3762 "ctlib/y_parser.c"
    break;

  case 78: /* logical_AND_expression: logical_AND_expression AND_OP inclusive_OR_expression  */
#line 845 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), &&, (yyvsp[0].value)); }
#line 3768 "ctlib/y_parser.c"
    break;

  case 80: /* logical_OR_expression: logical_OR_expression OR_OP logical_AND_expression  */
#line 851 "ctlib/parser.y"
          { BINARY_OP((yyval.value), (yyvsp[-2].value), ||, (yyvsp[0].value)); }
#line 3774 "ctlib/y_parser.c"
    break;

  case 82: /* conditional_expression: logical_OR_expression '?' comma_expression ':' conditional_expression  */
#line 857 "ctlib/parser.y"
          { (yyval.value) = (yyvsp[-4].value).iv ? (yyvsp[-2].value) : (yyvsp[0].value); (yyval.value).flags |= (yyvsp[-4].value).flags; }
#line 3780 "ctlib/y_parser.c"
    break;

  case 84: /* assignment_expression: unary_expression assignment_operator assignment_expression  */
#line 862 "ctlib/parser.y"
                                                                     { UNDEF_VAL((yyval.value)); }
#line 3786 "ctlib/y_parser.c"
    break;

  case 85: /* assignment_operator: '='  */
#line 866 "ctlib/parser.y"
              {}
#line 3792 "ctlib/y_parser.c"
    break;

  case 86: /* assignment_operator: MUL_ASSIGN  */
#line 867 "ctlib/parser.y"
                     {}
#line 3798 "ctlib/y_parser.c"
    break;

  case 87: /* assignment_operator: DIV_ASSIGN  */
#line 868 "ctlib/parser.y"
                     {}
#line 3804 "ctlib/y_parser.c"
    break;

  case 88: /* assignment_operator: MOD_ASSIGN  */
#line 869 "ctlib/parser.y"
                     {}
#line 3810 "ctlib/y_parser.c"
    break;

  case 89: /* assignment_operator: ADD_ASSIGN  */
#line 870 "ctlib/parser.y"
                     {}
#line 3816 "ctlib/y_parser.c"
    break;

  case 90: /* assignment_operator: SUB_ASSIGN  */
#line 871 "ctlib/parser.y"
                     {}
#line 3822 "ctlib/y_parser.c"
    break;

  case 91: /* assignment_operator: LEFT_ASSIGN  */
#line 872 "ctlib/parser.y"
                      {}
#line 3828 "ctlib/y_parser.c"
    break;

  case 92: /* assignment_operator: RIGHT_ASSIGN  */
#line 873 "ctlib/parser.y"
                       {}
#line 3834 "ctlib/y_parser.c"
    break;

  case 93: /* assignment_operator: AND_ASSIGN  */
#line 874 "ctlib/parser.y"
                     {}
#line 3840 "ctlib/y_parser.c"
    break;

  case 94: /* assignment_operator: XOR_ASSIGN  */
#line 875 "ctlib/parser.y"
                     {}
#line 3846 "ctlib/y_parser.c"
    break;

  case 95: /* assignment_operator: OR_ASSIGN  */
#line 876 "ctlib/parser.y"
                    {}
#line 3852 "ctlib/y_parser.c"
    break;

  case 96: /* assignment_expression_opt: %empty  */
#line 880 "ctlib/parser.y"
                        { UNDEF_VAL((yyval.value)); }
#line 3858 "ctlib/y_parser.c"
    break;

  case 99: /* comma_expression: comma_expression ',' assignment_expression  */
#line 885 "ctlib/parser.y"
                                                     { (yyval.value) = (yyvsp[0].value); }
#line 3864 "ctlib/y_parser.c"
    break;

  case 102: /* comma_expression_opt: comma_expression  */
#line 895 "ctlib/parser.y"
                           {}
#line 3870 "ctlib/y_parser.c"
    break;

  case 103: /* declaration: sue_declaration_specifier ';'  */
#line 933 "ctlib/parser.y"
                                        {}
#line 3876 "ctlib/y_parser.c"
    break;

  case 104: /* declaration: sue_type_specifier ';'  */
#line 934 "ctlib/parser.y"
                                 {}
#line 3882 "ctlib/y_parser.c"
    break;

  case 105: /* declaration: declaring_list ';'  */
#line 935 "ctlib/parser.y"
                             {}
#line 3888 "ctlib/y_parser.c"
    break;

  case 106: /* declaration: default_declaring_list ';'  */
#line 936 "ctlib/parser.y"
                                     {}
#line 3894 "ctlib/y_parser.c"
    break;

  case 107: /* default_declaring_list: declaration_qualifier_list identifier_declarator asm_string_opt initializer_opt  */
#line 944 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.pTypedefList) = NULL;
	    else
	    {
	      if ((yyvsp[-3].uval) & T_TYPEDEF)
	      {
	        TypeSpec ts;
	        ts.tflags = (yyvsp[-3].uval);
	        ts.ptr    = NULL;
	        if ((ts.tflags & ANY_TYPE_NAME) == 0)
	          ts.tflags |= T_INT;
	        (yyval.pTypedefList) = typedef_list_new(ts, LL_new());
	        LL_push(PSTATE->pCPI->typedef_lists, (yyval.pTypedefList));
	        MAKE_TYPEDEF((yyval.pTypedefList), (yyvsp[-2].pDecl));
	      }
	      else
	      {
	        (yyval.pTypedefList) = NULL;
	        decl_delete((yyvsp[-2].pDecl));
	      }
	    }
	  }
#line 3922 "ctlib/y_parser.c"
    break;

  case 108: /* default_declaring_list: type_qualifier_list identifier_declarator asm_string_opt initializer_opt  */
#line 968 "ctlib/parser.y"
          {
	    (yyval.pTypedefList) = NULL;
	    if ((yyvsp[-2].pDecl))
	      decl_delete((yyvsp[-2].pDecl));
	  }
#line 3932 "ctlib/y_parser.c"
    break;

  case 109: /* default_declaring_list: default_declaring_list ',' identifier_declarator asm_string_opt initializer_opt  */
#line 974 "ctlib/parser.y"
          {
	    (yyval.pTypedefList) = (yyvsp[-4].pTypedefList);
	    if ((yyval.pTypedefList))
	      MAKE_TYPEDEF((yyval.pTypedefList), (yyvsp[-2].pDecl));
	    else if((yyvsp[-2].pDecl))
	      decl_delete((yyvsp[-2].pDecl));
	  }
#line 3944 "ctlib/y_parser.c"
    break;

  case 110: /* declaring_list: declaration_specifier declarator asm_string_opt initializer_opt  */
#line 985 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.pTypedefList) = NULL;
	    else
	    {
	      if ((yyvsp[-3].tspec).tflags & T_TYPEDEF)
	      {
	        if (((yyvsp[-3].tspec).tflags & ANY_TYPE_NAME) == 0)
	          (yyvsp[-3].tspec).tflags |= T_INT;
	        ctt_refcount_inc((yyvsp[-3].tspec).ptr);
	        (yyval.pTypedefList) = typedef_list_new((yyvsp[-3].tspec), LL_new());
	        LL_push(PSTATE->pCPI->typedef_lists, (yyval.pTypedefList));
	        MAKE_TYPEDEF((yyval.pTypedefList), (yyvsp[-2].pDecl));
	      }
	      else
	      {
	        (yyval.pTypedefList) = NULL;
	        decl_delete((yyvsp[-2].pDecl));
	      }
	    }
	  }
#line 3970 "ctlib/y_parser.c"
    break;

  case 111: /* declaring_list: type_specifier declarator asm_string_opt initializer_opt  */
#line 1007 "ctlib/parser.y"
          {
	    (yyval.pTypedefList) = NULL;
	    if ((yyvsp[-2].pDecl))
	      decl_delete((yyvsp[-2].pDecl));
	  }
#line 3980 "ctlib/y_parser.c"
    break;

  case 112: /* declaring_list: declaring_list ',' declarator asm_string_opt initializer_opt  */
#line 1013 "ctlib/parser.y"
          {
	    (yyval.pTypedefList) = (yyvsp[-4].pTypedefList);
	    if ((yyval.pTypedefList))
	      MAKE_TYPEDEF((yyval.pTypedefList), (yyvsp[-2].pDecl));
	    else if ((yyvsp[-2].pDecl))
	      decl_delete((yyvsp[-2].pDecl));
	  }
#line 3992 "ctlib/y_parser.c"
    break;

  case 113: /* declaration_specifier: basic_declaration_specifier  */
#line 1025 "ctlib/parser.y"
          {
	    (yyval.tspec).ptr    = NULL;
	    (yyval.tspec).tflags = (yyvsp[0].uval);
	  }
#line 4001 "ctlib/y_parser.c"
    break;

  case 116: /* type_specifier: basic_type_specifier  */
#line 1036 "ctlib/parser.y"
          {
	    (yyval.tspec).ptr    = NULL;
	    (yyval.tspec).tflags = (yyvsp[0].uval);
	  }
#line 4010 "ctlib/y_parser.c"
    break;

  case 120: /* declaration_qualifier_list: type_qualifier_list storage_class  */
#line 1048 "ctlib/parser.y"
                                                           { (yyval.uval) = (yyvsp[0].uval);      }
#line 4016 "ctlib/y_parser.c"
    break;

  case 121: /* declaration_qualifier_list: declaration_qualifier_list declaration_qualifier  */
#line 1049 "ctlib/parser.y"
                                                           { (yyval.uval) = (yyvsp[-1].uval) | (yyvsp[0].uval); }
#line 4022 "ctlib/y_parser.c"
    break;

  case 127: /* declaration_qualifier: type_qualifier  */
#line 1064 "ctlib/parser.y"
                         { (yyval.uval) = 0;  }
#line 4028 "ctlib/y_parser.c"
    break;

  case 131: /* basic_declaration_specifier: declaration_qualifier_list basic_type_name  */
#line 1074 "ctlib/parser.y"
                                                            { (yyval.uval) = LLC_OR((yyvsp[-1].uval), (yyvsp[0].uval)); }
#line 4034 "ctlib/y_parser.c"
    break;

  case 132: /* basic_declaration_specifier: basic_type_specifier storage_class  */
#line 1075 "ctlib/parser.y"
                                                            { (yyval.uval) = LLC_OR((yyvsp[-1].uval), (yyvsp[0].uval)); }
#line 4040 "ctlib/y_parser.c"
    break;

  case 133: /* basic_declaration_specifier: basic_declaration_specifier declaration_qualifier  */
#line 1076 "ctlib/parser.y"
                                                            { (yyval.uval) = LLC_OR((yyvsp[-1].uval), (yyvsp[0].uval)); }
#line 4046 "ctlib/y_parser.c"
    break;

  case 134: /* basic_declaration_specifier: basic_declaration_specifier basic_type_name  */
#line 1077 "ctlib/parser.y"
                                                            { (yyval.uval) = LLC_OR((yyvsp[-1].uval), (yyvsp[0].uval)); }
#line 4052 "ctlib/y_parser.c"
    break;

  case 136: /* basic_type_specifier: type_qualifier_list basic_type_name  */
#line 1082 "ctlib/parser.y"
                                                            { (yyval.uval) = (yyvsp[0].uval);             }
#line 4058 "ctlib/y_parser.c"
    break;

  case 137: /* basic_type_specifier: basic_type_specifier type_qualifier  */
#line 1083 "ctlib/parser.y"
                                                            { (yyval.uval) = (yyvsp[-1].uval);             }
#line 4064 "ctlib/y_parser.c"
    break;

  case 138: /* basic_type_specifier: basic_type_specifier basic_type_name  */
#line 1084 "ctlib/parser.y"
                                                            { (yyval.uval) = LLC_OR((yyvsp[-1].uval), (yyvsp[0].uval)); }
#line 4070 "ctlib/y_parser.c"
    break;

  case 139: /* sue_declaration_specifier: declaration_qualifier_list elaborated_type_name  */
#line 1089 "ctlib/parser.y"
          {
	    (yyval.tspec).ptr    = (yyvsp[0].tspec).ptr;
	    (yyval.tspec).tflags = (yyvsp[0].tspec).tflags | (yyvsp[-1].uval);
	  }
#line 4079 "ctlib/y_parser.c"
    break;

  case 140: /* sue_declaration_specifier: sue_type_specifier storage_class  */
#line 1094 "ctlib/parser.y"
          {
	    (yyval.tspec).ptr    = (yyvsp[-1].tspec).ptr;
	    (yyval.tspec).tflags = (yyvsp[-1].tspec).tflags | (yyvsp[0].uval);
	  }
#line 4088 "ctlib/y_parser.c"
    break;

  case 141: /* sue_declaration_specifier: sue_declaration_specifier declaration_qualifier  */
#line 1099 "ctlib/parser.y"
          {
	    (yyval.tspec).ptr    = (yyvsp[-1].tspec).ptr;
	    (yyval.tspec).tflags = (yyvsp[-1].tspec).tflags | (yyvsp[0].uval);
	  }
#line 4097 "ctlib/y_parser.c"
    break;

  case 145: /* enum_type_specifier: type_qualifier_list enum_name  */
#line 1112 "ctlib/parser.y"
                                                     { (yyval.tspec) = (yyvsp[0].tspec); }
#line 4103 "ctlib/y_parser.c"
    break;

  case 146: /* enum_type_specifier: enum_type_specifier type_qualifier  */
#line 1113 "ctlib/parser.y"
                                                     { (yyval.tspec) = (yyvsp[-1].tspec); }
#line 4109 "ctlib/y_parser.c"
    break;

  case 148: /* su_type_specifier: type_qualifier_list aggregate_name  */
#line 1118 "ctlib/parser.y"
                                                     { (yyval.tspec) = (yyvsp[0].tspec); }
#line 4115 "ctlib/y_parser.c"
    break;

  case 149: /* su_type_specifier: su_type_specifier type_qualifier  */
#line 1119 "ctlib/parser.y"
                                                     { (yyval.tspec) = (yyvsp[-1].tspec); }
#line 4121 "ctlib/y_parser.c"
    break;

  case 152: /* typedef_declaration_specifier: typedef_type_specifier storage_class  */
#line 1128 "ctlib/parser.y"
          {
	    (yyval.tspec).ptr    = (yyvsp[-1].tspec).ptr;
	    (yyval.tspec).tflags = (yyvsp[-1].tspec).tflags | (yyvsp[0].uval);
	  }
#line 4130 "ctlib/y_parser.c"
    break;

  case 153: /* typedef_declaration_specifier: declaration_qualifier_list TYPE_NAME  */
#line 1133 "ctlib/parser.y"
          {
	    (yyval.tspec).ptr    = (yyvsp[0].pTypedef);
	    (yyval.tspec).tflags = T_TYPE | (yyvsp[-1].uval);
	  }
#line 4139 "ctlib/y_parser.c"
    break;

  case 154: /* typedef_declaration_specifier: typedef_declaration_specifier declaration_qualifier  */
#line 1138 "ctlib/parser.y"
          {
	    (yyval.tspec).ptr    = (yyvsp[-1].tspec).ptr;
	    (yyval.tspec).tflags = (yyvsp[-1].tspec).tflags | (yyvsp[0].uval);
	  }
#line 4148 "ctlib/y_parser.c"
    break;

  case 155: /* typedef_type_specifier: TYPE_NAME  */
#line 1145 "ctlib/parser.y"
                                                     { (yyval.tspec).ptr = (yyvsp[0].pTypedef); (yyval.tspec).tflags = T_TYPE; }
#line 4154 "ctlib/y_parser.c"
    break;

  case 156: /* typedef_type_specifier: type_qualifier_list TYPE_NAME  */
#line 1146 "ctlib/parser.y"
                                                     { (yyval.tspec).ptr = (yyvsp[0].pTypedef); (yyval.tspec).tflags = T_TYPE; }
#line 4160 "ctlib/y_parser.c"
    break;

  case 157: /* typedef_type_specifier: typedef_type_specifier type_qualifier  */
#line 1147 "ctlib/parser.y"
                                                     { (yyval.tspec) = (yyvsp[-1].tspec);                         }
#line 4166 "ctlib/y_parser.c"
    break;

  case 158: /* storage_class: TYPEDEF_TOK  */
#line 1151 "ctlib/parser.y"
                       { (yyval.uval) = T_TYPEDEF;  }
#line 4172 "ctlib/y_parser.c"
    break;

  case 159: /* storage_class: EXTERN_TOK  */
#line 1152 "ctlib/parser.y"
                       { (yyval.uval) = 0;          }
#line 4178 "ctlib/y_parser.c"
    break;

  case 160: /* storage_class: STATIC_TOK  */
#line 1153 "ctlib/parser.y"
                       { (yyval.uval) = 0;          }
#line 4184 "ctlib/y_parser.c"
    break;

  case 161: /* storage_class: AUTO_TOK  */
#line 1154 "ctlib/parser.y"
                       { (yyval.uval) = 0;          }
#line 4190 "ctlib/y_parser.c"
    break;

  case 162: /* storage_class: REGISTER_TOK  */
#line 1155 "ctlib/parser.y"
                       { (yyval.uval) = 0;          }
#line 4196 "ctlib/y_parser.c"
    break;

  case 163: /* storage_class: INLINE_TOK  */
#line 1156 "ctlib/parser.y"
                       { (yyval.uval) = 0;          }
#line 4202 "ctlib/y_parser.c"
    break;

  case 164: /* basic_type_name: INT_TOK  */
#line 1160 "ctlib/parser.y"
                       { (yyval.uval) = T_INT;      }
#line 4208 "ctlib/y_parser.c"
    break;

  case 165: /* basic_type_name: CHAR_TOK  */
#line 1161 "ctlib/parser.y"
                       { (yyval.uval) = T_CHAR;     }
#line 4214 "ctlib/y_parser.c"
    break;

  case 166: /* basic_type_name: SHORT_TOK  */
#line 1162 "ctlib/parser.y"
                       { (yyval.uval) = T_SHORT;    }
#line 4220 "ctlib/y_parser.c"
    break;

  case 167: /* basic_type_name: LONG_TOK  */
#line 1163 "ctlib/parser.y"
                       { (yyval.uval) = T_LONG;     }
#line 4226 "ctlib/y_parser.c"
    break;

  case 168: /* basic_type_name: FLOAT_TOK  */
#line 1164 "ctlib/parser.y"
                       { (yyval.uval) = T_FLOAT;    }
#line 4232 "ctlib/y_parser.c"
    break;

  case 169: /* basic_type_name: DOUBLE_TOK  */
#line 1165 "ctlib/parser.y"
                       { (yyval.uval) = T_DOUBLE;   }
#line 4238 "ctlib/y_parser.c"
    break;

  case 170: /* basic_type_name: SIGNED_TOK  */
#line 1166 "ctlib/parser.y"
                       { (yyval.uval) = T_SIGNED;   }
#line 4244 "ctlib/y_parser.c"
    break;

  case 171: /* basic_type_name: UNSIGNED_TOK  */
#line 1167 "ctlib/parser.y"
                       { (yyval.uval) = T_UNSIGNED; }
#line 4250 "ctlib/y_parser.c"
    break;

  case 172: /* basic_type_name: VOID_TOK  */
#line 1168 "ctlib/parser.y"
                       { (yyval.uval) = T_VOID;     }
#line 4256 "ctlib/y_parser.c"
    break;

  case 175: /* aggregate_name: aggregate_key_context '{' member_declaration_list_opt '}'  */
#line 1178 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	    {
	      (yyval.tspec).tflags = 0;
	      (yyval.tspec).ptr = NULL;
	    }
	    else
	    {
	      Struct *pStruct;
	      pStruct = struct_new(NULL, 0, (yyvsp[-3].context).uval, pragma_parser_get_pack(PSTATE->pragma), (yyvsp[-1].list));
	      pStruct->context = (yyvsp[-3].context).ctx;
	      LL_push(PSTATE->pCPI->structs, pStruct);
	      (yyval.tspec).tflags = (yyvsp[-3].context).uval;
	      (yyval.tspec).ptr = pStruct;
	    }
	  }
#line 4277 "ctlib/y_parser.c"
    break;

  case 176: /* aggregate_name: aggregate_key_context identifier_or_typedef_name '{' member_declaration_list_opt '}'  */
#line 1195 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	    {
	      (yyval.tspec).tflags = 0;
	      (yyval.tspec).ptr = NULL;
	      /* identifier_or_typedef_name is NULL */
	    }
	    else
	    {
	      Struct *pStruct = HT_get(PSTATE->pCPI->htStructs, (yyvsp[-3].identifier)->key, (yyvsp[-3].identifier)->keylen, (yyvsp[-3].identifier)->hash);

	      if (pStruct == NULL)
	      {
	        pStruct = struct_new((yyvsp[-3].identifier)->key, (yyvsp[-3].identifier)->keylen, (yyvsp[-4].context).uval, pragma_parser_get_pack(PSTATE->pragma), (yyvsp[-1].list));
	        pStruct->context = (yyvsp[-4].context).ctx;
	        LL_push(PSTATE->pCPI->structs, pStruct);
	        HT_storenode(PSTATE->pCPI->htStructs, (yyvsp[-3].identifier), pStruct);
	      }
	      else
	      {
	        DELETE_NODE((yyvsp[-3].identifier));

	        if (pStruct->declarations == NULL)
	        {
	          pStruct->context      = (yyvsp[-4].context).ctx;
	          pStruct->declarations = (yyvsp[-1].list);
	          pStruct->pack         = pragma_parser_get_pack(PSTATE->pragma);
	        }
	        else
	          LL_destroy((yyvsp[-1].list), (LLDestroyFunc) structdecl_delete);
	      }
	      (yyval.tspec).tflags = (yyvsp[-4].context).uval;
	      (yyval.tspec).ptr = pStruct;
	    }
	  }
#line 4317 "ctlib/y_parser.c"
    break;

  case 177: /* aggregate_name: aggregate_key_context identifier_or_typedef_name  */
#line 1231 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	    {
	      (yyval.tspec).tflags = 0;
	      (yyval.tspec).ptr = NULL;
	      /* identifier_or_typedef_name is NULL */
	    }
	    else
	    {
	      Struct *pStruct = HT_get(PSTATE->pCPI->htStructs, (yyvsp[0].identifier)->key, (yyvsp[0].identifier)->keylen, (yyvsp[0].identifier)->hash);

	      if (pStruct == NULL)
	      {
	        pStruct = struct_new((yyvsp[0].identifier)->key, (yyvsp[0].identifier)->keylen, (yyvsp[-1].context).uval, 0, NULL);
	        pStruct->context = (yyvsp[-1].context).ctx;
	        LL_push(PSTATE->pCPI->structs, pStruct);
	        HT_storenode(PSTATE->pCPI->htStructs, (yyvsp[0].identifier), pStruct);
	      }
	      else
	        DELETE_NODE((yyvsp[0].identifier));

	      (yyval.tspec).tflags = (yyvsp[-1].context).uval;
	      (yyval.tspec).ptr = pStruct;
	    }
	  }
#line 4347 "ctlib/y_parser.c"
    break;

  case 178: /* aggregate_key_context: aggregate_key  */
#line 1260 "ctlib/parser.y"
          {
	    (yyval.context).uval     = (yyvsp[0].uval);
	    (yyval.context).ctx.pFI  = PSTATE->pFI;
	    (yyval.context).ctx.line = PSTATE->pLexer->ctok->line;
	  }
#line 4357 "ctlib/y_parser.c"
    break;

  case 179: /* aggregate_key: STRUCT_TOK  */
#line 1268 "ctlib/parser.y"
                     { (yyval.uval) = T_STRUCT; }
#line 4363 "ctlib/y_parser.c"
    break;

  case 180: /* aggregate_key: UNION_TOK  */
#line 1269 "ctlib/parser.y"
                     { (yyval.uval) = T_UNION;  }
#line 4369 "ctlib/y_parser.c"
    break;

  case 181: /* member_declaration_list_opt: %empty  */
#line 1273 "ctlib/parser.y"
                                  { (yyval.list) = IS_LOCAL ? NULL : LL_new(); }
#line 4375 "ctlib/y_parser.c"
    break;

  case 183: /* member_declaration_list: member_declaration  */
#line 1279 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      ctt_refcount_inc((yyvsp[0].pStructDecl)->type.ptr);
	      (yyval.list) = LL_new();
	      LL_push((yyval.list), (yyvsp[0].pStructDecl));
	    }
	  }
#line 4390 "ctlib/y_parser.c"
    break;

  case 184: /* member_declaration_list: member_declaration_list member_declaration  */
#line 1290 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      ctt_refcount_inc((yyvsp[0].pStructDecl)->type.ptr);
	      (yyval.list) = (yyvsp[-1].list);
	      LL_push((yyval.list), (yyvsp[0].pStructDecl));
	    }
	  }
#line 4405 "ctlib/y_parser.c"
    break;

  case 187: /* unnamed_su_declaration: sut_type_specifier  */
#line 1308 "ctlib/parser.y"
                             { (yyval.pStructDecl) = IS_LOCAL ? NULL : structdecl_new((yyvsp[0].tspec), NULL); }
#line 4411 "ctlib/y_parser.c"
    break;

  case 188: /* member_declaring_list: type_specifier member_declarator  */
#line 1313 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.pStructDecl) = NULL;
	    else
	    {
	      if (((yyvsp[-1].tspec).tflags & ANY_TYPE_NAME) == 0)
	        (yyvsp[-1].tspec).tflags |= T_INT;
	      (yyval.pStructDecl) = structdecl_new((yyvsp[-1].tspec), LL_new());
	      if ((yyvsp[0].pDecl))
	        LL_push((yyval.pStructDecl)->declarators, (yyvsp[0].pDecl));
	    }
	  }
#line 4428 "ctlib/y_parser.c"
    break;

  case 189: /* member_declaring_list: member_declaring_list ',' member_declarator  */
#line 1326 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.pStructDecl) = NULL;
	    else
	    {
	      (yyval.pStructDecl) = (yyvsp[-2].pStructDecl);
	      if ((yyvsp[0].pDecl))
	        LL_push((yyval.pStructDecl)->declarators, (yyvsp[0].pDecl));
	    }
	  }
#line 4443 "ctlib/y_parser.c"
    break;

  case 190: /* member_declarator: declarator bit_field_size_opt  */
#line 1340 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.pDecl) = NULL;
	    else
	    {
	      (yyval.pDecl) = (yyvsp[-1].pDecl);

	      if (((yyvsp[0].value).flags & V_IS_UNDEF) == 0)
	      {
	        if ((yyvsp[0].value).iv <= 0)
	        {
	          char *msg;
	          AllocF(char *, msg, 80 + CTT_IDLEN((yyvsp[-1].pDecl)));
	          sprintf(msg, "%s width for bit-field '%s'",
	                  (yyvsp[0].value).iv < 0 ? "negative" : "zero", (yyvsp[-1].pDecl)->identifier);
	          decl_delete((yyvsp[-1].pDecl));
	          yyerror(pState, msg);
	          Free(msg);
	          YYERROR;
	        }

	        (yyval.pDecl)->bitfield_flag = 1;
	        (yyval.pDecl)->ext.bitfield.bits = (unsigned char) (yyvsp[0].value).iv;
	      }
	    }
	  }
#line 4474 "ctlib/y_parser.c"
    break;

  case 191: /* member_declarator: bit_field_size  */
#line 1367 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.pDecl) = NULL;
	    else
	    {
	      if ((yyvsp[0].value).iv < 0)
	      {
	        yyerror(pState, "negative width for bit-field");
	        YYERROR;
	      }

	      (yyval.pDecl) = decl_new("", 0);
	      (yyval.pDecl)->bitfield_flag = 1;
	      (yyval.pDecl)->ext.bitfield.bits = (unsigned char) (yyvsp[0].value).iv;
	    }
	  }
#line 4495 "ctlib/y_parser.c"
    break;

  case 192: /* bit_field_size_opt: %empty  */
#line 1386 "ctlib/parser.y"
                         { UNDEF_VAL((yyval.value)); }
#line 4501 "ctlib/y_parser.c"
    break;

  case 194: /* bit_field_size: ':' constant_expression  */
#line 1391 "ctlib/parser.y"
                                  { (yyval.value) = (yyvsp[0].value); }
#line 4507 "ctlib/y_parser.c"
    break;

  case 195: /* enum_name: enum_key_context '{' enumerator_list comma_opt '}'  */
#line 1396 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	    {
	      (yyval.tspec).tflags = 0;
	      (yyval.tspec).ptr = NULL;
	      LL_destroy((yyvsp[-2].list), (LLDestroyFunc) enum_delete);
	    }
	    else
	    {
	      EnumSpecifier *pEnum = enumspec_new(NULL, 0, (yyvsp[-2].list));
	      pEnum->context = (yyvsp[-4].context).ctx;
	      LL_push(PSTATE->pCPI->enums, pEnum);
	      (yyval.tspec).tflags = T_ENUM;
	      (yyval.tspec).ptr = pEnum;
	    }
	  }
#line 4528 "ctlib/y_parser.c"
    break;

  case 196: /* enum_name: enum_key_context identifier_or_typedef_name '{' enumerator_list comma_opt '}'  */
#line 1413 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	    {
	      (yyval.tspec).tflags = 0;
	      (yyval.tspec).ptr = NULL;
	      /* identifier_or_typedef_name is NULL */
	    }
	    else
	    {
	      EnumSpecifier *pEnum = HT_get(PSTATE->pCPI->htEnums, (yyvsp[-4].identifier)->key, (yyvsp[-4].identifier)->keylen, (yyvsp[-4].identifier)->hash);

	      if (pEnum == NULL)
	      {
	        pEnum = enumspec_new((yyvsp[-4].identifier)->key, (yyvsp[-4].identifier)->keylen, (yyvsp[-2].list));
	        pEnum->context = (yyvsp[-5].context).ctx;
	        LL_push(PSTATE->pCPI->enums, pEnum);
	        HT_storenode(PSTATE->pCPI->htEnums, (yyvsp[-4].identifier), pEnum);
	      }
	      else
	      {
	        DELETE_NODE((yyvsp[-4].identifier));

	        if (pEnum->enumerators == NULL)
	        {
	          enumspec_update(pEnum, (yyvsp[-2].list));
	          pEnum->context = (yyvsp[-5].context).ctx;
	        }
	        else
	          LL_destroy((yyvsp[-2].list), (LLDestroyFunc) enum_delete);
	      }

	      (yyval.tspec).tflags = T_ENUM;
	      (yyval.tspec).ptr = pEnum;
	    }
	  }
#line 4568 "ctlib/y_parser.c"
    break;

  case 197: /* enum_name: enum_key_context identifier_or_typedef_name  */
#line 1449 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	    {
	      (yyval.tspec).tflags = 0;
	      (yyval.tspec).ptr = NULL;
	      /* identifier_or_typedef_name is NULL */
	    }
	    else
	    {
	      EnumSpecifier *pEnum = HT_get(PSTATE->pCPI->htEnums, (yyvsp[0].identifier)->key, (yyvsp[0].identifier)->keylen, (yyvsp[0].identifier)->hash);

	      if (pEnum == NULL)
	      {
	        pEnum = enumspec_new((yyvsp[0].identifier)->key, (yyvsp[0].identifier)->keylen, NULL);
	        pEnum->context = (yyvsp[-1].context).ctx;
	        LL_push(PSTATE->pCPI->enums, pEnum);
	        HT_storenode(PSTATE->pCPI->htEnums, (yyvsp[0].identifier), pEnum);
	      }
	      else
	      {
	        DELETE_NODE((yyvsp[0].identifier));
	      }

	      (yyval.tspec).tflags = T_ENUM;
	      (yyval.tspec).ptr = pEnum;
	    }
	  }
#line 4600 "ctlib/y_parser.c"
    break;

  case 198: /* enum_key_context: ENUM_TOK  */
#line 1480 "ctlib/parser.y"
          {
	    (yyval.context).ctx.pFI  = PSTATE->pFI;
	    (yyval.context).ctx.line = PSTATE->pLexer->ctok->line;
	  }
#line 4609 "ctlib/y_parser.c"
    break;

  case 199: /* enumerator_list: enumerator  */
#line 1488 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      (yyval.list) = LL_new();
	      if ((yyvsp[0].pEnum)->value.flags & V_IS_UNDEF)
	      {
	        (yyvsp[0].pEnum)->value.flags &= ~V_IS_UNDEF;
	        (yyvsp[0].pEnum)->value.iv     = 0;
	      }
	      LL_push((yyval.list), (yyvsp[0].pEnum));
	    }
	  }
#line 4628 "ctlib/y_parser.c"
    break;

  case 200: /* enumerator_list: enumerator_list ',' enumerator  */
#line 1503 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      if ((yyvsp[0].pEnum)->value.flags & V_IS_UNDEF)
	      {
	        Enumerator *pEnum = LL_get((yyvsp[-2].list), -1);
	        (yyvsp[0].pEnum)->value.flags = pEnum->value.flags;
	        (yyvsp[0].pEnum)->value.iv    = pEnum->value.iv + 1;
	      }
	      LL_push((yyvsp[-2].list), (yyvsp[0].pEnum));
	      (yyval.list) = (yyvsp[-2].list);
	    }
	  }
#line 4648 "ctlib/y_parser.c"
    break;

  case 201: /* enumerator: identifier_or_typedef_name  */
#line 1522 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	    {
	      (yyval.pEnum) = NULL;
	      /* identifier_or_typedef_name is NULL */
	    }
	    else
	    {
	      (yyval.pEnum) = enum_new((yyvsp[0].identifier)->key, (yyvsp[0].identifier)->keylen, NULL);
	      HT_storenode(PSTATE->pCPI->htEnumerators, (yyvsp[0].identifier), (yyval.pEnum));
	    }
	  }
#line 4665 "ctlib/y_parser.c"
    break;

  case 202: /* enumerator: identifier_or_typedef_name '=' constant_expression  */
#line 1535 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	    {
	      (yyval.pEnum) = NULL;
	      /* identifier_or_typedef_name is NULL */
	    }
	    else
	    {
	      (yyval.pEnum) = enum_new((yyvsp[-2].identifier)->key, (yyvsp[-2].identifier)->keylen, &(yyvsp[0].value));
	      HT_storenode(PSTATE->pCPI->htEnumerators, (yyvsp[-2].identifier), (yyval.pEnum));
	    }
	  }
#line 4682 "ctlib/y_parser.c"
    break;

  case 207: /* parameter_declaration: declaration_specifier  */
#line 1560 "ctlib/parser.y"
                                                              {}
#line 4688 "ctlib/y_parser.c"
    break;

  case 208: /* parameter_declaration: declaration_specifier abstract_declarator  */
#line 1561 "ctlib/parser.y"
                                                              {}
#line 4694 "ctlib/y_parser.c"
    break;

  case 209: /* parameter_declaration: declaration_specifier identifier_declarator  */
#line 1562 "ctlib/parser.y"
                                                              { if ((yyvsp[0].pDecl)) decl_delete((yyvsp[0].pDecl)); }
#line 4700 "ctlib/y_parser.c"
    break;

  case 210: /* parameter_declaration: declaration_specifier parameter_typedef_declarator  */
#line 1563 "ctlib/parser.y"
                                                              { if ((yyvsp[0].pDecl)) decl_delete((yyvsp[0].pDecl)); }
#line 4706 "ctlib/y_parser.c"
    break;

  case 211: /* parameter_declaration: declaration_qualifier_list  */
#line 1564 "ctlib/parser.y"
                                                              {}
#line 4712 "ctlib/y_parser.c"
    break;

  case 212: /* parameter_declaration: declaration_qualifier_list abstract_declarator  */
#line 1565 "ctlib/parser.y"
                                                              {}
#line 4718 "ctlib/y_parser.c"
    break;

  case 213: /* parameter_declaration: declaration_qualifier_list identifier_declarator  */
#line 1566 "ctlib/parser.y"
                                                              { if ((yyvsp[0].pDecl)) decl_delete((yyvsp[0].pDecl)); }
#line 4724 "ctlib/y_parser.c"
    break;

  case 214: /* parameter_declaration: type_specifier  */
#line 1567 "ctlib/parser.y"
                                                              {}
#line 4730 "ctlib/y_parser.c"
    break;

  case 215: /* parameter_declaration: type_specifier abstract_declarator  */
#line 1568 "ctlib/parser.y"
                                                              {}
#line 4736 "ctlib/y_parser.c"
    break;

  case 216: /* parameter_declaration: type_specifier identifier_declarator  */
#line 1569 "ctlib/parser.y"
                                                              { if ((yyvsp[0].pDecl)) decl_delete((yyvsp[0].pDecl)); }
#line 4742 "ctlib/y_parser.c"
    break;

  case 217: /* parameter_declaration: type_specifier parameter_typedef_declarator  */
#line 1570 "ctlib/parser.y"
                                                              { if ((yyvsp[0].pDecl)) decl_delete((yyvsp[0].pDecl)); }
#line 4748 "ctlib/y_parser.c"
    break;

  case 218: /* parameter_declaration: type_qualifier_list  */
#line 1571 "ctlib/parser.y"
                                                              {}
#line 4754 "ctlib/y_parser.c"
    break;

  case 219: /* parameter_declaration: type_qualifier_list abstract_declarator  */
#line 1572 "ctlib/parser.y"
                                                              {}
#line 4760 "ctlib/y_parser.c"
    break;

  case 220: /* parameter_declaration: type_qualifier_list identifier_declarator  */
#line 1573 "ctlib/parser.y"
                                                              { if ((yyvsp[0].pDecl)) decl_delete((yyvsp[0].pDecl)); }
#line 4766 "ctlib/y_parser.c"
    break;

  case 221: /* identifier_list: IDENTIFIER  */
#line 1581 "ctlib/parser.y"
                                         { if ((yyvsp[0].identifier)) HN_delete((yyvsp[0].identifier)); }
#line 4772 "ctlib/y_parser.c"
    break;

  case 222: /* identifier_list: identifier_list ',' IDENTIFIER  */
#line 1582 "ctlib/parser.y"
                                         { if ((yyvsp[0].identifier)) HN_delete((yyvsp[0].identifier)); }
#line 4778 "ctlib/y_parser.c"
    break;

  case 224: /* identifier_or_typedef_name: TYPE_NAME  */
#line 1588 "ctlib/parser.y"
          {
	    (yyval.identifier) = IS_LOCAL ? NULL : HN_new((yyvsp[0].pTypedef)->pDecl->identifier, CTT_IDLEN((yyvsp[0].pTypedef)->pDecl), 0);
	  }
#line 4786 "ctlib/y_parser.c"
    break;

  case 225: /* type_name: type_specifier  */
#line 1595 "ctlib/parser.y"
          {
	    if (!IS_LOCAL)
	    {
	      unsigned size;
	      u_32 flags;
	      (void) PSTATE->pCPC->get_type_info(&PSTATE->pCPC->layout, &(yyvsp[0].tspec), NULL, "sf", &size, &flags);
	      (yyval.value).iv    = size;
	      (yyval.value).flags = 0;
	      if (flags & T_UNSAFE_VAL)
	        (yyval.value).flags |= V_IS_UNSAFE;
	    }
	  }
#line 4803 "ctlib/y_parser.c"
    break;

  case 226: /* type_name: type_specifier abstract_declarator  */
#line 1608 "ctlib/parser.y"
          {
	    if (!IS_LOCAL)
	    {
	      if ((yyvsp[0].absDecl).pointer_flag)
	      {
	        (yyval.value).iv = PSTATE->pCPC->layout.ptr_size * (yyvsp[0].absDecl).multiplicator;
	        (yyval.value).flags = 0;
	      }
	      else
	      {
	        unsigned size;
	        u_32 flags;
	        (void) PSTATE->pCPC->get_type_info(&PSTATE->pCPC->layout, &(yyvsp[-1].tspec), NULL, "sf", &size, &flags);
	        (yyval.value).iv = size * (yyvsp[0].absDecl).multiplicator;
	        (yyval.value).flags = 0;
	        if (flags & T_UNSAFE_VAL)
	          (yyval.value).flags |= V_IS_UNSAFE;
	      }
	    }
	  }
#line 4828 "ctlib/y_parser.c"
    break;

  case 227: /* type_name: type_qualifier_list  */
#line 1629 "ctlib/parser.y"
          {
	    if (!IS_LOCAL)
	    {
	      (yyval.value).iv = PSTATE->pCPC->layout.int_size;
	      (yyval.value).flags = 0;
	    }
	  }
#line 4840 "ctlib/y_parser.c"
    break;

  case 228: /* type_name: type_qualifier_list abstract_declarator  */
#line 1637 "ctlib/parser.y"
          {
	    if (!IS_LOCAL)
	    {
	      (yyval.value).iv = (yyvsp[0].absDecl).multiplicator * ((yyvsp[0].absDecl).pointer_flag ?
	              PSTATE->pCPC->layout.ptr_size : PSTATE->pCPC->layout.int_size);
	      (yyval.value).flags = 0;
	    }
	  }
#line 4853 "ctlib/y_parser.c"
    break;

  case 233: /* initializer: assignment_expression  */
#line 1655 "ctlib/parser.y"
                                {}
#line 4859 "ctlib/y_parser.c"
    break;

  case 241: /* designator: '.' identifier_or_typedef_name  */
#line 1675 "ctlib/parser.y"
                                         { DELETE_NODE((yyvsp[0].identifier)); }
#line 4865 "ctlib/y_parser.c"
    break;

  case 251: /* labeled_statement: identifier_or_typedef_name ':' statement  */
#line 1695 "ctlib/parser.y"
                                                   { DELETE_NODE((yyvsp[-2].identifier)); }
#line 4871 "ctlib/y_parser.c"
    break;

  case 269: /* jump_statement: GOTO_TOK identifier_or_typedef_name ';'  */
#line 1734 "ctlib/parser.y"
                                                  { DELETE_NODE((yyvsp[-1].identifier)); }
#line 4877 "ctlib/y_parser.c"
    break;

  case 280: /* $@3: %empty  */
#line 1760 "ctlib/parser.y"
                                                           { BEGIN_LOCAL; }
#line 4883 "ctlib/y_parser.c"
    break;

  case 281: /* function_definition: identifier_declarator $@3 compound_statement  */
#line 1761 "ctlib/parser.y"
                                                           { END_LOCAL; decl_delete((yyvsp[-2].pDecl)); }
#line 4889 "ctlib/y_parser.c"
    break;

  case 282: /* $@4: %empty  */
#line 1762 "ctlib/parser.y"
                                                           { BEGIN_LOCAL; }
#line 4895 "ctlib/y_parser.c"
    break;

  case 283: /* function_definition: declaration_specifier identifier_declarator $@4 compound_statement  */
#line 1763 "ctlib/parser.y"
                                                           { END_LOCAL; decl_delete((yyvsp[-2].pDecl)); }
#line 4901 "ctlib/y_parser.c"
    break;

  case 284: /* $@5: %empty  */
#line 1764 "ctlib/parser.y"
                                                           { BEGIN_LOCAL; }
#line 4907 "ctlib/y_parser.c"
    break;

  case 285: /* function_definition: type_specifier identifier_declarator $@5 compound_statement  */
#line 1765 "ctlib/parser.y"
                                                           { END_LOCAL; decl_delete((yyvsp[-2].pDecl)); }
#line 4913 "ctlib/y_parser.c"
    break;

  case 286: /* $@6: %empty  */
#line 1766 "ctlib/parser.y"
                                                           { BEGIN_LOCAL; }
#line 4919 "ctlib/y_parser.c"
    break;

  case 287: /* function_definition: declaration_qualifier_list identifier_declarator $@6 compound_statement  */
#line 1767 "ctlib/parser.y"
                                                           { END_LOCAL; decl_delete((yyvsp[-2].pDecl)); }
#line 4925 "ctlib/y_parser.c"
    break;

  case 288: /* $@7: %empty  */
#line 1768 "ctlib/parser.y"
                                                           { BEGIN_LOCAL; }
#line 4931 "ctlib/y_parser.c"
    break;

  case 289: /* function_definition: type_qualifier_list identifier_declarator $@7 compound_statement  */
#line 1769 "ctlib/parser.y"
                                                           { END_LOCAL; decl_delete((yyvsp[-2].pDecl)); }
#line 4937 "ctlib/y_parser.c"
    break;

  case 290: /* $@8: %empty  */
#line 1771 "ctlib/parser.y"
                                                             { BEGIN_LOCAL; }
#line 4943 "ctlib/y_parser.c"
    break;

  case 291: /* function_definition: old_function_declarator $@8 compound_statement  */
#line 1771 "ctlib/parser.y"
                                                                                                 { END_LOCAL; }
#line 4949 "ctlib/y_parser.c"
    break;

  case 292: /* $@9: %empty  */
#line 1772 "ctlib/parser.y"
                                                             { BEGIN_LOCAL; }
#line 4955 "ctlib/y_parser.c"
    break;

  case 293: /* function_definition: declaration_specifier old_function_declarator $@9 compound_statement  */
#line 1772 "ctlib/parser.y"
                                                                                                 { END_LOCAL; }
#line 4961 "ctlib/y_parser.c"
    break;

  case 294: /* $@10: %empty  */
#line 1773 "ctlib/parser.y"
                                                             { BEGIN_LOCAL; }
#line 4967 "ctlib/y_parser.c"
    break;

  case 295: /* function_definition: type_specifier old_function_declarator $@10 compound_statement  */
#line 1773 "ctlib/parser.y"
                                                                                                 { END_LOCAL; }
#line 4973 "ctlib/y_parser.c"
    break;

  case 296: /* $@11: %empty  */
#line 1774 "ctlib/parser.y"
                                                             { BEGIN_LOCAL; }
#line 4979 "ctlib/y_parser.c"
    break;

  case 297: /* function_definition: declaration_qualifier_list old_function_declarator $@11 compound_statement  */
#line 1774 "ctlib/parser.y"
                                                                                                 { END_LOCAL; }
#line 4985 "ctlib/y_parser.c"
    break;

  case 298: /* $@12: %empty  */
#line 1775 "ctlib/parser.y"
                                                             { BEGIN_LOCAL; }
#line 4991 "ctlib/y_parser.c"
    break;

  case 299: /* function_definition: type_qualifier_list old_function_declarator $@12 compound_statement  */
#line 1775 "ctlib/parser.y"
                                                                                                 { END_LOCAL; }
#line 4997 "ctlib/y_parser.c"
    break;

  case 300: /* $@13: %empty  */
#line 1777 "ctlib/parser.y"
                                                                              { BEGIN_LOCAL; }
#line 5003 "ctlib/y_parser.c"
    break;

  case 301: /* function_definition: old_function_declarator declaration_list $@13 compound_statement  */
#line 1777 "ctlib/parser.y"
                                                                                                                  { END_LOCAL; }
#line 5009 "ctlib/y_parser.c"
    break;

  case 302: /* $@14: %empty  */
#line 1778 "ctlib/parser.y"
                                                                              { BEGIN_LOCAL; }
#line 5015 "ctlib/y_parser.c"
    break;

  case 303: /* function_definition: declaration_specifier old_function_declarator declaration_list $@14 compound_statement  */
#line 1778 "ctlib/parser.y"
                                                                                                                  { END_LOCAL; }
#line 5021 "ctlib/y_parser.c"
    break;

  case 304: /* $@15: %empty  */
#line 1779 "ctlib/parser.y"
                                                                              { BEGIN_LOCAL; }
#line 5027 "ctlib/y_parser.c"
    break;

  case 305: /* function_definition: type_specifier old_function_declarator declaration_list $@15 compound_statement  */
#line 1779 "ctlib/parser.y"
                                                                                                                  { END_LOCAL; }
#line 5033 "ctlib/y_parser.c"
    break;

  case 306: /* $@16: %empty  */
#line 1780 "ctlib/parser.y"
                                                                              { BEGIN_LOCAL; }
#line 5039 "ctlib/y_parser.c"
    break;

  case 307: /* function_definition: declaration_qualifier_list old_function_declarator declaration_list $@16 compound_statement  */
#line 1780 "ctlib/parser.y"
                                                                                                                  { END_LOCAL; }
#line 5045 "ctlib/y_parser.c"
    break;

  case 308: /* $@17: %empty  */
#line 1781 "ctlib/parser.y"
                                                                              { BEGIN_LOCAL; }
#line 5051 "ctlib/y_parser.c"
    break;

  case 309: /* function_definition: type_qualifier_list old_function_declarator declaration_list $@17 compound_statement  */
#line 1781 "ctlib/parser.y"
                                                                                                                  { END_LOCAL; }
#line 5057 "ctlib/y_parser.c"
    break;

  case 314: /* parameter_typedef_declarator: TYPE_NAME  */
#line 1796 "ctlib/parser.y"
          {
	    (yyval.pDecl) = IS_LOCAL ? NULL : decl_new((yyvsp[0].pTypedef)->pDecl->identifier, CTT_IDLEN((yyvsp[0].pTypedef)->pDecl));
	  }
#line 5065 "ctlib/y_parser.c"
    break;

  case 315: /* parameter_typedef_declarator: TYPE_NAME postfixing_abstract_declarator  */
#line 1800 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.pDecl) = NULL;
	    else
	    {
	      (yyval.pDecl) = decl_new((yyvsp[-1].pTypedef)->pDecl->identifier, CTT_IDLEN((yyvsp[-1].pTypedef)->pDecl));
	      if ((yyvsp[0].list))
	      {
	        (yyval.pDecl)->array_flag = 1;
	        (yyval.pDecl)->ext.array = (yyvsp[0].list);
	      }
	    }
	  }
#line 5083 "ctlib/y_parser.c"
    break;

  case 318: /* clean_typedef_declarator: '*' parameter_typedef_declarator  */
#line 1822 "ctlib/parser.y"
          {
	    if ((yyvsp[0].pDecl))
	      (yyvsp[0].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[0].pDecl);
	  }
#line 5093 "ctlib/y_parser.c"
    break;

  case 319: /* clean_typedef_declarator: '*' type_qualifier_list parameter_typedef_declarator  */
#line 1828 "ctlib/parser.y"
          {
	    if ((yyvsp[0].pDecl))
	      (yyvsp[0].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[0].pDecl);
	  }
#line 5103 "ctlib/y_parser.c"
    break;

  case 320: /* clean_postfix_typedef_declarator: '(' clean_typedef_declarator ')'  */
#line 1836 "ctlib/parser.y"
                                           { (yyval.pDecl) = (yyvsp[-1].pDecl); }
#line 5109 "ctlib/y_parser.c"
    break;

  case 321: /* clean_postfix_typedef_declarator: '(' clean_typedef_declarator ')' postfixing_abstract_declarator  */
#line 1838 "ctlib/parser.y"
          {
	    POSTFIX_DECL((yyvsp[-2].pDecl), (yyvsp[0].list));
	    (yyval.pDecl) = (yyvsp[-2].pDecl);
	  }
#line 5118 "ctlib/y_parser.c"
    break;

  case 323: /* paren_typedef_declarator: '*' '(' simple_paren_typedef_declarator ')'  */
#line 1850 "ctlib/parser.y"
          {
	    if ((yyvsp[-1].pDecl))
	      (yyvsp[-1].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[-1].pDecl);
	  }
#line 5128 "ctlib/y_parser.c"
    break;

  case 324: /* paren_typedef_declarator: '*' type_qualifier_list '(' simple_paren_typedef_declarator ')'  */
#line 1856 "ctlib/parser.y"
          {
	    if ((yyvsp[-1].pDecl))
	      (yyvsp[-1].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[-1].pDecl);
	  }
#line 5138 "ctlib/y_parser.c"
    break;

  case 325: /* paren_typedef_declarator: '*' paren_typedef_declarator  */
#line 1862 "ctlib/parser.y"
          {
	    if ((yyvsp[0].pDecl))
	      (yyvsp[0].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[0].pDecl);
	  }
#line 5148 "ctlib/y_parser.c"
    break;

  case 326: /* paren_typedef_declarator: '*' type_qualifier_list paren_typedef_declarator  */
#line 1868 "ctlib/parser.y"
          {
	    if ((yyvsp[0].pDecl))
	      (yyvsp[0].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[0].pDecl);
	  }
#line 5158 "ctlib/y_parser.c"
    break;

  case 327: /* paren_postfix_typedef_declarator: '(' paren_typedef_declarator ')'  */
#line 1876 "ctlib/parser.y"
                                           { (yyval.pDecl) = (yyvsp[-1].pDecl); }
#line 5164 "ctlib/y_parser.c"
    break;

  case 328: /* paren_postfix_typedef_declarator: '(' simple_paren_typedef_declarator postfixing_abstract_declarator ')'  */
#line 1878 "ctlib/parser.y"
          {
	    POSTFIX_DECL((yyvsp[-2].pDecl), (yyvsp[-1].list));
	    (yyval.pDecl) = (yyvsp[-2].pDecl);
	  }
#line 5173 "ctlib/y_parser.c"
    break;

  case 329: /* paren_postfix_typedef_declarator: '(' paren_typedef_declarator ')' postfixing_abstract_declarator  */
#line 1883 "ctlib/parser.y"
          {
	    POSTFIX_DECL((yyvsp[-2].pDecl), (yyvsp[0].list));
	    (yyval.pDecl) = (yyvsp[-2].pDecl);
	  }
#line 5182 "ctlib/y_parser.c"
    break;

  case 330: /* simple_paren_typedef_declarator: TYPE_NAME  */
#line 1891 "ctlib/parser.y"
          {
	    (yyval.pDecl) = IS_LOCAL ? NULL : decl_new((yyvsp[0].pTypedef)->pDecl->identifier, CTT_IDLEN((yyvsp[0].pTypedef)->pDecl));
	  }
#line 5190 "ctlib/y_parser.c"
    break;

  case 331: /* simple_paren_typedef_declarator: '(' simple_paren_typedef_declarator ')'  */
#line 1894 "ctlib/parser.y"
                                                  { (yyval.pDecl) = (yyvsp[-1].pDecl); }
#line 5196 "ctlib/y_parser.c"
    break;

  case 335: /* unary_identifier_declarator: '*' identifier_declarator  */
#line 1905 "ctlib/parser.y"
          {
	    if ((yyvsp[0].pDecl))
	      (yyvsp[0].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[0].pDecl);
	  }
#line 5206 "ctlib/y_parser.c"
    break;

  case 336: /* unary_identifier_declarator: '*' type_qualifier_list identifier_declarator  */
#line 1911 "ctlib/parser.y"
          {
	    if ((yyvsp[0].pDecl))
	      (yyvsp[0].pDecl)->pointer_flag = 1;
	    (yyval.pDecl) = (yyvsp[0].pDecl);
	  }
#line 5216 "ctlib/y_parser.c"
    break;

  case 337: /* postfix_identifier_declarator: paren_identifier_declarator postfixing_abstract_declarator  */
#line 1920 "ctlib/parser.y"
          {
	    POSTFIX_DECL((yyvsp[-1].pDecl), (yyvsp[0].list));
	    (yyval.pDecl) = (yyvsp[-1].pDecl);
	  }
#line 5225 "ctlib/y_parser.c"
    break;

  case 338: /* postfix_identifier_declarator: '(' unary_identifier_declarator ')'  */
#line 1924 "ctlib/parser.y"
                                              { (yyval.pDecl) = (yyvsp[-1].pDecl); }
#line 5231 "ctlib/y_parser.c"
    break;

  case 339: /* postfix_identifier_declarator: '(' unary_identifier_declarator ')' postfixing_abstract_declarator  */
#line 1926 "ctlib/parser.y"
          {
	    POSTFIX_DECL((yyvsp[-2].pDecl), (yyvsp[0].list));
	    (yyval.pDecl) = (yyvsp[-2].pDecl);
	  }
#line 5240 "ctlib/y_parser.c"
    break;

  case 340: /* paren_identifier_declarator: IDENTIFIER  */
#line 1934 "ctlib/parser.y"
          {
	    if ((yyvsp[0].identifier))
	    {
	      (yyval.pDecl) = decl_new((yyvsp[0].identifier)->key, (yyvsp[0].identifier)->keylen);
	      HN_delete((yyvsp[0].identifier));
	    }
	    else
	    {
	      (yyval.pDecl) = NULL;
	    }
	  }
#line 5256 "ctlib/y_parser.c"
    break;

  case 341: /* paren_identifier_declarator: '(' paren_identifier_declarator ')'  */
#line 1945 "ctlib/parser.y"
                                              { (yyval.pDecl) = (yyvsp[-1].pDecl); }
#line 5262 "ctlib/y_parser.c"
    break;

  case 342: /* old_function_declarator: postfix_old_function_declarator  */
#line 1949 "ctlib/parser.y"
                                          {}
#line 5268 "ctlib/y_parser.c"
    break;

  case 343: /* old_function_declarator: '*' old_function_declarator  */
#line 1950 "ctlib/parser.y"
                                      {}
#line 5274 "ctlib/y_parser.c"
    break;

  case 344: /* old_function_declarator: '*' type_qualifier_list old_function_declarator  */
#line 1951 "ctlib/parser.y"
                                                          {}
#line 5280 "ctlib/y_parser.c"
    break;

  case 345: /* postfix_old_function_declarator: paren_identifier_declarator '(' identifier_list ')'  */
#line 1956 "ctlib/parser.y"
          {
	    if ((yyvsp[-3].pDecl))
	      decl_delete((yyvsp[-3].pDecl));
	  }
#line 5289 "ctlib/y_parser.c"
    break;

  case 346: /* postfix_old_function_declarator: '(' old_function_declarator ')'  */
#line 1960 "ctlib/parser.y"
                                          {}
#line 5295 "ctlib/y_parser.c"
    break;

  case 347: /* postfix_old_function_declarator: '(' old_function_declarator ')' postfixing_abstract_declarator  */
#line 1962 "ctlib/parser.y"
          {
	    if ((yyvsp[0].list))
	      LL_destroy((yyvsp[0].list), (LLDestroyFunc) value_delete);
	  }
#line 5304 "ctlib/y_parser.c"
    break;

  case 350: /* abstract_declarator: postfixing_abstract_declarator  */
#line 1972 "ctlib/parser.y"
          {
	    (yyval.absDecl).pointer_flag  = 0;
	    (yyval.absDecl).multiplicator = 1;
	    if ((yyvsp[0].list))
	    {
	      ListIterator ai;
	      Value *pValue;

	      LL_foreach(pValue, ai, (yyvsp[0].list))
	        (yyval.absDecl).multiplicator *= pValue->iv;

	      LL_destroy((yyvsp[0].list), (LLDestroyFunc) value_delete);
	    }
	  }
#line 5323 "ctlib/y_parser.c"
    break;

  case 352: /* postfixing_abstract_declarator: '(' ')'  */
#line 1990 "ctlib/parser.y"
                                      { (yyval.list) = NULL; }
#line 5329 "ctlib/y_parser.c"
    break;

  case 353: /* postfixing_abstract_declarator: '(' parameter_type_list ')'  */
#line 1991 "ctlib/parser.y"
                                      { (yyval.list) = NULL; }
#line 5335 "ctlib/y_parser.c"
    break;

  case 354: /* array_abstract_declarator: '[' type_qualifier_list_opt assignment_expression_opt ']'  */
#line 1996 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      (yyval.list) = LL_new();
	      LL_push((yyval.list), value_new((yyvsp[-1].value).iv, (yyvsp[-1].value).flags));
	      CT_DEBUG(PARSER, ("array dimension => %ld", (yyvsp[-1].value).iv));
	    }
	  }
#line 5350 "ctlib/y_parser.c"
    break;

  case 355: /* array_abstract_declarator: '[' STATIC_TOK type_qualifier_list_opt assignment_expression ']'  */
#line 2007 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      (yyval.list) = LL_new();
	      LL_push((yyval.list), value_new((yyvsp[-1].value).iv, (yyvsp[-1].value).flags));
	      CT_DEBUG(PARSER, ("array dimension => %ld", (yyvsp[-1].value).iv));
	    }
	  }
#line 5365 "ctlib/y_parser.c"
    break;

  case 356: /* array_abstract_declarator: '[' type_qualifier_list STATIC_TOK assignment_expression ']'  */
#line 2018 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      (yyval.list) = LL_new();
	      LL_push((yyval.list), value_new((yyvsp[-1].value).iv, (yyvsp[-1].value).flags));
	      CT_DEBUG(PARSER, ("array dimension => %ld", (yyvsp[-1].value).iv));
	    }
	  }
#line 5380 "ctlib/y_parser.c"
    break;

  case 357: /* array_abstract_declarator: '[' type_qualifier_list_opt '*' ']'  */
#line 2028 "ctlib/parser.y"
                                              { (yyval.list) = NULL; }
#line 5386 "ctlib/y_parser.c"
    break;

  case 358: /* array_abstract_declarator: array_abstract_declarator '[' assignment_expression ']'  */
#line 2030 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      (yyval.list) = (yyvsp[-3].list) ? (yyvsp[-3].list) : LL_new();
	      LL_push((yyval.list), value_new((yyvsp[-1].value).iv, (yyvsp[-1].value).flags));
	      CT_DEBUG(PARSER, ("array dimension => %ld", (yyvsp[-1].value).iv));
	    }
	  }
#line 5401 "ctlib/y_parser.c"
    break;

  case 359: /* array_abstract_declarator: array_abstract_declarator '[' '*' ']'  */
#line 2041 "ctlib/parser.y"
          {
	    if (IS_LOCAL)
	      (yyval.list) = NULL;
	    else
	    {
	      (yyval.list) = (yyvsp[-3].list) ? (yyvsp[-3].list) : LL_new();
	      LL_push((yyval.list), value_new(0, 0));
	      CT_DEBUG(PARSER, ("array dimension => *" ));
	    }
	  }
#line 5416 "ctlib/y_parser.c"
    break;

  case 360: /* unary_abstract_declarator: '*'  */
#line 2055 "ctlib/parser.y"
          {
	    (yyval.absDecl).pointer_flag = 1;
	    (yyval.absDecl).multiplicator = 1;
	  }
#line 5425 "ctlib/y_parser.c"
    break;

  case 361: /* unary_abstract_declarator: '*' type_qualifier_list  */
#line 2060 "ctlib/parser.y"
          {
	    (yyval.absDecl).pointer_flag = 1;
	    (yyval.absDecl).multiplicator = 1;
	  }
#line 5434 "ctlib/y_parser.c"
    break;

  case 362: /* unary_abstract_declarator: '*' abstract_declarator  */
#line 2065 "ctlib/parser.y"
          {
	    (yyvsp[0].absDecl).pointer_flag = 1;
	    (yyval.absDecl) = (yyvsp[0].absDecl);
	  }
#line 5443 "ctlib/y_parser.c"
    break;

  case 363: /* unary_abstract_declarator: '*' type_qualifier_list abstract_declarator  */
#line 2070 "ctlib/parser.y"
          {
	    (yyvsp[0].absDecl).pointer_flag = 1;
	    (yyval.absDecl) = (yyvsp[0].absDecl);
	  }
#line 5452 "ctlib/y_parser.c"
    break;

  case 364: /* postfix_abstract_declarator: '(' unary_abstract_declarator ')'  */
#line 2077 "ctlib/parser.y"
                                            { (yyval.absDecl) = (yyvsp[-1].absDecl); }
#line 5458 "ctlib/y_parser.c"
    break;

  case 365: /* postfix_abstract_declarator: '(' postfix_abstract_declarator ')'  */
#line 2078 "ctlib/parser.y"
                                              { (yyval.absDecl) = (yyvsp[-1].absDecl); }
#line 5464 "ctlib/y_parser.c"
    break;

  case 366: /* postfix_abstract_declarator: '(' postfixing_abstract_declarator ')'  */
#line 2080 "ctlib/parser.y"
          {
	    (yyval.absDecl).pointer_flag  = 0;
	    (yyval.absDecl).multiplicator = 1;
	    if ((yyvsp[-1].list))
	    {
	      ListIterator ai;
	      Value *pValue;

	      LL_foreach(pValue, ai, (yyvsp[-1].list))
	        (yyval.absDecl).multiplicator *= pValue->iv;

	      LL_destroy((yyvsp[-1].list), (LLDestroyFunc) value_delete);
	    }
	  }
#line 5483 "ctlib/y_parser.c"
    break;

  case 367: /* postfix_abstract_declarator: '(' unary_abstract_declarator ')' postfixing_abstract_declarator  */
#line 2095 "ctlib/parser.y"
          {
	    (yyval.absDecl) = (yyvsp[-2].absDecl);
	    if ((yyvsp[0].list))
	      LL_destroy((yyvsp[0].list), (LLDestroyFunc) value_delete);
	  }
#line 5493 "ctlib/y_parser.c"
    break;


#line 5497 "ctlib/y_parser.c"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      {
        yypcontext_t yyctx
          = {yyssp, yytoken};
        char const *yymsgp = YY_("syntax error");
        int yysyntax_error_status;
        yysyntax_error_status = yysyntax_error (&yymsg_alloc, &yymsg, &yyctx);
        if (yysyntax_error_status == 0)
          yymsgp = yymsg;
        else if (yysyntax_error_status == -1)
          {
            if (yymsg != yymsgbuf)
              YYSTACK_FREE (yymsg);
            yymsg = YY_CAST (char *,
                             YYSTACK_ALLOC (YY_CAST (YYSIZE_T, yymsg_alloc)));
            if (yymsg)
              {
                yysyntax_error_status
                  = yysyntax_error (&yymsg_alloc, &yymsg, &yyctx);
                yymsgp = yymsg;
              }
            else
              {
                yymsg = yymsgbuf;
                yymsg_alloc = sizeof yymsgbuf;
                yysyntax_error_status = YYENOMEM;
              }
          }
        yyerror (pState, yymsgp);
        if (yysyntax_error_status == YYENOMEM)
          YYNOMEM;
      }
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
                      yytoken, &yylval, pState);
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
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;
  ++yynerrs;

  /* Do not reclaim the symbols of the rule whose action triggered
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
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
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
                  YY_ACCESSING_SYMBOL (yystate), yyvsp, pState);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturnlab;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturnlab;


/*-----------------------------------------------------------.
| yyexhaustedlab -- YYNOMEM (memory exhaustion) comes here.  |
`-----------------------------------------------------------*/
yyexhaustedlab:
  yyerror (pState, YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturnlab;


/*----------------------------------------------------------.
| yyreturnlab -- parsing is finished, clean up and return.  |
`----------------------------------------------------------*/
yyreturnlab:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval, pState);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp, pState);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
  if (yymsg != yymsgbuf)
    YYSTACK_FREE (yymsg);
  return yyresult;
}

#line 2102 "ctlib/parser.y"



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
