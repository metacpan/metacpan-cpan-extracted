#include "macros_defs.h"


MODULE = Bit::Set    PACKAGE = Bit::Set    PREFIX = BS_

PROTOTYPES: DISABLE

INCLUDE: Set_procedural.xs.inc


MODULE = Bit::Set    PACKAGE = Bit::Set    PREFIX = BSOO_

PROTOTYPES: DISABLE

Bit_T_obj
BSOO_new(char *class, IV length)

    CODE:
        Bit_T_obj obj = Bit_new(length);
        RETVAL = obj;
    OUTPUT:
        RETVAL

void BSOO_DESTROY(Bit_T_obj obj)

    CODE:
      Bit_free(&obj);

Bit_T_obj
BSOO_load(char *class, IV length, char *buffer)

    CODE:
      Bit_T obj = Bit_load(length,(void *)buffer);
      RETVAL = obj;
    OUTPUT:
      RETVAL

IV
BSOO_extract(Bit_T_obj obj, char *buffer)

    CODE:
      IV rv = Bit_extract(obj,(void *)buffer);
      RETVAL = rv;
    OUTPUT:
      RETVAL

IV
BSOO_buffer_size(char *class, IV length)

    CODE:
      IV rv = Bit_buffer_size(length);
      RETVAL = rv;
    OUTPUT:
      RETVAL

IV
BSOO_length(Bit_T_obj obj)

    CODE:
      IV rv = Bit_length(obj);
      RETVAL = rv;
    OUTPUT:
      RETVAL

IV
BSOO_count(Bit_T_obj obj)

    CODE:
      IV rv = Bit_count(obj);
      RETVAL = rv;
    OUTPUT:
      RETVAL

void BSOO_aset(Bit_T_obj obj, INTEGER_ARRAY_REF indices)

    CODE:
      AV *av = (AV *)SvRV(indices);
      int n = av_len(av) + 1;
      ALLOC_ARRAY_IN_STACK_OR_HEAP(idx,int,n);
      FILL_INT_ARRAY_FROM_AV(av, idx, n);

      Bit_aset(obj, idx, n);
      FREE_ARRAY_IN_STACK_OR_HEAP(idx);


void BSOO_bset(Bit_T_obj obj, IV index)

    CODE:
      Bit_bset(obj, index);

void BSOO_aclear(Bit_T_obj obj, INTEGER_ARRAY_REF indices)

    CODE:
      AV *av = (AV *)SvRV(indices);
      int n = av_len(av) + 1;
      ALLOC_ARRAY_IN_STACK_OR_HEAP(idx,int,n);
      FILL_INT_ARRAY_FROM_AV(av, idx, n);

      Bit_aclear(obj, idx, n);

      FREE_ARRAY_IN_STACK_OR_HEAP(idx);

void BSOO_bclear(Bit_T_obj obj, IV index)

    CODE:
      Bit_bclear(obj, index);

void BSOO_clear(Bit_T_obj obj, IV lo, IV hi)

    CODE:
      Bit_clear(obj, lo, hi);

IV
BSOO_get(Bit_T_obj obj, IV index)

    CODE:
      IV rv = Bit_get(obj, index);
      RETVAL = rv;
    OUTPUT:
      RETVAL

void BSOO_not(Bit_T_obj obj, IV lo, IV hi)

    CODE:
      Bit_not(obj, lo, hi);

IV
BSOO_put(Bit_T_obj obj, IV index, IV bit)

    CODE:
      IV rv = Bit_put(obj, index, bit);
      RETVAL = rv;
    OUTPUT:
      RETVAL

void BSOO_set(Bit_T_obj obj, IV lo, IV hi)

    CODE:
      Bit_set(obj, lo, hi);

IV
BSOO_eq(Bit_T_obj obj, Bit_T_obj other)

    CODE:
      IV rv = Bit_eq(obj, other);
      RETVAL = rv;
    OUTPUT:
      RETVAL

IV
BSOO_leq(Bit_T_obj obj, Bit_T_obj other)

    CODE:
      IV rv = Bit_leq(obj, other);
      RETVAL = rv;
    OUTPUT:
      RETVAL

IV
BSOO_lt(Bit_T_obj obj, Bit_T_obj other)

    CODE:
      IV rv = Bit_lt(obj, other);
      RETVAL = rv;
    OUTPUT:
      RETVAL

SV*
BSOO_diff(Bit_T_obj obj, Bit_T_obj other)

    CODE:
      Bit_T rv = Bit_diff(obj, other);
      RETURN_BLESSED_REFERENCE("Bit::Set",rv);

SV*
BSOO_inter(Bit_T_obj obj, Bit_T_obj other)

    CODE:
      Bit_T rv = Bit_inter(obj, other);
      RETURN_BLESSED_REFERENCE("Bit::Set",rv);

SV*
BSOO_minus(Bit_T_obj obj, Bit_T_obj other)

    CODE:
      Bit_T rv = Bit_minus(obj, other);
      RETURN_BLESSED_REFERENCE("Bit::Set",rv);

SV*
BSOO_union(Bit_T_obj obj, Bit_T_obj other)

    CODE:
      Bit_T rv = Bit_union(obj, other);
      RETURN_BLESSED_REFERENCE("Bit::Set",rv);

IV
BSOO_diff_count(Bit_T_obj obj, Bit_T_obj other)

    CODE:
        RETVAL = Bit_diff_count(obj, other);
    OUTPUT:
        RETVAL

IV
BSOO_inter_count(Bit_T_obj obj, Bit_T_obj other)

    CODE:
        RETVAL = (IV)Bit_inter_count(obj, other);
    OUTPUT:
        RETVAL

IV
BSOO_minus_count(Bit_T_obj obj, Bit_T_obj other)

    CODE:
        RETVAL = Bit_minus_count(obj, other);
    OUTPUT:
        RETVAL

IV
BSOO_union_count(Bit_T_obj obj, Bit_T_obj other)

    CODE:
        RETVAL = Bit_union_count(obj, other);
    OUTPUT:
        RETVAL

