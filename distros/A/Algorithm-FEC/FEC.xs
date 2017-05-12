#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <unistd.h>
#include <sys/mman.h>

#include "fec.h"

struct fec_imp {
  void (*fec_free)(void *p) ;
  void *(*fec_new)(int k, int n) ;
  void (*fec_encode)(void *code, void *src[], void *dst, int index, int sz) ;
  int (*fec_decode)(void *code, void *pkt[], int index[], int sz) ;
};

static struct fec_imp fec8_imp  = { fec8_free , fec8_new , fec8_encode , fec8_decode  };
static struct fec_imp fec16_imp = { fec16_free, fec16_new, fec16_encode, fec16_decode };

typedef struct state {
  struct fec_imp *imp;
  void *code;
  int sz;
  int dp, ep;

  void **b_addr;
  void **b_mmap;
  int *b_sz;
  SV **b_sv;
  int *idx; /* the decoding indices */
} *Algorithm__FEC;

static void
chk_array (SV *sv, int size, const char *func, const char *var)
{
  if (!SvROK (sv)
      || SvTYPE (SvRV (sv)) != SVt_PVAV
      || av_len ((AV *)SvRV (sv)) != size - 1)
    croak ("%s: %s (%s) must be a reference to an array of size %d", func, SvPV_nolen (sv), var, size);
}

static void
free_files (struct state *self)
{
  int i;

  if (self->b_addr && self->b_sv)
    for (i = 0; i < self->dp; i++)
      if (self->b_sv[i])
        SvREFCNT_dec (self->b_sv[i]);
      else if (self->b_mmap[i])
        munmap (self->b_mmap[i], self->b_sz[i]);

  Safefree (self->b_addr); self->b_addr = 0;
  Safefree (self->b_mmap); self->b_mmap = 0;
  Safefree (self->b_sz  ); self->b_sz   = 0;
  Safefree (self->b_sv  ); self->b_sv   = 0;
  Safefree (self->idx   ); self->idx    = 0;
}

static void
realloc_files (struct state *self)
{
  free_files (self);

  Newz (0, self->b_addr, self->dp, void *);
  Newz (0, self->b_mmap, self->dp, void *);
  Newz (0, self->b_sz  , self->dp, int);
  Newz (0, self->b_sv  , self->dp, SV *);
}

static void
force_addrs (struct state *self, int dp)
{
  int i;

  for (i = 0; i < dp; i++)
    if (self->b_sv[i])
      {
        STRLEN size;
        self->b_addr[i] = SvPV_force (self->b_sv[i], size);

        if (size != self->sz)
          croak ("block #%d (a string) has size %d, not %d", i, (int)size, self->sz);
      } else if (!self->b_mmap[i]) {
        croak ("block #%d neither string nor file, did set_blocks fail and you ignored it?", i);
      }
}

static void
open_file (struct state *self, int idx, SV *sv, int rw)
{
  IO *io = 0;
  off_t offset;
  
  if (SvROK (sv) && SvTYPE (SvRV (sv)) == SVt_PVAV)
    {
      io = sv_2io (*av_fetch ((AV *)SvRV (sv), 0, 1));
      offset = SvIV (*av_fetch ((AV *)SvRV (sv), 1, 1));
      sv = 0;
    }
  else if (!SvPOK (sv))
    {
      io = sv_2io (sv);
      offset = 0;
      sv = 0;
    }

  if (io)
    {
      int fd = PerlIO_fileno (IoIFP (io));
      off_t ofs2 = offset & ~((off_t)getpagesize () - 1);
      void *mm;

      if (fd <= 0)
        croak ("invalid file descriptor for block #%d", idx);

      mm = mmap (0, self->sz + (offset - ofs2),
                       rw ? PROT_READ | PROT_WRITE : PROT_READ,
                       MAP_SHARED, fd, ofs2);

      if (mm == MAP_FAILED)
        croak ("unable to mmap block #%d (wrong offset or size?): %s", idx, strerror (errno));

      self->b_mmap[idx] = mm;
      self->b_addr[idx] = (void *)((char *)mm + (offset - ofs2));
      self->b_sz  [idx] = self->sz + (offset - ofs2);
    }
  else if (sv)
    self->b_sv[idx] = SvREFCNT_inc (sv);
  else
    croak ("unable to open block #%d, must be either string, filehandle, or [filehandle, offset]", idx);
}

static void
open_files (struct state *self, AV *av, int rw)
{
  int i;

  realloc_files (self);

  for (i = 0; i < self->dp; i++)
    open_file (self, i, *av_fetch (av, i, 1), rw);
}

MODULE = Algorithm::FEC		PACKAGE = Algorithm::FEC

PROTOTYPES: ENABLE

Algorithm::FEC
new(class, data_packets, encoded_packets, blocksize)
	SV *	class
	int	data_packets
        int	encoded_packets
        int	blocksize
	CODE:
        void *code;
        struct fec_imp *imp;

        if (data_packets < 2)
          croak ("the number of data packets must be >= 2"); /* for copy_blocks :) */

        if (encoded_packets < data_packets)
          croak ("the number of encoded packets must be >= the number of data packets");

        if (GF_SIZE16 < encoded_packets)
          croak ("the number of encoded packets must be <= %d", GF_SIZE16);

        imp = GF_SIZE8 < encoded_packets ? &fec16_imp : &fec8_imp;

        code = imp->fec_new (data_packets, encoded_packets);
        if (!code)
          croak ("FATAL: unable to create fec state");

        Newz(0, RETVAL, 1, struct state);
        RETVAL->imp = imp;
        RETVAL->code = code;
        RETVAL->sz = blocksize;
        RETVAL->dp = data_packets;
        RETVAL->ep = encoded_packets;
	OUTPUT:
        RETVAL

void
set_encode_blocks (self, blocks)
        Algorithm::FEC self
        SV *	blocks
	CODE:

        free_files (self);

        if (SvOK (blocks))
          {
            chk_array (blocks, self->dp, "set_encode_blocks", "blocks");
            open_files (self, (AV *)SvRV (blocks), 0);
          }

SV *
encode (self, block_index)
        Algorithm::FEC self
        int	block_index
	CODE:

        if (block_index < 0 || self->ep <= block_index)
          croak ("encode: block_index %d out of range, must be 0 <= block_index < %d",
                 block_index, self->ep);

        if (!self->b_addr)
          croak ("no blocks specified by a preceding call to set_encode_blocks");

        force_addrs (self, self->dp);

        RETVAL = newSV (self->sz);
        if (!RETVAL)
          croak ("unable to allocate result block (out of memory)");

        SvPOK_only (RETVAL);
        SvCUR_set (RETVAL, self->sz);

        self->imp->fec_encode (self->code, self->b_addr,
                               SvPVX (RETVAL), block_index, self->sz);

        OUTPUT:
        RETVAL

void
set_decode_blocks (self, blocks, indices)
        Algorithm::FEC self
        SV *	blocks
        SV *	indices
        ALIAS:
        shuffle = 1
	CODE:
{
        int i;
        int *idx;

        chk_array (blocks,  self->dp, "set_decode_blocks", "blocks");
        chk_array (indices, self->dp, "set_decode_blocks", "indices");

        Newz (0, idx, self->dp, int);

        /* copy and check */
        for (i = 0; i < self->dp; i++)
          {
            idx[i] = SvIV (*av_fetch ((AV *)SvRV (indices), i, 1));

            if (idx[i] < 0 || idx[i] >= self->ep)
              {
                Safefree (idx);
                croak ("index %d in array out of bounds (0 <= %d < %d != true)",
                       i, idx[i], self->ep);
              }
          }

        /*
         * do the same shuffling as fec_decode does here,
         * so we know the order.
         */
        for (i = 0; i < self->dp; i++)
          while (idx[i] < self->dp && idx[i] != i)
            {
              SV **a, **b, **e, **f;
              int d;
              void *p;
              SV *s;
              int j = idx[i];

              if (idx[j] == j)
                {
                  Safefree (idx);
                  croak ("error while shuffling, duplicate indices?");
                }

              a = av_fetch ((AV *)SvRV (indices), i, 1);
              b = av_fetch ((AV *)SvRV (indices), j, 1);
              e = av_fetch ((AV *)SvRV (blocks ), i, 1);
              f = av_fetch ((AV *)SvRV (blocks ), j, 1);

              d = idx[i]; idx[i] = idx[j]; idx[j] = d;
              s = *a;     *a     = *b;     *b = s;
              s = *e;     *e     = *f;     *f = s;
            }

        if (ix)
          Safefree (idx);
        else
          {
            open_files (self, (AV *)SvRV (blocks), 1);
            self->idx = idx;
          }
}

void
decode (self)
        Algorithm::FEC self
	CODE:

        if (!self->idx)
          croak ("index array must be set by a prior call to set_decode_blocks");

        force_addrs (self, self->dp);
        self->imp->fec_decode (self->code, self->b_addr, self->idx, self->sz);
        free_files (self);

void
copy (self, srcblock, dstblock)
        Algorithm::FEC self
	SV *	srcblock
        SV *	dstblock
        CODE:
        realloc_files (self);
        open_file (self, 0, srcblock, 0);
        open_file (self, 1, dstblock, 1);
        force_addrs (self, 2);
        Copy (self->b_addr[0], self->b_addr[1], self->sz, char);
        free_files (self);

void
DESTROY(self)
        Algorithm::FEC self
        CODE:
        self->imp->fec_free (self->code);
        free_files (self);
        Safefree(self);

