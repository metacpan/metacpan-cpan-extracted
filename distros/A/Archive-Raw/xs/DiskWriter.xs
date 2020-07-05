MODULE = Archive::Raw               PACKAGE = Archive::Raw::DiskWriter

DiskWriter
new (class, flags)
	SV *class
	int flags

	PREINIT:
		archive_raw_diskwriter *self;

	CODE:
		Newxz (self, 1, archive_raw_diskwriter);
		self->ar = archive_write_disk_new();
		archive_write_disk_set_options (self->ar, flags);
		archive_write_disk_set_standard_lookup (self->ar);

		if (self->ar == NULL)
			croak ("archive_write_disk_new() failed");

		RETVAL = self;

	OUTPUT: RETVAL

void
write (self, entry)
	DiskWriter self
	Entry entry

	PREINIT:
		int rc;

	CODE:
		rc = archive_write_header (self->ar, entry->e);
		archive_check_error (rc, self->ar, archive_write_header);

		if (archive_entry_size (entry->e) > 0)
		{
			const void *buffer;
			size_t size;
			la_int64_t offset;

			for (;;)
			{
				rc = archive_read_data_block (entry->reader->ar, &buffer, &size, &offset);
				if (rc == ARCHIVE_EOF)
					break;
				archive_check_error (rc, entry->reader->ar, archive_read_data_block);

				rc = archive_write_data_block (self->ar, buffer, size, offset);
				archive_check_error (rc, self->ar, archive_write_data_block);
			}
		}

		rc = archive_write_finish_entry (self->ar);
		archive_check_error (rc, self->ar, archive_write_finish_entry);

void
close (self)
	DiskWriter self

	PREINIT:
		int rc;

	CODE:
		rc = archive_write_close (self->ar);
		archive_check_error (rc, self->ar, archive_write_close);

void
DESTROY (self)
	DiskWriter self

	CODE:
		archive_write_free (self->ar);
		Safefree (self);
