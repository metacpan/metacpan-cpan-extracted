#include "std.h"

DLLEXPORT int array_reverse(int a[], int len) {
    int tmp, i;
    int ret = 0;
    for (i = 0; i < len / 2; i++) {
        ret += a[i];
        tmp = a[i];
        a[i] = a[len - i - 1];
        a[len - i - 1] = tmp;
    }
    return ret;
}

DLLEXPORT int array_reverse10(int a[10]) {
    return array_reverse(a, 10);
}

DLLEXPORT int array_sum(const int *a) {
    int i, sum;
    if (a == NULL) return -1;
    for (i = 0, sum = 0; a[i] != 0; i++)
        sum += a[i];
    return sum;
}
