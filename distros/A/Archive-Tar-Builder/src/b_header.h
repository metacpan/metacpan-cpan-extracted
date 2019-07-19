/*
 * Copyright (c) 2019, cPanel, L.L.C.
 * All rights reserved.
 * http://cpanel.net/
 *
 * This is free software; you can redistribute it and/or modify it under the
 * same terms as Perl itself.  See the Perl manual section 'perlartistic' for
 * further information.
 */

#ifndef _B_HEADER_H
#define _B_HEADER_H

#include <stdint.h>
#include <sys/types.h>
#include <fcntl.h>
#include <pwd.h>

#include "b_string.h"
#include "b_file.h"

#define B_HEADER_MAX_FILE_SIZE  8589934592

#define B_HEADER_SIZE            B_BLOCK_SIZE
#define B_HEADER_SUFFIX_SIZE   100
#define B_HEADER_MODE_SIZE       8
#define B_HEADER_UID_SIZE        8
#define B_HEADER_GID_SIZE        8
#define B_HEADER_SIZE_SIZE      12
#define B_HEADER_MTIME_SIZE     12
#define B_HEADER_CHECKSUM_SIZE   8
#define B_HEADER_CHECKSUM_LEN    7
#define B_HEADER_LINKDEST_SIZE 100
#define B_HEADER_MAGIC_SIZE      8
#define B_HEADER_USER_SIZE      32
#define B_HEADER_GROUP_SIZE     32
#define B_HEADER_MAJOR_SIZE      8
#define B_HEADER_MINOR_SIZE      8
#define B_HEADER_PREFIX_SIZE   155
#define B_HEADER_PADDING_SIZE   12

#define B_HEADER_MAGIC           "ustar\x00\x30\x30"
#define B_HEADER_MAX_USTAR_SIZE  LL8_589_934_591
#define B_HEADER_EMPTY_CHECKSUM  "\x20\x20\x20\x20\x20\x20\x20\x20"
#define B_HEADER_LONGLINK_PATH   "././@LongLink"
#define B_HEADER_LONGLINK_TYPE   'L'
#define B_HEADER_LONGDEST_TYPE   'K'
#define B_HEADER_PAX_TYPE        'x'

#define B_HEADER_MODE_FORMAT      "%.7o"
#define B_HEADER_UID_FORMAT       "%.7o"
#define B_HEADER_GID_FORMAT       "%.7o"
#define B_HEADER_INT_SIZE_FORMAT  "%.11o"
#define B_HEADER_LONG_SIZE_FORMAT "%.11llo"
#define B_HEADER_MTIME_FORMAT     "%.11o"
#define B_HEADER_CHECKSUM_FORMAT  "%.6o"
#define B_HEADER_MAJOR_FORMAT     "%.7lo"
#define B_HEADER_MINOR_FORMAT     "%.7lo"

#ifndef S_IPERM
#define S_IPERM 0777
#endif /* S_IPERM */

#define S_IF_HARDLINK 1

#define B_HEADER_IS_HARDLINK(header) \
    (header->linktype == '0' + S_IF_HARDLINK)

#define B_HEADER_IS_IFREG(header) \
    (header->linktype == '0')

typedef struct _b_header {
    b_string * suffix;
    mode_t     mode;
    uid_t      uid;
    gid_t      gid;
    uint64_t   size;
    time_t     mtime;
    char       linktype;
    b_string * linkdest;
    b_string * user;
    b_string * group;
    dev_t      major;
    dev_t      minor;
    b_string * prefix;
    int        truncated;
    int        truncated_link;
} b_header;

typedef struct _b_header_block {
    char suffix   [B_HEADER_SUFFIX_SIZE];
    char mode     [B_HEADER_MODE_SIZE];
    char uid      [B_HEADER_UID_SIZE];
    char gid      [B_HEADER_GID_SIZE];
    char size     [B_HEADER_SIZE_SIZE];
    char mtime    [B_HEADER_MTIME_SIZE];
    char checksum [B_HEADER_CHECKSUM_SIZE];
    char linktype;
    char linkdest [B_HEADER_LINKDEST_SIZE];
    char magic    [B_HEADER_MAGIC_SIZE];
    char user     [B_HEADER_USER_SIZE];
    char group    [B_HEADER_GROUP_SIZE];
    char major    [B_HEADER_MAJOR_SIZE];
    char minor    [B_HEADER_MINOR_SIZE];
    char prefix   [B_HEADER_PREFIX_SIZE];
    char padding  [B_HEADER_PADDING_SIZE];
} b_header_block;

b_header *       b_header_for_file(b_string *path, b_string *member_name, struct stat *st);
int              b_header_set_usernames(b_header *header, b_string *user, b_string *group);
b_header_block * b_header_encode_block(b_header_block *block, b_header *header);
b_header_block * b_header_encode_longlink_block(b_header_block *block, b_string *path, int type);
b_header_block * b_header_encode_pax_block(b_header_block *block, b_header *header, b_string *path);
size_t           b_header_compute_pax_length(b_string *path, const char *record);
void             b_header_destroy(b_header *header);

#endif /* _B_HEADER_H */
