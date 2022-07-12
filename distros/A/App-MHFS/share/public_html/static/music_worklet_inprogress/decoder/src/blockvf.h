#ifndef blockvf_h
#define blockvf_h
#include <stdbool.h>
#include <stdint.h>
#include <inttypes.h>

typedef struct blockvf_memrange {
    uint32_t start;
    struct blockvf_memrange *next;
} blockvf_memrange;

typedef enum {
    BLOCKVF_SUCCESS = 0,
    BLOCKVF_GENERIC_ERROR = 1,
    BLOCKVF_MEM_NEED_MORE = 2
} blockvf_error;

typedef struct  {
    void *buf;
    unsigned blocksize;
    blockvf_memrange *block;
    unsigned filesize;
    unsigned fileoffset;
} blockvf;

typedef enum
{
    blockvf_seek_origin_start,
    blockvf_seek_origin_current,
    blockvf_seek_origin_end
} blockvf_seek_origin;

unsigned blockvf_sizeof(void);
void blockvf_init(blockvf *pBlockvf, const unsigned blocksize);
void *blockvf_add_block(blockvf *pBlockvf, const uint32_t block_start, const unsigned filesize);
blockvf_error blockvf_seek(blockvf *pBlockvf, int64_t offset, blockvf_seek_origin origin);
blockvf_error blockvf_read(blockvf *pBlockvf, void* bufferOut, size_t bytesToRead, size_t *bytesRead, uint32_t *pNeededOffset);
blockvf_error blockvf_read_view(blockvf *pBlockvf, const size_t bytesToRead, const uint8_t **view, uint32_t *pNeededOffset);
void blockvf_deinit(blockvf *pBlockvf);
#endif /* blockvf_h */

#if defined(BLOCKVF_IMPLEMENTATION)
#ifndef block_vf_c
#define block_vf_c

#ifndef BLOCKVF_PRINT_ON
    #define BLOCKVF_PRINT_ON 0
#endif

#define BLOCKVF_PRINT(...) \
    do { if (BLOCKVF_PRINT_ON) fprintf(stdout, __VA_ARGS__); } while (0)

static int blockvf_realloc_buf(blockvf *pBlockvf, const unsigned bufsize)
{
	void *newbuf = realloc(pBlockvf->buf, bufsize);
	if(newbuf == NULL) return 0;
	pBlockvf->buf = newbuf;
    return 1;	
}

static void _blockvf_add_block(blockvf *pBlockvf, const uint32_t block_start)
{
    blockvf_memrange *block = malloc(sizeof(blockvf_memrange));
    block->start = block_start;
    blockvf_memrange **blocklist = &pBlockvf->block;
    for(;  *blocklist != NULL;  blocklist = &((*blocklist)->next))
    {
        if(block->start < ((*blocklist)->start))
        {
            break;
        }      
    }

    blockvf_memrange *nextblock = *blocklist;
    *blocklist = block;
    block->next = nextblock;
}

static bool blockvf_has_bytes(const blockvf *pBlockvf, const size_t bytesToRead, unsigned *neededblock)
{
    const unsigned blocksize = pBlockvf->blocksize;
    const unsigned last_needed_byte = pBlockvf->fileoffset + bytesToRead -1; 

    // initialize needed block to the block with fileoffset
    unsigned needed_block = (pBlockvf->fileoffset / pBlockvf->blocksize) * pBlockvf->blocksize;
    for(blockvf_memrange *block = pBlockvf->block; block != NULL; block = block->next)
    {
        if(block->start > needed_block)
        {
            // block starts after a needed block
            break;
        }
        else if(block->start == needed_block)
        {
            unsigned nextblock = block->start + blocksize;
            if(last_needed_byte < nextblock)
            {
                return true;
            }
            needed_block = nextblock;                
        }
    }

    BLOCKVF_PRINT("NEED MORE MEM file_offset: %u lastneedbyte %u needed_block %u\n", pBlockvf->fileoffset, last_needed_byte, needed_block);
    *neededblock = needed_block;
    /*for(blockvf_memrange *block = pBlockvf->block; block != NULL;)
    {
        BLOCKVF_PRINT("block: %u\n", block->start);
        blockvf_memrange *nextblock = block->next;        
        block = nextblock;
    }*/
    return false;
}

unsigned blockvf_sizeof(void)
{
    return sizeof(blockvf);
}

void blockvf_init(blockvf *pBlockvf, const unsigned blocksize)
{
    pBlockvf->buf = NULL;
    pBlockvf->blocksize = blocksize;
    pBlockvf->block = NULL;
    pBlockvf->filesize = 0;
    pBlockvf->fileoffset = 0;
}
void *blockvf_add_block(blockvf *pBlockvf, const uint32_t block_start, const unsigned filesize)
{
    // resize and or create the buffer if necessary
    int bufok = (pBlockvf->buf != NULL);
    if(filesize != pBlockvf->filesize)
    {   
        BLOCKVF_PRINT("changing filesize from %u to %u\n", pBlockvf->filesize, filesize);     
        if(filesize > pBlockvf->filesize)
        {   
            bufok = blockvf_realloc_buf(pBlockvf, filesize);            
        }
        // don't resize the buffer when file shrunk as a block could be pointing to it
        else
        {
            BLOCKVF_PRINT("warning, file shrunk\n");
            // fileoffset cannot exceed filesize
            if(pBlockvf->fileoffset > filesize)
            {
                BLOCKVF_PRINT("fileoffset > filesize, setting fileoffset to filesize\n");
                pBlockvf->fileoffset = filesize;
            }
        }
        pBlockvf->filesize = filesize;

    }
    if(!bufok) return NULL;

    // finally add the block to the list
    _blockvf_add_block(pBlockvf, block_start);
    return ((uint8_t*)(pBlockvf->buf))+block_start;
}

blockvf_error blockvf_seek(blockvf *pBlockvf, int64_t offset, blockvf_seek_origin origin)
{
    if(origin == blockvf_seek_origin_end)
    {
        BLOCKVF_PRINT("blockvf_seek: blockvf_seek_origin_end not supported, breaking %"PRId64" %u\n", offset, origin);
        return BLOCKVF_GENERIC_ERROR;
    }

    unsigned tempoffset = pBlockvf->fileoffset;
    if(origin == blockvf_seek_origin_current)
    {
        tempoffset += offset;
    }
    else
    {
        tempoffset = offset;
    }
    if((pBlockvf->filesize != 0) &&  (tempoffset > pBlockvf->filesize))
    {
        BLOCKVF_PRINT("blockvf_seek: seek past end of stream\n");        
        return BLOCKVF_GENERIC_ERROR;
    }

    BLOCKVF_PRINT("blockvf_seek seek update fileoffset %u\n", tempoffset);
    pBlockvf->fileoffset = tempoffset;
    return BLOCKVF_SUCCESS;
}

blockvf_error blockvf_read(blockvf *pBlockvf, void* bufferOut, size_t bytesToRead, size_t *bytesRead, uint32_t *pNeededOffset)
{
    if(pBlockvf->filesize > 0)
    {
        // don't allow us to read past EOF
        const unsigned endoffset = pBlockvf->fileoffset+bytesToRead;
        if(endoffset > pBlockvf->filesize)
        {
            BLOCKVF_PRINT("blockvf_read: truncating endoffset from %u to %u\n", endoffset, pBlockvf->filesize);
            bytesToRead = pBlockvf->filesize - pBlockvf->fileoffset;
        }
    }

    // nothing to read, do nothing
    if(bytesToRead == 0)
    {
        BLOCKVF_PRINT("blockvf_read: reached end of stream\n");
        *bytesRead = 0;        
        return BLOCKVF_SUCCESS;
    }
    
    //  HARD fail, we don't have the needed data
    unsigned needed;
    if(!blockvf_has_bytes(pBlockvf, bytesToRead, &needed))
    {
        *bytesRead = 0;
        *pNeededOffset = needed;
        return BLOCKVF_MEM_NEED_MORE;
    }
    
    // finally copy the data
    const unsigned src_offset = pBlockvf->fileoffset;
    const uint8_t  *src = (uint8_t*)(pBlockvf->buf);
    src += src_offset;
    //BLOCKVF_PRINT("memcpy 0x%p 0x%p %zu srcoffset %u filesize %u\n", bufferOut, src, bytesToRead, src_offset, pBlockvf->filesize);
    memcpy(bufferOut, src, bytesToRead);
    pBlockvf->fileoffset += bytesToRead;
    *bytesRead = bytesToRead;
    return BLOCKVF_SUCCESS;
}

// Zero copy blockvf access
blockvf_error blockvf_read_view(blockvf *pBlockvf, const size_t bytesToRead, const uint8_t **view, uint32_t *pNeededOffset)
{
    if(pBlockvf->filesize > 0)
    {
        // don't allow us to read past EOF
        const unsigned endoffset = pBlockvf->fileoffset+bytesToRead;
        if(endoffset > pBlockvf->filesize)
        {
            BLOCKVF_PRINT("blockvf_read_view: file is too small\n");
            return BLOCKVF_GENERIC_ERROR;
        }
    }

    unsigned needed;
    // NOP if bytesToRead == 0
    if(bytesToRead == 0)
    {
    }
    //  HARD fail, we don't have the needed data
    else if(!blockvf_has_bytes(pBlockvf, bytesToRead, &needed))
    {
        *pNeededOffset = needed;
        return BLOCKVF_MEM_NEED_MORE;
    }

    const unsigned before_offset = pBlockvf->fileoffset;
    pBlockvf->fileoffset += bytesToRead;
    *view = ((uint8_t*)(pBlockvf->buf)) + before_offset;
    return BLOCKVF_SUCCESS;
}

void blockvf_deinit(blockvf *pBlockvf)
{
    for(blockvf_memrange *block = pBlockvf->block; block != NULL;)
    {
        blockvf_memrange *nextblock = block->next;
        free(block);
        block = nextblock;
    }
    if(pBlockvf->buf != NULL) free(pBlockvf->buf);
}

#endif  /* block_vf_c */
#endif  /* BLOCKVF_IMPLEMENTATION */