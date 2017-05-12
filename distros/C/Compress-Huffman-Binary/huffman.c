#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "huffman.h"

/* The following #include gets ntohl and htonl on Windows and
   Unix. ntohl and htonl are functions for converting uint32_t from
   network (n) to host (h) order. These are used for storing binary
   data on the disc in a system-independent way. */

#ifdef WIN32
#include <winsock2.h>
#else
#include <netinet/in.h>
#endif

#ifdef HEADER

#ifdef __GNUC__
#define UNUSED __attribute__ ((unused))
#define NOIGNORE __attribute__ ((warn_unused_result))
#else
#define UNUSED
#define NOIGNORE
#endif /* def __GNUC__ */

/* Return statuses of functions in this file. */

typedef enum 
{
    huffman_status_ok,
    huffman_status_memory_failure,
    huffman_status_null_pointer,
    huffman_status_bounds,
    huffman_status_read_error,
}
huffman_status_t;

#endif /* def HEADER */

#define CALL(x) {							\
	huffman_status_t rc;						\
	rc = x;								\
	if (rc != huffman_status_ok) {					\
	    fprintf (stderr, "%s:%d: %s failed with status %d.\n",	\
		     __FILE__, __LINE__, #x, rc);			\
	    return rc;							\
	}								\
    }

/* Count mallocs and frees. */

//#define MEMCOUNT

#ifdef MEMCOUNT
static int n_mallocs;
#define MEMCLEAR n_mallocs = 0
#define MEMPLUS n_mallocs++
#define MEMFREE n_mallocs--
#define MEMCHECK(expect) {				\
	if (n_mallocs != expect) {			\
	    fprintf (stderr, "%s:%d: n_mallocs = %d, "	\
		     "expected %d\n",			\
		     __FILE__, __LINE__,		\
		     n_mallocs, expect);		\
	}						\
    }
#else
#define MEMCLEAR
#define MEMPLUS
#define MEMFREE
#define MEMCHECK(expect)
#endif /* MEMCOUNT */

#define DEBUG

#ifdef DEBUG
#define MESSAGE(x) {				\
	printf ("%s:%d: ", __FILE__, __LINE__);	\
	printf x;				\
	puts ("\n");				\
    }
#else
#define MESSAGE(x)
#endif

/* Used to build the Huffman code. */

typedef struct huffman_node_tag
{
    struct huffman_node_tag *parent;

    union
    {
	struct
	{
	    struct huffman_node_tag *zero, *one;
	};
	unsigned int symbol;
    };
    /* Zero for a leaf node. */
    double count;
    /* One for a leaf node. */
    unsigned int is_leaf : 1;
}
huffman_node;

typedef struct huffman_code_tag
{
    /* The length of this code in bits. */
    unsigned long numbits;

    /* The bits that make up this code. The first
       bit is at position 0 in bits[0]. The second
       bit is at position 1 in bits[0]. The eighth
       bit is at position 7 in bits[0]. The ninth
       bit is at position 0 in bits[1]. */
    unsigned char *bits;
}
huffman_code;

/* Given "numbits" bits, return the minimum number of bytes necessary
   to hold that many bits. */

static unsigned long
numbytes_from_numbits (unsigned long numbits)
{
    return numbits / 8 + (numbits % 8 ? 1 : 0);
}

/*
 * get_bit returns the ith bit in the bits array
 * in the 0th position of the return value.
 */
static unsigned char
get_bit (unsigned char* bits, unsigned long i)
{
    return (bits[i / 8] >> i % 8) & 1;
}

/* Reverse "numbits" bits of "bits" in place. */

static huffman_status_t NOIGNORE
reverse_bits (unsigned char* bits, unsigned long numbits)
{
    unsigned long numbytes = numbytes_from_numbits (numbits);
    unsigned char *reverse;
    unsigned long curbit;
    long curbyte = 0;
	
    reverse = calloc (numbytes, sizeof (unsigned char));
    if (! reverse) {
	return huffman_status_memory_failure;
    }
    for (curbit = 0; curbit < numbits; curbit++) {
	unsigned int bitpos = curbit % 8;

	if (curbit > 0 && curbit % 8 == 0) {
	    curbyte++;
	}
	reverse[curbyte] |= (get_bit (bits, numbits - curbit - 1) << bitpos);
    }
    memcpy (bits, reverse, numbytes);
    free (reverse);
    return huffman_status_ok;
}

/*
 * new_code builds a huffman_code from a leaf in
 * a Huffman tree.
 */

/* Build the huffman code by walking up to the root node and then
  reversing the bits, since the Huffman code is calculated by walking
  down the tree. */

static huffman_status_t NOIGNORE
new_code (const huffman_node* leaf, huffman_code ** new_ptr)
{
    unsigned long numbits = 0;
    unsigned char * bits = NULL;
    /* Return value. */
    huffman_code *p;

    while (leaf && leaf->parent) {
	huffman_node *parent = leaf->parent;
	unsigned char cur_bit = (unsigned char)(numbits % 8);
	unsigned long cur_byte = numbits / 8;

	/* If we need another byte to hold the code,
	   then allocate it. */
	if (cur_bit == 0) {
	    size_t new_size = cur_byte + 1;
	    if (! bits) {
		MEMPLUS;
	    }
	    bits = realloc (bits, new_size);
	    if (! bits) {
		return huffman_status_memory_failure;
	    }
	    bits[new_size - 1] = 0; /* Initialize the new byte. */
	}

	/* If a one must be added then or it in. If a zero
	 * must be added then do nothing, since the byte
	 * was initialized to zero. */
	if (leaf == parent->one) {
	    bits[cur_byte] |= 1 << cur_bit;
	}
	numbits++;
	leaf = parent;
    }

    CALL (reverse_bits (bits, numbits));

    p = malloc (sizeof (huffman_code));
    if (! p) {
	return huffman_status_memory_failure;
    }
    MEMPLUS;
    p->numbits = numbits;
    p->bits = bits;
    * new_ptr = p;
    return huffman_status_ok;
}

/* The maximum number of symbols we allow. */

#define MAX_SYMBOLS 256

//typedef huffman_node* symbol_frequencies_t[MAX_SYMBOLS];
//typedef huffman_code* SymbolEncoder[MAX_SYMBOLS];
//typedef huffman_node** symbol_frequencies_t;

typedef struct symbol_frequencies
{
    int n_nodes;
    huffman_node ** nodes;
    int allocated;
}
symbol_frequencies_t;

typedef huffman_code** SymbolEncoder;

/* Make a new "huffman_node" associated with a symbol. */

static huffman_status_t
new_leaf_node (unsigned char symbol, huffman_node ** node_ptr)
{
    huffman_node *p;
    p = malloc (sizeof (huffman_node));
    if (! p) {
	return huffman_status_memory_failure;
    }
    MEMPLUS;
    p->is_leaf = 1;
    p->symbol = symbol;
    p->count = 0;
    p->parent = 0;
    * node_ptr = p;
    return huffman_status_ok;
}

/* Make a new "huffman_node" associated with two child nodes, "zero"
   and "one", without a symbol, but with count "count". */

static huffman_status_t
new_nonleaf_node (unsigned long count, huffman_node *zero, huffman_node *one,
		  huffman_node** new_ptr)
{
    huffman_node *p;
    p = malloc (sizeof (huffman_node));
    if (! p) {
	return huffman_status_memory_failure;
    }
    MEMPLUS;
    p->is_leaf = 0;
    p->count = count;
    p->zero = zero;
    p->one = one;
    p->parent = 0;
    * new_ptr = p;
    return huffman_status_ok;
}

/* Free the memory associated with "subtree". */

static huffman_status_t
free_huffman_tree (huffman_node *subtree)
{
    if (subtree == NULL) {
	return huffman_status_ok;
    }

    if (! subtree->is_leaf) {
	CALL (free_huffman_tree (subtree->zero));
	subtree->zero = 0;
	CALL (free_huffman_tree (subtree->one));
	subtree->one = 0;
    }
	
    free (subtree);
    MEMFREE;
    return huffman_status_ok;
}

static huffman_status_t
free_code (huffman_code* p)
{
    free (p->bits);
    MEMFREE;
    free (p);
    MEMFREE;
    return huffman_status_ok;
}

static huffman_status_t
free_encoder (SymbolEncoder se)
{
    unsigned long i;
    for (i = 0; i < MAX_SYMBOLS; i++) {
	huffman_code *p = se[i];
	if (p) {
	    CALL (free_code (p));
	}
    }
    free (se);
    MEMFREE;
    return huffman_status_ok;
}

static huffman_status_t NOIGNORE
init_frequencies (symbol_frequencies_t ** sf_ptr)
{
    symbol_frequencies_t * sf;
    sf = calloc (1, sizeof (struct symbol_frequencies));
    if (! sf) {
	return huffman_status_memory_failure;
    }
    // Initially, allocate this many nodes. This can be expanded later.
    sf->allocated = MAX_SYMBOLS;
    sf->nodes = calloc (sf->allocated,  sizeof (huffman_node *));
    if (! sf->nodes) {
	return huffman_status_memory_failure;
    }
    * sf_ptr = sf;
    return huffman_status_ok;
}

static huffman_status_t NOIGNORE
free_frequencies (symbol_frequencies_t * sf)
{
    free (sf->nodes);
    free (sf);
    return huffman_status_ok;
}

/* Store of Huffman output in memory. */

typedef struct buf_cache_tag
{
    unsigned char *cache;
    /* Allocated bytes in "cache". */
    unsigned int cache_len;
    /* Bytes used in "cache". */
    unsigned int cache_cur;
    /* Output. */
    unsigned char **pbufout;
    /* Length of output. */
    unsigned int *pbufoutlen;
}
buf_cache;

/* Initialize "pc" to "cache_size" of memory, and set the other
   variables to zero. */

static huffman_status_t NOIGNORE
init_cache (buf_cache* pc,
	    unsigned int cache_size,
	    unsigned char ** pbufout,
	    unsigned int * pbufoutlen)
{
    if (! pc || ! pbufout || ! pbufoutlen) {
	return huffman_status_null_pointer;
    }
	
    pc->cache = malloc (cache_size);
    if (! pc->cache) {
	return huffman_status_memory_failure;
    }
    MEMPLUS;
    pc->cache_len = cache_size;
    pc->cache_cur = 0;
    pc->pbufout = pbufout;
    *pbufout = NULL;
    pc->pbufoutlen = pbufoutlen;
    *pbufoutlen = 0;

    return huffman_status_ok;
}

static huffman_status_t
free_cache (buf_cache * pc)
{
    if (pc->cache) {
	free (pc->cache);
	MEMFREE;
	pc->cache = NULL;
    }
    return huffman_status_ok;
}

/* Copy the contents of pc->cache into *pc->bufout, adjusting the
   sizes etc. */

static huffman_status_t NOIGNORE
flush_cache (buf_cache* pc)
{
    if (! pc) {
	return huffman_status_null_pointer;
    }
	
    if (pc->cache_cur > 0) {
	unsigned int newlen = pc->cache_cur + *pc->pbufoutlen;
	unsigned char* tmp;
	if (! *pc->pbufout) {
	    MEMPLUS;
	}
	tmp = realloc (*pc->pbufout, newlen);
	if (! tmp) {
	    return huffman_status_memory_failure;
	}

	memcpy (tmp + *pc->pbufoutlen, pc->cache, pc->cache_cur);

	*pc->pbufout = tmp;
	*pc->pbufoutlen = newlen;
	pc->cache_cur = 0;
    }

    return huffman_status_ok;
}

/* Write "to_write_len" bytes from "to_write" into the cache "pc". */

static huffman_status_t NOIGNORE
write_cache (buf_cache * pc,
	     const void *to_write,
	     unsigned int to_write_len)
{
    unsigned char* tmp;

    if (! pc || ! to_write) {
	return huffman_status_null_pointer;
    }
    if (pc->cache_len < pc->cache_cur) {
	return huffman_status_bounds;
    }
	
    /* If trying to write more than the cache will hold,
     * flush the cache and allocate enough space immediately,
     * that is, don't use the cache. */

    if (to_write_len > pc->cache_len - pc->cache_cur) {
	unsigned int newlen;
	CALL (flush_cache (pc));
	newlen = *pc->pbufoutlen + to_write_len;
	if (! *pc->pbufout) {
	    MEMPLUS;
	}
	tmp = realloc (*pc->pbufout, newlen);
	if (! tmp) {
	    return huffman_status_memory_failure;
	}

	memcpy (tmp + *pc->pbufoutlen, to_write, to_write_len);
	*pc->pbufout = tmp;
	*pc->pbufoutlen = newlen;
    }
    else {
	/* Write the data to the cache. */
	memcpy (pc->cache + pc->cache_cur, to_write, to_write_len);
	pc->cache_cur += to_write_len;
    }

    return huffman_status_ok;
}

static huffman_status_t NOIGNORE
symbol_frequencies_expand (symbol_frequencies_t * sf)
{
    sf->allocated *= 2;
    sf->nodes = realloc (sf->nodes, sf->allocated);
    if (! sf->nodes) {
	return huffman_status_memory_failure;
    }
    return huffman_status_ok;
}

#define UNASSIGNED -1

static huffman_status_t NOIGNORE
get_symbol_frequencies_from_memory (symbol_frequencies_t * sf,
				    const unsigned char *bufin,
				    unsigned int bufinlen,
				    unsigned int * total_count_ptr)
{
    unsigned int i;
    unsigned int total_count = 0;
    int char_to_node[MAX_SYMBOLS];
    unsigned int n_nodes;
    for (i = 0; i < MAX_SYMBOLS; i++) {
	char_to_node[i] = UNASSIGNED;
    }
    n_nodes = 0;
    /* Count the frequency of each symbol in the input file. */
    for (i = 0; i < bufinlen; i++) {
	unsigned char uc = bufin[i];
	if (char_to_node[uc] == UNASSIGNED) {
	    CALL (new_leaf_node (uc, & sf->nodes[n_nodes]));
	    char_to_node[uc] = n_nodes;
	    n_nodes++;
	    if (n_nodes > sf->allocated) {
		CALL (symbol_frequencies_expand (sf));
	    }
	}
	if (char_to_node[uc] < 0 || char_to_node[uc] >= n_nodes) {
	    return huffman_status_bounds;
	}
	sf->nodes[char_to_node[uc]]->count++;
	total_count++;
    }
    sf->n_nodes = n_nodes;
    * total_count_ptr = total_count;
    return huffman_status_ok;
}

/*
  compare symbol table entries p1 and p2.

 * When used by qsort, SFComp sorts the array so that
 * the symbol with the lowest frequency is first. Any
 * NULL entries will be sorted to the end of the list.
 */

static int
SFComp (const void *p1, const void *p2)
{
    const huffman_node *hn1 = *(const huffman_node**)p1;
    const huffman_node *hn2 = *(const huffman_node**)p2;

    /* Sort all NULLs to the end. */
    if (hn1 == NULL && hn2 == NULL) {
	return 0;
    }
    if (hn1 == NULL) {
	return 1;
    }
    if (hn2 == NULL) {
	return -1;
    }
    if (hn1->count > hn2->count) {
	return 1;
    }
    else if (hn1->count < hn2->count) {
	return -1;
    }
    return 0;
}

static void UNUSED
print_freqs (const symbol_frequencies_t * sf)
{
    size_t i;
    for (i = 0; i < sf->n_nodes; i++) {
	if (sf->nodes[i]) {
	    printf ("%d, %g\n", sf->nodes[i]->symbol, sf->nodes[i]->count);
	}
	else {
	    printf ("NULL\n");
	}
    }
}

/*
  "build_symbol_encoder" builds a "SymbolEncoder" by walking down to
  the leaves of the Huffman tree and then, for each leaf, determining
  its code.
 */

static huffman_status_t NOIGNORE
build_symbol_encoder (huffman_node *subtree, SymbolEncoder se)
{
    if (subtree == NULL) {
	return huffman_status_null_pointer;
    }
    if (subtree->is_leaf) {
	CALL (new_code (subtree, & se[subtree->symbol]));
    }
    else {
	CALL (build_symbol_encoder (subtree->zero, se));
	CALL (build_symbol_encoder (subtree->one, se));
    }
    return huffman_status_ok;
}

/*
 * calculate_huffman_codes turns sf_ptr into an array
 * with a single entry that is the root of the
 * huffman tree. The return value is a SymbolEncoder,
 * which is an array of huffman codes index by symbol value.
 */

static huffman_status_t
calculate_huffman_codes (symbol_frequencies_t * sf, SymbolEncoder * se_ptr)
{
    unsigned int i = 0;
    unsigned int n = 0;
    huffman_node *m1 = NULL, *m2 = NULL;
    SymbolEncoder se;
#if 0
    printf ("BEFORE SORT\n");
    print_freqs (sf);
#endif /* 0 */

    /* Sort the symbol frequency array by ascending frequency. */
    qsort (sf->nodes, sf->n_nodes, sizeof (* sf->nodes), SFComp);

#if 0
    printf ("AFTER SORT\n");
    print_freqs (sf);
#endif /* 0 */

    /* Get the number of symbols. */
    for (n = 0; n < MAX_SYMBOLS && sf->nodes[n]; n++) {
	;
    }

    /*
      Construct a Huffman tree. This code is based on the algorithm
      given in Managing Gigabytes by Ian Witten et al, 2nd edition,
      page 34.  This implementation uses a simple count instead of
      probability.
     */
    for (i = 0; i < n - 1; i++) {
	huffman_node * new;
	/* Set m1 and m2 to the two subsets of least probability. */
	m1 = sf->nodes[0];
	m2 = sf->nodes[1];

	/* Replace m1 and m2 with a set {m1, m2} whose probability
	 * is the sum of that of m1 and m2. */
	CALL (new_nonleaf_node (m1->count + m2->count, m1, m2, & new));
	sf->nodes[0] = m1->parent = m2->parent = new;
	sf->nodes[1] = NULL;
		
	/* Put newSet into the correct count position. */
	qsort (sf->nodes, n, sizeof (huffman_node *), SFComp);
    }

    /* Build the SymbolEncoder array from the tree. */
    se = calloc (MAX_SYMBOLS, sizeof (huffman_code *));
    if (! se) {
	return 0;
    }
    MEMPLUS;
    CALL (build_symbol_encoder (sf->nodes[0], se));
    * se_ptr = se;
    return huffman_status_ok;
}

/*
 * Write the huffman code table. The format is:
 * 4 byte code count in network byte order.
 * 4 byte number of bytes encoded
 *   (if you decode the data, you should get this number of bytes)
 * code1
 * ...
 * codeN, where N is the count read at the begginning of the file.
 * Each codeI has the following format:
 * 1 byte symbol, 1 byte code bit length, code bytes.
 * Each entry has numbytes_from_numbits code bytes.
 * The last byte of each code may have extra bits, if the number of
 * bits in the code is not a multiple of 8.
 */
/*
 * Allocates memory and sets *pbufout to point to it. The memory
 * contains the code table.
 */
static huffman_status_t NOIGNORE
write_code_table_to_memory (buf_cache * pc,
			    SymbolEncoder se,
			    uint32_t symbol_count)
{
    uint32_t i;
    uint32_t count = 0;

    /* Determine the number of entries in se. */
    for (i = 0; i < MAX_SYMBOLS; i++) {
	if (se[i]) {
	    count++;
	}
    }

    /* Write the number of entries in network byte order. */
    i = htonl (count);
    CALL (write_cache (pc, &i, sizeof (i)));
    /* Write the number of bytes that will be encoded. */
    symbol_count = htonl (symbol_count);
    CALL (write_cache (pc, &symbol_count, sizeof (symbol_count)));

    /* Write the entries. */
    for (i = 0; i < MAX_SYMBOLS; i++) {
	huffman_code *p = se[i];
	if (p) {
	    unsigned int numbytes;
	    /* The value of i is < MAX_SYMBOLS (256), so it can
	       be stored in an unsigned char. */
	    unsigned char uc = (unsigned char)i;
	    /* Write the 1 byte symbol. */
	    CALL (write_cache (pc, &uc, sizeof (uc)));
	    /* Write the 1 byte code bit length. */
	    uc = (unsigned char)p->numbits;
	    CALL (write_cache (pc, &uc, sizeof (uc)));
	    /* Write the code bytes. */
	    numbytes = numbytes_from_numbits (p->numbits);
	    CALL (write_cache (pc, p->bits, numbytes));
	}
    }
    return huffman_status_ok;
}

/* Put "readlen" bytes of "buf + *pindex" into "*bufout", checking
   that "readlen" does not overflow the end of "buf" at "buflen". */

static huffman_status_t NOIGNORE
memread (const unsigned char* buf,
	 unsigned int buflen,
	 unsigned int *pindex,
	 void* bufout,
	 unsigned int readlen)
{
    if (! buf || ! pindex || ! bufout) {
	return huffman_status_null_pointer;
    }
    if (buflen < *pindex) {
	return huffman_status_bounds;
    }

    if (readlen + *pindex >= buflen) {
	return huffman_status_bounds;
    }

    memcpy (bufout, buf + *pindex, readlen);
    *pindex += readlen;
    return huffman_status_ok;
}

/* "pindex" is the offset into bufin. */

static huffman_status_t
read_code_table_from_memory (const unsigned char* bufin,
			     unsigned int bufinlen,
			     unsigned int *pindex,
			     uint32_t *pDataBytes,
			     huffman_node**root_ptr)
{
    huffman_node *root;
    uint32_t count;

    CALL (new_nonleaf_node (0, NULL, NULL, & root));
	
    /* Read the number of entries.
       (it is stored in network byte order). */
    CALL (memread (bufin, bufinlen, pindex, &count, sizeof (count)));
    count = ntohl (count);

    /* Read the number of data bytes this encoding represents. */
    CALL (memread (bufin, bufinlen, pindex, pDataBytes, sizeof (*pDataBytes)));

    *pDataBytes = ntohl (*pDataBytes);

    /* Read the entries. */
    while (count-- > 0) {
	unsigned int curbit;
	unsigned char symbol;
	unsigned char numbits;
	unsigned char numbytes;
	unsigned char *bytes;
	huffman_node *p = root;

	CALL (memread (bufin, bufinlen, pindex, &symbol, sizeof (symbol)));
	CALL (memread (bufin, bufinlen, pindex, &numbits, sizeof (numbits)));
		
	numbytes = (unsigned char) numbytes_from_numbits (numbits);
	bytes = malloc (numbytes);
	if (! bytes) {
	    return huffman_status_memory_failure;
	}
	MEMPLUS;
	CALL (memread (bufin, bufinlen, pindex, bytes, numbytes));

	/*
	 * Add the entry to the Huffman tree. The value of the current
	 * bit is used to switch between zero and one child nodes in
	 * the tree. New nodes are added as needed in the tree.
	 */
	for (curbit = 0; curbit < numbits; curbit++) {
	    if (get_bit (bytes, curbit)) {
		if (p->one == NULL) {
		    if (curbit == (unsigned char)(numbits - 1)) {
			CALL (new_leaf_node (symbol, & p->one));
		    }
		    else {
			CALL (new_nonleaf_node (0, NULL, NULL, & p->one));
		    }
		    p->one->parent = p;
		}
		p = p->one;
	    }
	    else {
		if (p->zero == NULL) {
		    if (curbit == (unsigned char)(numbits - 1)) {
			CALL (new_leaf_node (symbol, & p->zero));
		    }
		    else {
			CALL (new_nonleaf_node (0, NULL, NULL, & p->zero));
		    }
		    p->zero->parent = p;
		}
		p = p->zero;
	    }
	}
		
	free (bytes);
	MEMFREE;
    }

    * root_ptr = root;
    return huffman_status_ok;
}

/* Encode the memory in "bufin" into "pc" using "se" for the Huffman
   codes. */

static int
do_memory_encode (buf_cache *pc,
		  const unsigned char* bufin,
		  unsigned int bufinlen,
		  SymbolEncoder se)
{
    unsigned char curbyte = 0;
    unsigned char curbit = 0;
    unsigned int i;
    huffman_status_t rc;

    for (i = 0; i < bufinlen; i++) {
	unsigned char uc = bufin[i];
	huffman_code *code = se[uc];
	unsigned long j;
		
	for (j = 0; j < code->numbits; j++) {
	    /* Add the current bit to curbyte. */
	    curbyte |= get_bit (code->bits, j) << curbit;

	    /* If this byte is filled up then write it
	     * out and reset the curbit and curbyte. */
	    curbit++;
	    if (curbit == 8) {
		rc = write_cache (pc, &curbyte, sizeof (curbyte));
		if (rc != huffman_status_ok) {
		    return rc;
		}
		curbyte = 0;
		curbit = 0;
	    }
	}
    }

    /*
     * If there is data in curbyte that has not been
     * output yet, which means that the last encoded
     * character did not fall on a byte boundary,
     * then output it.
     */
    if (curbit > 0) {
	rc = write_cache (pc, &curbyte, sizeof (curbyte));
	if (rc != huffman_status_ok) {
	    return rc;
	}
    }
    return huffman_status_ok;
}

#define CACHE_SIZE 1024

huffman_status_t NOIGNORE
huffman_encode_memory (const unsigned char *bufin,
		       unsigned int bufinlen,
		       unsigned char **pbufout,
		       unsigned int *pbufoutlen)
{
    symbol_frequencies_t * sf;
    SymbolEncoder se;
    huffman_node *root = NULL;
    unsigned int symbol_count;
    buf_cache cache;

    MEMCLEAR;
    /* Ensure the arguments are valid. */
    if (! pbufout || ! pbufoutlen) {
	return huffman_status_null_pointer;
    }

    CALL (init_cache (&cache, CACHE_SIZE, pbufout, pbufoutlen));
    /* Allocate memory for sf and set all its frequencies to 0. */
    CALL (init_frequencies (& sf));
    /* Get the frequency of each symbol in the input memory. */
    CALL (get_symbol_frequencies_from_memory (sf, bufin, bufinlen,
					     & symbol_count));

    /* Build an optimal table from the symbolCount. */
    CALL (calculate_huffman_codes (sf, & se));
    root = sf->nodes[0];

    /* Scan the memory again and, using the table
       previously built, encode it into the output memory. */
    CALL (write_code_table_to_memory (& cache, se, symbol_count));
    CALL (do_memory_encode (& cache, bufin, bufinlen, se));
    /* Flush the cache. */
    CALL (flush_cache (& cache));
    /* Free the Huffman tree. */
    CALL (free_huffman_tree (root));
    CALL (free_encoder (se));
    CALL (free_cache (& cache));
    CALL (free_frequencies (sf));
    MEMCHECK (1);
    return huffman_status_ok;
}

huffman_status_t NOIGNORE
huffman_decode_memory (const unsigned char *bufin,
		       unsigned int bufinlen,
		       unsigned char **pbufout,
		       unsigned int *pbufoutlen)
{
    huffman_node *root, *p;
    unsigned int data_count;
    unsigned int i = 0;
    unsigned char *buf;
    unsigned int bufcur = 0;

    MEMCLEAR;
    /* Ensure the arguments are valid. */
    if (! pbufout || ! pbufoutlen) {
	return huffman_status_null_pointer;
    }

    /* Read the Huffman code table. */
    CALL (read_code_table_from_memory (bufin, bufinlen, &i, &data_count,
				       & root));
    buf = malloc (data_count);
    if (! buf) {
	return huffman_status_memory_failure;
    }
    MEMPLUS;
    /* Decode the memory. */
    p = root;
    for (; i < bufinlen && data_count > 0; i++)  {
	unsigned char byte = bufin[i];
	// Bit mask
	unsigned char mask = 1;
	while (data_count > 0 && mask) {
	    p = byte & mask ? p->one : p->zero;
	    mask <<= 1;

	    if (p->is_leaf) {
		buf[bufcur] = p->symbol;
		bufcur++;
		p = root;
		data_count--;
	    }
	}
    }

    CALL (free_huffman_tree (root));
    *pbufout = buf;
    *pbufoutlen = bufcur;
    MEMCHECK (1);
    return huffman_status_ok;
}
