/*
 * This is copied more or less verbatim from the pointer table implementation in sv.c
 */

#include "ppport.h"

#define PTABLE_HASH(ptr) ((PTR2UV(ptr) >> 3) ^ (PTR2UV(ptr) >> (3 + 7)) ^ (PTR2UV(ptr) >> (3 + 17)))

struct PTABLE_entry {
    struct PTABLE_entry     *next;
    void                    *key;
    void                    *value;
};

struct PTABLE {
    struct PTABLE_entry     **tbl_ary;
    UV                      tbl_max;
    UV                      tbl_items;
};

typedef struct PTABLE_entry PTABLE_ENTRY_t;
typedef struct PTABLE            PTABLE_t;

static PTABLE_t * PTABLE_new(void);
static PTABLE_ENTRY_t * PTABLE_find(PTABLE_t *tbl, const void *key);
static void * PTABLE_fetch(PTABLE_t *tbl, const void *key);
static void PTABLE_store(PTABLE_t *tbl, void *key, void *value);
static void PTABLE_grow(PTABLE_t *tbl);
static void PTABLE_clear(PTABLE_t *tbl);
static void PTABLE_free(PTABLE_t *tbl);

/* create a new pointer => pointer table */

static PTABLE_t *
PTABLE_new(void)
{
    PTABLE_t *tbl;
    Newxz(tbl, 1, PTABLE_t);
    tbl->tbl_max = 511;
    tbl->tbl_items = 0;
    Newxz(tbl->tbl_ary, tbl->tbl_max + 1, PTABLE_ENTRY_t*);
    return tbl;
}

/* map an existing pointer using a table */

static PTABLE_ENTRY_t *
PTABLE_find(PTABLE_t *tbl, const void *key) {
    PTABLE_ENTRY_t *tblent;
    const UV hash = PTABLE_HASH(key);
    tblent = tbl->tbl_ary[hash & tbl->tbl_max];
    for (; tblent; tblent = tblent->next) {
        if (tblent->key == key)
            return tblent;
    }
    return NULL;
}

static void *
PTABLE_fetch(PTABLE_t *tbl, const void *key)
{
    PTABLE_ENTRY_t const *const tblent = PTABLE_find(tbl, key);
    return tblent ? tblent->value : NULL;
}

/* add a new entry to a pointer => pointer table */

static void
PTABLE_store(PTABLE_t *tbl, void *key, void *value)
{
    PTABLE_ENTRY_t *tblent = PTABLE_find(tbl, key);

    if (tblent) {
        tblent->value = value;
    } else {
        const UV entry = PTABLE_HASH(key) & tbl->tbl_max;
        Newx(tblent, 1, PTABLE_ENTRY_t);

        tblent->key = key;
        tblent->value = value;
        tblent->next = tbl->tbl_ary[entry];
        tbl->tbl_ary[entry] = tblent;
        tbl->tbl_items++;
        if (tblent->next && (tbl->tbl_items > tbl->tbl_max))
            PTABLE_grow(tbl);
    }
}

/* double the hash bucket size of an existing ptr table */

static void
PTABLE_grow(PTABLE_t *tbl)
{
    PTABLE_ENTRY_t **ary = tbl->tbl_ary;
    const UV oldsize = tbl->tbl_max + 1;
    UV newsize = oldsize * 2;
    UV i;

    Renew(ary, newsize, PTABLE_ENTRY_t*);
    Zero(&ary[oldsize], newsize - oldsize, PTABLE_ENTRY_t*);
    tbl->tbl_max = --newsize;
    tbl->tbl_ary = ary;

    for (i = 0; i < oldsize; i++, ary++) {
        PTABLE_ENTRY_t **curentp, **entp, *ent;
        if (!*ary)
            continue;
        curentp = ary + oldsize;
        for (entp = ary, ent = *ary; ent; ent = *entp) {
            if ((newsize & PTABLE_HASH(ent->key)) != i) {
                *entp = ent->next;
                ent->next = *curentp;
                *curentp = ent;
                continue;
            } else {
                entp = &ent->next;
            }
        }
    }
}

/* remove all the entries from a ptr table */

static void
PTABLE_clear(PTABLE_t *tbl)
{
    if (tbl && tbl->tbl_items) {
        register PTABLE_ENTRY_t * * const array = tbl->tbl_ary;
        UV riter = tbl->tbl_max;

        do {
            PTABLE_ENTRY_t *entry = array[riter];

            while (entry) {
                PTABLE_ENTRY_t * const oentry = entry;
                entry = entry->next;
                Safefree(oentry);
            }

            /* chocolateboy 2008-01-08
             *
             * make sure we clear the array entry, so that subsequent probes fail
             */

            array[riter] = NULL;
        } while (riter--);

        tbl->tbl_items = 0;
    }
}

/* clear and free a ptr table */

static void
PTABLE_free(PTABLE_t *tbl)
{
    if (!tbl) {
        return;
    }
    PTABLE_clear(tbl);
    Safefree(tbl->tbl_ary);
    Safefree(tbl);
}
