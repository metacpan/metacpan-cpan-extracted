
MODULE = Bit::Set::DB		PACKAGE = Bit::Set::DB     PREFIX=BSDB_

PROTOTYPES: DISABLE




# Functions that create, free, load from an external buffer


Bit_DB_T
BSDB_BitDB_new( IV length, IV num_of_bitsets)
    CODE:
        Bit_DB_T obj = BitDB_new((int)length,(int)num_of_bitsets);
        RETVAL = obj;
    OUTPUT:
        RETVAL

void 
BSDB_BitDB_free(SV* db_or_dbref)
    CODE:
        if (!SvROK(db_or_dbref)) {
            croak("BitDB_free expects a scalar reference");
        }
        SV *inner = SvRV(db_or_dbref);
        Bit_DB_T db = INT2PTR(Bit_DB_T, SvIV(inner));
        BitDB_free(&db);

Bit_DB_T
BSDB_BitDB_load(IV length, IV num_of_bitsets, SV* buffer)
    CODE:
        void *ptr = SV_TO_VOID(buffer);
        Bit_DB_T db = BitDB_load((int)length, (int)num_of_bitsets, ptr);
        RETVAL = db;
    OUTPUT:
        RETVAL

# Functions that obtain the properties of the Bit_DB_T
IV 
BSDB_BitDB_nelem(SV* db_or_dbref)
    CODE:
        Bit_DB_T db = SV_TO_TYPE(Bit_DB_T, db_or_dbref, UNDEF_DB_ERROR);
        RETVAL      = (IV)BitDB_nelem(db);
    OUTPUT:
        RETVAL

IV
BSDB_BitDB_length(SV* db_or_dbref)
    CODE:
        Bit_DB_T db =  SV_TO_TYPE(Bit_DB_T,db_or_dbref,UNDEF_DB_ERROR);
        RETVAL = (IV)BitDB_length(db);
    OUTPUT:
        RETVAL

IV
BSDB_BitDB_count_at(SV* db_or_dbref, IV index)
    CODE:
        Bit_DB_T db = SV_TO_TYPE(Bit_DB_T,db_or_dbref,UNDEF_DB_ERROR);
        RETVAL = (IV)BitDB_count_at(db,(int)index);
    OUTPUT:
        RETVAL

SV* 
BSDB_BitDB_count(SV* db_or_dbref,...)
    CODE:
        Bit_DB_T db = SV_TO_TYPE(Bit_DB_T,db_or_dbref,UNDEF_DB_ERROR);
        size_t nelem;
        int *counts;
        int mode;
        if(items ==1){
            mode = RETURN_PERL_ARRAY;
        } else {
            if(!SvOK(ST(1))) {
                mode = RETURN_PERL_ARRAY;
            } else
                mode = (int)SvIV(ST(1));
        }   
        if (mode == RETURN_RAW_BUFFER) {
            counts = BitDB_count(db);
            RETVAL = newSVuv(PTR2UV(counts));
        } else if (mode == RETURN_PERL_ARRAY) {
            counts = BitDB_count(db);
            nelem = (size_t)BitDB_nelem(db);
            AV *av = newAV_alloc_x(nelem);
            for (size_t i = 0; i < nelem; ++i) {
                av_store(av, i, newSViv(counts[i]));
            }
            RETVAL = newRV_inc((SV*)av);
            free(counts);
        } else {
            croak("Invalid mode for BitDB_count");
        }
    OUTPUT:
        RETVAL
# Functions that manipulate and obtain the contents of a packed
# container of bitsets (Bit_DB).

Bit_T
BSDB_BitDB_get_from(SV* db_or_dbref, IV index)
    CODE:
        Bit_DB_T db = SV_TO_TYPE(Bit_DB_T, db_or_dbref, UNDEF_DB_ERROR);
        Bit_T bitset = BitDB_get_from(db, (int)index);
        RETVAL = bitset;
    OUTPUT:
        RETVAL

void
BSDB_BitDB_put_at(SV* db_or_dbref, IV index, SV *set)
    CODE:
        Bit_DB_T db = SV_TO_TYPE(Bit_DB_T, db_or_dbref, UNDEF_DB_ERROR);
        Bit_T bitset = SV_TO_TYPE(Bit_T, set, UNDEF_ERROR);
        BitDB_put_at(db, (int)index, bitset);

void
BSDB_BitDB_clear_at(SV* db_or_dbref, IV index)
    CODE:
        Bit_DB_T db = SV_TO_TYPE(Bit_DB_T, db_or_dbref, UNDEF_DB_ERROR);
        BitDB_clear_at(db, (int)index);

void 
BSDB_BitDB_clear(SV* db_or_dbref)
    CODE:
        Bit_DB_T db = SV_TO_TYPE(Bit_DB_T, db_or_dbref, UNDEF_DB_ERROR);
        BitDB_clear(db);

void
BSDB_BitDB_extract_from(SV* db_or_dbref, IV index, SV* buffer)
    CODE:
        Bit_DB_T db = SV_TO_TYPE(Bit_DB_T, db_or_dbref, UNDEF_DB_ERROR);
        void *ptr = SV_TO_VOID(buffer);
        BitDB_extract_from(db, (int)index, ptr);


void
BSDB_BitDB_replace_at(SV* db_or_dbref, IV index, SV* buffer)
    CODE:
        Bit_DB_T db = SV_TO_TYPE(Bit_DB_T, db_or_dbref, UNDEF_DB_ERROR);
        void *ptr = SV_TO_VOID(buffer);
        BitDB_replace_at(db, (int)index, ptr);

# Setops count functions (CPU)

SV* 
BSDB_BitDB_union_count_cpu(db_or_dbref1, db_or_dbref2, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS(union,cpu)
    OUTPUT:
        RETVAL

SV* 
BSDB_BitDB_inter_count_cpu(db_or_dbref1, db_or_dbref2, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS(inter,cpu)
    OUTPUT:
        RETVAL

SV* 
BSDB_BitDB_minus_count_cpu(db_or_dbref1, db_or_dbref2, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS(minus,cpu)
    OUTPUT:
        RETVAL

SV* 
BSDB_BitDB_diff_count_cpu(db_or_dbref1, db_or_dbref2, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS(diff,cpu)
    OUTPUT:
        RETVAL

# Setops count functions (GPU)
SV* 
BSDB_BitDB_union_count_gpu(db_or_dbref1, db_or_dbref2, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS(union,gpu)
    OUTPUT:
        RETVAL

SV* 
BSDB_BitDB_inter_count_gpu(db_or_dbref1, db_or_dbref2, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS(inter,gpu)
    OUTPUT:
        RETVAL

SV* 
BSDB_BitDB_minus_count_gpu(db_or_dbref1, db_or_dbref2, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS(minus,gpu)
    OUTPUT:
        RETVAL

SV* 
BSDB_BitDB_diff_count_gpu(db_or_dbref1, db_or_dbref2, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS(diff,gpu)
    OUTPUT:
        RETVAL

# Setops count functions with store (CPU)

void
BSDB_BitDB_union_count_store_cpu(db_or_dbref1, db_or_dbref2, store, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS_STORE(union,store, cpu)


void 
BSDB_BitDB_inter_count_store_cpu(db_or_dbref1, db_or_dbref2,  store, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS_STORE(inter,store,cpu)


void
BSDB_BitDB_minus_count_store_cpu(db_or_dbref1, db_or_dbref2, store, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS_STORE(minus,store,cpu)


void 
BSDB_BitDB_diff_count_store_cpu(db_or_dbref1, db_or_dbref2,  store,opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS_STORE(diff,store,cpu)


# Setops count functions with store (gpu)

void 
BSDB_BitDB_union_count_store_gpu(db_or_dbref1, db_or_dbref2, store, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS_STORE(union,store, gpu)


void
BSDB_BitDB_inter_count_store_gpu(db_or_dbref1, db_or_dbref2,  store, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS_STORE(inter,store,gpu)


void
BSDB_BitDB_minus_count_store_gpu(db_or_dbref1, db_or_dbref2, store, opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS_STORE(minus,store,gpu)


void
BSDB_BitDB_diff_count_store_gpu(db_or_dbref1, db_or_dbref2,  store,opts,...)
SV* db_or_dbref1
SV* db_or_dbref2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        Bit_DB_T db1 = SV_TO_TYPE(Bit_DB_T, db_or_dbref1, UNDEF_DB_ERROR);           
        Bit_DB_T db2 = SV_TO_TYPE(Bit_DB_T, db_or_dbref2, UNDEF_DB_ERROR);           
        SETOPS_STORE(diff,store,gpu)

