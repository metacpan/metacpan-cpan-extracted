#include <string.h>
#include <stdio.h>
#include <mad.h>

#include "resample.h"

static mad_fixed_t const resample_table[9][9] = {
  /* 48000 */ { MAD_F(0x10000000) /* 1.000000000 */,
		MAD_F(0x116a3b36) /* 1.088435374 */,
		MAD_F(0x18000000) /* 1.500000000 */,
		MAD_F(0x20000000) /* 2.000000000 */,
		MAD_F(0x22d4766c) /* 2.176870748 */,
		MAD_F(0x30000000) /* 3.000000000 */,
		MAD_F(0x40000000) /* 4.000000000 */,
		MAD_F(0x45a8ecd8) /* 4.353741497 */,
		MAD_F(0x60000000) /* 6.000000000 */ },

  /* 44100 */ { MAD_F(0x0eb33333) /* 0.918750000 */,
		MAD_F(0x10000000) /* 1.000000000 */,
		MAD_F(0x160ccccd) /* 1.378125000 */,
		MAD_F(0x1d666666) /* 1.837500000 */,
		MAD_F(0x20000000) /* 2.000000000 */,
		MAD_F(0x2c19999a) /* 2.756250000 */,
		MAD_F(0x3acccccd) /* 3.675000000 */,
		MAD_F(0x40000000) /* 4.000000000 */,
		MAD_F(0x58333333) /* 5.512500000 */ },

  /* 32000 */ { MAD_F(0x0aaaaaab) /* 0.666666667 */,
		MAD_F(0x0b9c2779) /* 0.725623583 */,
		MAD_F(0x10000000) /* 1.000000000 */,
		MAD_F(0x15555555) /* 1.333333333 */,
		MAD_F(0x17384ef3) /* 1.451247166 */,
		MAD_F(0x20000000) /* 2.000000000 */,
		MAD_F(0x2aaaaaab) /* 2.666666667 */,
		MAD_F(0x2e709de5) /* 2.902494331 */,
		MAD_F(0x40000000) /* 4.000000000 */ },

  /* 24000 */ { MAD_F(0x08000000) /* 0.500000000 */,
		MAD_F(0x08b51d9b) /* 0.544217687 */,
		MAD_F(0x0c000000) /* 0.750000000 */,
		MAD_F(0x10000000) /* 1.000000000 */,
		MAD_F(0x116a3b36) /* 1.088435374 */,
		MAD_F(0x18000000) /* 1.500000000 */,
		MAD_F(0x20000000) /* 2.000000000 */,
		MAD_F(0x22d4766c) /* 2.176870748 */,
		MAD_F(0x30000000) /* 3.000000000 */ },

  /* 22050 */ { MAD_F(0x0759999a) /* 0.459375000 */,
		MAD_F(0x08000000) /* 0.500000000 */,
		MAD_F(0x0b066666) /* 0.689062500 */,
		MAD_F(0x0eb33333) /* 0.918750000 */,
		MAD_F(0x10000000) /* 1.000000000 */,
		MAD_F(0x160ccccd) /* 1.378125000 */,
		MAD_F(0x1d666666) /* 1.837500000 */,
		MAD_F(0x20000000) /* 2.000000000 */,
		MAD_F(0x2c19999a) /* 2.756250000 */ },

  /* 16000 */ { MAD_F(0x05555555) /* 0.333333333 */,
		MAD_F(0x05ce13bd) /* 0.362811791 */,
		MAD_F(0x08000000) /* 0.500000000 */,
		MAD_F(0x0aaaaaab) /* 0.666666667 */,
		MAD_F(0x0b9c2779) /* 0.725623583 */,
		MAD_F(0x10000000) /* 1.000000000 */,
		MAD_F(0x15555555) /* 1.333333333 */,
		MAD_F(0x17384ef3) /* 1.451247166 */,
		MAD_F(0x20000000) /* 2.000000000 */ },

  /* 12000 */ { MAD_F(0x04000000) /* 0.250000000 */,
		MAD_F(0x045a8ecd) /* 0.272108844 */,
		MAD_F(0x06000000) /* 0.375000000 */,
		MAD_F(0x08000000) /* 0.500000000 */,
		MAD_F(0x08b51d9b) /* 0.544217687 */,
		MAD_F(0x0c000000) /* 0.750000000 */,
		MAD_F(0x10000000) /* 1.000000000 */,
		MAD_F(0x116a3b36) /* 1.088435374 */,
		MAD_F(0x18000000) /* 1.500000000 */ },

  /* 11025 */ { MAD_F(0x03accccd) /* 0.229687500 */,
		MAD_F(0x04000000) /* 0.250000000 */,
		MAD_F(0x05833333) /* 0.344531250 */,
		MAD_F(0x0759999a) /* 0.459375000 */,
		MAD_F(0x08000000) /* 0.500000000 */,
		MAD_F(0x0b066666) /* 0.689062500 */,
		MAD_F(0x0eb33333) /* 0.918750000 */,
		MAD_F(0x10000000) /* 1.000000000 */,
		MAD_F(0x160ccccd) /* 1.378125000 */ },

  /*  8000 */ { MAD_F(0x02aaaaab) /* 0.166666667 */, 
		MAD_F(0x02e709de) /* 0.181405896 */, 
		MAD_F(0x04000000) /* 0.250000000 */, 
		MAD_F(0x05555555) /* 0.333333333 */, 
		MAD_F(0x05ce13bd) /* 0.362811791 */, 
		MAD_F(0x08000000) /* 0.500000000 */, 
		MAD_F(0x0aaaaaab) /* 0.666666667 */, 
		MAD_F(0x0b9c2779) /* 0.725623583 */, 
		MAD_F(0x10000000) /* 1.000000000 */ }
};

static int rateidx(unsigned int rate) {
	switch (rate) {
		case 48000: return 0;
		case 44100: return 1;
		case 32000: return 2;
		case 24000: return 3;
		case 22050: return 4;
		case 16000: return 5;
		case 12000: return 6;
		case 11025: return 7;
		case  8000: return 8;
	}
	return -1;
}

int mad_resample_init(struct mad_resample *mr, unsigned int oldrate, unsigned int newrate) {
	int oldi = rateidx(oldrate);
	int newi = rateidx(newrate);

	if (oldi == -1 || newi == -1) {
		mr->mode = 2;
		return -1;
	}
	
	mr->state[0].step = 0;
	mr->state[0].last = 0;
	
	mr->state[1].step = 0;
	mr->state[1].last = 0;
	
	if ((mr->ratio = resample_table[oldi][newi]) == MAD_F_ONE)
		mr->mode = 2;
	else
		mr->mode = 1;
	

	return 0;
}

unsigned int mad_resample_block(struct mad_resample *mr, struct mad_resample_state *ms, unsigned int nsamples, mad_fixed_t const *old, mad_fixed_t *new) {
	mad_fixed_t const *end, *begin;

	if (mr->mode != 1)
		return 0;
		
	end   = old + nsamples;
	begin = new;

	if (ms->step < 0) {
		ms->step = mad_f_fracpart(-ms->step);
		
		while (ms->step < MAD_F_ONE) {
			*new++ = 
			  ms->step                                        ?
			  ms->last + mad_f_mul(*old - ms->last, ms->step) :
			  ms->last;
			  
			ms->step += mr->ratio;
			if (((ms->step + 0x00000080L) & 0x0fffff00L) == 0)
				ms->step = (ms->step + 0x00000080L) & ~0x0fffffffL;
		}
		
		ms->step -= MAD_F_ONE;
	}
	
	while (end - old > 1 + mad_f_intpart(ms->step)) {
		old      += mad_f_intpart(ms->step);
		ms->step  = mad_f_fracpart(ms->step);
		
		*new++ = 
		  ms->step                                    ? 
		  *old + mad_f_mul(old[1] - old[0], ms->step) : 
		  *old;
		  
		  ms->step += mr->ratio;
		  
		  if (((ms->step + 0x00000080L) & 0x0fffff00L) == 0)
		  	ms->step = (ms->step + 0x00000080L) & ~0x0fffffffL;
	}
	
	if (end - old == 1 + mad_f_intpart(ms->step)) {
		ms->last = end[-1];
		ms->step = -ms->step;
	} else {
		ms->step -= mad_f_fromint(end - old);
	}
	
	return new - begin;
}
