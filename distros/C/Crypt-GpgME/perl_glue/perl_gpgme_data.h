ssize_t perl_gpgme_data_read (void *handle, void *buffer, size_t size);

ssize_t perl_gpgme_data_write (void *handle, const void *buffer, size_t size);

off_t perl_gpgme_data_seek (void *handle, const off_t offset, int whence);

void perl_gpgme_data_release (void *handle);

gpgme_data_t perl_gpgme_data_new (SV *sv);

gpgme_data_t perl_gpgme_data_from_io_handle (SV *sv);

SV *perl_gpgme_data_io_handle_from_scalar (SV *scalar);

SV *perl_gpgme_data_to_sv (gpgme_data_t data);
