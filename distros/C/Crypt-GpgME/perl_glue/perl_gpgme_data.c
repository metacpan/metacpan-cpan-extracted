#include "perl_gpgme.h"

ssize_t
perl_gpgme_data_read (void *handle, void *buffer, size_t size) {
	dSP;
	ssize_t got_size;
	int ret;
	STRLEN buf_len;
	char *buf_chr;
	SV *sv_buffer;

	sv_buffer = newSVpv ("", 0);

	ENTER;
	SAVETMPS;

	PUSHMARK (sp);

	EXTEND (sp, 3);
	PUSHs ((SV *)handle);
	PUSHs (sv_buffer);
	mPUSHi (size);

	PUTBACK;

	ret = call_method ("sysread", G_SCALAR);

	SPAGAIN;

	if (ret != 1) {
		PUTBACK;
		croak ("Calling sysread on io handle didn't return a single scalar.");
	}

	got_size = POPi;
	buf_chr = SvPV (sv_buffer, buf_len);
	buffer = memcpy (buffer, buf_chr, buf_len);

	PUTBACK;
	FREETMPS;
	LEAVE;

	return got_size;
}

ssize_t
perl_gpgme_data_write (void *handle, const void *buffer, size_t size) {
	dSP;
	ssize_t got_size;
	int ret;

	ENTER;
	SAVETMPS;

	PUSHMARK (sp);

	EXTEND (sp, 3);
	PUSHs ((SV *)handle);
	mPUSHp ((char *)buffer, size);
	mPUSHi (size);

	PUTBACK;

	ret = call_method ("syswrite", G_SCALAR);

	SPAGAIN;

	if (ret != 1) {
		PUTBACK;
		croak ("Calling syswrite on io handle didn't return a single scalar.");
	}

	got_size = POPi;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return got_size;
}

off_t
perl_gpgme_data_seek (void *handle, off_t offset, int whence) {
	dSP;
	off_t seeked;
	int ret;

	ENTER;
	SAVETMPS;

	PUSHMARK (sp);

	EXTEND (sp, 3);
	PUSHs ((SV *)handle);
	mPUSHi (offset);
	mPUSHi (whence);

	PUTBACK;

	ret = call_method ("sysseek", G_SCALAR);

	SPAGAIN;

	if (ret != 1) {
		PUTBACK;
		croak ("Calling sysseek on io handle didn't return a single scalar.");
	}

	seeked = POPi;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return seeked;
}

void
perl_gpgme_data_release (void *handle) {
	SvREFCNT_inc ((SV *)handle);
}

gpgme_data_t
perl_gpgme_data_new (SV *sv) {
	gpgme_data_t data;
	gpgme_error_t err;
	static struct gpgme_data_cbs cbs;
	static gpgme_data_cbs_t cbs_ptr = NULL;

	if (!cbs_ptr) {
		memset (&cbs, 0, sizeof (cbs));

		cbs.read = perl_gpgme_data_read;
		cbs.write = perl_gpgme_data_write;
		cbs.seek = perl_gpgme_data_seek;
		cbs.release = perl_gpgme_data_release;

		cbs_ptr = &cbs;
	}

	SvREFCNT_inc (sv);

	err = gpgme_data_new_from_cbs (&data, cbs_ptr, sv);
	perl_gpgme_assert_error (err);

	return data;
}

SV *
perl_gpgme_data_io_handle_from_scalar (SV *scalar) {
	dSP;
	SV *sv;
	int ret;

	ENTER;
	SAVETMPS;

	PUSHMARK (sp);

	EXTEND (sp, 2);
	mPUSHp ("Crypt::GpgME::Data", 18);
	PUSHs (newRV_inc (scalar));

	PUTBACK;

	ret = call_method ("new", G_SCALAR);

	SPAGAIN;

	if (ret != 1) {
		PUTBACK;
		croak ("Failed to create Crypt::GpgME::Data instance.");
	}

	sv = POPs;
	SvREFCNT_inc (sv); /* why? */

	PUTBACK;
	FREETMPS;
	LEAVE;

	return sv;
}

SV *
perl_gpgme_data_to_sv (gpgme_data_t data) {
	dSP;
	SV *sv, *buffer;
	char *buf;
	int ret;
	size_t len;

	gpgme_data_seek (data, 0, SEEK_SET);

	buf = gpgme_data_release_and_get_mem (data, &len);

	if (!buf) {
		buffer = newSV (0);
	}
	else {
		buffer = newSVpv (buf, len);
	}

	gpgme_free (buf);

	ENTER;
	SAVETMPS;

	PUSHMARK (sp);

	EXTEND (sp, 2);
	mPUSHp ("Crypt::GpgME::Data", 18);
	PUSHs (newRV_inc (buffer));

	PUTBACK;

	ret = call_method ("new", G_SCALAR);

	SPAGAIN;

	if (ret != 1) {
		PUTBACK;
		croak ("Failed to create Crypt::GpgME::Data instance.");
	}

	sv = POPs;
	SvREFCNT_inc (sv); /* why? */

	PUTBACK;
	FREETMPS;
	LEAVE;

	return sv;
}

gpgme_data_t
perl_gpgme_data_from_io_handle (SV *handle) {
	return perl_gpgme_data_new (handle);
}
