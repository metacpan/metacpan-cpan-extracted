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

static mode_t TYPES[] = {
    S_IFREG,
    0xff,    /* placeholder for unsupported hardlink type */
    S_IFLNK,
    S_IFCHR,
    S_IFBLK,
    S_IFDIR,
    S_IFIFO,
    0
};

struct path_data {
    b_string * prefix;
    b_string * suffix;
    int       truncated;
};

static inline char inode_linktype(struct stat *st) {
    int i;

    for (i=0; TYPES[i]; i++) {
        if ((st->st_mode & S_IFMT) == TYPES[i]) {
            return '0' + i;
        }
    }

    return '0';
}

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

static struct path_data *path_split(b_string *path, struct stat *st) {
    struct path_data *data;

    b_stack *prefix_items, *suffix_items;
    size_t prefix_size = 0, suffix_size = 0;
    int add_to_prefix = 0;

    b_stack *parts;
    b_string *item;

    if ((data = malloc(sizeof(*data))) == NULL) {
        goto error_data_malloc;
    }

    if ((parts = b_path_new(path)) == NULL) {
        goto error_path_new;
    }

    if ((prefix_items = b_stack_new(0)) == NULL) {
        goto error_prefix_items;
    }

    if ((suffix_items = b_stack_new(0)) == NULL) {
        goto error_suffix_items;
    }

    b_stack_set_destructor(parts,        B_STACK_DESTRUCTOR(b_string_free));
    b_stack_set_destructor(prefix_items, B_STACK_DESTRUCTOR(b_string_free));
    b_stack_set_destructor(suffix_items, B_STACK_DESTRUCTOR(b_string_free));

    data->truncated = 0;

    if (b_stack_count(parts) == 0) {
        goto error_empty_stack;
    }

    /*
     * Strip the leading / from the path, if present.
     */
    if (b_string_len(b_stack_item_at(parts, 0)) == 0) {
        b_string *leading = b_stack_shift(parts);

        b_string_free(leading);
    }

    while ((item = b_stack_pop(parts)) != NULL) {
        if (suffix_size && suffix_size + item->len >= B_HEADER_SUFFIX_SIZE) {
            add_to_prefix = 1;
        }

        /* directory will have a / added to the end */
        if ( ( (st->st_mode & S_IFMT) == S_IFDIR ) && ( suffix_size + item->len + 1 >= B_HEADER_SUFFIX_SIZE ) ) {
            add_to_prefix = 1;
        }

        if (add_to_prefix) {
            if (prefix_size) prefix_size++; /* Add 1 to make room for path separator */
            prefix_size += item->len;
        } else {
            if (suffix_size) suffix_size++; /* ^-- Ditto */
            suffix_size += item->len;
        }

        if (b_stack_push(add_to_prefix? prefix_items: suffix_items, item) == NULL) {
            goto error_item;
        }
    }

    b_stack_destroy(parts);

    /*
     * Assemble the prefix and suffix strings.
     */
    if ((data->prefix = b_string_join("/", b_stack_reverse(prefix_items))) == NULL) {
        goto error_prefix;
    }

    if ((data->suffix = b_string_join("/", b_stack_reverse(suffix_items))) == NULL) {
        goto error_suffix;
    }

    /*
     * If the item we are dealing with is a directory, then always consider the
     * trailing slash in its representation.
     */
    if ((st->st_mode & S_IFMT) == S_IFDIR) {
        suffix_size++;
        b_string_append_str(data->suffix, "/");
    }

    /*
     * If either of these cases are true, then in normal circumstances the path
     * prefix or suffix MUST be truncated to fix into a tar header's corresponding
     * fields.
     *
     * Note that this calculation MUST happen after any other path suffix or prefix
     * size calculations are complete.
     */
    if (suffix_size > B_HEADER_SUFFIX_SIZE || prefix_size > B_HEADER_PREFIX_SIZE) {
        data->truncated = 1;
    }

    b_stack_destroy(prefix_items);
    b_stack_destroy(suffix_items);

    return data;

error_suffix:
    b_string_free(data->prefix);

error_prefix:
error_item:
error_empty_stack:
    b_stack_destroy(suffix_items);

error_suffix_items:
    b_stack_destroy(prefix_items);

error_prefix_items:
    b_stack_destroy(parts);

error_path_new:
    free(data);

error_data_malloc:
    return NULL;
}

b_header *b_header_for_file(b_string *path, b_string *member_name, struct stat *st) {
    b_header *ret;

    struct path_data *path_data;

    if ((ret = malloc(sizeof(*ret))) == NULL) {
        goto error_malloc;
    }

    if ((path_data = path_split(member_name, st)) == NULL) {
        goto error_path_data;
    }

    ret->truncated = path_data->truncated;
    ret->prefix    = path_data->prefix;
    ret->suffix    = path_data->suffix;
    ret->mode      = st->st_mode;
    ret->uid       = st->st_uid;
    ret->gid       = st->st_gid;
    ret->size      = (st->st_mode & S_IFMT) == S_IFREG? st->st_size: 0;
    ret->mtime     = st->st_mtime;
    ret->linktype  = inode_linktype(st);
    ret->linkdest  = NULL;
    ret->user      = NULL;
    ret->group     = NULL;

    /*
     * TODO: Implement major and minor (should be much easier than in Perl)
     */
    ret->major = 0;
    ret->minor = 0;

    ret->truncated_link = 0;

    if ((st->st_mode & S_IFMT) == S_IFLNK) {
        if ((ret->linkdest = b_readlink(path, st)) == NULL) {
            goto error_readlink;
        }
        if (b_string_len(ret->linkdest) > B_HEADER_LINKDEST_SIZE) {
            ret->truncated_link = 1;
        }
    }

    /* 
     * free() path_data, but keep its prefix and suffix with us, as we will free() those
     * ourselves b_header_destroy()
     */
    free(path_data);

    return ret;

error_readlink:
    b_string_free(path_data->prefix);
    b_string_free(path_data->suffix);

    free(path_data);

error_path_data:
    free(ret);

error_malloc:
    return NULL;
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
