#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "stadtx_hash.h"
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <assert.h>

struct mph_header {
    U32 magic_num;
    U32 variant;
    U32 num_buckets;
    U32 state_ofs;

    U32 table_ofs;
    U32 key_flags_ofs;
    U32 val_flags_ofs;
    U32 str_buf_ofs;

    U64 table_checksum;
    U64 str_buf_checksum;
};

struct mph_bucket {
    union {
        U32 xor_val;
        I32 index;
    };
    U32 key_ofs;
    U32 val_ofs;
    U16 key_len;
    U16 val_len;
};

struct mph_obj {
    size_t bytes;
    struct mph_header *header;
    int fd;
};

#define sv_set_from_bucket(sv,strs,ofs,len,idx,flags,bits) \
STMT_START {                                            \
    U8 *ptr;                                            \
    U8 is_utf8;                                         \
    if (ofs) {                                          \
        ptr= (strs) + (ofs);                            \
        is_utf8= (*((flags)+(((idx)*(bits))>>3))>>(((idx)*(bits))&7))&((1<<bits)-1); \
    } else {                                            \
        ptr= 0;                                         \
        is_utf8= 0;                                     \
    }                                                   \
    sv_setpvn_mg((sv),ptr,len);                         \
    if (is_utf8 > 1) {                                  \
        sv_utf8_upgrade(sv);                            \
    }                                                   \
    else                                                \
    if (is_utf8) {                                      \
        SvUTF8_on(sv);                                  \
    }                                                   \
    else                                                \
    if (ptr) {                                          \
        SvUTF8_off(sv);                                 \
    }                                                   \
} STMT_END

int
lookup_bucket(struct mph_header *mph, U32 index, SV *key_sv, SV *val_sv)
{
    struct mph_bucket *bucket;
    U8 *strs;
    if (index >= mph->num_buckets) {
        return 0;
    }
    bucket= (struct mph_bucket *)((char *)mph + mph->table_ofs) + index;
    strs= (U8 *)mph + mph->str_buf_ofs;
    if (key_sv) {
        sv_set_from_bucket(key_sv,strs,bucket->key_ofs,bucket->key_len,index,((U8*)mph)+mph->key_flags_ofs,2);
    }
    if (val_sv) {
        sv_set_from_bucket(val_sv,strs,bucket->val_ofs,bucket->val_len,index,((U8*)mph)+mph->val_flags_ofs,1);
    }
    return 1;
}

int
lookup_key(struct mph_header *mph, SV *key_sv, SV *val_sv)
{
    U8 *strs= (U8 *)mph + mph->str_buf_ofs;
    struct mph_bucket *buckets= (struct mph_bucket *) ((char *)mph + mph->table_ofs);
    struct mph_bucket *bucket;
    U8 *state= (char *)mph + mph->state_ofs;
    STRLEN key_len;
    U8 *key_pv;
    U64 h0;
    U32 h1;
    U32 index;

    if (SvUTF8(key_sv)) {
        SV *tmp= sv_2mortal(newSVsv(key_sv));
        sv_utf8_downgrade(tmp,1);
        key_sv= tmp;
    }
    key_pv= SvPV(key_sv,key_len);
    h0= stadtx_hash_with_state(state,key_pv,key_len);
    h1= h0 >> 32;
    index= h1 % mph->num_buckets;

    bucket= buckets + index;
    if (!bucket->xor_val) {
        return 0;
    } else {
        U32 h2= h0 & 0xFFFFFFFF;
        U8 *got_key_pv;
        STRLEN got_key_len;
        if ( mph->variant == 0 || bucket->index > 0 ) {
            index = (h2 ^ bucket->xor_val) % mph->num_buckets;
        } else { /* mph->variant == 1 */
            index = -bucket->index-1;
        }
        bucket= buckets + index;
        got_key_pv= strs + bucket->key_ofs;
        if (bucket->key_len == key_len && memEQ(key_pv,got_key_pv,key_len)) {
            if (val_sv) {
                sv_set_from_bucket(val_sv,strs,bucket->val_ofs,bucket->val_len,index,((U8*)mph)+mph->val_flags_ofs,1);
            }
            return 1;
        }
        return 0;
    }
}

void
mph_mmap(char *file, struct mph_obj *obj) {
    struct stat st;
    int fd = open(file, O_RDONLY, 0);
    void *ptr;
    if (fd < 0)
        croak("failed to open '%s' for read", file);
    fstat(fd,&st);
    ptr = mmap(NULL,st.st_size,PROT_READ,MAP_SHARED | MAP_POPULATE, fd, 0);
    if (ptr == MAP_FAILED) {
        croak("failed to create mapping to file '%s'", file);
    }
    obj->bytes= st.st_size;
    obj->header= (struct mph_header*)ptr;
    obj->fd= fd;
}

void 
mph_munmap(struct mph_obj *obj) {
    munmap(obj->header,obj->bytes);
    close(obj->fd);
}


MODULE = Algorithm::MinPerfHashTwoLevel		PACKAGE = Algorithm::MinPerfHashTwoLevel		

UV
hash_with_state(str_sv,state_sv)
        SV* str_sv
        SV* state_sv
    PROTOTYPE: $$
    CODE:
{
    STRLEN str_len;
    STRLEN state_len;
    U8 *state_pv;
    U8 *str_pv= (U8 *)SvPV(str_sv,str_len);
    state_pv= (U8 *)SvPV(state_sv,state_len);
    if (state_len != STADTX_STATE_BYTES) {
        croak("state vector must be at exactly %d bytes",STADTX_SEED_BYTES);
    }
    RETVAL= stadtx_hash_with_state(state_pv,str_pv,str_len);
}
    OUTPUT:
        RETVAL

SV *
seed_state(base_seed_sv)
        SV* base_seed_sv
    PROTOTYPE: $
    CODE:
{
    STRLEN seed_len;
    STRLEN state_len;
    U8 *seed_pv;
    U8 *state_pv;
    SV *seed_sv;
    if (!SvOK(base_seed_sv))
        croak("seed must be defined");
    if (SvROK(base_seed_sv))
        croak("seed should not be a reference");
    seed_sv= base_seed_sv;
    seed_pv= (U8 *)SvPV(seed_sv,seed_len);

    if (seed_len != STADTX_SEED_BYTES) {
        if (SvREADONLY(base_seed_sv)) {
            if (seed_len < STADTX_SEED_BYTES) {
                warn("seed passed into seed_state() is readonly and too short, argument has been right padded with %d nulls",
                    (int)(STADTX_SEED_BYTES - seed_len));
            }
            else if (seed_len > STADTX_SEED_BYTES) {
                warn("seed passed into seed_state() is readonly and too long, using only the first %d bytes",
                    (int)STADTX_SEED_BYTES);
            }
            seed_sv= sv_2mortal(newSVsv(base_seed_sv)); 
        }
        if (seed_len < STADTX_SEED_BYTES) {
            sv_grow(seed_sv,STADTX_SEED_BYTES+1);
            while (seed_len < STADTX_SEED_BYTES) {
                seed_pv[seed_len] = 0;
                seed_len++;
            }
        }
        SvCUR_set(seed_sv,STADTX_SEED_BYTES);
        seed_pv= (U8 *)SvPV(seed_sv,seed_len);
    } else {
        seed_sv= base_seed_sv;
    }

    RETVAL= newSV(STADTX_STATE_BYTES+1);
    SvCUR_set(RETVAL,STADTX_STATE_BYTES);
    SvPOK_on(RETVAL);
    state_pv= (U8 *)SvPV(RETVAL,state_len);
    stadtx_seed_state(seed_pv,state_pv);
}
    OUTPUT:
        RETVAL

U32
calc_xor_val(max_xor_val,h2_sv,idx_sv,used_sv,used_pos)
    U32 max_xor_val
    SV *h2_sv
    SV *idx_sv
    SV *used_sv
    SV *used_pos
    PROTOTYPE: $$$$$
    CODE:
{
    U32 xor_val= 0;
    STRLEN h2_strlen;
    STRLEN bucket_count;
    char *used= SvPV(used_sv,bucket_count);
    U32 *h2_start= (U32 *)SvPV(h2_sv,h2_strlen);
    STRLEN h2_count= h2_strlen / sizeof(U32);
    U32 *h2_end= h2_start + h2_count;
    U32 *idx_start;
    
    sv_grow(idx_sv,h2_strlen);
    SvCUR_set(idx_sv,h2_strlen);
    SvPOK_on(idx_sv);
    idx_start= (U32 *)SvPVX(idx_sv);

    if (h2_count == 1 && SvOK(used_pos)) {
        I32 pos= SvIV(used_pos);
        while (pos < bucket_count && used[pos]) {
            pos++;
        }
        SvIV_set(used_pos,pos);
        if (pos == bucket_count) {
            RETVAL= 0;
        } else {
            *idx_start= pos;
            pos = -pos-1;
            RETVAL= (U32)pos;
        }
    } else {
        next_xor_val:
        while (1) {
            U32 *h2_ptr= h2_start;
            U32 *idx_ptr= idx_start;
            if (xor_val == max_xor_val) {
                RETVAL= 0;
                break;
            } else {
                xor_val++;
            }
            while (h2_ptr < h2_end) {
                U32 i= (*h2_ptr ^ xor_val) % bucket_count;
                U32 *check_idx;
                if (used[i])
                    goto next_xor_val;
                for (check_idx= idx_start; check_idx < idx_ptr; check_idx++) {
                    if (*check_idx == i)
                        goto next_xor_val;
                }
                *idx_ptr= i;
                h2_ptr++;
                idx_ptr++;
            }
            RETVAL= xor_val;
            break;
        }
    }
}
    OUTPUT:
        RETVAL

MODULE = Algorithm::MinPerfHashTwoLevel		PACKAGE = Tie::Hash::MinPerfHashTwoLevel::OnDisk

SV*
mount_file(file_sv)
        SV* file_sv
    PROTOTYPE: $
    CODE:
{
    struct mph_obj obj;
    STRLEN file_len;
    char *file_pv= SvPV(file_sv,file_len);
    mph_mmap(file_pv,&obj);
    RETVAL= newSVpvn((char *)&obj,sizeof(struct mph_obj));
    SvPOK_on(RETVAL);
    SvREADONLY_on(RETVAL);
}
    OUTPUT:
        RETVAL

void
unmount_file(mount_sv)
        SV* mount_sv
    PROTOTYPE: $
    CODE:
{
    struct mph_obj *obj= (struct mph_obj *)SvPV_nolen(mount_sv);
    mph_munmap(obj);
    SvOK_off(mount_sv);
}


UV
num_buckets(mount_sv)
        SV* mount_sv
    PROTOTYPE: $
    CODE:
{
    struct mph_obj *obj= (struct mph_obj *)SvPV_nolen(mount_sv);
    RETVAL= obj->header->num_buckets;
}
    OUTPUT:
        RETVAL

int
fetch_by_index(mount_sv,index,...)
        SV* mount_sv
        U32 index
    PROTOTYPE: $$;$$
    CODE:
{
    struct mph_obj *obj= (struct mph_obj *)SvPV_nolen(mount_sv);
    SV* key_sv= items > 2 ? ST(2) : NULL;
    SV* val_sv= items > 3 ? ST(3) : NULL;
    if (items > 4)
       croak_xs_usage(cv,  "mount_sv, index, key_sv, val_sv");
    RETVAL= lookup_bucket(obj->header,index,key_sv,val_sv);    
}
    OUTPUT:
        RETVAL

int
fetch_by_key(mount_sv,key_sv,...)
        SV* mount_sv
        SV* key_sv
    PROTOTYPE: $$;$
    CODE:
{
    SV* val_sv= items > 2 ? ST(2) : NULL;
    struct mph_obj *obj= (struct mph_obj *)SvPV_nolen(mount_sv);
    if (items > 3)
       croak_xs_usage(cv,  "mount_sv, index, key_sv");
    RETVAL= lookup_key(obj->header,key_sv,val_sv);
}
    OUTPUT:
        RETVAL
