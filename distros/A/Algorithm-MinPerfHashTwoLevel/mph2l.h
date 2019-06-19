#ifndef MPH_SEED_BYTES
#define MPH_SEED_BYTES (sizeof(U64) * 2)
#endif
#ifndef MPH_STATE_BYTES
#define MPH_STATE_BYTES (sizeof(U64) * 4)
#endif

#define U64 U64TYPE

#ifndef MPH_MAP_POPULATE
#ifdef MAP_POPULATE
#define MPH_MAP_POPULATE MAP_POPULATE
#else
#define MPH_MAP_POPULATE MAP_PREFAULT_READ
#endif
#endif

#define MPH_KEYSV_IDX               0
#define MPH_KEYSV_H1_KEYS           1
#define MPH_KEYSV_XOR_VAL           2
#define MPH_KEYSV_H0                3
#define MPH_KEYSV_KEY               4
#define MPH_KEYSV_KEY_NORMALIZED    5
#define MPH_KEYSV_KEY_IS_UTF8       6
#define MPH_KEYSV_VAL               7
#define MPH_KEYSV_VAL_NORMALIZED    8
#define MPH_KEYSV_VAL_IS_UTF8       9

#define MPH_KEYSV_VARIANT           10
#define MPH_KEYSV_COMPUTE_FLAGS     11
#define MPH_KEYSV_STATE             12
#define MPH_KEYSV_SOURCE_HASH       13
#define MPH_KEYSV_BUF_LENGTH        14
#define MPH_KEYSV_BUCKETS           15
#define MPH_KEYSV_MOUNT             16

#define COUNT_MPH_KEYSV 17

#define MPH_INIT_KEYSV(idx, str) STMT_START {                           \
    MY_CXT.keysv[idx].sv = newSVpvn((str ""), (sizeof(str) - 1));       \
    PERL_HASH(MY_CXT.keysv[idx].hash, (str ""), (sizeof(str) - 1));     \
} STMT_END

#define MPH_INIT_ALL_KEYSV() STMT_START {\
    MY_CXT_INIT;                                                \
    MPH_INIT_KEYSV(MPH_KEYSV_IDX,"idx");                        \
    MPH_INIT_KEYSV(MPH_KEYSV_H1_KEYS,"h1_keys");                \
    MPH_INIT_KEYSV(MPH_KEYSV_XOR_VAL,"xor_val");                \
    MPH_INIT_KEYSV(MPH_KEYSV_H0,"h0");                          \
    MPH_INIT_KEYSV(MPH_KEYSV_KEY,"key");                        \
    MPH_INIT_KEYSV(MPH_KEYSV_KEY_NORMALIZED,"key_normalized");  \
    MPH_INIT_KEYSV(MPH_KEYSV_KEY_IS_UTF8,"key_is_utf8");        \
    MPH_INIT_KEYSV(MPH_KEYSV_VAL,"val");                        \
    MPH_INIT_KEYSV(MPH_KEYSV_VAL_NORMALIZED,"val_normalized");  \
    MPH_INIT_KEYSV(MPH_KEYSV_VAL_IS_UTF8,"val_is_utf8");        \
                                                                \
    MPH_INIT_KEYSV(MPH_KEYSV_VARIANT,"variant");                \
    MPH_INIT_KEYSV(MPH_KEYSV_COMPUTE_FLAGS,"compute_flags");    \
    MPH_INIT_KEYSV(MPH_KEYSV_STATE,"state");                    \
    MPH_INIT_KEYSV(MPH_KEYSV_SOURCE_HASH,"source_hash");        \
    MPH_INIT_KEYSV(MPH_KEYSV_BUF_LENGTH,"buf_length");          \
    MPH_INIT_KEYSV(MPH_KEYSV_BUCKETS,"buckets");                \
    MPH_INIT_KEYSV(MPH_KEYSV_MOUNT,"mount");                    \
} STMT_END

#define MPH_F_FILTER_UNDEF          (1<<0)
#define MPH_F_DETERMINISTIC         (1<<1)
#define MPH_F_NO_DEDUPE             (1<<2)
#define MPH_F_VALIDATE              (1<<3)

#define MPH_MOUNT_ERROR_OPEN_FAILED     (-1)
#define MPH_MOUNT_ERROR_FSTAT_FAILED    (-2)
#define MPH_MOUNT_ERROR_TOO_SMALL       (-3)
#define MPH_MOUNT_ERROR_BAD_SIZE        (-4)
#define MPH_MOUNT_ERROR_MAP_FAILED      (-5)
#define MPH_MOUNT_ERROR_BAD_MAGIC       (-6)
#define MPH_MOUNT_ERROR_BAD_VERSION     (-7)
#define MPH_MOUNT_ERROR_BAD_OFFSETS     (-8)
#define MPH_MOUNT_ERROR_CORRUPT_TABLE   (-9)
#define MPH_MOUNT_ERROR_CORRUPT_STR_BUF (-10)
#define MPH_MOUNT_ERROR_CORRUPT_FILE    (-11)

#define MAGIC_DECIMAL 1278363728 /* PH2L */
#define MAGIC_BIG_ENDIAN_DECIMAL 1346908748

#define MPH_VALS_ARE_SAME_UTF8NESS_FLAG_BIT   1           /* 0000 0001 */
#define MPH_VALS_ARE_SAME_UTF8NESS_MASK       3           /* 0000 0011 */
#define MPH_VALS_ARE_SAME_UTF8NESS_SHIFT      1           /*  000 0001 */
#define MPH_KEYS_ARE_SAME_UTF8NESS_FLAG_BIT   4           /* 0000 0100 */
#define MPH_KEYS_ARE_SAME_UTF8NESS_MASK       (7 << 2)    /* 0001 1100 */
#define MPH_KEYS_ARE_SAME_UTF8NESS_SHIFT      3           /*    0 0011 */

/*
#ifndef av_top_index
#define av_top_index(x) av_len(x)
#endif
*/

#ifndef MPH_STATIC_INLINE
#ifdef PERL_STATIC_INLINE
#define MPH_STATIC_INLINE PERL_STATIC_INLINE
#else
#define MPH_STATIC_INLINE static inline
#endif
#endif

#define hv_fetch_ent_with_keysv(hv,keysv_idx,lval)                      \
    hv_fetch_ent(hv,MY_CXT.keysv[keysv_idx].sv,lval,MY_CXT.keysv[keysv_idx].hash);

#define hv_store_ent_with_keysv(hv,keysv_idx,val_sv)                    \
    hv_store_ent(hv,MY_CXT.keysv[keysv_idx].sv,val_sv,MY_CXT.keysv[keysv_idx].hash);

#define hv_copy_with_keysv(hv1,hv2,keysv_idx) STMT_START {              \
    HE *got_he= hv_fetch_ent_with_keysv(hv1,keysv_idx,0);               \
    if (got_he) {                                                       \
        SV *got_sv= HeVAL(got_he);                                      \
        hv_store_ent_with_keysv(hv2,keysv_idx,got_sv);                  \
        SvREFCNT_inc(got_sv);                                           \
    }                                                                   \
} STMT_END

#define hv_setuv_with_keysv(hv,keysv_idx,uv)                            \
STMT_START {                                                            \
    HE *got_he= hv_fetch_ent_with_keysv(hv,keysv_idx,1);                \
    if (got_he) sv_setuv(HeVAL(got_he),uv);                             \
} STMT_END

#define HASH2INDEX(x,h2,xor_val,bucket_count) STMT_START {      \
        x= h2 ^ xor_val;                                                \
        /* see: https://stackoverflow.com/a/12996028                    \
         * but we could use any similar integer hash function. */       \
        x = ((x >> 16) ^ x) * 0x45d9f3b;                                \
        x = ((x >> 16) ^ x) * 0x45d9f3b;                                \
        x = ((x >> 16) ^ x);                                            \
        x %= bucket_count;                                              \
} STMT_END

#ifndef CHAR_BITS
#define CHAR_BITS 8
#endif

#define _BITSDECL(idx,bits) \
    const U64 bitpos= idx * bits;                           \
    const U64 bytepos= bitpos / CHAR_BITS;                  \
    const U8 shift= bitpos % CHAR_BITS;                     \
    const U8 bitmask= ( 1 << bits ) - 1

#define GETBITS(into,flags,idx,bits) STMT_START {           \
    _BITSDECL(idx,bits);                                    \
    into= ((flags)[bytepos] >> shift) & bitmask;            \
} STMT_END

#define SETBITS(value,flags,idx,bits) STMT_START {          \
    _BITSDECL(idx,bits);                                    \
    const U8 v= value;                                      \
    (flags)[bytepos] &= ~(bitmask << shift);                \
    (flags)[bytepos] |= ((v & bitmask) << shift);           \
} STMT_END

typedef struct {
    SV *sv;
    U32 hash;
} sv_with_hash;

typedef struct {
    sv_with_hash keysv[COUNT_MPH_KEYSV];
} my_cxt_t;

struct mph_header {
    U32 magic_num;
    U32 variant;
    U32 num_buckets;
    U32 state_ofs;

    U32 table_ofs;
    U32 key_flags_ofs;
    U32 val_flags_ofs;
    U32 str_buf_ofs;

    union {
        U64 table_checksum;
        U64 general_flags;
    };
    union {
        U64 str_buf_checksum;
    };
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
};

