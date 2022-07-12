#ifndef mhfs_cl_decoder_h
#define mhfs_cl_decoder_h

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#define LIBEXPORT EMSCRIPTEN_KEEPALIVE
#else
#define LIBEXPORT
#endif
#include "miniaudio.h"

#include "mhfs_cl.h"

typedef struct {
    unsigned outputSampleRate;
    unsigned outputChannels;
    bool has_madc;
    ma_data_converter madc;
    size_t dcTempOutSize;
    float32_t *pDCTempOut;
    unsigned interleaveData_pcm_frames;
    float32_t interleavedData[];
} mhfs_cl_decoder;

LIBEXPORT mhfs_cl_decoder *mhfs_cl_decoder_open(const unsigned outputSampleRate, const unsigned outputChannels, const unsigned deinterleave_max_pcm_frames);
LIBEXPORT mhfs_cl_error mhfs_cl_decoder_read_pcm_frames_f32_deinterleaved(mhfs_cl_decoder *mhfs_d, mhfs_cl_track *pTrack, const uint32_t desired_pcm_frames, float32_t *outFloat[], mhfs_cl_track_return_data *pReturnData);
LIBEXPORT void mhfs_cl_decoder_close(mhfs_cl_decoder *mhfs_d);
LIBEXPORT void mhfs_cl_decoder_flush(mhfs_cl_decoder *mhfs_d);
#endif /* mhfs_cl_decoder_h */

#if defined(MHFSCLDECODER_IMPLEMENTATION)
#ifndef mhfs_cl_decoder_c
#define mhfs_cl_decoder_c

#include "mhfs_cl_track.h"

#ifndef MHFSCLDEC_PRINT_ON
    #define MHFSCLDEC_PRINT_ON 0
#endif

#define MHFSCLDEC_PRINT(...) \
    do { if (MHFSCLDEC_PRINT_ON) fprintf(stdout, __VA_ARGS__); } while (0)

size_t mhfs_cl_decoder_size(const unsigned outputChannels, const unsigned deinterleave_max_pcm_frames)
{
    return sizeof(mhfs_cl_decoder) + (sizeof(float32_t*) * outputChannels * deinterleave_max_pcm_frames);
}

mhfs_cl_decoder *mhfs_cl_decoder_open(const unsigned outputSampleRate, const unsigned outputChannels, const unsigned deinterleave_max_pcm_frames)
{
    mhfs_cl_decoder *mhfs_d = malloc(mhfs_cl_decoder_size(outputChannels, deinterleave_max_pcm_frames));
    if(mhfs_d == NULL) return NULL;
    mhfs_d->outputSampleRate = outputSampleRate;
    mhfs_d->outputChannels = outputChannels;
    mhfs_d->has_madc = false;
    mhfs_d->dcTempOutSize = 0;
    mhfs_d->pDCTempOut = NULL;
    mhfs_d->interleaveData_pcm_frames = deinterleave_max_pcm_frames;
    return mhfs_d;
}

void mhfs_cl_decoder_close(mhfs_cl_decoder *mhfs_d)
{
    if(mhfs_d->has_madc)  ma_data_converter_uninit(&mhfs_d->madc, NULL);
    if(mhfs_d->pDCTempOut != NULL) free(mhfs_d->pDCTempOut);
    free(mhfs_d);
}

void mhfs_cl_decoder_flush(mhfs_cl_decoder *mhfs_d)
{
    if(mhfs_d->has_madc)
    {
        ma_data_converter_uninit(&mhfs_d->madc, NULL);
        mhfs_d->has_madc = false;
    }
}

mhfs_cl_error mhfs_cl_decoder_read_pcm_frames_f32(mhfs_cl_decoder *mhfs_d, mhfs_cl_track *pTrack, const uint32_t desired_pcm_frames, float32_t *outFloat, mhfs_cl_track_return_data *pReturnData)
{
    // open the decoder if needed
    if(!pTrack->dec_initialized)
    {
        MHFSCLDEC_PRINT("force open ma_decoder (not initialized)\n");
        const mhfs_cl_error openCode = mhfs_cl_track_read_pcm_frames_f32(pTrack, 0, NULL, pReturnData);
        if(openCode != MHFS_CL_SUCCESS)
        {
            return openCode;
        }
    }
    
    // fast path, no resampling / channel conversion needed
    if((pTrack->meta.sampleRate == mhfs_d->outputSampleRate) && (pTrack->meta.channels == mhfs_d->outputChannels))
    {
        return mhfs_cl_track_read_pcm_frames_f32(pTrack, desired_pcm_frames, outFloat, pReturnData);
    }
    else
    {
        // initialize the data converter
        if(mhfs_d->has_madc && (mhfs_d->madc.channelsIn != pTrack->meta.channels))
        {
            ma_data_converter_uninit(&mhfs_d->madc, NULL);
            mhfs_d->has_madc = false;            
        }
        if(!mhfs_d->has_madc)
        {
            ma_data_converter_config config = ma_data_converter_config_init(ma_format_f32, ma_format_f32, pTrack->meta.channels, mhfs_d->outputChannels, pTrack->meta.sampleRate, mhfs_d->outputSampleRate);
            if(ma_data_converter_init(&config, NULL, &mhfs_d->madc) != MA_SUCCESS)
            {
                MHFSCLDEC_PRINT("failed to init data converter\n");
                return MHFS_CL_ERROR;
            }
            mhfs_d->has_madc = true;
            MHFSCLDEC_PRINT("success init data converter\n"); 
        }
        else if(mhfs_d->madc.sampleRateIn != pTrack->meta.sampleRate)
        {
            if(ma_data_converter_set_rate(&mhfs_d->madc, pTrack->meta.sampleRate, mhfs_d->outputSampleRate) != MA_SUCCESS)
            {
                MHFSCLDEC_PRINT("failed to change data converter samplerate\n");
                return MHFS_CL_ERROR;
            }
        }

        // decode
        uint64_t dec_frames_req;
        if(ma_data_converter_get_required_input_frame_count(&mhfs_d->madc, desired_pcm_frames, &dec_frames_req) != MA_SUCCESS)
        {
            MHFSCLDEC_PRINT("failed to get data converter input frame count\n");
            return MHFS_CL_ERROR;
        }
        const size_t reqBytes = dec_frames_req * sizeof(float32_t)*pTrack->meta.channels;
        if(reqBytes > mhfs_d->dcTempOutSize)
        {
            float32_t *tempOut = realloc(mhfs_d->pDCTempOut, reqBytes);
            if(tempOut == NULL)
            {
                MHFSCLDEC_PRINT("realloc failed\n");
                return MHFS_CL_ERROR;
            }
            mhfs_d->dcTempOutSize = reqBytes;
            mhfs_d->pDCTempOut = tempOut;
        }
        const mhfs_cl_error readCode = mhfs_cl_track_read_pcm_frames_f32(pTrack, dec_frames_req, mhfs_d->pDCTempOut, pReturnData);
        if((readCode != MHFS_CL_SUCCESS) || (pReturnData->frames_read == 0))
        {
            return readCode;
        }
        uint64_t decoded_frames = pReturnData->frames_read;

        // resample
        uint64_t frameCountOut = desired_pcm_frames;       
        ma_result result = ma_data_converter_process_pcm_frames(&mhfs_d->madc, mhfs_d->pDCTempOut, &decoded_frames, outFloat, &frameCountOut);
        if(result != MA_SUCCESS)
        {
            MHFSCLDEC_PRINT("resample failed\n");
            return MHFS_CL_ERROR;
        }
        pReturnData->frames_read = frameCountOut;
        return MHFS_CL_SUCCESS;
    }
}

mhfs_cl_error mhfs_cl_decoder_read_pcm_frames_f32_deinterleaved(mhfs_cl_decoder *mhfs_d, mhfs_cl_track *pTrack, const uint32_t desired_pcm_frames, float32_t *outFloat[], mhfs_cl_track_return_data *pReturnData)
{
    if(desired_pcm_frames > mhfs_d->interleaveData_pcm_frames)
    {
        MHFSCLDEC_PRINT("%s: Not enough space to deinterleave internally\n", __func__);
        return MHFS_CL_ERROR;
    }
    const mhfs_cl_error code = mhfs_cl_decoder_read_pcm_frames_f32(mhfs_d, pTrack, desired_pcm_frames, mhfs_d->interleavedData, pReturnData);
    if(code == MHFS_CL_SUCCESS)
    {
        for(unsigned i = 0; i < pReturnData->frames_read; i++)
        {
            for(unsigned j = 0; j < mhfs_d->outputChannels; j++)
            {
                const float32_t sample = mhfs_d->interleavedData[(i*mhfs_d->outputChannels) + j];
                outFloat[j][i] = sample;
            }
        }
    }
    return code;
}

#endif  /* mhfs_cl_decoder_c */
#endif  /* MHFSCLDECODER_IMPLEMENTATION */
