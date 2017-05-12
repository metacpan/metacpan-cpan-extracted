#include "stdio.h"
#include "extern.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "embed.h"
#include "Blue.h"

/*
------------------------------------------------------------------------
XSUB Interface to DBM::Deep::Blue
Copyright, PhilipRBrenan at gmail dot com, 2010
------------------------------------------------------------------------
*/

/*
------------------------------------------------------------------------
Decode memory indirection address from blessed scalar
------------------------------------------------------------------------
*/

M **decodeAddress(SV *r)
 {SV *s = SvRV(r);
  UL  m = SvUV(s);
  return (M **)m;
 }

/*
------------------------------------------------------------------------
Package the memory structure indirection address and object number
together
------------------------------------------------------------------------
*/

typedef struct tieMO
 {M **m;  // Memory structure
  UL  o;  // Array object
 } tieMO;

/*
------------------------------------------------------------------------
Decode tmo. The tmo indicates the memory structure address and object
used to contain an array or hash
------------------------------------------------------------------------
*/

tieMO *decodeTmo(SV *r)
 {SvROK(r);                                      // Blessed variable reference
  SV *T = (SV *)SvRV(r);                         // Dereference to string
  STRLEN L;                                      // Length of string
  tieMO *t = (void *)SvPV(T, L);                 // Address tmo
  M **m = t->m;                                  // Memory
  UL  o = t->o;                                  // Array object

  return t;
 }

/*
------------------------------------------------------------------------
Created blessed reference to an object in memory structure
------------------------------------------------------------------------
*/

SV *createBlessedObjectRef(M **m, UL a, char *package)
 {tieMO tmo; tmo.m = m; tmo.o = a;               // How to find object in memory structure
  SV *S     = newSVpv((char *)&tmo, sizeof(tmo));// Save it in a string

  SV *tie   = newRV_noinc(S);                    // Create a reference to the tmo string
  HV *stash = gv_stashpv(package, GV_ADD);       // Name the tying package
  sv_bless(tie, stash);                          // Bless the control information 

  return tie;
 }

/*
------------------------------------------------------------------------
DESTROY
------------------------------------------------------------------------
*/

void c_DESTROY(SV *r)
 {M **m = decodeAddress(r);
  freeMemoryArea(m);
 }

/*
------------------------------------------------------------------------
commit
------------------------------------------------------------------------
*/

void c_commit(SV *r)
 {M **m = decodeAddress(r);
  commit(m);
 }

/*
------------------------------------------------------------------------
rollback
------------------------------------------------------------------------
*/

void c_rollback(SV *r)
 {M **m = decodeAddress(r);
  rollback(m);
 }

/*
------------------------------------------------------------------------
begin_work
------------------------------------------------------------------------
*/

void c_begin_work(SV *r)
 {M **m = decodeAddress(r);
  begin_work(m);
 }

/*
------------------------------------------------------------------------
dumpArea
------------------------------------------------------------------------
*/

void c_dump(SV *r, char *s)
 {M **m = decodeAddress(r);
  dumpArea(m, s);
 }

/*
------------------------------------------------------------------------
Get size of memory area
------------------------------------------------------------------------
*/

unsigned long c_size(SV *r)
 {M **m = decodeAddress(r);
  return (*m)->length;
 }

/*
------------------------------------------------------------------------
Dump sizes of arrays and hashes
------------------------------------------------------------------------
*/

void c_dahs(SV *r)
 {M **m = decodeAddress(r);
  dahs(m);
 }

/*
------------------------------------------------------------------------
Allocate new memory structure and return a blessed reference to it
------------------------------------------------------------------------
*/

SV *c_new()
 {UL M = (UL)allocMemoryArea(2);
  SV *r = newRV(newSV(0));
  return sv_setref_uv(r, "DBM::Deep::Blue", M);
 }

/*
------------------------------------------------------------------------
File backed memory structure
------------------------------------------------------------------------
*/

SV *c_file(char *f)
 {M **m = allocPagedMemoryArea(f);

  UL M = (UL)m;
  SV *r = newRV(newSV(0));
  return sv_setref_uv(r, "DBM::Deep::Blue", M);
 }

/*
########################################################################
Objects
########################################################################
*/

/*
------------------------------------------------------------------------
Save data from Perl into a memory structure and return the number of the
object created
------------------------------------------------------------------------
*/

UL saveObjectData(M **m, SV *s)
 {if (!(SvROK(s)))                               // Save string or undefined
   {if (SvOK(s))                                 // String
     {STRLEN l;
      char *c = SvPV(s, l); 
      UL o = allocString(m, c, l);
      return o;
     }
    return 0;                                    // Undefined
   }

// Save blessing string if object is blessed

  UL blessString = 0;                            // Object number of string used to bless object
   {HV *stash=SvSTASH(SvRV(s));                  // Get stash of reference
    if (stash)
     {char *name = HvNAME_get(stash);            // Name of package blkessed into
      blessString = saveStringInHashST           // Save string in HashST
       (m, name, strlen(name));                  
     }
   }

// Load from a reference to data in this memory structure

  MAGIC *Mc = mg_find(SvRV(s), PERL_MAGIC_tied); // Find magic associated with this SV 
  if (Mc > 0)
   {SV *T = Mc->mg_obj ;                         // Find tied variable from Magic
    long aa = sv_isa(T, "DBM_Deep_Blue_Array");  // In this package
    long bb = sv_isa(T, "DBM_Deep_Blue_Hash");   // or this oackage
    if (aa || bb)
     {tieMO *t = decodeTmo(T);                   // Address array
      if (t->m == m)                             // In this memory structure? 
       {return t->o;                             // Return object number - it is already in this memory structure
       }
      else                                       // In another memory structure 
       {croak("Copy from one memory structure to another not yet supported\n");
       }
     }
   }

// Load from Perl     

  long t = SvTYPE(SvRV(s));                      // Type of reference

  if (t == SVt_PVAV)                             // Array
   {AV *a = (AV *)SvRV(s);
    UL  o = allocArray(m);
    saveArrayBless(m, o, blessString);           // Save bless string for this array  
    if (av_len(a) == -1)
     {SV * tie = createBlessedObjectRef(m, o, "DBM_Deep_Blue_Array");
      hv_magic(a, (GV*)tie, PERL_MAGIC_tied);    // Do the tie
     }
    else
     {UL i;
      for(i = 0; i <= av_len(a); ++i)            // Save the contents of the array into the memory structure 
       {SV **v = av_fetch(a, i, 0);
        if (v == NULL) {continue;}               // Skip undefined entries
         putArray(m, o, i, saveObjectData(m, *v));
       }
     }
    return o;                                    // return number of array object
   }

  if (t == SVt_PVHV)                             // Hash
   {HV *h = (HV *)SvRV(s);
    UL  o = allocHash(m);
    saveHashBless(m, o, blessString);            // Save bless string
    UL  n = hv_iterinit(h);                      // Number of entries in Hash?
    if (n == 0)
     {SV * tie = createBlessedObjectRef(m, o, "DBM_Deep_Blue_Hash");
      hv_magic(h, (GV*)tie, PERL_MAGIC_tied);    // Do the tie
     }
    else                                         // Copy hash contents into memory structure
     {UL i;
      for(i = 0; i < n; ++i)
       {char  *k;
        UL     l;
        SV    *v = hv_iternextsv(h, &k, &l);

        putHash(m, o, k, l, saveObjectData(m, v));
       }
     }
    return o;        
   }

  croak("Cannot handle type %d", t); 
 }

/*
------------------------------------------------------------------------
Bless a reference with the contents of the hash key with object number o
------------------------------------------------------------------------
*/

void bless(SV *s, M **m, UL o)
 {HashKey *k = addressHashKey(m, o);               // Address bless name string saved in HashST
  char  B[1024];                                   // Buffer large enough for most names 
  char *b = B;         
  UL l = k->length;                                // Length required

  if (l > sizeof(b)-1) {b = malloc(l+1);}          // Get buffer for exceptionally long bless name string 
  memcpy(b, k->array, l);                          // Copy data
  b[l] = 0;                                        // Set trailing byte of string for str* routines  


  HV *stash = gv_stashpv(b, GV_ADD);               // Name the tying package
  sv_bless(s, stash);                              // Bless the control information

  if (b != B) {free(b);}                           // Free buffer if it was allocated by malloc
 }

/*
------------------------------------------------------------------------
Bless an array reference r to match array with object number o in memory
structure m
------------------------------------------------------------------------
*/

void blessArrayReference(SV *s, M **m, UL o)
 {Array *A = addressArray(m, o);                   // Address array
  if (A->blessed == 0) {return;}                   // Object not blessed
  bless(s, m, A->blessed);                         // Bless reference to match array
 }

/*
------------------------------------------------------------------------
Bless a hash reference r to match hash with object number o in memory
structure m
------------------------------------------------------------------------
*/

void blessHashReference(SV *s, M **m, UL o)
 {Hash *H = addressHash(m, o);                     // Address hash
  if (H->blessed == 0) {return;}                   // Object not blessed
  bless(s, m, H->blessed);                         // Bless reference to match hash
 }

/*
------------------------------------------------------------------------
Tie object to a variable of the right type
------------------------------------------------------------------------
*/

SV *tieObject(M **m, UL o)
 {if (o == 0)
   {return &PL_sv_undef;                           // Return undefined if entry does not exist
   }

  UL t = getObjectType(m, o);                      // Tie by object type

  if (t == ObjectTypeString)                       // String
   {String *S = addressString(m, o);               // Address string
    SV *s = newSVpvn(S->array, S->length);         // Make SV from string
    return s;
   }
 
  if (t == ObjectTypeHashKey)                      // Hash Key
   {HashKey *S = addressHashKey(m, o);             // Address hash key
    SV *s = newSVpvn(S->array, S->length);         // Make SV from hash key
    return s;
   }
 
  if (t == ObjectTypeArray)                        // Array
   {SV *tie = createBlessedObjectRef(m, o, "DBM_Deep_Blue_Array");
    AV *A   = newAV();                             // This is the tied array
    hv_magic(A, (GV*)tie, PERL_MAGIC_tied);        // Do the tie
    SV *r = newRV_noinc((SV *)A);                  // Create a reference to the tied array
    blessArrayReference(r, m, o);                  // Bless reference if necessary
    return r;                                      // Return reference
   }  

  if (t == ObjectTypeHash)                         // Hash
   {SV * tie = createBlessedObjectRef(m, o, "DBM_Deep_Blue_Hash");
    
    HV *H     = newHV();                           // This is the tied hash
    hv_magic(H, (GV*)tie, PERL_MAGIC_tied);        // Do the tie
    SV *r = newRV_noinc((SV *)H);                  // Create a reference to the tied array
    blessHashReference(r, m, o);                   // Bless reference to hash
    return r;                                      // Return reference
   }  

  croak("Cannot tie type %u\n", t);
 }

/*
########################################################################
Strings
########################################################################
*/

/*
------------------------------------------------------------------------
getString
------------------------------------------------------------------------
*/

SV *c_getString(SV *r, UL o)
 {M **m = decodeAddress(r);
  String *S = addressString(m, o);
  SV *s = newSVpvn(S->array, S->length);
  return s;
 }

/*
########################################################################
Arrays
########################################################################
*/

/*
------------------------------------------------------------------------
FETCHSIZE
------------------------------------------------------------------------
*/

UL a_FETCHSIZE(SV *r)
 {tieMO *t = decodeTmo(r);
  return getArraySize(t->m, t->o);               // Return array size
 }

/*
------------------------------------------------------------------------
FETCH
------------------------------------------------------------------------
*/

SV *a_FETCH(SV *r, UL i)
 {tieMO *t = decodeTmo(r);                       // Address array

  UL o = getArray(t->m, t->o, i);                // Get object from array

  if (o == 0)
   {return &PL_sv_undef;                         // Return undefined if entry does not exist
   }

  return tieObject(t->m, o);
 }


/*
------------------------------------------------------------------------
EXISTS
------------------------------------------------------------------------
*/

int a_EXISTS(SV *r, UL i)
 {tieMO *t = decodeTmo(r);                       // Address array

  UL o = getArray(t->m, t->o, i);                // Get object from array

  return !!o;                                    // Return existance of object
 }

/*
------------------------------------------------------------------------
STORE
------------------------------------------------------------------------
*/

void a_STORE(SV *r, UL i, SV *S)
 {tieMO *t = decodeTmo(r);                       // Address array
  putArray(t->m, t->o, i, saveObjectData(t->m, S)); // Put object in array at indicated position
 }

/*
------------------------------------------------------------------------
EXTEND
------------------------------------------------------------------------
*/
  
void a_EXTEND(SV *r, UL c)
 {tieMO *t = decodeTmo(r);
  extendArray(t->m, t->o, c);
 }

/*
------------------------------------------------------------------------
STORESIZE
------------------------------------------------------------------------
*/
  
void a_STORESIZE(SV *r, UL c)
 {tieMO *t = decodeTmo(r);
  if (c < 0) {c = 0;}
  setArraySize(t->m, t->o, c);
 }

/*
------------------------------------------------------------------------
CLEAR
------------------------------------------------------------------------
*/
  
void a_CLEAR(SV *r)
 {tieMO *t = decodeTmo(r);
  clearArray(t->m, t->o);
 }

/*
------------------------------------------------------------------------
PUSH
------------------------------------------------------------------------
*/
  
void a_PUSH(SV *r, SV *v)
 {tieMO *t = decodeTmo(r);
  pushArray(t->m, t->o, saveObjectData(t->m, v));
 }

/*
------------------------------------------------------------------------
POP
------------------------------------------------------------------------
*/

SV *a_POP(SV *r)
 {tieMO *t = decodeTmo(r);
  UL o = popArray(t->m, t->o);
  return tieObject(t->m, o);
 }

/*
------------------------------------------------------------------------
UNSHIFT
------------------------------------------------------------------------
*/

void a_UNSHIFT(SV *r, SV *v)
 {tieMO *t = decodeTmo(r);
  unshiftArray(t->m, t->o, saveObjectData(t->m, v));
 }

/*
------------------------------------------------------------------------
SHIFT
------------------------------------------------------------------------
*/

SV *a_SHIFT(SV *r)
 {tieMO *t = decodeTmo(r);
  UL o = shiftArray(t->m, t->o);
  return tieObject(t->m, o);
 }

/*
------------------------------------------------------------------------
SPLICE
------------------------------------------------------------------------

SV *a_SPLICE(SV *r, long n, SV **a)
 {tieMO *t = decodeTmo(r);
   {long i;
    if (items > 0) {a[1] = SvIV(ST(1));}  
    if (items > 1) {a[2] = SvIV(ST(2));}  
    for(i = 3; i < n; ++i)
     {a[i] = saveObjectData(t->m, a[i]);
     }
   }
  spliceArray(t->m, t->o, n, a);  
  return &PL_sv_undef;
 }

/*
------------------------------------------------------------------------
allocArray
------------------------------------------------------------------------
*/

SV *c_allocArray(SV *r)
 {M **m   = decodeAddress(r);                    // Decode address of memory structure 
  UL  a   = allocArray(m);                       // Create array in memory structure
  SV *tie = createBlessedObjectRef(m, a, "DBM_Deep_Blue_Array");
    
  AV *A     = newAV();                           // This is the tied array
  hv_magic(A, (GV*)tie, PERL_MAGIC_tied);        // Do the tie
  return newRV_noinc((SV *)A);                   // Return a reference to the tied array
 }

/*
------------------------------------------------------------------------
allocGlobalArray
------------------------------------------------------------------------
*/

SV *c_allocGlobalArray(SV *r)
 {M **m   = decodeAddress(r);                    // Decode address of memory structure 
  UL  a   = allocGlobalArray(m);                 // Create array in memory structure
  SV *tie = createBlessedObjectRef(m, a, "DBM_Deep_Blue_Array");
    
  AV *A     = newAV();                           // This is the tied array
  hv_magic(A, (GV*)tie, PERL_MAGIC_tied);        // Do the tie
  return newRV_noinc((SV *)A);                   // Return a reference to the tied array
 }

/*
########################################################################
Hash
########################################################################
*/

/*
------------------------------------------------------------------------
FETCH
------------------------------------------------------------------------
*/

SV *h_FETCH(SV *r, SV *K)
 {tieMO *t = decodeTmo(r);                       // Address hash

  STRLEN l;
  char *k = SvPV(K, l);
  UL o = getHash(t->m, t->o, k, l);              // Get object from hash

  if (o == 0)
   {return &PL_sv_undef;                         // Return undefined if entry does not exist
   }

  return tieObject(t->m, o);                     // Return found object
 }

/*
------------------------------------------------------------------------
STORE
------------------------------------------------------------------------
*/

void h_STORE(SV *r, SV *K, SV *S)
 {tieMO *t = decodeTmo(r);                       // Address hash
  STRLEN l;
  char *k = SvPV(K, l);
  putHash(t->m, t->o, k, l, saveObjectData(t->m, S)); // Put object in hash
 }

/*
------------------------------------------------------------------------
DELETE
------------------------------------------------------------------------
*/

SV *h_DELETE(SV *r, SV *K)
 {tieMO *t = decodeTmo(r);                       // Address hash

  STRLEN l;
  char *k = SvPV(K, l);
  UL o = deleteHashKey(t->m, t->o, k, l);        // Delete object from hash

  if (o == 0)
   {return &PL_sv_undef;                         // Return undefined if entry does not exist
   }

  return tieObject(t->m, o);                     // Return data from deleted object
 }

/*
------------------------------------------------------------------------
CLEAR
------------------------------------------------------------------------
*/

void h_CLEAR(SV *r)
 {tieMO *t = decodeTmo(r);                       // Address hash

  clearHash(t->m, t->o);                         // Clear hash
 }

/*
------------------------------------------------------------------------
EXISTS
------------------------------------------------------------------------
*/

int h_EXISTS(SV *r, SV *K)
 {tieMO *t = decodeTmo(r);                       // Address hash

  STRLEN l;
  char *k = SvPV(K, l);
  return inHash(t->m, t->o, k, l);         // Test whether key exists
 }

/*
------------------------------------------------------------------------
SCALAR
------------------------------------------------------------------------
*/

unsigned long h_SCALAR(SV *r)
 {tieMO *t = decodeTmo(r);                       // Address hash

  return getHashSize(t->m, t->o);                // Count of elements
 }

/*
------------------------------------------------------------------------
FIRSTKEY
------------------------------------------------------------------------
*/

SV *h_FIRSTKEY(SV *r)
 {tieMO *t = decodeTmo(r);                       // Address hash

  UL s = getHashFirst(t->m, t->o);               // Get first object in hash

  if (s == 0)
   {return &PL_sv_undef;                         // Return undefined if empty
   }

  UL o = getKey   (t->m, t->o);
  return tieObject(t->m, o);                     // Return first key
 }

/*
------------------------------------------------------------------------
NEXTKEY
------------------------------------------------------------------------
*/

SV *h_NEXTKEY(SV *r, SV *k)
 {tieMO *t = decodeTmo(r);                       // Address hash

  UL s = getHashNext(t->m, t->o);                // Get next object in hash

  if (s == 0)
   {return &PL_sv_undef;                         // Return undefined if finished
   }

  UL o = getKey   (t->m, t->o);
  return tieObject(t->m, o);                     // Return next key
 }

/*
------------------------------------------------------------------------
allocHash
------------------------------------------------------------------------
*/

SV *c_allocHash(SV *r)
 {M **m   = decodeAddress(r);                    // Decode address of memory structure 
  UL  a   = allocHash(m);                        // Create array in memory structure
  SV *tie = createBlessedObjectRef(m, a, "DBM_Deep_Blue_Hash");
    
  HV *H     = newHV();                           // This is the tied hash
  hv_magic(H, (GV*)tie, PERL_MAGIC_tied);        // Do the tie
  return newRV_noinc((SV *)H);                   // Return a reference to the tied hash
 }

/*
------------------------------------------------------------------------
allocGlobalHash
------------------------------------------------------------------------
*/

SV *c_allocGlobalHash(SV *r)
 {M **m   = decodeAddress(r);                    // Decode address of memory structure 
  UL  a   = allocGlobalHash(m);                  // Create hash in memory structure
  SV *tie = createBlessedObjectRef(m, a, "DBM_Deep_Blue_Hash");
    
  HV *H     = newHV();                           // This is the tied hash
  hv_magic(H, (GV*)tie, PERL_MAGIC_tied);        // Do the tie
  return newRV_noinc((SV *)H);                   // Return a reference to the tied hash
 }

/*
------------------------------------------------------------------------
Test array for raw performance
------------------------------------------------------------------------
*/

void c_testArray(SV *r)
 {M **m = decodeAddress(r);
  UL a = allocArray(m);
  UL i;
  for(i = 0; i < 10000; ++i)
   {putArray(m, a, i  % 100, a);
   } 
 }

/*
------------------------------------------------------------------------
Test hash for raw performance
------------------------------------------------------------------------
*/

void c_testHash(SV *r)
 {M **m = decodeAddress(r);
  UL h = allocHash(m);
  UL i;
  for(i = 0; i < 10000; ++i)
   {char b[100];
    sprintf(b, "%d", i % 100);
    putHash(m, h, b, strlen(b), h);
   } 
 }

/*
------------------------------------------------------------------------
XSUB definitions
------------------------------------------------------------------------
*/
MODULE = DBM::Deep::Blue	PACKAGE = DBM::Deep::Blue	PREFIX = c_
PROTOTYPES: ENABLE

void
interface_v_m(SV *m)
INTERFACE:
c_DESTROY
c_begin_work
c_commit
c_rollback
c_dahs

void
interface_v_ms(SV *m, char *s)
INTERFACE:
c_dump

SV *
interface_S_ml(SV *m, unsigned long o)
INTERFACE:
c_getString

SV *
interface_S_v()
INTERFACE:
c_new

SV *
interface_S_s(char *f)
INTERFACE:
c_file

unsigned long
interface_l_m(SV *m)
INTERFACE:
c_size

SV *
interface_S_m(SV *m)
INTERFACE:
c_allocArray
c_allocGlobalArray
c_allocHash
c_allocGlobalHash

void
c_interface_v_S(SV *tmo)
INTERFACE:
c_testHash
c_testArray

#-----------------------------------------------------------------------
# Arrays
#-----------------------------------------------------------------------

MODULE = DBM::Deep::Blue	PACKAGE = DBM_Deep_Blue_Array	PREFIX = a_
PROTOTYPES: ENABLE

unsigned long
a_interface_S_t(SV *tmo)
INTERFACE:
a_FETCHSIZE

void
a_interface_v_SlS(SV *tmo, unsigned long i, SV *S)
INTERFACE:
a_STORE

SV *
a_interface_S_Sl(SV *tmo, unsigned long i)
INTERFACE:
a_FETCH

void
a_interface_v_Sl(SV *tmo, unsigned long i)
INTERFACE:
a_EXTEND
a_STORESIZE

void
a_interface_v_S(SV *tmo)
INTERFACE:
a_CLEAR

unsigned long
a_interface_l_SS(SV *tmo, SV *v, ...)
INTERFACE:
a_PUSH
CODE:
 {long i;
  for(i = 1; i < items; ++i)
   {XSFUNCTION(tmo, ST(i));
   }
  RETVAL = items-1;
 }
OUTPUT:
  RETVAL

unsigned long
a_interface_unshift(SV *tmo, SV *v, ...)
INTERFACE:
a_UNSHIFT
CODE:
 {long i;
  for(i = items-1; i > 0; --i)
   {XSFUNCTION(tmo, ST(i));
   }
  RETVAL = items+1;
 }
OUTPUT:
  RETVAL

SV *
a_interface_S_S(SV *tmo)
INTERFACE:
a_POP
a_SHIFT

#int
#a_interface_i_Sl(SV *tmo, unsigned long i)
#INTERFACE:
#a_EXISTS

#SV *
#a_SPLICE(SV *tmo, ...)
#CODE:
# {SV **a = malloc(sizeof(SV *) * items);

#  long i;
#  for(i = 0; i < items; ++i)
#   {a[i] = ST(i);
#   }   
#  RETVAL = a_SPLICE(tmo, items, a);
#  free(a);
# }
#OUTPUT:
#  RETVAL

#-----------------------------------------------------------------------
# Hashes
#-----------------------------------------------------------------------

MODULE = DBM::Deep::Blue	PACKAGE = DBM_Deep_Blue_Hash	PREFIX = h_
PROTOTYPES: ENABLE

SV *
h_interface_S_S(SV *tmo)
INTERFACE:
h_FIRSTKEY

SV *
h_interface_S_SS(SV *tmo, SV *K)
INTERFACE:
h_FETCH
h_DELETE
h_NEXTKEY

int
h_interface_i_SS(SV *tmo, SV *K)
INTERFACE:
h_EXISTS

unsigned long
h_interface_ul_SS(SV *tmo)
INTERFACE:
h_SCALAR

void
h_interface_v_SS(SV *tmo)
INTERFACE:
h_CLEAR

void
h_interface_v_SSS(SV *tmo, SV *K, SV *S)
INTERFACE:
h_STORE
