#ifndef mhfs_cl_track_h
#define mhfs_cl_track_h

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#define LIBEXPORT EMSCRIPTEN_KEEPALIVE
#else
#define LIBEXPORT
#endif
#include "miniaudio.h"

#include "blockvf.h"
#include "mhfs_cl.h"

typedef float float32_t;

typedef enum {
    MHFS_CL_TRACK_M_AUDIOINFO = 0,
    MHFS_CL_TRACK_M_TAGS = 1,
    MHFS_CL_TRACK_M_PICTURE = 2
} mhfs_cl_track_meta;

typedef enum {
    MCT_MAI_FLD_EMPTY         = 0,
    MCT_MAI_FLD_BITSPERSAMPLE = 1 << 0,
    MCT_MAI_FLD_BITRATE       = 1 << 1
} mhfs_cl_track_meta_audioinfo_field;

typedef struct {
    uint64_t totalPCMFrameCount;
    uint32_t sampleRate;
    mhfs_cl_track_meta_audioinfo_field fields;
    uint16_t bitrate;
    uint8_t channels;
    uint8_t bitsPerSample;
} mhfs_cl_track_meta_audioinfo;

typedef struct {
    uint32_t commentSize;
    const uint8_t *comment;
} mhfs_cl_track_meta_tags_comment;

typedef struct {
    uint32_t vendorLength;
    const char *vendorString;
    const uint32_t commentCount;
    drflac_vorbis_comment_iterator comment_iterator;
    mhfs_cl_track_meta_tags_comment currentComment;
} mhfs_cl_track_meta_tags;

typedef struct {
    uint32_t pictureType;
    uint32_t mimeSize;
    const uint8_t *mime;
    uint32_t descSize;
    const uint8_t *desc;
    uint32_t pictureDataSize;
    const void *pictureData;
} mhfs_cl_track_meta_picture;

typedef void (*mhfs_cl_track_on_metablock)(void*, const mhfs_cl_track_meta, void *);

#define MHFS_CL_TRACK_MAX_ALLOCS 3
typedef struct {
    void *allocptrs[MHFS_CL_TRACK_MAX_ALLOCS];
    size_t allocsizes[MHFS_CL_TRACK_MAX_ALLOCS];
} mhfs_cl_track_allocs;

typedef struct {
    blockvf_error code;
    uint32_t extradata;
} mhfs_cl_track_blockvf_data;

typedef struct {
    // for backup and restore
    ma_decoder backupDecoder;
    unsigned backupFileOffset;
    mhfs_cl_track_allocs allocs;

    ma_decoder_config decoderConfig;
    ma_decoder decoder;
    bool dec_initialized;
    blockvf vf;
    mhfs_cl_track_blockvf_data vfData;
    mhfs_cl_track_meta_audioinfo meta;
    unsigned afterID3Offset;
    bool meta_initialized;
    uint32_t currentFrame;
} mhfs_cl_track;

typedef union {
    uint32_t frames_read;
    uint32_t needed_offset;
} mhfs_cl_track_return_data;

LIBEXPORT void mhfs_cl_track_init(mhfs_cl_track *pTrack, const unsigned blocksize);
LIBEXPORT void mhfs_cl_track_deinit(mhfs_cl_track *pTrack);
LIBEXPORT void *mhfs_cl_track_add_block(mhfs_cl_track *pTrack, const uint32_t block_start, const unsigned filesize);
LIBEXPORT mhfs_cl_error mhfs_cl_track_load_metadata(mhfs_cl_track *pTrack, mhfs_cl_track_return_data *pReturnData, const char *mime, const char *fullfilename, const uint64_t totalPCMFrameCount, const mhfs_cl_track_on_metablock on_metablock, void *context);
LIBEXPORT int mhfs_cl_track_seek_to_pcm_frame(mhfs_cl_track *pTrack, const uint32_t pcmFrameIndex);
LIBEXPORT mhfs_cl_error mhfs_cl_track_read_pcm_frames_f32(mhfs_cl_track *pTrack, const uint32_t desired_pcm_frames, float32_t *outFloat, mhfs_cl_track_return_data *pReturnData);

LIBEXPORT double mhfs_cl_track_meta_audioinfo_durationInSecs(const mhfs_cl_track_meta_audioinfo *pInfo);
LIBEXPORT const mhfs_cl_track_meta_tags_comment *mhfs_cl_track_meta_tags_next_comment(mhfs_cl_track_meta_tags *pTags);
#endif /* mhfs_cl_track.h */

#if defined(MHFSCLTRACK_IMPLEMENTATION)
#ifndef mhfs_cl_track_c
#define mhfs_cl_track_c

#ifndef MHFSCLTR_PRINT_ON
    #define MHFSCLTR_PRINT_ON 0
#endif

#define MHFSCLTR_PRINT(...) \
    do { if (MHFSCLTR_PRINT_ON) fprintf(stdout, __VA_ARGS__); } while (0)

#define mhfs_cl_member_size(type, member) sizeof(((type *)0)->member)

static inline uint32_t unaligned_beu32_to_native(const void *src)
{
    const uint8_t *pNum = src;
    return (pNum[0] << 24) | (pNum[1] << 16) | (pNum[2] << 8) | (pNum[3]);
}

static inline uint32_t unaligned_leu32_to_native(const void *src)
{
    const uint8_t *pNum = src;
    return (pNum[0]) | (pNum[1] << 8) | (pNum[2] << 16) | (pNum[3] << 24);
}

static inline uint32_t unaligned_leu16_to_native(const void *src)
{
    const uint8_t *pNum = src;
    return (pNum[0]) | (pNum[1] << 8);
}

uint32_t mhfs_cl_flac_picture_block_get_type(const void *pPictureBlock)
{
    return unaligned_beu32_to_native(pPictureBlock);
}

#pragma pack(1)
typedef struct {
    uint8_t beu32[4];
    uint8_t data[];
} UnalignedBEPascalString;
#pragma pack()

uint32_t UnalignedBEPascalString_length(const UnalignedBEPascalString *str)
{
    return unaligned_beu32_to_native(str->beu32);
}

const UnalignedBEPascalString *mhfs_cl_flac_picture_block_get_mime(const uint8_t *pPictureBlock)
{
    return (UnalignedBEPascalString*)&pPictureBlock[4];
}

const UnalignedBEPascalString *mhfs_cl_flac_picture_block_get_desc(const uint8_t *pPictureBlock, const uint32_t mimeSize)
{
    return (UnalignedBEPascalString*)(&pPictureBlock[8+mimeSize]);
}

const UnalignedBEPascalString *mhfs_cl_flac_picture_block_get_picture(const uint8_t *pPictureBlock, const uint32_t mimeSize, const uint32_t descSize)
{
    return (UnalignedBEPascalString*)(&pPictureBlock[8+mimeSize+4+descSize+16]);
}

static void mhfs_cl_track_meta_audioinfo_init(mhfs_cl_track_meta_audioinfo *pMetadata, const uint64_t totalPCMFrameCount, const uint32_t sampleRate, const uint8_t channels, const mhfs_cl_track_meta_audioinfo_field fields, const uint8_t bitsPerSample, const uint16_t bitrate)
{
    pMetadata->totalPCMFrameCount = totalPCMFrameCount;
    pMetadata->sampleRate = sampleRate;
    pMetadata->channels = channels;
    pMetadata->fields = fields;
    pMetadata->bitsPerSample = bitsPerSample;
    pMetadata->bitrate = bitrate;
}

static inline mhfs_cl_error mhfs_cl_error_from_blockvf_error(const blockvf_error bvferr)
{
    switch(bvferr)
    {
        case BLOCKVF_SUCCESS:
        return MHFS_CL_SUCCESS;

        case BLOCKVF_MEM_NEED_MORE:
        return MHFS_CL_NEED_MORE_DATA;

        case BLOCKVF_GENERIC_ERROR:
        default:
        return MHFS_CL_ERROR;
    }
}

static inline ma_result mhfs_cl_track_blockvf_error_to_ma_result(const blockvf_error bvfError, mhfs_cl_track_blockvf_data *pData)
{
    switch(bvfError)
    {
        case BLOCKVF_SUCCESS:
        return MA_SUCCESS;
        break;
        case BLOCKVF_MEM_NEED_MORE:
        pData->code = BLOCKVF_MEM_NEED_MORE;
        case BLOCKVF_GENERIC_ERROR:
        default:
        return MA_ERROR;
        break;
    }
}

static ma_result mhfs_cl_track_on_seek_ma_decoder(ma_decoder *pDecoder, int64_t offset, ma_seek_origin origin)
{
    mhfs_cl_track *pTrack = (mhfs_cl_track *)pDecoder->pUserData;
    // for whatever reason miniaudio tries over an over again, check for repeat failures and error
    if(pTrack->vfData.code != BLOCKVF_SUCCESS)
    {
        //BLOCKVF_PRINT("on_seek_mem: already failed, breaking %"PRId64" %u\n", offset, origin);
        return MA_ERROR;
    }

    blockvf_seek_origin bvf_origin;
    switch(origin)
    {
        case ma_seek_origin_start:
        bvf_origin = blockvf_seek_origin_start;
        break;
        case ma_seek_origin_current:
        bvf_origin = blockvf_seek_origin_current;
        break;
        case ma_seek_origin_end:
        bvf_origin = blockvf_seek_origin_end;
        break;
        default:
        BLOCKVF_PRINT("unknown origin: %"PRId64" %u\n", offset, origin);
        return MA_ERROR;
        break;
    }

    const blockvf_error seekres = blockvf_seek(&pTrack->vf, offset, bvf_origin);
    return mhfs_cl_track_blockvf_error_to_ma_result(seekres, &pTrack->vfData);
}

static ma_result mhfs_cl_track_on_read_ma_decoder(ma_decoder *pDecoder, void* bufferOut, size_t bytesToRead, size_t *bytesRead)
{
    mhfs_cl_track *pTrack = (mhfs_cl_track *)pDecoder->pUserData;
    // for whatever reason miniaudio tries over an over again, check for repeat failures and error
    if(pTrack->vfData.code != BLOCKVF_SUCCESS)
    {
        BLOCKVF_PRINT("on_read_mem: already failed\n");
        *bytesRead = 0;
        return MA_ERROR;
    }

    const blockvf_error bvfError = blockvf_read(&pTrack->vf, bufferOut, bytesToRead, bytesRead, &pTrack->vfData.extradata);
    return mhfs_cl_track_blockvf_error_to_ma_result(bvfError, &pTrack->vfData);
}

// round up to nearest multiple of 8
static inline size_t ceil8(const size_t toround)
{
    return ((toround +7) & (~7));
}

static void *mhfs_cl_track_malloc(size_t sz, void* pUserData)
{
    mhfs_cl_track *pTrack = (mhfs_cl_track *)pUserData;
    mhfs_cl_track_allocs *pAllocs = &pTrack->allocs;
    for(unsigned i = 0; i < MHFS_CL_TRACK_MAX_ALLOCS; i++)
    {
        if(pAllocs->allocptrs[i] == NULL)
        {
            const size_t rsz = ceil8(sz);
            uint8_t *res = malloc(rsz * 2);
            if(res == NULL)
            {
                MHFSCLTR_PRINT("%s: %zu malloc failed\n", __func__, sz);
            }
            MHFSCLTR_PRINT("%s: %zu %p\n", __func__, sz, res);
            pAllocs->allocsizes[i]= sz;
            pAllocs->allocptrs[i] = res;
            return res;
        }
    }
    MHFSCLTR_PRINT("%s: %zu failed to find slot for alloc\n", __func__, sz);
    return NULL;
}

static void mhfs_cl_track_free(void* p, void* pUserData)
{
    mhfs_cl_track *pTrack = (mhfs_cl_track *)pUserData;
    mhfs_cl_track_allocs *pAllocs = &pTrack->allocs;

    for(unsigned i = 0; i < MHFS_CL_TRACK_MAX_ALLOCS; i++)
    {
        if(pAllocs->allocptrs[i] == p)
        {
            MHFSCLTR_PRINT("%s: 0x%p\n", __func__, p);
            free(p);
            pAllocs->allocptrs[i] = NULL;
            return;
        }
    }
    MHFSCLTR_PRINT("%s: failed to record free %p\n", __func__, p);
}

static void *mhfs_cl_track_realloc(void *p, size_t sz, void* pUserData)
{
    if(p == NULL)
    {
        MHFSCLTR_PRINT("%s: %zu realloc passing to malloc\n", __func__, sz);
        return mhfs_cl_track_malloc(sz, pUserData);
    }
    else if(sz == 0)
    {
        MHFSCLTR_PRINT("%s: %zu realloc passing to free\n", __func__, sz);
        mhfs_cl_track_free(p, pUserData);
        return NULL;
    }

    mhfs_cl_track *pTrack = (mhfs_cl_track *)pUserData;
    mhfs_cl_track_allocs *pAllocs = &pTrack->allocs;
    for(unsigned i = 0; i < MHFS_CL_TRACK_MAX_ALLOCS; i++)
    {
        if(pAllocs->allocptrs[i] == p)
        {
            const size_t osz = pAllocs->allocsizes[i];
            const size_t orsz = ceil8(pAllocs->allocsizes[i]);
            const size_t rsz = ceil8(sz);
            // avoid losing the start of backup by moving it down
            if(rsz < orsz)
            {
                uint8_t *ogalloc = p;
                memmove(ogalloc+rsz, ogalloc+orsz, sz);
            }
            uint8_t *newalloc = realloc(p, rsz*2);
            if(newalloc == NULL)
            {
                if(rsz >= orsz)
                {
                    MHFSCLTR_PRINT("%s: %zu realloc failed\n", __func__, sz);
                    return NULL;
                }
                // we moved the data down so we can't fail
                newalloc = p;
            }
            // move the backup data forward
            else if(rsz > orsz)
            {
                memmove(newalloc+rsz, newalloc+orsz, osz);
            }

            pAllocs->allocsizes[i]= sz;
            pAllocs->allocptrs[i] = newalloc;
            return newalloc;
        }
    }
    MHFSCLTR_PRINT("%s: %zu failed to find\n", __func__, sz);
    return NULL;
}

static inline void mhfs_cl_track_allocs_backup_or_restore(mhfs_cl_track *pTrack, const bool backup)
{
    // copy ma_decoder and blockvf fileoffset
    if(backup)
    {
        pTrack->backupDecoder    = pTrack->decoder;
        pTrack->backupFileOffset = pTrack->vf.fileoffset;
    }
    else
    {
        pTrack->decoder       = pTrack->backupDecoder;
        pTrack->vf.fileoffset = pTrack->backupFileOffset;
    }

    // copy the allocations
    mhfs_cl_track_allocs *pAllocs = &pTrack->allocs;
    for(unsigned i = 0; i < MHFS_CL_TRACK_MAX_ALLOCS; i++)
    {
        if(pAllocs->allocptrs[i] != NULL)
        {
            const size_t offset = ceil8(pAllocs->allocsizes[i]);
            uint8_t *allocBuf = pAllocs->allocptrs[i];
            const uint8_t *srcBuf;
            uint8_t *destBuf;
            if(backup)
            {
                srcBuf = allocBuf;
                destBuf = allocBuf + offset;
            }
            else
            {
                srcBuf = allocBuf + offset;
                destBuf = allocBuf;
            }
            memcpy(destBuf, srcBuf, pAllocs->allocsizes[i]);
        }
    }
}

static inline void mhfs_cl_track_allocs_backup(mhfs_cl_track *pTrack)
{
    return mhfs_cl_track_allocs_backup_or_restore(pTrack, true);
}

static inline void mhfs_cl_track_allocs_restore(mhfs_cl_track *pTrack)
{
    return mhfs_cl_track_allocs_backup_or_restore(pTrack, false);
}

void mhfs_cl_track_init(mhfs_cl_track *pTrack, const unsigned blocksize)
{
    for(unsigned i = 0; i < MHFS_CL_TRACK_MAX_ALLOCS; i++)
    {
        pTrack->allocs.allocptrs[i] = NULL;
    }
    pTrack->decoderConfig = ma_decoder_config_init(ma_format_f32, 0, 0);
    ma_allocation_callbacks cbs;
    cbs.pUserData = pTrack;
    cbs.onMalloc = &mhfs_cl_track_malloc;
    cbs.onRealloc = &mhfs_cl_track_realloc;
    cbs.onFree = &mhfs_cl_track_free;
    pTrack->decoderConfig.allocationCallbacks = cbs;
    pTrack->decoderConfig.encodingFormat = ma_encoding_format_unknown;

    pTrack->dec_initialized = false;
    blockvf_init(&pTrack->vf, blocksize);
    pTrack->meta_initialized = false;
    pTrack->currentFrame = 0;
}

void mhfs_cl_track_deinit(mhfs_cl_track *pTrack)
{
    if(pTrack->dec_initialized) ma_decoder_uninit(&pTrack->decoder);
    blockvf_deinit(&pTrack->vf);
}

void *mhfs_cl_track_add_block(mhfs_cl_track *pTrack, const uint32_t block_start, const unsigned filesize)
{
    return blockvf_add_block(&pTrack->vf, block_start, filesize);
}

// mhfs_cl_track_read_pcm_frames_f32 will catch the error if we dont here
int mhfs_cl_track_seek_to_pcm_frame(mhfs_cl_track *pTrack, const uint32_t pcmFrameIndex)
{
    if(pTrack->dec_initialized)
    {
        if(pcmFrameIndex >= pTrack->meta.totalPCMFrameCount)
        {
            // allow seeking to 0 always
            if(pcmFrameIndex != 0)
            {
                return 0;
            }
        }
    }
    pTrack->currentFrame = pcmFrameIndex;
    return 1;
}

double mhfs_cl_track_meta_audioinfo_durationInSecs(const mhfs_cl_track_meta_audioinfo *pInfo)
{
    return (pInfo->sampleRate > 0) ? ((double)pInfo->totalPCMFrameCount / pInfo->sampleRate) : 0;
}

typedef enum {
	DAF_FLAC,
	DAF_MP3,
    DAF_WAV,
	DAF_PCM
} DecoderAudioFormats;

static inline void mhfs_cl_track_swap_tryorder(ma_encoding_format *first,  ma_encoding_format *second)
{
    ma_encoding_format temp = *first;
    *first = *second;
    *second = temp;
}

static inline uint32_t unsynchsafe_32(const uint32_t n)
{
    uint32_t result = 0;
    result |= (n & 0x7F000000) >> 3;
    result |= (n & 0x007F0000) >> 2;
    result |= (n & 0x00007F00) >> 1;
    result |= (n & 0x0000007F) >> 0;
    return result;
}

const mhfs_cl_track_meta_tags_comment *mhfs_cl_track_meta_tags_next_comment(mhfs_cl_track_meta_tags *pTags)
{
    pTags->currentComment.comment = (uint8_t*)drflac_next_vorbis_comment(&pTags->comment_iterator, &pTags->currentComment.commentSize);
    if(pTags->currentComment.comment == NULL)
    {
        return NULL;
    }
    return &pTags->currentComment;
}

static mhfs_cl_error mhfs_cl_track_load_metadata_flac(mhfs_cl_track *pTrack, mhfs_cl_track_return_data *pReturnData, const mhfs_cl_track_on_metablock on_metablock, void *context)
{
    // check for magic
    const uint8_t *id;
    const blockvf_error idError = blockvf_read_view(&pTrack->vf, 4, &id, &pReturnData->needed_offset);
    if(idError != BLOCKVF_SUCCESS)
    {
        return mhfs_cl_error_from_blockvf_error(idError);
    }
    if(memcmp(id, "fLaC", 4) != 0)
    {
        return MHFS_CL_ERROR;
    }

    // parse metadata blocks
    bool hasStreamInfo = false;
    bool hasSeekTable = false;
    bool isLast;
    do {
        // load the block header
        const uint8_t *metablock_header;
        const blockvf_error mbheaderError = blockvf_read_view(&pTrack->vf, 4, &metablock_header, &pReturnData->needed_offset);
        if(mbheaderError != BLOCKVF_SUCCESS)
        {
            if(mbheaderError == BLOCKVF_MEM_NEED_MORE)
            {
                return mhfs_cl_error_from_blockvf_error(mbheaderError);
            }
            MHFSCLTR_PRINT("Stopping metadata parsing, blockvf error\n");
            break;
        }
        isLast = metablock_header[0] & 0x80;
        const unsigned blocktype = (metablock_header[0] & 0x7F);
        const size_t blocksize = (metablock_header[1] << 16) | (metablock_header[2] << 8) | (metablock_header[3]);

        // skip or read the block
        if( (blocktype != DRFLAC_METADATA_BLOCK_TYPE_STREAMINFO) && (blocktype != DRFLAC_METADATA_BLOCK_TYPE_VORBIS_COMMENT) && (blocktype != DRFLAC_METADATA_BLOCK_TYPE_PICTURE))
        {
            if(blocktype == DRFLAC_METADATA_BLOCK_TYPE_SEEKTABLE)
            {
                hasSeekTable = true;
            }
            const blockvf_error skipblockError = blockvf_seek(&pTrack->vf, blocksize, blockvf_seek_origin_current);
            if(skipblockError != BLOCKVF_SUCCESS)
            {
                MHFSCLTR_PRINT("Stopping metadata parsing, blockvf error\n");
                break;
            }
            continue;
        }
        const uint8_t *blockData;
        const blockvf_error blockdataError = blockvf_read_view(&pTrack->vf, blocksize, &blockData, &pReturnData->needed_offset);
        if(blockdataError != BLOCKVF_SUCCESS)
        {
            if(blockdataError == BLOCKVF_MEM_NEED_MORE)
            {
                return mhfs_cl_error_from_blockvf_error(blockdataError);
            }
            MHFSCLTR_PRINT("Stopping metadata parsing, blockvf error\n");
            break;
        }

        // parse the block
        if(blocktype == DRFLAC_METADATA_BLOCK_TYPE_STREAMINFO)
        {
            hasStreamInfo = true;
            const uint32_t sampleRate = (blockData[10] << 12) | (blockData[11] << 4) | ((blockData[12] & 0xF0) >> 4);
            const uint8_t channels = ((blockData[12] & 0xE) >> 1)+1;
            const uint8_t bitsPerSample = (((blockData[12] & 0x1) << 4) | ((blockData[13] & 0xF0) >> 4))+1;
            const uint64_t top4 = (blockData[13] & 0xF);
            const uint64_t totalPCMFrameCount = (top4 << 32) | (blockData[14] << 24) | (blockData[15] << 16) | (blockData[16] << 8) | (blockData[17]);
            mhfs_cl_track_meta_audioinfo_init(&pTrack->meta, totalPCMFrameCount, sampleRate, channels, MCT_MAI_FLD_BITSPERSAMPLE, bitsPerSample, 0);
            if(on_metablock != NULL)
            {
                on_metablock(context, MHFS_CL_TRACK_M_AUDIOINFO, &pTrack->meta);
            }
        }
        else if(blocktype == DRFLAC_METADATA_BLOCK_TYPE_VORBIS_COMMENT)
        {
            const uint32_t vendorLength = blockData[0] | (blockData[1] << 8) | (blockData[2] << 16) | (blockData[3] << 24);
            MHFSCLTR_PRINT("vendor_string: %.*s\n", vendorLength, &blockData[4]);
            const unsigned ccStart = sizeof(uint32_t) + vendorLength;
            const uint32_t commentCount = blockData[ccStart] | (blockData[ccStart+1] << 8) | (blockData[ccStart+2] << 16) | (blockData[ccStart+3] << 24);

            if(on_metablock != NULL)
            {
                mhfs_cl_track_meta_tags tags = {
                    .vendorLength = vendorLength,
                    .vendorString = (char*)&blockData[4],
                    .commentCount = commentCount
                };
                drflac_init_vorbis_comment_iterator(&tags.comment_iterator, commentCount, &blockData[ccStart+4]);
                on_metablock(context, MHFS_CL_TRACK_M_TAGS, &tags);
            }
        }
        else if(blocktype == DRFLAC_METADATA_BLOCK_TYPE_PICTURE)
        {
            if(on_metablock != NULL)
            {
                // pictureBlock = ((uint8_t*)pTrack->vf.buf) + (pTrack->vf.fileoffset - blocksize);
                const UnalignedBEPascalString *mime = mhfs_cl_flac_picture_block_get_mime(blockData);
                const uint32_t mimeSize = UnalignedBEPascalString_length(mime);
                const UnalignedBEPascalString *desc = mhfs_cl_flac_picture_block_get_desc(blockData, mimeSize);
                const uint32_t descSize = UnalignedBEPascalString_length(desc);
                const UnalignedBEPascalString *picData = mhfs_cl_flac_picture_block_get_picture(blockData, mimeSize, descSize);

                mhfs_cl_track_meta_picture picture = {
                    .pictureType = mhfs_cl_flac_picture_block_get_type(blockData),
                    .mimeSize = mimeSize,
                    .mime = mime->data,
                    .descSize = descSize,
                    .desc = desc->data,
                    .pictureDataSize = UnalignedBEPascalString_length(picData),
                    .pictureData = picData->data
                };
                on_metablock(context, MHFS_CL_TRACK_M_PICTURE, &picture);
            }
        }
    } while(!isLast);
    if(!hasStreamInfo)
    {
        return MHFS_CL_ERROR;
    }
    else if(!hasSeekTable)
    {
        MHFSCLTR_PRINT("warning: track does NOT have seektable!\n");
    }

    pTrack->meta_initialized = true;
    return MHFS_CL_SUCCESS;
}

static inline mhfs_cl_error mhfs_cl_parse_id3_header_after_magic(blockvf *pBlockvf, uint32_t *blockvfNeededOffset, uint16_t *id3version,  uint8_t *flags, uint32_t *tagSize)
{
    const uint8_t *header;
    const blockvf_error headerError = blockvf_read_view(pBlockvf, 7, &header, blockvfNeededOffset);
    if(headerError != BLOCKVF_SUCCESS)
    {
        return mhfs_cl_error_from_blockvf_error(headerError);
    }
    uint32_t headerSize = unsynchsafe_32((header[3] << 24) | (header[4] << 16) | (header[5] << 8) | (header[6]));
    if(header[2] & 0x10)
    {
        headerSize += 10;
    }
    *id3version = (header[0] << 8) | header[1];
    *flags = header[2];
    *tagSize = headerSize;
    return MHFS_CL_SUCCESS;
}

typedef enum {
    MCT_MVER_TWOPOINTFIVE = 0x0,
    MCT_MVER_RESERVED     = 0x1,
    MCT_MVER_TWO          = 0x2,
    MCT_MVER_ONE          = 0x3
} mhfs_cl_track_mpeg_version;

typedef enum {
    MCT_MLAYER_RESERVED = 0x0,
    MCT_MLAYER_3        = 0x1,
    MCT_MLAYER_2        = 0x2,
    MCT_MLAYER_1        = 0x3
} mhfs_cl_track_mpeg_layer;

static mhfs_cl_error mhfs_cl_track_load_metadata_mp3(mhfs_cl_track *pTrack, mhfs_cl_track_return_data *pReturnData, const mhfs_cl_track_on_metablock on_metablock, void *context)
{
    const unsigned startoffset = pTrack->vf.fileoffset;

    // we care about id3 tags in mp3
    pTrack->vf.fileoffset = 0;
    for(;;)
    {
        const uint8_t *id;
        const blockvf_error idError = blockvf_read_view(&pTrack->vf, 3, &id, &pReturnData->needed_offset);
        if(idError != BLOCKVF_SUCCESS)
        {
            return mhfs_cl_error_from_blockvf_error(idError);
        }
        if(memcmp(id, "ID3", 3) != 0) break;
        uint16_t version;
        uint8_t flags;
        uint32_t tagSize;
        const mhfs_cl_error parseError = mhfs_cl_parse_id3_header_after_magic(&pTrack->vf, &pReturnData->needed_offset, &version, &flags, &tagSize);
        if(parseError != MHFS_CL_SUCCESS)
        {
            return parseError;
        }
        MHFSCLTR_PRINT("id3 version: %X %X\n", (version >> 8) & 0xFF, version & 0xFF);
        const uint8_t *frames;
        const blockvf_error frameError = blockvf_read_view(&pTrack->vf, tagSize, &frames, &pReturnData->needed_offset);
        if(frameError != BLOCKVF_SUCCESS)
        {
            return mhfs_cl_error_from_blockvf_error(frameError);
        }
        while(tagSize >= 10) {
            const uint32_t framesize = unsynchsafe_32(unaligned_beu32_to_native(frames+4));
            unsigned frameheadersize = 10;
            MHFSCLTR_PRINT("id3 frameid: %c %c %c %c size: %u\n", frames[0], frames[1], frames[2], frames[3], framesize);
            if(frames[9] & 0x3) {
                MHFSCLTR_PRINT("unsync applied\n");
            }
            else if(frames[9] & 0x1) {
                const uint32_t dli = unsynchsafe_32(unaligned_beu32_to_native(&frames[10]));
                MHFSCLTR_PRINT("data length indicator %u\n", dli);
                frameheadersize += 4;
            }
            if((framesize+frameheadersize) > tagSize)
            {
                MHFSCLTR_PRINT("id3 frame exceeds tag!, size left: %u\n", tagSize-frameheadersize);
                break;
            }
            if(memcmp(frames, "APIC", 4) == 0)
            {
                if(on_metablock != NULL)
                {
                    const uint8_t *apicCurrentItem = &frames[frameheadersize];
                    const uint8_t encoding = apicCurrentItem[0]; apicCurrentItem++;
                    const char *mime = (char*)apicCurrentItem;
                    const uint32_t mimeSize = strlen(mime); apicCurrentItem += (mimeSize+1);
                    uint8_t type = apicCurrentItem[0]; apicCurrentItem++;
                    const char *desc = (char*)apicCurrentItem;
                    const uint32_t descSize = strlen(desc); apicCurrentItem += (descSize+1);
                    uint32_t pictureDataSize = framesize - 4 - mimeSize - descSize;
                    const uint8_t *pictureData = apicCurrentItem;
                    if((pictureData+pictureDataSize) != (frames + (framesize+frameheadersize)))
                    {
                        MHFSCLTR_PRINT("picture size is messed up\n");
                    }
                    MHFSCLTR_PRINT("APIC encoding: %X mime: %s type: %X, desc: %s\n", encoding, mime, type, desc);
                    mhfs_cl_track_meta_picture picture = {
                        .pictureType = type,
                        .mimeSize = mimeSize,
                        .mime = (uint8_t*)mime,
                        .descSize = descSize,
                        .desc = (uint8_t*)desc,
                        .pictureDataSize = pictureDataSize,
                        .pictureData = pictureData
                    };
                    on_metablock(context, MHFS_CL_TRACK_M_PICTURE, &picture);
                }
            }

            tagSize -= (framesize+frameheadersize);
            frames += (framesize+frameheadersize);
        }
    }
    pTrack->vf.fileoffset = startoffset;

    // check for magic
    const uint8_t *id;
    const blockvf_error idError = blockvf_read_view(&pTrack->vf, 4, &id, &pReturnData->needed_offset);
    if(idError != BLOCKVF_SUCCESS)
    {
        return mhfs_cl_error_from_blockvf_error(idError);
    }
    const uint32_t uMagic = unaligned_beu32_to_native(id);
    // sync
    if((uMagic & 0xFFE00000) != 0xFFE00000)
    {
        return MHFS_CL_ERROR;
    }
    // version
    const unsigned version = (uMagic & 0x00180000) >> 19;
    if(version == MCT_MVER_RESERVED)
    {
        return MHFS_CL_ERROR;
    }
    // layer
    const unsigned layer = (uMagic & 0x00060000) >> 17;
    if(layer == MCT_MLAYER_RESERVED)
    {
        return MHFS_CL_ERROR;
    }
    // crc
    const unsigned crc = (uMagic & 0x00010000) >> 16;
    (void)crc;
    // bitrate index
    const unsigned bitrateindex = (uMagic & 0x0000F000) >> 12;
    MHFSCLTR_PRINT("birateindex %u\n", bitrateindex);
    if(bitrateindex == 0xF)
    {
        return MHFS_CL_ERROR;
    }
    static const uint8_t halfrate[2][3][15] = {
        { { 0,4,8,12,16,20,24,28,32,40,48,56,64,72,80 }, { 0,4,8,12,16,20,24,28,32,40,48,56,64,72,80 }, { 0,16,24,28,32,40,48,56,64,72,80,88,96,112,128 } },
        { { 0,16,20,24,28,32,40,48,56,64,80,96,112,128,160 }, { 0,16,24,28,32,40,48,56,64,80,96,112,128,160,192 }, { 0,16,32,48,64,80,96,112,128,144,160,176,192,208,224 } },
    };
    const unsigned bitrate = 2*halfrate[!!(version & 0x1)][layer - 1][bitrateindex];
    MHFSCLTR_PRINT("bitrate %u\n", bitrate);
    // samplerate index
    const unsigned samplerateindex = (uMagic & 0x00000C00) >> 10;
    MHFSCLTR_PRINT("samplerateindex %u\n", samplerateindex);
    if(samplerateindex == 0x3)
    {
        return MHFS_CL_ERROR;
    }
    static const unsigned g_hz[3] = { 44100, 48000, 32000 };
    const unsigned sampleRate = g_hz[samplerateindex] >> (int)!(version & 0x1) >> (int)!(version & 0x2);
    //padding and priv -- not read
    //channel mode
    const unsigned channelmode = (uMagic & 0x000000C0) >> 6;
    MHFSCLTR_PRINT("channel mode %u\n", channelmode);
    const unsigned channels = (channelmode == 3) ? 1 : 2;

    unsigned expectedXing = (channels == 2) ? 32 : 17;
    expectedXing += (!crc);
    MHFSCLTR_PRINT("Expecting xing %u bytes after mpeg header\n", expectedXing);
    const blockvf_error skipblockError = blockvf_seek(&pTrack->vf, expectedXing, blockvf_seek_origin_current);
    if(skipblockError != BLOCKVF_SUCCESS)
    {
        MHFSCLTR_PRINT("Stopping metadata parsing, blockvf error\n");
        return mhfs_cl_error_from_blockvf_error(skipblockError);
    }
    // check for xing
    const uint8_t *xing;
    const blockvf_error xingError = blockvf_read_view(&pTrack->vf, 4, &xing, &pReturnData->needed_offset);
    if(xingError != BLOCKVF_SUCCESS)
    {
        return mhfs_cl_error_from_blockvf_error(xingError);
    }
    MHFSCLTR_PRINT("xing/vbr magic %c %c %c %c | %x %x %x %x\n", xing[0], xing[1], xing[2], xing[3], xing[0], xing[1], xing[2], xing[3]);
    bool isXing = (memcmp(xing, "Xing", 4) == 0) || (memcmp(xing, "Info", 4) == 0);
    if(!isXing)
    {
        // Xing tag may be misplaced when CRC protection is enabled, check for that and zeroed flag fields
        isXing = (memcmp(xing, "ng\0\0", 4) == 0) || (memcmp(xing, "fo\0\0", 4) == 0);
        if(isXing)
        {
            pTrack->vf.fileoffset -= 2;
        }
    }
    if(isXing)
    {
        const uint8_t *flagsBytes;
        const blockvf_error xingFlagsError = blockvf_read_view(&pTrack->vf, 4, &flagsBytes, &pReturnData->needed_offset);
        if(xingFlagsError != BLOCKVF_SUCCESS)
        {
            return mhfs_cl_error_from_blockvf_error(xingFlagsError);
        }
        const uint32_t xingFlags = unaligned_beu32_to_native(flagsBytes);
        if(xingFlags & 0x1)
        {
            const uint8_t *framesBytes;
            const blockvf_error framesError = blockvf_read_view(&pTrack->vf, 4, &framesBytes, &pReturnData->needed_offset);
            if(framesError != BLOCKVF_SUCCESS)
            {
                return mhfs_cl_error_from_blockvf_error(framesError);
            }
            const uint32_t frames = unaligned_beu32_to_native(framesBytes);
            MHFSCLTR_PRINT("xing frames %u\n", frames);
            // FIX ME FIX ME we add 1 to mp3frames because the decoder will currently (foolishly) decode the xing mp3frame
            mhfs_cl_track_meta_audioinfo_init(&pTrack->meta, (frames + 1) * 1152, sampleRate, channels, MCT_MAI_FLD_BITRATE, 0, bitrate);
            if(on_metablock != NULL)
            {
                on_metablock(context, MHFS_CL_TRACK_M_AUDIOINFO, &pTrack->meta);
            }
            pTrack->meta_initialized = true;
            return MHFS_CL_SUCCESS;
        }
        return MHFS_CL_ERROR;
    }

    // check for VBRI
    const blockvf_error seekVBRI = blockvf_seek(&pTrack->vf, startoffset+36, blockvf_seek_origin_start);
    if(seekVBRI != BLOCKVF_SUCCESS)
    {
        return mhfs_cl_error_from_blockvf_error(seekVBRI);
    }
    const uint8_t *vbriMagic;
    const blockvf_error vbriMagicError = blockvf_read_view(&pTrack->vf, 4, &vbriMagic, &pReturnData->needed_offset);
    if(vbriMagicError != BLOCKVF_SUCCESS)
    {
        return mhfs_cl_error_from_blockvf_error(vbriMagicError);
    }
    if(memcmp(vbriMagic, "VBRI", 4) == 0)
    {
        MHFSCLTR_PRINT("VBRI found\n");
        const uint8_t *vbriFields;
        const blockvf_error vbriFieldsError = blockvf_read_view(&pTrack->vf, 22, &vbriFields, &pReturnData->needed_offset);
        if(vbriFieldsError != BLOCKVF_SUCCESS)
        {
            return mhfs_cl_error_from_blockvf_error(vbriFieldsError);
        }
        const uint32_t frames = unaligned_beu32_to_native(&vbriFields[10]);
        MHFSCLTR_PRINT("vbri frames %u\n", frames);
        // FIX ME FIX ME need to verify pcmframes  calculation
        mhfs_cl_track_meta_audioinfo_init(&pTrack->meta, (frames + 1) * 1152, sampleRate, channels, MCT_MAI_FLD_BITRATE, 0, bitrate);
        if(on_metablock != NULL)
        {
            on_metablock(context, MHFS_CL_TRACK_M_AUDIOINFO, &pTrack->meta);
        }
        pTrack->meta_initialized = true;
        return MHFS_CL_SUCCESS;
    }

    // TODO

    // ID3 TLEN?



    //estimate from bitrate?

    return MHFS_CL_ERROR;
}

typedef enum {
MCT_WAVE_FORMAT_PCM          = 0x1,
MCT_WAVE_FORMAT_ADPCM        = 0x2,
MCT_WAVE_FORMAT_IEEE_FLOAT   = 0x3,
MCT_WAVE_FORMAT_ALAW         = 0x6,
MCT_WAVE_FORMAT_MULAW        = 0x7,
MCT_WAVE_FORMAT_DVI_ADPCM    = 0x11,
MCT_WAVE_FORMAT_EXTENSIBLE   = 0xFFFE
} mhfs_cl_wav_format;

typedef enum {
    MCT_WAVE_CHUNK_FMT = 'f' | ('m' << 8) | ('t' << 16) | (' ' << 24),
    MCT_WAVE_CHUNK_DATA = 'd' | ('a' << 8) | ('t' << 16) | ('a' << 24)
} mhfs_cl_riff_chunk_type;

static inline mhfs_cl_error mhfs_cl_wav_read_chunk_header(blockvf *pBlockvf, uint32_t *pNeededOffset, mhfs_cl_riff_chunk_type *pChunkType, uint32_t *pChunkSize)
{
    const uint8_t *chunkHeader;
    const blockvf_error chunkHeaderError = blockvf_read_view(pBlockvf, 8, &chunkHeader, pNeededOffset);
    if(chunkHeaderError != BLOCKVF_SUCCESS)
    {
        return mhfs_cl_error_from_blockvf_error(chunkHeaderError);
    }
    *pChunkType = unaligned_leu32_to_native(&chunkHeader[0]);
    *pChunkSize = unaligned_leu32_to_native(&chunkHeader[4]);
    return MHFS_CL_SUCCESS;
}

static mhfs_cl_error mhfs_cl_track_load_metadata_wav(mhfs_cl_track *pTrack, mhfs_cl_track_return_data *pReturnData, const mhfs_cl_track_on_metablock on_metablock, void *context)
{
    {
    const uint8_t *wavHeader;
    const blockvf_error wavHeaderError = blockvf_read_view(&pTrack->vf, 12, &wavHeader, &pReturnData->needed_offset);
    if(wavHeaderError != BLOCKVF_SUCCESS)
    {
        return mhfs_cl_error_from_blockvf_error(wavHeaderError);
    }

    if(memcmp(&wavHeader[0], "RIFF", 4) != 0)
    {
        return MHFS_CL_ERROR;
    }
    /* chunksize is here */
    if(memcmp(&wavHeader[8], "WAVE", 4) != 0)
    {
        return MHFS_CL_ERROR;
    }
    }

    bool bGotFmt = false;
    unsigned channels;
    unsigned sampleRate;
    unsigned bitsPerSample;
    uint64_t totalPCMFrameCount;
    unsigned bytesPerPCMFrame;
    do {
        mhfs_cl_riff_chunk_type chunkType;
        uint32_t chunkSize;
        const mhfs_cl_error chunkHeaderError = mhfs_cl_wav_read_chunk_header(&pTrack->vf, &pReturnData->needed_offset, &chunkType, &chunkSize);
        if(chunkHeaderError != MHFS_CL_SUCCESS)
        {
            return chunkHeaderError;
        }
        if(chunkType == MCT_WAVE_CHUNK_FMT)
        {
            const uint8_t *fmtChunk;
            const blockvf_error chunkReadError = blockvf_read_view(&pTrack->vf, chunkSize, &fmtChunk, &pReturnData->needed_offset);
            if(chunkReadError != BLOCKVF_SUCCESS)
            {
                return mhfs_cl_error_from_blockvf_error(chunkReadError);
            }
            const mhfs_cl_wav_format audioFormat = unaligned_leu16_to_native(&fmtChunk[0]);
            switch(audioFormat)
            {
                case MCT_WAVE_FORMAT_PCM:
                /*case MCT_WAVE_FORMAT_ADPCM:
                case MCT_WAVE_FORMAT_IEEE_FLOAT:
                case MCT_WAVE_FORMAT_ALAW:
                case MCT_WAVE_FORMAT_MULAW:
                case MCT_WAVE_FORMAT_DVI_ADPCM:*/
                case MCT_WAVE_FORMAT_EXTENSIBLE:
                break;
                default:
                MHFSCLTR_PRINT("wav format not supported\n");
                return MHFS_CL_ERROR;
            }
            channels = unaligned_leu16_to_native(&fmtChunk[2]);
            sampleRate = unaligned_leu32_to_native(&fmtChunk[4]);
            /* byterate is here */
            const unsigned blockAlign = unaligned_leu16_to_native(&fmtChunk[12]);
            bitsPerSample = unaligned_leu16_to_native(&fmtChunk[14]);
            if(chunkSize > 16)
            {

            }

            /*
            The bytes per frame is a bit ambiguous. It can be either be based on the bits per sample, or the block align. The way I'm doing it here
            is that if the bits per sample is a multiple of 8, use floor(bitsPerSample*channels/8), otherwise fall back to the block align.
            */
            if ((bitsPerSample & 0x7) == 0) {
                /* Bits per sample is a multiple of 8. */
                bytesPerPCMFrame = (bitsPerSample * channels) >> 3;
            } else {
                bytesPerPCMFrame = blockAlign;
            }

            /* Validation for known formats. a-law and mu-law should be 1 byte per channel. If it's not, it's not decodable. */
            if (audioFormat == DR_WAVE_FORMAT_ALAW || audioFormat == DR_WAVE_FORMAT_MULAW) {
                if (bytesPerPCMFrame != channels) {
                    return MHFS_CL_ERROR;
                }
            }
            bGotFmt = true;
        }
        else if(chunkType == MCT_WAVE_CHUNK_DATA)
        {
            if(!bGotFmt)
            {
                return MHFS_CL_ERROR;
            }
            totalPCMFrameCount = chunkSize / bytesPerPCMFrame;
            mhfs_cl_track_meta_audioinfo_init(&pTrack->meta, totalPCMFrameCount, sampleRate, channels, MCT_MAI_FLD_BITSPERSAMPLE, bitsPerSample, 0);
            if(on_metablock != NULL)
            {
                on_metablock(context, MHFS_CL_TRACK_M_AUDIOINFO, &pTrack->meta);
            }
            pTrack->meta_initialized = true;
            MHFSCLTR_PRINT("self initialized metadata from wav\n");
            return MHFS_CL_SUCCESS;
        }
        else
        {
            const blockvf_error chunkSkipError = blockvf_seek(&pTrack->vf, chunkSize, blockvf_seek_origin_current);
            if(chunkSkipError != BLOCKVF_SUCCESS)
            {
                return mhfs_cl_error_from_blockvf_error(chunkSkipError);
            }
        }
    } while(1);

    return MHFS_CL_ERROR;
}



static inline void mhfs_cl_track_blockvf_ma_decoder_call_before(mhfs_cl_track *pTrack, const bool bSaveDecoder)
{
    pTrack->vfData.code = BLOCKVF_SUCCESS;
    if(bSaveDecoder)
    {
        mhfs_cl_track_allocs_backup(pTrack);
    }
}

static inline mhfs_cl_error mhfs_cl_track_blockvf_ma_decoder_call_after(mhfs_cl_track *pTrack, const bool bRestoreDecoder, uint32_t *pNeededOffset)
{
    if(pTrack->vfData.code != BLOCKVF_SUCCESS)
    {
        *pNeededOffset = pTrack->vfData.extradata;
        if(bRestoreDecoder)
        {
            mhfs_cl_track_allocs_restore(pTrack);
        }
    }
    return mhfs_cl_error_from_blockvf_error(pTrack->vfData.code);
}

static mhfs_cl_error mhfs_cl_track_open_ma_decoder(mhfs_cl_track *pTrack, uint32_t *pNeededOffset)
{
    pTrack->vf.fileoffset = 0;
    mhfs_cl_track_blockvf_ma_decoder_call_before(pTrack, false);
    const ma_result openRes = ma_decoder_init(&mhfs_cl_track_on_read_ma_decoder, &mhfs_cl_track_on_seek_ma_decoder, pTrack, &pTrack->decoderConfig, &pTrack->decoder);
    const mhfs_cl_error openBlockRes = mhfs_cl_track_blockvf_ma_decoder_call_after(pTrack, false, pNeededOffset);
    if(openBlockRes != MHFS_CL_SUCCESS)
    {
        if(openRes == MA_SUCCESS) ma_decoder_uninit(&pTrack->decoder);
        return openBlockRes;
    }
    else if(openRes == MA_SUCCESS)
    {
        pTrack->dec_initialized = true;
        return MHFS_CL_SUCCESS;
    }
    return MHFS_CL_ERROR;
}

static mhfs_cl_error mhfs_cl_track_load_metadata_ma_decoder(mhfs_cl_track *pTrack, mhfs_cl_track_return_data *pReturnData, const mhfs_cl_track_on_metablock on_metablock, void *context)
{
    // open the decoder
    mhfs_cl_error retval = mhfs_cl_track_open_ma_decoder(pTrack, &pReturnData->needed_offset);
    if(retval != MHFS_CL_SUCCESS)
    {
        return retval;
    }

    // read and store the metadata
    const unsigned savefileoffset = pTrack->vf.fileoffset;
    uint64_t totalPCMFrameCount = pTrack->meta.totalPCMFrameCount;
    if(pTrack->decoderConfig.encodingFormat != ma_encoding_format_mp3)
    {
        ma_decoder_get_length_in_pcm_frames(&pTrack->decoder, &totalPCMFrameCount);
    }
    MHFSCLTR_PRINT("decoder output samplerate %u\n", pTrack->decoder.outputSampleRate);
    mhfs_cl_track_meta_audioinfo_init(&pTrack->meta, totalPCMFrameCount, pTrack->decoder.outputSampleRate, pTrack->decoder.outputChannels, MCT_MAI_FLD_EMPTY, 0, 0);
    if(on_metablock != NULL)
    {
        on_metablock(context, MHFS_CL_TRACK_M_AUDIOINFO, &pTrack->meta);
    }

    if(retval == MHFS_CL_SUCCESS)
    {
        pTrack->meta_initialized = true;
    }
    pTrack->vf.fileoffset = savefileoffset;
    return retval;
}

static inline ma_encoding_format mhfs_cl_guess_codec(const uint8_t *id, const char *mime, const char *fullfilename)
{
    const size_t namelen = strlen(fullfilename);
    const char *lastFourChars = (namelen >= 4) ? (fullfilename + namelen - 4) : "";
    const uint32_t uMagic = unaligned_beu32_to_native(id);
    if(memcmp(id, "fLaC", 4) == 0)
    {
        return ma_encoding_format_flac;
    }
    else if(memcmp(id, "RIFF", 4) == 0)
    {
        return ma_encoding_format_wav;
    }
    // check mpeg sync and verify the audio version id isn't reserved
    else if(((uMagic & 0xFFE00000) == 0xFFE00000) && ((uMagic & 0x00180000) != 0x80000))
    {
        return ma_encoding_format_mp3;
    }
    // fallback, attempt to speed up guesses by mime
    else if(strcmp(mime, "audio/flac") == 0)
    {
        return ma_encoding_format_flac;
    }
    else if((strcmp(mime, "audio/wave") == 0) || (strcmp(mime, "audio/wav") == 0))
    {
        return ma_encoding_format_wav;
    }
    else if(strcmp(mime, "audio/mpeg") == 0)
    {
        return ma_encoding_format_mp3;
    }
    // fallback, fallback attempt to speed up guesses with file extension
    else if(strcmp(lastFourChars, "flac") == 0)
    {
        return ma_encoding_format_flac;
    }
    else if(strcmp(lastFourChars, ".wav") == 0)
    {
        return ma_encoding_format_wav;
    }
    else if(strcmp(lastFourChars, ".mp3") == 0)
    {
        return ma_encoding_format_mp3;
    }
    else
    {
        MHFSCLTR_PRINT("warning: unable to guess format\n");
        return ma_encoding_format_unknown;
    }
}

typedef struct {
    bool initialized;
    mhfs_cl_error res;
    uint32_t neededOffset;
} mhfs_cl_track_io_error;

static inline void mhfs_cl_track_io_error_update(mhfs_cl_track_io_error *ioError, const mhfs_cl_error res, const uint32_t neededOffset)
{
    if(res != MHFS_CL_NEED_MORE_DATA) return;
    if(!ioError->initialized)
    {
        ioError->initialized = true;
        ioError->res = res;
        ioError->neededOffset = neededOffset;
    }
}

mhfs_cl_error mhfs_cl_track_load_metadata(mhfs_cl_track *pTrack, mhfs_cl_track_return_data *pReturnData, const char *mime, const char *fullfilename, const uint64_t totalPCMFrameCount, const mhfs_cl_track_on_metablock on_metablock, void *context)
{
    mhfs_cl_track_return_data rd;
    if(pReturnData == NULL) pReturnData = &rd;

    // seek past ID3 tags
    pTrack->vf.fileoffset = 0;
    const uint8_t *id;
    for(;;)
    {
        const blockvf_error idError = blockvf_read_view(&pTrack->vf, 4, &id, &pReturnData->needed_offset);
        if(idError != BLOCKVF_SUCCESS)
        {
            return mhfs_cl_error_from_blockvf_error(idError);
        }
        MHFSCLTR_PRINT("uMagic %X %X %X %X @ 0x%X\n", id[0], id[1], id[2], id[3], pTrack->vf.fileoffset-4);
        if(memcmp(id, "ID3", 3) != 0) break;
        pTrack->vf.fileoffset--;
        uint16_t id3version;
        uint8_t flags;
        uint32_t tagSize;
        const mhfs_cl_error parseError = mhfs_cl_parse_id3_header_after_magic(&pTrack->vf, &pReturnData->needed_offset, &id3version, &flags, &tagSize);
        if(parseError != MHFS_CL_SUCCESS)
        {
            return parseError;
        }
        if(BLOCKVF_SUCCESS != blockvf_seek(&pTrack->vf, tagSize, blockvf_seek_origin_current))
        {
            return MHFS_CL_ERROR;
        }
    }
    pTrack->afterID3Offset = pTrack->vf.fileoffset - 4;

    // attempt to guess the codec to determine what codec to try first
    ma_encoding_format encFmt;
    if(pTrack->decoderConfig.encodingFormat == ma_encoding_format_unknown)
    {
        encFmt = mhfs_cl_guess_codec(id, mime, fullfilename);
    }
    else
    {
        encFmt = pTrack->decoderConfig.encodingFormat;
    }
    ma_encoding_format tryorder[] = { ma_encoding_format_flac, ma_encoding_format_mp3, ma_encoding_format_wav};
    const unsigned max_try_count = sizeof(tryorder) / sizeof(tryorder[0]);
    if(encFmt == ma_encoding_format_mp3)
    {
        mhfs_cl_track_swap_tryorder(&tryorder[DAF_MP3], &tryorder[0]);
    }
    else if(encFmt == ma_encoding_format_wav)
    {
        mhfs_cl_track_swap_tryorder(&tryorder[DAF_WAV], &tryorder[0]);
    }

    // set this as a fallback
    pTrack->meta.totalPCMFrameCount = totalPCMFrameCount;

    // try the various codecs
    mhfs_cl_track_io_error ioError = {
        .initialized = false
    };
    for(unsigned i = 0; i < max_try_count; i++)
    {
        pTrack->decoderConfig.encodingFormat = tryorder[i];
        pTrack->vf.fileoffset = pTrack->afterID3Offset;

        // try loading via our methods
        mhfs_cl_track_return_data temprd;
        if(pTrack->decoderConfig.encodingFormat == ma_encoding_format_flac)
        {
            const mhfs_cl_error retval = mhfs_cl_track_load_metadata_flac(pTrack, &temprd, on_metablock, context);
            if(retval == MHFS_CL_SUCCESS)
            {
                return retval;
            }
            mhfs_cl_track_io_error_update(&ioError, retval, temprd.needed_offset);
        }
        else if(pTrack->decoderConfig.encodingFormat == ma_encoding_format_wav)
        {
            const mhfs_cl_error retval = mhfs_cl_track_load_metadata_wav(pTrack, &temprd, on_metablock, context);
            if(retval == MHFS_CL_SUCCESS)
            {
                return retval;
            }
            mhfs_cl_track_io_error_update(&ioError, retval, temprd.needed_offset);
        }
        else if(pTrack->decoderConfig.encodingFormat == ma_encoding_format_mp3)
        {
            const mhfs_cl_error retval = mhfs_cl_track_load_metadata_mp3(pTrack, &temprd, on_metablock, context);
            if(retval == MHFS_CL_SUCCESS)
            {
                return retval;
            }
            mhfs_cl_track_io_error_update(&ioError, retval, temprd.needed_offset);
        }

        // try loading via ma_decoder
        const mhfs_cl_error retval = mhfs_cl_track_load_metadata_ma_decoder(pTrack, &temprd, on_metablock, context);
        if(retval == MHFS_CL_SUCCESS)
        {
            return retval;
        }
        mhfs_cl_track_io_error_update(&ioError, retval, temprd.needed_offset);
    }

    pTrack->decoderConfig.encodingFormat = encFmt;
    if(ioError.initialized)
    {
        pReturnData->needed_offset = ioError.neededOffset;
        return ioError.res;
    }
    return MHFS_CL_ERROR;
}

mhfs_cl_error mhfs_cl_track_read_pcm_frames_f32(mhfs_cl_track *pTrack, const uint32_t desired_pcm_frames, float32_t *outFloat, mhfs_cl_track_return_data *pReturnData)
{
    mhfs_cl_track_return_data rd;
    if(pReturnData == NULL) pReturnData = &rd;
    mhfs_cl_error retval = MHFS_CL_SUCCESS;

    // initialize the decoder if necessary
    if(!pTrack->meta_initialized)
    {
        MHFSCLTR_PRINT("metadata is somehow not initialized\n");
        return MHFS_CL_ERROR;
    }
    if(!pTrack->dec_initialized)
    {
        retval = mhfs_cl_track_open_ma_decoder(pTrack, &pReturnData->needed_offset);
        if(retval != MHFS_CL_SUCCESS) return retval;
    }

    // seek to sample
    MHFSCLTR_PRINT("seek to %u d_pcmframes %u\n", pTrack->currentFrame, desired_pcm_frames);
    const uint32_t currentPCMFrame32 = 0xFFFFFFFF;
    mhfs_cl_track_blockvf_ma_decoder_call_before(pTrack, true);
    const ma_result seekRes = ma_decoder_seek_to_pcm_frame(&pTrack->decoder, pTrack->currentFrame);
    const mhfs_cl_error seekBlockRes = mhfs_cl_track_blockvf_ma_decoder_call_after(pTrack, true, &pReturnData->needed_offset);
    if(seekBlockRes != MHFS_CL_SUCCESS)
    {
        MHFSCLTR_PRINT("%s: failed seek_to_pcm_frame NOT OK current: %u desired: %u\n", __func__, currentPCMFrame32, pTrack->currentFrame);
        return seekBlockRes;
    }
    if(seekRes != MA_SUCCESS)
    {
        MHFSCLTR_PRINT("%s: seek failed current: %u desired: %u ma_result %d\n", __func__, currentPCMFrame32, pTrack->currentFrame, seekRes);
        retval = MHFS_CL_ERROR;
        goto mhfs_cl_track_read_pcm_frames_f32_FAIL;
    }

    // finally read
    uint64_t frames_decoded = 0;
    if(desired_pcm_frames != 0)
    {
        uint64_t toread = desired_pcm_frames;

        // decode to pcm
        mhfs_cl_track_blockvf_ma_decoder_call_before(pTrack, true);
        ma_result decRes = ma_decoder_read_pcm_frames(&pTrack->decoder, outFloat, toread, &frames_decoded);
        const mhfs_cl_error decBlockRes = mhfs_cl_track_blockvf_ma_decoder_call_after(pTrack, true, &pReturnData->needed_offset);
        if(decBlockRes != MHFS_CL_SUCCESS)
        {
            MHFSCLTR_PRINT("mhfs_cl_track_read_pcm_frames_f32_mem: failed read_pcm_frames_f32\n");
            return decBlockRes;
        }
        if(decRes != MA_SUCCESS)
        {
            MHFSCLTR_PRINT("mhfs_cl_track_read_pcm_frames_f32_mem: failed read_pcm_frames_f32(decode), ma_result %d\n", decRes);
            retval = MHFS_CL_ERROR;
            if(decRes == MA_AT_END)
            {
                MHFSCLTR_PRINT("MA_AT_END\n"); // not a real error
            }
            goto mhfs_cl_track_read_pcm_frames_f32_FAIL;
        }
        if(frames_decoded != desired_pcm_frames)
        {
            MHFSCLTR_PRINT("mhfs_cl_track_read_pcm_frames_f32_mem: expected %u decoded %"PRIu64"\n", desired_pcm_frames, frames_decoded);
        }
        pTrack->currentFrame += frames_decoded;
    }

    MHFSCLTR_PRINT("returning from pTrack->currentFrame: %u, totalFrames %"PRIu64" frames_decoded %"PRIu64" desired %u\n", pTrack->currentFrame, pTrack->meta.totalPCMFrameCount, frames_decoded, desired_pcm_frames);
    pReturnData->frames_read = frames_decoded;
    return MHFS_CL_SUCCESS;

mhfs_cl_track_read_pcm_frames_f32_FAIL:
    if(pTrack->dec_initialized)
    {
        ma_decoder_uninit(&pTrack->decoder);
        pTrack->dec_initialized = false;
    }
    return retval;
}

#endif  /* mhfs_cl_track_c */
#endif  /* MHFSCLTRACK_IMPLEMENTATION */
