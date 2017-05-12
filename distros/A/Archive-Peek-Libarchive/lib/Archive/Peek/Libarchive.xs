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
    
MODULE = Archive::Peek::Libarchive          PACKAGE = Archive::Peek::Libarchive

void _files(const char * filename)
PPCODE:
    struct archive *a;
    struct archive_entry *entry;
    int r;

    a = _open_file(filename);

    for (;;) {
        r = archive_read_next_header(a, &entry);
        if (r == ARCHIVE_EOF)
            break;
	if (r != ARCHIVE_OK)
            croak(archive_error_string(a));
        if (archive_entry_filetype(entry) == AE_IFREG) {
            mXPUSHs(newSVpv(archive_entry_pathname(entry), 0));
        }
    }
    _close_file(a);

void _file(const char * archivename, const char * filename)
PPCODE:
    struct archive *a;
    struct archive_entry *entry;
    int r;
    const void *buffer;
    size_t size;
    off_t offset;
    SV* sv;
    SV* temp;

    a = _open_file(archivename);
    sv = newSVpvs("");
        
    for (;;) {
        r = archive_read_next_header(a, &entry);
        if (r == ARCHIVE_EOF)
            break;
	if (r != ARCHIVE_OK)
            croak(archive_error_string(a));
        if (archive_entry_filetype(entry) == AE_IFREG && (strcmp(archive_entry_pathname(entry), filename)) == 0) {
	    for (;;) {
                r = archive_read_data_block(a, &buffer, &size, &offset);
		if (r == ARCHIVE_EOF) {
                    break;
		}
		if (r != ARCHIVE_OK) {
                    croak(archive_error_string(a));
                }
		sv_catpvn(sv, buffer, size);
            }
        }
    }
    XPUSHs(sv);
    _close_file(a);

void _iterate(const char * archivename, SV* callbackref)
CODE:
    struct archive *a;
    struct archive_entry *entry;
    int r;
    const void *buffer;
    size_t size;
    off_t offset;
    SV* filename;
    SV* contents;
    SV* callback;

    if (!SvROK((SV*) callbackref)) {
	Perl_croak(aTHX_ "YAJL: callbackref is not a reference");
    } else {
	DEBUG && printf("  callbackref is a reference\n");
    }

    callback = (SV*) SvRV((SV*) callbackref);
    if (SvTYPE(callback) != SVt_PVCV) {
        Perl_croak(aTHX_ "Callback is not a PVCV");
    } else {
        DEBUG && printf("  callback is a PVCV\n");
    }
    DEBUG && printf("  about to call callback\n");

    a = _open_file(archivename);

    for (;;) {
        r = archive_read_next_header(a, &entry);
        if (r == ARCHIVE_EOF)
            break;
	if (r != ARCHIVE_OK)
            croak(archive_error_string(a));
        if (archive_entry_filetype(entry) == AE_IFREG) {
	    DEBUG && printf("  start\n");
	    contents = newSVpvs("");

            filename = newSVpv(archive_entry_pathname(entry), 0);
	    for (;;) {
                r = archive_read_data_block(a, &buffer, &size, &offset);
		if (r == ARCHIVE_EOF) {
                    break;
		}
		if (r != ARCHIVE_OK) {
                    croak(archive_error_string(a));
                }
		sv_catpvn(contents, buffer, size);
            }
	    DEBUG && printf("  dSP\n");
	    dSP;
	    DEBUG && printf("  ENTER\n");
	    ENTER;
	    DEBUG && printf("  SAVETMPS\n");
	    SAVETMPS;
	    DEBUG && printf("  PUSHMARK\n");
	    PUSHMARK(SP);
	    DEBUG && printf("  mXPUSHs1\n");
	    mXPUSHs(filename);
	    DEBUG && printf("  mXPUSHs2\n");
	    mXPUSHs(contents);
	    DEBUG && printf("  PUTBACK\n");
	    PUTBACK;
	    DEBUG && printf("  call_sv\n");
	    call_sv(callback, G_DISCARD);
	    DEBUG && printf("  FREETMPS\n");
            FREETMPS;
	    DEBUG && printf("  LEAVE\n");
	    LEAVE;
	    DEBUG && printf("  end\n");

        }
    }
    _close_file(a);
