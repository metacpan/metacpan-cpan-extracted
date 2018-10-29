/*
@(#)File:           $RCSfile: sqltoken.h,v $
@(#)Version:        $Revision: 2004.3 $
@(#)Last changed:   $Date: 2004/12/21 00:29:14 $
@(#)Purpose:        SQL Tokenizer for Informix
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 2004
@(#)Product:        Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28)
*/

/*TABSTOP=4*/

#ifndef SQLTOKEN_H
#define SQLTOKEN_H

#ifdef  __cplusplus
extern "C" {
#endif

#ifdef MAIN_PROGRAM
#ifndef lint
static const char sqltoken_h[] = "@(#)$Id: sqltoken.h,v 2004.3 2004/12/21 00:29:14 jleffler Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

enum
{
	JLSS_CSTYLE_COMMENT = 0x01,
	JLSS_ISOSQL_COMMENT = 0x02,
	JLSS_INFORMIX_COMMENT = 0x04,
	JLSS_ALLSQL_COMMENTS = (JLSS_CSTYLE_COMMENT|JLSS_ISOSQL_COMMENT|JLSS_INFORMIX_COMMENT)
};

typedef enum { SQL_NOCOMMENT, SQL_OPTIMIZERHINT, SQL_COMMENT, SQL_INCOMPLETE } SQLComment;

/*
** sqltoken() -- Extract an SQL token from the given string
**
** Return value points to start of token; *end points one beyond end
** If *end == return value, there are no more tokens in the string
** Understands and ignores {...}, C style, and SQL style comments;
** but understands and returns hints in any recognized comment style.
** Understands character strings, and unsigned numbers with optional
** fractions and exponents; a leading sign is a separate token.
**
** iustoken() -- Also extracts an SQL token from the given string.
**
** It uses sqltoken() to do most of the work, but recognizes SET, LIST
** and MULTISET literals (which look like SET{ROW(1,2)}), and returns
** token including open curly bracket of token (including any embedded
** white space or comments).
**
** Neither iustoken() nor sqltoken() modifies the string.
**
** Usage pattern:
**     char *str;
**     char *src;
**     char *end;
** 	   ...initialize str...
**     while (*(src = iustoken(str, &end)) != '\0' && src != end)
**     {
**         -- str..src-1 contains white space or comments
**         strncpy(buffer, src, end - src);
**         buffer[end - src] = '\0';
**         ...use buffer...
**         str = end;
**     }
*/

extern char *sqltoken(const char *string, const char **end);
extern char *iustoken(const char *string, const char **end);

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
extern SQLComment sqlcomment(const char *string, int style, const char **begin, const char **end);

#ifdef  __cplusplus
}
#endif

#endif	/* SQLTOKEN_H */
