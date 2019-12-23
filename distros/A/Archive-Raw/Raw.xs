#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <archive.h>
#include <archive_entry.h>

#include "constants.h"

#ifndef la_int64_t
#define la_int64_t __LA_INT64_T
#endif

typedef struct
{
	struct archive *ar;
	int reading;
} archive_raw_reader;

typedef struct
{
	struct archive *ar;
} archive_raw_diskwriter;

typedef struct
{
	struct archive_entry *e;
	archive_raw_reader *reader;
} archive_raw_entry;

typedef struct
{
	struct archive *m;
} archive_raw_match;

typedef archive_raw_diskwriter *DiskWriter;
typedef archive_raw_entry *Entry;
typedef archive_raw_match *Match;
typedef archive_raw_reader *Reader;

#ifndef MUTABLE_GV
#define MUTABLE_GV(p) ((GV *)MUTABLE_PTR(p))
#endif

#define ARCHIVE_NEW_OBJ(rv, package, sv)                   \
	STMT_START {                                       \
		(rv) = sv_setref_pv (newSV(0), package, sv);   \
	} STMT_END

STATIC void *archive_sv_to_ptr (const char *type, SV *sv, const char *file, int line)
{
	SV *full_type = sv_2mortal (newSVpvf ("Archive::Raw::%s", type));

	if (!(sv_isobject (sv) && sv_derived_from (sv, SvPV_nolen (full_type))))
		croak("Argument is not of type %s @ (%s:%d)\n",
			SvPV_nolen (full_type), file, line);

	return INT2PTR (void *, SvIV ((SV *) SvRV (sv)));
}

#define ARCHIVE_SV_TO_PTR(type, sv) \
	archive_sv_to_ptr(#type, sv, __FILE__, __LINE__)

#define archive_check_error(e, ar, method) \
	if (e < ARCHIVE_OK) \
		croak ("%s error: %s (%d)", #method, archive_error_string (ar), e);


MODULE = Archive::Raw               PACKAGE = Archive::Raw

int
libarchive_version()
	CODE:
		RETVAL = archive_version_number();

	OUTPUT: RETVAL

INCLUDE: const-xs-constants.inc

INCLUDE: xs/DiskWriter.xs
INCLUDE: xs/Entry.xs
INCLUDE: xs/Match.xs
INCLUDE: xs/Reader.xs
