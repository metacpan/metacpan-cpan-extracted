/*
  XS for Archive::Lha

  This XS is, though largely modified, based on LHa for UNIX.
  See lib/Archive/Lha.pm for Authors/Copyright/License information.
*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "Lha.h"
#include <time.h>

/*
  these are not from LHa for UNIX
*/

void
destroy_stash(LhaStash * stash)
{
  Safefree(stash->tree->left);
  Safefree(stash->tree->right);
  Safefree(stash->tree);
  Safefree(stash->pt->table);
  Safefree(stash->pt->length);
  Safefree(stash->pt);
  Safefree(stash->c->table);
  Safefree(stash->c->length);
  Safefree(stash->c);
  Safefree(stash->bit);
  Safefree(stash->queue);
  Safefree(stash);
}

void
safe_croak(LhaStash * stash, char * dying_message)
{
  destroy_stash(stash);
  croak("%s", dying_message);
}

void
output(LhaStash * stash, unsigned char * queue, int len)
{
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVpv(queue, len)));
  PUTBACK;
  call_sv(stash->write, G_VOID);
  SPAGAIN;
  PUTBACK;
  FREETMPS;
  LEAVE;
}

void
input(LhaStash * stash, int len)
{
  int n;
  SV *sv;
  STRLEN got;
  const char *ptr;
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSViv(len)));
  PUTBACK;
  n = call_sv(stash->read, G_SCALAR);
  SPAGAIN;
  if (n != 1)
    safe_croak(stash, "There's something wrong in 'read' callback");
  sv  = POPs;
  ptr = SvPVbyte(sv, got);
  Copy(ptr, stash->bit->readbuf, (STRLEN)len <= got ? (STRLEN)len : got, unsigned char);
  PUTBACK;
  FREETMPS;
  LEAVE;
}

/*
  modified from LHa for UNIX: bitio.c ver 1.14
    original authors:
      Source All chagned       1995.01.14  N.Watazaki
      Separated from crcio.c   2002.10.26  Koji Arai
*/

unsigned short
shiftbits(LhaBitstream * bit, unsigned char n)
{
  return (bit->value << n)
       + (bit->buf >> (char_bit - n));
}

void
fillbuf(LhaStash * stash, unsigned char n)
{
  unsigned short len;
  LhaBitstream * bit = stash->bit;
  while (n > bit->pos) {
    n -= bit->pos;
    bit->value = shiftbits(bit, bit->pos);
    if (stash->encoded_size > 0) {
      if (bit->readpos == 0) {
        if (stash->encoded_size > readbuf_size)
          len = readbuf_size;
        else
          len = stash->encoded_size;
        input(stash, len);
      }
      bit->buf = bit->readbuf[bit->readpos++];
      if (bit->readpos == readbuf_size)
        bit->readpos = 0;
      stash->encoded_size--;
    }
    else
      bit->buf = 0;
    bit->pos = char_bit;
  }
  bit->pos -= n;
  bit->value = shiftbits(bit, n);
  bit->buf <<= n;
}

unsigned short
peekbits(LhaStash * stash, unsigned char n)
{
  return (stash->bit->value >> (ushort_bit - n));
}

unsigned short
getbits(LhaStash * stash, unsigned char n)
{
  unsigned short bits = peekbits(stash, n);
  fillbuf(stash, n);
  return bits;
}

void
init_bitstream(LhaStash * stash)
{
  LhaBitstream  * bitstream;

  Newxz(bitstream, 1, LhaBitstream);
  stash->bit = bitstream;

  stash->bit->blocksize = 0;
  stash->bit->readpos = 0;
  stash->bit->value = 0;
  stash->bit->buf = 0;
  stash->bit->pos = 0;
  fillbuf(stash, ushort_bit);
}

/*
  modified from LHa for UNIX: maketbl.c ver 1.14
    original author(s):
      Source All chagned       1995.01.14  N.Watazaki
*/

void
make_table(LhaStash * stash, LhaTable * table, unsigned short nchar)
{
  unsigned short count[ushort_bit + 1];
  unsigned short weight[ushort_bit + 1];
  unsigned short start[ushort_bit + 1];
  unsigned short total, avail;
  unsigned short from, to;
  unsigned char  bits_to_shift, bit;
  unsigned int   i, j, l;
  char           n;
  unsigned short *p;

  if (table->bit > ushort_bit) {
    safe_croak(stash, "Table is broken: table bit is too large");
  }

  for(i = 1; i <= ushort_bit; i++) {
    count[i]  = 0;
    weight[i] = 1u << (ushort_bit - i);
  }

  for(i = 0; i < nchar; i++)
    if (table->length[i] > ushort_bit) {
      safe_croak(stash, "Table is broken: bit length is too large");
    }
    else
      count[table->length[i]]++;

  total = 0;
  for(i = 1; i <= ushort_bit; i++) {
    start[i] = total;
    total += weight[i] * count[i];
  }
  if (total & ushort_max) {
    safe_croak(stash, "Table is broken: total mismatch");
  }

  bits_to_shift = ushort_bit - table->bit;
  for(i = 1; i <= table->bit; i++) {
    start[i]  >>= bits_to_shift;
    weight[i] >>= bits_to_shift;
  }

  from = start[table->bit + 1] >> bits_to_shift;
  to   = min(1u << table->bit, table->size);
  if (from)
    for(i = from; i < to; i++)
      table->table[i] = 0;

  avail = nchar;
  for(i = 0; i < nchar; i++) {
    bit = table->length[i];
    if (bit == 0)
      continue;
    l = start[bit] + weight[bit];
    if (bit <= table->bit) {
      l = min(l, table->size);
      for(j = start[bit]; j < l; j++)
        table->table[j] = i;
    }
    else {
      j = start[bit];
      if ((j >> bits_to_shift) > table->size) {
        safe_croak(stash, "Table is broken");
      }
      p = &(table->table[j >> bits_to_shift]);
      j <<= table->bit;
      n = bit - table->bit;
      while (--n >= 0) {
        if (*p == 0) {
          stash->tree->right[avail] = stash->tree->left[avail] = 0;
          *p = avail++;
        }
        if (j & ushort_center)
          p = &(stash->tree->right[*p]);
        else
          p = &(stash->tree->left[*p]);
        j <<= 1;
      }
      *p = i;
    }
    start[bit] = l;
  }
}

/*
  modified from LHa for UNIX: huf.c ver 1.14
    original authors:
      Source All chagned       1995.01.14  N.Watazaki
      Support LH7 & Bug Fixed  2000.10. 6  t.okamoto
*/

void
read_pt_len(LhaStash * stash, short nn, unsigned char nbit, short threshold)
{
  int i, c;
  unsigned short n, mask;

  n = getbits(stash, nbit);
  if (n == 0) {
    c = getbits(stash, nbit);
    for(i = 0; i < nn; i++)
      stash->pt->length[i] = 0;
    for(i = 0; i < stash->pt->size; i++)
      stash->pt->table[i] = c;
  }
  else {
    i = 0;
    while (i < min(n, stash->pt->length_size)) {
      c = peekbits(stash, 3);
      if (c != 7)
        fillbuf(stash, 3);
      else {
        mask = create_mask(3);
        while (stash->bit->value & mask) {
          mask >>= 1;
          c++;
        }
        fillbuf(stash, (unsigned char)(c - 3));
      }
      stash->pt->length[i++] = c;
      if (i == threshold) {
        c = getbits(stash, 2);
        while (--c >= 0 && i < stash->pt->length_size)
          stash->pt->length[i++] = 0;
      }
    }
    while (i < nn)
      stash->pt->length[i++] = 0;
    make_table(stash, stash->pt, nn);
  }
}

void
read_c_len(LhaStash * stash)
{
  short i, c, n;
  unsigned short mask;

  n = getbits(stash, stash->CBIT);
  if (n == 0) {
    c = getbits(stash, stash->CBIT);
    for(i = 0; i < stash->c->length_size; i++)
      stash->c->length[i] = 0;
    for(i = 0; i < stash->c->size; i++)
      stash->c->table[i] = c;
  }
  else {
    i = 0;
    while (i < min(n, stash->c->length_size)) {
      c = stash->pt->table[peekbits(stash, stash->pt->bit)];
      if (c >= stash->NT) {
        mask = create_mask(stash->pt->bit);
        do {
          if (stash->bit->value & mask)
            c = stash->tree->right[c];
          else
            c = stash->tree->left[c];
          mask >>= 1;
        } while (c >= stash->NT && (mask || c != stash->tree->left[c]));
      }
      fillbuf(stash, stash->pt->length[c]);
      if (c <= 2) {
        if (c == 0)
          c = 1;
        else if (c == 1)
          c = getbits(stash, 4) + 3;
        else
          c = getbits(stash, stash->CBIT) + 20;
        while (--c >= 0)
          stash->c->length[i++] = 0;
      }
      else
        stash->c->length[i++] = c - 2;
    }
    while (i < stash->c->length_size)
      stash->c->length[i++] = 0;
    make_table(stash, stash->c, stash->c->length_size);
  }
}

unsigned short
decode_c(LhaStash * stash)
{
  unsigned short j, mask;

  if (stash->bit->blocksize == 0) {
    stash->bit->blocksize = getbits(stash, ushort_bit);
    read_pt_len(stash, stash->NT, stash->TBIT, 3);
    read_c_len(stash);
    read_pt_len(stash, stash->NP, stash->PBIT, -1);
  }
  stash->bit->blocksize--;
  j = stash->c->table[peekbits(stash, stash->c->bit)];
  if (j < stash->c->length_size)
    fillbuf(stash, stash->c->length[j]);
  else {
    fillbuf(stash, stash->c->bit);
    mask = create_mask(0);
    do {
      if (stash->bit->value & mask)
        j = stash->tree->right[j];
      else
        j = stash->tree->left[j];
      mask >>= 1;
    } while (j >= stash->c->length_size && (mask || j != stash->tree->left[j]));
    fillbuf(stash, (unsigned char)(stash->c->length[j] - stash->c->bit));
  }
  return j;
}

unsigned short
decode_p(LhaStash * stash)
{
  unsigned short j, mask;

  j = stash->pt->table[peekbits(stash, stash->pt->bit)];
  if (j < stash->NP)
    fillbuf(stash, stash->pt->length[j]);
  else {
    fillbuf(stash, stash->pt->bit);
    mask = create_mask(0);
    do {
      if (stash->bit->value & mask)
        j = stash->tree->right[j];
      else
        j = stash->tree->left[j];
      mask >>= 1;
    } while (j >= stash->NP && (mask || j != stash->tree->left[j]));
    fillbuf(stash, (unsigned char)(stash->pt->length[j] - stash->pt->bit));
  }
  if (j != 0)
    j = (1u << (j - 1)) + getbits(stash, (unsigned char)(j - 1));
  return j;
}

/*
  modified from LHa for UNIX: crcio.c ver 1.14
    original author(s):
      Source All chagned       1995.01.14  N.Watazaki
*/

unsigned short
calc_crc16(unsigned short crc, unsigned char * str, unsigned int len)
{
  while (len-- > 0)
    crc = crctable[(crc ^ *str++) & uchar_max] ^ (crc >> char_bit);
  return crc;
}

/*
  this is not from LHa for UNIX
*/

void
init_tables(HV * self, LhaStash * stash)
{
  LhaTable * pt_table;
  LhaTable * c_table;
  LhaTree  * tree;

  stash->NPT  = self_ushort("NPT");
  stash->NP   = self_ushort("NP");
  stash->NT   = self_ushort("NT");
  stash->NC   = self_ushort("NC");
  stash->PBIT = self_uchar("PBIT");
  stash->TBIT = self_uchar("TBIT");
  stash->CBIT = self_uchar("CBIT");

  Newxz(pt_table, 1, LhaTable);
  Newxz(c_table,  1, LhaTable);
  Newxz(tree,     1, LhaTree);

  pt_table->bit         = self_uchar("PT_TABLE_BIT");
  pt_table->size        = self_ushort("PT_TABLE_SIZE");
  pt_table->length_size = stash->NPT;

  Newxz(pt_table->table,  pt_table->size,        unsigned short);
  Newxz(pt_table->length, pt_table->length_size, unsigned char);

  c_table->bit         = self_uchar("C_TABLE_BIT");
  c_table->size        = self_ushort("C_TABLE_SIZE");
  c_table->length_size = stash->NC;

  Newxz(c_table->table,  c_table->size,        unsigned short);
  Newxz(c_table->length, c_table->length_size, unsigned char);

  Newxz(tree->left,  2 * stash->NC - 1, unsigned short);
  Newxz(tree->right, 2 * stash->NC - 1, unsigned short);

  stash->tree = tree;
  stash->pt   = pt_table;
  stash->c    = c_table;
}

MODULE = Archive::Lha PACKAGE = Archive::Lha::Decode::Base PREFIX = xs_

PROTOTYPES: DISABLE

#/*
#  modified from LHa for UNIX: slide.c ver 1.14
#    original authors:
#      Modified                                   Nobutaka Watazaki
#  Ver. 1.14d  Exchanging a search algorithm  1997.01.11  T.Okamoto
#*/

unsigned short
xs_decode(hashref)
    SV *  hashref;
  CODE:
    HV * self;
    unsigned char * queue;
    LhaStash      * stash;
    unsigned short  crc16;
    int i, c, matchlen, matchoff, matchpos, adjust;
    unsigned int dicsize, dicsize1, total, loc;

    dSP;
    self = (HV *) SvRV(hashref);

    if ( !hash_exists(self, "read") )
      croak("'read' callback is missing");
    if ( !hash_exists(self, "write") )
      croak("'write' callback is missing");

    dicsize  = self_uint("DICSIZE");
    dicsize1 = dicsize - 1;

    Newxz(queue, dicsize, unsigned char);
    Newxz(stash, 1, LhaStash);

    stash->queue = queue;

    stash->read          = self_sv("read");
    stash->write         = self_sv("write");
    stash->original_size = self_uint("original_size");
    stash->encoded_size  = self_uint("encoded_size");

    init_tables(self, stash);
    init_bitstream(stash);

    adjust = (1u << uchar_bit) - self_uchar("THRESHOLD");
    crc16  = 0;
    loc    = 0;
    total  = 0;
    while ( total < stash->original_size ) {
      c = decode_c(stash);
      if (c <= uchar_max) {
        queue[loc++] = c;
        if (loc == dicsize) {
          output(stash, queue, dicsize);
          crc16 = calc_crc16(crc16, queue, dicsize);
          loc = 0;
        }
        total++;
      }
      else {
        matchlen = c - adjust;
        matchoff = decode_p(stash) + 1;
        matchpos = (loc - matchoff) & dicsize1;
        total += matchlen;
        for(i = 0; i < matchlen; i++) {
          queue[loc++] = queue[(matchpos + i) & dicsize1];
          if (loc == dicsize) {
            output(stash, queue, dicsize);
            crc16 = calc_crc16(crc16, queue, dicsize);
            loc = 0;
          }
        }
      }
    }
    if (loc) {
      output(stash, queue, loc);
      crc16 = calc_crc16(crc16, queue, loc);
    }

    destroy_stash(stash);

    RETVAL = crc16;

  OUTPUT:
    RETVAL

MODULE = Archive::Lha PACKAGE = Archive::Lha::CRC PREFIX = xs_

PROTOTYPES: DISABLE

#/* this is not from LHa for UNIX */

unsigned short
xs_update(unsigned short crc, SV * str, STRLEN len)
  CODE:
    RETVAL = calc_crc16(crc, SvPV(str, len), len);

  OUTPUT:
    RETVAL

MODULE = Archive::Lha PACKAGE = Archive::Lha::Header::Utils PREFIX = xs_

PROTOTYPES: DISABLE

unsigned char
xs_checksum(SV * buf, STRLEN offset)
  CODE:
    STRLEN len;
    unsigned char * s = (unsigned char *) SvPV(buf, len);
    unsigned char sum = 0;
    STRLEN i;
    for (i = offset; i < len; i++)
      sum += s[i];
    RETVAL = sum;
  OUTPUT:
    RETVAL

IV
xs_dostime2utime(U32 v)
  CODE:
    struct tm t;
    time_t result;
    if (v == 0) {
      RETVAL = 0;
    } else {
      t.tm_sec   = (v & 0x1F) * 2;
      t.tm_min   = (v >>  5) & 0x3F;
      t.tm_hour  = (v >> 11) & 0x1F;
      t.tm_mday  = (v >> 16) & 0x1F;
      t.tm_mon   = ((v >> 21) & 0x0F) - 1;
      t.tm_year  = ((v >> 25) & 0x7F) + 80;
      t.tm_isdst = -1;
      result = mktime(&t);
      RETVAL = (result == (time_t)-1) ? 0 : (IV)result;
    }
  OUTPUT:
    RETVAL

MODULE = Archive::Lha PACKAGE = Archive::Lha PREFIX = xs_

PROTOTYPES: DISABLE
