/*  Curses.c
**
**  Copyright (c) 1994-2000  William Setzer
**
**  You may distribute under the terms of either the Artistic License
**  or the GNU General Public License, as specified in the README file.
*/

#define _XOPEN_SOURCE_EXTENDED 1  /* We expect wide character functions */

#include <stdbool.h>
   /* We don't use 'bool', but Curses header files sometimes define
      it in a way that breaks <perl.h>, when it is subsequently included,
      and having bool already defined seems to stop Curses header files from
      doing that.  See further discussion of 'bool' below.
   */
#include "config.h"
#include "c-config.h"
#include "CursesDef.h"
#include "CursesTyp.h"

/* c-config.h above includes Ncurses header files that define macro
   'instr'.  Unfortunately, perl.h (below) also defines 'instr'.
   Fortunately, we don't need the Curses version -- we use
   winstr(stdscr, ...) instead.  So we undef instr here to avoid a compiler
   warning about the redeclaration.

   Similarly, c-config.h may define a macro "tab", while the word
   "tab" is used in perl.h another way, so we undefine it to avoid
   a nasty syntax error.

   "term.h" pollutes the name space with hundreds of other macros too.
   We'll probably have to add to this list; maybe someday we should
   just undef them all, since we don't use them.

   "bool" is another, and is more problematic.  Sometimes, ncurses.h defines
   that explicitly and that's bad, but sometimes it does it by including
   <stdbool.h>, and that's fine.  In the former case, we should undefine it
   now, but in the latter we can't, because then a subsequent #include
   <stdbool.h> (by something we #include below) won't define bool because
   stdbool.h has already been included.  We once had a #undef bool in the Mac
   OSX hints file, so someone presumably found it necessary.  But we have also
   had a Mac OSX system on which compile failed _because_ of that undef, for
   the reason described above.

   We also saw (AIX, August 2022) curses.h define bool in such a way that
   the subsquently included <perl.h> defined its interface structure with
   the Perl core using the wrong size for bool.  Fortunately, the Perl
   interface catches that in its "handshake" to negotiate the interface
   and refuses to run, with an error message like

     loadable library and perl binaries are mismatched (got 0xd800000, needed
     0xd700000)" or "(got handshake key 8d00080, needed 8700080)

   (Note the misnomer: "loadable library" means Curses.so)

   When we include <stdbool.h> here, that AIX problem ceases to exist --
   <curses.h> apparently sees that bool is already defined and does not
   define it itself.
 */

#undef instr
#undef tab

#include <EXTERN.h>  /* Needed by <perl.h> */
#include <perl.h>
#include <XSUB.h>
/* I don't know why NEED_sv_2pv_flags is necessary, but ppport.h doesn't
   work right without it.  Maybe a bug in Devel::PPPort?  */
#define NEED_sv_2pv_flags
#include "ppport.h"
    /* Defines PERL_REVISION, etc. (if perl.h doesn't) */

#ifndef C_PANELFUNCTION
#  define PANEL int
#endif

#ifndef C_MENUFUNCTION
#  define MENU int
#  define ITEM int
#endif

#ifndef C_FORMFUNCTION
#  define FORM int
#  define FIELD int
#endif

/* Before 1.17 (September 2007), we undefined macro 'SP' here, for
   the Pdcurses case only.  I don't know why, but it caused the build
   with Pdcurses to fail, so we took it out.  'SP' is
   defined in Perl's CORE/pp.h via our inclusion of perl.h above.
*/

#if PERL_VERSION >= 6
#define HAVE_PERL_UTF8_TO_UV 1
#define HAVE_PERL_UV_TO_UTF8 1
#else
#define HAVE_PERL_UTF8_TO_UV 0
#define HAVE_PERL_UV_TO_UTF8 0
#endif

#if PERL_VERSION >= 7
#define HAVE_PERL_UTF8_TO_UVCHR 1
#define HAVE_PERL_UVCHR_TO_UTF8 1
#else
#define HAVE_PERL_UTF8_TO_UVCHR 0
#define HAVE_PERL_UVCHR_TO_UTF8 0
#endif

#if PERL_VERSION >= 16 /* really 15.something */
#define HAVE_PERL_UTF8_TO_UVCHR_BUF 1
#else
#define HAVE_PERL_UTF8_TO_UVCHR_BUF 0
#endif

/*
** Begin support variables and functions
*/

static char *c_function;
static int   c_win, c_x, c_arg;

static void
c_countargs(fn, nargs, base)
char *fn;
int nargs;
int base;
{
    switch (nargs - base)
    {
    case 0:  c_win = 0; c_x = 0; c_arg = 0; break;
    case 1:  c_win = 1; c_x = 0; c_arg = 1; break;
    case 2:  c_win = 0; c_x = 1; c_arg = 2; break;
    case 3:  c_win = 1; c_x = 2; c_arg = 3; break;
    default:
    croak("Curses function '%s' called with too %s arguments", fn,
          nargs < base ? "few" : "many");
    }
    c_function = fn;
}

static void
c_exactargs(fn, nargs, base)
char *fn;
int nargs;
int base;
{
    if (nargs != base)
    croak("Curses function '%s' called with too %s arguments", fn,
          nargs < base ? "few" : "many" );

    c_function = fn;
}

static int
c_domove(win, sv_y, sv_x)
WINDOW *win;
SV *sv_y;
SV *sv_x;
{
    int y = (int)SvIV(sv_y);
    int x = (int)SvIV(sv_x);

    return wmove(win, y, x);
}

static void
c_fun_not_there(fn)
char *fn;
{
    croak("Curses function '%s' is not defined in your Curses library", fn);
}

static void
c_var_not_there(fn)
char *fn;
{
    croak("Curses variable '%s' is not defined in your Curses library", fn);
}

static void
c_con_not_there(fn)
char *fn;
{
    croak("Curses constant '%s' is not defined in your Curses library", fn);
}

/*
** Begin complex type conversion routines
*/

static chtype
c_sv2chtype(sv)
SV *sv;
{
    if (SvPOK(sv)) {
        char *tmp = SvPV_nolen(sv);
        return (chtype)(unsigned char)tmp[0];
    }
    return (chtype)SvIV(sv);
}

static void
c_chtype2sv(sv, ch)
SV *sv;
chtype ch;
{
    if (ch == ERR || ch > 255) { sv_setiv(sv, (I32)ch); }
    else {
    char tmp[2];
    tmp[0] = (char)ch;
    tmp[1] = (char)0;
    sv_setpv(sv, tmp);
    }
}

static FIELD *
c_sv2field(sv, argnum)
SV *sv;
int argnum;
{
    if (sv_derived_from(sv, "Curses::Field"))
    return (FIELD *)SvIV((SV*)SvRV(sv));
    if (argnum >= 0)
    croak("argument %d to Curses function '%s' is not a Curses field",
          argnum, c_function);
    else
    croak("argument is not a Curses field");
}

static void
c_field2sv(SV *    const svP,
           FIELD * const fieldP) {
/*----------------------------------------------------------------------------
  Make *svP a reference to a scalar whose value is the numerical
  equivalent of 'fieldP' and which is blessed into the hypothetical
  package "Curses::Field".
-----------------------------------------------------------------------------*/
    sv_setref_pv(svP, "Curses::Field", (void*)fieldP);
}

static FORM *
c_sv2form(sv, argnum)
SV *sv;
int argnum;
{
    if (sv_derived_from(sv, "Curses::Form"))
    return (FORM *)SvIV((SV*)SvRV(sv));
    if (argnum >= 0)
    croak("argument %d to Curses function '%s' is not a Curses form",
          argnum, c_function);
    else
    croak("argument is not a Curses form");
}

static void
c_form2sv(sv, val)
SV *sv;
FORM *val;
{
    sv_setref_pv(sv, "Curses::Form", (void*)val);
}

static ITEM *
c_sv2item(sv, argnum)
SV *sv;
int argnum;
{
    if (sv_derived_from(sv, "Curses::Item"))
    return (ITEM *)SvIV((SV*)SvRV(sv));
    if (argnum >= 0)
    croak("argument %d to Curses function '%s' is not a Curses item",
          argnum, c_function);
    else
    croak("argument is not a Curses item");
}



static void
c_item2sv(SV *   const svP,
          ITEM * const valP) {
/*----------------------------------------------------------------------------
   Make *svP a reference to a new scalar whose implementation value is
   'valP' and which is blessed into class Curses::Item.

   Caller can pass the referenced scalar to other functions of the Curses
   module, which can recover the ITEM * from it.
-----------------------------------------------------------------------------*/
    sv_setref_pv(svP, "Curses::Item", (void*)valP);
}



static MENU *
c_sv2menu(sv, argnum)
SV *sv;
int argnum;
{
    if (sv_derived_from(sv, "Curses::Menu"))
    return (MENU *)SvIV((SV*)SvRV(sv));
    if (argnum >= 0)
    croak("argument %d to Curses function '%s' is not a Curses menu",
          argnum, c_function);
    else
    croak("argument is not a Curses menu");
}

static void
c_menu2sv(sv, val)
SV *sv;
MENU *val;
{
    sv_setref_pv(sv, "Curses::Menu", (void*)val);
}

static PANEL *
c_sv2panel(sv, argnum)
SV *sv;
int argnum;
{
    if (sv_derived_from(sv, "Curses::Panel"))
    return (PANEL *)SvIV((SV*)SvRV(sv));
    if (argnum >= 0)
    croak("argument %d to Curses function '%s' is not a Curses panel",
          argnum, c_function);
    else
    croak("argument is not a Curses panel");
}

static void
c_panel2sv(sv, val)
SV *sv;
PANEL *val;
{
    sv_setref_pv(sv, "Curses::Panel", (void*)val);
}

static SCREEN *
c_sv2screen(sv, argnum)
SV *sv;
int argnum;
{
    if (sv_derived_from(sv, "Curses::Screen"))
    return (SCREEN *)SvIV((SV*)SvRV(sv));
    if (argnum >= 0)
    croak("argument %d to Curses function '%s' is not a Curses screen",
          argnum, c_function);
    else
    croak("argument is not a Curses screen");
}

static void
c_screen2sv(sv, val)
SV *sv;
SCREEN *val;
{
    sv_setref_pv(sv, "Curses::Screen", (void*)val);
}

static WINDOW *
c_sv2window(sv, argnum)
SV *sv;
int argnum;
{
    if (sv_derived_from(sv, "Curses::Window")) {
      WINDOW *ret = (WINDOW *)SvIV((SV*)SvRV(sv));
      return ret;
    }
    if (argnum >= 0)
    croak("argument %d to Curses function '%s' is not a Curses window",
          argnum, c_function);
    else
    croak("argument is not a Curses window");
}

static void
c_window2sv(sv, val)
SV *sv;
WINDOW *val;
{
    sv_setref_pv(sv, "Curses::Window", (void*)val);
}


static void
c_setchar(sv, name)
SV *sv;
char *name;
{
    int len  = SvLEN(sv);

    if (len > 0) {
        name[len - 1] = 0;

    SvCUR(sv) = strlen(name);
    SvPOK_only(sv);
    *SvEND(sv) = 0;
    }
}

static void
c_setchtype(sv, name)
SV *sv;
chtype *name;
{
    int n   = 0;
    int rs  = sizeof(chtype);
    int len = SvLEN(sv);

    if (len - len % rs > rs) {            /* find even multiple of rs */
        name[len - len % rs - rs] = 0;

    while (*name++) { n++; }

    SvCUR(sv) = n;
    SvPOK_only(sv);
    *(chtype *)SvEND(sv) = 0;
    }
}

static void
c_setmevent(sv)
SV *sv;
{
    SvCUR(sv) = sizeof(MEVENT);
    SvPOK_only(sv);
}


#if ((HAVE_PERL_UVCHR_TO_UTF8 || HAVE_PERL_UV_TO_UTF8) && \
    (HAVE_PERL_UTF8_TO_UVCHR_BUF || HAVE_PERL_UTF8_TO_UVCHR || \
     HAVE_PERL_UTF8_TO_UV))
  #include "CursesWide.c"
  #define HAVE_WIDE_SV_HELPER 1
#else
  #define HAVE_WIDE_SV_HELPER 0
#endif

/*
**  Cheesy, I know.  But it works.
*/


#include "CursesFun.c"
#if HAVE_WIDE_SV_HELPER
  #include "CursesFunWide.c"
  #define HAVE_WIDE_XS_FUNCTIONS 1
#else
  #define HAVE_WIDE_XS_FUNCTIONS 0
#endif
#include "CursesVar.c"
#include "CursesCon.c"
#include "CursesBoot.c"
