#include "perl-couchbase.h"


#define CONVERT_DIRECTION_OUT 1
#define CONVERT_DIRECTION_IN 2

static inline SV *
serialize_convert(SV *meth, SV *input, int direction)
{
    dSP;
    SV *ret;
    int count;    
    
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    
    XPUSHs(input);
    PUTBACK; 
    
    if(direction == CONVERT_DIRECTION_OUT) {
        count = call_sv(meth, G_SCALAR);
        SPAGAIN;
        
        /*for ouptut we must have this function succeed!*/
        if(count != 1) {
            croak("Serialization method returned nothing!");
        }
        ret = POPs;
    } else {
        count = call_sv(meth, G_SCALAR|G_EVAL);
        SPAGAIN;
        
        /*if someone has messed up our flags, don't die, but throw a warning*/
        if(SvTRUE(ERRSV)) {
            warn("Couldn't deserialize data: %s", SvPV_nolen(ERRSV));
            ret = input;
        } else {
            if(count != 1) {
                croak("Serialization method returned nothing?");
            }
            ret = POPs;
        }
    }
    
    SvREFCNT_inc(ret);
    
    FREETMPS;
    LEAVE;
    return ret;
}

static inline SV *
compression_convert(SV *meth, SV *input, int direction)
{
    dSP;
    int count;
    SV *converted = newSV(0);
    SV *ret;
    
    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    EXTEND(SP, 2);
    
    PUSHs(sv_2mortal(newRV_inc(input)));
    PUSHs(sv_2mortal(newRV_inc(converted)));
    PUTBACK;
    
    /*output conversion must succeed*/
    if(direction == CONVERT_DIRECTION_OUT) {
        if(call_sv(meth, G_SCALAR) != 1) {
            croak("Compression method returned nothing");
        }
        SPAGAIN;
        
        if(!SvTRUE(POPs)) {
            croak("Compression method returned error status");
        }
        input = NULL;
        
    } else {
        count = call_sv(meth, G_SCALAR|G_EVAL);
        SPAGAIN;
        
        if(SvTRUE(ERRSV)) {
            warn("Could not decompress input: %s", SvPV_nolen(ERRSV));
        } else if (count == 0) {
            warn("Decompression method didn't return anything");
        } else if( (ret = POPs) && SvTRUE(ret) == 0 ){
            warn("Decompression method returned error status");
        } else if (!SvTRUE(converted)) {
            warn("Decompression returned empty string");
        } else {
            input = NULL;
        }
    }
    if(input != NULL) {
        /*conversion failed*/
        SvREFCNT_dec(converted);
        converted = input;
    }
    
    FREETMPS;
    LEAVE;
    
    return converted;
}

#define plcb_can_convert(object, flags) \
    ((object->my_flags & (PLCBf_DECONVERT|flags)) == \
        (PLCBf_DECONVERT|flags))

void plcb_convert_storage(
    PLCB_t *object, SV **data_sv, STRLEN *data_len,
    uint32_t *flags)
{
    SV *sv;
    *flags = 0;
    
    /* dereference SCALAR reference. bypass all conversion checks because
     * this is an internal setting
     */
    if( (object->my_flags & PLCBf_DEREF_RVPV) &&
       SvROK(*data_sv) && SvTYPE(SvRV(*data_sv)) == SVt_PV) {
        *data_sv = SvRV(*data_sv);
        *data_len = SvCUR(*data_sv);
    }
    
    if( (object->my_flags & PLCBf_DO_CONVERSION == 0 ||
         object->my_flags & PLCBf_DECONVERT == 0)
       && SvROK(*data_sv) == 0) {
        return;
    }
    
    sv = *data_sv;
    
    /*only serialize references*/
    if(SvROK(sv)) {
        if(!plcb_can_convert(object, PLCBf_USE_STORABLE)) {
            croak("serialization requested but output conversion disabled");
        }
        
        sv = serialize_convert(object->cv_serialize, sv,
                               CONVERT_DIRECTION_OUT);        
        plcb_storeflags_apply_serialization(object, *flags);
        *data_len = SvCUR(sv); /*set this so compression method sees new length*/
    }
    
    if( plcb_can_convert(object, PLCBf_USE_COMPRESSION)
       && object->compress_threshold
       && *data_len >= object->compress_threshold ) {
        
        sv = compression_convert(object->cv_compress, sv,
                                            CONVERT_DIRECTION_OUT);
        plcb_storeflags_apply_compression(object, *flags); 
    }
    
    if(*data_sv != sv) {
        *data_sv = sv;
        *data_len = SvCUR(sv);
    }
}

void plcb_convert_storage_free(PLCB_t *object, SV *data, uint32_t flags)
{
    if(plcb_storeflags_has_compression(object, flags) == 0 &&
       plcb_storeflags_has_serialization(object,flags) == 0) {
        return;
    }
    
    SvREFCNT_dec(data);
}

SV* plcb_convert_retrieval(
    PLCB_t *object, const char *data, size_t data_len, uint32_t flags)
{
    SV *ret_sv, *input_sv;
    
    input_sv = newSVpvn(data, data_len);
    
    if(plcb_storeflags_has_conversion(object, flags) == 0
       || (object->my_flags & PLCBf_DECONVERT) == 0 ) {
        return input_sv;
    }
    
    ret_sv = input_sv;
    
    if(plcb_storeflags_has_compression(object, flags)) {
        ret_sv = compression_convert(object->cv_decompress, ret_sv,
                                     CONVERT_DIRECTION_IN);
    }
    
    if(plcb_storeflags_has_serialization(object, flags)) {
        ret_sv = serialize_convert(object->cv_deserialize, ret_sv,
                                   CONVERT_DIRECTION_IN);
    }
    
    if(ret_sv != input_sv) {
        SvREFCNT_dec(input_sv);
    }
    
    return ret_sv;
}


/*this function provides an easy interface to fiddle with the module's settings*/
int plcb_convert_settings(PLCB_t *object, int flag, int new_value)
{
    int ret;
    if(flag == PLCBf_COMPRESS_THRESHOLD) {
        /*this isn't really a flag value, but a proper integer*/
        ret = object->compress_threshold;
        
        object->compress_threshold = new_value >= 0
            ? new_value
            : object->compress_threshold;
        if(new_value >= 0) {
            object->my_flags |= PLCBf_USE_COMPRESSION;
        }
        return ret;
    }
    
    ret = (object->my_flags & flag);
    
    if(new_value > 0) {
        object->my_flags |= flag;
    } else {
        if(new_value == 0) {
            object->my_flags &= (~flag);
        }
    }
    
    return ret;
}
