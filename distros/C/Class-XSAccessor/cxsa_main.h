#ifndef cxsa_main_h_
#define cxsa_main_h_

#include "EXTERN.h"
#include "perl.h"
#include "ppport.h"

#include "cxsa_hash_table.h"

typedef struct autoxs_hashkey_str autoxs_hashkey;
struct autoxs_hashkey_str {
  U32 hash;
  char* key;
  I32 len; /* not STRLEN for perl internal UTF hacks and hv_common_keylen
              -- man, these things can take you by surprise */
  autoxs_hashkey * next; /* Alas, this is the node of a linked list */

  /* It may be tempting to add more data here for further parameterization
   * of the accessor methods. That's simple at first sight (just add another
   * bit of data here, say a void* for user data, whatever). But when you
   * think about it some more, you'll see that this has various nasty
   * consequences in the context of re-using the hashkey entries.
   * - Hashkey structs are shared and there's a reverse look-up using the
   *   hash-key-string itself for that purpose.
   * - Sharing the hashkey structs is important for threads: Otherwise, we
   *   have to implement full cloning on thread creation. Oh my.
   * - If we didn't share hashkey structs, we'd have to deallocate them when
   *   an accessor method is no longer used. That means detecting when that
   *   happens. Note that there is not reference counting mechanism we can
   *   use to make this easy. So the sharing/reuse of hashkey structs was a
   *   way to avoid this real or perceived memory leak on re-generation of
   *   accessors for the same object slot.
   */
};

autoxs_hashkey * get_hashkey(pTHX_ const char* key, const I32 len);
I32 get_internal_array_index(I32 object_ary_idx);

/* Macro to encapsulate fetching of a hashkey struct pointer for the actual
 * XSUBs */
#define CXAH_GET_HASHKEY ((autoxs_hashkey *) XSANY.any_ptr)


/*************************
 * thread-shared memory
 ************************/

extern autoxs_hashkey * CXSAccessor_last_hashkey;
extern autoxs_hashkey * CXSAccessor_hashkeys;
extern HashTable* CXSAccessor_reverse_hashkeys;

extern U32 CXSAccessor_no_arrayindices;
extern U32 CXSAccessor_free_arrayindices_no;
extern I32* CXSAccessor_arrayindices;

extern U32 CXSAccessor_reverse_arrayindices_length;
extern I32* CXSAccessor_reverse_arrayindices;

#endif
