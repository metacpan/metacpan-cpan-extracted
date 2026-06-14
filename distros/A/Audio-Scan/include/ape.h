/*
 *
 * Original Copyright:

Copyright (c) 2007 Jeremy Evans

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Refactored by Dan Sully

*/

#ifndef _APETAG_H_
#define _APETAG_H_

#define APE_CHECKED_APE        (1 << 0)
#define APE_CHECKED_OFFSET     (1 << 1)
#define APE_CHECKED_FIELDS     (1 << 2)
#define APE_HAS_APE            (1 << 3)
#define APE_HAS_ID3            (1 << 4)
#define APE_NO_ID3             (1 << 5)

/* Artificial limits -- recommended but can be increased */
#define APE_MAXIMUM_TAG_SIZE   2048 * 1024 // recommended limit is 8KB but have seen files that are larger (Bug 15324, https://github.com/Logitech/slimserver/issues/961)
#define APE_MAXIMUM_ITEM_COUNT 64
#define APE_ID3_MIN_TAG_SIZE   128

/* True minimum values */
#define APE_MINIMUM_TAG_SIZE   64
#define APE_ITEM_MINIMUM_SIZE  11

#define APE_ITEM_READ_FLAGS    1
#define APE_ITEM_READ_WRITE    0
#define APE_ITEM_READ_ONLY     1

#define APE_ITEM_TYPE_FLAGS    6
#define APE_ITEM_UTF8          0
#define APE_ITEM_BINARY        2
#define APE_ITEM_EXTERNAL      4
#define APE_ITEM_RESERVED      6

#define APE_PREAMBLE "APETAGEX"

#define ID3_LENGTH(TAG) (uint32_t)(((TAG->flags & APE_HAS_ID3) && !(TAG->flags & APE_NO_ID3)) ? APE_ID3_MIN_TAG_SIZE : 0)
#define TAG_LENGTH(TAG) (tag->size + ID3_LENGTH(TAG))

#define APE_TAG_HEADER_LEN     32
#define APE_TAG_FOOTER_LEN     32

#define APE_TAG_CONTAINS_HEADER 0x80000000
#define APE_TAG_TYPE_BINARY     0x00000002

typedef struct {
    PerlIO* fd;           /* PerlIO handle */
    HV* info;
    HV* tags;             /* Perl Hash structure to append tags into */
    char* filename;       /* Name of the file being parsed */
    Buffer tag_header;    /* Tag Header data */
    Buffer tag_data;      /* Tag body data */
    Buffer tag_footer;    /* Tag footer data */
    uint32_t version;     /* 1000 or 2000 */
    uint32_t flags;       /* parsing status flags */
    uint32_t footer_flags;
    uint32_t size;        /* On disk size in bytes */
    uint32_t offset;      /* offset counter used for artwork offset */
    uint32_t item_count;
    uint32_t num_fields;
} ApeTag;

int _ape_parse(ApeTag* tag);
int _ape_get_tag_info(ApeTag* tag);
int _ape_parse_fields(ApeTag* tag);
int _ape_parse_field(ApeTag* tag);
int _ape_check_validity(ApeTag* tag, uint32_t flags, char* key, char* value);

#endif /* !_APETAG_H_ */
