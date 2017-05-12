#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "bitlist.h"
#include "sequences.h"


/********************  bit stack functions  ********************/

#define BIT_STACK_SIZE 32

/* Combining writes when possible saves time.  If done in the push, it also
 * means our stack is limited by number of bits instead of number of pushes.
 * This does a simple opportunistic combination instead of filling each word.
 * Min bits possible in stack:  ((BITS_PER_WORD/2)+1) * (BIT_STACK_SIZE+1)
 */
#define MAKE_BITSTACK \
  int   bs_p = 0; \
  int   bs_top_bits = 0; \
  WTYPE bs_top_val = W_ZERO; \
  int   bs_stack_b[BIT_STACK_SIZE]; \
  WTYPE bs_stack_v[BIT_STACK_SIZE];

#define PUSH_BITSTACK(bits, value) \
  { int b_ = bits; \
    WTYPE v_ = (value) & (W_FFFF >> (BITS_PER_WORD - b_)); \
    if ((bs_top_bits + b_) <= BITS_PER_WORD) { \
      bs_top_val |= (v_ << bs_top_bits); \
      bs_top_bits += b_; \
    } else { \
      assert(bs_p < BIT_STACK_SIZE); \
      bs_stack_b[bs_p] = bs_top_bits; \
      bs_stack_v[bs_p] = bs_top_val; \
      bs_p++; \
      bs_top_bits = b_; \
      bs_top_val = v_; \
    } \
  }
#define WRITE_BITSTACK(list) \
  if (bs_top_bits > 0) { \
    swrite(list, bs_top_bits, bs_top_val); \
    while (bs_p-- > 0) \
      swrite(list, bs_stack_b[bs_p], bs_stack_v[bs_p]); \
  }


/********************  how to grow list  ********************/
static void expand_list(BitList *list, int len)
{
  if ( len > list->maxlen )
    resize(list, 1.10 * (len+4096) );
}


/********************  debugging  ********************/
#if 0
static char binstr[BITS_PER_WORD+1];
static char* word_to_bin(WTYPE word)
{
  int i;
  for (i = 0; i < BITS_PER_WORD; i++) {
    WTYPE bit = (word >> (MAXBIT-i)) & 1;
    binstr[i] = (bit == 0) ? '0' : '1';
  }
  binstr[BITS_PER_WORD] = '\0';
  return binstr;
}
#endif

/********************  dealing with sub calls  ********************/

static WTYPE call_get_sub(SV* self, SV* code, BitList* list)
{
  dSP;                               /* Local copy of stack pointer         */
  int count;
  WTYPE v;

  ENTER;                             /* Start wrapper                       */
  SAVETMPS;                          /* Start (2)                           */

  PUSHMARK(SP);                      /* Start args: note our SP             */
  XPUSHs(self);                      /*    our stream                       */
  PUTBACK;                           /* End args:   set global SP to ours   */

  count = call_sv(code, G_SCALAR);   /* Call the sub                        */
  SPAGAIN;                           /* refresh local stack pointer         */

  if (count != 1)
    croak("get sub should return one value");

  v = POPu;                          /* Get the returned value              */

  /* TODO:
   *   Something isn't right here -- the stack is messed up if I do the
   *   PUTBACK, but skipping it is wrong.
   */
#if 0
  PUTBACK;                           /* let global SP know what we did      */
#endif
  FREETMPS;                          /* End wrapper                         */
  LEAVE;                             /* End (2)                             */
  return v;
}

static void call_put_sub(SV* self, SV* code, BitList* list, WTYPE value)
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(self);
  XPUSHs(sv_2mortal(newSVuv(value)));
  PUTBACK;

  (void) call_sv(code, G_VOID);
  SPAGAIN;

  PUTBACK;
  FREETMPS;
  LEAVE;
}


/********************  BitList basics  ********************/

BitList *new(
  FileMode    mode,
  const char* file,
  const char* fheaderdata,
  int         fheaderlines,
  int         initial_bits
)
{
  BitList* list;
  New(0, list, 1, BitList);

  list->data = 0;
  list->pos = 0;
  list->len = 0;
  list->maxlen = 0;

  list->mode = mode;
  list->file = file;
  list->file_header = (fheaderdata == 0)  ?  0  :  strdup(fheaderdata);
  list->file_header_lines = fheaderlines;

  list->is_writing = 0;
  switch (list->mode) {
    case eModeR:
    case eModeRO:
    case eModeA:    list->is_writing = 0;  break;
    case eModeW:
    case eModeWO:
    case eModeRW:   list->is_writing = 1;  break;
    default:        assert(0);
  }

  if (list->is_writing)
    write_open(list);
  else
    read_open(list);

  if (list->mode == eModeA)
    write_open(list);

  if (initial_bits > 0)
    (void) resize(list, initial_bits);

  return list;
}

int resize(BitList *list, int bits)
{
  assert(bits >= 0);
  if (bits == 0) {
    /* erase everything */
    if (list->data != 0) {
      Safefree(list->data);
      list->data = 0;
    }
  } else {
    /* Grow or shrink */
    int oldwords = NWORDS(list->maxlen);
    int newwords = NWORDS(bits);
    Renew(list->data, newwords, WTYPE);
    if (newwords > oldwords) {
      /* Zero out any new allocated space */
      memset( list->data + oldwords,  0,  (newwords-oldwords)*sizeof(WTYPE) );
    }
    list->maxlen = bits;
  }
  if (list->data == 0) {
    list->maxlen = 0;
    list->len = 0;
    list->pos = 0;
  }
  return list->maxlen;
}

void DESTROY(BitList *list)
{
  if (list == 0) {
    croak("null object");
  } else {
    if (list->is_writing)        write_close(list);
    if (list->data != 0)         Safefree(list->data);
    if (list->file_header != 0)  Safefree(list->file_header);
    Safefree(list);
  }
}

void dump(BitList *list)
{
  int words = NWORDS(list->len);
  int i;
  for (i = 0; i < words; i++) {
    fprintf(stderr, "%2d %08lx\n", i, list->data[i]);
  }
}

int _set_len(BitList *list, int newlen)
{
  if ( (newlen < 0) || (newlen > list->maxlen) )
    croak("invalid length: %d", newlen);
  else
    list->len = newlen;
  return list->len;
}
int _set_pos(BitList *list, int newpos)
{
  assert(list != 0);
  if ( (newpos < 0) || (newpos > list->len) )
    croak("invalid position: %d", newpos);
  else
    list->pos = newpos;
  return list->pos;
}


/********************  BitList file i/o  ********************/

void read_open(BitList *list)
{
  if (list->mode == eModeWO) {
    croak("read while stream opened writeonly");
    return;
  }
  if (list->is_writing)
    write_close(list);
  if (list->file != 0) {
    unsigned long bits;
    FILE* fh = fopen(list->file, "r");
    if (!fh) {
      croak("Cannot open file '%s' for read", list->file);
      return;
    }
    /* Read in their header lines.  This is hacky. */
    if (list->file_header_lines > 0) {
      int hline;
      int maxbytes = 1024 * list->file_header_lines;
      int nbytes = 0;
      char *hbuf, *hptr;

      New(0, hbuf, maxbytes, char);
      for (hline = 0, hptr = hbuf; hline < list->file_header_lines; hline++) {
        char* fresult;
        int len;
        if (nbytes >= maxbytes) {
          croak("Overflow reading header line %d/%d", hline, list->file_header_lines);
          fclose(fh);
          return;
        }
        fresult = fgets(hptr, maxbytes - nbytes, fh);
        len = strlen(hptr);
        if ( !fresult || feof(fh) || (len == 0) || (hptr[len-1] != '\n') ) {
          croak("Error reading header line %d/%d", hline, list->file_header_lines);
          fclose(fh);
          return;
        }
        hptr += len;
        nbytes += len;
      }
      Renew(hbuf, nbytes+1, char);
      if (list->file_header != 0)
        Safefree( (void*) list->file_header );
      list->file_header = hbuf;
    }
    /* Read the number of bits */
    if (fscanf(fh, "%lu\n", &bits) != 1) {
      croak("Cannot read number of bits from file");
      fclose(fh);
      return;
    }
    /* Read data */
    list->pos = 0;
    list->len = 0;
    {
      size_t total_bytes = 0;
      char* buf;
      New(0, buf, 16384, char);
      while (!feof(fh)) {
        char* bptr = buf;
        size_t bytes = fread(buf, sizeof(char), 16384, fh);
        total_bytes += bytes;
        while (bytes-- > 0) {
          swrite(list, 8, *bptr++);
        }
      }
      Safefree(buf);
      if (total_bytes != NBYTES(bits)) {
        croak("Read %d bytes, expected %lu", total_bytes, NBYTES(bits));
        fclose(fh);
        return;
      }
      list->len = bits;
    }
    fclose(fh);
  }
  assert(list->is_writing == 0);
}

void write_open(BitList *list)
{
  if (list->mode == eModeRO) {
    croak("write while stream opened readonly");
    return;
  }
  if (!list->is_writing) {
    list->is_writing = 1;
  }
  assert(list->is_writing == 1);
}

void write_close(BitList *list)
{
  if (list->is_writing) {
    if (list->file != 0) {
      FILE* fh;
      char* buf = to_raw(list);
      if (buf == 0)
        return;
      fh = fopen(list->file, "w");
      if (!fh) {
        croak("Cannot open file '%s' for write", list->file);
      } else {
        if (list->file_header != 0)
          fprintf(fh, "%s\n", list->file_header);
        fprintf(fh, "%d\n", list->len);
        fwrite(buf, 1, NBYTES(list->len), fh);
      }
      Safefree(buf);
      fclose(fh);
    }
    list->is_writing = 0;
    list->pos = list->len;
  }
  assert(list->is_writing == 0);
}


/********************  BitList read/write  ********************/

WTYPE sread(BitList *list, int bits)
{
  WTYPE v;
  int wpos, bpos, wlen;

  if ( (bits <= 0) || (bits > BITS_PER_WORD) ) {
    croak("invalid parameters: bits %d must be 1-%d", bits, (int)BITS_PER_WORD);
    return W_ZERO;
  }
  if ( (list->pos + bits) > list->len ) {
    croak("read off end of stream");
    return W_ZERO;
  }
#if 0
  WTYPE v = sreadahead(list, bits);
#else
  wpos = list->pos / BITS_PER_WORD;
  bpos = list->pos % BITS_PER_WORD;
  wlen = BITS_PER_WORD - bits;

  if (bpos <= wlen) {  /* single-word read */
    v = (list->data[wpos] >> (wlen-bpos)) & (W_FFFF >> wlen);
  } else {             /* double-word read */
    int bits1 = BITS_PER_WORD - bpos;
    int bits2 = bits - bits1;
    v =   ( (list->data[wpos+0] & (W_FFFF >> bpos)) << bits2 )
        | ( list->data[wpos+1] >> (BITS_PER_WORD - bits2) );
  }
#endif
  list->pos += bits;
  return v;
}

WTYPE sreadahead(BitList *list, int bits)
{
  WTYPE v = 0;
  int pos = list->pos;
  int shift, wpos, bpos, wlen;

  if ( (bits <= 0) || (bits > BITS_PER_WORD) ) {
    croak("invalid parameters: bits %d must be 1-%d", bits, (int)BITS_PER_WORD);
    return W_ZERO;
  }

  /* Readahead can read past the end of the data, and requires that we fill
   * in with zeros.  We could force the data to always have BITS_PER_WORD of
   * empty space, or we can shift things here. */
  shift = (pos+bits) - list->len;

  if (shift > 0) {
    bits -= shift;
  }

  wpos = pos / BITS_PER_WORD;
  bpos = pos % BITS_PER_WORD;
  wlen = BITS_PER_WORD - bits;

  if (bpos <= wlen) {  /* single-word read */
    v = (list->data[wpos] >> (wlen-bpos)) & (W_FFFF >> wlen);
  } else {             /* double-word read */
    int bits1 = BITS_PER_WORD - bpos;
    int bits2 = bits - bits1;
    v =   ( (list->data[wpos+0] & (W_FFFF >> bpos)) << bits2 )
        | ( list->data[wpos+1] >> (BITS_PER_WORD - bits2) );
  }

  if (shift > 0) {
    v <<= shift;
  }

  return v;
}

void swrite(BitList *list, int bits, WTYPE value)
{
  int len = list->len;
  int wpos, bpos, wlen;

  if (bits <= 0) {
    croak("invalid parameters: bits %d must be > 0", bits);
    return;
  }

  /* expand the data if necessary */
  expand_list(list, len+bits);

  if (value == 0) {
    list->len += bits;
    return;
  } else if (value == W_ONE) {
    len += bits-1;
    bits = 1;
  }

  /* We allowed writing 0 and 1 with any number of positive bits. */
  if (bits > BITS_PER_WORD) {
    croak("invalid parameters: bits %d must be 1-%d", bits, (int)BITS_PER_WORD);
    return;
  }

  /* mask value if needed */
  if (bits < BITS_PER_WORD) {
    value &= (W_FFFF >> (BITS_PER_WORD - bits));
    assert(value < (W_ONE << bits));
  }

#if 0
  /* Simple write */
  while (bits > 0) {
    int wpos = len / BITS_PER_WORD;
    int bpos = len % BITS_PER_WORD;
    WTYPE* wptr = list->data + wpos;
    WTYPE bit = (value >> (bits-1)) & 1;
    *wptr |= (bit << ( MAXBIT - bpos));
    /* fprintf(stderr, "w%3d/%2d=%d [%s]\n", wpos, (BITS_PER_WORD-1) - bpos, bit, word_to_bin(*wptr)); */
    bits--;
    len++;
  }
  list->len = len;
  return;
#endif

  wpos = len / BITS_PER_WORD;
  bpos = len % BITS_PER_WORD;
  wlen = BITS_PER_WORD - bits;

  if (bpos <= wlen) {  /* single-word write */
    list->data[wpos] |= (value & (W_FFFF >> wlen)) << (wlen-bpos);
  } else {             /* double-word write */
    int first_bits = BITS_PER_WORD - bpos;
    wlen           = BITS_PER_WORD - (bits - first_bits);
    list->data[wpos++] |=  value >> (bits - first_bits);
    list->data[wpos] |= (value & (W_FFFF >> wlen)) << (wlen-0);
  }

  list->len = len + bits;
}


/********************  BitList basic put/get  ********************/

void put_string(BitList *list, const char* s)
{
  /* Write words.  Reasonably fast. */
  WTYPE word;
  int bits;

  assert( (list != 0) && (s != 0) );
  while (*s != '\0') {
    word = 0;
    for (bits = 0;  (*s != 0) && (bits < BITS_PER_WORD);  bits++, s++) {
      word = (word << 1) | (*s != '0');
    }
    assert(bits > 0);
    swrite(list, bits, word);
  }
}

#if 0
static int  str_map_init = 0;
static char str_map[256][8];
#endif

char* read_string(BitList *list, int bits)
{
  char* buf;
  int pos = list->pos;
  assert(bits >= 0);
  assert( list->pos < list->len );
  assert (bits <= (list->len - list->pos));
  New(0, buf, bits+1, char);
#if 0
  /* Simple code */
  int b;
  for (b = 0; b < bits; b++) {
    int wpos = pos / BITS_PER_WORD;
    int bpos = pos % BITS_PER_WORD;
    if ( ((list->data[wpos] << bpos) & (W_ONE << MAXBIT)) == 0 )
      buf[b] = '0';
    else
      buf[b] = '1';
    pos++;
  }
  list->pos = pos;
#endif
#if 1
  {
    /* Much better, but could still be sped up. */
    int wpos = pos / BITS_PER_WORD;
    int bpos = pos % BITS_PER_WORD;
    WTYPE word = list->data[wpos] << bpos;
    char*  bptr = buf;
    int b = bits;
    while (b-- > 0) {
      *bptr++ = ((word & (W_ONE << MAXBIT)) == 0) ? '0' : '1';
      word <<= 1;
      if (++bpos >= BITS_PER_WORD) {
        word = list->data[++wpos];
        bpos = 0;
        while (b >= BITS_PER_WORD) {
          if (word == W_ZERO) {
            memset(bptr, '0', BITS_PER_WORD);
            bptr += BITS_PER_WORD;
            b -= BITS_PER_WORD;
            word = list->data[++wpos];
          } else if (word == W_FFFF) {
            memset(bptr, '1', BITS_PER_WORD);
            bptr += BITS_PER_WORD;
            b -= BITS_PER_WORD;
            word = list->data[++wpos];
          } else {
            break;
          }
        }
      }
    }
    list->pos = pos + bits;
  }
#endif
  buf[bits] = '\0';
  return buf;
}

char* to_raw(BitList *list)
{
  int bytes = NBYTES(list->len);
  char* buf;
  New(0, buf, bytes, char);
  if (buf != 0) {
    char* bptr = buf;
    int b;
    list->pos = 0;
    for (b = 0; b < bytes; b++) {
      *bptr++ = sreadahead(list, 8);
      list->pos += 8;
    }
  }
  return buf;
}
void put_raw(BitList *list, const char* str, int bits)
{
  const char* bptr = str;
  int bytes = bits / 8;
  if ( (str == 0) || (bits < 0) ) {
    croak("invalid input to put_raw");
    return;
  }
  while (bytes-- > 0) {
    swrite(list, 8, *bptr++);
  }
  bits = bits % 8;
  if (bits > 0) {
    int val = (*bptr & 0xFF) >> (8-bits);
    swrite(list, bits, val);
  }
}
void from_raw(BitList *list, const char* str, int bits)
{
  if ( (str == 0) || (bits < 0) ) {
    croak("invalid input to from_raw");
    return;
  }
  resize(list, bits);
  if (bits > 0) {
    int bytes = NBYTES(bits);
    const char* bptr = str;
    list->pos = 0;
    list->len = 0;
    while (bytes-- > 0) {
      swrite(list, 8, *bptr++);
    }
    list->len = bits;
  }
}

void _xput_stream (BitList *list, BitList *src)
{
  if (src->len <= 0)
    return;

  /* rewind_for_read(src) */
  if (src->is_writing)
    write_close(src);
  src->pos = 0;

  assert(list->is_writing);
  assert(!src->is_writing);

  expand_list(list, list->len + src->len);

  if (list->len == 0) {
    /* Copy direct.  Must copy whole words. */
    memcpy(list->data, src->data, sizeof(WTYPE) * NWORDS(src->len));
    list->len = src->len;
    src->pos = src->len;
  } else {
    /* sread/swrite */
    int bits = src->len;
    while (bits >= BITS_PER_WORD) {
      swrite(list, BITS_PER_WORD,  sread(src, BITS_PER_WORD)  );
      bits -= BITS_PER_WORD;
    }
    if (bits > 0)
      swrite(list, bits,  sread(src, bits)  );
  }
}



/*******************************************************************************
 *
 *                                      CODES
 *
 ******************************************************************************/

WTYPE get_unary (BitList *list)
{
  int pos, maxpos, wpos, bpos;
  WTYPE word, v;
  WTYPE *wptr;

  assert( list->pos < list->len );
  pos = list->pos;
  maxpos = list->len - 1;

  /* First word */
  wpos = pos / BITS_PER_WORD;
  bpos = pos % BITS_PER_WORD;
  wptr = list->data + wpos;
  word = (*wptr & (W_FFFF >> bpos)) << bpos;

  if (word == W_ZERO) {
    pos += (BITS_PER_WORD - bpos);
    while ( (*++wptr == W_ZERO) && (pos <= maxpos) )
       pos += BITS_PER_WORD;
    word = *wptr;
  }
  if (pos > maxpos) {
    croak("read off end of stream");
    return W_ZERO;
  }
  assert(word != 0);

#if 0
  #if sizeof(WTYPE) >= 8
    if ((word & W_CONST(0xFFFFFFFF00000000))==W_ZERO) {pos+=32; word<<=32;}
    if ((word & W_CONST(0xFFFF000000000000))==W_ZERO) {pos+=16; word<<=16;}
    if ((word & W_CONST(0xFF00000000000000))==W_ZERO) {pos+= 8; word<<= 8;}
  #else
    if ((word & W_CONST(0xFFFF0000))==W_ZERO) {pos+=16; word<<=16;}
    if ((word & W_CONST(0xFF000000))==W_ZERO) {pos+= 8; word<<= 8;}
  #endif
#endif
  while ( ((word >> MAXBIT) & W_ONE) == W_ZERO ) {
    pos++;
    word <<= 1;
  }
  /* We found a 1 in one of our valid words, this should be true */
  assert(pos <= maxpos);

  v = pos - list->pos;
  list->pos = pos+1;
  assert(list->pos <= list->len);  /* double check we're not off the end */
  return v;
}

void put_unary (BitList *list, WTYPE value)
{
  int len, bits, wpos, bpos;

  /* Simple way to do this:   swrite(list, value+1, W_ONE); */
  len = list->len;
  bits = value+1;

  expand_list(list, len+bits);

  len += value;

  wpos = len / BITS_PER_WORD;
  bpos = len % BITS_PER_WORD;

  list->data[wpos] |= (W_ONE << (MAXBIT - bpos));
  list->len = len + 1;
}



WTYPE get_unary1 (BitList *list)
{
  int pos, maxpos, wpos, bpos;
  WTYPE word, v;
  WTYPE *wptr;
  assert( list->pos < list->len );
  pos = list->pos;
  maxpos = list->len - 1;

  /* First word */
  wpos = pos / BITS_PER_WORD;
  bpos = pos % BITS_PER_WORD;
  wptr = list->data + wpos;
  word = (bpos == 0) ? *wptr
                     : (*wptr << bpos) | (W_FFFF >> (BITS_PER_WORD - bpos));

  if (word == W_FFFF) {
    pos += (BITS_PER_WORD - bpos);
    while ( (*++wptr == W_FFFF) && (pos <= maxpos) )
       pos += BITS_PER_WORD;
    word = *wptr;
  }
  if (pos > maxpos) {
    croak("read off end of stream");
    return W_ZERO;
  }
  assert(word != W_FFFF);

  while ( (word & (W_ONE << MAXBIT)) != W_ZERO ) {
    pos++;
    word <<= 1;
  }

  if (pos > maxpos) {
    croak("read off end of stream");
    return W_ZERO;
  }

  v = pos - list->pos;
  list->pos = pos+1;
  return v;
}

void put_unary1 (BitList *list, WTYPE value)
{
  int len = list->len;
  int bits = value+1;

  int wpos = len / BITS_PER_WORD;
  int bpos = len % BITS_PER_WORD;
  WTYPE first_bits = BITS_PER_WORD - bpos;

  expand_list(list, len+value+1);

  if ( (bpos > 0) && (first_bits <= value) ) {
    list->data[wpos++] |= (W_FFFF >> bpos);
    bpos = 0;
    value -= first_bits;
  }
  /* Straightforward word-setting code:
   *   while (value > BITS_PER_WORD) {
   *     list->data[wpos++] = W_FFFF;
   *     value -= BITS_PER_WORD;
   *   }
   */
  if (value >= BITS_PER_WORD) {
    WTYPE nwords = value / BITS_PER_WORD;
    memset((char*) (list->data + wpos), 0xFF, nwords * sizeof(WTYPE));
    value -= nwords * BITS_PER_WORD;
    wpos += nwords;
  }
  if (value > 0)
    list->data[wpos] |= ( (W_FFFF << (BITS_PER_WORD-value)) >> bpos);

  list->len = len + bits;
}



WTYPE get_gamma (BitList *list)
{
  WTYPE base, v;
  int pos = list->pos;
  assert( list->pos < list->len );
  base = get_unary(list);
  if (base == W_ZERO) {
    v = W_ZERO;
  } else if (base == BITS_PER_WORD) {
    v = W_FFFF;
  } else if (base > BITS_PER_WORD) {
    list->pos = pos;  /* restore position */
    croak("code error: Gamma base %lu", (unsigned long)base);
    return W_ZERO;
  } else {
    v = ( (W_ONE << base) | sread(list, base) ) - W_ONE;
  }
  return v;
}

void put_gamma (BitList *list, WTYPE value)
{
  if (value == W_ZERO) {
    swrite(list, 1, 1);
  } else if (value == W_FFFF) {
    put_unary(list, BITS_PER_WORD);
  } else {
    WTYPE v = value+1;
    int base = 1;
    while ( (v >>= 1) != 0)
      base++;
    swrite(list, base-1, W_ZERO);
    swrite(list, base, value+1);
  }
}



WTYPE get_delta (BitList *list)
{
  WTYPE base, v;
  int pos = list->pos;
  assert( list->pos < list->len );
  base = get_gamma(list);
  if (base == W_ZERO) {
    v = W_ZERO;
  } else if (base == BITS_PER_WORD) {
    v = W_FFFF;
  } else if (base > BITS_PER_WORD) {
    list->pos = pos;  /* restore position */
    croak("code error: Delta base %lu", (unsigned long)base);
    return W_ZERO;
  } else {
    v = ( (W_ONE << base) | sread(list, base) ) - W_ONE;
  }
  return v;
}

void put_delta (BitList *list, WTYPE value)
{
  if (value == W_ZERO) {
    put_gamma(list, 0);
  } else if (value == W_FFFF) {
    put_gamma(list, BITS_PER_WORD);
  } else {
    WTYPE v = value+1;
    int base = 0;
    while ( (v >>= 1) != 0)
      base++;
    put_gamma(list, base);
    swrite(list, base, value+1);
  }
}



WTYPE get_omega (BitList *list)
{
  WTYPE first_bit;
  WTYPE v = W_ONE;
  int pos = list->pos;
  assert( list->pos < list->len );
  /* TODO: sread will croak if off stream, but position needs to be reset */
  while ( (first_bit = sread(list, 1)) == W_ONE ) {
    if (v == BITS_PER_WORD) {
      return W_FFFF;
    } else if (v > BITS_PER_WORD) {
      list->pos = pos;  /* restore position */
      croak("code error: Omega overflow");
      return W_ZERO;
    }
    if ( (list->pos + (v+1)) > (WTYPE)list->len ) {
      list->pos = pos;  /* restore position */
      croak("read off end of stream");
      return W_ZERO;
    }
    v = (W_ONE << v) | sread(list, v);
  }
  return (v - W_ONE);
}

void put_omega (BitList *list, WTYPE value)
{
  MAKE_BITSTACK;

  if (value == W_FFFF) {
    /* Write the code that will make v = BITS_PER_WORD */
    int fbits = 1 + (BITS_PER_WORD > 32);
    swrite(list, 1, 1);
    swrite(list, 1, 0);        /* v = 2                          */
    swrite(list, 1, 1);
    swrite(list, 2, fbits);    /* v = 5 (32-bit) or 6 (64-bit)   */
    swrite(list, 1, 1);
    swrite(list, 4+fbits, 0);  /* v = 2^5 (32)  /  2^6 (64)      */
    swrite(list, 1, 1);        /* Decode v as bit count          */
    return;
  }

  value += W_ONE;
  PUSH_BITSTACK(1, W_ZERO);

  while (value > W_ONE) {
    WTYPE v = value;
    int base = 0;
    while ( (v >>= 1) != 0)
      base++;
    PUSH_BITSTACK(base+1, value);
    value = base;
  }

  WRITE_BITSTACK(list);
}



#define MAXFIB 100
static WTYPE fibv[MAXFIB] = {0};
static int   maxfibv = 0;
static void _calc_fibv(void)
{
  if (fibv[0] == 0) {
    int i;
    fibv[0] = 1;
    fibv[1] = 2;
    for (i = 2; i < MAXFIB; i++) {
      fibv[i] = fibv[i-2] + fibv[i-1];
      if (fibv[i] < fibv[i-1]) {
        maxfibv = i-1;
        break;
      }
    }
    assert(maxfibv > 0);
  }
}

WTYPE get_fib (BitList *list)
{
  int b;
  WTYPE code, v;
  int pos = list->pos;

  assert( list->pos < list->len );
  _calc_fibv();
  code = get_unary(list);
  v = 0;
  b = -1;
  do {
    b += (int) code+1;
    if (b > maxfibv) {
      list->pos = pos;  /* restore position */
      croak("code error: Fibonacci overflow");
      return W_ZERO;
    }
    if (list->pos >= list->len) {
      list->pos = pos;  /* restore position */
      croak("read off end of stream");
      return W_ZERO;
    }
    v += fibv[b];
  } while ( (code = get_unary(list)) != 0);
  return(v-1);
}

void put_fib (BitList *list, WTYPE value)
{
  int s;
  WTYPE v;
  MAKE_BITSTACK;

  if (value < 2) {
    swrite(list, 2+value, W_CONST(3));
    return;
  }

  _calc_fibv();

  /* We're constructing a big code backwards.  We fill in a word backwards,
   * then add it to a stack when full.  When done, we pop off each word from
   * the stack and write it. */

  s = 3;  /* 0 and 1 taken care of earlier, so value >= 2 */
  while ( (s <= maxfibv) && (value >= (fibv[s]-1)) )
    s++;

  /* Note that we're being careful to allow ~0 to be encoded properly. */
  v = value - fibv[--s] + 1;

  /* Current word we're constructing.  Trailing '11' filled in. */
  PUSH_BITSTACK(2, W_CONST(3));

  while (s-- > 0) {
    if (v >= fibv[s]) {
      v -= fibv[s];
      PUSH_BITSTACK(1, W_ONE);
    } else {
      PUSH_BITSTACK(1, W_ZERO);
    }
  }
  WRITE_BITSTACK(list);
}



/* Generalized Fibonacci codes */
#define MAX_FIBGEN_M 16
static WTYPE fibm_val[MAX_FIBGEN_M-1][MAXFIB] = { {0} };
static WTYPE fibm_sum[MAX_FIBGEN_M-1][MAXFIB] = { {0} };
static int   fibm_max[MAX_FIBGEN_M-1] = {0};
static void _calc_fibm(int m)
{
  WTYPE* fv, *fs;
  assert( (m >= 2) && (m <= MAX_FIBGEN_M) );
  fv = &(fibm_val[m-2][0]);

  if (fv[0] == 0) {
    int i,j;
    fv[0] = 1;
    fv[1] = 2;
    for (i = 2; i < MAXFIB; i++) {
      WTYPE sum = fv[i-1] + (m > i);
      for (j = 2; (j <= m) && (j <= i); j++)
        sum += fv[i-j];
      fv[i] = sum;
      if (fv[i] < fv[i-1]) {
        fibm_max[m-2] = i-1;
        break;
      }
    }
    assert(fibm_max[m-2] > 0);
    /* calculate sums */
    fs = &(fibm_sum[m-2][0]);
    fs[0] = fv[0];
    for (i = 1; i <= fibm_max[m-2]; i++) {
      WTYPE sum = fs[i-1] + fv[i];
      if (sum < fs[i-1])  sum = W_FFFF;
      fs[i] = sum;
    }
  }
}

WTYPE get_fibgen (BitList *list, int m)
{
  int s, fmax, pos;
  WTYPE code, term, v, *fv, *fs;
  fv = &(fibm_val[m-2][0]);
  fs = &(fibm_sum[m-2][0]);
  fmax = fibm_max[m-2];
  pos = list->pos;

  assert( list->pos < list->len );
  _calc_fibm(m);
  term = ~(W_FFFF << m);   /*   000001..1 */

  /* For m=2, using get_unary works very well, as it will one or more bits
   * in a single call, and the terminator is only two bits.  As m increases,
   * more and more time is spent calling get_unary repeatedly to read the
   * terminator.
   *
   * This code instead reads 1-m bits at a time, looking for the terminator.
   * It could be slightly faster if it used readahead to get 16-32 bits at
   * a time.
   */

  code = sread(list, m);
  if (code == term)  return W_ZERO;

  v = W_ONE;
  s = 0;
  while (1) {
    int count, codelen, c;

    count = 0;  while (code & (1 << count))  count++;

    codelen = m-count;
    if (codelen == 0)
      break;

    if ( (list->pos + codelen) > list->len ) {
      list->pos = pos;  /* restore position */
      croak("read off end of stream");
      return W_ZERO;
    }
    code = (code << codelen) | sread(list, codelen);

    for (c = m+codelen-1; c >= m; c--) {
      if (s > fmax) {
        list->pos = pos;  /* restore position */
        croak("code error: Fibonacci overflow");
        return W_ZERO;
      }
      if (code & (1 << c))
        v += fv[s];
      s++;
    }
    code &= term;
  }
  if (s >= 2)
    v += fs[s-2];
  return v;
}

void put_fibgen (BitList *list, int m, WTYPE value)
{
  WTYPE term;

  _calc_fibm(m);
  term = ~(W_FFFF << m);   /*   000001..1 */

  if (value == 0) {
    swrite(list, m, term);
  } else if (value == 1) {
    swrite(list, m+1, term);
  } else {
    WTYPE* fv = &(fibm_val[m-2][0]);
    WTYPE* fs = &(fibm_sum[m-2][0]);
    int fmax = fibm_max[m-2];
    int s;
    WTYPE v;
    MAKE_BITSTACK;

    s = 1;
    while ( (s <= fmax) && (value > fs[s]))
      s++;
    v = value - fs[s-1] - 1;

    /* Start stack and add the trailing '011' */
    PUSH_BITSTACK(m+1, term);

    while (s-- > 0) {
      if (v >= fv[s]) {
        v -= fv[s];
        PUSH_BITSTACK(1, W_ONE);
      } else {
        PUSH_BITSTACK(1, W_ZERO);
      }
    }
    WRITE_BITSTACK(list);
  }
}



WTYPE get_levenstein (BitList *list)
{
  WTYPE C, v;
  int pos = list->pos;
  assert( list->pos < list->len );
  C = get_unary1(list);
  v = 0;
  if (C > 0) {
    WTYPE i;
    v = 1;
    for (i = 1; i < C; i++) {
      if (v > BITS_PER_WORD) {
        list->pos = pos;  /* restore position */
        croak("code error: Levenstein overflow");
        return W_ZERO;
      }
      if ( (list->pos + v) > (WTYPE)list->len ) {
        list->pos = pos;  /* restore position */
        croak("read off end of stream");
        return W_ZERO;
      }
      v = (W_ONE << v) | sread(list, v);
    }
  }
  return(v);
}

void put_levenstein (BitList *list, WTYPE value)
{
  int ngroups = 1;
  MAKE_BITSTACK;

  if (value == W_ZERO) {
    swrite(list, 1, 0);
    return;
  }

  while (1) {
    WTYPE v = value;
    int base = 0;
    while ( (v >>= 1) != 0)
      base++;
    if (base == 0)
      break;
    PUSH_BITSTACK(base, value);
    value = base;
    ngroups++;
  }

  put_unary1(list, ngroups);
  WRITE_BITSTACK(list);
}



WTYPE get_evenrodeh (BitList *list)
{
  WTYPE v, first_bit;
  int pos = list->pos;
  assert( list->pos < list->len );
  v = sread(list, 3);
  if (v > 3) {
    /* TODO: sread will croak if off stream, but position needs to be reset */
    while ( (first_bit = sread(list, 1)) == W_ONE ) {
      v -= W_ONE;
      if (v > BITS_PER_WORD) {
        list->pos = pos;  /* restore position */
        croak("code error: Even-Rodeh overflow");
        return W_ZERO;
      }
      if ( (list->pos + v) > (WTYPE)list->len ) {
        list->pos = pos;  /* restore position */
        croak("read off end of stream");
        return W_ZERO;
      }
      v = (W_ONE << v) | sread(list, v);
    }
  }
  return v;
}

void put_evenrodeh (BitList *list, WTYPE value)
{
  MAKE_BITSTACK;

  if (value <= W_CONST(3)) {
    swrite(list, 3, value);
    return;
  }

  PUSH_BITSTACK(1, W_ZERO);

  while (value > W_CONST(3)) {
    WTYPE v = value;
    int base = 1;
    while ( (v >>= 1) != 0)
      base++;
    PUSH_BITSTACK(base, value);
    value = base;
  }
  WRITE_BITSTACK(list);
}



/* Goldbach codes using the sieves directly.
 * Slower but memory friendly.  Needs prime_count and nth_prime to be fast.
 * Decoding especially takes a huge hit as n increases.
 * Encoding 1B takes 388MB with number list, 32MB with sieve.
 */
WTYPE get_goldbach_g1 (BitList *list)
{
  int i, j;
  int pos = list->pos;
  WTYPE pi, pj, value;
  assert( pos < list->len );

  i = get_gamma(list);
  j = get_gamma(list) + i;
  pi = (i == 0) ? 1 : nth_prime(i+1);
  pj = (j == 0) ? 1 : nth_prime(j+1);
  value = pi + pj;
  return ((value/2)-1);
}

void put_goldbach_g1 (BitList *list, WTYPE value)
{
  int i, j;

  if (value >= (W_FFFF>>1)) {
    croak("value %lu out of range 0 - %lu", (unsigned long)value, (unsigned long)(W_FFFF>>1));
    return;
  }
  value = (value+1) * 2;

  if (!find_best_prime_pair(value, 0, &i, &j)) {
    croak("value %lu out of range", (unsigned long)value);
    return;
  }
  put_gamma(list, (WTYPE)i);
  put_gamma(list, (WTYPE)j);
}

WTYPE get_goldbach_g2 (BitList *list)
{
  int i, j;
  int pos = list->pos;
  WTYPE look, value;
  WTYPE subtract = W_ONE;
  assert( pos < list->len );

  if ( (list->pos + 3) > list->len ) {
    croak("read off end of stream");
    return W_ZERO;
  }
  look = sreadahead(list, 3);
  if (look == W_CONST(6)) {  (void) sread(list, 3); return W_ZERO;  }
  if (look == W_CONST(7)) {  (void) sread(list, 3); return W_ONE;   }

  if (look >= W_CONST(4)) {
    subtract = W_ZERO;
    (void) sread(list, 1);
  }

  i = get_gamma(list);
  j = get_gamma(list);

  if (j == 0) {
    value = (i == 0) ? 1 : nth_prime(i+1);
  } else {
    WTYPE pi, pj;
    i = i - 1;
    j = j + i - 1;
    pi = (i == 0) ? 1 : nth_prime(i+1);
    pj = (j == 0) ? 1 : nth_prime(j+1);
    value = pi + pj;
  }
  return (value - subtract);
}

void put_goldbach_g2 (BitList *list, WTYPE value)
{
  int i, j;

  if (value == W_ZERO) { swrite(list, 3, W_CONST(6)); return; }
  if (value == W_ONE ) { swrite(list, 3, W_CONST(7)); return; }

  /* Encode 32-bit ~0 by hand to avoid overflow issues */
  if (value == 0xFFFFFFFF) {
    put_gamma(list, 105097509);
    put_gamma(list, 122);
    return;
  }
  if (value == W_FFFF) {
    croak("value %lu out of range 0 - %lu", (unsigned long)value, (unsigned long)W_FFFF-1);
    return;
  }
  value++;

  if ( (value != 2) && is_prime(value) ) {
    int spindex = prime_count(value)-1;
    /* printf("g2 prime: storing %d followed by 1\n", spindex); */
    put_gamma(list, (WTYPE)spindex);
    swrite(list, 1, W_ONE);
    return;
  }
  
  if ((value % 2) == 1) {
    swrite(list, 1, W_ONE);
    value--;
  }

  if (!find_best_prime_pair(value, 1, &i, &j)) {
    croak("value out of range");
    return;
  }
  put_gamma(list, (WTYPE)i);
  put_gamma(list, (WTYPE)j);
}



WTYPE get_binword (BitList *list, int k)
{
  return sread(list, k);
}
void  put_binword (BitList *list, int k, WTYPE value)
{
  swrite(list, k, value);
}



WTYPE get_baer (BitList *list, int k)
{
  WTYPE mk, C, v;

  assert(k >= -32);
  assert(k <= 32);
  mk = (k < 0) ? -k : 0;

  C = get_unary1(list);
  if (C < mk)
    return C;
  C -= mk;
  v = (sread(list, 1) == W_ZERO)  ?  W_ONE
                                  :  W_CONST(2) + sread(list, 1);
  if (C > 0)
    v = (v << C)  +  ((W_ONE << (C+W_ONE)) - W_CONST(2))  +  sread(list, C);
  v += mk;
  if (k > 0) {
    v = W_ONE + ( ((v-W_ONE) << k) | sread(list, k) );
  }
  return (v-W_ONE);
}
void  put_baer (BitList *list, int k, WTYPE value)
{
  WTYPE mk, C, v, postword;

  assert(k >= -32);
  assert(k <= 32);
  mk = (k < 0) ? -k : 0;

  if (value < mk) {
    put_unary1(list, value);
    return;
  }
  v = (k == 0)  ?  value+W_ONE
                :  (k < 0)  ?  value-mk+W_ONE  :  W_ONE + (value >> k);
  C = 0;
  postword = 0;

  /* This ensures ~0 is encoded correctly. */
  if ( (k == 0) & (value >= 3) ) {
    if ((value & 1) == 0) { v = (value - W_CONST(2)) >> 1;  postword = W_ONE; }
    else                  { v = (value - W_ONE) >> 1; }
    C = 1;
  }

  while (v >= 4) {
    if ((v & 1) == 0) { v = (v - W_CONST(2)) >> 1; }
    else              { v = (v - W_CONST(3)) >> 1; postword |= (W_ONE << C); }
    C++;
  }

  put_unary1(list, C+mk);
  if (v == 1)
    swrite(list, 1, 0);
  else
    swrite(list, 2, v);
  if (C > 0)
    swrite(list, C, postword);
  if (k > 0)
    swrite(list, k, value);
}



typedef struct {
  int    maxhk;
  int    s [BITS_PER_WORD / 2];    /* shift amount */
  WTYPE  t [BITS_PER_WORD / 2];    /* threshold    */
} bvzeta_map;

static bvzeta_map bvzeta_map_cache[16] = { {0} };

static void bv_make_param_map(int k)
{
  bvzeta_map* bvm;
  assert(k >= 2);
  assert(k <= 15);
  bvm = &(bvzeta_map_cache[k]);
  if (bvm->maxhk == 0) {
    int h;
    int maxh = (BITS_PER_WORD - 1) / k;
    assert(maxh < (BITS_PER_WORD/2));
    for (h = 0; h <= maxh; h++) {
      int hk = h * k;
      int s = 1;
      WTYPE interval, z;
      interval = (W_ONE << (hk+k)) - (W_ONE << hk) - W_ONE;
      z = interval + W_ONE;
      { WTYPE v = z; while ( (v >>= 1) != 0)  s++; } /* ceil log2(z) */
      assert(s >= 2);
      bvm->s[h] = s;
      bvm->t[h] = (W_ONE << s) - z;  /* threshold */
    }
    bvm->maxhk = maxh * k;
  }
}

WTYPE get_boldivigna (BitList *list, int k)
{
  bvzeta_map* bvm;
  int s;
  WTYPE h, maxh, t, first, v;

  assert(k >= 1);
  assert(k <= 15);  /* You should use Delta codes for anything over 6. */

  if (k == 1)  return get_gamma(list);

  bvm = &(bvzeta_map_cache[k]);
  if (bvm->maxhk == 0)
    bv_make_param_map(k);

  maxh = bvm->maxhk / k;
  assert(maxh < (BITS_PER_WORD/2));

  h = get_unary(list);
  if (h > maxh) return W_FFFF;
  s = bvm->s[h];
  t = bvm->t[h];
  assert(s >= 2);
  first = sread(list, s-1);
  if (first >= t)
    first = (first << 1) + sread(list, 1) - t;

  v = (W_ONE << (h*k)) - W_ONE + first;   /* -1 is to make 0 based */
  return v;
}
void  put_boldivigna (BitList *list, int k, WTYPE value)
{
  bvzeta_map* bvm;
  int maxh, maxhk, hk, h, s;
  WTYPE t, x;

  assert(k >= 1);
  assert(k <= 15);  /* You should use Delta codes for anything over 6. */

  if (k == 1)  { put_gamma(list, value); return; }

  bvm = &(bvzeta_map_cache[k]);
  if (bvm->maxhk == 0)
    bv_make_param_map(k);

  maxh = bvm->maxhk / k;
  assert(maxh < (BITS_PER_WORD/2));

  if (value == W_FFFF)  { put_unary(list, maxh+1); return; }

  maxhk = maxh * k;
  hk = 0;
  while ( (hk < maxhk) && (value >= ((W_ONE << (hk+k))-W_ONE)) )  hk += k;
  h = hk/k;
  assert(h <= maxh);
  s = bvm->s[h];
  t = bvm->t[h];

  put_unary(list, h);
  x = value - (W_ONE << hk) + W_ONE;
  if (x < t)
    swrite(list, s-1, x);
  else
    swrite(list, s, x+t);
}



WTYPE get_comma (BitList *list, int k)
{
  WTYPE comma, base, chunk;
  int pos = list->pos;
  WTYPE v = 0;
  assert( list->pos < list->len );
  assert(k >= 1);
  assert(k <= 16);

  if (k == 1)  return get_unary(list);

  comma = ~(W_FFFF << k);   /*   000001..1 */
  base = (1 << k) - 1;
  while (1) {
    if ( (list->pos + k) > list->len ) {
      list->pos = pos;  /* restore position */
      croak("read off end of stream");
      return W_ZERO;
    }
    chunk = sread(list, k);
    if (chunk == comma)
      break;
    v = base*v + chunk;
  }
  return v;
}
void  put_comma (BitList *list, int k, WTYPE value)
{
  WTYPE comma, base;
  MAKE_BITSTACK;

  assert(k >= 1);
  assert(k <= 16);

  if (k == 1)  { put_unary(list, value); return; }

  comma = ~(W_FFFF << k);   /*   000001..1 */
  base = (1 << k) - 1;

  PUSH_BITSTACK(k, comma);

  while (value > W_ZERO) {
    WTYPE newval = value / base;
    PUSH_BITSTACK(k, value - newval*base);
    value = newval;
  }
  WRITE_BITSTACK(list);
}



WTYPE get_block_taboo (BitList *list, int bits, WTYPE taboo)
{
  WTYPE base;
  WTYPE v = 0;
  WTYPE basemult = 1;
  WTYPE baseval = 0;
  int pos = list->pos;
  assert( list->pos < list->len );
  assert( (bits >= 1) && (bits <= 16) );

  if (bits == 1) {
    return (taboo == 0) ? get_unary1(list) : get_unary(list);
  }

  base = (1 << bits) - 1;
  while (1) {
    WTYPE digit;
    WTYPE newv;
    if ( (list->pos + bits) > list->len ) {
      list->pos = pos;  /* restore position */
      croak("read off end of stream");
      return W_ZERO;
    }
    digit = sread(list, bits);
    if (digit == taboo)
      break;
    if (digit > taboo)  digit--;
    newv = base*v + digit;
    if (newv < v) {
      list->pos = pos;  /* restore position */
      croak("code error: Block Taboo overflow");
      return W_ZERO;
    }
    v = newv;
    baseval += basemult;
    basemult *= base;
  }
  v += baseval;
  return v;
}
void  put_block_taboo (BitList *list, int bits, WTYPE taboo, WTYPE value)
{
  WTYPE base, basemult;
  WTYPE baseval = 1;
  int nchunks = 1;
  MAKE_BITSTACK;

  assert( (bits >= 1) && (bits <= 16) );

  if (bits == 1)  {
    if (taboo == 0)  put_unary1(list, value);
    else             put_unary(list, value);
    return;
  }
  if (value == 0) {
    swrite(list, bits, taboo);
    return;
  }

  base = (1 << bits) - 1;
  basemult = base;

  while (value >= (baseval + basemult)) {
    baseval += basemult;
    basemult *= base;
    nchunks++;
  }
  value -= baseval;

  PUSH_BITSTACK(bits, taboo);

  while (nchunks-- > 0) {
    WTYPE digit = value % base;
    if (digit >= taboo)  digit++;
    PUSH_BITSTACK(bits, digit);
    value = value / base;
  }
  WRITE_BITSTACK(list);
}



WTYPE get_rice_sub (BitList *list, SV* self, SV* code, int k)
{
  WTYPE v;
  assert( (k >= 0) && (k <= BITS_PER_WORD) );
  assert( ((code == 0) && (self == 0))  ||  ((code != 0) && (self != 0)) );

  v = (code == 0)  ?  get_unary(list)  :  call_get_sub(self, code, list);
  if (k > 0)
    v = (v << k) | sread(list, k);
  return v;
}
void  put_rice_sub (BitList *list, SV* self, SV* code, int k, WTYPE value)
{
  WTYPE q;
  assert( (k >= 0) && (k <= BITS_PER_WORD) );
  assert( ((code == 0) && (self == 0))  ||  ((code != 0) && (self != 0)) );

  q = value >> k;
  if (code == 0) { put_unary(list, q); }
  else           { call_put_sub(self, code, list, q); }
  if (k > 0) {
    WTYPE r = value - (q << k);
    swrite(list, k, r);
  }
}



WTYPE get_gamma_rice (BitList *list, int k)
{
  WTYPE v;
  assert(k >= 0);
  assert(k <= BITS_PER_WORD);
  v = get_gamma(list);
  if (k > 0)
    v = (v << k) | sread(list, k);
  return v;
}
void  put_gamma_rice (BitList *list, int k, WTYPE value)
{
  assert(k >= 0);
  assert(k <= BITS_PER_WORD);
  if (k == 0) {
    put_gamma(list, value);
  } else {
    WTYPE q = value >> k;
    WTYPE r = value - (q << k);
    put_gamma(list, q);
    swrite(list, k, r);
  }
}



WTYPE get_golomb_sub (BitList *list, SV* self, SV* code, WTYPE m)
{
  int base = 1;
  WTYPE threshold, q, v;

  assert(m >= W_ONE);
  assert( ((code == 0) && (self == 0))  ||  ((code != 0) && (self != 0)) );

  q = (code == 0)  ?  get_unary(list)  :  call_get_sub(self, code, list);
  if (m == W_ONE)  return q;

  base = 1;
  {
    v = m-W_ONE;
    while (v >>= 1)  base++;
  }
  threshold = (W_ONE << base) - m;

  v = q * m;
  if (threshold == 0) {
    v += sread(list, base);
  } else {
    WTYPE first = sread(list, base-1);
    if (first >= threshold)
      first = (first << 1) + sread(list, 1) - threshold;
    v += first;
  }
  return v;
}
void  put_golomb_sub (BitList *list, SV* self, SV* code, WTYPE m, WTYPE value)
{
  int base = 1;
  WTYPE threshold, q, r;

  assert(m >= W_ONE);
  assert( ((code == 0) && (self == 0))  ||  ((code != 0) && (self != 0)) );

  if (m == W_ONE) {
    if (code == 0) { put_unary(list, value); }
    else           { call_put_sub(self, code, list, value); }
    return;
  }

  {
    WTYPE v = m-W_ONE;
    while (v >>= 1)  base++;
  }
  threshold = (W_ONE << base) - m;

  q = value / m;
  r = value - (q * m);
  if (code == 0) { put_unary(list, q); }
  else           { call_put_sub(self, code, list, q); }
  if (r < threshold)
    swrite(list, base-1, r);
  else
    swrite(list, base, r + threshold);
}



WTYPE get_gamma_golomb (BitList *list, WTYPE m)
{
  int base = 1;
  WTYPE threshold, q, v;

  assert(m >= W_ONE);

  q = get_gamma(list);
  if (m == W_ONE)  return q;

  {
    v = m-W_ONE;
    while (v >>= 1)  base++;
  }
  threshold = (W_ONE << base) - m;

  v = q * m;
  if (threshold == 0) {
    v += sread(list, base);
  } else {
    WTYPE first = sread(list, base-1);
    if (first >= threshold)
      first = (first << 1) + sread(list, 1) - threshold;
    v += first;
  }
  return v;
}
void  put_gamma_golomb (BitList *list, WTYPE m, WTYPE value)
{
  int base = 1;
  WTYPE threshold, q, r;

  assert(m >= W_ONE);
  if (m == W_ONE) {
    put_gamma(list, value);
    return;
  }

  {
    WTYPE v = m-W_ONE;
    while (v >>= 1)  base++;
  }
  threshold = (W_ONE << base) - m;

  q = value / m;
  r = value - (q * m);
  put_gamma(list, q);
  if (r < threshold)
    swrite(list, base-1, r);
  else
    swrite(list, base, r + threshold);
}



#define QLOW  0
#define QHIGH 7
WTYPE get_adaptive_rice_sub (BitList *list, SV* self, SV* code, int *kp)
{
  int k;
  WTYPE q, v;

  assert( ((code == 0) && (self == 0))  ||  ((code != 0) && (self != 0)) );
  assert( (list != 0) && (kp != 0) );
  k = *kp;
  assert( (k >= 0) && (k <= BITS_PER_WORD) );

  q = (code == 0)  ?  get_gamma(list)  :  call_get_sub(self, code, list);
  v = q << k;
  if (k > 0)
    v |= sread(list, k);
  if ( (q <= QLOW ) && (k > 0            ) )  *kp -= 1;
  if ( (q >= QHIGH) && (k < BITS_PER_WORD) )  *kp += 1;
  return v;
}
void  put_adaptive_rice_sub (BitList *list, SV* self, SV* code, int *kp, WTYPE value)
{
  int k;
  WTYPE q;

  assert( ((code == 0) && (self == 0))  ||  ((code != 0) && (self != 0)) );
  assert( (list != 0) && (kp != 0) );
  k = *kp;
  assert( (k >= 0) && (k <= BITS_PER_WORD) );

  q = value >> k;
  if (code == 0) { put_gamma(list, q); }
  else           { call_put_sub(self, code, list, q); }

  if (k > 0) {
    WTYPE r = value - (q << k);
    swrite(list, k, r);
  }
  if ( (q <= QLOW ) && (k > 0            ) )  *kp -= 1;
  if ( (q >= QHIGH) && (k < BITS_PER_WORD) )  *kp += 1;
}



typedef struct {
  int    size;       /* only defined in first entry */
  int    prefix;
  int    bits;
  WTYPE  prefix_cmp;
  WTYPE  minval;
  WTYPE  maxval;
} startstop_map_entry;

char* make_startstop_prefix_map(SV* paramref)
{
  int nparams, prefix_size, prefix, bits, p;
  WTYPE prefix_cmp, minval, maxval;
  startstop_map_entry* map;

  assert(paramref != 0);
  if (    (!SvROK(paramref))
       || (SvTYPE(SvRV(paramref)) != SVt_PVAV)
       || ((nparams = av_len((AV *)SvRV(paramref))+1) < 2)) {
    croak("invalid parameters: startstop ref");
    return 0;
  }

  New(0, map, nparams, startstop_map_entry);

  prefix_size = nparams-1;
  prefix_cmp = W_ONE << prefix_size;
  prefix = 0;
  bits = 0;
  minval = 0;
  maxval = 0;

  for (p = 0; p < nparams; p++) {
    int step;
    SV** step_sv = av_fetch((AV *)SvRV(paramref), p, 0);
    if ( (step_sv == 0) || (SvIV(*step_sv) < 0) ) {
      croak("invalid parameters: startstop step");
      Safefree(map);
      return 0;
    }
    step = (*step_sv != &PL_sv_undef)  ?  SvIV(*step_sv)  :  BITS_PER_WORD;
    bits += step;
    if (bits > BITS_PER_WORD)  bits = BITS_PER_WORD;
    if (p == 0)
      minval = 0;
    else
      minval += maxval+1;
    maxval = (bits < BITS_PER_WORD)  ?  (W_ONE << bits)-W_ONE  :  W_FFFF;
    prefix++;
    prefix_cmp >>= 1;
    map[p].prefix = prefix;
    map[p].bits = bits;
    map[p].prefix_cmp = prefix_cmp;
    map[p].minval = minval;
    map[p].maxval = ((minval+maxval)<maxval) ? W_FFFF : minval+maxval;

  }
  map[0].size = nparams;
  /* Patch last value */
  map[nparams-1].prefix--;

  return (char*) map;
}

WTYPE get_startstop  (BitList *list, const char* cmap)
{
  int nparams, prefix, prefix_bits, bits;
  WTYPE minval;
  WTYPE v;
  WTYPE look;
  int looksize;
  const startstop_map_entry* map = (const startstop_map_entry*) cmap;

  assert(map != 0);

  nparams = map[0].size;
  looksize = map[nparams-1].prefix;
  look = sreadahead(list, looksize);
  prefix = 0;
  while (look < map[prefix].prefix_cmp)  prefix++;
  assert(prefix < nparams);

  prefix_bits = map[prefix].prefix;
  bits        = map[prefix].bits;
  minval      = map[prefix].minval;

  list->pos += prefix_bits;
  v = minval;
  if (bits > 0)
    v += sread(list, bits);
  return v;
}

void put_startstop  (BitList *list, const char* cmap, WTYPE value)
{
  int nparams, prefix, prefix_bits, bits;
  WTYPE global_maxval, prefix_cmp, minval;
  WTYPE v;
  const startstop_map_entry* map = (const startstop_map_entry*) cmap;

  assert(map != 0);
  nparams = map[0].size;
  global_maxval = map[nparams-1].maxval;
  if (value > global_maxval) {
    croak("value %lu out of range 0 - %lu", value, global_maxval);
    return;
  }
  prefix = 0;
  while (value > map[prefix].maxval)  prefix++;
  assert(prefix < nparams);

  prefix_bits = map[prefix].prefix;
  bits        = map[prefix].bits;
  prefix_cmp  = map[prefix].prefix_cmp;
  minval      = map[prefix].minval;

  v = value - minval;
  if ( (prefix_bits + bits) <= BITS_PER_WORD ) {
    if (prefix_cmp != 0)
      v |= W_ONE << bits;
    swrite(list, prefix_bits + bits, v);
  } else {
    if (prefix_cmp == 0)
      swrite(list, prefix_bits, 0);
    else
      put_unary(list, prefix_bits-1);
    if (bits > 0)
      swrite(list, bits, v);
  }
}
