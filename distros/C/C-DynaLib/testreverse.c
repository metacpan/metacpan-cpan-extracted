/*
 * This program checks in which direction the params are on the stack.
 */

#define main notmain
#include <EXTERN.h>
#include <perl.h>
#undef main
#undef fprintf
#undef fopen
#undef fclose

#include <stdio.h>

#ifdef INCLUDE_ALLOCA
#include <alloca.h>
#endif
#ifdef INCLUDE_MALLOC
#include <malloc.h>
#endif

#ifndef SIGSEGV
#include <signal.h>
#endif

I32 a[] = { 225437, 616282, 3853003, 899434198, 86381619,
	    16556758, 94159, 4893126, 77778212 };

int grows_downward;
int one_by_one = 1;
int reverse = 0;
int do_reverse = 0;
int args_size[2];
int adjust[] = {0, 0};
int do_adjust = 0;

int *which;

void handler(int sig) {
  exit(1);
}

int test(b0, b1, b2, b3, b4, b5, b6, b7, b8)
     I32 b0, b1, b2, b3, b4, b5, b6, b7, b8;
{
  int i;

  if (b0 == a[0]
      && b1 == a[1]
      && b2 == a[2]
      && b3 == a[3]
      && b4 == a[4]
      && b5 == a[5]
      && b6 == a[6]
      && b7 == a[7]
      && b8 == a[8]
      )
    {
      return 1;
    }
  for (i = 0; i < 9; i++) {
    if (a[i] == b4) {
      if ((i == 0 || a[i-1] == b3) && (i == 8 || a[i+1] == b5)) {
	*which = (i - 4) * sizeof (I32);
	break;
      }
      else if ((i == 0 || a[i-1] == b5) && (i == 8 || a[i+1] == b3)) {
	reverse = 1;
	*which = (i - 4) * sizeof (I32);
	break;
      }
    }
  }
  return 0;
}

int do_one_arg(x)
  char *x;
{
  char *arg;
  int i;

  args_size[0] = sizeof x;
  which = &adjust[0];
  if (one_by_one) {
    for (i = 8; i >= 0; i--) {
      arg = (char *) alloca(sizeof (I32));
      Copy(&a[do_reverse ? 8-i : i], arg, sizeof (I32), char);
    }
  }
  else {
    arg = (char *) alloca(sizeof a) + do_adjust;
    for (i = 0; i < 9; i++) {
      Copy(&a[do_reverse ? 8-i : i], arg, sizeof (I32), char);
      arg += sizeof (I32);
    }
  }
  return ((int (*)()) test)();
}

int main(argc, argv)
  int argc;
  char **argv;
{
  FILE *fp;
  int one_arg, three_args;
  int *p1, *p2;

#ifdef SIGSEGV
  signal(SIGSEGV, handler);
#endif
#ifdef SIGILL
  signal(SIGILL, handler);
#endif
  p1 = (int *) alloca(sizeof *p1);
  p2 = (int *) alloca(sizeof *p2); /* p1 - 0x20 */
  grows_downward = (p1 - p2 > 0 ? 1 : 0);
  one_by_one = (p1 - p2 == (grows_downward ? 1 : -1));

  one_arg = do_one_arg(NULL);
  if (reverse) {
    do_reverse = reverse ^ (one_by_one ? grows_downward : 0);
    one_arg = do_one_arg(NULL);
  }
  return reverse ? 1 : 0;
}
