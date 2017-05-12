/* cdecl.h is generated when you run `perl Makefile.PL DECL=cdecl' */
#include "cdecl.h"

/*
 * Convert Perl sub args to C args and pass them to (*func)().
 * Special case with passing 3 words explicit.
 */
static int
cdecl3_pray(ax, items, func)
     I32 ax;		/* used by the ST() macro */
     I32 items;
     void *func;
{
#ifdef USE_THREADS
  dTHR;
#endif
  STRLEN arg_len;
  char *arg_scalar, *arg_on_stack;
  register int i;
  void* d1, *d2, *d3;
  d1 = d2 = d3 = NULL;

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

  for (i = items; i-- > 0; ) {
    (void) SvPV(ST(i), arg_len);
    /* CDECL_ARG_ALIGN=8 for amd64 */
    total_arg_len += min(arg_len, CDECL_ARG_ALIGN);
  }
  arg_on_stack = (char *) alloca(total_arg_len);
  arg_on_stack += CDECL_ADJUST;
#if CDECL_REVERSE
  for (i = items - 1; i >= 0; i--) {
#else  /* ! CDECL_REVERSE */
  for (i = 0; i < items; i++) {
#endif  /* ! CDECL_REVERSE */
    arg_scalar = SvPV(ST(i), arg_len);
    if (sizeof(void*) == 8 && arg_len < 8) { 
      /* amd64 aligns to 8, so zero the values of smaller args.
	 http://blogs.msdn.com/oldnewthing/archive/2004/01/14/58579.aspx
      */
      memzero(arg_on_stack, 8);
    }
    Copy(arg_scalar, arg_on_stack, arg_len, char);
    arg_on_stack += min(arg_len, CDECL_ARG_ALIGN);
  }
#endif  /* ! CDECL_ONE_BY_ONE */

  if (CDECL_STACK_RESERVE == 3 && items > 2) {
    arg_scalar = SvPV(ST(0), arg_len);
    Copy(arg_scalar, &d1, arg_len, char);
    arg_scalar = SvPV(ST(1), arg_len);
    Copy(arg_scalar, &d2, arg_len, char);
    arg_scalar = SvPV(ST(2), arg_len);
    Copy(arg_scalar, &d3, arg_len, char);
    return ((int (*)()) func)(d1,d2,d3);
  }
  else if (CDECL_STACK_RESERVE == 2 || items == 2) {
    arg_scalar = SvPV(ST(0), arg_len);
    Copy(arg_scalar, &d1, arg_len, char);
    arg_scalar = SvPV(ST(1), arg_len);
    Copy(arg_scalar, &d2, arg_len, char);
    return ((int (*)()) func)(d1,d2);
  }
  else if (CDECL_STACK_RESERVE == 1 || items == 1) {
    arg_scalar = SvPV(ST(0), arg_len);
    Copy(arg_scalar, &d1, arg_len, char);
    return ((int (*)()) func)(d1);
  }
  else if (items == 0) {
    return ((int (*)()) func)();
  }
  else {
    printf("invalid CDECL_STACK_RESERVE=%d\n", CDECL_STACK_RESERVE);
    exit (1);
  }
}

#if defined(__GNUC__) && __GNUC__ >= 3 && defined(__GNUC_MINOR__) && (__GNUC_MINOR__ >= 3)
#define cdecl3_CALL(func, type)						\
    (type)((*((int (*)()) cdecl3_pray))(ax,items,func))
#else
#define cdecl3_CALL(func, type)						\
    ((*((type (*)()) cdecl3_pray))(ax,items,func))
#endif
