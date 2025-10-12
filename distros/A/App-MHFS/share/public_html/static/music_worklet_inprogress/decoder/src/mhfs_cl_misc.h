#ifndef mhfs_cl_misc_h
#define mhfs_cl_misc_h

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#define LIBEXPORT EMSCRIPTEN_KEEPALIVE
#else
#define LIBEXPORT
#endif
#include <stdint.h>
#include <stddef.h>
#include "exposetype.h"

// util
LIBEXPORT unsigned long mhfs_cl_djb2(const uint8_t *pData, const size_t dataLen);

// For JS convenience export types
LIBEXPORT et_value mhfs_cl_et_load_type(const uint32_t itemIndex, const uint32_t subItemIndex);
#endif /* mhfs_cl_misc_h */

#if defined(MHFSCLMISC_IMPLEMENTATION)
#ifndef mhfs_cl_misc_c
#define mhfs_cl_misc_c

#include "mhfs_cl.h"
#include "mhfs_cl_track.h"

unsigned long mhfs_cl_djb2(const uint8_t *pData, const size_t dataLen)
{
    unsigned long hash = 5381;
    for(unsigned i = 0; i < dataLen; i++)
    {
        hash = ((hash << 5) + hash) + pData[i];
    }
    return hash;
}

et_value mhfs_cl_et_load_type(const uint32_t itemIndex, const uint32_t subItemIndex)
{
    switch(itemIndex)
    {
        case 0:
        ET_EXPOSE_CONST_IV(ET_TT_CONST_IV);
        break;
        case 1:
        ET_EXPOSE_CONST_IV(ET_TT_CONST_CSTRING);
        break;
        case 2:
        ET_EXPOSE_CONST_IV(ET_TT_ST);
        break;
        case 3:
        ET_EXPOSE_CONST_IV(ET_TT_ST_END);
        break;
        case 4:
        ET_EXPOSE_CONST_IV(ET_TT_UINT64);
        break;
        case 5:
        ET_EXPOSE_CONST_IV(ET_TT_UINT32);
        break;
        case 6:
        ET_EXPOSE_CONST_IV(ET_TT_UINT16);
        break;
        case 7:
        ET_EXPOSE_CONST_IV(ET_TT_UINT8);
        break;
        case 8:
        ET_EXPOSE_CONST_IV(MHFS_CL_SUCCESS);
        break;
        case 9:
        ET_EXPOSE_CONST_IV(MHFS_CL_ERROR);
        break;
        case 10:
        ET_EXPOSE_CONST_IV(MHFS_CL_NEED_MORE_DATA);
        break;
        case 11:
        ET_EXPOSE_CONST_IV(MHFS_CL_TRACK_M_AUDIOINFO);
        break;
        case 12:
        ET_EXPOSE_CONST_IV(MHFS_CL_TRACK_M_TAGS);
        break;
        case 13:
        ET_EXPOSE_CONST_IV(MHFS_CL_TRACK_M_PICTURE);
        break;
        case 14:
        ET_EXPOSE_STRUCT_BEGIN(mhfs_cl_track);
        break;
        case 15:
        ET_EXPOSE_STRUCT_END();
        break;
        case 16:
        ET_EXPOSE_STRUCT_BEGIN(mhfs_cl_track_return_data);
        break;
        case 17:
        ET_EXPOSE_STRUCT_UINT32(mhfs_cl_track_return_data, frames_read);
        break;
        case 18:
        ET_EXPOSE_STRUCT_UINT32(mhfs_cl_track_return_data, needed_offset);
        break;
        case 19:
        ET_EXPOSE_STRUCT_END();
        break;
        case 20:
        ET_EXPOSE_CONST_IV(MCT_MAI_FLD_EMPTY);
        break;
        case 21:
        ET_EXPOSE_CONST_IV(MCT_MAI_FLD_BITSPERSAMPLE);
        break;
        case 22:
        ET_EXPOSE_CONST_IV(MCT_MAI_FLD_BITRATE);
        break;
        case 23:
        ET_EXPOSE_STRUCT_BEGIN(mhfs_cl_track_meta_audioinfo);
        break;
        case 24:
        ET_EXPOSE_STRUCT_UINT64(mhfs_cl_track_meta_audioinfo, totalPCMFrameCount);
        break;
        case 25:
        ET_EXPOSE_STRUCT_UINT32(mhfs_cl_track_meta_audioinfo, sampleRate);
        break;
        case 26:
        ET_EXPOSE_STRUCT_UINT32(mhfs_cl_track_meta_audioinfo, fields);
        break;
        case 27:
        ET_EXPOSE_STRUCT_UINT16(mhfs_cl_track_meta_audioinfo, bitrate);
        break;
        case 28:
        ET_EXPOSE_STRUCT_UINT8(mhfs_cl_track_meta_audioinfo, channels);
        break;
        case 29:
        ET_EXPOSE_STRUCT_UINT8(mhfs_cl_track_meta_audioinfo, bitsPerSample);
        break;
        case 30:
        ET_EXPOSE_STRUCT_END();
        break;
        case 31:
        ET_EXPOSE_STRUCT_BEGIN(mhfs_cl_track_meta_tags_comment);
        break;
        case 32:
        ET_EXPOSE_STRUCT_UINT32(mhfs_cl_track_meta_tags_comment, commentSize);
        break;
        case 33:
        ET_EXPOSE_STRUCT_PTR(mhfs_cl_track_meta_tags_comment, comment);
        break;
        case 34:
        ET_EXPOSE_STRUCT_END();
        break;
        case 35:
        ET_EXPOSE_STRUCT_BEGIN(mhfs_cl_track_meta_picture);
        break;
        case 36:
        ET_EXPOSE_STRUCT_UINT32(mhfs_cl_track_meta_picture, pictureType);
        break;
        case 37:
        ET_EXPOSE_STRUCT_UINT32(mhfs_cl_track_meta_picture, mimeSize);
        break;
        case 38:
        ET_EXPOSE_STRUCT_PTR(mhfs_cl_track_meta_picture, mime);
        break;
        case 39:
        ET_EXPOSE_STRUCT_UINT32(mhfs_cl_track_meta_picture, descSize);
        break;
        case 40:
        ET_EXPOSE_STRUCT_PTR(mhfs_cl_track_meta_picture, desc);
        break;
        case 41:
        ET_EXPOSE_STRUCT_UINT32(mhfs_cl_track_meta_picture, pictureDataSize);
        break;
        case 42:
        ET_EXPOSE_STRUCT_PTR(mhfs_cl_track_meta_picture, pictureData);
        break;
        case 43:
        ET_EXPOSE_STRUCT_END();
        break;
    }
    return 0;
}

#endif  /* mhfs_cl_misc_c */
#endif  /* MHFSCLMISC_IMPLEMENTATION */
