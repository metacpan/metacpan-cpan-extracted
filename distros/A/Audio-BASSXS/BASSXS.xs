#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <bass.h>

#include "const-c.inc"

MODULE = Audio::BASSXS		PACKAGE = Audio::BASSXS		

INCLUDE: const-xs.inc

PROTOTYPES: DISABLE

DWORD
BASS_SetConfig(option, value)
    DWORD option
    DWORD value

DWORD
BASS_GetConfig(option)
    DWORD option

DWORD
BASS_GetVersion()

char *
BASS_GetDeviceDescription(device)
    DWORD device

BOOL
BASS_SetDevice(device)
    DWORD device

DWORD
BASS_GetDevice()

BOOL
BASS_Free()

void *
BASS_GetDSoundObject(object)
    DWORD object

HV *
BASS_GetInfo()
INIT:
    HV * rh;
    HV * results;
    BASS_INFO info;

    results = (HV *)sv_2mortal((SV *)newHV());
CODE:
    info.size=sizeof(BASS_INFO);
    BASS_GetInfo(&info);
    rh = (HV *)sv_2mortal((SV *)newHV());

    hv_store(rh, "size",      4, newSVnv(info.size),      0);
    hv_store(rh, "flags",     5, newSVnv(info.flags),     0);
    hv_store(rh, "hwsize",    6, newSVnv(info.hwsize),    0);
    hv_store(rh, "hwfree",    6, newSVnv(info.hwfree),    0);
    hv_store(rh, "freesam",   7, newSVnv(info.freesam),   0);
    hv_store(rh, "free3d",    6, newSVnv(info.free3d),    0);
    hv_store(rh, "minrate",   7, newSVnv(info.minrate),   0);
    hv_store(rh, "maxrate",   7, newSVnv(info.maxrate),   0);
    hv_store(rh, "eax",       3, newSVnv(info.eax),       0);
    hv_store(rh, "minbuf",    6, newSVnv(info.minbuf),    0);
    hv_store(rh, "dsver",     5, newSVnv(info.dsver),     0);
    hv_store(rh, "latency",   7, newSVnv(info.latency),   0);
    hv_store(rh, "initflags", 9, newSVnv(info.initflags), 0);
    hv_store(rh, "speakers",  8, newSVnv(info.speakers),  0);
    hv_store(rh, "driver",    6, newSVpv(info.driver,0),  0);
    RETVAL = rh;
OUTPUT:
    RETVAL
    
BOOL
BASS_Update()

float
BASS_GetCPU()

BOOL
BASS_SetVolume(DWORD volume)

int
BASS_GetVolume()


BOOL
BASS_Init(device, freq, flags, win, dsguid)
    DWORD device
    DWORD freq
    DWORD flags
    HWND win
    const GUID *dsguid

BOOL
BASS_Start()

BOOL
BASS_Pause()

BOOL
BASS_Stop()

DWORD 
BASS_ErrorGetCode()

HSTREAM 
BASS_StreamCreate(freq, chans, flags, proc, user)
    DWORD freq
    DWORD chans
    DWORD flags
    void *proc
    DWORD user

HSTREAM 
BASS_StreamCreateFile(mem, file, offset, length, flags)
    BOOL mem
    const char *file
    DWORD offset 
    DWORD length
    DWORD flags

BOOL 
BASS_StreamPlay(handle, flush, flags)
    HSTREAM handle
    BOOL flush
    DWORD flags

HSTREAM 
BASS_StreamCreateURL(url, offset, flags, proc, user)
    const char *url
    DWORD offset
    DWORD flags
    DOWNLOADPROC *proc
    DWORD user

HSTREAM 
BASS_StreamCreateFileUser(buffered, flags, proc, user)
    BOOL buffered
    DWORD flags
    void *proc 
    DWORD user

void 
BASS_StreamFree(handle)
    HSTREAM handle

QWORD 
BASS_StreamGetLength(handle)
    HSTREAM handle

char *
BASS_StreamGetTags(handle, tags)
    HSTREAM handle 
    DWORD tags

BOOL 
BASS_StreamPreBuf(handle)
    HSTREAM handle

DWORD 
BASS_StreamGetFilePosition(handle, mode)
    HSTREAM handle
    DWORD mode

