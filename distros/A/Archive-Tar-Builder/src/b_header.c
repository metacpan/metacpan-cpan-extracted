#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include "b_header.h"
#include "b_stack.h"
#include "b_path.h"
#include "b_util.h"

static inline uint64_t checksum(b_header_block *block) {
    uint64_t sum = 0;
    int i;

    for (i=0; i<B_HEADER_SIZE; i++) {
        sum += ((uint8_t *)(block))[i];
    }

    return sum;
}

static inline int is_big_endian() {
    uint16_t num = 1;

    return ((uint8_t *)&num)[1];
}

static inline void encode_base256_value(unsigned char *field, size_t len, uint64_t value) {
    size_t i;
    size_t value_size = sizeof(value);
    size_t offset     = len - value_size;

    for (i=0; i<value_size; i++) {
        int from_i = is_big_endian()? i: value_size - i - 1;

        field[offset + i] = ((uint8_t *)&value)[from_i];
    }

    /*
     * Set the uppermost bit to indicate a base256-encoded size value.
     */
    field[0] |= 0x80;
}

static inline void encode_checksum(b_header_block *block) {
    memcpy(  block->checksum, B_HEADER_EMPTY_CHECKSUM, B_HEADER_CHECKSUM_SIZE);
    snprintf(block->checksum, B_HEADER_CHECKSUM_LEN,   B_HEADER_CHECKSUM_FORMAT, checksum(block));

    block->checksum[7] = ' ';
}

size_t b_header_compute_pax_length(b_string *path, const char *record) {
    size_t len, i;
    char shortbuf[32];

    len = b_string_len(path);

    /* snprintf returns the number of characters (excluding the NUL) we would
     * have written had space been available.  Iterate three times to be sure
     * the value is stable.
     */
    for (i=0; i<3; i++) {
        len = snprintf(shortbuf, sizeof(shortbuf), "%d %s=%s\n", len, record, path->str);
    }

    return len;
}


b_header_block *b_header_encode_block(b_header_block *block, b_header *header) {
    if (header->suffix) {
        strncpy(block->suffix, header->suffix->str, 100);
    }

    snprintf(block->mode, B_HEADER_MODE_SIZE, B_HEADER_MODE_FORMAT, header->mode & S_IPERM);
    snprintf(block->uid,  B_HEADER_UID_SIZE,  B_HEADER_UID_FORMAT,  header->uid);
    snprintf(block->gid,  B_HEADER_GID_SIZE,  B_HEADER_GID_FORMAT,  header->gid);

    if (header->size >= B_HEADER_MAX_FILE_SIZE) {
        encode_base256_value(block->size, B_HEADER_SIZE_SIZE, header->size);
    } else {
        snprintf(block->size, B_HEADER_SIZE_SIZE, B_HEADER_LONG_SIZE_FORMAT, header->size);
    }

    snprintf(block->mtime, B_HEADER_MTIME_SIZE, B_HEADER_MTIME_FORMAT, header->mtime);

    block->linktype = header->linktype;

    if (header->linkdest != NULL) {
        strncpy(block->linkdest, header->linkdest->str, B_HEADER_LINKDEST_SIZE);
    }

    memcpy(block->magic, B_HEADER_MAGIC, B_HEADER_MAGIC_SIZE);

    if (header->user != NULL) {
        strncpy(block->user, header->user->str, B_HEADER_USER_SIZE);
    }

    if (header->group != NULL) {
        strncpy(block->group, header->group->str, B_HEADER_GROUP_SIZE);
    }

    if (header->major && header->minor) {
        snprintf(block->major, B_HEADER_MAJOR_SIZE, B_HEADER_MAJOR_FORMAT, header->major);
        snprintf(block->minor, B_HEADER_MINOR_SIZE, B_HEADER_MINOR_FORMAT, header->minor);
    }

    if (header->prefix) {
        strncpy(block->prefix, header->prefix->str, B_HEADER_PREFIX_SIZE);
    }

    encode_checksum(block);

    return block;
}

b_header_block *b_header_encode_longlink_block(b_header_block *block, b_string *path, int type) {
    memcpy(  block->magic,  B_HEADER_MAGIC,       B_HEADER_MAGIC_SIZE);
    snprintf(block->suffix, B_HEADER_SUFFIX_SIZE, B_HEADER_LONGLINK_PATH);
    snprintf(block->size,   B_HEADER_SIZE_SIZE,   B_HEADER_INT_SIZE_FORMAT,   b_string_len(path));

    block->linktype = type;

    encode_checksum(block);

    return block;
}

b_header_block *b_header_encode_pax_block(b_header_block *block, b_header *header, b_string *path) {
    size_t pax_len = b_header_compute_pax_length(path, "path");

    if (header->linkdest)
        pax_len += b_header_compute_pax_length(header->linkdest, "linkpath");

	b_header_encode_block(block, header);

    snprintf(block->size, B_HEADER_SIZE_SIZE, B_HEADER_LONG_SIZE_FORMAT, (unsigned long long)pax_len);

	memset(block->prefix, 0, sizeof(block->prefix));
	snprintf(block->prefix, sizeof(block->prefix), "./PaxHeaders.%d", getpid());
    block->linktype = B_HEADER_PAX_TYPE;

    encode_checksum(block);

    return block;
}

int b_header_set_usernames(b_header *header, b_string *user, b_string *group) {
    header->user  = user;
    header->group = group;

    return 0;
}

void b_header_destroy(b_header *header) {
    if (header == NULL) return;

    if (header->prefix != NULL) {
        b_string_free(header->prefix);
    }

    if (header->suffix != NULL) {
        b_string_free(header->suffix);
    }

    if (header->linkdest != NULL) {
        b_string_free(header->linkdest);
    }

    if (header->user != NULL) {
        b_string_free(header->user);
    }

    if (header->group != NULL) {
        b_string_free(header->group);
    }

    header->prefix   = NULL;
    header->suffix   = NULL;
    header->linkdest = NULL;
    header->user     = NULL;
    header->group    = NULL;

    free(header);
}
