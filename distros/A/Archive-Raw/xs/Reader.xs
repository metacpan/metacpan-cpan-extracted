MODULE = Archive::Raw               PACKAGE = Archive::Raw::Reader

Reader
new (class)
	SV *class

	PREINIT:
		archive_raw_reader *self;

	CODE:
		Newxz (self, 1, archive_raw_reader);
		self->ar = archive_read_new();
		if (self->ar == NULL)
			croak ("archive_read_new() failed");

		archive_read_support_format_all (self->ar);
		archive_read_support_filter_all (self->ar);

		RETVAL = self;

	OUTPUT: RETVAL

void
open_filename (self, filename)
	Reader self
	const char *filename

	PREINIT:
		int rc;

	CODE:
		if (self->reading)
			croak ("already open");

		rc = archive_read_open_filename (self->ar, filename, 16384);
		archive_check_error (rc, self->ar, archive_read_open_filename);

		self->reading = 1;

Entry
next (self)
	Reader self

	PREINIT:
		int rc;
		archive_raw_entry *entry;
		struct archive_entry *e;

	CODE:
		if (!self->reading)
			croak ("not open");

		rc = archive_read_next_header (self->ar, &e);
		if (rc == ARCHIVE_EOF)
			XSRETURN_UNDEF;
		archive_check_error (rc, self->ar, archive_read_next_header);

		Newxz (entry, 1, archive_raw_entry);
		entry->e = archive_entry_clone (e);
		entry->reader = self; // TODO: This should be reference counted

		RETVAL = entry;

	OUTPUT: RETVAL

int
has_encrypted_entries (self)
	Reader self

	CODE:
#if ARCHIVE_VERSION_NUMBER >= 3002000
		RETVAL = archive_read_has_encrypted_entries (self->ar);
#else
		croak ("this feature requires libarchive 3.2+");
#endif

	OUTPUT: RETVAL

int
format_capabilities (self)
	Reader self

	CODE:
#if ARCHIVE_VERSION_NUMBER >= 3002000
		RETVAL = archive_read_format_capabilities (self->ar);
#else
		croak ("this feature requires libarchive 3.2+");
#endif

	OUTPUT: RETVAL

void
add_passphrase (self, phrase)
	Reader self
	const char *phrase

	PREINIT:
		int rc;

	CODE:
#if ARCHIVE_VERSION_NUMBER >= 3002000
		rc = archive_read_add_passphrase (self->ar, phrase);
		archive_check_error (rc, self->ar, archive_read_add_passphrase);
#else
		croak ("this feature requires libarchive 3.2+");
#endif

int
file_count (self)
	Reader self

	CODE:
		RETVAL = archive_file_count (self->ar);

	OUTPUT: RETVAL

int
format (self)
	Reader self

	CODE:
		RETVAL = archive_format (self->ar);

	OUTPUT: RETVAL

const char *
format_name (self)
	Reader self

	CODE:
		RETVAL = archive_format_name (self->ar);

	OUTPUT: RETVAL

void
close (self)
	Reader self

	PPCODE:
		if (self->reading)
		{
			archive_read_close (self->ar);
			self->reading = 0;
			XSRETURN_YES;
		}

		XSRETURN_NO;

void
DESTROY (self)
	Reader self

	CODE:
		if (self->reading)
			archive_read_close (self->ar);
		archive_read_free (self->ar);
		Safefree (self);
