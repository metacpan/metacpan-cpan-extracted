#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define MAX_AMPL 	32767
#define PCM_RATE	176400

struct crossfade_channels_s {
	short left;
	short right;
};

struct crossfade_s {
	int len;
	short *spline_out;
	short *spline_in;
};

int crossfade_ease_in_out_quad_func (float t, float b, float c, float d) {
	return -c *(t/=d)*(t-2) + b;
}

char *crossfade_build_easeout_quad_spline (int d) {
	unsigned int t = 0, v;
	short *spline, *s;
	
	d *= 44100;
	if ((spline = (short *) malloc(sizeof(short) * d)) == NULL)
		return NULL;
	
	s = spline;
	while (t != d) {
		v = crossfade_ease_in_out_quad_func(t++, 0, MAX_AMPL, d);	

		*s++ = MAX_AMPL - v;
	}
	
	return spline;
}

char *crossfade_build_easein_quad_spline (int d) {
	int t = 0, v;
	short *spline, *s;
	
	d *= 44100;
	if ((spline = (short *) malloc(sizeof(short) * d)) == NULL)
		return NULL;
	
	s = spline;
	while (t != d) {
		v = crossfade_ease_in_out_quad_func(t++, 0, MAX_AMPL, d);

		*s++ = v;
	}
	
	return spline;
}

struct crossfade_s *crossfade_init (int duration) {
	struct crossfade_s *crossfade = NULL;
	
	if ((crossfade = (struct crossfade_s *) malloc(sizeof (struct crossfade_s))) == NULL)
		return NULL;
	memset (crossfade, 0, sizeof (struct crossfade_s));
	
	if ((crossfade->spline_out = (short *) crossfade_build_easeout_quad_spline(duration)) == NULL)
		goto clean;
	
	if ((crossfade->spline_in = (short *) crossfade_build_easein_quad_spline(duration)) == NULL)
		goto clean;	
		
	crossfade->len  = duration * PCM_RATE;
	
	return crossfade;
	
clean:
	if (crossfade->spline_out)
		free (crossfade->spline_out);
	if (crossfade->spline_in)
		free (crossfade->spline_in);
	
	return NULL;
}

unsigned int CROSSFADE_init (int duration) {
	return (unsigned int) crossfade_init(duration);
}

void crossfade_ease_in_out_quad (struct crossfade_s *crossfade, char *out, char *in, char *result) {
	struct crossfade_channels_s *chout, *chin, *chresult;
	short *spout, *spin;
	double dout, din;
	int r = 0;
	
	chout = (struct crossfade_channels_s *) out;
	chin = (struct crossfade_channels_s *) in;
	chresult = (struct crossfade_channels_s *) result;
	
	spout = crossfade->spline_out;
	spin = crossfade->spline_in;
	
	while (r < crossfade->len) {
		dout = ((double) *spout) / MAX_AMPL;
		din = ((double) *spin) / MAX_AMPL;
		
		chresult->left = (double) chout->left * dout + (double) chin->left * din;
		chresult->right = (double) chout->right * dout + (double) chin->right * din;
		
		chout++;
		chin++;
		chresult++;
		spout++;
		spin++;
		
		r += sizeof (struct crossfade_channels_s);
	}
}

void CROSSFADE_ease_in_out_quad (int crossfade, SV *out, SV *in, SV *result) {
	crossfade_ease_in_out_quad ((struct crossfade_s *) crossfade, SvPVX(out), SvPVX(in), SvPVX(result));
}


MODULE = Audio::C4Stream::Mixer	PACKAGE = Audio::C4Stream::Mixer

PROTOTYPES: DISABLE


int
crossfade_ease_in_out_quad_func (t, b, c, d)
	float	t
	float	b
	float	c
	float	d

char *
crossfade_build_easeout_quad_spline (d)
	int	d

char *
crossfade_build_easein_quad_spline (d)
	int	d

unsigned int
CROSSFADE_init (duration)
	int	duration

void
CROSSFADE_ease_in_out_quad (crossfade, out, in, result)
	int	crossfade
	SV *	out
	SV *	in
	SV *	result
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	CROSSFADE_ease_in_out_quad(crossfade, out, in, result);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */