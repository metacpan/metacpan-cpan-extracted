#include "std.h"

typedef int (*pii_i)(void *, int, int);
DLLEXPORT int cb_pii_i(pii_i cb) {
    return ((*cb)(NULL, 100, 200));
}

//
typedef bool (*dZb_b)(double, const char *, bool);
DLLEXPORT bool cb_dZb_b(dZb_b cb) {
    return ((*cb)(9.9, "Hi", false));
}

//
typedef void (*v_v)(void);
DLLEXPORT bool cb_v_v(v_v cb) {
    ((*cb)());
    return true;
}

//
typedef bool (*b_b)(bool);
DLLEXPORT bool cb_b_b(b_b cb) {
    return ((*cb)(true));
}

//
typedef char (*c_c)(char);
DLLEXPORT char cb_c_c(c_c cb) {
    return ((*cb)(-'A'));
}

//
typedef unsigned char (*C_C)(unsigned char);
DLLEXPORT unsigned char cb_C_C(C_C cb) {
    return ((*cb)('Q'));
}

//
typedef short (*s_s)(short);
DLLEXPORT short cb_s_s(s_s cb) {
    return ((*cb)(-8));
}

//
typedef unsigned short (*S_S)(unsigned short);
DLLEXPORT unsigned short cb_S_S(S_S cb) {
    return ((*cb)(16));
}

//
typedef int (*i_i)(int);
DLLEXPORT int cb_i_i(i_i cb) {
    return ((*cb)(-20));
}

//
typedef unsigned int (*I_I)(unsigned int);
DLLEXPORT unsigned int cb_I_I(I_I cb) {
    return ((*cb)(44));
}

//
typedef long (*j_j)(long);
DLLEXPORT long cb_j_j(j_j cb) {
    return ((*cb)(-3219));
}

//
typedef unsigned long (*J_J)(unsigned long);
DLLEXPORT unsigned long cb_J_J(J_J cb) {
    return ((*cb)(8990));
}

//
typedef long long (*l_l)(long long);
DLLEXPORT long long cb_l_l(l_l cb) {
    return ((*cb)(-47923));
}

//
typedef unsigned long long (*L_L)(unsigned long long);
DLLEXPORT unsigned long long cb_L_L(L_L cb) {
    return ((*cb)(93294));
}

//
typedef float (*f_f)(float);
DLLEXPORT float cb_f_f(f_f cb) {
    return ((*cb)(-99.3));
}

//
typedef double (*d_d)(double);
DLLEXPORT double cb_d_d(d_d cb) {
    return ((*cb)(200.3));
}

//
typedef char *(*Z_Z)(char *);
DLLEXPORT char *cb_Z_Z(Z_Z cb) {
    return ((*cb)("Ready!"));
}

//
struct A {
    Z_Z cb;
    int i;
};
DLLEXPORT char *cb_A(struct A a) {
    return ((*a.cb)("Ready!"));
}

//
typedef char *(*sub)();
typedef char *(*CV_Z)(char *, sub code);
DLLEXPORT char *cb_CV_Z(CV_Z cb, sub code) {
    warn("# here at %s line %d", __FILE__, __LINE__);
    (*code)();
    warn("# here at %s line %d", __FILE__, __LINE__);
    return ((*cb)("Ready!", code));
}
