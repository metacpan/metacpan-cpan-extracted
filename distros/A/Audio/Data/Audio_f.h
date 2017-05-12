#ifndef AUDIO_VT
#define AUDIO_VT
#include "Audio.h"
typedef struct AudioVtab
{
#define VFUNC(type,name,mem,args) type (*mem) args;
#define VVAR(type,name,mem)       type (*mem);
#include "Audio.t"
#undef VFUNC
#undef VVAR
} AudioVtab;
extern AudioVtab *AudioVptr;
extern AudioVtab *AudioVGet _((void));
#endif /* AUDIO_VT */
