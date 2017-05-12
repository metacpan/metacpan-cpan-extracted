#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "Audio_f.h"
static AudioVtab AudioVtable =
{
#define VFUNC(type,name,mem,args) name,
#define VVAR(type,name,mem)      &name,
#include "Audio.t"
#undef VFUNC
#undef VVAR
};
AudioVtab *AudioVptr;
AudioVtab *AudioVGet() { return AudioVptr = &AudioVtable;}
