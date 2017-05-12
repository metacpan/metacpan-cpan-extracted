/* these two need to be on top for win32 */
#include <stdlib.h>
#include <audiere.h>

/* normal perl includes */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* ************************************************************************ */
using namespace audiere;

/*
(C) by Tels <http://bloodgate.com/perl/> 
*/

MODULE = Audio::Audiere::Audiere_perl	PACKAGE = Audio::Audiere

PROTOTYPES: DISABLE
#############################################################################
        
AudioDevicePtr*
_init_device(SV* classname, char* devicename, char* parameters)
  PREINIT:
    AudioDevicePtr* device;
    AudioDevice* dev;
  CODE:
    dev = OpenDevice(devicename, parameters);
    if (!dev)
      {
      RETVAL = NULL;
      }
    else
      {
      device = new AudioDevicePtr(OpenDevice(devicename, parameters));
      RETVAL = device;
      }
  OUTPUT:
      RETVAL

void
_drop_device(SV* classname, AudioDevicePtr* device)
  CODE:
    delete device;

const char*
getVersion(SV* classname)
  CODE:
    RETVAL = audiere::GetVersion();
  OUTPUT:	
    RETVAL

const char*
_get_name(AudioDevicePtr* device)
  CODE:
    RETVAL = (*device)->getName();
  OUTPUT:	
    RETVAL

##############################################################################
# Stream code

MODULE = Audio::Audiere::Audiere_perl	PACKAGE = Audio::Audiere::Stream

OutputStreamPtr*
_open(AudioDevicePtr* device, char* filename, bool buffer)
    PREINIT:
	OutputStreamPtr* stream;
  CODE:
     stream = new OutputStreamPtr(OpenSound(*device, filename, buffer));
     RETVAL = stream;
  OUTPUT:
    RETVAL

OutputStreamPtr*
_tone(AudioDevicePtr* device, double frequenzy)
  PREINIT:
    OutputStreamPtr* stream;
    SampleSourcePtr* sample;
  CODE:
    sample = new SampleSourcePtr(CreateTone(frequenzy));
    stream = new OutputStreamPtr(OpenSound(*device, *sample, true));
    RETVAL = stream;
  OUTPUT:
    RETVAL

OutputStreamPtr*
_square_wave(AudioDevicePtr* device, double frequenzy)
  PREINIT:
    OutputStreamPtr* stream;
    SampleSourcePtr* sample;
  CODE:
    sample = new SampleSourcePtr(CreateSquareWave(frequenzy));
    stream = new OutputStreamPtr(OpenSound(*device, *sample, true));
    RETVAL = stream;
  OUTPUT:
    RETVAL

OutputStreamPtr*
_pink_noise(AudioDevicePtr* device)
  PREINIT:
    OutputStreamPtr* stream;
    SampleSourcePtr* sample;
  CODE:
     sample = new SampleSourcePtr(CreatePinkNoise());
     stream = new OutputStreamPtr(OpenSound( *device, *sample, true));
     RETVAL = stream;
  OUTPUT:
    RETVAL

OutputStreamPtr*
_white_noise(AudioDevicePtr* device)
  PREINIT:
    OutputStreamPtr* stream;
    SampleSourcePtr* sample;
  CODE:
     sample = new SampleSourcePtr(CreateWhiteNoise());
     stream = new OutputStreamPtr(OpenSound( *device, *sample, true));
     RETVAL = stream;
  OUTPUT:
    RETVAL


void
_free_stream(OutputStreamPtr* stream)
  CODE:
    delete stream;

void
_play(OutputStreamPtr* stream)
  CODE:
    (*stream)->play();

void
_stop(OutputStreamPtr* stream)
  CODE:
    (*stream)->stop();

int
_getLength(OutputStreamPtr* stream)
  CODE:
    RETVAL = (*stream)->getLength();
  OUTPUT:
    RETVAL

float
_getPan(OutputStreamPtr* stream)
  CODE:
    RETVAL = (*stream)->getPan();
  OUTPUT:
    RETVAL

float
_setPan(OutputStreamPtr* stream, float pan)
  CODE:
    (*stream)->setPan(pan);
    RETVAL = (*stream)->getPan();
  OUTPUT:
    RETVAL


float
_getVolume(OutputStreamPtr* stream)
  CODE:
    RETVAL = (*stream)->getVolume();
  OUTPUT:
    RETVAL

float
_setVolume(OutputStreamPtr* stream, float vol)
  CODE:
    (*stream)->setVolume(vol);
    RETVAL = (*stream)->getVolume();
  OUTPUT:
    RETVAL


unsigned int
_getPosition(OutputStreamPtr* stream)
  CODE:
    RETVAL = (*stream)->getPosition();
  OUTPUT:
    RETVAL

unsigned int
_setPosition(OutputStreamPtr* stream, int pos)
  CODE:
    (*stream)->setPosition(pos);
    RETVAL = (*stream)->getPosition();
  OUTPUT:
    RETVAL


float
_getRepeat(OutputStreamPtr* stream)
  CODE:
    RETVAL = (*stream)->getRepeat();
  OUTPUT:
    RETVAL

bool
_setRepeat(OutputStreamPtr* stream, bool rep)
  CODE:
    (*stream)->setRepeat(rep);
    RETVAL = (*stream)->getRepeat();
  OUTPUT:
    RETVAL


float
_getPitch(OutputStreamPtr* stream)
  CODE:
    RETVAL = (*stream)->getPitchShift();
  OUTPUT:
    RETVAL

float
_setPitch(OutputStreamPtr* stream, double pitch)
  CODE:
    (*stream)->setPitchShift(pitch);
    RETVAL = (*stream)->getPitchShift();
  OUTPUT:
    RETVAL

##############################################################################

bool
_isPlaying(OutputStreamPtr* stream)
  CODE:
    RETVAL = (*stream)->isPlaying();
  OUTPUT:
    RETVAL

bool
_isSeekable(OutputStreamPtr* stream)
  CODE:
    RETVAL = (*stream)->isSeekable();
  OUTPUT:
    RETVAL


# EOF
##############################################################################

