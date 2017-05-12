/*
 * Audio::PortAudio perl modules for portable audio I/O
 * Copyright (C) 2007  Joost Diepenmaat.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * See the COPYING file for more information.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "portaudio.h"
#include "ppport.h"
#include <limits.h>

#define THROW_PA_ERROR if (err != paNoError) croak(Pa_GetErrorText(err));

#define Audio_PortAudio_HostAPI int
#define Audio_PortAudio_Device  int
#define Audio_PortAudio_Stream  PaStream*

const PaStreamParameters* sv_to_stream_parameters(SV* sv) {
    HV* hv;
    SV** valuep;
    PaStreamParameters* sp;
    SV** fvaluep;
    if (!(SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV)) {
        return NULL;
    }
    hv = (HV*) SvRV(sv);
    Newx(sp, 1, PaStreamParameters);
    if (!sp) croak("Can't allocate PaStreamParameters struct");
    valuep = hv_fetch(hv, "device", 6, 0);
    if (!valuep) croak("Missing device parameter");
    sp->device = SvIV(SvRV(*valuep));
    valuep = hv_fetch(hv,"channel_count",13,0);
    if (!valuep) croak("Missing cannel_count parameter");
    sp->channelCount = SvIV(*valuep);
    valuep = hv_fetch(hv,"sample_format",13,0);
    if (valuep) {
        sp->sampleFormat = SvUV(*valuep);
    }
    else {
        sp->sampleFormat = 1; /* floating points range -1 .. 1 */
    }
    valuep = hv_fetch(hv,"latency",7,0);
    if (valuep) {
        sp->suggestedLatency = SvNV(*valuep);
    }
    else {
        sp->suggestedLatency = 0;
    }
    sp->hostApiSpecificStreamInfo = NULL;
    return sp;
}

MODULE = Audio::PortAudio::Stream PACKAGE = Audio::PortAudio::Stream

INCLUDE: stream-constants.xs

int
_internal_read_stream( self, buffer, frames, typesize, channels )
    Audio_PortAudio_Stream self
    SV* buffer
    unsigned long frames
    int typesize
    int channels
    PREINIT:
    unsigned long blen;
    void *realbuffer;
    CODE:
    if (typesize == 0) croak("typesize = 0");
    if (channels == 0) croak("channels = 0");
    if (SvPOK(buffer)) {
        SvPOK_only(buffer);
    }
    else {
        SvPV_force(buffer,PL_na);
    }
    blen = ((frames * typesize *channels) +1);
    realbuffer = (void *) SvGROW(buffer, blen);
    RETVAL = !Pa_ReadStream(self, realbuffer, frames);
    SvCUR_set(buffer,(STRLEN) (frames * typesize * channels));
    OUTPUT:
    RETVAL

int
_internal_write_stream( self, buffer, typesize,channels)
    Audio_PortAudio_Stream self
    SV* buffer
    int typesize
    int channels
    CODE:
    if (typesize == 0) croak("typesize = 0");
    if (channels == 0) croak("channels = 0");
/*warn("%d %d %d",typesize, channels, SvCUR(buffer) / ( typesize * channels) );*/
RETVAL = !Pa_WriteStream( self, (const void*) SvPV_nolen(buffer), SvCUR(buffer) / ( typesize * channels));
    OUTPUT:
    RETVAL

void
_start(self)
    Audio_PortAudio_Stream self
    PREINIT:
    int err;
    CODE:
    err = Pa_StartStream(self);
    THROW_PA_ERROR

void
_stop(self)
    Audio_PortAudio_Stream self
    PREINIT:
    int err;
    CODE:
    err = Pa_StopStream(self);
    THROW_PA_ERROR

void 
_close(self)
    Audio_PortAudio_Stream self
    PREINIT:
    int err;
    CODE:
    err = Pa_CloseStream(self);
    THROW_PA_ERROR

long
read_available(self)
    Audio_PortAudio_Stream self
    CODE:
    RETVAL = Pa_GetStreamReadAvailable(self);
    OUTPUT:
    RETVAL

long
write_available(self)
    Audio_PortAudio_Stream self
    CODE:
    RETVAL = Pa_GetStreamWriteAvailable(self);
    OUTPUT:
    RETVAL


MODULE = Audio::PortAudio::Device PACKAGE = Audio::PortAudio::Device

PROTOTYPES: DISABLE

const char*
name(self)
    Audio_PortAudio_Device self
    CODE:
    RETVAL = Pa_GetDeviceInfo(self)->name;
    OUTPUT:
    RETVAL

Audio_PortAudio_HostAPI
host_api(self)
    Audio_PortAudio_Device self
    CODE:
    RETVAL = Pa_GetDeviceInfo(self)->hostApi;
    OUTPUT:
    RETVAL

int
max_input_channels(self)
    Audio_PortAudio_Device self
    CODE:
    RETVAL = Pa_GetDeviceInfo(self)->maxInputChannels;
    OUTPUT:
    RETVAL

int
max_output_channels(self)
    Audio_PortAudio_Device self
    CODE:
    RETVAL = Pa_GetDeviceInfo(self)->maxOutputChannels;
    OUTPUT:
    RETVAL

double
default_sample_rate(self)
    Audio_PortAudio_Device self
    CODE:
    RETVAL = Pa_GetDeviceInfo(self)->defaultSampleRate;
    OUTPUT:
    RETVAL

PaTime
default_low_input_latency(self)
    Audio_PortAudio_Device self
    CODE:
    RETVAL = Pa_GetDeviceInfo(self)->defaultLowInputLatency;
    OUTPUT:
    RETVAL

PaTime
default_low_output_latency(self)
    Audio_PortAudio_Device self
    CODE:
    RETVAL = Pa_GetDeviceInfo(self)->defaultLowOutputLatency;
    OUTPUT:
    RETVAL

PaTime
default_high_input_latency(self)
    Audio_PortAudio_Device self
    CODE:
    RETVAL = Pa_GetDeviceInfo(self)->defaultHighInputLatency;
    OUTPUT:
    RETVAL

PaTime
default_high_output_latency(self)
    Audio_PortAudio_Device self
    CODE:
    RETVAL = Pa_GetDeviceInfo(self)->defaultHighOutputLatency;
    OUTPUT:
    RETVAL


MODULE = Audio::PortAudio::HostAPI PACKAGE = Audio::PortAudio::HostAPI

PROTOTYPES: DISABLE

PaHostApiTypeId
type(self)
    Audio_PortAudio_HostAPI self
    CODE:
    RETVAL = Pa_GetHostApiInfo(self)->type;
    OUTPUT:
    RETVAL

const char*
name(self)
    Audio_PortAudio_HostAPI self
    CODE:
    RETVAL = Pa_GetHostApiInfo(self)->name;
    OUTPUT:
    RETVAL

int
device_count(self)
    Audio_PortAudio_HostAPI self
    CODE:
    RETVAL = Pa_GetHostApiInfo(self)->deviceCount;
    OUTPUT:
    RETVAL

Audio_PortAudio_Device
default_input_device(self)
    Audio_PortAudio_HostAPI self
    PREINIT:
    PaDeviceIndex i;
    CODE:
    i=Pa_GetHostApiInfo(self)->defaultInputDevice;
    if (i == paNoDevice) croak("No device found");
    RETVAL = Pa_HostApiDeviceIndexToDeviceIndex(self,i);
    if (RETVAL == paNoDevice) croak("No device found");
    OUTPUT:
    RETVAL

Audio_PortAudio_Device
default_output_device(self)
    Audio_PortAudio_HostAPI self
    PREINIT:
    PaDeviceIndex i;
    CODE:
    i = Pa_GetHostApiInfo(self)->defaultOutputDevice;
    if (i == paNoDevice) croak("No device found");
    RETVAL = Pa_HostApiDeviceIndexToDeviceIndex(self,i);
    if (RETVAL == paNoDevice) croak("No device found");
    OUTPUT:
    RETVAL

Audio_PortAudio_Device
device(self, index)
    Audio_PortAudio_HostAPI self
    int index
    CODE:
    RETVAL = Pa_HostApiDeviceIndexToDeviceIndex(self,index);
    if (RETVAL == paNoDevice) croak("No device found");
    OUTPUT:
    RETVAL

MODULE = Audio::PortAudio PACKAGE = Audio::PortAudio

PROTOTYPES: DISABLE

int
version()
    CODE:
    RETVAL = Pa_GetVersion();
    OUTPUT:
    RETVAL

const char*
version_text()
    CODE:
    RETVAL = Pa_GetVersionText();
    OUTPUT:
    RETVAL

const char*
error_text(errorCode)
    PaError errorCode
    CODE:
    Pa_GetErrorText(errorCode);

void
initialize()
    PREINIT:
    PaError err;
    CODE:
    err = Pa_Initialize();
    THROW_PA_ERROR

void
terminate()
    PREINIT:
    PaError err;
    CODE:
    err = Pa_Terminate();
    THROW_PA_ERROR

PaHostApiIndex
host_api_count()
    CODE:
    RETVAL = Pa_GetHostApiCount();
    OUTPUT:
    RETVAL

Audio_PortAudio_HostAPI
default_host_api()
    CODE:
    RETVAL = Pa_GetDefaultHostApi();
    OUTPUT:
    RETVAL

Audio_PortAudio_HostAPI
host_api(index)
    PaHostApiIndex index
    CODE:
    RETVAL = index;
    OUTPUT:
    RETVAL


PaError
is_format_supported(input_parameters,output_parameters,sample_rate)
    SV* input_parameters
    SV* output_parameters
    double sample_rate
    PREINIT:
    const PaStreamParameters* isp;
    const PaStreamParameters* osp;
    CODE:
    isp = sv_to_stream_parameters(input_parameters);
    osp = sv_to_stream_parameters(input_parameters);
    RETVAL=Pa_IsFormatSupported( isp, osp, sample_rate);
    Safefree(isp);
    Safefree(osp);
    OUTPUT:
    RETVAL

Audio_PortAudio_Stream
_open_stream( input_parameters, output_parameters, sample_rate, frames_per_buffer, stream_flags )
    SV* input_parameters
    SV* output_parameters
    double sample_rate
    unsigned long frames_per_buffer
    PaStreamFlags stream_flags
    PREINIT:
    int err;
    const PaStreamParameters* isp;
    const PaStreamParameters* osp;
    PaStream* pastreamp;
    CODE:
    isp = sv_to_stream_parameters(input_parameters);
    osp = sv_to_stream_parameters(output_parameters);
/*    warn("open_stream: %d %d, %d %d",isp ? isp->device : -1, isp ? isp->channelCount : -1, osp ? osp->device : -1, osp ? osp->channelCount : -1); */
    err = Pa_OpenStream(&pastreamp, isp,osp,sample_rate, frames_per_buffer, stream_flags, NULL, NULL);
    THROW_PA_ERROR
    RETVAL = pastreamp;
    OUTPUT:
    RETVAL


