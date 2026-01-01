/*
    Provides an interface to
    1) a BIT_T type and a set of functions to manipulate it.
    2) Packed containers of Bit_T (Bit_DB_T) that can be used to
       store multiple bitsets in a contiguous memory region.

    * Author : Christos Argyropoulos
    * Created : April 1st 2025
    * License : Free


    The Bit_T is a simple uncompressed bitset implementation based
    on David Hanson's "C Interfaces and Implementations" book

    This is not a general bitset library, i.e. one cannot grow the bitset.
    Bitsets are also limited in capacity to int (at the time of the
    writting the same size as uint32_t). If one needs larger bitsets, then
    they should probably be using roaring or compressed bitsets.

    Functions that create, free or load an externally created bitset into a T.
    * Bit_new           : Create a new bitset with a fixed capacity/length
    * Bit_free          : Free the bitset and zeros the pointer for safe
                          deallocation (if the space for the bit was allocated
                          by the library). Returns the address of the storage
                          if allocated externally, or NULL if the
                          bitset was allocated by the library.
    * Bit_load          : Load an externally allocated bitset into a (new) T
    * Bit_extract       : Extract the bitset from a T into an externally
                          allocated buffer. Returns the number of bytes written.


    Functions that obtain the properties of a bitset:
    * Bit_length        : Return the length (or capacity) of the bitset (bits)
    * Bit_count         : Count the number of bits set in the bitset
    * Bit_buffer_size   : Return the number of bytes needed to store the
                          individual bits of the bitset of a given length

    Functions that manipulate the bitset:
    * Bit_aset          : Set an array of bits in the bitset to one
    * Bit_bset          : Set a bit in the bitset to one
    * Bit_aclear        : Clear an array of bits in the bitset
    * Bit_bclear        : Clear a bit in the bitset
    * Bit_clear         : Clears a range of bits [lo,hi] in the bitset
    * Bit_get           : Get the value of a bit in the bitset
    * Bit_map           : Applies a function to each bit in the bitset. The
    *                     function *may* change the bitset in place. Note that
    *                     as a function is applied from left to right, the
    *                     changes will be seen by subsequent calls
    * Bit_not           : Inverts a range of bits [lo,hi] in the bitset
    * Bit_put           : Set a bit in the bitset to a value & returns the
                          previous value of the bit
    * Bit_set           : Sets a range of bits [lo,hi] in the bitset to one

    Functions that compare bitsets:
    * Bit_eq            : Compare two bitsets for equality (=1)
    * Bit_leq           : Compare two bitsets for less than or equal (=1)
    * Bit_lt            : Compare two bitsets for less than (=1)

    Functions that operate on sets of bitsets (and create a new one):
    * Bit_inter         : Perform an intersection operation with another bitset
    * Bit_diff          : Perform a difference operation, logical AND
    * Bit_minus         : Perform a symmetric difference operation, ie the XOR
    * Bit_union         : Perform a union operation with another bitset


    Functions that perform counts on set operations of two bitsets:
    * Bit_diff_count    : Count the number of bits set in the difference
    * Bit_inter_count   : Count the number of bits set in the intersection
    * Bit_minus_count   : Count the number of bits set in the symmetric
                          difference
    * Bit_union_count   : Count the number of bits set in the union

    ===========================================================================

    The Bit_DB_T is a packed container of Bit_T and thus contains only
    a few functions to manipulate it.

    * BitDB_new         : Create a new packed container of bitsets
    * BitDB_load        : Load a packed container of bitsets from an
                          externally allocated buffer
    * BitDB_free        : Free the packed container of bitsets
    * BitDB_length      : Get the length of bitsets in the packed container.
    * BitDB_count_at    : Population count at a given index in the container.
    * BitDB_nelem       : Get the number of bitsets in the packed container.
    * BitDB_count       : Population count of all bitsets in the container.

    * BitDB_clear_at    : Clear a bitset at a given index in the packed
                          container.
    * BitDB_clear       : Clear all bitsets in the packed container.
    * BitDB_get_from    : Returns a bitset from the bytes at a given index.
    * BitDB_put_at      : Set a bit in the bitset at a given index in the packed
                          container to the contents of another bitset.
    * BitDB_extract_from: Extract a bitset from the packed container at a given
   index into an externally allocated buffer. Returns the number of bytes
   written. The buffer must be large enough to hold the bitset (so please ensure
   that you use Bit_buffer_size(BitDB_length(set)) to obtain the size of the
   buffer you need if you don't already know this information).

    * BitDB_replace_at   : Replace a bitset in the packed container at a given
   index with the contents of a buffer.
    * BitDB_insert_at    : Insert a new bitset into the packed container at
    *                     a given index.

    * BitDB_SETOP_count : Count the number of bits set in the SETOP
                          of all the bitsets in the container with all the
                          bitsets in another container. This is a macro that
                          expands to a function that takes two containers,
                          a structure for various control options and a target
                          that is their the token cpu or gpu. The actual
                          functions are BitDB_inter_count_cpu and
                          BitDB_inter_count_gpu.

    * BitDB_SETOP_count_store : Count the number of bits set in the SETOP
                          of all the bitsets in the container with all the
                          bitsets in another container. This is a macro that
                          expands to a function that takes two containers,
                          a structure for various control options and a target
                          pre-allocated buffer to store the results and a target
                          that is their the token cpu or gpu. The actual
                          functions are BitDB_inter_count_store_cpu and
                          BitDB_inter_count_store_gpu.

    > SETOP can be one of the following:
        1. inter = intersection
        2. union = union
        3. diff = difference
        4. minus = symmetric difference

    DANGER: While the load functions will write the appropriate number of bytes
    to the buffer, the caller is responsible for ensuring that the buffer is
    large enough to hold the results. Extreme (sprintf level) FAFO may obtain
    in the form of security bugs and buffer overflows if the user fails to
   ensure the buffer is adequately sized.

   NOTE that the macro functions are not callable if one is to compile this
   into a dynamic library, as the macro expansion will not be visible. In this
   case one has to call the functions directly, e.g. BitDB_inter_count_cpu
   or BitDB_inter_count_store_cpu.
*/

#ifndef BIT_INCLUDED
#define BIT_INCLUDED

#include <stdbool.h>
#include <stddef.h>

#define T Bit_T
typedef struct T* T;

#define T_DB Bit_DB_T
typedef struct T_DB* T_DB;

typedef struct {
    int num_cpu_threads;  // number of CPU threads
    int device_id;        // GPU device ID, ignored for CPU
    bool upd_1st_operand; // if true, update the first container in the GPU
    bool upd_2nd_operand; // if true, update the second container in the GPU
    bool release_1st_operand; // if true, release the first container in the GPU
    bool release_2nd_operand; // if true, release the second container in the GPU
    bool release_counts;    // if true, release the counts buffer in the GPU
} SETOP_COUNT_OPTS;

/*
    Functions that create, free and obtain the properties of the bitset. Note
    the following error checking
    * Bit_new           : Checked runtime error if length is less than 0 or
                          greater than INT_MAX.L.
    * Bit_free          : It is a checked runtime error to try to free a bitset
                          that was not allocated by the library.
    * Bit_load          : Checked runtime error if length is less than 0 or
                          greater than INT_MAX. Also checks if buffer is NUL
    * Bit_buffer_size   : Checked runtime error if length is less than 0 or
                          greater than INT_MAX.
    * Bit_length        : Obtains the length (capacity of the bitset) in bits.
                          It is a checked runtime error to a non-positive length
                          or a length greater than INT_MAX.
    * Bit_count         : Counts the number of set bits set in the bitset.

    It is a checked runtime error to pass a NULL set to any of these routines.
*/
extern T Bit_new(int length);  // create a new bitset
extern void* Bit_free(T* set); // free the bitset
extern T Bit_load(int length, void* buffer);
extern int Bit_extract(T set, void* buffer);

extern int Bit_buffer_size(int length);
extern int Bit_length(T set);
extern int Bit_count(T set);

/*
    Functions that manipulate an individual bitset (member operations).
    Note the following error checking:

    It is a checked runtime error to 1) pass a NULL set 2) of the low bit
    is less than zero, 3) the high bit to be greater than the bitset
    length and 4) the low bit to be greater than the high bit, 5) the
    indices to attempt to overrun the bitset length.
    */
extern void Bit_aset(T set, int indices [], int n); // set an array of bits
extern void Bit_bset(T set, int index); // set a bit in the bitset to 1
extern void Bit_aclear(T set, int indices [],
    int n); // clear an array of bits in the bitset
extern void Bit_bclear(T set, int index); // clear a bit in the bitset
extern void Bit_clear(T set, int lo,
    int hi); // clear a range of bits [lo,hi] in the bitset
extern int Bit_get(T set, int index); // returns the bit at index
extern void
Bit_map(T set, void apply(int n, int bit, void* cl),
    void* cl); // maps apply to bit n in the range [0, length-1], where *cl
// is a pointer to a closure that is provided by the client
extern void Bit_not(T set, int lo,
    int hi); // inverts a range of bits [lo,hi] in the bitset
extern int Bit_put(T set, int n, int val); // sets the nth bit to val in set
extern void Bit_set(T set, int lo,
    int hi); // sets a range of bits [lo,hi] in the bitset

/*
    Functions that compare two bitsets; note the following error checking:

    It is a checked runtime error for the two bitsets to be of different
    lengths, or if s or t are NULL.

*/
extern int Bit_eq(T s, T t);  // compare two bitsets for equality
extern int Bit_leq(T s, T t); // compare two bitsets for less than or equal
extern int Bit_lt(T s, T t);  // compare two bitsets for less than

/*
    Functions that operate on sets of bitsets (and create a new one):
    It is a checked runtime error for the two bitsets to be of different
    lengths, or if both s and t are NULL.
    If one of the bitsets is NULL, then the corresponding operation is
    interpreted as against the empty set. In particularBit_

        > Bit_diff(s,NULL) or Bit_diff(NULL, t) returns t or s
        > Bit_diff(s,s) returns (a copy of of) the empty set
        > Bit_inter(s,NULL) or Bit_inter(NULL, t) returns the empty set
        > Bit_minus(NULL,s) or Bit_minus(s,s) returns the empty set
        > Bit_minus(s,NULL) returns a copy of s
        > Bit_union(s,NULL) or Bit_union(NULL, t) makes a copy of s or t
        > Bit_union(s,s) returns a copy of s


*/
extern T Bit_diff(T s, T t);  // difference of two bitsets
extern T Bit_inter(T s, T t); // intersection of two bitsets
extern T Bit_minus(T s, T t); // symmetric difference of two bitsets
extern T Bit_union(T s, T t); // union of two bitsets

/*
    Functions that calculate population counts on the operations of sets of
    bitsets (but without creating a new bitset):
    It is a checked runtime error for the two bitsets to be of different
    lengths, or if both s and t are NULL.
    If one of the bitsets is NULL, then the corresponding operation is
    interpreted as against the empty set. In particularBit_

        > Bit_diff_count(s,NULL) or Bit_diff_count(NULL, t) returns t or s
        > Bit_diff_count(s,s) returns (a copy of of) the empty set
        > Bit_inter_count(s,NULL) or Bit_inter_count(NULL, t) returns the empty
   set > Bit_minus_count(NULL,s) or Bit_minus_count(s,s) returns 0 >
   Bit_minus_count(s,NULL) returns Bit_count(s) > Bit_union_count(s,NULL) or
   Bit_union_count(NULL, t) > Bit_union_count(s,s) returns a copy of s


*/
extern int Bit_diff_count(T s, T t);  // difference of two bitsets
extern int Bit_inter_count(T s, T t); // intersection of two bitsets
extern int Bit_minus_count(T s, T t); // symmetric difference of two bitsets
extern int Bit_union_count(T s, T t); // union of two bitsets

/*
    BitDB operations on packed containers of bitsets

    Functions that create, free, load from an external buffer and obtain the properties of a packed  container of bitsets (a Bit Database, Bit_DB).
    Note the following error checking
    * BitDB_new          : Checked runtime error if length or size is less
                          than 0 or greater than INT_MAX.L.
    * BitDB_free         : It is a checked runtime error to try to free a Bit_DB
                          that was not allocated by the library.
    * BitDB_load         : Checked runtime error if length or size is less
                          than 0 or greater than INT_MAX. Also checks if buffer
                          is NULL
    * BitDB_length       : It is a checked runtime error to a non-positive
   length or a length greater than INT_MAX.
    * BitDB_nelem        : See footnote
    * BitDB_count_at     : See footnote; it is also a checked runtime error
                          to pass an index that is less than 0 or greater than
                          the number of bitsets in the container.
    * BitDB_count        : See footnote

    It is a checked runtime error to pass a NULL set to any of these routines.
*/
extern T_DB BitDB_new(int length, int num_of_bitsets);
extern T_DB BitDB_load(int length, int num_of_bitsets, void* buffer);
extern void* BitDB_free(T_DB* set);

/*
    Functions that return the properties of a Bit_DB container. 

*/
extern int BitDB_length(T_DB set);
extern int BitDB_nelem(T_DB set);
extern int BitDB_count_at(T_DB set, int index);
extern int* BitDB_count(T_DB set);
/*
    Functions that manipulate and obtain the contents of a packed
    container of bitsets (Bit_DB). One can use either Bits or externally
    allocated buffers. Note the following error checking:

    * BitDB_extract_from  : It is a checked runtime error to pass
                            a NULL buffer

    * BitDB_replace_at    : It is a checked runtime error to pass
                            a NULL buffer

    It is a checked runtime error to pass a NULL set, or an index that is
    less than 0 or greater than the number of bitsets in the container for
    any of these routines.
*/
extern T BitDB_get_from(T_DB set, int index);
extern void BitDB_put_at(T_DB set, int index, T bitset);
extern int BitDB_extract_from(T_DB set, int index, void* buffer);
extern void BitDB_replace_at(T_DB set, int index, void* buffer);
extern void BitDB_clear(T_DB set);
extern void BitDB_clear_at(T_DB set, int index);



/*
    Functions that perform SETOP counts between two packed containers
    of bitsets (Bit_DB). Note the following error checking:
    1. It is a checked runtime error to pass a NULL bits or bit, or if
    the two containers have different lengths. Note that this is
    contrast to the same functions for Bit_T which allow for one or more
    of the containers to be NULL.
    2. For the load functions, it is a checked runtime error to pass
    a NULL buffer.
*/

#define BitDB_inter_count(bit, bits, opts, TARGET)                             \
  BitDB_inter_count_##TARGET((bit), (bits), (opts))

#define BitDB_inter_count_store(bit, bits, opts, results, TARGET)              \
  BitDB_inter_count_store_##TARGET((bit), (bits), (opts), (results))

#define BitDB_union_count(bit, bits, opts, TARGET)                             \
  BitDB_union_count_##TARGET((bit), (bits), (opts))

#define BitDB_union_count_store(bit, bits, opts, results, TARGET)              \
  BitDB_union_count_store_##TARGET((bit), (bits), (opts), (results))

#define BitDB_diff_count(bit, bits, opts, TARGET)                              \
  BitDB_diff_count_##TARGET((bit), (bits), (opts))

#define BitDB_diff_count_store(bit, bits, opts, results, TARGET)               \
  BitDB_diff_count_store_##TARGET((bit), (bits), (opts), (results))

#define BitDB_minus_count(bit, bits, opts, TARGET)                             \
  BitDB_minus_count_##TARGET((bit), (bits), (opts))

#define BitDB_minus_count_store(bit, bits, opts, results, TARGET)              \
  BitDB_minus_count_store_##TARGET((bit), (bits), (opts), (results))

extern int* BitDB_inter_count_store_cpu(T_DB bit, T_DB bits, int* buffer,
    SETOP_COUNT_OPTS opts);
extern int* BitDB_inter_count_store_gpu(T_DB bit, T_DB bits, int* buffer,
    SETOP_COUNT_OPTS opts);
extern int* BitDB_inter_count_cpu(T_DB bit, T_DB bits, SETOP_COUNT_OPTS opts);
extern int* BitDB_inter_count_gpu(T_DB bit, T_DB bits, SETOP_COUNT_OPTS opts);

extern int* BitDB_union_count_store_cpu(T_DB bit, T_DB bits, int* buffer,
    SETOP_COUNT_OPTS opts);
extern int* BitDB_union_count_store_gpu(T_DB bit, T_DB bits, int* buffer,
    SETOP_COUNT_OPTS opts);
extern int* BitDB_union_count_cpu(T_DB bit, T_DB bits, SETOP_COUNT_OPTS opts);
extern int* BitDB_union_count_gpu(T_DB bit, T_DB bits, SETOP_COUNT_OPTS opts);

extern int* BitDB_diff_count_store_cpu(T_DB bit, T_DB bits, int* buffer,
    SETOP_COUNT_OPTS opts);
extern int* BitDB_diff_count_store_gpu(T_DB bit, T_DB bits, int* buffer,
    SETOP_COUNT_OPTS opts);
extern int* BitDB_diff_count_cpu(T_DB bit, T_DB bits, SETOP_COUNT_OPTS opts);
extern int* BitDB_diff_count_gpu(T_DB bit, T_DB bits, SETOP_COUNT_OPTS opts);

extern int* BitDB_minus_count_store_cpu(T_DB bit, T_DB bits, int* buffer,
    SETOP_COUNT_OPTS opts);
extern int* BitDB_minus_count_store_gpu(T_DB bit, T_DB bits, int* buffer,
    SETOP_COUNT_OPTS opts);
extern int* BitDB_minus_count_cpu(T_DB bit, T_DB bits, SETOP_COUNT_OPTS opts);
extern int* BitDB_minus_count_gpu(T_DB bit, T_DB bits, SETOP_COUNT_OPTS opts);


#undef T
#undef T_DB
#endif
