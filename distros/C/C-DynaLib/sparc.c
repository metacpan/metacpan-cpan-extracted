/* alloca.h is needed with Sun's cc */
#include <alloca.h>

#ifdef __GNUC__
/*
 * We'll take advantage of gcc's inline asm capability.
 */
#else  /* ! __GNUC__ */
static void *
sparc_where_arg_7(a,b,c,d,e,f,g)
     int a,b,c,d,e,f,g;
{
  return &g;
}
#endif  /* ! __GNUC__ */

/*
 * Convert Perl sub args to C args and pass them to (*func)().
 */
static int
sparc_pray(ax, items, func)
I32 ax;		/* used by the ST() macro */
I32 items;
int (*func)();
{
#ifdef USE_THREADS
  dTHR;
#endif
  STRLEN arg_len, chunk_len;
  char *arg_scalar, *arg_on_stack;
  int nbytes = 0;
  int pseu[6];  /* Array of first six "pseudo-arguments" */
  int check_len;
  register int i, j;
  int stack_needed = 0;

  for (i = DYNALIB_ARGSTART; i < items; ) {
    arg_scalar = SvPV(ST(i), arg_len);
    i++;
    check_len = nbytes + arg_len;
    if (check_len > sizeof pseu) {
      stack_needed = check_len - sizeof pseu;
      arg_len -= stack_needed;
    }
    Copy(arg_scalar, &((char *) (&pseu[0]))[nbytes], arg_len, char);
    nbytes = check_len;
    if (check_len >= sizeof pseu) {
      for (j = i; j < items; j++) {
	SvPV(ST(j), arg_len);
	stack_needed += arg_len;
      }
      if (stack_needed > 0) {
	alloca(stack_needed);
#ifdef __GNUC__
	/*
	 * ??? gcc's alloca seems to always return a pointer that's 4 bytes
	 * above what we need.  These instructions fix it, if need be.
	 * Maybe this has something to do with alignment of doubles?
	 * Still, it's strange that Solaris cc doesn't do the same.
	 */
	asm("add %%sp,92,%%o0\n\tst %%o0,%0" : "=m"(arg_on_stack) : );
#else  /* ! __GNUC__ */
	arg_on_stack = ((void *(*)())sparc_where_arg_7)();
#endif  /* ! __GNUC__ */
	if (check_len > sizeof pseu) {
	  /* An argument straddles the 6-word line; part goes on stack. */
	  SvPV(ST(i), arg_len);
	  chunk_len = check_len - sizeof pseu;
	  Copy(&arg_scalar[arg_len - chunk_len], arg_on_stack, chunk_len, char);
	  arg_on_stack += chunk_len;
	}
	while (i < items) {
	  arg_scalar = SvPV(ST(i), arg_len);
	  i++;
	  Copy(arg_scalar, arg_on_stack, arg_len, char);
	  arg_on_stack += arg_len;
	}
      }
    }
  }
  /* Cross your fingers. */
  return (*((int (*)()) func))(pseu[0], pseu[1], pseu[2],
			       pseu[3], pseu[4], pseu[5]);
}

#define sparc_CALL(func, type)						\
    ((*((type (*)()) sparc_pray))(ax,items,func))
