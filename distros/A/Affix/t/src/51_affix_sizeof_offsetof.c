#include "std.h"
//
DLLEXPORT size_t s_bool() {
    return sizeof(bool);
}
DLLEXPORT size_t s_char() {
    return sizeof(char);
}
DLLEXPORT size_t s_short() {
    return sizeof(short);
}
DLLEXPORT size_t s_int() {
    return sizeof(int);
}
DLLEXPORT size_t s_long() {
    return sizeof(long);
}
DLLEXPORT size_t s_longlong() {
    return sizeof(long long);
}
DLLEXPORT size_t s_float() {
    return sizeof(float);
}
DLLEXPORT size_t s_double() {
    return sizeof(double);
}
DLLEXPORT size_t s_ssize_t() {
    return sizeof(ssize_t);
}
DLLEXPORT size_t s_size_t() {
    //~ warn("# sizeof(size_t) == %zu", sizeof(size_t));
    //~ warn("# sizeof(unsigned long) == %zu", sizeof(unsigned long));
    //~ warn("# sizeof(unsigned long long) == %zu", sizeof(unsigned long long));
    //~ warn("# sizeof(unsigned int) == %zu", sizeof(unsigned int));
    /*
        warn("# Size_t_size == %zu", Size_t_size);
        warn("# INTSIZE == %zu", INTSIZE);
        warn("# LONGSIZE == %zu", LONGSIZE);*/
    return sizeof(size_t);
}

DLLEXPORT size_t s_pointer() {
    return sizeof(void *);
}

DLLEXPORT size_t s_pointer_array() {
    return sizeof(void *[1]);
}

DLLEXPORT size_t s_string_array() {
    return sizeof(char *[3]);
}

//
typedef struct {
    char c[3];
} struct1;
typedef struct {
    int c[3];
} struct2;
typedef struct {
    double d;
    int c[3];
} struct3;
typedef struct {
    struct3 y;
} struct4;
typedef struct {
    struct {
        double d;
        int c[3];
    } y;

} struct5;

typedef struct {
    struct3 y;
    struct4 s;
    char c;
} struct6;

typedef struct {
    int i;
    char *Z;
} struct7;

typedef struct {
    double d;
    int c[4];
} struct8;

DLLEXPORT size_t s_struct1() {
    return sizeof(struct1);
}
DLLEXPORT size_t s_struct2() {
    return sizeof(struct2);
}
DLLEXPORT size_t s_struct3() {
    return sizeof(struct3);
}
DLLEXPORT size_t s_struct4() {
    return sizeof(struct4);
}
DLLEXPORT size_t s_struct5() {
    return sizeof(struct5);
}
DLLEXPORT size_t s_struct6() {
    //~ warn("offsetof(struct6, s) == %zu", offsetof(struct6, s));
    //~ warn("offsetof(struct6, c) == %zu", offsetof(struct6, c));
    //~ warn("sizeof(struct4) == %zu", sizeof(struct4));
    return sizeof(struct6);
}

DLLEXPORT size_t s_struct7() {
    return sizeof(struct7);
}

DLLEXPORT size_t s_struct8() {
    return sizeof(struct8);
}
//
typedef struct {
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
    struct {
        int i;
    } A;
    union
    {
        int i;
        struct {
            void *ptr;
            long l;
        } structure;

    } u;
} massive;
DLLEXPORT size_t s_massive() {
    return sizeof(massive);
}

//
typedef struct {
    double d;
    int c[4];
} array_struct;
DLLEXPORT size_t s_array1(int length) {
    return sizeof(array_struct[length]);
}

//
typedef union
{
    int i;
    float d;
} union1;

typedef union
{
    int i;
    struct1 s;
    float d;
} union2;
typedef union
{
    int i;
    struct3 s;
    float d;
} union3;
typedef union
{
    int i;
    struct1 s[5];
    float d;
} union4;

DLLEXPORT size_t s_union1() {
    return sizeof(union1);
}
DLLEXPORT size_t s_union2() {
    return sizeof(union2);
}
DLLEXPORT size_t s_union3() {
    return sizeof(union3);
}
DLLEXPORT size_t s_union4() {
    return sizeof(union4);
}
//
DLLEXPORT size_t s_voidptr() {
    return sizeof(void *);
}
//
DLLEXPORT size_t o_B() {
    return offsetof(massive, B);
}
DLLEXPORT size_t o_c() {
    return offsetof(massive, c);
}
DLLEXPORT size_t o_C() {
    return offsetof(massive, C);
}
DLLEXPORT size_t o_s() {
    return offsetof(massive, s);
}
DLLEXPORT size_t o_S() {
    return offsetof(massive, S);
}
DLLEXPORT size_t o_i() {
    return offsetof(massive, i);
}
DLLEXPORT size_t o_I() {
    return offsetof(massive, I);
}
DLLEXPORT size_t o_j() {
    return offsetof(massive, j);
}
DLLEXPORT size_t o_J() {
    return offsetof(massive, J);
}
DLLEXPORT size_t o_l() {
    return offsetof(massive, l);
}
DLLEXPORT size_t o_L() {
    return offsetof(massive, L);
}
DLLEXPORT size_t o_f() {
    return offsetof(massive, f);
}
DLLEXPORT size_t o_d() {
    return offsetof(massive, d);
}
DLLEXPORT size_t o_p() {
    return offsetof(massive, p);
}
DLLEXPORT size_t o_Z() {
    return offsetof(massive, Z);
}
