// C program to demonstrate use of variable
// number of arguments.
#include <stdarg.h>

#include "std.h"

// this function returns minimum of integer
// numbers passed. First argument is count
// of numbers.
DLLEXPORT int average(int num, ...) {
    va_list valist;

    int sum = 0, i;

    va_start(valist, num);
    for (i = 0; i < num; i++) {
        sum += va_arg(valist, int);
        warn("# sum: %d", sum);
    }

    va_end(valist);

    warn("# %d / %d == %d", sum, num, sum / num);
    return sum / num;
}
