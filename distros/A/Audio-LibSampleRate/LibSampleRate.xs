#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <samplerate.h>
/*
struct generic_callback_data {
	SV* cb_data;
	SV* func;
	int channels;
};

long _generic_callback(void *cb_data, float **data){
	struct generic_callback_data gc_data;
	int nr;

	gc_data = *(struct generic_callback_data*)cb_data;

	dSP;
	PUSHMARK(SP);
	XPUSHs(gc_data.cb_data);
	PUTBACK;
	nr = call_sv(gc_data.func, G_ARRAY);
	SPAGAIN;
	while(nr--)
	return nr / 
}
*/

/*SV*
callback_new(pkg, func, converter_type = 0, channels = 2, cb_data = &PL_sv_undef)
    const char *pkg
    SV* pkg
    int converter_type
    int channels
    SV* cb_data
  PREINIT:
    int error;
    SRC_STATE *state;
  CODE:
    state = src_new(converter_type, channels, &error);
    if(state == NULL) {
         croak("src_new failed with error %d (%s)\n", error, src_strerror(error));
    }
    RETVAL = sv_setref_iv(newSV(0), pkg, PTR2IV(state));
  OUTPUT:
    RETVAL
*/

#define cerror(func) croak("%s failed with error %d (%s)\n", func, error, src_strerror(error))
#define SELF INT2PTR(SRC_STATE*, SvIV(SvRV(self)))

MODULE = Audio::LibSampleRate PACKAGE = Audio::LibSampleRate
PROTOTYPES: ENABLE

void
src_simple(data_in, src_ratio, converter_type = 0, channels = 2)
    AV* data_in
    double src_ratio
    int converter_type
    int channels
  PREINIT:
    SRC_DATA data;
    AV* data_out;
    float *in, *out;
    int i, error;
  PPCODE:
    data.input_frames = (av_len(data_in) + 1) / channels;
    data.output_frames = data.input_frames * src_ratio + 10;
    Newx(in, data.input_frames * channels, float);
    Newx(out, data.output_frames * channels, float);
    for(i = 0 ; i <= av_len(data_in) ; i++)
        if(av_exists(data_in, i))
            in[i] = SvNV(*av_fetch(data_in, i, 0));
    data.data_in = in;
    data.data_out = out;
    data.src_ratio = src_ratio;
    if (error = src_simple(&data, converter_type, channels))
         cerror("src_simple");
    EXTEND(SP, data.output_frames_gen);
    for(i = 0 ; i < data.output_frames_gen ; i++)
        PUSHs(sv_2mortal(newSVnv(data.data_out[i])));
    Safefree(in);
    Safefree(out);

SV*
new(pkg, converter_type = 0, channels = 2)
    const char *pkg
    int converter_type
    int channels
  PREINIT:
    int error;
    SRC_STATE *state;
  CODE:
    state = src_new(converter_type, channels, &error);
    if(state == NULL)
        cerror("src_new");
    RETVAL = sv_setref_iv(newSV(0), pkg, PTR2IV(state));
  OUTPUT:
    RETVAL

void
DESTROY(self)
  SV* self
  CODE:
    src_delete(SELF);

void
process(self, data_in, src_ratio, end_of_input = 0)
    SV* self
    AV* data_in
    double src_ratio
    int end_of_input
  PREINIT:
    SRC_DATA data;
    AV* data_out;
    float *in, *out;
    int i, error;
  PPCODE:
    data.input_frames = av_len(data_in) + 1;
    data.output_frames = data.input_frames * src_ratio + 10;
    Newx(in, data.input_frames, float);
    Newx(out, data.output_frames, float);
    for(i = 0 ; i <= av_len(data_in) ; i++)
        if(av_exists(data_in, i))
            in[i] = SvNV(*av_fetch(data_in, i, 0));
    data.data_in = in;
    data.data_out = out;
    data.src_ratio = src_ratio;
    data.end_of_input = end_of_input;
    if(error = src_process(SELF, &data))
        cerror("src_process");
    EXTEND(SP, data.output_frames_gen);
    for(i = 0 ; i < data.output_frames_gen ; i++)
        PUSHs(sv_2mortal(newSVnv(data.data_out[i])));

void
reset(self)
    SV* self
  PREINIT:
    int error;
  CODE:
    if(error = src_reset(SELF))
        cerror("src_reset");

void
set_ratio(self, new_ratio)
    SV* self
    double new_ratio
  PREINIT:
    int error;
  CODE:
    if(error = src_set_ratio(SELF, new_ratio))
        cerror("src_set_ratio");

const char*
src_get_name(converter_type)
    int converter_type

const char*
src_get_description(converter_type)
    int converter_type
