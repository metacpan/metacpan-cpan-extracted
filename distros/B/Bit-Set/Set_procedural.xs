SV *
BS_Bit_new(IV length)
    CODE:
        Bit_T set = Bit_new((int)length);
        RETVAL = newSVuv(PTR2UV(set));
    OUTPUT:
        RETVAL

void
BS_Bit_free(SV *set_ref)
    CODE:
        if (!SvROK(set_ref)) {
            croak("Bit_free expects a scalar reference");
        }
        SV *inner = SvRV(set_ref);
        Bit_T set = INT2PTR(Bit_T, SvIV(inner));
        Bit_free(&set);


SV *
BS_Bit_load(IV length, SV *buffer)
    CODE:
        void *ptr = SV_TO_VOID(buffer);
        Bit_T set = Bit_load((int)length, ptr);
        RETVAL = newSVuv(PTR2UV(set));
    OUTPUT:
        RETVAL

IV
BS_Bit_extract(SV *set, SV *buffer)
    CODE:
        Bit_T obj = SV_TO_BIT_T(Bit_T, set, UNDEF_ERROR);
        void *ptr = SV_TO_VOID(buffer);
        RETVAL = (IV)Bit_extract(obj, ptr);
    OUTPUT:
        RETVAL

IV
BS_Bit_buffer_size(IV length)
    CODE:
        RETVAL = (IV)Bit_buffer_size((int)length);
    OUTPUT:
        RETVAL

IV
BS_Bit_length(SV *set)
    CODE:
        Bit_T obj = SV_TO_BIT_T(Bit_T, set, UNDEF_ERROR);
        RETVAL = (IV)Bit_length(obj);
    OUTPUT:
        RETVAL

IV
BS_Bit_count(SV *set)
    CODE:
        Bit_T obj = SV_TO_BIT_T(Bit_T, set, UNDEF_ERROR);
        RETVAL = (IV)Bit_count(obj);
    OUTPUT:
        RETVAL

void
BS_Bit_aset(SV *set, INTEGER_ARRAY_REF indices)
    CODE:
        Bit_T obj = SV_TO_BIT_T(Bit_T, set, UNDEF_ERROR);
        int stack_buf[STACK_MAX];
        int *idx=NULL;
        AV *av = (AV *)SvRV(indices);
        int n = av_len(av) + 1;
        if(n <=STACK_MAX) {
            idx =stack_buf;
        } else {
            Newx(idx, n,int );  // no need to handle null here, C will handle it
        }
        for (int i = 0; i < n; ++i) {
            SV **svp = av_fetch(av, i, 0);
            idx[i] = SvIV(*svp);
        }

        Bit_aset(obj, idx, n);

        if (idx != stack_buf)
            Safefree(idx);

void
BS_Bit_bset(SV *set, IV index)
    CODE:
        Bit_T obj = SV_TO_BIT_T(Bit_T, set, UNDEF_ERROR);
        Bit_bset(obj, (int)index);

void
BS_Bit_aclear(SV *set, INTEGER_ARRAY_REF indices)
    CODE:
        Bit_T obj = SV_TO_BIT_T(Bit_T, set, UNDEF_ERROR);
        int stack_buf[STACK_MAX];
        int *idx=NULL;
        AV *av = (AV *)SvRV(indices);
        int n = av_len(av) + 1;
        if(n <=STACK_MAX) {
            idx =stack_buf;
        } else {
            Newx(idx, n,int );  // no need to handle null here, C will handle it
        }
        for (int i = 0; i < n; ++i) {
            SV **svp = av_fetch(av, i, 0);
            idx[i] = SvIV(*svp);
        }

        Bit_aclear(obj, idx, n);

        if (idx != stack_buf)
            Safefree(idx);

void
BS_Bit_bclear(SV *set, IV index)
    CODE:
        Bit_T obj = SV_TO_BIT_T(Bit_T, set, UNDEF_ERROR);
        Bit_bclear(obj, (int)index);

void
BS_Bit_clear(SV *set, IV lo, IV hi)
    CODE:
        Bit_T obj = SV_TO_BIT_T(Bit_T, set, UNDEF_ERROR);
        Bit_clear(obj, (int)lo, (int)hi);

IV
BS_Bit_get(SV *set, IV index)
    CODE:
        Bit_T obj = SV_TO_BIT_T(Bit_T, set, UNDEF_ERROR);
        RETVAL = (IV)Bit_get(obj, (int)index);
    OUTPUT:
        RETVAL

void
BS_Bit_not(SV *set, IV lo, IV hi)
    CODE:
        Bit_T obj = SV_TO_BIT_T(Bit_T, set, UNDEF_ERROR);
        Bit_not(obj, (int)lo, (int)hi);

IV
BS_Bit_put(SV *set, IV n, IV val)
    CODE:
        Bit_T obj = SV_TO_BIT_T(Bit_T, set, UNDEF_ERROR);
        RETVAL = (IV)Bit_put(obj, (int)n, (int)val);
    OUTPUT:
        RETVAL

void
BS_Bit_set(SV *set, IV lo, IV hi)
    CODE:
        Bit_T obj = SV_TO_BIT_T(Bit_T, set, UNDEF_ERROR);
        Bit_set(obj, (int)lo, (int)hi);

IV
BS_Bit_eq(SV *s, SV *t)
    CODE:
        Bit_T ss = SV_TO_BIT_T(Bit_T, s, UNDEF_ERROR);
        Bit_T tt = SV_TO_BIT_T(Bit_T, t, UNDEF_ERROR);
        RETVAL = (IV)Bit_eq(ss, tt);
    OUTPUT:
        RETVAL

IV
BS_Bit_leq(SV *s, SV *t)
    CODE:
        Bit_T ss = SV_TO_BIT_T(Bit_T, s, UNDEF_ERROR);
        Bit_T tt = SV_TO_BIT_T(Bit_T, t, UNDEF_ERROR);
        RETVAL = (IV)Bit_leq(ss, tt);
    OUTPUT:
        RETVAL

IV
BS_Bit_lt(SV *s, SV *t)
    CODE:
        Bit_T ss = SV_TO_BIT_T(Bit_T, s, UNDEF_ERROR);
        Bit_T tt = SV_TO_BIT_T(Bit_T, t, UNDEF_ERROR);
        RETVAL = (IV)Bit_lt(ss, tt);
    OUTPUT:
        RETVAL

SV *
BS_Bit_diff(SV *s, SV *t)
    CODE:
        Bit_T ss = SV_TO_BIT_T(Bit_T, s, UNDEF_ERROR);
        Bit_T tt = SV_TO_BIT_T(Bit_T, t, UNDEF_ERROR);
        Bit_T rv = Bit_diff(ss, tt);
        RETVAL = newSVuv(PTR2UV(rv));
    OUTPUT:
        RETVAL

SV *
BS_Bit_inter(SV *s, SV *t)
    CODE:
        Bit_T ss = SV_TO_BIT_T(Bit_T, s, UNDEF_ERROR);
        Bit_T tt = SV_TO_BIT_T(Bit_T, t, UNDEF_ERROR);
        Bit_T rv = Bit_inter(ss, tt);
        RETVAL = newSVuv(PTR2UV(rv));
    OUTPUT:
        RETVAL

SV *
BS_Bit_minus(SV *s, SV *t)
    CODE:
        Bit_T ss = SV_TO_BIT_T(Bit_T, s, UNDEF_ERROR);
        Bit_T tt = SV_TO_BIT_T(Bit_T, t, UNDEF_ERROR);
        Bit_T rv = Bit_minus(ss, tt);
        RETVAL = newSVuv(PTR2UV(rv));
    OUTPUT:
        RETVAL

SV *
BS_Bit_union(SV *s, SV *t)
    CODE:
        Bit_T ss = SV_TO_BIT_T(Bit_T, s, UNDEF_ERROR);
        Bit_T tt = SV_TO_BIT_T(Bit_T, t, UNDEF_ERROR);
        Bit_T rv = Bit_union(ss, tt);
        RETVAL = newSVuv(PTR2UV(rv));
    OUTPUT:
        RETVAL

IV
BS_Bit_diff_count(SV *s, SV *t)
    CODE:
        Bit_T ss = SV_TO_BIT_T(Bit_T, s, UNDEF_ERROR);
        Bit_T tt = SV_TO_BIT_T(Bit_T, t, UNDEF_ERROR);
        RETVAL = (IV)Bit_diff_count(ss, tt);
    OUTPUT:
        RETVAL

IV
BS_Bit_inter_count(SV *s, SV *t)
    CODE:
        Bit_T ss = SV_TO_BIT_T(Bit_T, s, UNDEF_ERROR);
        Bit_T tt = SV_TO_BIT_T(Bit_T, t, UNDEF_ERROR);
        RETVAL = (IV)Bit_inter_count(ss, tt);
    OUTPUT:
        RETVAL

IV
BS_Bit_minus_count(SV *s, SV *t)
    CODE:
        Bit_T ss = SV_TO_BIT_T(Bit_T, s, UNDEF_ERROR);
        Bit_T tt = SV_TO_BIT_T(Bit_T, t, UNDEF_ERROR);
        RETVAL = (IV)Bit_minus_count(ss, tt);
    OUTPUT:
        RETVAL

IV
BS_Bit_union_count(SV *s, SV *t)
    CODE:
        Bit_T ss = SV_TO_BIT_T(Bit_T, s, UNDEF_ERROR);
        Bit_T tt = SV_TO_BIT_T(Bit_T, t, UNDEF_ERROR);
        RETVAL = (IV)Bit_union_count(ss, tt);
    OUTPUT:
        RETVAL
