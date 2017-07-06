#include <stdint.h>
#define PERL_NO_GET_CONTEXT
#include "perl.h"

#ifndef CC_DEFINE_H
#define CC_DEFINE_H

#define IS_BIG_ENDIAN (*(uint16_t *)"\0\xff" < 0x100)
#if INTPTR_MAX == INT64_MAX
#define CAN_64BIT
#elif INTPTR_MAX == INT32_MAX
#else
#error Unknown pointer size. Please make sure your compiler understands C99 and has a stdint.h
#endif

#define CC_METADATA_FLAG_GLOBAL_TABLES_SPEC 1
#define CC_METADATA_FLAG_HAS_MORE_PAGES     2
#define CC_METADATA_FLAG_NO_METADATA        4

#define CC_TYPE_CUSTOM    0x0000
#define CC_TYPE_ASCII     0x0001
#define CC_TYPE_BIGINT    0x0002
#define CC_TYPE_BLOB      0x0003
#define CC_TYPE_BOOLEAN   0x0004
#define CC_TYPE_COUNTER   0x0005
#define CC_TYPE_DECIMAL   0x0006
#define CC_TYPE_DOUBLE    0x0007
#define CC_TYPE_FLOAT     0x0008
#define CC_TYPE_INT       0x0009
#define CC_TYPE_TEXT      0x000A
#define CC_TYPE_TIMESTAMP 0x000B
#define CC_TYPE_UUID      0x000C
#define CC_TYPE_VARCHAR   0x000D
#define CC_TYPE_VARINT    0x000E
#define CC_TYPE_TIMEUUID  0x000F
#define CC_TYPE_INET      0x0010
#define CC_TYPE_DATE      0x0011
#define CC_TYPE_TIME      0x0012
#define CC_TYPE_SMALLINT  0x0013
#define CC_TYPE_TINYINT   0x0014
#define CC_TYPE_LIST      0x0020
#define CC_TYPE_MAP       0x0021
#define CC_TYPE_SET       0x0022
#define CC_TYPE_UDT       0x0030
#define CC_TYPE_TUPLE     0x0031

struct cc_type;
struct cc_udt;
struct cc_udt_field;
struct cc_column;
struct cc_tuple;

struct cc_type {
    uint16_t type_id;
    union {
        struct cc_type *inner_type;
        char *custom_name;
        struct cc_udt *udt;
        struct cc_tuple *tuple;
    };
};

struct cc_udt_field {
    SV *name;
    U32 name_hash;
    struct cc_type type;
};

struct cc_udt {
    SV *keyspace;
    SV *udt_name;
    int field_count;
    struct cc_udt_field *fields;
};

struct cc_tuple {
    int field_count;
    struct cc_type *fields;
};

struct cc_column {
    SV *keyspace;
    SV *table;
    SV *name;
    struct cc_type type;
    U32 name_hash;
};

#endif
