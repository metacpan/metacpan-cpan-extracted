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
    warn("# sizeof(size_t) == %zu", sizeof(size_t));
    warn("# sizeof(unsigned long) == %zu", sizeof(unsigned long));
    warn("# sizeof(unsigned long long) == %zu", sizeof(unsigned long long));
    warn("# sizeof(unsigned int) == %zu", sizeof(unsigned int));

    /*warn("# Size_t_size == %zu", Size_t_size);
    warn("# INTSIZE == %zu", INTSIZE);
    warn("# LONGSIZE == %zu", LONGSIZE);*/
    return sizeof(size_t);
}

//
typedef struct
{
    char c[3];
} struct1;
typedef struct
{
    int c[3];
} struct2;
typedef struct
{
    double d;
    int c[3];
} struct3;
typedef struct
{
    struct3 y;
} struct4;
typedef struct
{
    struct
    {
        double d;
        int c[3];
    } y;

} struct5;

typedef struct
{
    struct3 y;
    struct4 s;
    char c;
} struct6;

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
    warn("offsetof(struct6, s) == %d", offsetof(struct6, s));
    warn("offsetof(struct6, c) == %d", offsetof(struct6, c));
    warn("sizeof(struct4) == %d", sizeof(struct4));
    return sizeof(struct6);
}

//
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
DLLEXPORT size_t s_massive() {
    return sizeof(massive);
}

//
DLLEXPORT size_t s_array1() {
    return sizeof(struct {
        double d;
        int c[3];
    }[3]);
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
