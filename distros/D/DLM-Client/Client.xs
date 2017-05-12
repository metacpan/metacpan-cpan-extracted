#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libdlm.h>

#include "const-c.inc"

// int dlm_lock_wait(mode, dlm_lksb, flags, name, namelen, parent, bastarg, bastaddr, range);
//         int          mode
//         struct dlm_lksb *lksb,
//         int          flags
//         const void * name
//         unsigned int namelen,
//         uint32_t parent,                        /* unused */
//         void *bastarg,
//         void (*bastaddr) (void *bastarg),
//         void *range);                           /* unused */
// 
// int dlm_unlock_wait(lkid, flags, dlm_lksb)
//         uint32_t lkid,
//         uint32_t flags,
//         struct dlm_lksb *lksb);

MODULE = DLM::Client		PACKAGE = DLM::Client		

INCLUDE: const-xs.inc


int lock_resource(resource, mode, flags, lockid)
        const char   *resource
        int          mode
        int          flags
        int          &lockid
    OUTPUT:
        RETVAL
        lockid
        

int unlock_resource(lockid)
        int          lockid
    OUTPUT: 
        RETVAL


