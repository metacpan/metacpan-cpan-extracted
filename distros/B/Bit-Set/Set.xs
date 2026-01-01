#include "macros_defs.h"

MODULE = Bit::Set    PACKAGE = Bit::Set    PREFIX = BS_

PROTOTYPES: DISABLE

INCLUDE: Set_procedural.xs


MODULE = Bit::Set    PACKAGE = Bit::Set    PREFIX = BSOO_

PROTOTYPES: DISABLE


SV *BSOO_new(char *class, IV length)

    CODE:
      Bit_T obj = Bit_new(length);
      ST(0)  = sv_newmortal();
      sv_setiv(newSVrv(ST(0), class), PTR2IV(obj));

void BSOO_DESTROY(Bit_T obj)

    CODE:
      Bit_free(&obj);

SV *BSOO_load(char *class, IV length, char *buffer)

    CODE:
      Bit_T obj = Bit_load(length,(void *)buffer);
      ST(0)  = sv_newmortal();
      sv_setiv(newSVrv(ST(0), class), PTR2IV(obj));

SV *BSOO_extract(Bit_T obj, char *buffer)

    CODE:
      IV rv = Bit_extract(obj,(void *)buffer);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), rv);

SV *BSOO_buffer_size(char *class, IV length)

    CODE:
      IV rv = Bit_buffer_size(length);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), rv);

SV *BSOO_length(Bit_T obj)

    CODE:
      IV rv = Bit_length(obj);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), rv);

SV *BSOO_count(Bit_T obj)

    CODE:
      IV rv = Bit_count(obj);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), rv);

void BSOO_aset(Bit_T obj, INTEGER_ARRAY_REF indices)

    CODE:
      AV *av = (AV *)SvRV(indices);
      int n = av_len(av) + 1;
  ALLOC_ARRAY_IN_STACK_OR_HEAP(idx,int,n);
      FILL_INT_ARRAY_FROM_AV(av, idx, n);

      Bit_aset(obj, idx, n);
      FREE_ARRAY_IN_STACK_OR_HEAP(idx);


void BSOO_bset(Bit_T obj, IV index)

    CODE:
      Bit_bset(obj, index);

void BSOO_aclear(Bit_T obj, INTEGER_ARRAY_REF indices)

    CODE:
      AV *av = (AV *)SvRV(indices);
      int n = av_len(av) + 1;
  ALLOC_ARRAY_IN_STACK_OR_HEAP(idx,int,n);
      FILL_INT_ARRAY_FROM_AV(av, idx, n);

      Bit_aclear(obj, idx, n);

      FREE_ARRAY_IN_STACK_OR_HEAP(idx);

void BSOO_bclear(Bit_T obj, IV index)

    CODE:
      Bit_bclear(obj, index);

void BSOO_clear(Bit_T obj, IV lo, IV hi)

    CODE:
      Bit_clear(obj, lo, hi);

SV *BSOO_get(Bit_T obj, IV index)

    CODE:
      IV rv = Bit_get(obj, index);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), rv);

void BSOO_not(Bit_T obj, IV lo, IV hi)

    CODE:
      Bit_not(obj, lo, hi);

SV *BSOO_put(Bit_T obj, IV index, IV bit)

    CODE:
      IV rv = Bit_put(obj, index, bit);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), rv);

void BSOO_set(Bit_T obj, IV lo, IV hi)

    CODE:
      Bit_set(obj, lo, hi);

SV *BSOO_eq(Bit_T obj, Bit_T other)

    CODE:
      IV rv = Bit_eq(obj, other);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), rv);

SV *BSOO_leq(Bit_T obj, Bit_T other)

    CODE:
      IV rv = Bit_leq(obj, other);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), rv);

SV *BSOO_lt(Bit_T obj, Bit_T other)

    CODE:
      IV rv = Bit_lt(obj, other);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), rv);

SV *BSOO_diff(Bit_T obj, Bit_T other)

    CODE:
      Bit_T rv = Bit_diff(obj, other);
      ST(0)  = sv_newmortal();
      sv_setiv(newSVrv(ST(0), "Bit::Set"), PTR2IV(rv));

SV *BSOO_inter(Bit_T obj, Bit_T other)

    CODE:
      Bit_T rv = Bit_inter(obj, other);
      ST(0)  = sv_newmortal();
      sv_setiv(newSVrv(ST(0), "Bit::Set"), PTR2IV(rv));

SV *BSOO_minus(Bit_T obj, Bit_T other)

    CODE:
      Bit_T rv = Bit_minus(obj, other);
      ST(0)  = sv_newmortal();
      sv_setiv(newSVrv(ST(0), "Bit::Set"), PTR2IV(rv));

SV *BSOO_union(Bit_T obj, Bit_T other)

    CODE:
      Bit_T rv = Bit_union(obj, other);
      ST(0)  = sv_newmortal();
      sv_setiv(newSVrv(ST(0), "Bit::Set"), PTR2IV(rv));

SV *BSOO_diff_count(Bit_T obj, Bit_T other)

    CODE:
      IV rv = Bit_diff_count(obj, other);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), rv);

SV *BSOO_inter_count(Bit_T obj, Bit_T other)

    CODE:
      IV rv = Bit_inter_count(obj, other);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), rv);

SV *BSOO_minus_count(Bit_T obj, Bit_T other)

    CODE:
      IV rv = Bit_minus_count(obj, other);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), rv);

SV *BSOO_union_count(Bit_T obj, Bit_T other)

    CODE:
      IV rv = Bit_union_count(obj, other);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), rv);

