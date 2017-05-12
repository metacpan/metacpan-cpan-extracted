/*
 * chocolateboy 2009-02-25
 *
 * This is a customised version of the pointer table implementation in sv.c
 */

#include "ppport.h"

#if PTRSIZE == 8
    /*
     * This is one of Thomas Wang's hash functions for 64-bit integers from:
     * http://www.concentric.net/~Ttwang/tech/inthash.htm
     */
    U32 hash(PTRV u) {
        u = (~u) + (u << 18);
        u = u ^ (u >> 31);
        u = u * 21;
        u = u ^ (u >> 11);
        u = u + (u << 6);
        u = u ^ (u >> 22);
        return (U32)u;
    }
#else
    /*
     * This is one of Bob Jenkins' hash functions for 32-bit integers
     * from: http://burtleburtle.net/bob/hash/integer.html
     */
    U32 hash(PTRV u) {
        u = (u + 0x7ed55d16) + (u << 12);
        u = (u ^ 0xc761c23c) ^ (u >> 19);
        u = (u + 0x165667b1) + (u << 5);
        u = (u + 0xd3a2646c) ^ (u << 9);
        u = (u + 0xfd7046c5) + (u << 3);
        u = (u ^ 0xb55a4f09) ^ (u >> 16);
        return u;
    }
#endif

#define OPTABLE_HASH(op) hash(PTR2nat(op))

typedef struct OPTableEntry {
    struct OPTableEntry *next;
    const OP *key;
    OPAnnotation *value;
} OPTableEntry;

typedef struct OPAnnotationGroupImpl {
    struct OPTableEntry **array;
    UV size;
    UV items;
    NV threshold;
} OPTable;

typedef void (*OPTableEntryValueDtor)(pTHX_ OPAnnotation *);

STATIC OPAnnotation *OPTable_delete(OPTable *table, OP *op);
STATIC OPAnnotation *OPTable_fetch(OPTable *table, const OP *key);
STATIC OPAnnotation * OPTable_store(OPTable *table, const OP *key, OPAnnotation *value);
STATIC OPTableEntry *OPTable_find(OPTable *table, const OP *key);
STATIC OPTable *OPTable_new(UV size, NV threshold);
STATIC void OPTable_clear(pTHX_ OPTable *table, OPTableEntryValueDtor dtor);
STATIC void OPTable_free(OPTable *table);
STATIC void OPTable_grow(OPTable *table);

STATIC OPTable * OPTable_new(UV size, NV threshold) {
    OPTable *table;

    if ((size < 2) || (size & (size - 1))) {
        croak(__PACKAGE__ ": invalid op table size: expected a power of 2 (>= 2), got %u", (unsigned)size);
    }

    if (!((threshold > 0) && (threshold < 1))) {
        croak(__PACKAGE__ ": invalid threshold: expected 0.0 < threshold < 1.0, got %f", threshold);
    }

    Newxz(table, 1, OPTable);

    table->size = size;
    table->threshold = threshold;
    table->items = 0;

    Newxz(table->array, size, OPTableEntry *);

    return table;
}

STATIC OPTableEntry * OPTable_find(OPTable *table, const OP *key) {
    OPTableEntry *entry;
    UV index = OPTABLE_HASH(key) & (table->size - 1);

    for (entry = table->array[index]; entry; entry = entry->next) {
        if (entry->key == key) {
            break;
        }
    }

    return entry;
}

STATIC OPAnnotation *OPTable_delete(OPTable *table, OP *op) {
    OPTableEntry *entry, *prev = NULL;
    OPAnnotation *annotation = NULL;
    UV index = OPTABLE_HASH(op) & (table->size - 1);

    for (entry = table->array[index]; entry; prev = entry, entry = entry->next) {
        if (entry->key == op) {

            if (prev) {
                prev->next = entry->next;
            } else {
                table->array[index] = entry->next;
            }

            --(table->items);
            annotation = entry->value;
            Safefree(entry);
            break;
        }
    }

    return annotation;
}

STATIC OPAnnotation * OPTable_fetch(OPTable *table, const OP *key) {
    OPTableEntry const * const entry = OPTable_find(table, key);

    return entry ? entry->value : NULL;
}

STATIC OPAnnotation * OPTable_store(OPTable *table, const OP *key, OPAnnotation *value) {
    OPAnnotation *annotation = NULL;
    OPTableEntry *entry = OPTable_find(table, key);

    if (entry) {
        annotation = entry->value;
        entry->value = value;
    } else {
        const UV index = OPTABLE_HASH(key) & (table->size - 1);
        Newx(entry, 1, OPTableEntry);

        entry->key = key;
        entry->value = value;
        entry->next = table->array[index];

        table->array[index] = entry;
        ++(table->items);

        if (((NV)table->items / (NV)table->size) > table->threshold) {
            OPTable_grow(table);
        }
    }

    return annotation;
}

/* double the size of the array */
STATIC void OPTable_grow(OPTable *table) {
    OPTableEntry **array = table->array;
    const UV oldsize = table->size;
    UV newsize = oldsize * 2;
    UV i;

    Renew(array, newsize, OPTableEntry*);
    Zero(&array[oldsize], newsize - oldsize, OPTableEntry*);
    table->size = newsize;
    table->array = array;

    for (i = 0; i < oldsize; ++i, ++array) {
        OPTableEntry **current_entry_ptr, **entry_ptr, *entry;

        if (!*array) {
            continue;
        }

        current_entry_ptr = array + oldsize;

        for (entry_ptr = array, entry = *array; entry; entry = *entry_ptr) {
            UV index = OPTABLE_HASH(entry->key) & (newsize - 1);

            if (index != i) {
                *entry_ptr = entry->next;
                entry->next = *current_entry_ptr;
                *current_entry_ptr = entry;
                continue;
            } else {
                entry_ptr = &entry->next;
            }
        }
    }
}

STATIC void OPTable_clear(pTHX_ OPTable *table, OPTableEntryValueDtor dtor) {
    if (table && table->items) {
        OPTableEntry ** const array = table->array;
        UV riter = table->size - 1;

        do {
            OPTableEntry *entry = array[riter];

            while (entry) {
                OPTableEntry * const temp = entry;
                entry = entry->next;
                dtor(aTHX_ temp->value);
                Safefree(temp);
            }

            /* chocolateboy 2008-01-08
             *
             * make sure we clear the array entry, so that subsequent probes fail
             */

            array[riter] = NULL;
        } while (riter--);

        table->items = 0;
    }
}

STATIC void OPTable_free(OPTable *table) {
    if (table) {
        Safefree(table);
    }
}
