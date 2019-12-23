MODULE = Archive::Raw               PACKAGE = Archive::Raw::Match

Match
new (class)
	SV *class

	PREINIT:
		archive_raw_match *self;

	CODE:
		Newxz (self, 1, archive_raw_match);
		self->m = archive_match_new();
		if (self->m == NULL)
			croak ("archive_match_new() failed");

		RETVAL = self;

	OUTPUT: RETVAL

void
excluded (self, entry)
	Match self
	Entry entry

	PPCODE:
		if (archive_match_excluded (self->m, entry->e))
			XSRETURN_YES;

		XSRETURN_NO;

void
path_excluded (self, entry)
	Match self
	Entry entry

	PPCODE:
		if (archive_match_path_excluded (self->m, entry->e))
			XSRETURN_YES;

		XSRETURN_NO;

void
time_excluded (self, entry)
	Match self
	Entry entry

	PPCODE:
		if (archive_match_time_excluded (self->m, entry->e))
			XSRETURN_YES;

		XSRETURN_NO;

void
owner_excluded (self, entry)
	Match self
	Entry entry

	PPCODE:
		if (archive_match_owner_excluded (self->m, entry->e))
			XSRETURN_YES;

		XSRETURN_NO;

void
include_pattern (self, pattern)
	Match self
	const char *pattern

	PREINIT:
		int rc;

	CODE:
		rc = archive_match_include_pattern (self->m, pattern);
		archive_check_error (rc, self->m, archive_match_include_pattern);

void
include_pattern_from_file (self, file)
	Match self
	const char *file

	PREINIT:
		int rc;

	CODE:
		rc = archive_match_include_pattern_from_file (self->m, file, 0);
		archive_check_error (rc, self->m, archive_match_include_pattern_from_file);

void
exclude_pattern (self, pattern)
	Match self
	const char *pattern

	PREINIT:
		int rc;

	CODE:
		rc = archive_match_exclude_pattern (self->m, pattern);
		archive_check_error (rc, self->m, archive_match_exclude_pattern);

void
exclude_pattern_from_file (self, file)
	Match self
	const char *file

	PREINIT:
		int rc;

	CODE:
		rc = archive_match_exclude_pattern_from_file (self->m, file, 0);
		archive_check_error (rc, self->m, archive_match_exclude_pattern_from_file);

void
include_uid (self, uid)
	Match self
	unsigned int uid

	PREINIT:
		int rc;

	CODE:
		rc = archive_match_include_uid (self->m, uid);
		archive_check_error (rc, self->m, archive_match_include_uid);

void
include_gid (self, gid)
	Match self
	unsigned int gid

	PREINIT:
		int rc;

	CODE:
		rc = archive_match_include_gid (self->m, gid);
		archive_check_error (rc, self->m, archive_match_include_gid);

void
include_uname (self, uname)
	Match self
	const char *uname

	PREINIT:
		int rc;

	CODE:
		rc = archive_match_include_uname (self->m, uname);
		archive_check_error (rc, self->m, archive_match_include_uname);

void
include_gname (self, gname)
	Match self
	const char *gname

	PREINIT:
		int rc;

	CODE:
		rc = archive_match_include_gname (self->m, gname);
		archive_check_error (rc, self->m, archive_match_include_gname);

void
DESTROY (self)
	Match self

	CODE:
		archive_match_free (self->m);
		Safefree (self);
