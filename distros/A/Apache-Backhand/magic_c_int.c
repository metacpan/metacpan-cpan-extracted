/* ====================================================================
 * Copyright (c) 2000 David Lowe.
 *
 * magic_c_int.c
 *
 * A set of functions for creating magical SVs closely tied to C integers
 * ==================================================================== */

#include "magic_c_int.h"

I32 magic_c_int_get(IV num, SV *sv) {
    MAGIC *mg = mg_find(sv, (int)'U');

    sv_setiv(sv, *((int *)(SvIV(mg->mg_obj))));
    return 1;
}
 
I32 magic_c_int_set(IV num, SV *sv) {
    MAGIC *mg = mg_find(sv, (int)'U');

    *((int *)(SvIV(mg->mg_obj))) = SvIV(sv);
    return 1;
}
 
SV *newSV_magic_c_int(int *addr) {
    static struct ufuncs magic_c_int = {magic_c_int_get, magic_c_int_set, 0};
    SV                   *var        = newSViv(*addr);
    MAGIC                *mg         = NULL;

    sv_magic(var, newSViv((int)addr), (int)'U', NULL, 0);
    mg = mg_find(var, (int)'U');
    mg->mg_ptr = (char *)&magic_c_int;

    return var;
}
