#include "std.h"

typedef struct intstruct {
    int i;
} IntStruct;
typedef struct intintstruct {
    int i, j;
} IntIntStruct;

DLLEXPORT int TakeIntStruct(IntStruct x) {
    warn("# x.i!, %d", x.i);
    warn("# IntStruct.i == %lu", offsetof(IntStruct, i));
    warn("# IntIntStruct.i == %lu", offsetof(IntIntStruct, i));
    warn("# IntIntStruct.j == %lu", offsetof(IntIntStruct, j));
    if (x.i == 42) return 1;
    return 0;
}

DLLEXPORT int TakeIntIntStruct(IntIntStruct x) {
    warn("# x.i!, %d", x.i);
    warn("# x.j, %d", x.j);
    return x.i + x.j;
}

DLLEXPORT int TakeIntArray(int ints[3]) {
    int retval = 0;
    for (int i = 0; i < 3; ++i)
        retval += ints[i];
    return retval;
}

struct twoshortstruct {
    short x, y;
};
typedef struct twoshortstruct TwoShortStruct;

DLLEXPORT int TakeTwoShortsStruct(TwoShortStruct x) {
    // return offsetof(struct twoshortstruct, y);
    // return sizeof(TwoShortStruct);
    int retval = 0;
    if (x.x == 10) retval += 1;
    if (x.y == 20) retval += 2;
    return retval;
}

struct intshortcharstruct {
    int x;
    short y;
    char z;
};
typedef struct intshortcharstruct IntShortCharStruct;

struct i_ {
    char d;
    char a;
    short f;
    int fds;
    int fdae;
    long klj;
    char l;
    char p;
    char nl;

    // int y;
    // long fd;
    //  double fdsa;
    // long long fdd;
    // short v2;
};
struct is_ {
    int x;
    short y;
};
struct isc_ {
    int x;
    short y;
    char z;
};

#include <stddef.h>
#include <stdio.h>

typedef struct {
    char c1;
    char c2;
    short s1;
    int i1;
    int i2;
    long l1;
    char c3;
    char c4;
    char c5;
} gappy_t;

#define Pt(struct, field, tchar) printf("# ------------ @%zu%s ", offsetof(struct, field), #tchar);

int pppp() {
    Pt(gappy_t, c1, c);
    Pt(gappy_t, c2, c);

    Pt(gappy_t, s1, s !);

    Pt(gappy_t, i1, i);
    Pt(gappy_t, i2, i);

    Pt(gappy_t, l1, l !);

    Pt(gappy_t, c3, c);
    Pt(gappy_t, c4, c);
    Pt(gappy_t, c5, c);
    printf("\n");
    return 0;
}

struct test {
    char a[5];
    char b;
    short c;
    int d;
    int e[3];
    long f;
    char g;
    char h[2];
    char i;

    // int y;
    // long fd;
    //  double fdsa;
    // long long fdd;
    // short v2;

}
//__attribute__ ((aligned (16)))
;

DLLEXPORT int IntShortChar(IntShortCharStruct x) {
    /*  return sizeof(struct test);
  return offsetof(struct test, b);


char d;
  char a;
  short f;
  int fds;
  int fdae;
  long klj;
  char l; char p; char nl;

  pppp();
  return sizeof(struct i_);
  return sizeof(x);*/
    if (x.x == 101 && x.y == 102 && x.z == 103) return 3;
    return 0;
}

DLLEXPORT int TakeADouble(double x) {
    if (-6.9 - x < 0.001) return 4;
    return 0;
}

DLLEXPORT int TakeADoubleNaN(double x) {
    if (isnan(x)) return 4;
    return 0;
}

DLLEXPORT int TakeAFloat(float x) {
    if (4.2 - x < 0.001) return 5;
    return 0;
}

DLLEXPORT int TakeAFloatNaN(float x) {
    if (isnan(x)) return 5;
    return 0;
}

DLLEXPORT int TakeAString(char *pass_msg) {
    if (0 == strcmp(pass_msg, "ok 6 - passed a string")) return 6;
    return 0;
}

static char *cached_str = NULL;
DLLEXPORT void SetString(char *str) {
    cached_str = str;
}

DLLEXPORT int CheckString() {
    if (0 == strcmp(cached_str, "ok 7 - checked previously passed string")) return 7;
    return 0;
}

DLLEXPORT int wrapped(int n) {
    if (n == 42) return 8;
    return 0;
}

DLLEXPORT int TakeInt64(int64_t x) {
    if (x == 0xFFFFFFFFFF) return 9;
    return 0;
}

DLLEXPORT int TakeUint8(unsigned char x) {
    if (x == 0xFE) return 10;
    return 0;
}

DLLEXPORT int TakeUint16(unsigned short x) {
    if (x == 0xFFFE) return 11;
    return 0;
}

DLLEXPORT int TakeUint32(unsigned int x) {
    if (x == 0xFFFFFFFE) return 12;
    return 0;
}

DLLEXPORT int TakeSizeT(size_t x) {
    if (x == 42) return 13;
    return 0;
}

DLLEXPORT int TakeSSizeT(ssize_t x) {
    if (x == -42) return 14;
    return 0;
}
