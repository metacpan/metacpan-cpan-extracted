/*
@(#)File:           $RCSfile: sqltoken.c,v $
@(#)Version:        $Revision: 2016.1 $
@(#)Last changed:   $Date: 2016/01/17 19:21:46 $
@(#)Purpose:        Identify SQL token in string
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1998-2005,2008-09,2016
@(#)Product:        Informix Database Driver for Perl DBI Version 2018.1031 (2018-10-31)
*/

/*TABSTOP=4*/

#include "sqltoken.h"
#include "debug.h"
#include <assert.h>
#include <ctype.h>
#include <string.h>

/* Simulate C++ const_cast<type>(value) */
#ifdef __cplusplus
#define CONST_CAST(type, value) const_cast<type>(value)
#else
#define CONST_CAST(type, value) ((type)(value))
#endif /* __cplusplus */

#define LCURLY '{'
#define RCURLY '}'
#define STAR   '*'
#define SLASH  '/'
#define PLUS   '+'
#define DASH   '-'

#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
extern const char jlss_id_sqltoken_c[];
const char jlss_id_sqltoken_c[] = "@(#)$Id: sqltoken.c,v 2016.1 2016/01/17 19:21:46 jleffler Exp $";
#endif /* lint */

/*
** sqlcomment() -- Isolate SQL Comments
**
** Skip over white space (per isspace()) in string, and identify a
** comment or hint, if there is one.  Three comment styles are
** recognized:
**  * C-style comments -- slash star to star slash.
**  * ISO double dash comments -- from dash dash to newline.
**  * Informix brace comments -- left curly brace to right curly brace.
** For each comment style, if the first character is a plus sign, the
** comment is an optimizer hint.
**
** Returns appropriate value from SQLComment enumeration.
** Sets *begin to point to the start of the comment.
** Sets *end to point to the first character after the comment.
** If there is no comment, then *begin and *end both point to the first
** non-comment, non-white space character.  If *begin != *end and *end
** points to ASCII NUL '\0', the comment is incomplete.
**
** This is primarily an internal function used by sqltoken() and
** iustoken(), but has to be exposed and may be of general use.
**
** Usage pattern:
**     const char *src;
**     const char *end;
**     const char *bgn;
**     int   style = JLSS_ALLSQL_COMMENTS;
**     SQLComment cmt;
**     ...initialize src...
**     while ((cmt = sqlcomment(src, style, &bgn, &end)) == SQL_COMMENT)
**         src = end;
**     ...after the loop, bgn points to either the end of the string, or
**     ...the start of the next non-comment token.  If comments are of
**     ...interest, they can be picked up in the body of the loop.
*/

SQLComment sqlcomment(const char *input, int style, const char **bgn, const char **end)
{
    const char *token = input;
    unsigned char c = *input;
    const char s_hint[] = "+ hint";
    const char s_cmmt[] = " comment";
    DB_TRACKING();

    DB_TRACE(0, "-->>sqlcomment: <<%.32s%s>>\n", input, (strlen(input) > 32 ? "..." : ""));
    while (isspace(c = *input))
        input++;
    *bgn = input;
    DB_TRACE(0, "----sqlcomment: <<%c>>\n", c);
    if (c != LCURLY && c != DASH && c != SLASH)
    {
        /* It isn't a comment - whatever else it is */
        *end = input;
        DB_TRACE(0, "<<--sqlcomment: non-comment (0x%02X)\n", **bgn);
        return(SQL_NOCOMMENT);
    }
    else if ((style & JLSS_INFORMIX_COMMENT) != 0 && c == LCURLY)
    {
        /* Optimizer hint (to first RCURLY); treat as symbol */
        const char *comment_type = (input[1] == PLUS) ? s_hint : s_cmmt;
        if ((token = strchr(input + 1, RCURLY)) == 0)
        {
            *end = input + strlen(input);
            DB_TRACE(0, "<<--sqlcomment: incomplete {%s\n", comment_type);
            return SQL_INCOMPLETE;
        }
        *end = token + 1;
        DB_TRACE(0, "<<--sqlcomment: complete {%s }\n", comment_type);
        return (input[1] == PLUS) ? SQL_OPTIMIZERHINT : SQL_COMMENT;
    }
    else if ((style & JLSS_ISOSQL_COMMENT) != 0 && c == DASH && input[1] == DASH)
    {
        /* Optimizer hint (to end of line); treat as symbol */
        const char *comment_type = (input[2] == PLUS) ? s_hint : s_cmmt;
        if ((token = strchr(input + 2, '\n')) == 0)
        {
            *end = input + strlen(input);
            DB_TRACE(0, "<<--sqlcomment: incomplete --%s\n", comment_type);
            return SQL_INCOMPLETE;
        }
        *end = token + 1;
        DB_TRACE(0, "<<--sqlcomment: complete --%s\n", comment_type);
        return (input[2] == PLUS) ? SQL_OPTIMIZERHINT : SQL_COMMENT;
    }
    else if ((style & JLSS_CSTYLE_COMMENT) != 0 && c == SLASH && input[1] == STAR)
    {
        /* Optimizer hint to star-slash combo; treat as symbol */
        /* Mercifully, we don't have to deal with backslash-newline splicing */
        const char *comment_type = (input[2] == PLUS) ? s_hint : s_cmmt;
        int plus = (input[2] == PLUS);
        input += 2;
        while ((token = strchr(input, STAR)) != 0)
        {
            if (*(token + 1) != SLASH)
                input = token + 1;
            else
                break;
        }
        if (token == 0)
        {
            *end = input + strlen(input);
            DB_TRACE(0, "<<--sqlcomment: incomplete /*%s\n", comment_type);
            return SQL_INCOMPLETE;
        }
        else
        {
            *end = token + 2;
            DB_TRACE(0, "<<--sqlcomment: complete /*%s */\n", comment_type);
            return plus ? SQL_OPTIMIZERHINT : SQL_COMMENT;
        }
    }
    *end = input;
    /* Found, for example, the slash in SELECT a / b AS c ... */
    DB_TRACE(0, "<<--sqlcomment: non-comment (0x%02X)\n", **bgn);
    return SQL_NOCOMMENT;
}

/*
** sqltoken() - get SQL token
**
** Returns pointer to start of next SQL token (keyword, string,
** punctuation) in given string, or pointer to null at end of string if
** there is none.  The end of the token is in the end parameter.
**
** The current version recognizes three comment conventions:
** -- comment to end of line
** { comment enclosed in braces }
** C-style comments (slash-star to star-slash).
** When the first character after the open comment marker is a plus, it
** is recognized as an Informix-style optimizer hint and returned as a
** token: {+ hint } and --+ hint to end of line
** 2001-03-31: # to end of line is no longer regarded as a comment
** (because of SLVs).
** 2004-12-24: Permit hexadecimal constants (0xFFFFFFFF etc).
*/
char *sqltoken(const char *input, const char **end)
{
    const char *token;
    unsigned char  c;
    unsigned char  q;

    if (*input != '\0')
    {
        int   style = JLSS_ALLSQL_COMMENTS;
        SQLComment cmt;
        const char *c_bgn;
        const char *c_end;

        while ((cmt = sqlcomment(input, style, &c_bgn, &c_end)) == SQL_COMMENT)
            input = c_end;

        input = c_bgn;
        if (cmt == SQL_OPTIMIZERHINT || cmt == SQL_INCOMPLETE)
        {
            *end = c_end;
            return CONST_CAST(char *, input);
        }
        if ((c = *input) == '\0')
        {
            *end = input;
            return CONST_CAST(char *, input);
        }
        else if (c == '\'' || c == '"')
        {
            /* Character string or delimited identifier */
            const char *str = input + 1;
            token = input;
            q = c;
            /* Ignores newlines in quoted strings! */
            /* Handles adjacent doubled quotes */
            while ((str = strchr(str, q)) != 0)
            {
                if (*(str + 1) != q)
                {
                    *end = str + 1;
                    return CONST_CAST(char *, token);
                }
                str += 2;
            }
            *end = input;
            return CONST_CAST(char *, input);
        }
        else if (isdigit(c) || (c == '.' && isdigit((unsigned char)input[1])))
        {
            /* Intelligent number parsing */
            /* Handles unsigned integers, fixed point, */
            /* and exponental (1E+32) notation */
            token = input;
            if (c == '0' && (input[1] == 'x' || input[1] == 'X') && isxdigit((unsigned char)input[2]))
            {
                /* Hexadecimal integer */
                input += 2;
                while ((c = *input++) != '\0' && isxdigit(c))
                    ;
            }
            else
            {
                /* Octal or decimal integer, or floating point */
                if (c == '.')
                    input++;
                while ((c = *input++) != '\0' && isdigit(c))
                    ;
                if (c == '.')
                {
                    while ((c = *input++) != '\0' && isdigit(c))
                        ;
                }
                if (c == 'e' || c == 'E')
                {
                    /* Maybe exponential notation -- in fact should be... */
                    if (isdigit((unsigned char)*input) ||
                        ((*input == PLUS || *input == DASH) && isdigit((unsigned char)input[1])))
                    {
                        if ((c = *input++) == PLUS || c == DASH)
                            input++;
                        while ((c = *input++) != '\0' && isdigit(c))
                            ;
                    }
                }
            }
            *end = input - 1;
            return CONST_CAST(char *, token);
        }
        else if (isalpha(c) || c == '_')
        {
            /* Word (identifier or keyword) */
            token = input;
            /*
            ** JL 2005-12-15: IDS 10.00.UC3 and 9.40.UC7 permit
            ** non-leading $ signs in identifiers.
            */
            while ((c = *input++) != '\0' && (isalnum(c) || c == '_' || c == '$'))
                ;
            *end = input - 1;
            return CONST_CAST(char *, token);
        }
        else
        {
            /* Punctuation - symbols */
            token = input++;
            /* Only compound symbols known are: <> != <= >= || :: (used in IUS) */
            /* Any other punctuation character is treated as a single token */
            if (*input != '\0' && (c == '<' || c == '!' || c == '|' || c == '>' || c == ':'))
            {
                switch (c)
                {
                case '<':
                    if (*input == '>' || *input == '=')
                        input++;
                    break;
                case '>':
                    if (*input == '=')
                        input++;
                    break;
                case '!':
                    if (*input == '=')
                        input++;
                    break;
                case '|':
                    if (*input == '|')
                        input++;
                    break;
                case ':':
                    if (*input == ':')
                        input++;
                    break;
                default:
                    assert(0);
                    break;
                }
            }
            *end = input;
            return CONST_CAST(char *, token);
        }
    }
    *end = input;
    return CONST_CAST(char *, input);
}

#ifdef TEST

#include <stdio.h>

#define DIM(x)  (sizeof(x)/sizeof(*(x)))

static const char * const input[] =
{
    " \t\v\f\n\r ", /* Pure white space (NB: \b backspace is not white space) */
    "{SELECT * FROM SysTables}", /* Pure comment */
    "SELECT * FROM SysTables",
    "SELECT 0xFAB0dead AS hex_number FROM SysTables",
    "SELECT { * } Tabid FROM SysTables",
    "SELECT -- * \n Tabid FROM SysTables",
    "SELECT #- * \n Tabid FROM SysTables",  /* Obsolete # comment convention */
    "SELECT a+b FROM 'informix'.systables",
    "SELECT a+1 AS\"a\"\"b\",a+1.23AS'a''b2'FROM db@server:\"user\".table\n"
        "WHERE (x+2 UNITS DAY)>=(DATETIME(1998-12-23 13:12:10) YEAR TO SECOND-1 UNITS DAY)\n"
        "  AND t<+3.14159E+32\n",
    "SELECT a.--this should be in comment and invisible\n"
        "b FROM SomeDbase:{this should be in comment and invisible too}\n"
        "user.#--more commentary\n\t\ttablename",   /* Obsolete # comment convention */
    "SELECT (a>=<=<>!=||...(b)) FROM Nowhere",
    "{cc}-1{c}+1{c}.1{c}-.1{c}+.1{}-1.2E3{c}+1.23E+4{c}-1.234e-56{c}-1.234E",
    "info columns for 'cdhdba'.cdh_user",
    "select a::type as _ from _",
    "select {+ hint} _ as _ from _",
    "select --+ hint\n\t_ as _ from _",
    "create temp table p$q(r$s int)",
    "select 'abc\ndef' from has_newline",
    "select /* XX */ * from /* YY * / */ whatnot",
    "select {/* XX */ * from /* YY * /} /* ZZ */ * from whatnot",
    "select/* XX */*from/* YY * / */whatnot",
    "/**/select/**/x/**/from/**/whatnot/**/",
    "--\nselect/***/x/****/from/*****/whatnot/******/",
    /* Incomplete comment - and hint */
    "select/*+ hint */*from/*/*****/torture_test/*",

    /* C90 string concatenation is a wonderful thing! */
    /* Super-extreme owner name (32 double quotes, doubled up, enclosed in double quotes) */
    /* Super-extreme table name (128 double-quotes, doubled up, enclosed in double quotes) */
    "info columns for \""
    "\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\""
    "\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\""
    "\"\n.\n\""
    "\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\""
    "\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\""
    "\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\""
    "\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\""
    "\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\""
    "\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\""
    "\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\""
    "\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\""
    "\";",
    /* This is an example of where sqltoken() does one lot of recognition and iustoken() does another */
    "TABLE{}({}LIST/*comment*/{{}SET{{}1{},{}2{},{}3{}}{}}){}\t\n",

};

int main(void)
{
    int i;
    int n;
    const char *str;
    const char *src;
    const char *end;
    char  buffer[2048];

    for (i = 0; i < DIM(input); i++)
    {
        n = 0;
        str = input[i];
        printf("Data: <<%s>>\n", str);
        while (*(src = sqltoken(str, &end)) != '\0' && src != end)
        {
            strncpy(buffer, src, end - src);
            buffer[end - src] = '\0';
            n++;
            printf("Token %d: <<%s>>\n", n, buffer);
            str = end;
        }
        if (n == 0)
            printf("== No tokens found ==\n");
    }
    printf("** TEST COMPLETE **\n");
    return 0;
}

#endif /* TEST */
