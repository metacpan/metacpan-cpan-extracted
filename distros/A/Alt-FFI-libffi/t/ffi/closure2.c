#include <stdio.h>

typedef int (*adder)(int, int);

int call_adder(adder f, int a, int b)
{
  return f(a,b);
}
