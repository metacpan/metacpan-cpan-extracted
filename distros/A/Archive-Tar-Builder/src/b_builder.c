#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#ifdef __GLIBC__
#include <sys/sysmacros.h>
#endif /* __GLIBC__ */
#include <unistd.h>
#include <errno.h>
#include "match_engine.h"
#include "b_util.h"
#include "b_file.h"
#include "b_path.h"
#include "b_string.h"
#include "b_header.h"
#include "b_stack.h"
#include "b_buffer.h"
#include "b_builder.h"

struct path_data {
    b_string * prefix;
    b_string * suffix;
    int       truncated;
};

/*
 * Given the value of st->st_mode & S_IFMT, return the corresponding tar header
 * type identifier character.  The hardlink type is not accounted for here as
 * it is supplied below by header_for_file() when hardlinks are detected.
 */
static inline char inode_linktype(struct stat *st) {
    /*
     * The values in this jump table are sorted roughly in order of commonality
     * of each inode type.
     */
    switch (st->st_mode & S_IFMT) {
        case S_IFREG: return '0';
        case S_IFDIR: return '5';
        case S_IFLNK: return '2';
        case S_IFIFO: return '6';
        case S_IFCHR: return '3';
        case S_IFBLK: return '4';
    }

    return '0';
}

b_builder *b_builder_new(size_t block_factor) {
    b_builder *builder;

    if ((builder = malloc(sizeof(*builder))) == NULL) {
        goto error_malloc;
    }

    if ((builder->buf = b_buffer_new(block_factor? block_factor: B_BUFFER_DEFAULT_FACTOR)) == NULL) {
        goto error_buffer_new;
    }

    if ((builder->err = b_error_new()) == NULL) {
        goto error_error_new;
    }

    builder->total           = 0;
    builder->match           = NULL;
    builder->options         = B_BUILDER_NONE;
    builder->user_lookup     = NULL;
    builder->user_cache      = NULL;
    builder->hardlink_lookup = NULL;
    builder->hardlink_cache  = NULL;
    builder->data            = NULL;

    return builder;

error_error_new:
    b_buffer_destroy(builder->buf);

error_buffer_new:
    free(builder);

error_malloc:
    return NULL;
}

enum b_builder_options b_builder_get_options(b_builder *builder) {
    if (builder == NULL) return B_BUILDER_NONE;

    return builder->options;
}

void b_builder_set_options(b_builder *builder, enum b_builder_options options) {
    builder->options = options;
}

b_error *b_builder_get_error(b_builder *builder) {
    if (builder == NULL) return NULL;

    return builder->err;
}

b_buffer *b_builder_get_buffer(b_builder *builder) {
    if (builder == NULL) return NULL;

    return builder->buf;
}

void b_builder_set_data(b_builder *builder, void *data) {
    if (builder == NULL) return;

    builder->data = data;
}

/*
 * The caller should assume responsibility for initializing and destroying the
 * user lookup service as appropriate.
 */
void b_builder_set_user_lookup(b_builder *builder, b_user_lookup service, void *ctx) {
    builder->user_lookup = service;
    builder->user_cache     = ctx;
}

void b_builder_set_hardlink_cache(b_builder *builder, b_hardlink_lookup lookup, void *cache) {
    builder->hardlink_lookup = lookup;
    builder->hardlink_cache  = cache;
}

int b_builder_is_excluded(b_builder *builder, const char *path) {
    return lafe_excluded(builder->match, path);
}

int b_builder_include(b_builder *builder, const char *pattern) {
    return lafe_include(&builder->match, pattern);
}

int b_builder_include_from_file(b_builder *builder, const char *file) {
    return lafe_include_from_file(&builder->match, file, 0);
}

int b_builder_exclude(b_builder *builder, const char *pattern) {
    return lafe_exclude(&builder->match, pattern);
}

int b_builder_exclude_from_file(b_builder *builder, const char *file) {
    return lafe_exclude_from_file(&builder->match, file);
}

static int encode_longlink(b_builder *builder, b_header_block *block, b_string *path, int type, off_t *wrlen) {
    b_buffer *buf = builder->buf;
    b_error *err  = builder->err;

    if (path == NULL) {
        return 0;
    }

    if (b_header_encode_longlink_block(block, path, type) == NULL) {
        return -1;
    }

    builder->total += *wrlen;

    if ((*wrlen = b_file_write_path_blocks(buf, path)) < 0) {
        if (err) {
            b_error_set(err, B_ERROR_FATAL, errno, "Cannot write long filename header", path);
        }

        return -1;
    }

    builder->total += *wrlen;

    return 0;
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

static inline int is_hardlink(struct stat *st) {
    return (st->st_mode & S_IFMT) == S_IFREG && st->st_nlink > 1;
}

static b_header *header_for_file(b_builder *builder, b_string *path, b_string *member_name, struct stat *st) {
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
    ret->major     = major(st->st_dev);
    ret->minor     = minor(st->st_dev);
    ret->linktype  = inode_linktype(st);
    ret->linkdest  = NULL;
    ret->user      = NULL;
    ret->group     = NULL;

    ret->truncated_link = 0;

    if ((st->st_mode & S_IFMT) == S_IFLNK) {
        if ((ret->linkdest = b_readlink(path, st)) == NULL) {
            goto error_readlink;
        }
    } else if (is_hardlink(st) && builder->hardlink_lookup) {
        b_string *linkdest;

        if (linkdest = builder->hardlink_lookup(builder->hardlink_cache, st->st_dev, st->st_ino, path)) {
            ret->linktype = '0' + S_IF_HARDLINK;
            ret->linkdest = linkdest;
        }
    }

    if (ret->linkdest && b_string_len(ret->linkdest) > B_HEADER_LINKDEST_SIZE) {
        ret->truncated_link = 1;
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

int b_builder_write_file(b_builder *builder, b_string *path, b_string *member_name, struct stat *st, int fd) {
    b_buffer *buf = builder->buf;
    b_error *err  = builder->err;

    off_t wrlen = 0;

    b_header *header;
    b_header_block *block;

    if (buf == NULL) {
        errno = EINVAL;
        return -1;
    }

    if (err) {
        b_error_clear(err);
    }

    if ((header = header_for_file(builder, path, member_name, st)) == NULL) {
        if (err) {
            b_error_set(err, B_ERROR_FATAL, errno, "Cannot build header for file", path);
        }

        goto error_header_for_file;
    }

    /*
     * If there is a user lookup service installed, then resolve the user and
     * group of the current filesystem object and supply them within the
     * b_header object.
     */
    if (builder->user_lookup != NULL) {
        b_string *user = NULL, *group = NULL;

        if (builder->user_lookup(builder->user_cache, st->st_uid, st->st_gid, &user, &group) < 0) {
            if (err) {
                b_error_set(err, B_ERROR_WARN, errno, "Cannot lookup user and group for file", path);
            }

            goto error_lookup;
        }

        if (b_header_set_usernames(header, user, group) < 0) {
            goto error_lookup;
        }
    }

    /*
     * If the header is marked to contain truncated paths, then write a GNU
     * longlink header, followed by the blocks containing the path name to be
     * assigned.
     */
    if (header->truncated || header->truncated_link) {
        b_string *longlink_path;

        /*
         * GNU extensions must be explicitly enabled to encode GNU LongLink
         * headers.
         */
        if (!(builder->options & B_BUILDER_EXTENSIONS_MASK)) {
            errno = ENAMETOOLONG;

            if (err) {
                b_error_set(err, B_ERROR_WARN, errno, "File name too long", member_name);
            }

            goto error_path_toolong;
        }

        if ((block = b_buffer_get_block(buf, B_HEADER_SIZE, &wrlen)) == NULL) {
            goto error_get_header_block;
        }

        if ((longlink_path = b_string_dup(member_name)) == NULL) {
            goto error_longlink_path_dup;
        }

        if ((st->st_mode & S_IFMT) == S_IFDIR) {
            if ((b_string_append_str(longlink_path, "/")) == NULL) {
                goto error_longlink_path_append;
            }
        }

        if (builder->options & B_BUILDER_GNU_EXTENSIONS) {
            if (header->truncated && encode_longlink(builder, block, longlink_path, B_HEADER_LONGLINK_TYPE, &wrlen) < 0) {
                goto error_header_encode;
            }

            if (header->truncated_link && encode_longlink(builder, block, header->linkdest, B_HEADER_LONGDEST_TYPE, &wrlen) < 0) {
                goto error_header_encode;
            }
        } else if (builder->options & B_BUILDER_PAX_EXTENSIONS) {
            if (b_header_encode_pax_block(block, header, longlink_path) == NULL) {
                goto error_header_encode;
            }

            builder->total += wrlen;

            if ((wrlen = b_file_write_pax_path_blocks(buf, longlink_path, header->linkdest)) < 0) {
                if (err) {
                    b_error_set(err, B_ERROR_FATAL, errno, "Cannot write long filename header", member_name);
                }

                goto error_write;
            }

            builder->total += wrlen;
        }
    }

    /*
     * Then, of course, encode and write the real file header block.
     */
    if ((block = b_buffer_get_block(buf, B_HEADER_SIZE, &wrlen)) == NULL) {
        goto error_write;
    }

    if (b_header_encode_block(block, header) == NULL) {
        goto error_header_encode;
    }

    builder->total += wrlen;

    /*
     * Finally, end by writing the file contents.
     */
    if (B_HEADER_IS_IFREG(header) && fd > 0) {
        if ((wrlen = b_file_write_contents(buf, fd, header->size)) < 0) {
            if (err) {
                b_error_set(err, B_ERROR_WARN, errno, "Cannot write file to archive", path);
            }

            goto error_write;
        }

        builder->total += wrlen;
    }

    b_header_destroy(header);

    return 1;

error_write:
error_longlink_path_append:
error_longlink_path_dup:
error_get_header_block:
error_path_toolong:
error_header_encode:
error_lookup:
    b_header_destroy(header);

error_header_for_file:
    return -1;
}

void b_builder_destroy(b_builder *builder) {
    if (builder == NULL) return;

    if (builder->buf) {
        b_buffer_destroy(builder->buf);
        builder->buf = NULL;
    }

    if (builder->err) {
        b_error_destroy(builder->err);
        builder->err = NULL;
    }

    builder->options = B_BUILDER_NONE;
    builder->total   = 0;
    builder->data    = NULL;

    lafe_cleanup_exclusions(&builder->match);

    builder->match = NULL;

    free(builder);
}
