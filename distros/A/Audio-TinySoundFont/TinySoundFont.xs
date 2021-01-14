#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define TSF_IMPLEMENTATION
#define TSF_STATIC
#include "TinySoundFont/tsf.h"

typedef tsf* Audio__TinySoundFont__XS;

#define SAMPLE_RATE 44100

static int atsf_perlio_read(PerlIO* f, void* ptr, unsigned int size)
{
  dTHX;
  return (int)PerlIO_read(f, ptr, size);
}

static int atsf_perlio_skip(PerlIO* f, unsigned int count)
{
  dTHX;
  return !PerlIO_seek(f, count, SEEK_CUR);
}

MODULE = Audio::TinySoundFont  PACKAGE = Audio::TinySoundFont::XS

BOOT:
{
    HV *stash = gv_stashpv("Audio::TinySoundFont::XS", 0);

    newCONSTSUB(stash, "SAMPLE_RATE",        newSViv(SAMPLE_RATE));
    newCONSTSUB(stash, "MONO",               newSViv(TSF_MONO));
    newCONSTSUB(stash, "STEREO_INTERLEAVED", newSViv(TSF_STEREO_INTERLEAVED));
    newCONSTSUB(stash, "STEREO_UNWEAVED",    newSViv(TSF_STEREO_UNWEAVED));
}

Audio::TinySoundFont::XS
load_file(CLASS, filename)
    SV *CLASS = NO_INIT
    const char* filename
  CODE:
    RETVAL = tsf_load_filename(filename);
    if ( RETVAL == NULL )
    {
      croak("Unable to load file: %s\n", filename);
    }
    tsf_set_output(RETVAL, TSF_MONO, SAMPLE_RATE, -10);
  OUTPUT:
    RETVAL

Audio::TinySoundFont::XS
load_fh(CLASS, fh)
    SV *CLASS = NO_INIT
    PerlIO* fh
  CODE:
    struct tsf_stream stream = {
      fh,
      (int(*)(void*,void*,unsigned int))&atsf_perlio_read,
      (int(*)(void*,unsigned int))&atsf_perlio_skip
    };
    RETVAL = tsf_load(&stream);
    if ( RETVAL == NULL )
    {
      croak("Unable to load: %p\n", fh);
    }
    tsf_set_output(RETVAL, TSF_MONO, SAMPLE_RATE, -10);
  OUTPUT:
    RETVAL

int
presetcount(self)
    Audio::TinySoundFont::XS self
  CODE:
    RETVAL = tsf_get_presetcount(self);
  OUTPUT:
    RETVAL

const char*
get_presetname(self, preset_idx)
    Audio::TinySoundFont::XS self
    int preset_idx
  CODE:
    RETVAL = tsf_get_presetname(self, preset_idx);
  OUTPUT:
    RETVAL

int
active_voices(self)
    Audio::TinySoundFont::XS self
  CODE:
    RETVAL = tsf_active_voice_count(self);
  OUTPUT:
    RETVAL

void
set_volume(self, global_gain);
    Audio::TinySoundFont::XS self
    float global_gain
  CODE:
    global_gain = global_gain < 0 ? 0
                : global_gain > 1 ? 1
                : global_gain;
    tsf_set_volume(self, global_gain);

void
note_on(self, preset_idx, note, velocity)
    Audio::TinySoundFont::XS self
    int preset_idx
    int note
    float velocity
  CODE:
    tsf_note_on(self, preset_idx, note, velocity);

void
note_off(self, preset_idx, note)
    Audio::TinySoundFont::XS self
    int preset_idx
    int note
  CODE:
    tsf_note_off(self, preset_idx, note);

SV *
render(self, samples)
    Audio::TinySoundFont::XS self
    int samples
  CODE:
    int slen = samples * sizeof(short);
    if ( slen == 0 )
    {
      XSRETURN_PV("");
    }
    RETVAL = newSV(slen);
    SvCUR_set(RETVAL,  slen);
    SvPOK_only(RETVAL);
    STRLEN len;
    short* buffer;
    buffer = (short *)SvPVX(RETVAL);
    tsf_render_short(self, buffer, samples, 0);
    *(SvEND(RETVAL)) = '\0';
  OUTPUT:
    RETVAL
