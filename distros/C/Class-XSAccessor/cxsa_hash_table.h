#ifndef cxsa_hash_table_h_
#define cxsa_hash_table_h_

#include "cxsa_memory.h"

#include "EXTERN.h"
#include "ppport.h"
#include "perl.h"

typedef struct HashTableEntry {
    struct HashTableEntry* next;
    const char* key;
    STRLEN len;
    void * value;
} HashTableEntry;

typedef struct {
    struct HashTableEntry** array;
    UV size;
    UV items;
    NV threshold;
} HashTable;

/* void * CXSA_HashTable_delete(HashTable* table, const char* key, STRLEN len); */
void * CXSA_HashTable_fetch(HashTable* table, const char* key, STRLEN len);
void * CXSA_HashTable_store(HashTable* table, const char* key, STRLEN len, void * value);
HashTableEntry* CXSA_HashTable_find(HashTable* table, const char* key, STRLEN len);
HashTable* CXSA_HashTable_new(UV size, NV threshold);
void CXSA_HashTable_clear(HashTable* table, bool do_release_values);
void CXSA_HashTable_free(HashTable* table, bool do_release_values);
void CXSA_HashTable_grow(HashTable* table);

#endif
