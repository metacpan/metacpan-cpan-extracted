#include "macros_defs.h"

MODULE = Bit::Set::DB		PACKAGE = Bit::Set::DB     PREFIX=BSDB_

PROTOTYPES: DISABLE

INCLUDE: DB_procedural.xs.inc

MODULE = Bit::Set::DB		PACKAGE = Bit::Set::DB     PREFIX=BSDBOO_

PROTOTYPES: DISABLE


Bit_DB_T_obj
BSDBOO_new(char *class, IV length, IV num_of_bitsets)
    CODE:
        Bit_DB_T obj = BitDB_new((int)length,(int)num_of_bitsets);
        RETVAL = obj;
    OUTPUT:
        RETVAL

void 
BSDBOO_DESTROY(Bit_DB_T_obj obj)
    CODE:
        BitDB_free(&obj);

Bit_DB_T_obj
BSDBOO_load(char *class, IV length, IV num_of_bitsets, char * buffer)
    CODE:
        Bit_DB_T db = BitDB_load((int)length, (int)num_of_bitsets, buffer);
        RETVAL = db;
    OUTPUT:
        RETVAL

# Functions that obtain the properties of the Bit_DB_T
IV 
BSDBOO_nelem(Bit_DB_T_obj db)
    CODE:
        RETVAL      = (IV)BitDB_nelem(db);
    OUTPUT:
        RETVAL

IV
BSDBOO_length(Bit_DB_T_obj db)
    CODE:
        RETVAL = (IV)BitDB_length(db);
    OUTPUT:
        RETVAL

IV
BSDBOO_count_at(Bit_DB_T_obj db, IV index)
    CODE:
        RETVAL = (IV)BitDB_count_at(db,(int)index);
    OUTPUT:
        RETVAL

SV* 
BSDBOO_count(Bit_DB_T_obj db,...)
    CODE:
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

SV*
BSDBOO_get_from(Bit_DB_T_obj db, IV index)
    CODE:
        Bit_T bitset = BitDB_get_from(db, (int)index);
        RETURN_BLESSED_REFERENCE("Bit::Set", bitset);

void
BSDBOO_put_at(Bit_DB_T_obj db, IV index, Bit_T_obj bitset)
    CODE:
        BitDB_put_at(db, (int)index, bitset);

void
BSDBOO_clear_at(Bit_DB_T_obj db, IV index)
    CODE:
        BitDB_clear_at(db, (int)index);

void 
BSDBOO_clear(Bit_DB_T_obj db)
    CODE:
        BitDB_clear(db);

void
BSDBOO_extract_from(Bit_DB_T_obj db, IV index, SV*  buffer)
    CODE:
        void *ptr = SV_TO_VOID(buffer);
        BitDB_extract_from(db, (int)index, ptr);


void
BSDBOO_replace_at(Bit_DB_T_obj db, IV index, SV*  buffer)
    CODE:
        void *ptr = SV_TO_VOID(buffer);
        BitDB_replace_at(db, (int)index, ptr);

# Setops count functions (CPU)

SV* 
BSDBOO_union_count_cpu(db1, db2, opts,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
    CODE:
        SETOPS(union,cpu)
    OUTPUT:
        RETVAL

SV* 
BSDBOO_inter_count_cpu(db1, db2, opts,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
    CODE:
        SETOPS(inter,cpu)
    OUTPUT:
        RETVAL

SV* 
BSDBOO_minus_count_cpu(db1, db2, opts,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
    CODE:
        SETOPS(minus,cpu)
    OUTPUT:
        RETVAL

SV* 
BSDBOO_diff_count_cpu(db1, db2, opts,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
    CODE:
        SETOPS(diff,cpu)
    OUTPUT:
        RETVAL

# Setops count functions (GPU)
SV* 
BSDBOO_union_count_gpu(db1, db2, opts,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
    CODE:
        SETOPS(union,gpu)
    OUTPUT:
        RETVAL

SV* 
BSDBOO_inter_count_gpu(db1, db2, opts,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
    CODE:
        SETOPS(inter,gpu)
    OUTPUT:
        RETVAL

SV* 
BSDBOO_minus_count_gpu(db1, db2, opts,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
    CODE:
        SETOPS(minus,gpu)
    OUTPUT:
        RETVAL

SV* 
BSDBOO_diff_count_gpu(db1, db2, opts,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
    CODE:
        SETOPS(diff,gpu)
    OUTPUT:
        RETVAL

# Setops count functions with store (CPU)

void
BSDBOO_union_count_store_cpu(db1, db2, opts, store,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        SETOPS_STORE(union,store, cpu)


void 
BSDBOO_inter_count_store_cpu(db1, db_or_dbref2, opts,store,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        SETOPS_STORE(inter,store,cpu)


void
BSDBOO_minus_count_store_cpu(db1, db2,  opts,store,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        SETOPS_STORE(minus,store,cpu)


void 
BSDBOO_diff_count_store_cpu(db1, db2,  opts,store,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        SETOPS_STORE(diff,store,cpu)


# Setops count functions with store (gpu)

void 
BSDBOO_union_count_store_gpu(db1, db2,  opts,store,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        SETOPS_STORE(union,store, gpu)


void
BSDBOO_inter_count_store_gpu(db1, db2,   opts,store,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        SETOPS_STORE(inter,store,gpu)


void
BSDBOO_minus_count_store_gpu(db1, db2,  opts,store,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        SETOPS_STORE(minus,store,gpu)


void
BSDBOO_diff_count_store_gpu(db1, db2,  opts,store,...)
Bit_DB_T_obj db1
Bit_DB_T_obj db2
SETOP_COUNT_OPTS_t opts
SV* store
    CODE:
        SETOPS_STORE(diff,store,gpu)
