#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <archive.h>
#include <archive_entry.h>
#include "ppport.h"

int DEBUG = 0;

typedef struct archive* Archive__Peek__Libarchive;

struct archive* _open_file(const char * filename) {
    struct archive *a;
    int r;

    a = archive_read_new();
    archive_read_support_compression_all(a);
    archive_read_support_format_all(a);

    if ((r = archive_read_open_file(a, filename, 10240))) {
        croak(archive_error_string(a));
    }
    return a;
}

void _close_file(struct archive* a) {
    archive_read_close(a);
    archive_read_finish(a);
}

static int
_copy_data(struct archive *ar, struct archive *aw)
{
	int r;
	const void *buff;
	size_t size;
	off_t offset;

	for (;;) {
		r = archive_read_data_block(ar, &buff, &size, &offset);
		if (r == ARCHIVE_EOF)
			return (ARCHIVE_OK);
		if (r != ARCHIVE_OK)
			return (r);
		r = archive_write_data_block(aw, buff, size, offset);
		if (r != ARCHIVE_OK) {
			warn("archive_write_data_block()",
			    archive_error_string(aw));
			return (r);
		}
	}
}
    
MODULE = Archive::Extract::Libarchive          PACKAGE = Archive::Extract::Libarchive

void _extract(const char * filename, const char * path)
PPCODE:
    struct archive *a;
    struct archive *ext;
    struct archive_entry *entry;
    SV *path_sv;
    int r;
    int flags;
    
    a = _open_file(filename);

    flags = ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM | ARCHIVE_EXTRACT_ACL | ARCHIVE_EXTRACT_FFLAGS;
    ext = archive_write_disk_new();
    archive_write_disk_set_options(ext, flags);
    archive_write_disk_set_standard_lookup(ext);

    for (;;) {
        r = archive_read_next_header(a, &entry);
        if (r == ARCHIVE_EOF)
            break;
	if (r != ARCHIVE_OK)
            croak(archive_error_string(a));
        if (archive_entry_filetype(entry) == AE_IFREG) {
            mXPUSHs(newSVpv(archive_entry_pathname(entry), 0));
        }

	path_sv = newSVpv(path, 0);
	sv_catpvs(path_sv, "/");
	sv_catpv(path_sv, archive_entry_pathname(entry));
	archive_entry_set_pathname(entry, SvPV_nolen(path_sv));
	sv_free(path_sv);
	
	r = archive_write_header(ext, entry);
	if (r != ARCHIVE_OK)
	    croak(archive_error_string(ext));
	_copy_data(a, ext);
	r = archive_write_finish_entry(ext);
	if (r != ARCHIVE_OK)
	    croak(archive_error_string(ext));
    }
    _close_file(a);
    archive_write_close(ext);
    archive_write_finish(ext);
