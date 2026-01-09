#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdbool.h>
#include "macros_defs.h"


MODULE = Bit::Set::DB::SETOP_COUNT_OPTS    PACKAGE = Bit::Set::DB::SETOP_COUNT_OPTS

PROTOTYPES: DISABLE

SV*
new(class, ...)
    char* class
CODE:
    SETOP_COUNT_OPTS_t opts;
    Newz(0, opts, 1, SETOP_COUNT_OPTS);
    
    /* Set defaults */
    *opts = (SETOP_COUNT_OPTS){
        .num_cpu_threads = 0,
        .device_id = 0,
        .upd_1st_operand = false,
        .upd_2nd_operand = false,
        .release_1st_operand = true,
        .release_2nd_operand = true,
        .release_counts = true
    };
    
    /* Parse arguments if provided */
    if (items > 1) {
        HV* args = NULL;
        bool temp_hash = false;
        
        /* Check if first argument is a hash reference */
        if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            args = (HV*)SvRV(ST(1));
        }
        /* Check if we have key-value pairs (must be even number of args after class) */
        else if ((items - 1) % 2 == 0) {
            /* Create temporary hash from key-value pairs */
            args = newHV();
            temp_hash = true;
            
            int i;
            for (i = 1; i < items; i += 2) {
                char* key = SvPV_nolen(ST(i));
                SV* val = ST(i + 1);
                hv_store(args, key, strlen(key), newSVsv(val), 0);
            }
        }
        else {
            croak("Usage: new(CLASS) or new(CLASS, \\%%opts) or new(CLASS, key => val, ...)");
        }
        
        if (args) {
            SV** svp;
             if ((svp = hv_fetch(args, "num_cpu_threads", 15, 0))) 
                opts->device_id = SvIV(*svp);           
            if ((svp = hv_fetch(args, "device_id", 9, 0))) 
                opts->device_id = SvIV(*svp);
            if ((svp = hv_fetch(args, "upd_1st_operand", 15, 0))) 
                opts->upd_1st_operand = SvTRUE(*svp);
            if ((svp = hv_fetch(args, "upd_2nd_operand", 15, 0))) 
                opts->upd_2nd_operand = SvTRUE(*svp);
            if ((svp = hv_fetch(args, "release_1st_operand", 19, 0))) 
                opts->release_1st_operand = SvTRUE(*svp);
            if ((svp = hv_fetch(args, "release_2nd_operand", 19, 0))) 
                opts->release_2nd_operand = SvTRUE(*svp);
            if ((svp = hv_fetch(args, "release_counts", 14, 0))) 
                opts->release_counts = SvTRUE(*svp);
                
            if (temp_hash) {
                hv_undef(args);
            }
        }
    }
    
    RETURN_BLESSED_REFERENCE(class,opts);


void
DESTROY(obj)
    SV* obj
CODE:
    if (SvROK(obj)) {
        SETOP_COUNT_OPTS_t opts = (SETOP_COUNT_OPTS_t)SvIV(SvRV(obj));
        if (opts) Safefree(opts);
    }

int 
num_cpu_threads(obj, ...)
SV* obj
CODE:
    SETOP_COUNT_OPTS_t opts = (SETOP_COUNT_OPTS_t)SvIV(SvRV(obj));
    if (items > 1) opts->num_cpu_threads = SvIV(ST(1));
    RETVAL = opts->num_cpu_threads;
OUTPUT:
    RETVAL

int
device_id(obj, ...)
    SV* obj
CODE:
    SETOP_COUNT_OPTS_t opts = (SETOP_COUNT_OPTS_t)SvIV(SvRV(obj));
    if (items > 1) opts->device_id = SvIV(ST(1));
    RETVAL = opts->device_id;
OUTPUT:
    RETVAL

bool
upd_1st_operand(obj, ...)
    SV* obj
CODE:
    SETOP_COUNT_OPTS_t opts = (SETOP_COUNT_OPTS_t)SvIV(SvRV(obj));
    if (items > 1) opts->upd_1st_operand = SvTRUE(ST(1));
    RETVAL = opts->upd_1st_operand;
OUTPUT:
    RETVAL

bool
upd_2nd_operand(obj, ...)
    SV* obj
CODE:
    SETOP_COUNT_OPTS_t opts = (SETOP_COUNT_OPTS_t)SvIV(SvRV(obj));
    if (items > 1) opts->upd_2nd_operand = SvTRUE(ST(1));
    RETVAL = opts->upd_2nd_operand;
OUTPUT:
    RETVAL

bool
release_1st_operand(obj, ...)
    SV* obj
CODE:
    SETOP_COUNT_OPTS_t opts = (SETOP_COUNT_OPTS_t)SvIV(SvRV(obj));
    if (items > 1) opts->release_1st_operand = SvTRUE(ST(1));
    RETVAL = opts->release_1st_operand;
OUTPUT:
    RETVAL

bool
release_2nd_operand(obj, ...)
    SV* obj
CODE:
    SETOP_COUNT_OPTS_t opts = (SETOP_COUNT_OPTS_t)SvIV(SvRV(obj));
    if (items > 1) opts->release_2nd_operand = SvTRUE(ST(1));
    RETVAL = opts->release_2nd_operand;
OUTPUT:
    RETVAL

bool
release_counts(obj, ...)
    SV* obj
CODE:
    SETOP_COUNT_OPTS_t opts = (SETOP_COUNT_OPTS_t)SvIV(SvRV(obj));
    if (items > 1) opts->release_counts = SvTRUE(ST(1));
    RETVAL = opts->release_counts;
OUTPUT:
    RETVAL