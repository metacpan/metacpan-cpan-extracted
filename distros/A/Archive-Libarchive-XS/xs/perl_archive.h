#ifndef PERL_LIBARCHIVE_H
#define PERL_LIBARCHIVE_H

#define HAS_archive_perl_codeset        1
#define HAS_archive_perl_utf8_mode      1

const char *archive_perl_codeset(void);
int archive_perl_utf8_mode(void);

#if ARCHIVE_VERSION_NUMBER < 3000000

#if !defined(__LA_INT64_T)
# if defined(_WIN32) && !defined(__CYGWIN__)
#  define __LA_INT64_T    __int64
# else
#  if defined(_SCO_DS)
#   define __LA_INT64_T    long long
#  else
#   define __LA_INT64_T    int64_t
#  endif
# endif
#endif

#define archive_read_support_filter_all(a)                                archive_read_support_compression_all(a)
#define archive_read_support_filter_bzip2(a)                              archive_read_support_compression_bzip2(a)
#define archive_read_support_filter_compress(a)                           archive_read_support_compression_compress(a)
#define archive_read_support_filter_gzip(a)                               archive_read_support_compression_gzip(a)
#define archive_read_support_filter_lzip(a)                               archive_read_support_compression_lzip(a)
#define archive_read_support_filter_lzma(a)                               archive_read_support_compression_lzma(a)
#define archive_read_support_filter_none(a)                               archive_read_support_compression_none(a)
#define archive_read_support_filter_program(a,cmd)                        archive_read_support_compression_program(a,cmd)
#define archive_read_support_filter_program_signature(a,cmd, match, size) archive_read_support_compression_program_signature(a, cmd,match,size)
#define archive_read_support_filter_rpm(a)                                archive_read_support_compression_rpm(a)
#define archive_read_support_filter_uu(a)                                 archive_read_support_compression_uu(a)
#define archive_read_support_filter_xz(a)                                 archive_read_support_compression_xz(a)

#define HAS_archive_read_support_filter_all                               HAS_archive_read_support_compression_all
#define HAS_archive_read_support_filter_bzip2                             HAS_archive_read_support_compression_bzip2
#define HAS_archive_read_support_filter_compress                          HAS_archive_read_support_compression_compress
#define HAS_archive_read_support_filter_gzip                              HAS_archive_read_support_compression_gzip
#define HAS_archive_read_support_filter_lzip                              HAS_archive_read_support_compression_lzip
#define HAS_archive_read_support_filter_lzma                              HAS_archive_read_support_compression_lzma
#define HAS_archive_read_support_filter_none                              HAS_archive_read_support_compression_none
#define HAS_archive_read_support_filter_program                           HAS_archive_read_support_compression_program
#define HAS_archive_read_support_filter_program_signature                 HAS_archive_read_support_compression_program_signature
#define HAS_archive_read_support_filter_rpm                               HAS_archive_read_support_compression_arpm
#define HAS_archive_read_support_filter_uu                                HAS_archive_read_support_compression_uu
#define HAS_archive_read_support_filter_xz                                HAS_archive_read_support_compression_xz

#define archive_entry_acl_add_entry(a,type,permset,tag,qual,name)         ARCHIVE_OK; archive_entry_acl_add_entry(a,type,permset,tag,qual,name)

#define archive_write_add_filter_bzip2(a)                                 archive_write_set_compression_bzip2(a)
#define archive_write_add_filter_compress(a)                              archive_write_set_compression_compress(a)
#define archive_write_add_filter_gzip(a)                                  archive_write_set_compression_gzip(a)
#define archive_write_add_filter_lzip(a)                                  archive_write_set_compression_lzip(a)
#define archive_write_add_filter_lzma(a)                                  archive_write_set_compression_lzma(a)
#define archive_write_add_filter_none(a)                                  archive_write_set_compression_none(a)
#define archive_write_add_filter_program(a,cmd)                           archive_write_set_compression_program(a,cmd)
#define archive_write_add_filter_xz(a)                                    archive_write_set_compression_xz(a)

#define HAS_archive_write_add_filter_bzip2                                HAS_archive_write_set_compression_bzip2
#define HAS_archive_write_add_filter_compress                             HAS_archive_write_set_compression_compress
#define HAS_archive_write_add_filter_gzip                                 HAS_archive_write_set_compression_gzip
#define HAS_archive_write_add_filter_lzip                                 HAS_archive_write_set_compression_lzip
#define HAS_archive_write_add_filter_lzma                                 HAS_archive_write_set_compression_lzma
#define HAS_archive_write_add_filter_none                                 HAS_archive_write_set_compression_none
#define HAS_archive_write_add_filter_program                              HAS_archive_write_set_compression_program
#define HAS_archive_write_add_filter_xz                                   HAS_archive_write_set_compression_xz

#define archive_read_free(a)                                              archive_read_finish(a)
#define HAS_archive_read_free                                             HAS_archive_read_finish
#define archive_write_free(a)                                             archive_write_finish(a)
#define HAS_archive_write_free                                            HAS_archive_write_finish

#endif

#endif
