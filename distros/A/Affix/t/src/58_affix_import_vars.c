#include "std.h"

DLLEXPORT int integer = 5;
DLLEXPORT char *string = "Hi!";

DLLEXPORT const char *const pStrNoYes[] = {"No", "Yes"};

DLLEXPORT char *get_string() {
    return string;
}

DLLEXPORT int get_integer() {
    return integer;
}
