#include "std.h"

typedef struct
{
    bool B;
    char c;
    unsigned char C;
    short s;
    unsigned short S;
    int i;
    unsigned int I;
    long j;
    unsigned long J;
    long long l;
    unsigned long long L;
    float f;
    double d;
    int *p;
    char *Z;
    struct
    {
        int i;
    } A;
    union
    {
        int i;
        struct
        {
            void *ptr;
            long l;
        } structure;
    } u;
} massive;

int _p = 303;
massive retval = {.B = true,
                  .c = 'c',
                  .C = 'C',
                  .s = 3,
                  .S = 5,
                  .i = -987,
                  .I = 678,
                  .j = 13579,
                  .J = 24680,
                  .l = -1234567890,
                  .L = 9876543210,
                  .f = 9.9843,
                  .d = 1.246,
                  .p = &_p,
                  .Z = "Just a little test",
                  .u = 5,
                  .A = {.i = 50}};

DLLEXPORT massive *massive_ptr() {
    warn("    # sizeof in C:    %d", sizeof(massive));
    warn("    # offset.B:       %d", offsetof(massive, B));
    warn("    # offset.c:       %d", offsetof(massive, c));
    warn("    # offset.C:       %d", offsetof(massive, C));
    warn("    # offset.s:       %d", offsetof(massive, s));
    warn("    # offset.S:       %d", offsetof(massive, S));
    warn("    # offset.i:       %d", offsetof(massive, i));
    warn("    # offset.I:       %d", offsetof(massive, I));
    warn("    # offset.j:       %d", offsetof(massive, j));
    warn("    # offset.J:       %d", offsetof(massive, J));
    warn("    # offset.Z:       %d", offsetof(massive, Z));

    /*retval.c = -100;
    retval.C = 100;
    retval.s = -30;
    retval.S = 40;
    retval.Z = "Hi!";*/
    //(massive*) malloc(sizeof(massive));
    warn("Z.i: %d", retval.A.i);
    warn("Z: %s", retval.Z);
    return &retval;
}
DLLEXPORT char *dbl_ptr(double *dbl) {
    warn("# dbl == %f", *dbl);
    if (dbl == NULL)
        return "NULL";
    else if (*dbl == 0) {
        *dbl = 1000;
        return "empty";
    }
    else if (*dbl == 100) {
        *dbl = 1000;
        return "one hundred";
    }
    else if (*dbl == 100.04) {
        *dbl = 10000;
        return "one hundred and change";
    }
    else if (*dbl == 9) {
        *dbl = 9876.543;
        return "nine";
    }

    return "fallback";
}

/* Use typedef to declare the name "my_function_t"
   as an alias whose type is a function that takes
   one integer argument and returns an integer */
typedef double my_function_t(int, int);

DLLEXPORT double pointer_test(double *dbl, int arr[5], int size,
                              my_function_t *my_function_pointer) {
    if (dbl == NULL) return -1;
    if (*dbl == 90) return 501;
    // for (int i = 0; i < size; ++i)
    //     warn("# arr[%d] == %d", i, arr[i]);
    if (*dbl >= 590343.12351) {
        warn("# In: %f", *dbl);
        *dbl = 3.493;
        return *dbl * 5.25;
    }
    /* Invoke the function via the global function
       pointer variable. */
    double ret = my_function_pointer(4, 8);
    *dbl = ret * 2;

    return 900;
}
