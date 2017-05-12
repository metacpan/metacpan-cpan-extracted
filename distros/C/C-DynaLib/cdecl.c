/* cdecl.h is generated when you run `perl Makefile.PL DECL=cdecl' */
#include "cdecl.h"

/*
 * Convert Perl sub args to C args and pass them to (*func)().
 * Caller cleanup.
 * See http://en.wikipedia.org/wiki/X86_calling_conventions
 */
static int
cdecl_pray(ax, items, func)
     I32 ax;		/* used by the ST() macro */
     I32 items;
     void *func;
{
#ifdef USE_THREADS
  dTHR;
#endif
  /* DYNALIB_ARGSTART = 3 because of three locals here. */
  STRLEN arg_len;
  char *arg_scalar, *arg_on_stack;
  register int i;
#if CDECL_ONE_BY_ONE

#if CDECL_REVERSE
  for (i = DYNALIB_ARGSTART; i < items; i++) {
#else  /* ! CDECL_REVERSE */
  for (i = items - 1; i >= DYNALIB_ARGSTART; i--) {
#endif  /* ! CDECL_REVERSE */
    arg_scalar = SvPV(ST(i), arg_len);
    arg_on_stack = alloca(arg_len);
    Copy(arg_scalar, arg_on_stack, arg_len, char);
  }
#else  /* ! CDECL_ONE_BY_ONE */
  STRLEN total_arg_len = 0;

  for (i = items; i-- > DYNALIB_ARGSTART; ) {
    (void) SvPV(ST(i), arg_len);
    /* XXX CDECL_ARG_ALIGN=8 for amd64 */
    total_arg_len += arg_len;
  }
  arg_on_stack = (char *) alloca(total_arg_len);
  arg_on_stack += CDECL_ADJUST;
#if CDECL_REVERSE
  for (i = items - 1; i >= DYNALIB_ARGSTART; i--) {
#else  /* ! CDECL_REVERSE */
  for (i = DYNALIB_ARGSTART; i < items; i++) {
#endif  /* ! CDECL_REVERSE */
    arg_scalar = SvPV(ST(i), arg_len);
#ifdef __x86_64__
    if (arg_len < 8) { 
      /* x86_64 aligns to 8 non zero-filled.
	 http://blogs.msdn.com/oldnewthing/archive/2004/01/14/58579.aspx
      */
      memzero(arg_on_stack, 8);
    }
#endif
    Copy(arg_scalar, arg_on_stack, arg_len, char);
    arg_on_stack += arg_len;
  }
#endif  /* ! CDECL_ONE_BY_ONE */

  /* Cross your fingers. */
  return (*((int (*)()) func))();
}

#if defined(__GNUC__) && __GNUC__ >= 3 && defined(__GNUC_MINOR__) && (__GNUC_MINOR__ >= 3)
#define cdecl_CALL(func, type)						\
    (type)((*((int (*)()) cdecl_pray))(ax,items,func))
#else
#define cdecl_CALL(func, type)						\
    ((*((type (*)()) cdecl_pray))(ax,items,func))
#endif
