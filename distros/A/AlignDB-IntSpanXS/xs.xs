#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "intspan.h"

typedef intspan*         AlignDB__IntSpanXS;

MODULE = AlignDB::IntSpanXS		PACKAGE = AlignDB::IntSpanXS

int
POS_INF(itsx)
    AlignDB::IntSpanXS itsx
    INIT:
        int i = POS_INF - 1;
    PROTOTYPE: $
    PPCODE:
        XPUSHs(sv_2mortal(newSViv(i)));

int
NEG_INF(itsx)
    AlignDB::IntSpanXS itsx
    PROTOTYPE: $
    PPCODE:
        XPUSHs(sv_2mortal(newSViv(NEG_INF)));

SV *
EMPTY_STRING(itsx)
    AlignDB::IntSpanXS itsx
    PROTOTYPE: $
    PPCODE:
        XPUSHs(sv_2mortal(newSVpv(EMPTY_STRING, 0)));

AlignDB::IntSpanXS
_new(pack)
    char *pack
    PROTOTYPE: $
    CODE:
        RETVAL = intspan_new();
    OUTPUT:
        RETVAL

void
DESTROY(itsx)
    AlignDB::IntSpanXS itsx
    PROTOTYPE: $
    CODE:
        intspan_destroy(itsx);

void
clear(itsx)
    AlignDB::IntSpanXS itsx
    PROTOTYPE: $
    CODE:
        intspan_clear(itsx);

void
edges(itsx)
    AlignDB::IntSpanXS itsx
    INIT:
        int i;
        int j;
        veci *vec;
    PROTOTYPE: $
    PPCODE:
        vec = intspan_edges(itsx);
        for (i = 0; i < veci_size(vec); i++) {
            j = veci_get(vec, i);
            XPUSHs(sv_2mortal(newSViv(j)));
        }
        #veci_destroy(vec); //this vec belongs to the intspan object

int
edge_size(itsx)
    AlignDB::IntSpanXS itsx
    PROTOTYPE: $
    CODE:
        RETVAL = intspan_edge_size(itsx);
    OUTPUT:
        RETVAL

int
span_size(itsx)
    AlignDB::IntSpanXS itsx
    PROTOTYPE: $
    CODE:
        RETVAL = intspan_span_size(itsx);
    OUTPUT:
        RETVAL

SV *
as_string(itsx)
    AlignDB::IntSpanXS itsx
    PREINIT:
        char *tmp_buffer;
        int len = 1024;
    PROTOTYPE: $
    PPCODE:
        tmp_buffer = (char *)malloc(len + 1);
        if (tmp_buffer == NULL)
            XSRETURN_UNDEF;

        intspan_as_string(itsx, &tmp_buffer, len);

        XPUSHs(sv_2mortal(newSVpv(tmp_buffer, 0)));
        free(tmp_buffer);

void
as_array(itsx)
    AlignDB::IntSpanXS itsx
    INIT:
        int i;
        int j;
        veci *vec;
    PROTOTYPE: $
    PPCODE:
        vec = intspan_as_veci(itsx);
        for (i = 0; i < veci_size(vec); i++) {
            j = veci_get(vec, i);
            XPUSHs(sv_2mortal(newSViv(j)));
        }
        veci_destroy(vec);

void
ranges(itsx)
    AlignDB::IntSpanXS itsx
    INIT:
        int i;
        int j;
        veci *vec;
    PROTOTYPE: $
    PPCODE:
        vec = intspan_ranges(itsx);
        for (i = 0; i < veci_size(vec); i++) {
            j = veci_get(vec, i);
            XPUSHs(sv_2mortal(newSViv(j)));
        }
        veci_destroy(vec);

int
cardinality(itsx)
    AlignDB::IntSpanXS itsx
    CODE:
        RETVAL = intspan_cardinality(itsx);
    OUTPUT:
        RETVAL

int
is_empty(itsx)
    AlignDB::IntSpanXS itsx
    CODE:
        RETVAL = intspan_is_empty(itsx);
    OUTPUT:
        RETVAL

int
is_not_empty(itsx)
    AlignDB::IntSpanXS itsx
    CODE:
        RETVAL = intspan_is_not_empty(itsx);
    OUTPUT:
        RETVAL

int
is_neg_inf(itsx)
    AlignDB::IntSpanXS itsx
    CODE:
        RETVAL = intspan_is_neg_inf(itsx);
    OUTPUT:
        RETVAL

int
is_pos_inf(itsx)
    AlignDB::IntSpanXS itsx
    CODE:
        RETVAL = intspan_is_pos_inf(itsx);
    OUTPUT:
        RETVAL

int
is_infinite(itsx)
    AlignDB::IntSpanXS itsx
    CODE:
        RETVAL = intspan_is_infinite(itsx);
    OUTPUT:
        RETVAL

int
is_finite(itsx)
    AlignDB::IntSpanXS itsx
    CODE:
        RETVAL = intspan_is_finite(itsx);
    OUTPUT:
        RETVAL

int
is_universal(itsx)
    AlignDB::IntSpanXS itsx
    CODE:
        RETVAL = intspan_is_universal(itsx);
    OUTPUT:
        RETVAL

int
_contains(itsx, i)
    AlignDB::IntSpanXS itsx
    int i
    PROTOTYPE: $$
    CODE:
        RETVAL = intspan_contains(itsx, i);
    OUTPUT:
        RETVAL

void
add_pair(itsx, lower, upper)
    AlignDB::IntSpanXS itsx
    int lower
    int upper
    PROTOTYPE: $$$
    CODE:
        intspan_add_pair(itsx, lower, upper);

void
add_int(itsx, i)
    AlignDB::IntSpanXS itsx
    int i
    PROTOTYPE: $$
    CODE:
        intspan_add(itsx, i);

void
add_array(itsx, array)
    AlignDB::IntSpanXS itsx
    AV * array
    INIT:
        int i;
        int j;
        veci *vec = veci_create(64);
    PROTOTYPE: $$
    CODE:
        for (i = 0; i <= av_len(array); i++) {
            SV** elem = av_fetch(array, i, 0);
            if (elem != NULL) {
                j = SvIV(*elem);
                veci_add(vec, j);
            }
        }
        intspan_add_vec(itsx, vec);
        veci_destroy(vec);

void
add_runlist(itsx, rl)
    AlignDB::IntSpanXS itsx
    char * rl
    PROTOTYPE: $$
    CODE:
        intspan_add_runlist(itsx, rl);

void
invert(itsx)
    AlignDB::IntSpanXS itsx
    PROTOTYPE: $
    CODE:
        intspan_invert(itsx);

void
remove_pair(itsx, lower, upper)
    AlignDB::IntSpanXS itsx
    int lower
    int upper
    PROTOTYPE: $$$
    CODE:
        intspan_remove_pair(itsx, lower, upper);

void
remove_int(itsx, i)
    AlignDB::IntSpanXS itsx
    int i
    PROTOTYPE: $$
    CODE:
        intspan_remove(itsx, i);

void
remove_array(itsx, array)
    AlignDB::IntSpanXS itsx
    AV * array
    INIT:
        int i;
        int j;
        veci *vec = veci_create(64);
    PROTOTYPE: $$
    CODE:
        for (i = 0; i <= av_len(array); i++) {
            SV** elem = av_fetch(array, i, 0);
            if (elem != NULL) {
                j = SvIV(*elem);
                veci_add(vec, j);
            }
        }
        intspan_remove_vec(itsx, vec);
        veci_destroy(vec);

void
remove_runlist(itsx, rl)
    AlignDB::IntSpanXS itsx
    char * rl
    PROTOTYPE: $$
    CODE:
        intspan_remove_runlist(itsx, rl);

AlignDB::IntSpanXS
copy(itsx)
    AlignDB::IntSpanXS itsx
    PROTOTYPE: $
    CODE:
        RETVAL = intspan_copy(itsx);
    OUTPUT:
        RETVAL

int
_find_pos(itsx, val, low)
    AlignDB::IntSpanXS itsx
    int val
    int low
    PROTOTYPE: $$$
    CODE:
        RETVAL = intspan_find_pos(itsx, val, low);
    OUTPUT:
        RETVAL
