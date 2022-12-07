#include "std.h"

DLLEXPORT void Nothing() {
    /* we don't even print something */
}

DLLEXPORT int Argless() {
    return 2;
}

DLLEXPORT char ArglessChar() {
    return 2;
}

DLLEXPORT long long ArglessLongLong() {
    return 2;
}

int my_int = 2;
DLLEXPORT int *ArglessPointer() {
    return &my_int;
}

const char *my_str = "Just a string";
DLLEXPORT const char *ArglessUTF8String() {
    return my_str;
}

DLLEXPORT int long_and_complicated_name() {
    return 3;
}
