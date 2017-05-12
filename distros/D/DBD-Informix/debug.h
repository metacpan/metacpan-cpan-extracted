/*
@(#)File:           $RCSfile: debug.h,v $
@(#)Version:        $Revision: 3.10 $
@(#)Last changed:   $Date: 2013/11/24 20:24:54 $
@(#)Purpose:        Definitions for the debugging system
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1990-93,1997-99,2003,2005,2008,2011,2013
@(#)Product:        Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
*/

#ifndef DEBUG_H
#define DEBUG_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

/*
** Control whether debugging macros are active at compile time.
*/
#undef DB_ACTIVE
#ifdef DEBUG
#define DB_ACTIVE 1
#else
#define DB_ACTIVE 0
#endif /* DEBUG */

/*
** TRACE is a legacy interface; new code should use DB_TRACE.
**
** Usage:  TRACE((level, fmt, ...));
**
** "level" is the debugging level which must be operational for the output
** to appear. "fmt" is a printf format string. "..." is whatever extra
** arguments fmt requires (possibly nothing).
**
** Usage:  DB_TRACE(level, fmt, ...);
**
** The structure of the macros means that the code is always validated
** but is not called when DEBUG is undefined.
** -- See chapter 8 of 'The Practice of Programming', by Kernighan and Pike.
*/
#define TRACE(x) \
            do { if (DB_ACTIVE) db_print x; } while (0)
#define DB_TRACE(level, ...)\
            do { if (DB_ACTIVE) db_print(level, __VA_ARGS__); } while (0)

/*
** Usage:  DB_CALL(level, ...);
**
** Example: DB_CALL(1, dump_structure(db_getfileptr(), "tag", arg1, arg2));
**
** If trace is active at given level, execute the code in the variable
** arguments.  Normally used to selectively execute printing functions.
*/
#define DB_CALL(level, ...)\
            do { if (DB_ACTIVE && db_getdebug() >= (level)) { __VA_ARGS__; } } while (0)

#ifndef lint
#ifdef DEBUG
/* This string can't be made extern - multiple definition in general */
static const char jlss_id_debug_enabled[] = "@(#)*** DEBUG ***";
#endif /* DEBUG */
#ifdef MAIN_PROGRAM
const char jlss_id_debug_h[] = "@(#)$Id: debug.h,v 3.10 2013/11/24 20:24:54 jleffler Exp $";
#endif /* MAIN_PROGRAM */
#endif /* lint */

#include <stdio.h>

extern int      db_getdebug(void);
extern int      db_newindent(void);
extern int      db_oldindent(void);
extern int      db_setdebug(int level);
extern int      db_setindent(int i);
extern void     db_print(int level, const char *fmt,...);
extern void     db_setfilename(const char *fn);
extern void     db_setfileptr(FILE *fp);
extern FILE    *db_getfileptr(void);

/* Semi-private function */
extern const char *db_indent(void);

/**************************************\
** MULTIPLE DEBUGGING SUBSYSTEMS CODE **
\**************************************/

/*
** MDTRACE is a legacy interface; new code should use DB_MDTRACE.
**
** Usage:  MDTRACE((subsys, level, fmt, ...));
**
** "subsys" is the debugging system to which this statement belongs.
** The significance of the subsystems is determined by the programmer,
** except that the functions such as db_print refer to subsystem 0.
** "level" is the debugging level which must be operational for the
** output to appear. "fmt" is a printf format string. "..." is
** whatever extra arguments fmt requires (possibly nothing).
**
** Usage:  DB_MDTRACE(subsys, level, fmt, ...);
*/
#define MDTRACE(x) \
            do { if (DB_ACTIVE) db_mdprint x; } while (0)
#define DB_MDTRACE(subsys, level, ...) \
            do { if (DB_ACTIVE) db_mdprint(subsys, level, __VA_ARGS__); } while (0)

/*
** Usage:  DB_MDCALL(subsys, level, ...);
**
** Example: DB_CALL(subsys, 1, dump_structure(db_getfileptr(), "tag", arg1, arg2));
**
** If trace is active at given level for given subsystem, execute the
** code in the variable arguments.  Normally used to selectively execute
** printing functions.
*/
#define DB_MDCALL(subsys, level, ...) \
            do { if (DB_ACTIVE && db_mdgetdebug(subsys) >= (level)) { __VA_ARGS__; } } while (0)

extern int      db_mdgetdebug(int subsys);
extern int      db_mdparsearg(char *arg);
extern int      db_mdsetdebug(int subsys, int level);
extern void     db_mdprint(int subsys, int level, const char *fmt,...);
extern void     db_mdsubsysnames(char * const *names);

#endif /* DEBUG_H */
