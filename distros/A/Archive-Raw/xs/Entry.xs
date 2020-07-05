MODULE = Archive::Raw               PACKAGE = Archive::Raw::Entry

unsigned int
filetype (self, ...)
	Entry self

	CODE:
		if (items > 1)
			archive_entry_set_filetype (self->e, SvUV (ST (1)));

		RETVAL = archive_entry_filetype (self->e);

	OUTPUT: RETVAL

const char *
pathname (self, ...)
	Entry self

	CODE:
		if (items > 1)
			archive_entry_set_pathname (self->e, SvPV_nolen (ST (1)));

		RETVAL = archive_entry_pathname (self->e);

	OUTPUT: RETVAL

void
is_data_encrypted (self)
	Entry self

	PPCODE:
#if ARCHIVE_VERSION_NUMBER >= 3002000
		if (archive_entry_is_data_encrypted (self->e))
			XSRETURN_YES;
#else
		croak ("this feature requires libarchive 3.2+");
#endif

		XSRETURN_NO;

void
is_metadata_encrypted (self)
	Entry self

	PPCODE:
#if ARCHIVE_VERSION_NUMBER >= 3002000
		if (archive_entry_is_metadata_encrypted (self->e))
			XSRETURN_YES;
#else
		croak ("this feature requires libarchive 3.2+");
#endif

		XSRETURN_NO;

void
is_encrypted (self)
	Entry self

	PPCODE:
#if ARCHIVE_VERSION_NUMBER >= 3002000
		if (archive_entry_is_encrypted (self->e))
			XSRETURN_YES;
#else
			croak ("this feature requires libarchive 3.2+");
#endif

		XSRETURN_NO;

void
ctime_is_set (self)
	Entry self

	PPCODE:
		if (archive_entry_ctime_is_set (self->e))
			XSRETURN_YES;

		XSRETURN_NO;

void
mtime_is_set (self)
	Entry self

	PPCODE:
		if (archive_entry_mtime_is_set (self->e))
			XSRETURN_YES;

		XSRETURN_NO;

void
size_is_set (self)
	Entry self

	PPCODE:
		if (archive_entry_size_is_set (self->e))
			XSRETURN_YES;

		XSRETURN_NO;

int
size (self, ...)
	Entry self

	CODE:
		if (items > 1)
		{
			if (SvOK (ST (1)))
				archive_entry_set_size (self->e, SvIV (ST (1)));
			else
				archive_entry_unset_size (self->e);
		}

		RETVAL = archive_entry_size (self->e);

	OUTPUT: RETVAL

double
ctime (self, ...)
	Entry self

	PREINIT:
		AV *result;

	CODE:
		if (items > 1)
		{
			if (SvOK (ST (1)))
				archive_entry_set_ctime (self->e, SvUV (ST (1)), items > 2 ? SvIV (ST (2)) : 0);
			else
				archive_entry_unset_ctime (self->e);
		}

		double res = archive_entry_ctime (self->e);
		res += archive_entry_ctime_nsec (self->e)/1000000000UL;

		RETVAL = res;

	OUTPUT: RETVAL

double
mtime (self, ...)
	Entry self

	PREINIT:
		AV *result;

	CODE:
		if (items > 1)
		{
			if (SvOK (ST (1)))
				archive_entry_set_mtime (self->e, SvUV (ST (1)), items > 2 ? SvIV (ST (2)) : 0);
			else
				archive_entry_unset_mtime (self->e);
		}

		double res = archive_entry_mtime (self->e);
		res += archive_entry_mtime_nsec (self->e)/1000000000UL;

		RETVAL = res;

	OUTPUT: RETVAL

const char *
uname (self, ...)
	Entry self

	CODE:
		if (items > 1)
			archive_entry_set_uname (self->e, SvPV_nolen (ST (1)));

		RETVAL = archive_entry_uname (self->e);

	OUTPUT: RETVAL

const char *
gname (self, ...)
	Entry self

	CODE:
		if (items > 1)
			archive_entry_set_gname (self->e, SvPV_nolen (ST (1)));

		RETVAL = archive_entry_gname (self->e);

	OUTPUT: RETVAL

SV *
uid (self, ...)
	Entry self

	CODE:
		if (items > 1)
			archive_entry_set_uid (self->e, SvUV (ST (1)));

		RETVAL = newSVuv (archive_entry_uid (self->e));

	OUTPUT: RETVAL

SV *
gid (self, ...)
	Entry self

	CODE:
		if (items > 1)
			archive_entry_set_gid (self->e, SvUV (ST (1)));

		RETVAL = newSVuv (archive_entry_gid (self->e));

	OUTPUT: RETVAL

SV *
mode (self, ...)
	Entry self

	CODE:
		if (items > 1)
			archive_entry_set_mode (self->e, SvUV (ST (1)));

		RETVAL = newSVuv (archive_entry_mode (self->e));

	OUTPUT: RETVAL

const char *
strmode (self)
	Entry self

	CODE:
		RETVAL = archive_entry_strmode (self->e);

	OUTPUT: RETVAL

const char *
symlink (self, ...)
	Entry self

	CODE:
		if (items > 1)
			archive_entry_set_symlink (self->e, SvPV_nolen (ST (1)));

		RETVAL = archive_entry_symlink (self->e);

	OUTPUT: RETVAL

int
symlink_type (self, ...)
	Entry self

	CODE:
#if ARCHIVE_VERSION_NUMBER >= 3004000
		if (items > 1)
			archive_entry_set_symlink_type (self->e, SvIV (ST (1)));
		RETVAL = archive_entry_symlink_type (self->e);
#else
		croak ("this feature requires libarchive 3.4+");
#endif

	OUTPUT: RETVAL

void
DESTROY (self)
	Entry self

	CODE:
		archive_entry_free (self->e);
		Safefree (self);
