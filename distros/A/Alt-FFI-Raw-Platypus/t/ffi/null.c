#include <stdlib.h>
#include <t2t/simple.h>

extern void
pass_in_undef_str(const char *value)
{
  ok(value == NULL, "value == NULL (string)");
}

extern const char *
return_undef_str(void)
{
  return NULL;
}

extern void pass_in_undef_ptr(const void *value) {
  ok(value == NULL, "value == NULL (opaque)");
}

extern const void *return_undef_ptr(void) {
  return NULL;
}
