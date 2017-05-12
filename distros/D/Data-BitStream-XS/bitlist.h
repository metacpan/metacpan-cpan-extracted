#ifndef DBXS_BITLIST_H
#define DBXS_BITLIST_H


/*
 * Note: we have to be careful with our function names.  On HP/UX, for example,
 * if we have a function calles setpos, it will call the Fortran setpos
 * function instead of ours, leading to all sorts of fun errors.
 */

#include "wtype.h"

typedef enum
{
   eModeR,
   eModeRO,
   eModeW,
   eModeWO,
   eModeRW,
   eModeA
} FileMode;

typedef struct
{
   int         maxlen;
   int         len;
   int         pos;
   WTYPE*      data;
   FileMode    mode;
   const char* file;
   char*       file_header;
   int         file_header_lines;
   int         is_writing;
} BitList;

extern BitList*  new            (FileMode mode,
                                 const char* file,
                                 const char* fheaderdata,
                                 int fheaderlines,
                                 int initial_size);

extern void      DESTROY        (BitList *pVector);

extern int       resize         (BitList *l, int bits);

extern int       _set_len       (BitList *l, int newlen);
extern int       _set_pos       (BitList *l, int newpos);

extern void      read_open      (BitList *l);
extern void      write_open     (BitList *l);
extern void      write_close    (BitList *l);

extern WTYPE     sread          (BitList *l, int bits);
extern WTYPE     sreadahead     (BitList *l, int bits);
extern void      swrite         (BitList *l, int bits, WTYPE value);

extern void      dump           (BitList *l);

extern void      put_string     (BitList *l, const char* s);
extern char*     read_string    (BitList *l, int bits);

extern char*     to_raw         (BitList *l);
extern void      put_raw        (BitList *list, const char* str, int bits);
extern void      from_raw       (BitList *l, const char* str, int bits);

/* src ought to be const, but we're going to call write_close() on it */
extern void      _xput_stream    (BitList *l, BitList *s);

extern WTYPE     get_unary      (BitList *l);
extern WTYPE     get_unary1     (BitList *l);
extern WTYPE     get_gamma      (BitList *l);
extern WTYPE     get_delta      (BitList *l);
extern WTYPE     get_omega      (BitList *l);
extern WTYPE     get_fib        (BitList *l);
extern WTYPE     get_fibgen     (BitList *l, int m);
extern WTYPE     get_levenstein (BitList *l);
extern WTYPE     get_evenrodeh  (BitList *l);
extern WTYPE     get_goldbach_g1(BitList *l);
extern WTYPE     get_goldbach_g2(BitList *l);
extern WTYPE     get_binword    (BitList *l, int k);
extern WTYPE     get_baer       (BitList *l, int k);
extern WTYPE     get_boldivigna (BitList *l, int k);
extern WTYPE     get_comma      (BitList *l, int k);
extern WTYPE     get_block_taboo(BitList *l, int bits, WTYPE taboo);
extern WTYPE     get_rice_sub   (BitList *l, SV* self, SV* code, int k);
extern WTYPE     get_golomb_sub (BitList *l, SV* self, SV* code, WTYPE m);
extern WTYPE     get_gamma_rice (BitList *l, int k);
extern WTYPE     get_gamma_golomb (BitList *l, WTYPE m);
extern WTYPE     get_adaptive_rice_sub (BitList *l, SV* self, SV* code, int *k);
extern WTYPE     get_startstop  (BitList *l, const char* cmap);

extern void      put_unary      (BitList *l, WTYPE value);
extern void      put_unary1     (BitList *l, WTYPE value);
extern void      put_gamma      (BitList *l, WTYPE value);
extern void      put_delta      (BitList *l, WTYPE value);
extern void      put_omega      (BitList *l, WTYPE value);
extern void      put_fib        (BitList *l, WTYPE value);
extern void      put_fibgen     (BitList *l, int m, WTYPE value);
extern void      put_levenstein (BitList *l, WTYPE value);
extern void      put_evenrodeh  (BitList *l, WTYPE value);
extern void      put_goldbach_g1(BitList *l, WTYPE value);
extern void      put_goldbach_g2(BitList *l, WTYPE value);
extern void      put_binword    (BitList *l, int k, WTYPE value);
extern void      put_baer       (BitList *l, int k, WTYPE value);
extern void      put_boldivigna (BitList *l, int k, WTYPE value);
extern void      put_comma      (BitList *l, int k, WTYPE value);
extern void      put_block_taboo(BitList *l, int bits, WTYPE taboo, WTYPE value);
extern void      put_rice_sub   (BitList *l, SV* self, SV* code, int k, WTYPE value);
extern void      put_golomb_sub (BitList *l, SV* self, SV* code, WTYPE m, WTYPE value);
extern void      put_gamma_rice (BitList *l, int k, WTYPE value);
extern void      put_gamma_golomb (BitList *l, WTYPE m, WTYPE value);
extern void      put_adaptive_rice_sub (BitList *l, SV* self, SV* code, int *k, WTYPE value);
extern void      put_startstop  (BitList *l, const char* cmap, WTYPE value);

extern char*     make_startstop_prefix_map(SV* paramref);

#endif
