#include "cxsa_main.h"

#include "cxsa_locking.h"

/*************************
 * initialization section 
 ************************/

autoxs_hashkey * CXSAccessor_last_hashkey = NULL;
autoxs_hashkey * CXSAccessor_hashkeys = NULL;
HashTable* CXSAccessor_reverse_hashkeys = NULL;


/* TODO the array index storage is still thought to not be 100%
 * thread-safe during re-allocation and concurrent access by an
 * implementation XSUB. Requires the same linked-list dance as the
 * hash case. */
U32 CXSAccessor_no_arrayindices = 0;
U32 CXSAccessor_free_arrayindices_no = 0;
I32* CXSAccessor_arrayindices = NULL;

U32 CXSAccessor_reverse_arrayindices_length = 0;
I32* CXSAccessor_reverse_arrayindices = NULL;

/*************************
 * implementation section 
 *************************/

/* implement hash containers */

STATIC
autoxs_hashkey *
_new_hashkey() {
  autoxs_hashkey * retval;
  retval = (autoxs_hashkey *) cxa_malloc( sizeof(autoxs_hashkey) );
  retval->next = NULL;

  if (CXSAccessor_last_hashkey != NULL) { /* apend to list */
    CXSAccessor_last_hashkey->next = retval;
  }
  else { /* init */
    CXSAccessor_hashkeys = retval;
  }
  CXSAccessor_last_hashkey = retval;

  return retval;
}

autoxs_hashkey *
get_hashkey(pTHX_ const char* key, const I32 len) {
  autoxs_hashkey * hashkey;

  CXSA_ACQUIRE_GLOBAL_LOCK(CXSAccessor_lock);

  /* init */
  if (CXSAccessor_reverse_hashkeys == NULL)
    CXSAccessor_reverse_hashkeys = CXSA_HashTable_new(16, 0.9);

  hashkey = (autoxs_hashkey *) CXSA_HashTable_fetch(CXSAccessor_reverse_hashkeys, key, (STRLEN)len);
  if (hashkey == NULL) { /* does not exist */
    hashkey = _new_hashkey();
    /* store the new hash key in the reverse lookup table */
    CXSA_HashTable_store(CXSAccessor_reverse_hashkeys, key, len, hashkey);
  }

  CXSA_RELEASE_GLOBAL_LOCK(CXSAccessor_lock);

  return hashkey;
}



/* implement array containers */

STATIC
void
_resize_array(I32** array, U32* len, U32 newlen) {
  *array = (I32*)cxa_realloc((void*)(*array), newlen*sizeof(I32));
  *len = newlen;
}

STATIC
void
_resize_array_init(I32** array, U32* len, U32 newlen, I32 init) {
  U32 i;
  *array = (I32*)cxa_realloc((void*)(*array), newlen*sizeof(I32));
  for (i = *len; i < newlen; ++i)
    (*array)[i] = init;
  *len = newlen;
}

/* this is private, call get_internal_array_index instead */
I32
_new_internal_arrayindex() {
  if (CXSAccessor_no_arrayindices == CXSAccessor_free_arrayindices_no) {
    U32 extend = 2 + CXSAccessor_no_arrayindices * 2;
    /*printf("extending array index storage by %u\n", extend);*/
    _resize_array(&CXSAccessor_arrayindices, &CXSAccessor_no_arrayindices, extend);
  }
  return CXSAccessor_free_arrayindices_no++;
}

I32 get_internal_array_index(I32 object_ary_idx) {
  I32 new_index;

  CXSA_ACQUIRE_GLOBAL_LOCK(CXSAccessor_lock);

  if (CXSAccessor_reverse_arrayindices_length <= (U32)object_ary_idx)
    _resize_array_init( &CXSAccessor_reverse_arrayindices,
                        &CXSAccessor_reverse_arrayindices_length,
                        object_ary_idx+1, -1 );

  /* -1 == "undef" */
  if (CXSAccessor_reverse_arrayindices[object_ary_idx] > -1) {
    CXSA_RELEASE_GLOBAL_LOCK(CXSAccessor_lock);
    return CXSAccessor_reverse_arrayindices[object_ary_idx];
  }

  new_index = _new_internal_arrayindex();
  CXSAccessor_reverse_arrayindices[object_ary_idx] = new_index;

  CXSA_RELEASE_GLOBAL_LOCK(CXSAccessor_lock);

  return new_index;
}

