/* resample.h:  resampling engine.  resamples the naitve mad_fixed_t pcm
   stream,  using linear interpolation method lifted from mad-0.14.2b
   distribution. */

#define MAX_NSAMPLES (1152 * 3)
   
struct mad_resample {
	mad_fixed_t	ratio;

	struct mad_resample_state {
		mad_fixed_t	step;
		mad_fixed_t	last;
	} state[2];

	unsigned int	mode;  /* 0=uninit. 1=do resample 2=no resample */
};

int mad_resample_init(struct mad_resample *, unsigned int, unsigned int);
unsigned int mad_resample_block(struct mad_resample *, struct mad_resample_state *, unsigned int, mad_fixed_t const *, mad_fixed_t *);


	
