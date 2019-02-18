#include <stdio.h>
#include <string.h>
#include <t2t/simple.h>

struct some_struct {
  int   some_int;
  char *some_str;
};

extern void
take_one_struct(struct some_struct *arg)
{
  ok(arg->some_int == 42, "got passed int 42");
  ok(strlen(arg->some_str) == 5, "got passed str of right length");
  ok(strcmp(arg->some_str, "hello") == 0, "got passed string hello");
}

extern void
return_one_struct(struct some_struct *arg)
{
  arg->some_int = 42;
  arg->some_str = strdup("hello");
}
