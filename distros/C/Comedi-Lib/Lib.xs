/*
 * Part of Comedi::Lib
 *
 * Copyright (c) 2009 Manuel Gebele <forensixs@gmx.de>, Germany
 *
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <comedilib.h>

int lib_close(comedi_t *dev)
{
   return comedi_close(dev);
}

comedi_t *lib_open(const char *fn)
{
   return comedi_open(fn);
}

int lib_loglevel(int level)
{
   return comedi_loglevel(level);
}

void lib_perror(const char *str)
{
   return comedi_perror(str);
}

const char *lib_strerror(int errnum)
{
   return comedi_strerror(errnum);
}

int lib_errno()
{
   return comedi_errno();
}

int lib_fileno(comedi_t *dev)
{
   return comedi_fileno(dev);
}

int lib_get_n_subdevices(comedi_t *dev)
{
   return comedi_get_n_subdevices(dev);
}

int lib_get_version_code(comedi_t *dev)
{
   return comedi_get_version_code(dev);
}

const char *lib_get_driver_name(comedi_t *dev)
{
   return comedi_get_driver_name(dev);
}

const char *lib_get_board_name(comedi_t *dev)
{
   return comedi_get_board_name(dev);
}

int lib_get_subdevice_type(comedi_t *dev, unsigned int subdev)
{
   return comedi_get_subdevice_type(dev, subdev);
}

int lib_find_subdevice_by_type(comedi_t *dev, int type, unsigned int start)
{
   return comedi_find_subdevice_by_type(dev, type, start);
}

int lib_get_read_subdevice(comedi_t *dev)
{
   return comedi_get_read_subdevice(dev);
}

int lib_get_write_subdevice(comedi_t *dev)
{
   return comedi_get_write_subdevice(dev);
}

int lib_get_subdevice_flags(comedi_t *dev, unsigned int subdev)
{
   return comedi_get_subdevice_flags(dev, subdev);
}

int lib_get_n_channels(comedi_t *dev, unsigned int subdev)
{
   return comedi_get_n_channels(dev, subdev);
}

int lib_range_is_chan_specific(comedi_t *dev, unsigned int subdev)
{
   return comedi_range_is_chan_specific(dev, subdev);
}

int lib_maxdata_is_chan_specific(comedi_t *dev, unsigned int subdev)
{
   return comedi_maxdata_is_chan_specific(dev, subdev);
}

lsampl_t lib_get_maxdata(comedi_t *dev, unsigned int subdev,
                         unsigned int chan)
{
   return comedi_get_maxdata(dev, subdev, chan);
}

int lib_get_n_ranges(comedi_t *dev, unsigned int subdev, unsigned int chan)
{
   return comedi_get_n_ranges(dev, subdev, chan);
}

/* Comedilib returns a pointer to a comedi_range structure */
HV *lib_get_range(comedi_t *dev, unsigned int subdev, unsigned int chan,
                  unsigned int rng)
{
   comedi_range *range;
   HV *range_hash = (HV *)sv_2mortal((SV *)newHV());

   range = comedi_get_range(dev, subdev, chan, rng);
   if (!range) {
      hv_undef(range_hash); /* optional */
      return range_hash;
   }
   
   /*
    * The comedi_range structure contains the following components:
    * double min;
    * double max;
    * unsigned int unit;
    */
   hv_store(range_hash, "min",  3, newSVnv(range->min),  0);
   hv_store(range_hash, "max",  3, newSVnv(range->max),  0);
   hv_store(range_hash, "unit", 4, newSVuv(range->unit), 0);

   return range_hash;
}

int lib_find_range(comedi_t *dev, unsigned int subdev, unsigned int chan,
                   unsigned int unit, double min, double max)
{
   return comedi_find_range(dev, subdev, chan, unit, min, max);
}

int lib_get_buffer_size(comedi_t *dev, unsigned int subdev)
{
    return comedi_get_buffer_size(dev, subdev);
}

int lib_get_max_buffer_size(comedi_t *dev, unsigned int subdev)
{
   return comedi_get_max_buffer_size(dev, subdev);
}

int lib_set_buffer_size(comedi_t *dev, unsigned int subdev, unsigned int size)
{
   return comedi_set_buffer_size(dev, subdev, size);
}

/* _DEPRECATED_ - comedi_trigger */

int lib_do_insn(comedi_t *dev, HV *insn_ref)
{
   SV **insn, **n, **subdev, **chanspec, **data;
   AV *data_arr;
   int len;
   unsigned int *insn_data;
   int i;
   SV **ele;
   comedi_insn cinsn;
   int retval;

   if (!(insn = hv_fetch(insn_ref, "insn", 4, 0)))
      return -1;

   if (!(n = hv_fetch(insn_ref, "n", 1, 0)))
      return -1;

   if (!(subdev = hv_fetch(insn_ref, "subdev", 6, 0)))
      return -1;

   if (!(chanspec = hv_fetch(insn_ref, "chanspec", 8, 0)))
      return -1;

   if (!(data = hv_fetch(insn_ref, "data", 4, 0)))
      return -1;

   if (!(data_arr = (AV *)SvRV(*data)))
      return -1;

   len = av_len(data_arr);
   if (len == -1)
      /* An empty array makes no sense at all */
      return len;

   Newx(insn_data, len + 1, unsigned int);

   for (i = 0; i <= len; i++) {
      if (!(ele = av_fetch(data_arr, i, FALSE)))
         return -1;
      insn_data[i] = SvUV(*ele);
   }

   cinsn.insn = SvUV(*insn);
   cinsn.n = SvUV(*n);
   cinsn.data = insn_data;
   cinsn.subdev = SvUV(*subdev);
   cinsn.chanspec = SvUV(*chanspec);

   if ((retval = comedi_do_insn(dev, &cinsn)) == -1)
      return retval;

   /* Copy back, essential for a number of
    * instructions (e.g. INSN_READ) */
   for (i = 0; i <= len; i++)
      av_store(data_arr, i, newSVuv(cinsn.data[i]));

   return retval;
}

int lib_do_insnlist(comedi_t *dev, HV *insnlist_ref)
{
   SV **n_insns, **insns;
   AV *insns_arr;
   int insns_len;
   comedi_insn *insns_tmp;
   AV **data_arr;
   int *data_len;
   int i;
   SV **insn_ele;
   HV *insn_hash;
   SV **insn, **n, **subdev, **chanspec, **data;
   unsigned int *insn_data;
   int j;
   SV **data_ele;
   comedi_insn cinsn;
   comedi_insnlist insnlist;
   int retval;

   if (!(n_insns = hv_fetch(insnlist_ref, "n_insns", 7, 0)))
      return -1;

   if (n_insns <= 0) /* There's nothing to do */
      return 0;

   if (!(insns = hv_fetch(insnlist_ref, "insns", 5, 0)))
      return -1;

   if (!(insns_arr = (AV *)SvRV(*insns)))
      return -1;

   insns_len = av_len(insns_arr);
   if (insns_len == -1)
      /* An empty array makes no sense at all */
      return insns_len;

   Newx(insns_tmp, insns_len + 1, comedi_insn);
   Newx(data_arr, insns_len + 1, AV *);
   Newx(data_len, insns_len + 1, int);

   for (i = 0; i <= insns_len; i++) {
      if (!(insn_ele = av_fetch(insns_arr, i, FALSE)))
         return -1;

      if (!(insn_hash = (HV *)SvRV(*insn_ele)))
         return -1;

      if (!(insn = hv_fetch(insn_hash, "insn", 4, 0)))
         return -1;

      if (!(n = hv_fetch(insn_hash, "n", 1, 0)))
         return -1;

      if (!(subdev = hv_fetch(insn_hash, "subdev", 6, 0)))
         return -1;
      
      if (!(chanspec = hv_fetch(insn_hash, "chanspec", 8, 0)))
         return -1;

      if (!(data = hv_fetch(insn_hash, "data", 4, 0)))
         return -1;

      if (!(data_arr[i] = (AV *)SvRV(*data)))
         return -1;

      data_len[i] = av_len(data_arr[i]);
      if (data_len[i] == -1)
         continue; /* Or better return -1 ? */

      Newx(insn_data, data_len[i] + 1, unsigned int);

      for (j = 0; j <= data_len[i]; j++) {
         if (!(data_ele = av_fetch(data_arr[i], j, FALSE)))
            return -1;
         insn_data[j] = SvUV(*data_ele);
      }

      cinsn.insn = SvUV(*insn);
      cinsn.n = SvUV(*n);
      cinsn.data = insn_data;
      cinsn.subdev = SvUV(*subdev);
      cinsn.chanspec = SvUV(*chanspec);
   
      insns_tmp[i] = cinsn;
   }

   insnlist.n_insns = SvUV(*n_insns);
   insnlist.insns = insns_tmp;

   retval = comedi_do_insnlist(dev, &insnlist);
   if (retval == -1)
      return retval;

   /* Copy back */
   for (i = 0; i <= insns_len; i++)
      for (j = 0; j <= data_len[i]; j++)
         av_store(data_arr[i], j, newSViv(insnlist.insns[i].data[j]));
   
   return retval;
}

int lib_lock(comedi_t *dev, unsigned int subdev)
{
   return comedi_lock(dev, subdev);
}

int lib_unlock(comedi_t *dev, unsigned int subdev)
{
   return comedi_unlock(dev, subdev);
}

/* _DEPRECATED_ - comedi_to_phys */
/* _DEPRECATED_ - comedi_from_phys */

int lib_data_read(comedi_t *dev, unsigned int subdev, unsigned int chan,
                  unsigned int rng, unsigned int aref, SV *data)
{
   int retval;
   lsampl_t data_tmp;
   SV *sv;

   retval = comedi_data_read(dev, subdev, chan, rng, aref, &data_tmp);
   if (retval == -1)
      return retval;   

   sv = SvRV(data);
   sv_setuv(sv, data_tmp);

   return retval;
}

int lib_data_read_delayed(comedi_t *dev, unsigned int subdev, unsigned int chan,
                          unsigned int rng, unsigned int aref, SV *data,
                          unsigned int ns)
{
   int retval;
   lsampl_t data_tmp;
   SV *sv;

   retval = comedi_data_read_delayed(dev, subdev, chan, rng, aref, &data_tmp,
                                     ns);
   if (retval == -1)
      return retval;

   sv = SvRV(data);
   sv_setuv(sv, data_tmp);

   return retval;
}

int lib_data_read_hint(comedi_t *dev, unsigned int subdev, unsigned int chan,
                       unsigned int rng, unsigned int aref)
{
   return comedi_data_read_hint(dev, subdev, chan, rng, aref);   
}

int lib_data_write(comedi_t *dev, unsigned int subdev, unsigned int chan,
                   unsigned int rng, unsigned int aref, lsampl_t data)
{
   return comedi_data_write(dev, subdev, chan, rng, aref, data);
}

int lib_dio_config(comedi_t *dev, unsigned int subdev, unsigned int chan,
                   unsigned int dir)
{
   return comedi_dio_config(dev, subdev, chan, dir);
}

int lib_dio_get_config(comedi_t *dev, unsigned int subdev, unsigned int chan,
                       SV *dir)
{
   int retval;
   unsigned int dir_tmp;
   SV *sv;

   retval = comedi_dio_get_config(dev, subdev, chan, &dir_tmp);
   if (retval == -1)
      return retval;

   sv = SvRV(dir);
   sv_setuv(sv, dir_tmp);
   
   return retval;
}

int lib_dio_read(comedi_t *dev, unsigned int subdev, unsigned int chan,
                 SV *bit)
{
   int retval;
   unsigned int bit_tmp;
   SV *sv;

   retval = comedi_dio_read(dev, subdev, chan, &bit_tmp);
   if (retval == -1)
      return retval;

   sv = SvRV(bit);
   sv_setuv(sv, bit_tmp);

   return retval;
}

int lib_dio_write(comedi_t *dev, unsigned int subdev, unsigned int chan,
                  unsigned int bit)
{
   return comedi_dio_write(dev, subdev, chan, bit);
}

/* _DEPRECATED_ - comedi_dio_bitfield */

int lib_dio_bitfield2(comedi_t *dev, unsigned int subdev,
                      unsigned int write_mask, SV *bits,
                      unsigned int base_ch)
{
   int retval;
   unsigned int bits_tmp;
   SV *sv;

   retval = comedi_dio_bitfield2(dev, subdev, write_mask, &bits_tmp, base_ch);
   if (retval == -1)
      return retval;

   sv = SvRV(bits);
   sv_setuv(sv, bits_tmp);

   return retval;
}

/* _DEPRECATED_ - comedi_sv_init */
/* _DEPRECATED_ - comedi_sv_update */
/* _DEPRECATED_ - comedi_sv_measure */

/* Not implemented yet - comedi_get_cmd_src_mask */
/* Not implemented yet - comedi_get_cmd_generic_timed */

int lib_cancel(comedi_t *dev, unsigned int subdev)
{
   return comedi_cancel(dev, subdev);
}

/* Not implemented yet - comedi_command */
/* Not implemented yet - comedi_command_test */

int lib_poll(comedi_t *dev, unsigned int subdev)
{
   return comedi_poll(dev, subdev);
}

int lib_set_max_buffer_size(comedi_t *dev, unsigned int subdev,
                            unsigned int max_size)
{
   return comedi_set_max_buffer_size(dev, subdev, max_size);
}

int lib_get_buffer_contents(comedi_t *dev, unsigned int subdev)
{
   return comedi_get_buffer_contents(dev, subdev);
}

int lib_mark_buffer_read(comedi_t *dev, unsigned int subdev,
                         unsigned int num_bytes)
{
   return comedi_mark_buffer_read(dev, subdev, num_bytes);
}

int lib_mark_buffer_written(comedi_t *dev, unsigned int subdev,
                            unsigned int num_bytes)
{
   return comedi_mark_buffer_written(dev, subdev, num_bytes);
}

int lib_get_buffer_offset(comedi_t *dev, unsigned int subdev)
{
   return comedi_get_buffer_offset(dev, subdev);
}

/* _DEPRECATED_ - comedi_get_timer */
/* _DEPRECATED_ - comedi_timed_1chan */

MODULE = Comedi::Lib	PACKAGE = Comedi::Lib	

PROTOTYPES: DISABLE


int
lib_close (dev)
	comedi_t *	dev

comedi_t *
lib_open (fn)
	const char *	fn

int
lib_loglevel (level)
	int	level

void
lib_perror (str)
	const char *	str
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	lib_perror(str);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

const char *
lib_strerror (errnum)
	int	errnum

int
lib_errno ()

int
lib_fileno (dev)
	comedi_t *	dev

int
lib_get_n_subdevices (dev)
	comedi_t *	dev

int
lib_get_version_code (dev)
	comedi_t *	dev

const char *
lib_get_driver_name (dev)
	comedi_t *	dev

const char *
lib_get_board_name (dev)
	comedi_t *	dev

int
lib_get_subdevice_type (dev, subdev)
	comedi_t *	dev
	unsigned int	subdev

int
lib_find_subdevice_by_type (dev, type, start)
	comedi_t *	dev
	int	type
	unsigned int	start

int
lib_get_read_subdevice (dev)
	comedi_t *	dev

int
lib_get_write_subdevice (dev)
	comedi_t *	dev

int
lib_get_subdevice_flags (dev, subdev)
	comedi_t *	dev
	unsigned int	subdev

int
lib_get_n_channels (dev, subdev)
	comedi_t *	dev
	unsigned int	subdev

int
lib_range_is_chan_specific (dev, subdev)
	comedi_t *	dev
	unsigned int	subdev

int
lib_maxdata_is_chan_specific (dev, subdev)
	comedi_t *	dev
	unsigned int	subdev

lsampl_t
lib_get_maxdata (dev, subdev, chan)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	chan

int
lib_get_n_ranges (dev, subdev, chan)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	chan

HV *
lib_get_range (dev, subdev, chan, rng)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	chan
	unsigned int	rng

int
lib_find_range (dev, subdev, chan, unit, min, max)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	chan
	unsigned int	unit
	double	min
	double	max

int
lib_get_buffer_size (dev, subdev)
	comedi_t *	dev
	unsigned int	subdev

int
lib_get_max_buffer_size (dev, subdev)
	comedi_t *	dev
	unsigned int	subdev

int
lib_set_buffer_size (dev, subdev, size)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	size

int
lib_do_insn (dev, insn_ref)
	comedi_t *	dev
	HV *	insn_ref

int
lib_do_insnlist (dev, insnlist_ref)
	comedi_t *	dev
	HV *	insnlist_ref

int
lib_lock (dev, subdev)
	comedi_t *	dev
	unsigned int	subdev

int
lib_unlock (dev, subdev)
	comedi_t *	dev
	unsigned int	subdev

int
lib_data_read (dev, subdev, chan, rng, aref, data)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	chan
	unsigned int	rng
	unsigned int	aref
	SV *	data

int
lib_data_read_delayed (dev, subdev, chan, rng, aref, data, ns)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	chan
	unsigned int	rng
	unsigned int	aref
	SV *	data
	unsigned int	ns

int
lib_data_read_hint (dev, subdev, chan, rng, aref)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	chan
	unsigned int	rng
	unsigned int	aref

int
lib_data_write (dev, subdev, chan, rng, aref, data)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	chan
	unsigned int	rng
	unsigned int	aref
	lsampl_t	data

int
lib_dio_config (dev, subdev, chan, dir)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	chan
	unsigned int	dir

int
lib_dio_get_config (dev, subdev, chan, dir)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	chan
	SV *	dir

int
lib_dio_read (dev, subdev, chan, bit)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	chan
	SV *	bit

int
lib_dio_write (dev, subdev, chan, bit)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	chan
	unsigned int	bit

int
lib_dio_bitfield2 (dev, subdev, write_mask, bits, base_ch)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	write_mask
	SV *	bits
	unsigned int	base_ch

int
lib_cancel (dev, subdev)
	comedi_t *	dev
	unsigned int	subdev

int
lib_poll (dev, subdev)
	comedi_t *	dev
	unsigned int	subdev

int
lib_set_max_buffer_size (dev, subdev, max_size)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	max_size

int
lib_get_buffer_contents (dev, subdev)
	comedi_t *	dev
	unsigned int	subdev

int
lib_mark_buffer_read (dev, subdev, num_bytes)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	num_bytes

int
lib_mark_buffer_written (dev, subdev, num_bytes)
	comedi_t *	dev
	unsigned int	subdev
	unsigned int	num_bytes

int
lib_get_buffer_offset (dev, subdev)
	comedi_t *	dev
	unsigned int	subdev

